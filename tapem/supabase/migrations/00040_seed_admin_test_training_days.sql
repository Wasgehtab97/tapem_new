-- =============================================================================
-- Tap'em — Seed training calendar data for admin_test @ Lifthouse test gym
--
-- Inserts one finished workout_session per training day covering
-- 2025-08-30 through 2026-03-22.
--
-- Idempotency: each row carries a deterministic idempotency_key built from
-- md5('tapem_admin_test_seed_v1_' || date). Re-running this migration is
-- safe — existing rows are silently skipped via ON CONFLICT DO NOTHING.
-- =============================================================================

DO $$
DECLARE
  v_user_id   UUID;
  v_gym_id    UUID  := 'a0000000-0000-0000-0000-000000000099'; -- Lifthouse test
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
  -- ── Resolve admin_test user ───────────────────────────────────────────────

  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE lower(username::TEXT) = 'admin_test';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'admin_test user not found — run 00039 first';
  END IF;

  -- ── Pick any active equipment from the test gym ───────────────────────────
  -- The session needs a valid equipment_id (FK, NOT NULL).
  -- Any piece of equipment works — the calendar only needs session_day_anchor.

  SELECT id INTO v_equip_id
  FROM public.gym_equipment
  WHERE gym_id = v_gym_id
    AND is_active = TRUE
  ORDER BY name
  LIMIT 1;

  IF v_equip_id IS NULL THEN
    RAISE EXCEPTION 'No active equipment in Lifthouse test gym — run 00038 first';
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
      -- Deterministic key: md5 of seed namespace + date casts cleanly to UUID
      -- (PostgreSQL accepts a 32-char hex string in UUID casts)
      md5('tapem_admin_test_seed_v1_' || v_date::TEXT)::UUID,
      'seed:admin_test_calendar_v1'
    )
    ON CONFLICT (idempotency_key) DO NOTHING;
  END LOOP;

  RAISE NOTICE 'Seeded % training days for admin_test at Lifthouse test gym',
    array_length(training_days, 1);
END $$;
