-- =============================================================================
-- Tap'em — 00041: Exclude seed sessions from leaderboard XP fallback
--
-- Root cause: get_gym_leaderboard has an xp_from_sessions fallback that
-- counts workout_sessions directly (25 XP per unique day) for users who
-- have no xp_events. After migration 00040 seeded 107 workout_sessions for
-- admin_test, the fallback computed 107 × 25 = 2,675 XP even though no real
-- XP events exist.
--
-- Fix: add a NOT LIKE 'seed:%' guard on the notes column so seeded demo
-- sessions are never counted towards leaderboard XP. Real sessions always
-- have notes = NULL, so no real data is affected.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_gym_leaderboard(
  p_gym_id UUID,
  p_axis   TEXT DEFAULT 'training_day'
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

  -- ── All active gym members ────────────────────────────────────────────────
  members AS (
    SELECT m.user_id
    FROM   public.memberships m
    WHERE  m.gym_id    = p_gym_id
      AND  m.is_active = true
  ),

  -- ── XP from xp_events (primary) ──────────────────────────────────────────
  xp_from_events AS (
    SELECT
      xe.user_id,
      SUM(xe.xp_amount)::INTEGER AS total_xp
    FROM public.xp_events xe
    WHERE xe.gym_id     = p_gym_id
      AND xe.axis::TEXT = p_axis
    GROUP BY xe.user_id
  ),

  -- ── XP from user_gym_xp aggregate (fast path) ────────────────────────────
  xp_from_agg AS (
    SELECT
      ugx.user_id,
      ugx.total_xp
    FROM public.user_gym_xp ugx
    WHERE ugx.gym_id   = p_gym_id
      AND ugx.total_xp > 0
      AND p_axis = 'training_day'
  ),

  -- ── XP from workout_sessions fallback (25 XP per unique training day) ─────
  -- Only used for users with no xp_events and no aggregate row.
  -- Seed / demo sessions (notes LIKE 'seed:%') are excluded so that
  -- artificially inserted calendar data never inflates leaderboard XP.
  xp_from_sessions AS (
    SELECT
      ws.user_id,
      (COUNT(DISTINCT COALESCE(ws.session_day_anchor::TEXT,
                               ws.started_at::DATE::TEXT)) * 25)::INTEGER AS total_xp
    FROM public.workout_sessions ws
    WHERE ws.gym_id    = p_gym_id
      AND p_axis       = 'training_day'
      AND (ws.notes IS NULL OR ws.notes NOT LIKE 'seed:%')   -- ← new guard
      AND ws.user_id NOT IN (SELECT xf.user_id FROM xp_from_events xf)
      AND ws.user_id NOT IN (SELECT xa.user_id FROM xp_from_agg  xa)
    GROUP BY ws.user_id
  ),

  -- ── Merge all XP sources ──────────────────────────────────────────────────
  merged_xp AS (
    SELECT user_id, total_xp FROM xp_from_events WHERE total_xp > 0
    UNION ALL
    SELECT user_id, total_xp FROM xp_from_agg
      WHERE user_id NOT IN (SELECT user_id FROM xp_from_events)
    UNION ALL
    SELECT user_id, total_xp FROM xp_from_sessions WHERE total_xp > 0
  ),

  -- ── Best XP per user ──────────────────────────────────────────────────────
  best_xp AS (
    SELECT user_id, MAX(total_xp)::INTEGER AS total_xp
    FROM   merged_xp
    GROUP  BY user_id
  ),

  -- ── Join members with XP ──────────────────────────────────────────────────
  leaderboard AS (
    SELECT
      up.id                                           AS user_id,
      up.username,
      COALESCE(bx.total_xp, 0)                       AS total_xp,
      public.xp_to_level(COALESCE(bx.total_xp, 0))  AS current_level,
      COALESCE(bx.total_xp / 25, 0)                  AS training_days,
      public.xp_needed_for_next_level(
        COALESCE(bx.total_xp, 0)
      )                                               AS xp_to_next_level
    FROM members m
    JOIN public.user_profiles up ON up.id = m.user_id
    LEFT JOIN best_xp bx           ON bx.user_id = m.user_id
    WHERE (up.privacy_level IS NULL OR up.privacy_level::TEXT != 'private')
  )

  SELECT
    RANK() OVER (ORDER BY lb.total_xp DESC)::BIGINT AS rank,
    lb.user_id,
    lb.username,
    lb.total_xp,
    lb.current_level,
    lb.training_days,
    lb.xp_to_next_level
  FROM leaderboard lb
  ORDER BY rank, lb.username
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_gym_leaderboard IS
  'Membership-anchored leaderboard. Awards 25 XP per training day. XP sources '
  'in priority order: (1) xp_events, (2) user_gym_xp aggregate, '
  '(3) workout_sessions fallback (real sessions only — notes LIKE ''seed:%'' excluded). '
  'Never returns empty for a gym with at least one active member. '
  'Respects privacy_level.';

GRANT EXECUTE ON FUNCTION public.get_gym_leaderboard(UUID, TEXT)
  TO authenticated;
