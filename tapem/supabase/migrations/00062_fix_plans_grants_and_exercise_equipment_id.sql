-- =============================================================================
-- Tap'em — 00062: Fix plan table grants + add equipment_id to session_exercises
--
-- Fixes two runtime errors:
--
-- 1. "permission denied for table workout_plans / plan_items" (42501)
--    workout_plans and plan_items were never granted to the `authenticated`
--    role (only service_role bypassed RLS). PostgREST-direct reads/writes from
--    the Flutter client use the JWT-authenticated role, so all reads/writes
--    failed. Fix: add GRANT SELECT, INSERT, UPDATE, DELETE to authenticated.
--
-- 2. "column session_exercises.equipment_id does not exist" (42703)
--    The reinstall fallback in plans_provider.dart queries
--    session_exercises.equipment_id to reconstruct plan items from a past
--    session, but sync-workout never stored this column.
--    Fix: add the nullable column, update sync-workout to write it, and
--    backfill existing rows from xp_events (axis='exercise_equipment').
-- =============================================================================

-- ─── 1. Grants for workout_plans ─────────────────────────────────────────────

GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_plans TO authenticated;
GRANT ALL ON public.workout_plans TO service_role;

-- ─── 2. Grants for plan_items ─────────────────────────────────────────────────

GRANT SELECT, INSERT, UPDATE, DELETE ON public.plan_items TO authenticated;
GRANT ALL ON public.plan_items TO service_role;

-- ─── 3. Add equipment_id to session_exercises ─────────────────────────────────
-- Nullable: historical rows had no equipment_id stored at exercise level
-- (it was only on the session). sync-workout will now populate it going forward.

ALTER TABLE public.session_exercises
  ADD COLUMN IF NOT EXISTS equipment_id UUID
    REFERENCES public.gym_equipment(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_session_exercises_equipment
  ON public.session_exercises (equipment_id)
  WHERE equipment_id IS NOT NULL;

-- ─── 4. Backfill equipment_id from xp_events ─────────────────────────────────
-- xp_events rows with axis='exercise_equipment' store equipment_id and have
-- source_type='session_exercise' / source_id=session_exercise_id.
-- This is the most reliable backfill source for existing data.

UPDATE public.session_exercises se
SET    equipment_id = xe.equipment_id
FROM   public.xp_events xe
WHERE  xe.source_type   = 'session_exercise'
  AND  xe.source_id     = se.id
  AND  xe.axis          = 'exercise_equipment'
  AND  xe.equipment_id  IS NOT NULL
  AND  se.equipment_id  IS NULL;
