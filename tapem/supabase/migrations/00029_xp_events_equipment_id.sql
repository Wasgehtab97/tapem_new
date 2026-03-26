-- =============================================================================
-- Tap'em — 00029: Add equipment_id to xp_events (systemic attribution fix)
--
-- Root cause of fragile equipment XP queries:
--   xp_events for the exercise_equipment axis stores exercise_key and
--   source_id (= session_exercises.id) but NOT equipment_id. Any query that
--   wants to group XP by piece of equipment must join:
--     xp_events → session_exercises → workout_sessions → gym_equipment
--   This 3-table join breaks whenever any link is missing:
--     • session_exercises rows not yet synced
--     • workout_sessions.equipment_id is NULL (post-26 relaxation) or stale
--     • xp_events created through a different code path (manual, migration)
--
-- Fix:
--   Store equipment_id directly on xp_events for exercise_equipment axis.
--   Events become self-contained; no cross-table joins needed for attribution.
--   This follows the event-sourcing principle: an event carries all context
--   needed to interpret it, even if related rows are later modified or deleted.
--
-- Steps:
--   1. Add nullable equipment_id column to xp_events.
--   2. Backfill existing exercise_equipment events via the join (best-effort).
--   3. Replace get_gym_equipment_overview with a simpler direct-column query.
-- =============================================================================

-- ─── Step 1: Add equipment_id column ─────────────────────────────────────────

ALTER TABLE public.xp_events
  ADD COLUMN IF NOT EXISTS equipment_id UUID;
-- Intentionally no FK — equipment_id may reference machines that were deleted
-- or seeded with different UUIDs after a DB reset. We treat it as an opaque
-- label, not a relational constraint.

COMMENT ON COLUMN public.xp_events.equipment_id IS
  'For exercise_equipment axis: the gym_equipment.id that the session was '
  'performed on. Stored denormalised so queries never need to join through '
  'session_exercises → workout_sessions. NULL for training_day / muscle_group '
  'axes, and for legacy events created before this migration.';

-- ─── Step 2: Backfill existing events (best-effort) ──────────────────────────
-- For exercise_equipment events already in the table, try to recover
-- equipment_id via session_exercises.session_id → workout_sessions.equipment_id.
-- Rows where the join fails (stale UUIDs, missing session_exercises) remain NULL.

UPDATE public.xp_events xe
SET    equipment_id = ws.equipment_id
FROM   public.session_exercises se
JOIN   public.workout_sessions  ws ON ws.id = se.session_id
                                   AND ws.equipment_id IS NOT NULL
WHERE  xe.source_id    = se.id
  AND  xe.source_type  = 'session_exercise'
  AND  xe.axis::TEXT   = 'exercise_equipment'
  AND  xe.equipment_id IS NULL;

-- ─── Step 3: Replace get_gym_equipment_overview ───────────────────────────────
-- New version groups directly on xp_events.equipment_id — no session joins.

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

  -- ── XP per user per equipment — pure xp_events scan, no joins ────────────
  equipment_user_xp AS (
    SELECT
      xe.equipment_id,
      xe.user_id,
      SUM(xe.xp_amount)::INTEGER AS total_xp
    FROM public.xp_events xe
    WHERE xe.gym_id        = p_gym_id
      AND xe.axis::TEXT    = 'exercise_equipment'
      AND xe.equipment_id  IS NOT NULL
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
  )

  -- ── All active machines LEFT JOIN top user ────────────────────────────────
  -- Every machine always appears; top_user_id is NULL if no one trained yet.
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
        AND r.rn            = 1
  LEFT JOIN public.user_profiles up
         ON up.id = r.user_id
        AND (up.privacy_level IS NULL OR up.privacy_level::TEXT != 'private')
  WHERE ge.gym_id    = p_gym_id
    AND ge.is_active = true
  ORDER BY
    COALESCE(r.total_xp, -1) DESC,  -- machines with XP first
    ge.name ASC                       -- untrained machines: alphabetical
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_gym_equipment_overview IS
  'Per-machine leaderboard. Sources XP directly from xp_events.equipment_id '
  '(denormalised, no cross-table joins). Always returns all active gym machines. '
  'top_user_id is NULL for untrained machines. Respects privacy_level.';

GRANT EXECUTE ON FUNCTION public.get_gym_equipment_overview(UUID)
  TO authenticated;
