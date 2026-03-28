-- =============================================================================
-- Tap'em — Re-seed training calendar data for "pumpingturtle" at Lifthouse
--
-- The original seed (00043) resolved the gym from the user's most recent
-- membership at the time, which was NOT Lifthouse. The RLS policy requires
-- has_active_membership(gym_id), so those sessions were invisible via Supabase
-- after reinstall (local SQLite is wiped). This migration corrects that by:
--   1. Upserting a membership row at Lifthouse for pumpingturtle.
--   2. Seeding the correct date list (v2) at Lifthouse with a new idempotency
--      namespace so re-running is fully safe.
--
-- IMPORTANT — Calendar only, NO XP:
--   This migration inserts into workout_sessions ONLY — it does NOT write to
--   xp_events. No XP is awarded. Leaderboard, level, and all XP aggregates
--   remain untouched.
--
-- Idempotency: key = md5('tapem_pumpingturtle_seed_v2_' || date)::UUID.
--   Re-running is safe — existing rows are silently skipped.
-- =============================================================================

DO $$
DECLARE
  v_user_id   UUID;
  v_gym_id    UUID := 'a0000000-0000-0000-0000-000000000001'; -- Lifthouse
  v_equip_id  UUID;
  v_date      DATE;

  training_days DATE[] := ARRAY[
    -- ── August 2025 ──────────────────────────────────────────────────────────
    '2025-08-30',

    -- ── September 2025 ───────────────────────────────────────────────────────
    '2025-09-02', '2025-09-04', '2025-09-05', '2025-09-07', '2025-09-09',
    '2025-09-11', '2025-09-12', '2025-09-14', '2025-09-16', '2025-09-18',
    '2025-09-19', '2025-09-20', '2025-09-23', '2025-09-25', '2025-09-30',

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
    '2026-03-17', '2026-03-19', '2026-03-20', '2026-03-22', '2026-03-25'
  ]::DATE[];

BEGIN
  -- ── Resolve pumpingturtle user ────────────────────────────────────────────

  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE lower(username::TEXT) = 'pumpingturtle';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User pumpingturtle not found in user_profiles';
  END IF;

  -- ── Ensure membership at Lifthouse ────────────────────────────────────────
  -- Required by RLS: user_id = auth.uid() AND has_active_membership(gym_id).
  -- Without this the Supabase SELECT returns nothing after reinstall.

  INSERT INTO public.memberships (user_id, gym_id, role, joined_at)
  VALUES (v_user_id, v_gym_id, 'member', now())
  ON CONFLICT (user_id, gym_id) DO NOTHING;

  -- ── Pick any active equipment from Lifthouse ──────────────────────────────

  SELECT id INTO v_equip_id
  FROM public.gym_equipment
  WHERE gym_id = v_gym_id
    AND is_active = TRUE
  ORDER BY name
  LIMIT 1;

  IF v_equip_id IS NULL THEN
    RAISE EXCEPTION 'No active equipment found in Lifthouse (%) — run equipment seed first', v_gym_id;
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
      (v_date::TIMESTAMP + INTERVAL '9 hours')  AT TIME ZONE 'UTC',
      (v_date::TIMESTAMP + INTERVAL '10 hours 30 minutes') AT TIME ZONE 'UTC',
      'sync_confirmed',
      md5('tapem_pumpingturtle_seed_v2_' || v_date::TEXT)::UUID,
      'seed:pumpingturtle_calendar_v2'
    )
    ON CONFLICT (idempotency_key) DO NOTHING;
  END LOOP;

  RAISE NOTICE 'Seeded % training days for pumpingturtle at Lifthouse (%)',
    array_length(training_days, 1), v_gym_id;
END $$;
