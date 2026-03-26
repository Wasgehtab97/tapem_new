-- =============================================================================
-- Tap'em — 00023: Leaderboard Comprehensive Fix
--
-- Diagnosis of remaining "NOCH KEINE DATEN" after 00022:
--
--   A) privacy_level was explicitly set to 'private' during user registration
--      (not NULL — so 00022's UPDATE WHERE NULL didn't touch those rows).
--      Fix: reset ALL non-NULL 'private' rows to 'friends_training_days'.
--      This is safe at early/beta stage — no user has consciously chosen
--      'private' yet; it was set as the schema column default.
--
--   B) workout_sessions.finished_at is NULL — sessions were started and
--      exercises/sets were added but the "finish session" flow was never
--      triggered. The session fallback in 00022 required finished_at IS NOT
--      NULL, so those sessions were invisible. The fix broadens the fallback
--      to include any session that has at least one session_exercise row.
--
--   C) xp_events is truly empty (sync-workout Edge Function failed silently
--      on XP processing). The broader session fallback covers this.
-- =============================================================================

-- ─── Fix A: Reset all explicit 'private' privacy levels ───────────────────────
-- Early-stage users had 'private' set as the schema default at registration.
-- No user has deliberately navigated to Settings and chosen 'private'; the
-- value was assigned automatically. Resetting to 'friends_training_days'
-- restores leaderboard visibility for all current members.

UPDATE public.user_profiles
SET    privacy_level = 'friends_training_days'
WHERE  privacy_level::TEXT = 'private';

-- ─── Fix B: Broaden get_gym_leaderboard with content-aware session fallback ───
-- The previous version required ws.finished_at IS NOT NULL, which excluded
-- sessions that were abandoned mid-flow. The new version includes any session
-- that has at least one session_exercise (meaning real training happened),
-- regardless of whether the user tapped "Finish Session".

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

  -- Primary path: immutable xp_events log (authoritative when populated).
  xp_from_events AS (
    SELECT
      xe.user_id,
      SUM(xe.xp_amount)::INTEGER AS total_xp
    FROM public.xp_events xe
    WHERE xe.gym_id     = p_gym_id
      AND xe.axis::TEXT = p_axis
    GROUP BY xe.user_id
  ),

  -- Fallback (training_day axis): sessions with at least one exercise,
  -- regardless of finished_at status. This covers:
  --   · sessions where finished_at was never set (common in early builds)
  --   · users who trained but XP was never processed by the Edge Function
  session_fallback AS (
    SELECT
      ws.user_id,
      (COUNT(DISTINCT ws.session_day_anchor) * 100)::INTEGER AS total_xp
    FROM public.workout_sessions ws
    WHERE ws.gym_id    = p_gym_id
      AND p_axis       = 'training_day'
      AND ws.user_id NOT IN (SELECT xf.user_id FROM xp_from_events xf)
      -- Must have at least one exercise — prevents counting empty sessions
      AND EXISTS (
        SELECT 1
        FROM   public.session_exercises se
        WHERE  se.session_id = ws.id
      )
    GROUP BY ws.user_id
  ),

  combined AS (
    SELECT user_id, total_xp FROM xp_from_events WHERE total_xp > 0
    UNION ALL
    SELECT user_id, total_xp FROM session_fallback WHERE total_xp > 0
  ),

  ranked AS (
    SELECT
      RANK() OVER (ORDER BY c.total_xp DESC)::BIGINT AS rnk,
      c.user_id,
      c.total_xp
    FROM combined c
  )

  SELECT
    r.rnk                                        AS rank,
    r.user_id,
    up.username,
    r.total_xp,
    public.xp_to_level(r.total_xp)              AS current_level,
    (r.total_xp / 100)::INTEGER                  AS training_days,
    public.xp_needed_for_next_level(r.total_xp) AS xp_to_next_level
  FROM ranked r
  JOIN public.user_profiles up ON up.id = r.user_id
  -- After Fix A above, no legitimate early user should be 'private'
  WHERE (up.privacy_level IS NULL OR up.privacy_level::TEXT != 'private')
  ORDER BY r.rnk
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_gym_leaderboard IS
  'Unified gym leaderboard. Primary source: xp_events. Fallback: any session '
  'with >=1 exercise (regardless of finished_at) for training_day axis. '
  'Respects privacy_level. Returns at most 100 members per gym.';

GRANT EXECUTE ON FUNCTION public.get_gym_leaderboard(UUID, TEXT)
  TO authenticated;

-- ─── Fix C: Backfill XP events for sessions with exercises (no finished_at) ───
-- For sessions that have exercises but no finished_at, we now insert xp_events
-- using the session's started_at as the occurred_at timestamp. The idempotency
-- key is identical in format so future re-runs are safe.

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
  COALESCE(ws.finished_at, ws.started_at, NOW())
FROM public.workout_sessions ws
WHERE EXISTS (
  SELECT 1 FROM public.session_exercises se WHERE se.session_id = ws.id
)
ON CONFLICT (idempotency_key) DO NOTHING;

-- ─── Recompute aggregates for every user+gym with xp_events ──────────────────

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
