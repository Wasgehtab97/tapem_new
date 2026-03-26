-- =============================================================================
-- Tap'em — Seed training calendar data for pumpingturtle
--
-- Inserts one finished workout_session per training day covering
-- 2025-08-30 through 2026-03-22 (real training history before app existed).
--
-- IMPORTANT — Calendar only, NO XP:
--   This migration inserts into workout_sessions ONLY — it does NOT write to
--   xp_events. The xp_events trigger fires on xp_events inserts, not on
--   workout_sessions inserts, so no XP is awarded. Leaderboard, level,
--   and all XP aggregates remain untouched.
--
-- Idempotency: each row carries a deterministic idempotency_key built from
-- md5('tapem_pumpingturtle_seed_v1_' || date). Re-running this migration is
-- safe — existing rows are silently skipped via ON CONFLICT DO NOTHING.
-- =============================================================================

DO $$
DECLARE
  v_user_id   UUID;
  v_gym_id    UUID;
  v_equip_id  UUID;
  v_date      DATE;

  training_days DATE[] := ARRAY[
    -- ── August 2025 ──────────────────────────────────────────────────────────
    '2025-08-30',

    -- ── September 2025 ───────────────────────────────────────────────────────
    '2025-09-02', '2025-09-04', '2025-09-05', '2025-09-07', '2025-09-09',
    '2025-09-11', '2025-09-12', '2025-09-14', '2025-09-15', '2025-09-16',
    '2025-09-18', '2025-09-19', '2025-09-20', '2025-09-23', '2025-09-25',
    '2025-09-30',

    -- ── October 2025 ─────────────────────────────────────────────────────────
    '2025-10-02', '2025-10-03', '2025-10-04', '2025-10-07', '2025-10-09',
    '2025-10-10', '2025-10-11', '2025-10-13', '2025-10-14', '2025-10-15',
    '2025-10-17', '2025-10-19', '2025-10-28',

    -- ── November 2025 ────────────────────────────────────────────────────────
    '2025-11-02', '2025-11-03', '2025-11-04', '2025-11-06', '2025-11-07',
    '2025-11-08', '2025-11-09', '2025-11-11', '2025-11-13', '2025-11-14',
    '2025-11-15', '2025-11-16', '2025-11-18', '2025-11-21', '2025-11-27',
    '2025-11-28', '2025-11-30',

    -- ── December 2025 ────────────────────────────────────────────────────────
    '2025-12-02', '2025-12-03', '2025-12-05', '2025-12-07', '2025-12-08',
    '2025-12-11', '2025-12-12', '2025-12-13', '2025-12-15', '2025-12-16',
    '2025-12-19', '2025-12-20', '2025-12-22', '2025-12-23', '2025-12-28',

    -- ── January 2026 ─────────────────────────────────────────────────────────
    '2026-01-06', '2026-01-08', '2026-01-09', '2026-01-13', '2026-01-15',
    '2026-01-16', '2026-01-17', '2026-01-19', '2026-01-23', '2026-01-24',
    '2026-01-25', '2026-01-27', '2026-01-29', '2026-01-31',

    -- ── February 2026 ────────────────────────────────────────────────────────
    '2026-02-04', '2026-02-05', '2026-02-06', '2026-02-08', '2026-02-09',
    '2026-02-10', '2026-02-11', '2026-02-16', '2026-02-17', '2026-02-18',
    '2026-02-19', '2026-02-21', '2026-02-22', '2026-02-24', '2026-02-25',
    '2026-02-26', '2026-02-28',

    -- ── March 2026 ───────────────────────────────────────────────────────────
    '2026-03-01', '2026-03-03', '2026-03-06', '2026-03-08', '2026-03-09',
    '2026-03-10', '2026-03-11', '2026-03-13', '2026-03-15', '2026-03-16',
    '2026-03-17', '2026-03-19', '2026-03-20', '2026-03-22'
  ]::DATE[];

BEGIN
  -- ── Resolve pumpingturtle user ────────────────────────────────────────────

  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE lower(username::TEXT) = 'pumpingturtle';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'pumpingturtle user not found in user_profiles';
  END IF;

  -- ── Resolve gym via active membership ─────────────────────────────────────
  -- Uses the most recently joined gym. Sessions are only needed for the
  -- calendar heatmap which queries all of the user's sessions (no gym filter).

  SELECT gym_id INTO v_gym_id
  FROM public.memberships
  WHERE user_id = v_user_id
  ORDER BY joined_at DESC
  LIMIT 1;

  IF v_gym_id IS NULL THEN
    RAISE EXCEPTION 'pumpingturtle has no gym membership — add one first';
  END IF;

  -- ── Pick any active equipment from that gym ───────────────────────────────
  -- The session requires a valid equipment_id (FK, NOT NULL).
  -- The specific machine does not matter — the calendar only uses
  -- session_day_anchor.

  SELECT id INTO v_equip_id
  FROM public.gym_equipment
  WHERE gym_id = v_gym_id
    AND is_active = TRUE
  ORDER BY name
  LIMIT 1;

  IF v_equip_id IS NULL THEN
    RAISE EXCEPTION 'No active equipment found in gym % for pumpingturtle', v_gym_id;
  END IF;

  -- ── Insert one session per training day ───────────────────────────────────

  FOREACH v_date IN ARRAY training_days LOOP
    INSERT INTO public.workout_sessions (
      id,
      gym_id,
      user_id,
      equipment_id,
      session_day_anchor,
      started_at,
      finished_at,
      sync_status,
      idempotency_key,
      notes
    ) VALUES (
      gen_random_uuid(),
      v_gym_id,
      v_user_id,
      v_equip_id,
      v_date,
      -- Simulate a morning workout (09:00 – 10:30 UTC)
      (v_date::TIMESTAMP + INTERVAL '9 hours')  AT TIME ZONE 'UTC',
      (v_date::TIMESTAMP + INTERVAL '10 hours 30 minutes') AT TIME ZONE 'UTC',
      'sync_confirmed',
      -- Deterministic key — safe to re-run
      md5('tapem_pumpingturtle_seed_v1_' || v_date::TEXT)::UUID,
      'seed:pumpingturtle_calendar_v1'
    )
    ON CONFLICT (idempotency_key) DO NOTHING;
  END LOOP;

  RAISE NOTICE 'Seeded % training days for pumpingturtle at gym %',
    array_length(training_days, 1), v_gym_id;
END $$;
