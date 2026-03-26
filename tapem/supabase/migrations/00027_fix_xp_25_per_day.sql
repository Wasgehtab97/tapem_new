-- =============================================================================
-- Tap'em — 00027: Unify training_day XP to 25 per day
--
-- Root cause:
--   Migration 00026 inserted placeholder XP events using 100 XP/day (the old
--   value). The canonical award is 25 XP per training day across all surfaces:
--   Flutter (XpRules.trainingDayBase), Edge Functions (XP_TRAINING_DAY), and
--   SQL (this migration). This migration:
--
--   1. Corrects the placeholder events from migration 00026 (100→25 for
--      ironbronz, 200→50 for ironwood) by updating xp_amount in xp_events.
--   2. Updates get_gym_leaderboard to use 25 XP/day instead of 100 for the
--      workout_sessions fallback calculation and the training_days divisor.
--   3. Adds get_gym_equipment_overview RPC — returns per-exercise top-user
--      data for the EQUIPMENT XP scrollable list in the community screen.
--   4. Recomputes user_gym_xp for all affected users.
-- =============================================================================

-- ─── Fix 1a: Correct ironbronz placeholder XP (100 → 25) ─────────────────────

DO $$
DECLARE
  v_user_id UUID;
  v_gym_id  UUID := 'a0000000-0000-0000-0000-000000000001';
BEGIN
  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE LOWER(username) = 'ironbronz'
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE NOTICE '00027: ironbronz not found — skipping correction';
    RETURN;
  END IF;

  UPDATE public.xp_events
  SET    xp_amount = 25
  WHERE  user_id  = v_user_id
    AND  gym_id   = v_gym_id
    AND  axis::TEXT = 'training_day'
    AND  xp_amount  = 100;

  RAISE NOTICE '00027: corrected ironbronz training_day XP rows to 25';
END;
$$;

-- ─── Fix 1b: Correct ironwood placeholder XP (100 → 25 per row) ──────────────

DO $$
DECLARE
  v_user_id UUID;
  v_gym_id  UUID := 'a0000000-0000-0000-0000-000000000001';
BEGIN
  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE LOWER(username) = 'ironwood'
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE NOTICE '00027: ironwood not found — skipping correction';
    RETURN;
  END IF;

  UPDATE public.xp_events
  SET    xp_amount = 25
  WHERE  user_id   = v_user_id
    AND  gym_id    = v_gym_id
    AND  axis::TEXT = 'training_day'
    AND  xp_amount  = 100;

  RAISE NOTICE '00027: corrected ironwood training_day XP rows to 25';
END;
$$;

-- ─── Fix 2: Update get_gym_leaderboard — 25 XP/day multiplier and divisor ────
-- The workout_sessions fallback computed (distinct training days * 100).
-- The training_days column divided total_xp by 100.
-- Both must use 25 to stay in sync with the canonical award amount.

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

  -- ── XP from workout_sessions fallback (25 XP per unique training day) ────
  xp_from_sessions AS (
    SELECT
      ws.user_id,
      (COUNT(DISTINCT COALESCE(ws.session_day_anchor::TEXT, ws.started_at::DATE::TEXT)) * 25)::INTEGER AS total_xp
    FROM public.workout_sessions ws
    WHERE ws.gym_id    = p_gym_id
      AND p_axis       = 'training_day'
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
  '(3) workout_sessions fallback. Never returns empty for a gym with at least '
  'one active member. Respects privacy_level.';

GRANT EXECUTE ON FUNCTION public.get_gym_leaderboard(UUID, TEXT)
  TO authenticated;

-- ─── Fix 3: Add get_gym_equipment_overview RPC ────────────────────────────────
-- Returns one row per exercise_key in this gym: the top user (by total XP on
-- that exercise) plus the count of distinct athletes who have any XP on it.
-- Used by the EQUIPMENT XP scrollable list in the community screen.

CREATE OR REPLACE FUNCTION public.get_gym_equipment_overview(p_gym_id UUID)
RETURNS TABLE (
  exercise_key   TEXT,
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
  WITH per_user_exercise AS (
    SELECT
      xe.exercise_key,
      xe.user_id,
      SUM(xe.xp_amount)::INTEGER AS total_xp
    FROM public.xp_events xe
    WHERE xe.gym_id      = p_gym_id
      AND xe.axis::TEXT  = 'exercise_equipment'
      AND xe.exercise_key IS NOT NULL
    GROUP BY xe.exercise_key, xe.user_id
  ),
  ranked AS (
    SELECT
      exercise_key,
      user_id,
      total_xp,
      public.xp_to_level(total_xp)                             AS lv,
      RANK() OVER (PARTITION BY exercise_key ORDER BY total_xp DESC) AS rn,
      COUNT(*) OVER (PARTITION BY exercise_key)::INTEGER        AS cnt
    FROM per_user_exercise
  )
  SELECT
    r.exercise_key,
    r.user_id          AS top_user_id,
    up.username        AS top_username,
    r.total_xp         AS top_xp,
    r.lv               AS top_level,
    r.cnt              AS distinct_users
  FROM ranked r
  JOIN public.user_profiles up ON up.id = r.user_id
  WHERE r.rn = 1
    AND (up.privacy_level IS NULL OR up.privacy_level::TEXT != 'private')
  ORDER BY r.total_xp DESC
  LIMIT 50;
$$;

COMMENT ON FUNCTION public.get_gym_equipment_overview IS
  'Per-exercise leaderboard overview. Returns the top user for every '
  'exercise_key with any exercise_equipment XP in the gym. Used for the '
  'scrollable equipment XP list in the community screen.';

GRANT EXECUTE ON FUNCTION public.get_gym_equipment_overview(UUID)
  TO authenticated;

-- ─── Fix 4: Recompute user_gym_xp for all affected users ─────────────────────

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
  RAISE NOTICE '00027: recomputed user_gym_xp for all training_day users';
END;
$$;
