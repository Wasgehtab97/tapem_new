-- =============================================================================
-- Tap'em — 00034: Comprehensive backfill of equipment_id on xp_events
--
-- Root cause of "Niemand" on Equipment XP tab:
--   exercise_equipment xp_events have equipment_id = NULL because they were
--   written before xp_events.equipment_id existed (pre-migration-00029), or
--   because the sync-workout edge function failed at the XP step (session
--   data was written but XP was not).
--
-- Note: session_exercises has no equipment_id column server-side (it exists
-- only in the local Drift schema). The only server-side source for equipment
-- attribution is workout_sessions.equipment_id (set from the NFC-scanned
-- machine UUID). Plan/freestyle sessions (equipment_id = NULL on the session)
-- cannot be backfilled — those events will be NULL until a fresh sync runs
-- with the updated edge function.
--
-- Steps:
--   1. Retry backfill of equipment_id on existing xp_events via
--      session_exercises → workout_sessions (superset of 00032's attempt).
--   2. Create missing exercise_equipment xp_events for finished sessions that
--      have set_entries but no corresponding event.
--   3. Recompute XP aggregates for all affected users.
-- =============================================================================

-- ─── Step 1: Retry backfill from workout_sessions.equipment_id ────────────────
-- Covers NFC-scan sessions where the machine UUID is on the session row.

UPDATE public.xp_events xe
SET    equipment_id = ws.equipment_id
FROM   public.session_exercises se
JOIN   public.workout_sessions  ws ON ws.id = se.session_id
WHERE  xe.source_id        = se.id
  AND  xe.source_type      = 'session_exercise'
  AND  xe.axis             = 'exercise_equipment'::public.xp_axis
  AND  xe.equipment_id     IS NULL
  AND  ws.equipment_id     IS NOT NULL;

-- ─── Step 2: Create missing exercise_equipment xp_events ─────────────────────
-- For finished sessions that have session_exercises + set_entries but no
-- xp_event yet (e.g. sync failed at the XP insertion step, or legacy data).
-- Uses the same formula as sync-workout: 5 + floor(reps/5) per set, cap 120.

INSERT INTO public.xp_events (
  gym_id,
  user_id,
  axis,
  xp_amount,
  source_type,
  source_id,
  idempotency_key,
  exercise_key,
  equipment_id,
  occurred_at
)
SELECT
  ws.gym_id,
  ws.user_id,
  'exercise_equipment'::public.xp_axis,
  LEAST(
    SUM(
      CASE
        WHEN st.duration_seconds IS NOT NULL THEN 5
        ELSE 5 + FLOOR(COALESCE(st.reps, 0)::FLOAT / 5)::INTEGER
      END
    )::INTEGER,
    120
  ) AS xp_amount,
  'session_exercise',
  se.id,
  'exercise_equipment:session_exercise:' || se.id,
  se.exercise_key,
  ws.equipment_id,   -- NULL for freestyle sessions (acceptable — no machine attribution)
  ws.finished_at
FROM  public.session_exercises se
JOIN  public.workout_sessions  ws ON ws.id = se.session_id
JOIN  public.set_entries       st ON st.session_exercise_id = se.id
WHERE ws.finished_at IS NOT NULL
GROUP BY se.id, ws.gym_id, ws.user_id, se.exercise_key, ws.equipment_id, ws.finished_at
HAVING LEAST(
  SUM(
    CASE
      WHEN st.duration_seconds IS NOT NULL THEN 5
      ELSE 5 + FLOOR(COALESCE(st.reps, 0)::FLOAT / 5)::INTEGER
    END
  )::INTEGER,
  120
) > 0
ON CONFLICT (idempotency_key) DO UPDATE
  -- If event exists but equipment_id is NULL, fill it in now.
  SET equipment_id = EXCLUDED.equipment_id
  WHERE public.xp_events.equipment_id IS NULL
    AND EXCLUDED.equipment_id IS NOT NULL;

-- ─── Step 3: Recompute XP aggregates for all affected users ───────────────────

DO $$
DECLARE
  rec     RECORD;
  v_count INTEGER := 0;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, gym_id
    FROM   public.xp_events
    WHERE  axis = 'exercise_equipment'::public.xp_axis
  LOOP
    PERFORM public.recompute_user_gym_xp(rec.user_id, rec.gym_id);
    v_count := v_count + 1;
  END LOOP;
  RAISE NOTICE '00034: recomputed XP aggregates for % user-gym pairs', v_count;
END;
$$;
