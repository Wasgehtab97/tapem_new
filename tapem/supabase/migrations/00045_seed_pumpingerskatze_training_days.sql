-- =============================================================================
-- Tap'em — Seed training calendar data for pumpingerskatze
--
-- Inserts one finished workout_session per training day covering
-- 2025-08-31 through 2026-03-21 (real training history before app existed).
-- Gym: Club Aktiv (a0000000-0000-0000-0000-000000000003)
--
-- IMPORTANT — Calendar only, NO XP:
--   This migration inserts into workout_sessions ONLY — it does NOT write to
--   xp_events. The xp_events trigger fires on xp_events inserts, not on
--   workout_sessions inserts, so no XP is awarded. Leaderboard, level,
--   and all XP aggregates remain untouched.
--
-- Idempotency: each row carries a deterministic idempotency_key built from
-- md5('tapem_pumpingerskatze_seed_v1_' || date). Re-running this migration is
-- safe — existing rows are silently skipped via ON CONFLICT DO NOTHING.
-- =============================================================================

DO $$
DECLARE
  v_user_id   UUID;
  v_gym_id    UUID := 'a0000000-0000-0000-0000-000000000003'; -- Club Aktiv
  v_equip_id  UUID;
  v_date      DATE;

  training_days DATE[] := ARRAY[
    -- ── August 2025 ──────────────────────────────────────────────────────────
    '2025-08-31',

    -- ── September 2025 ───────────────────────────────────────────────────────
    '2025-09-03', '2025-09-09', '2025-09-12', '2025-09-17', '2025-09-19',
    '2025-09-21', '2025-09-22',

    -- ── October 2025 ─────────────────────────────────────────────────────────
    '2025-10-05', '2025-10-08', '2025-10-10', '2025-10-12', '2025-10-13',
    '2025-10-16', '2025-10-20', '2025-10-23', '2025-10-24', '2025-10-26',
    '2025-10-31',

    -- ── November 2025 ────────────────────────────────────────────────────────
    '2025-11-01', '2025-11-04', '2025-11-05', '2025-11-09', '2025-11-11',
    '2025-11-15', '2025-11-16', '2025-11-18', '2025-11-19', '2025-11-21',
    '2025-11-22', '2025-11-25', '2025-11-26', '2025-11-28',

    -- ── December 2025 ────────────────────────────────────────────────────────
    '2025-12-04', '2025-12-07', '2025-12-08', '2025-12-11', '2025-12-17',

    -- ── January 2026 ─────────────────────────────────────────────────────────
    '2026-01-03', '2026-01-05', '2026-01-06', '2026-01-09', '2026-01-11',
    '2026-01-12', '2026-01-17', '2026-01-18', '2026-01-19', '2026-01-22',
    '2026-01-23', '2026-01-25',

    -- ── February 2026 ────────────────────────────────────────────────────────
    '2026-02-01', '2026-02-02', '2026-02-05', '2026-02-06', '2026-02-09',
    '2026-02-12', '2026-02-14', '2026-02-16', '2026-02-19', '2026-02-20',
    '2026-02-23', '2026-02-27',

    -- ── March 2026 ───────────────────────────────────────────────────────────
    '2026-03-02', '2026-03-04', '2026-03-06', '2026-03-07', '2026-03-09',
    '2026-03-13', '2026-03-17', '2026-03-20', '2026-03-21'
  ]::DATE[];

BEGIN
  -- ── Resolve pumpingerskatze user ──────────────────────────────────────────

  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE lower(username::TEXT) = 'pumpingerskatze';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'pumpingerskatze user not found in user_profiles';
  END IF;

  -- ── Verify membership at Club Aktiv ───────────────────────────────────────

  IF NOT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = v_user_id AND gym_id = v_gym_id
  ) THEN
    RAISE EXCEPTION 'pumpingerskatze has no membership at Club Aktiv (%)' , v_gym_id;
  END IF;

  -- ── Pick any active equipment from Club Aktiv ─────────────────────────────
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
    RAISE EXCEPTION 'No active equipment found in Club Aktiv (%)', v_gym_id;
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
      md5('tapem_pumpingerskatze_seed_v1_' || v_date::TEXT)::UUID,
      'seed:pumpingerskatze_calendar_v1'
    )
    ON CONFLICT (idempotency_key) DO NOTHING;
  END LOOP;

  RAISE NOTICE 'Seeded % training days for pumpingerskatze at Club Aktiv (%)',
    array_length(training_days, 1), v_gym_id;
END $$;
