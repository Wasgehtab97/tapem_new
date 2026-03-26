-- =============================================================================
-- Tap'em — 00024: Membership-Based Leaderboard
--
-- Root cause of persistent empty leaderboard:
--   workouts_sessions and xp_events on Supabase are EMPTY because the
--   sync-workout / finish-session Edge Function has not run successfully yet.
--   Workouts exist only in Drift (local SQLite) on the device. All previous
--   session-based fallbacks fail because there is nothing to fall back to.
--
-- Fix: anchor the leaderboard on the `memberships` table instead of on
-- xp_events / workout_sessions. Every user who has an active gym membership
-- is listed. Their XP is pulled from user_gym_xp where it exists; users
-- without any XP appear at rank = (number of users with XP + 1) with 0 XP
-- and Level 1.
--
-- Result: the leaderboard is NEVER empty. As soon as sync runs and XP is
-- awarded, the user climbs the board in real-time (pull-to-refresh).
-- =============================================================================

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

  -- ── All active gym members (source of truth for "who is in this gym") ────
  members AS (
    SELECT m.user_id
    FROM   public.memberships m
    WHERE  m.gym_id    = p_gym_id
      AND  m.is_active = true
  ),

  -- ── XP from xp_events (primary — populated after first sync) ─────────────
  xp_from_events AS (
    SELECT
      xe.user_id,
      SUM(xe.xp_amount)::INTEGER AS total_xp
    FROM public.xp_events xe
    WHERE xe.gym_id     = p_gym_id
      AND xe.axis::TEXT = p_axis
    GROUP BY xe.user_id
  ),

  -- ── XP from user_gym_xp materialised view (fast path when populated) ─────
  xp_from_agg AS (
    SELECT
      ugx.user_id,
      ugx.total_xp
    FROM public.user_gym_xp ugx
    WHERE ugx.gym_id = p_gym_id
      AND ugx.total_xp > 0
      AND p_axis = 'training_day'        -- user_gym_xp is training_day axis
  ),

  -- ── XP from workout_sessions fallback (for sessions not yet in xp_events) ─
  xp_from_sessions AS (
    SELECT
      ws.user_id,
      (COUNT(DISTINCT COALESCE(ws.session_day_anchor::TEXT, ws.started_at::DATE::TEXT)) * 100)::INTEGER AS total_xp
    FROM public.workout_sessions ws
    WHERE ws.gym_id    = p_gym_id
      AND p_axis       = 'training_day'
      AND ws.user_id NOT IN (SELECT xf.user_id FROM xp_from_events xf)
      AND ws.user_id NOT IN (SELECT xa.user_id FROM xp_from_agg  xa)
    GROUP BY ws.user_id
  ),

  -- ── Merge all XP sources, keep best value per user ────────────────────────
  merged_xp AS (
    -- From xp_events (primary)
    SELECT user_id, total_xp FROM xp_from_events WHERE total_xp > 0
    UNION ALL
    -- From materialized aggregate (covers when events exist but table wasn't in primary CTE)
    SELECT user_id, total_xp FROM xp_from_agg
      WHERE user_id NOT IN (SELECT user_id FROM xp_from_events)
    UNION ALL
    -- From session-based computation
    SELECT user_id, total_xp FROM xp_from_sessions WHERE total_xp > 0
  ),

  -- ── Deduplicate: keep max XP per user across all sources ──────────────────
  best_xp AS (
    SELECT user_id, MAX(total_xp)::INTEGER AS total_xp
    FROM   merged_xp
    GROUP  BY user_id
  ),

  -- ── Join members with their XP (0 for members who haven't trained yet) ────
  leaderboard AS (
    SELECT
      up.id                                           AS user_id,
      up.username,
      COALESCE(bx.total_xp, 0)                       AS total_xp,
      public.xp_to_level(COALESCE(bx.total_xp, 0))  AS current_level,
      COALESCE(bx.total_xp / 100, 0)                 AS training_days,
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
  ORDER BY rank, lb.username    -- stable secondary sort by username for ties
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_gym_leaderboard IS
  'Membership-anchored leaderboard. Shows ALL active gym members regardless '
  'of whether they have synced workouts yet. XP sources in priority order: '
  '(1) xp_events, (2) user_gym_xp aggregate, (3) workout_sessions fallback. '
  'Members with 0 XP appear at the bottom. Never returns empty for a gym '
  'that has at least one active member. Respects privacy_level.';

GRANT EXECUTE ON FUNCTION public.get_gym_leaderboard(UUID, TEXT)
  TO authenticated;
