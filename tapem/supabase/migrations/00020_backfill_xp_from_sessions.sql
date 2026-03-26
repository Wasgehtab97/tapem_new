-- =============================================================================
-- Tap'em — Backfill XP for all finished workout_sessions that have no
-- training_day xp_event. Safe to run multiple times (idempotent via
-- ON CONFLICT DO NOTHING on idempotency_key).
-- Fixes the window where the sync-workout edge function had a bug and
-- sessions were synced without XP being processed.
-- =============================================================================

-- Step 1: Insert missing training_day xp_events for every finished session.
INSERT INTO public.xp_events (
  gym_id,
  user_id,
  axis,
  xp_amount,
  source_type,
  source_id,
  idempotency_key,
  occurred_at
)
SELECT
  ws.gym_id,
  ws.user_id,
  'training_day',
  100,   -- XP_TRAINING_DAY constant (matches finish-session edge fn)
  'workout_session',
  ws.id,
  'training_day:workout_session:' || ws.gym_id || ':' || ws.user_id || ':' || ws.session_day_anchor,
  ws.finished_at
FROM public.workout_sessions ws
WHERE ws.finished_at IS NOT NULL
ON CONFLICT (idempotency_key) DO NOTHING;

-- Step 2: Insert missing exercise_equipment xp_events for session_exercises
-- that have checked sets. XP = 5 + floor(reps/5) per set, capped at 120.
INSERT INTO public.xp_events (
  gym_id,
  user_id,
  axis,
  xp_amount,
  source_type,
  source_id,
  idempotency_key,
  exercise_key,
  occurred_at
)
SELECT
  se.gym_id,
  ws.user_id,
  'exercise_equipment',
  LEAST(
    SUM(
      CASE
        WHEN st.duration_seconds IS NOT NULL THEN 5
        ELSE 5 + FLOOR(COALESCE(st.reps, 0) / 5)
      END
    )::INTEGER,
    120
  ),
  'session_exercise',
  se.id,
  'exercise_equipment:session_exercise:' || se.id,
  se.exercise_key,
  ws.finished_at
FROM public.session_exercises se
JOIN public.workout_sessions ws ON ws.id = se.session_id
JOIN public.set_entries st      ON st.session_exercise_id = se.id
WHERE ws.finished_at IS NOT NULL
GROUP BY se.id, se.gym_id, ws.user_id, se.exercise_key, ws.finished_at
HAVING LEAST(
  SUM(
    CASE
      WHEN st.duration_seconds IS NOT NULL THEN 5
      ELSE 5 + FLOOR(COALESCE(st.reps, 0) / 5)
    END
  )::INTEGER,
  120
) > 0
ON CONFLICT (idempotency_key) DO NOTHING;

-- Step 3: Recompute user_gym_xp aggregates for every affected user+gym.
DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, gym_id
    FROM public.xp_events
    WHERE axis = 'training_day'
  LOOP
    PERFORM public.recompute_user_gym_xp(rec.user_id, rec.gym_id);
  END LOOP;
END;
$$;
