-- =============================================================================
-- Tap'em — Mark 2026-03-24 as a training day for "pumpingturtle" at Lifthouse
--
-- The user trained on this date before installing the app.
-- Calendar-only: inserts into workout_sessions ONLY.
-- No xp_events, no session_exercises, no set_entries — XP is NOT awarded.
-- =============================================================================

DO $$
DECLARE
  v_user_id  UUID;
  v_gym_id   UUID := 'a0000000-0000-0000-0000-000000000001'; -- Lifthouse
  v_equip_id UUID;
  v_date     DATE := '2026-03-24';
BEGIN
  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE lower(username::TEXT) = 'pumpingturtle';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User pumpingturtle not found in user_profiles';
  END IF;

  SELECT id INTO v_equip_id
  FROM public.gym_equipment
  WHERE gym_id = v_gym_id AND is_active = TRUE
  ORDER BY name
  LIMIT 1;

  IF v_equip_id IS NULL THEN
    RAISE EXCEPTION 'No active equipment found in Lifthouse (%)  — run equipment seed first', v_gym_id;
  END IF;

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
    md5('tapem_pumpingturtle_manual_20260324')::UUID,
    'manual:trained_before_app'
  )
  ON CONFLICT (idempotency_key) DO NOTHING;

  RAISE NOTICE 'Marked 2026-03-24 as training day for pumpingturtle at Lifthouse';
END $$;
