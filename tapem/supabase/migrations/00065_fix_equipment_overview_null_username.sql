-- =============================================================================
-- Tap'em — 00065: Fix @null top athlete in equipment overview / leaderboard
--
-- Root cause:
--   get_gym_equipment_overview used a LEFT JOIN to user_profiles with the
--   privacy filter in the ON clause.  When the rank-#1 user is private OR
--   has a NULL username, the LEFT JOIN still returns that user's row (so
--   top_user_id is non-null) but with top_username = NULL → the client
--   renders "@null".
--
-- Fix:
--   Introduce a `public_users` CTE that pre-filters to users who have a
--   non-null username AND are not private.  Only those users participate in
--   the equipment_user_xp ranking, so the top_user_id returned always
--   corresponds to a displayable user.  The current user's own XP is kept
--   in a separate CTE so private self-XP still shows to the user themselves.
--
--   Same fix applied to get_equipment_leaderboard (already used INNER JOIN
--   but was missing the username IS NOT NULL guard).
-- =============================================================================

-- ─── 1. Rebuild get_gym_equipment_overview ────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_gym_equipment_overview(
  p_gym_id  UUID,
  p_user_id UUID
)
RETURNS TABLE (
  equipment_id   UUID,
  equipment_name TEXT,
  top_user_id    UUID,
  top_username   TEXT,
  top_xp         INTEGER,
  top_level      SMALLINT,
  distinct_users INTEGER,
  my_xp          INTEGER,
  my_level       SMALLINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH

  -- ── Only users that can be shown publicly ─────────────────────────────────
  -- username IS NOT NULL guards against accounts created outside the app flow.
  -- privacy_level filter hides users who opted out of leaderboards.
  public_users AS (
    SELECT id, username
    FROM public.user_profiles
    WHERE username IS NOT NULL
      AND (privacy_level IS NULL OR privacy_level::TEXT != 'private')
  ),

  -- ── XP per PUBLIC user per equipment ─────────────────────────────────────
  -- Joining public_users here means private / nameless users are excluded
  -- from the ranking entirely — the next eligible user becomes #1.
  equipment_user_xp AS (
    SELECT
      xe.equipment_id,
      xe.user_id,
      SUM(xe.xp_amount)::INTEGER AS total_xp
    FROM public.xp_events xe
    JOIN public_users pu ON pu.id = xe.user_id
    WHERE xe.gym_id       = p_gym_id
      AND xe.axis::TEXT   = 'exercise_equipment'
      AND xe.equipment_id IS NOT NULL
    GROUP BY xe.equipment_id, xe.user_id
  ),

  -- ── Rank public users per equipment ──────────────────────────────────────
  ranked AS (
    SELECT
      equipment_id,
      user_id,
      total_xp,
      public.xp_to_level(total_xp)::SMALLINT                        AS lv,
      RANK() OVER (PARTITION BY equipment_id ORDER BY total_xp DESC) AS rn,
      COUNT(*) OVER (PARTITION BY equipment_id)::INTEGER             AS cnt
    FROM equipment_user_xp
  ),

  -- ── Current user's own XP — computed independently so it always shows ────
  -- regardless of the user's own privacy setting (you always see yourself).
  my_xp AS (
    SELECT
      xe.equipment_id,
      SUM(xe.xp_amount)::INTEGER                                    AS total_xp,
      public.xp_to_level(SUM(xe.xp_amount)::INTEGER)::SMALLINT     AS lv
    FROM public.xp_events xe
    WHERE xe.gym_id       = p_gym_id
      AND xe.axis::TEXT   = 'exercise_equipment'
      AND xe.equipment_id IS NOT NULL
      AND xe.user_id      = p_user_id
    GROUP BY xe.equipment_id
  )

  SELECT
    ge.id                    AS equipment_id,
    ge.name                  AS equipment_name,
    r.user_id                AS top_user_id,
    pu.username              AS top_username,   -- always non-null when r.user_id set
    r.total_xp               AS top_xp,
    r.lv                     AS top_level,
    COALESCE(r.cnt, 0)       AS distinct_users,
    COALESCE(mx.total_xp, 0) AS my_xp,
    COALESCE(mx.lv,       1) AS my_level
  FROM public.gym_equipment ge
  LEFT JOIN ranked r
         ON r.equipment_id = ge.id AND r.rn = 1
  LEFT JOIN public_users pu
         ON pu.id = r.user_id
  LEFT JOIN my_xp mx ON mx.equipment_id = ge.id
  WHERE ge.gym_id    = p_gym_id
    AND ge.is_active = true
  ORDER BY
    COALESCE(r.total_xp, -1) DESC,  -- machines with any XP first
    ge.name ASC
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_gym_equipment_overview IS
  'Per-machine overview with top PUBLIC athlete and current-user stats. '
  'Private users and users without a username are excluded from the top-athlete '
  'slot so the client never receives a null username. Returns all active machines.';

GRANT EXECUTE ON FUNCTION public.get_gym_equipment_overview(UUID, UUID)
  TO authenticated;

-- ─── 2. Rebuild get_equipment_leaderboard ────────────────────────────────────
-- Add username IS NOT NULL guard (was missing — could show null usernames
-- in the per-machine drill-down sheet for users who bypassed onboarding).

CREATE OR REPLACE FUNCTION public.get_equipment_leaderboard(
  p_gym_id       UUID,
  p_equipment_id UUID
)
RETURNS TABLE (
  rank             BIGINT,
  user_id          UUID,
  username         TEXT,
  total_xp         INTEGER,
  current_level    SMALLINT,
  xp_to_next_level INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH per_user AS (
    SELECT
      user_id,
      SUM(xp_amount)::INTEGER AS total_xp
    FROM public.xp_events
    WHERE gym_id        = p_gym_id
      AND axis::TEXT    = 'exercise_equipment'
      AND equipment_id  = p_equipment_id
    GROUP BY user_id
  )
  SELECT
    RANK() OVER (ORDER BY pu.total_xp DESC)::BIGINT AS rank,
    pu.user_id,
    up.username,
    pu.total_xp,
    public.xp_to_level(pu.total_xp)::SMALLINT        AS current_level,
    public.xp_needed_for_next_level(pu.total_xp)     AS xp_to_next_level
  FROM per_user pu
  JOIN public.user_profiles up
    ON up.id = pu.user_id
   AND up.username IS NOT NULL
   AND (up.privacy_level IS NULL OR up.privacy_level::TEXT != 'private')
  ORDER BY rank, up.username
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_equipment_leaderboard IS
  'Full ranked leaderboard for one specific gym machine. '
  'Returns only athletes with a public, non-null username.';

GRANT EXECUTE ON FUNCTION public.get_equipment_leaderboard(UUID, UUID)
  TO authenticated;
