-- =============================================================================
-- Tap'em — XP Aggregate Trigger
--
-- Problem: user_gym_xp / user_exercise_xp were only updated when the
-- Edge Function explicitly called recompute_user_gym_xp(). If that call
-- failed (or was skipped), XP events were orphaned in xp_events with no
-- aggregation. The leaderboard then returned empty results.
--
-- Fix: Attach a statement-level trigger to xp_events so aggregates are
-- recomputed automatically on every INSERT — independent of the Edge
-- Function. The REFERENCING clause collects affected (user_id, gym_id)
-- pairs once per statement, so a batch insert (e.g. 5 events for one
-- workout) calls recompute_user_gym_xp exactly once per unique pair —
-- not once per row.
--
-- Edge Functions may still call recompute_user_gym_xp explicitly; that
-- is idempotent and harmless. We removed those calls to keep Edge
-- Functions stateless w.r.t. aggregation.
-- =============================================================================

-- ─── Trigger function ─────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public._recompute_xp_on_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, gym_id FROM new_events
  LOOP
    PERFORM public.recompute_user_gym_xp(rec.user_id, rec.gym_id);
  END LOOP;
  RETURN NULL;
END;
$$;

COMMENT ON FUNCTION public._recompute_xp_on_insert IS
  'Statement-level trigger handler: recomputes XP aggregates for every '
  '(user_id, gym_id) pair affected by a bulk xp_events INSERT.';

-- ─── Trigger ──────────────────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS xp_events_recompute_on_insert ON public.xp_events;

CREATE TRIGGER xp_events_recompute_on_insert
  AFTER INSERT ON public.xp_events
  REFERENCING NEW TABLE AS new_events
  FOR EACH STATEMENT
  EXECUTE FUNCTION public._recompute_xp_on_insert();

-- ─── Backfill: re-run XP generation for all finished sessions ─────────────────
-- Safe to run multiple times — xp_events upserts use ON CONFLICT DO NOTHING
-- on idempotency_key, and recompute_user_gym_xp is fully idempotent.
-- This fixes sessions that were synced before the trigger existed.

-- Step 1: training_day XP — 100 XP per unique (gym, user, day)
INSERT INTO public.xp_events (
  gym_id, user_id, axis, xp_amount,
  source_type, source_id, idempotency_key, occurred_at
)
SELECT
  ws.gym_id,
  ws.user_id,
  'training_day',
  100,
  'workout_session',
  ws.id,
  'training_day:workout_session:' || ws.gym_id || ':' || ws.user_id || ':' || ws.session_day_anchor,
  ws.finished_at
FROM public.workout_sessions ws
WHERE ws.finished_at IS NOT NULL
ON CONFLICT (idempotency_key) DO NOTHING;

-- Step 2: exercise_equipment XP — XP_PER_SET_BASE + floor(reps/5), capped at 120
INSERT INTO public.xp_events (
  gym_id, user_id, axis, xp_amount,
  source_type, source_id, idempotency_key, exercise_key, occurred_at
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
JOIN public.set_entries       st ON st.session_exercise_id = se.id
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

-- Step 3: Recompute aggregates for every user+gym that has xp_events.
-- The trigger fires for INSERTs above; this DO block handles the case
-- where all events already existed (ON CONFLICT → no insert → no trigger).
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
