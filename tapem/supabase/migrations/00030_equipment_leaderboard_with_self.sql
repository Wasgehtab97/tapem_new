-- =============================================================================
-- Tap'em — 00030: Equipment overview with own XP + per-equipment leaderboard
--
-- Changes:
--   1. get_gym_equipment_overview: add p_user_id parameter and return
--      my_xp / my_level so the client can show the user's own standing
--      on each machine alongside the top athlete — without a second RPC call.
--   2. get_equipment_leaderboard: new function — returns ALL gym members
--      ranked by XP on one specific machine. Powers the drill-down sheet
--      opened when the user taps an equipment row.
-- =============================================================================

-- ─── 1. Rebuild get_gym_equipment_overview with user-specific stats ───────────
-- Signature changed (+ p_user_id, + my_xp, + my_level) so DROP + CREATE.

DROP FUNCTION IF EXISTS public.get_gym_equipment_overview(UUID);

CREATE FUNCTION public.get_gym_equipment_overview(
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

  -- ── XP per user per equipment (direct column — no joins) ──────────────────
  equipment_user_xp AS (
    SELECT
      xe.equipment_id,
      xe.user_id,
      SUM(xe.xp_amount)::INTEGER AS total_xp
    FROM public.xp_events xe
    WHERE xe.gym_id       = p_gym_id
      AND xe.axis::TEXT   = 'exercise_equipment'
      AND xe.equipment_id IS NOT NULL
    GROUP BY xe.equipment_id, xe.user_id
  ),

  -- ── Rank users per equipment ──────────────────────────────────────────────
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

  -- ── Current user's XP per equipment ──────────────────────────────────────
  my_xp AS (
    SELECT
      equipment_id,
      total_xp,
      public.xp_to_level(total_xp)::SMALLINT AS lv
    FROM equipment_user_xp
    WHERE user_id = p_user_id
  )

  SELECT
    ge.id                    AS equipment_id,
    ge.name                  AS equipment_name,
    r.user_id                AS top_user_id,
    up.username              AS top_username,
    r.total_xp               AS top_xp,
    r.lv                     AS top_level,
    COALESCE(r.cnt, 0)       AS distinct_users,
    COALESCE(mx.total_xp, 0) AS my_xp,
    COALESCE(mx.lv,       1) AS my_level
  FROM public.gym_equipment ge
  LEFT JOIN ranked r
         ON r.equipment_id = ge.id AND r.rn = 1
  LEFT JOIN public.user_profiles up
         ON up.id = r.user_id
        AND (up.privacy_level IS NULL OR up.privacy_level::TEXT != 'private')
  LEFT JOIN my_xp mx ON mx.equipment_id = ge.id
  WHERE ge.gym_id    = p_gym_id
    AND ge.is_active = true
  ORDER BY
    COALESCE(r.total_xp, -1) DESC,  -- machines with any XP first
    ge.name ASC
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_gym_equipment_overview IS
  'Per-machine overview with top athlete and current-user stats. '
  'Always returns all active gym machines; my_xp = 0 when user has not '
  'trained on a machine yet. top_user_id NULL when no one has trained.';

GRANT EXECUTE ON FUNCTION public.get_gym_equipment_overview(UUID, UUID)
  TO authenticated;

-- ─── 2. New: per-equipment full leaderboard ───────────────────────────────────
-- Returns every gym member who has XP on this specific machine, ranked.
-- Powers the drill-down sheet opened by tapping an equipment row.

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
   AND (up.privacy_level IS NULL OR up.privacy_level::TEXT != 'private')
  ORDER BY rank, up.username
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_equipment_leaderboard IS
  'Full ranked leaderboard for one specific gym machine. '
  'Returns only athletes who have exercise_equipment XP on that machine.';

GRANT EXECUTE ON FUNCTION public.get_equipment_leaderboard(UUID, UUID)
  TO authenticated;
