-- =============================================================================
-- Tap'em — 00022: Leaderboard Data Fix & Robust Ranking Function
--
-- Root causes of empty leaderboard:
--   1. privacy_level column may have defaulted to 'private', causing
--      newly registered users to be excluded from rankings until they
--      explicitly changed the setting in their profile.
--   2. user_gym_xp aggregation may not have been computed for users whose
--      sessions were synced before the trigger in 00021 was applied.
--   3. NULL privacy_level on user_profiles rows (no explicit default set).
--
-- Fixes applied:
--   1. Set privacy_level column DEFAULT → 'friends_training_days'
--   2. Backfill NULL privacy_level → 'friends_training_days'
--   3. Add get_gym_leaderboard() — unified RPC with session-based fallback
--      that returns data even when user_gym_xp aggregation hasn't run
--   4. Re-run comprehensive XP backfill (idempotent)
--   5. Final recompute of all user_gym_xp aggregates
-- =============================================================================

-- ─── Fix 1: Column default ────────────────────────────────────────────────────
-- Future INSERT statements will use 'friends_training_days' as the default,
-- ensuring new users appear in rankings immediately after their first workout.

ALTER TABLE public.user_profiles
  ALTER COLUMN privacy_level SET DEFAULT 'friends_training_days';

-- ─── Fix 2: Backfill NULL privacy_level ──────────────────────────────────────
-- Existing rows with NULL (from before the DEFAULT was set) are visible
-- nowhere in rankings because the RPC WHERE clause is != 'private'. NULL
-- rows pass that check but may have been unintended. Treating NULL as
-- 'friends_training_days' is the safe, non-breaking choice.

UPDATE public.user_profiles
SET    privacy_level = 'friends_training_days'
WHERE  privacy_level IS NULL;

-- ─── Fix 3: Robust leaderboard RPC ───────────────────────────────────────────
-- Replaces the old get_gym_training_day_ranking / get_gym_equipment_ranking
-- pair with a single unified function. Key improvement: a session-based
-- fallback ensures users with finished sessions appear even when their
-- xp_events haven't been backfilled yet.
--
-- Columns returned:
--   rank             — RANK() OVER xp DESC (ties share same rank)
--   user_id          — UUID of the ranked member
--   username         — from user_profiles
--   total_xp         — sum of XP for this axis
--   current_level    — xp_to_level(total_xp)
--   training_days    — total_xp / 100 (only meaningful for training_day axis)
--   xp_to_next_level — XP still needed for next level-up

CREATE OR REPLACE FUNCTION public.get_gym_leaderboard(
  p_gym_id UUID,
  p_axis   TEXT DEFAULT 'training_day'  -- 'training_day' | 'exercise_equipment'
)
RETURNS TABLE (
  rank             BIGINT,
  user_id          UUID,
  username         TEXT,
  total_xp         INTEGER,
  current_level    SMALLINT,
  training_days    INTEGER,
  xp_to_next_level INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH

  -- Primary path: aggregate from the immutable xp_events log.
  -- This is always the authoritative source when backfill has run.
  xp_from_events AS (
    SELECT
      xe.user_id,
      SUM(xe.xp_amount)::INTEGER AS total_xp
    FROM public.xp_events xe
    WHERE xe.gym_id     = p_gym_id
      AND xe.axis::TEXT = p_axis        -- cast enum → TEXT to match TEXT param
    GROUP BY xe.user_id
  ),

  -- Fallback path (training_day axis only): users who have finished sessions
  -- but no corresponding xp_events yet. Computes 100 XP per unique training
  -- day — matching the canonical server-side constant in finish-session.
  --
  -- This covers the window between session sync and XP backfill, which is
  -- the most common cause of empty leaderboards in early deployments.
  session_fallback AS (
    SELECT
      ws.user_id,
      (COUNT(DISTINCT ws.session_day_anchor) * 100)::INTEGER AS total_xp
    FROM public.workout_sessions ws
    WHERE ws.gym_id        = p_gym_id
      AND ws.finished_at   IS NOT NULL
      AND p_axis           = 'training_day'
      AND ws.user_id NOT IN (SELECT xf.user_id FROM xp_from_events xf)
    GROUP BY ws.user_id
  ),

  -- Merge both paths; only include members with actual XP.
  combined AS (
    SELECT user_id, total_xp FROM xp_from_events WHERE total_xp > 0
    UNION ALL
    SELECT user_id, total_xp FROM session_fallback WHERE total_xp > 0
  ),

  -- Apply RANK() once after merging so ties are computed correctly.
  ranked AS (
    SELECT
      RANK() OVER (ORDER BY c.total_xp DESC)::BIGINT AS rnk,
      c.user_id,
      c.total_xp
    FROM combined c
  )

  SELECT
    r.rnk                                          AS rank,
    r.user_id,
    up.username,
    r.total_xp,
    public.xp_to_level(r.total_xp)                AS current_level,
    (r.total_xp / 100)::INTEGER                    AS training_days,
    public.xp_needed_for_next_level(r.total_xp)   AS xp_to_next_level
  FROM ranked r
  JOIN public.user_profiles up ON up.id = r.user_id
  -- Include users with NULL privacy_level (treated as non-private per Fix 2)
  WHERE (up.privacy_level IS NULL OR up.privacy_level != 'private')
  ORDER BY r.rnk
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_gym_leaderboard IS
  'Unified gym leaderboard. Reads from xp_events (primary) with a '
  'session-based fallback for users whose XP has not been aggregated yet. '
  'Supports training_day and exercise_equipment axes. '
  'Respects privacy_level. Returns at most 100 members per gym.';

GRANT EXECUTE ON FUNCTION public.get_gym_leaderboard(UUID, TEXT)
  TO authenticated;

-- ─── Fix 4: Comprehensive XP backfill ────────────────────────────────────────
-- Re-insert training_day XP events for every finished session.
-- ON CONFLICT DO NOTHING makes this fully idempotent — safe to run multiple
-- times and will not create duplicate events.

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
  100,
  'workout_session',
  ws.id,
  'training_day:workout_session:' || ws.gym_id || ':' || ws.user_id || ':' || ws.session_day_anchor,
  ws.finished_at
FROM public.workout_sessions ws
WHERE ws.finished_at IS NOT NULL
ON CONFLICT (idempotency_key) DO NOTHING;

-- Backfill exercise_equipment XP events for all session_exercises with sets.
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
        ELSE 5 + FLOOR(COALESCE(st.reps, 0)::FLOAT / 5)::INTEGER
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
      ELSE 5 + FLOOR(COALESCE(st.reps, 0)::FLOAT / 5)::INTEGER
    END
  )::INTEGER,
  120
) > 0
ON CONFLICT (idempotency_key) DO NOTHING;

-- ─── Fix 5: Recompute all user_gym_xp aggregates ──────────────────────────────
-- Runs recompute_user_gym_xp for every (user_id, gym_id) pair that has any
-- training_day XP event. Safe to run after fixes 1–4; the trigger installed
-- in 00021 handles future inserts automatically.

DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, gym_id
    FROM   public.xp_events
    WHERE  axis::TEXT = 'training_day'
  LOOP
    PERFORM public.recompute_user_gym_xp(rec.user_id, rec.gym_id);
  END LOOP;
END;
$$;
