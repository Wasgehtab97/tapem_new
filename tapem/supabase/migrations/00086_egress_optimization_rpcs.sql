-- =============================================================================
-- Tap'em — 00086: Egress optimisation RPCs
-- Date: 2026-04-04
--
-- Replaces high-egress client-side nested-join queries with slim server-side
-- aggregate functions.  Before this migration the Flutter app fetched up to
-- 1 000 workout sessions × nested exercises × sets on every progress-screen
-- open or post-workout sync (~200–750 KB/call × many calls/day).
--
-- Changes:
--   1. get_user_equipment_xp_summary   — replaces 250/1000-row session join
--      in localXpBaseProvider (~4 KB vs ~80 KB).
--   2. get_user_exercise_performance_summary — replaces 250/1000-row nested
--      set-data join in progressPerformanceExercisesProvider (~50 KB vs ~250 KB).
--   3. get_gym_leaderboard updated to include avatar_url — eliminates the
--      secondary user_profiles fetch in gymLeaderboardProvider (~15 KB saved).
-- =============================================================================

-- =============================================================================
-- 1. get_user_equipment_xp_summary
-- =============================================================================
-- Returns pre-aggregated equipment/exercise XP straight from user_exercise_xp,
-- joined with gym_equipment to resolve the display key used by the Flutter
-- client (equipment_id UUID for fixed machines, exercise_key text for others).
--
-- Replaces the Flutter call that fetched workout_sessions(session_exercises)
-- with LIMIT 250 or 1000 just to count sessions-per-exercise for XP approximation.
-- The user_exercise_xp table already holds the exact confirmed totals.
--
-- Security: auth.uid() = p_user_id enforced in WHERE clause.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_user_equipment_xp_summary(
  p_user_id UUID,
  p_gym_id  UUID
)
RETURNS TABLE (
  exercise_key   TEXT,
  equipment_id   UUID,
  equipment_name TEXT,
  total_xp       INTEGER,
  current_level  SMALLINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  -- Security guard: a user may only query their own XP.
  -- Returns 0 rows for any request where p_user_id ≠ the authenticated caller.
  SELECT
    uex.exercise_key,
    ge.id           AS equipment_id,   -- NULL for freeform / custom exercises
    ge.name         AS equipment_name,
    uex.total_xp,
    uex.current_level
  FROM public.user_exercise_xp uex
  LEFT JOIN public.gym_equipment ge
    ON  ge.canonical_exercise_key = uex.exercise_key
    AND ge.gym_id                 = p_gym_id
    AND ge.is_active              = TRUE
  WHERE uex.user_id = p_user_id
    AND uex.gym_id  = p_gym_id
    AND auth.uid()  = p_user_id   -- callers cannot query other users' XP
    AND uex.total_xp > 0
  ORDER BY uex.total_xp DESC;
$$;

COMMENT ON FUNCTION public.get_user_equipment_xp_summary IS
  'Returns confirmed server XP per exercise/equipment for a single user. '
  'Joins user_exercise_xp with gym_equipment to expose the equipment_id '
  'display key used by the Flutter XP map. Replaces a 250/1000-row '
  'nested workout_sessions join (~4 KB vs ~80 KB).';

GRANT EXECUTE ON FUNCTION public.get_user_equipment_xp_summary(UUID, UUID)
  TO authenticated;


-- =============================================================================
-- 2. get_user_exercise_performance_summary
-- =============================================================================
-- Returns the best e1rm set per (exercise_key, session_day_anchor) for a user.
-- The Flutter progress chart (ProgressPerformanceExercise) needs a time-series
-- of best e1rm values per exercise — previously fetched as a 3-level nested
-- JSON join (sessions → exercises → sets) with up to 1 000 session rows.
--
-- This RPC pushes the aggregation to the database:
--   • Typical result: ~30 exercises × ~20 training days ≈ 600 rows × ~80 bytes
--     ≈ ~50 KB  (was 250 sessions × 5 exercises × 5 sets × 40 bytes ≈ 250 KB).
--   • On reinstall path (no local SQLite): same 50 KB vs previous 750 KB.
--
-- Cardio exercises (exercise_key LIKE 'cardio:%') are excluded — the progress
-- chart only renders strength exercises.
--
-- Security: auth.uid() = p_user_id enforced in WHERE clause.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_user_exercise_performance_summary(
  p_user_id UUID,
  p_gym_id  UUID
)
RETURNS TABLE (
  exercise_key       TEXT,
  display_name       TEXT,
  session_day_anchor DATE,
  best_e1rm          NUMERIC(8,2),
  best_weight_kg     NUMERIC(6,2),
  best_reps          SMALLINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  -- Security guard: callers cannot query other users' data.
  SELECT
    se.exercise_key,
    -- Most-recent display_name wins (name may be refined over time).
    (array_agg(se.display_name ORDER BY ws.finished_at DESC NULLS LAST))[1]  AS display_name,
    ws.session_day_anchor,
    -- Best (highest) e1rm for this exercise on this day.
    ROUND(
      MAX(entry.weight_kg * (1.0 + entry.reps::NUMERIC / 30.0)),
      2
    )                                                                          AS best_e1rm,
    -- Weight and reps from the set that produced the best e1rm.
    (array_agg(
       entry.weight_kg
       ORDER BY entry.weight_kg * (1.0 + entry.reps::NUMERIC / 30.0) DESC NULLS LAST
    ))[1]                                                                      AS best_weight_kg,
    (array_agg(
       entry.reps
       ORDER BY entry.weight_kg * (1.0 + entry.reps::NUMERIC / 30.0) DESC NULLS LAST
    ))[1]::SMALLINT                                                            AS best_reps
  FROM public.set_entries entry
  JOIN public.session_exercises se
    ON  se.id           = entry.session_exercise_id
    AND se.gym_id       = p_gym_id
    AND se.exercise_key NOT LIKE 'cardio:%'   -- strength only
  JOIN public.workout_sessions ws
    ON  ws.id          = se.session_id
    AND ws.gym_id      = p_gym_id
    AND ws.user_id     = p_user_id
    AND ws.finished_at IS NOT NULL
  WHERE entry.reps      > 0
    AND entry.weight_kg > 0
    AND entry.gym_id    = p_gym_id
    AND auth.uid()      = p_user_id   -- callers cannot query other users' data
  GROUP BY se.exercise_key, ws.session_day_anchor
  ORDER BY se.exercise_key, ws.session_day_anchor;
$$;

COMMENT ON FUNCTION public.get_user_exercise_performance_summary IS
  'Returns best e1rm set per (exercise, training day) for a single user. '
  'Used by the Flutter progress chart to build strength trend curves. '
  'Replaces a 250/1000-row nested workout_sessions→exercises→sets JSON join '
  '(~50 KB vs ~250 KB on the normal path, ~50 KB vs ~750 KB on reinstall).';

GRANT EXECUTE ON FUNCTION public.get_user_exercise_performance_summary(UUID, UUID)
  TO authenticated;


-- =============================================================================
-- 3. Update get_gym_leaderboard — add avatar_url to result set
-- =============================================================================
-- Eliminates the secondary user_profiles SELECT that the Flutter client issued
-- after every leaderboard call to resolve avatar_url per user.
-- With ~50 members, that secondary call cost ~15 KB per leaderboard load, and
-- was triggered on every post-workout sync.
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_gym_leaderboard(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.get_gym_leaderboard(
  p_gym_id UUID,
  p_axis   TEXT DEFAULT 'training_day'
)
RETURNS TABLE (
  rank             BIGINT,
  user_id          UUID,
  username         TEXT,
  avatar_url       TEXT,
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
  -- Only for users with no xp_events and no aggregate row.
  -- Seed / demo sessions (notes LIKE 'seed:%') are excluded.
  xp_from_sessions AS (
    SELECT
      ws.user_id,
      (COUNT(DISTINCT COALESCE(ws.session_day_anchor::TEXT,
                               ws.started_at::DATE::TEXT)) * 25)::INTEGER AS total_xp
    FROM public.workout_sessions ws
    WHERE ws.gym_id    = p_gym_id
      AND p_axis       = 'training_day'
      AND (ws.notes IS NULL OR ws.notes NOT LIKE 'seed:%')
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
      up.avatar_url,                                  -- added: avoids secondary Flutter fetch
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
    lb.avatar_url,
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
  '(3) workout_sessions fallback (real sessions only). '
  'Now includes avatar_url to eliminate a secondary user_profiles fetch. '
  'Respects privacy_level.';

GRANT EXECUTE ON FUNCTION public.get_gym_leaderboard(UUID, TEXT)
  TO authenticated;
