-- =============================================================================
-- Tap'em — 00033: Remove seed XP filler data + fix freestyle session equipment_id
--
-- Problem: Migration 00031 seeded fake exercise_equipment XP events for
--   ironbronz/ironwood so the Equipment XP tab wasn't empty during development.
--   These seed values now pollute the leaderboard with fake data.
--
-- Also: Workout sessions synced with equipment_id = 'freestyle' (the Flutter
--   sentinel for multi-equipment sessions) ended up with literal string
--   'freestyle' in workout_sessions.equipment_id instead of NULL.
--
-- Fixes:
--   1. Delete all xp_events with idempotency_key LIKE 'equipment_seed:%'
--   2. Nullify workout_sessions.equipment_id where value is 'freestyle'
--   3. Recompute XP aggregates for all affected users
-- =============================================================================

-- ─── 1. Delete seed XP events ─────────────────────────────────────────────────

DELETE FROM public.xp_events
WHERE idempotency_key LIKE 'equipment_seed:%';

-- ─── 2. Fix freestyle sentinel in workout_sessions ────────────────────────────
-- The Flutter client stores 'freestyle' as a sentinel for plan-based multi-
-- equipment sessions. The edge function now normalises this to NULL before
-- upsert, but any sessions synced before that fix may have the raw string.

UPDATE public.workout_sessions
SET equipment_id = NULL
WHERE equipment_id::text = 'freestyle';

-- ─── 3. Recompute XP aggregates for all users in all gyms ─────────────────────

DO $$
DECLARE
  rec     RECORD;
  v_count INTEGER := 0;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, gym_id
    FROM   public.user_gym_xp
  LOOP
    PERFORM public.recompute_user_gym_xp(rec.user_id, rec.gym_id);
    v_count := v_count + 1;
  END LOOP;
  RAISE NOTICE '00033: recomputed XP aggregates for % user-gym pairs', v_count;
END;
$$;
