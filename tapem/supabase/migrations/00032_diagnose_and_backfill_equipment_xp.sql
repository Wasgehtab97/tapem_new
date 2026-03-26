-- =============================================================================
-- Tap'em — 00032: Diagnose real exercise_equipment XP + comprehensive backfill
--
-- Problem: Real workout data (e.g. Abductor) not showing in Equipment XP tab.
-- Root causes investigated:
--   A. exercise_equipment xp_events exist but equipment_id = NULL
--      (session was created before edge function was updated to stamp it)
--   B. exercise_equipment xp_events exist with equipment_id set but the
--      get_gym_equipment_overview query still doesn't surface them
--   C. exercise_equipment xp_events do not exist at all for real sessions
--      (sets were logged but sync failed at XP step)
--
-- This migration:
--   1. Outputs diagnostic counts via RAISE NOTICE
--   2. Retries backfill of equipment_id on existing xp_events where NULL
--      (broader approach: uses ANY available workout_session link)
--   3. Creates missing exercise_equipment xp_events for any finished session
--      that has session_exercises + set_entries but no corresponding event
--      (idempotent via ON CONFLICT DO NOTHING)
-- =============================================================================

DO $$
DECLARE
  v_gym_id UUID := 'a0000000-0000-0000-0000-000000000001';
  v_count  INTEGER;
BEGIN

  -- ── Diagnostic: how many exercise_equipment events exist total? ────────────
  SELECT COUNT(*) INTO v_count
  FROM public.xp_events
  WHERE gym_id = v_gym_id
    AND axis = 'exercise_equipment'::public.xp_axis;
  RAISE NOTICE '00032 DIAG: exercise_equipment xp_events total = %', v_count;

  -- ── Diagnostic: how many have NULL equipment_id? ──────────────────────────
  SELECT COUNT(*) INTO v_count
  FROM public.xp_events
  WHERE gym_id = v_gym_id
    AND axis = 'exercise_equipment'::public.xp_axis
    AND equipment_id IS NULL;
  RAISE NOTICE '00032 DIAG: exercise_equipment events with NULL equipment_id = %', v_count;

  -- ── Diagnostic: how many have non-NULL equipment_id (excludes seeds)? ─────
  SELECT COUNT(*) INTO v_count
  FROM public.xp_events
  WHERE gym_id = v_gym_id
    AND axis = 'exercise_equipment'::public.xp_axis
    AND equipment_id IS NOT NULL
    AND idempotency_key NOT LIKE 'equipment_seed:%';
  RAISE NOTICE '00032 DIAG: real exercise_equipment events WITH equipment_id = %', v_count;

  -- ── Diagnostic: finished sessions count ───────────────────────────────────
  SELECT COUNT(*) INTO v_count
  FROM public.workout_sessions
  WHERE gym_id = v_gym_id AND finished_at IS NOT NULL;
  RAISE NOTICE '00032 DIAG: finished workout sessions = %', v_count;

  -- ── Diagnostic: session_exercises with at least one set ───────────────────
  SELECT COUNT(DISTINCT se.id) INTO v_count
  FROM public.session_exercises se
  JOIN public.workout_sessions  ws ON ws.id = se.session_id
  JOIN public.set_entries       st ON st.session_exercise_id = se.id
  WHERE ws.gym_id = v_gym_id AND ws.finished_at IS NOT NULL;
  RAISE NOTICE '00032 DIAG: session_exercises with sets in finished sessions = %', v_count;

END;
$$;

-- ─── Fix A: Retry equipment_id backfill (no IS NOT NULL restriction) ─────────
-- Migration 00029 required ws.equipment_id IS NOT NULL on the join.
-- This version also catches sessions where equipment_id IS NOT NULL
-- but wasn't matched before due to ordering.
-- Rows where ws.equipment_id IS NULL remain NULL (nothing we can do).

UPDATE public.xp_events xe
SET    equipment_id = ws.equipment_id
FROM   public.session_exercises se
JOIN   public.workout_sessions  ws ON ws.id = se.session_id
WHERE  xe.source_id    = se.id
  AND  xe.source_type  = 'session_exercise'
  AND  xe.axis         = 'exercise_equipment'::public.xp_axis
  AND  xe.equipment_id IS NULL
  AND  ws.equipment_id IS NOT NULL
  AND  xe.idempotency_key NOT LIKE 'equipment_seed:%';

-- ─── Fix B: Create missing exercise_equipment xp_events ──────────────────────
-- For any finished session that has session_exercises + set_entries but
-- no corresponding exercise_equipment xp_event yet.
-- Uses the same XP formula as sync-workout (5 + floor(reps/5) per set, cap 120).

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
  ),
  'session_exercise',
  se.id,
  'exercise_equipment:session_exercise:' || se.id,
  se.exercise_key,
  ws.equipment_id,   -- NULL when session had no machine scanned (acceptable)
  ws.finished_at
FROM public.session_exercises se
JOIN public.workout_sessions ws ON ws.id = se.session_id
JOIN public.set_entries       st ON st.session_exercise_id = se.id
WHERE ws.finished_at IS NOT NULL
  AND ws.gym_id = 'a0000000-0000-0000-0000-000000000001'
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
  SET equipment_id = EXCLUDED.equipment_id
  WHERE public.xp_events.equipment_id IS NULL
    AND EXCLUDED.equipment_id IS NOT NULL;

-- ─── Recompute aggregates for all affected users ───────────────────────────────

DO $$
DECLARE
  rec RECORD;
  v_count INTEGER := 0;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, gym_id
    FROM   public.xp_events
    WHERE  axis = 'exercise_equipment'::public.xp_axis
      AND  gym_id = 'a0000000-0000-0000-0000-000000000001'
  LOOP
    PERFORM public.recompute_user_gym_xp(rec.user_id, rec.gym_id);
    v_count := v_count + 1;
  END LOOP;
  RAISE NOTICE '00032: recomputed xp aggregates for % users', v_count;
END;
$$;
