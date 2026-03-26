-- =============================================================================
-- Tap'em — equipment_feedback
--
-- Purpose: Bring the equipment_feedback table under migration control and
-- harden it with RLS.  The table may already exist in production (created
-- manually without RLS), so every DDL statement is written to be idempotent.
--
-- Sensitive columns: user_id (PII), message (free text)
-- Security model:
--   • INSERT  — authenticated member of the gym submits feedback
--   • SELECT  — gym coaches/admins read feedback in their gym
--   • Users cannot read other users' feedback
--   • service_role bypasses RLS for admin tooling
-- =============================================================================

-- ─── 1. Create table (no-op if it already exists) ────────────────────────────

CREATE TABLE IF NOT EXISTS public.equipment_feedback (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id          UUID        NOT NULL
                    REFERENCES public.tenant_gyms(id)    ON DELETE CASCADE,
  equipment_id    UUID        NOT NULL
                    REFERENCES public.gym_equipment(id)  ON DELETE CASCADE,
  equipment_name  TEXT        NOT NULL,   -- denormalised snapshot at submit time
  user_id         UUID        NOT NULL
                    REFERENCES auth.users(id)            ON DELETE CASCADE,
  message         TEXT        NOT NULL
                    CONSTRAINT equipment_feedback_message_nonempty
                    CHECK (char_length(trim(message)) > 0),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add created_at if table existed without it (idempotent)
ALTER TABLE public.equipment_feedback
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- ─── 2. Indexes ───────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_equipment_feedback_gym
  ON public.equipment_feedback (gym_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_equipment_feedback_user
  ON public.equipment_feedback (user_id);

-- ─── 3. Enable RLS (idempotent — safe to run even if already enabled) ────────

ALTER TABLE public.equipment_feedback ENABLE ROW LEVEL SECURITY;

-- ─── 4. Policies ──────────────────────────────────────────────────────────────

-- Members can submit feedback for equipment in their active gym.
DO $$ BEGIN
  CREATE POLICY "equipment_feedback_insert_own"
    ON public.equipment_feedback FOR INSERT
    TO authenticated
    WITH CHECK (
      user_id = auth.uid()
      AND public.has_active_membership(gym_id)
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Coaches and admins can read all feedback in their gym.
DO $$ BEGIN
  CREATE POLICY "equipment_feedback_read_coach"
    ON public.equipment_feedback FOR SELECT
    TO authenticated
    USING (public.is_gym_coach(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── 5. Grants ────────────────────────────────────────────────────────────────

-- authenticated role needs INSERT (member submits) and SELECT (coach reads)
GRANT SELECT, INSERT ON public.equipment_feedback TO authenticated;

-- service_role for admin tooling / edge functions
GRANT ALL ON public.equipment_feedback TO service_role;
