-- =============================================================================
-- Tap'em — 00028: Equipment overview anchored on gym_equipment table
--
-- Problem (migration 00027 version):
--   get_gym_equipment_overview only returned rows from xp_events — so if no
--   exercise_equipment XP exists yet, the list was empty. This made the
--   EQUIPMENT XP tab show "Noch keine Daten" even though equipment is
--   configured in the gym.
--
-- Fix:
--   Anchor on gym_equipment (all active machines), LEFT JOIN to xp_events via
--   session_exercises → workout_sessions to find per-machine XP. Every machine
--   always appears; top_user_id / top_xp are NULL when no one has trained yet.
--   Machines with any XP sort first (by highest XP); untrained machines sort
--   alphabetically after.
-- =============================================================================

-- Return type changed (exercise_key → equipment_id + equipment_name):
-- must DROP and re-CREATE; CREATE OR REPLACE cannot change return columns.
DROP FUNCTION IF EXISTS public.get_gym_equipment_overview(UUID);

CREATE FUNCTION public.get_gym_equipment_overview(p_gym_id UUID)
RETURNS TABLE (
  equipment_id   UUID,
  equipment_name TEXT,
  top_user_id    UUID,
  top_username   TEXT,
  top_xp         INTEGER,
  top_level      SMALLINT,
  distinct_users INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH

  -- ── XP per user per equipment ─────────────────────────────────────────────
  -- xp_events.source_id = session_exercises.id for exercise_equipment axis.
  -- Join through to workout_sessions to get the equipment_id.
  equipment_user_xp AS (
    SELECT
      ws.equipment_id,
      xe.user_id,
      SUM(xe.xp_amount)::INTEGER AS total_xp
    FROM public.xp_events xe
    JOIN public.session_exercises se
         ON se.id          = xe.source_id
        AND xe.source_type  = 'session_exercise'
    JOIN public.workout_sessions ws
         ON ws.id           = se.session_id
        AND ws.equipment_id IS NOT NULL
    WHERE xe.gym_id      = p_gym_id
      AND xe.axis::TEXT  = 'exercise_equipment'
    GROUP BY ws.equipment_id, xe.user_id
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
  )

  -- ── All active machines LEFT JOIN top user ────────────────────────────────
  SELECT
    ge.id                   AS equipment_id,
    ge.name                 AS equipment_name,
    r.user_id               AS top_user_id,
    up.username             AS top_username,
    r.total_xp              AS top_xp,
    r.lv                    AS top_level,
    COALESCE(r.cnt, 0)      AS distinct_users
  FROM public.gym_equipment ge
  LEFT JOIN ranked r
         ON r.equipment_id = ge.id
        AND r.rn           = 1
  LEFT JOIN public.user_profiles up
         ON up.id = r.user_id
        AND (up.privacy_level IS NULL OR up.privacy_level::TEXT != 'private')
  WHERE ge.gym_id    = p_gym_id
    AND ge.is_active = true
  ORDER BY
    COALESCE(r.total_xp, -1) DESC,   -- trained machines first, sorted by top XP
    ge.name ASC                        -- untrained machines: alphabetical
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_gym_equipment_overview IS
  'Per-machine leaderboard. Returns ALL active gym equipment for the gym. '
  'top_user_id / top_xp are NULL for machines no one has trained on yet. '
  'Trained machines appear first (highest top XP), untrained machines '
  'appear alphabetically after. Never returns empty for a configured gym.';

GRANT EXECUTE ON FUNCTION public.get_gym_equipment_overview(UUID)
  TO authenticated;
