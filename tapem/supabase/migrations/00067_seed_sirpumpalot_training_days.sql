-- =============================================================================
-- Tap'em — Seed training calendar for "sirpumpalot" at Fitseveneleven Schwalbach
--
-- Calendar only, NO XP:
--   Inserts into workout_sessions ONLY — no xp_events, no session_exercises,
--   no set_entries. XP is NOT awarded.
--
-- Idempotency: key = md5('tapem_sirpumpalot_seed_v1_' || date)::UUID.
--   Re-running is fully safe — existing rows are silently skipped.
-- =============================================================================

DO $$
DECLARE
  v_user_id  UUID;
  v_gym_id   UUID := 'a0000000-0000-0000-0000-000000000002'; -- Fitseveneleven Schwalbach
  v_equip_id UUID;
  v_date     DATE;

  training_days DATE[] := ARRAY[
    -- ── September 2025 ───────────────────────────────────────────────────────
    '2025-09-02', '2025-09-04', '2025-09-09', '2025-09-11', '2025-09-13',
    '2025-09-16', '2025-09-21', '2025-09-23', '2025-09-24',

    -- ── October 2025 ─────────────────────────────────────────────────────────
    '2025-10-01', '2025-10-03', '2025-10-08', '2025-10-30',

    -- ── November 2025 ────────────────────────────────────────────────────────
    '2025-11-04', '2025-11-07', '2025-11-10', '2025-11-13',
    '2025-11-20', '2025-11-21', '2025-11-26', '2025-11-30',

    -- ── December 2025 ────────────────────────────────────────────────────────
    '2025-12-09', '2025-12-15',

    -- ── January 2026 ─────────────────────────────────────────────────────────
    '2026-01-14', '2026-01-17', '2026-01-21',

    -- ── February 2026 ────────────────────────────────────────────────────────
    '2026-02-02', '2026-02-05', '2026-02-16', '2026-02-18',

    -- ── March 2026 ───────────────────────────────────────────────────────────
    '2026-03-11', '2026-03-14', '2026-03-15', '2026-03-19', '2026-03-20',
    '2026-03-22', '2026-03-23', '2026-03-27'
  ]::DATE[];

BEGIN
  -- ── Resolve sirpumpalot user ──────────────────────────────────────────────

  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE lower(username::TEXT) = 'sirpumpalot';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User sirpumpalot not found in user_profiles';
  END IF;

  -- ── Ensure membership at Fitseveneleven Schwalbach ───────────────────────
  -- Required by RLS: has_active_membership(gym_id).

  INSERT INTO public.memberships (user_id, gym_id, role, joined_at)
  VALUES (v_user_id, v_gym_id, 'member', now())
  ON CONFLICT (user_id, gym_id) DO NOTHING;

  -- ── Pick any active equipment from the gym ───────────────────────────────

  SELECT id INTO v_equip_id
  FROM public.gym_equipment
  WHERE gym_id = v_gym_id AND is_active = TRUE
  ORDER BY name
  LIMIT 1;

  IF v_equip_id IS NULL THEN
    RAISE EXCEPTION 'No active equipment found in Fitseveneleven Schwalbach (%) — run equipment seed first', v_gym_id;
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
      md5('tapem_sirpumpalot_seed_v1_' || v_date::TEXT)::UUID,
      'seed:sirpumpalot_calendar_v1'
    )
    ON CONFLICT (idempotency_key) DO NOTHING;
  END LOOP;

  RAISE NOTICE 'Seeded % training days for sirpumpalot at Fitseveneleven Schwalbach (%)',
    array_length(training_days, 1), v_gym_id;
END $$;
