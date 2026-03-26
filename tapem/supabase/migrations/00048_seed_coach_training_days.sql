-- =============================================================================
-- Tap'em — Seed training calendar data for coach
--
-- Inserts one finished workout_session per training day for the user "coach"
-- at KSV Eisenschmiede (a0000000-0000-0000-0000-000000000005).
--
-- IMPORTANT — Calendar only, NO XP:
--   This migration inserts into workout_sessions ONLY — it does NOT write to
--   xp_events. No XP is awarded. Leaderboard, level, and all XP aggregates
--   remain untouched.
--
-- Idempotency: each row carries a deterministic idempotency_key built from
-- md5('tapem_coach_seed_v1_' || date). Re-running this migration is safe —
-- existing rows are silently skipped via ON CONFLICT DO NOTHING.
-- =============================================================================

DO $$
DECLARE
  v_user_id   UUID;
  v_gym_id    UUID := 'a0000000-0000-0000-0000-000000000005'; -- KSV Eisenschmiede
  v_equip_id  UUID;
  v_date      DATE;

  training_days DATE[] := ARRAY[
    '2026-03-03',
    '2026-03-06',
    '2026-03-09',
    '2026-03-12'
  ]::DATE[];

BEGIN
  -- ── Resolve coach user ────────────────────────────────────────────────────

  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE lower(username::TEXT) = 'coach';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User coach not found in user_profiles';
  END IF;

  -- ── Verify membership at KSV Eisenschmiede ────────────────────────────────

  IF NOT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = v_user_id AND gym_id = v_gym_id
  ) THEN
    RAISE EXCEPTION 'coach has no membership at KSV Eisenschmiede (%)', v_gym_id;
  END IF;

  -- ── Pick any active equipment from KSV Eisenschmiede ─────────────────────

  SELECT id INTO v_equip_id
  FROM public.gym_equipment
  WHERE gym_id = v_gym_id
    AND is_active = TRUE
  ORDER BY name
  LIMIT 1;

  IF v_equip_id IS NULL THEN
    RAISE EXCEPTION 'No active equipment found in KSV Eisenschmiede (%)', v_gym_id;
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
      md5('tapem_coach_seed_v1_' || v_date::TEXT)::UUID,
      'seed:coach_calendar_v1'
    )
    ON CONFLICT (idempotency_key) DO NOTHING;
  END LOOP;

  RAISE NOTICE 'Seeded % training days for coach at KSV Eisenschmiede (%)',
    array_length(training_days, 1), v_gym_id;
END $$;
