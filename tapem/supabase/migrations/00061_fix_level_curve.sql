-- =============================================================================
-- Tap'em — 00061: Fix XP level curve (flat 100 XP per level)
--
-- Root cause: xp_to_level() from 00003 uses an escalating curve
-- (500 * level XP per level). The Flutter app uses a flat 100 XP per level
-- (XpRules.trainingDayXpPerLevel / exerciseXpPerLevel / muscleGroupXpPerLevel).
--
-- A user with 25 XP (1 training day) sees "noch 1475 XP bis Lvl 2" because
-- the DB computes xp_needed_for_next_level(25) = 1500 - 25 = 1475.
-- The correct value is 100 - 25 = 75.
--
-- Fix: Replace both functions with flat 100-XP versions that match the
-- Flutter XpRules constants. Then recompute user_gym_xp for all users so
-- the stored xp_to_next_level values are correct immediately.
-- =============================================================================

-- ─── Replace xp_to_level ─────────────────────────────────────────────────────
-- Old: escalating curve (500 * level XP per level)
-- New: flat 100 XP per level  → level = floor(total_xp / 100) + 1

CREATE OR REPLACE FUNCTION public.xp_to_level(p_total_xp INTEGER)
RETURNS SMALLINT LANGUAGE sql IMMUTABLE AS $$
  SELECT (GREATEST(p_total_xp, 0) / 100 + 1)::SMALLINT;
$$;

-- ─── Replace xp_needed_for_next_level ────────────────────────────────────────
-- Old: (500 * (level+1)) - total_xp
-- New: 100 - (total_xp % 100), clamped to [1, 100]

CREATE OR REPLACE FUNCTION public.xp_needed_for_next_level(p_total_xp INTEGER)
RETURNS INTEGER LANGUAGE sql IMMUTABLE AS $$
  SELECT 100 - (GREATEST(p_total_xp, 0) % 100);
$$;

-- ─── Recompute user_gym_xp for every user+gym ────────────────────────────────
-- Runs recompute_user_gym_xp so that all stored current_level and
-- xp_to_next_level values reflect the new flat curve immediately.
-- Safe to re-run: fully idempotent (ON CONFLICT DO UPDATE).

DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, gym_id FROM public.xp_events
  LOOP
    PERFORM public.recompute_user_gym_xp(rec.user_id, rec.gym_id);
  END LOOP;
END;
$$;
