-- =============================================================================
-- Tap'em — Seed training calendar data for "neele" at Lifthouse
--
-- Inserts one finished workout_session per training day for the date range
-- 2025-09-02 through 2026-03-24 (real training history from provided list).
--
-- IMPORTANT — Calendar only, NO XP:
--   This migration inserts into workout_sessions ONLY — it does NOT write to
--   xp_events. No XP is awarded. Leaderboard, level, and all XP aggregates
--   remain untouched.
--
-- IMPORTANT — Membership guard:
--   The RLS policy on workout_sessions requires has_active_membership(gym_id).
--   If neele has no membership at Lifthouse the Supabase SELECT would return
--   nothing after a reinstall (local SQLite wiped). This migration upserts a
--   membership row so the seeded sessions are always visible via RLS.
--
-- Idempotency: each row carries a deterministic idempotency_key built from
-- md5('tapem_neele_seed_v1_' || date). Re-running this migration is safe —
-- existing rows are silently skipped via ON CONFLICT DO NOTHING.
-- =============================================================================

DO $$
DECLARE
  v_user_id   UUID;
  v_gym_id    UUID := 'a0000000-0000-0000-0000-000000000001'; -- Lifthouse
  v_equip_id  UUID;
  v_date      DATE;

  training_days DATE[] := ARRAY[
    -- ── September 2025 ───────────────────────────────────────────────────────
    '2025-09-02', '2025-09-04', '2025-09-05', '2025-09-07', '2025-09-09',
    '2025-09-11', '2025-09-12', '2025-09-14', '2025-09-16', '2025-09-18',
    '2025-09-19', '2025-09-23', '2025-09-25', '2025-09-26', '2025-09-28',
    '2025-09-30',

    -- ── October 2025 ─────────────────────────────────────────────────────────
    '2025-10-07', '2025-10-09', '2025-10-10', '2025-10-16', '2025-10-19',
    '2025-10-23', '2025-10-24', '2025-10-28', '2025-10-30', '2025-10-31',

    -- ── November 2025 ────────────────────────────────────────────────────────
    '2025-11-02', '2025-11-04', '2025-11-06', '2025-11-07', '2025-11-09',
    '2025-11-11', '2025-11-14', '2025-11-16', '2025-11-18', '2025-11-22',
    '2025-11-25', '2025-11-27', '2025-11-28', '2025-11-30',

    -- ── December 2025 ────────────────────────────────────────────────────────
    '2025-12-02', '2025-12-04', '2025-12-05', '2025-12-07', '2025-12-09',
    '2025-12-13', '2025-12-14', '2025-12-16', '2025-12-19', '2025-12-20',
    '2025-12-22', '2025-12-28', '2025-12-30', '2025-12-31',

    -- ── January 2026 ─────────────────────────────────────────────────────────
    '2026-01-02', '2026-01-03', '2026-01-06', '2026-01-08', '2026-01-09',
    '2026-01-13', '2026-01-15', '2026-01-16', '2026-01-17', '2026-01-20',
    '2026-01-23', '2026-01-25', '2026-01-27', '2026-01-30', '2026-01-31',

    -- ── February 2026 ────────────────────────────────────────────────────────
    '2026-02-03', '2026-02-05', '2026-02-06', '2026-02-08', '2026-02-10',
    '2026-02-19', '2026-02-21', '2026-02-24', '2026-02-26', '2026-02-28',

    -- ── March 2026 ───────────────────────────────────────────────────────────
    '2026-03-01', '2026-03-03', '2026-03-06', '2026-03-08', '2026-03-10',
    '2026-03-13', '2026-03-15', '2026-03-17', '2026-03-20', '2026-03-24'
  ]::DATE[];

BEGIN
  -- ── Resolve neele user ────────────────────────────────────────────────────

  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE lower(username::TEXT) = 'neele';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User neele not found in user_profiles';
  END IF;

  -- ── Ensure membership at Lifthouse ────────────────────────────────────────
  -- Required by the RLS policy:  user_id = auth.uid() AND has_active_membership(gym_id)
  -- Without an active membership row the Supabase SELECT would return nothing
  -- after a reinstall (local SQLite is wiped on reinstall).

  INSERT INTO public.memberships (user_id, gym_id, role, joined_at)
  VALUES (v_user_id, v_gym_id, 'member', now())
  ON CONFLICT (user_id, gym_id) DO NOTHING;

  -- ── Pick any active equipment from Lifthouse ──────────────────────────────
  -- The session needs a valid equipment_id (FK, NOT NULL).
  -- Any piece of equipment works — the calendar only uses session_day_anchor.

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
      -- Simulate a morning workout (09:00 – 10:30 UTC)
      (v_date::TIMESTAMP + INTERVAL '9 hours')  AT TIME ZONE 'UTC',
      (v_date::TIMESTAMP + INTERVAL '10 hours 30 minutes') AT TIME ZONE 'UTC',
      'sync_confirmed',
      -- Deterministic key — safe to re-run
      md5('tapem_neele_seed_v1_' || v_date::TEXT)::UUID,
      'seed:neele_calendar_v1'
    )
    ON CONFLICT (idempotency_key) DO NOTHING;
  END LOOP;

  RAISE NOTICE 'Seeded % training days for neele at Lifthouse (%)',
    array_length(training_days, 1), v_gym_id;
END $$;
