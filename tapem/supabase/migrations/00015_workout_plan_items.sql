-- =============================================================================
-- Tap'em — Workout Plan Items
-- Member-owned training plans: plan_items table + workout_plans hardening
-- =============================================================================

-- ─── workout_plans: missing is_active column + name constraint ────────────────

ALTER TABLE public.workout_plans
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.workout_plans
  ADD CONSTRAINT workout_plans_name_length
  CHECK (char_length(name) BETWEEN 1 AND 50);

-- updated_at trigger was missing from baseline migration
CREATE TRIGGER set_updated_at_workout_plans
  BEFORE UPDATE ON public.workout_plans
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─── plan_items ───────────────────────────────────────────────────────────────
-- Each row is one exercise slot in a WorkoutPlan, ordered by [position].
-- Referencing either a fixed_machine canonical exercise or a user custom exercise.

CREATE TABLE public.plan_items (
  id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id                 UUID        NOT NULL
                            REFERENCES public.workout_plans(id) ON DELETE CASCADE,
  gym_id                  UUID        NOT NULL
                            REFERENCES public.tenant_gyms(id)   ON DELETE CASCADE,
  equipment_id            UUID        NOT NULL
                            REFERENCES public.gym_equipment(id)  ON DELETE CASCADE,
  -- Exactly one of the two exercise references should be set per row:
  -- fixed_machine/cardio: canonical_exercise_key set, custom_exercise_id null
  -- open_station:         custom_exercise_id set
  canonical_exercise_key  TEXT,
  custom_exercise_id      UUID
                            REFERENCES public.user_custom_exercises(id) ON DELETE SET NULL,
  -- Denormalised display name — avoids joins on every plan load
  display_name            TEXT NOT NULL
                            CONSTRAINT plan_item_display_name_nonempty
                            CHECK (char_length(display_name) > 0),
  position                SMALLINT    NOT NULL CHECK (position >= 0),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Each position must be unique within a plan (enforced atomically on reorder)
  UNIQUE (plan_id, position)
);

CREATE INDEX idx_plan_items_plan ON public.plan_items (plan_id);
CREATE INDEX idx_plan_items_gym  ON public.plan_items (gym_id);

-- ─── RLS ──────────────────────────────────────────────────────────────────────

ALTER TABLE public.plan_items ENABLE ROW LEVEL SECURITY;

-- Plan owner can do everything with their plan's items
CREATE POLICY "plan_items_manage_own"
  ON public.plan_items FOR ALL
  TO authenticated
  USING (
    public.has_active_membership(gym_id)
    AND EXISTS (
      SELECT 1 FROM public.workout_plans wp
      WHERE wp.id = plan_items.plan_id
        AND wp.created_by = auth.uid()
    )
  )
  WITH CHECK (
    public.has_active_membership(gym_id)
    AND EXISTS (
      SELECT 1 FROM public.workout_plans wp
      WHERE wp.id = plan_items.plan_id
        AND wp.created_by = auth.uid()
    )
  );

-- Coaches can read plan items for all plans in their gym
CREATE POLICY "plan_items_coach_read"
  ON public.plan_items FOR SELECT
  TO authenticated
  USING (public.is_gym_coach(gym_id));

-- ─── workout_plans: delete policy for owner ───────────────────────────────────
-- Allow member to soft-delete (set is_active=false) their own plans

CREATE POLICY "workout_plans_delete_own"
  ON public.workout_plans FOR DELETE
  TO authenticated
  USING (created_by = auth.uid());
