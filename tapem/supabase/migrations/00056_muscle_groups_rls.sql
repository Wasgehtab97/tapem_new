-- =============================================================================
-- Tap'em — Muscle group RLS policies
-- =============================================================================

-- ─── exercise_muscle_groups ───────────────────────────────────────────────────

ALTER TABLE public.exercise_muscle_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "gym members can read exercise muscle groups"
  ON public.exercise_muscle_groups
  FOR SELECT
  USING (public.has_active_membership(gym_id));

CREATE POLICY "gym admins can manage exercise muscle groups"
  ON public.exercise_muscle_groups
  FOR ALL
  USING (public.is_gym_admin(gym_id));

-- ─── user_custom_exercise_muscle_groups ──────────────────────────────────────

ALTER TABLE public.user_custom_exercise_muscle_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users own their custom exercise muscle groups"
  ON public.user_custom_exercise_muscle_groups
  FOR ALL
  USING (user_id = auth.uid());
