-- =============================================================================
-- Tap'em — 00031: Seed exercise_equipment XP for test users
--
-- Root cause of empty Equipment XP tab:
--   No exercise_equipment XP events exist in the database. Migration 00022's
--   backfill found nothing because no real workout with logged sets has been
--   synced. The equipment_id column added in 00029 also has nothing to
--   backfill, so all machines show "Noch niemand trainiert".
--
-- Fix:
--   Directly insert exercise_equipment xp_events for ironbronz and ironwood
--   using subqueries to resolve equipment UUIDs from the Lifthouse gym
--   (gym_id = a0000000-0000-0000-0000-000000000001). One event per
--   (user, equipment piece) with realistic XP amounts.
--   All inserts are idempotent via ON CONFLICT DO NOTHING.
-- =============================================================================

DO $$
DECLARE
  v_gym_id   UUID := 'a0000000-0000-0000-0000-000000000001';
  v_bronz_id UUID;
  v_wood_id  UUID;
BEGIN

  -- Resolve test user IDs
  SELECT id INTO v_bronz_id FROM public.user_profiles WHERE LOWER(username) = 'ironbronz' LIMIT 1;
  SELECT id INTO v_wood_id  FROM public.user_profiles WHERE LOWER(username) = 'ironwood'  LIMIT 1;

  IF v_bronz_id IS NULL THEN
    RAISE NOTICE '00031: ironbronz not found — skipping';
    RETURN;
  END IF;
  IF v_wood_id IS NULL THEN
    RAISE NOTICE '00031: ironwood not found — skipping';
    RETURN;
  END IF;

  -- ─── Insert exercise_equipment XP events ────────────────────────────────────
  -- equipment_id is resolved per INSERT via subquery on (gym_id, name, manufacturer).
  -- source_id is a deterministic UUID so idempotency_key stays stable.
  -- occurred_at uses realistic past dates to spread leaderboard history.

  INSERT INTO public.xp_events (
    gym_id, user_id, axis, xp_amount,
    source_type, source_id,
    idempotency_key,
    exercise_key, equipment_id,
    occurred_at
  )

  -- ── ironbronz — 12 machines ──────────────────────────────────────────────
  SELECT v_gym_id, v_bronz_id, 'exercise_equipment'::public.xp_axis, xp,
         'session_exercise', gen_random_uuid(),
         'equipment_seed:bronz:' || eq_name || ':' || COALESCE(mfr,'null'),
         ex_key,
         (SELECT id FROM public.gym_equipment WHERE gym_id = v_gym_id AND name = eq_name AND (manufacturer = mfr OR (manufacturer IS NULL AND mfr IS NULL)) LIMIT 1),
         (NOW() - (days_ago || ' days')::INTERVAL)::TIMESTAMPTZ
  FROM (VALUES
    ('Benchpress',         'ATX',             'bench_press',       95,  3),
    ('Leg Press',          'Cybex',           'leg_press',         120, 5),
    ('Leg Press',          'Hammer Strength', 'leg_press',         80,  7),
    ('Lat Pulldown',       'Nautilus',        'lat_pulldown',      110, 2),
    ('Shoulder Press',     'Hoist',           'shoulder_press',    75,  4),
    ('Leg Extensions',     'Gym80',           'leg_extensions',    90,  6),
    ('Leg Curl',           'Nautilus',        'leg_curl',          85,  8),
    ('High Row',           'Hammer Strength', 'high_row',          70,  9),
    ('Chest Press',        'MTS',             'chest_press',       100, 1),
    ('Tricep Extensions',  'Gym80',           'tricep_extensions', 65,  10),
    ('Lateral Raise',      'Hammer Strength', 'lateral_raise',     55,  11),
    ('Abductor',           'Schnell',         'hip_abduction',     45,  12)
  ) AS t(eq_name, mfr, ex_key, xp, days_ago)
  WHERE (SELECT id FROM public.gym_equipment WHERE gym_id = v_gym_id AND name = eq_name AND (manufacturer = mfr OR (manufacturer IS NULL AND mfr IS NULL)) LIMIT 1) IS NOT NULL

  UNION ALL

  -- ── ironwood — 10 machines (different distribution) ──────────────────────
  SELECT v_gym_id, v_wood_id, 'exercise_equipment'::public.xp_axis, xp,
         'session_exercise', gen_random_uuid(),
         'equipment_seed:wood:' || eq_name || ':' || COALESCE(mfr,'null'),
         ex_key,
         (SELECT id FROM public.gym_equipment WHERE gym_id = v_gym_id AND name = eq_name AND (manufacturer = mfr OR (manufacturer IS NULL AND mfr IS NULL)) LIMIT 1),
         (NOW() - (days_ago || ' days')::INTERVAL)::TIMESTAMPTZ
  FROM (VALUES
    ('Benchpress',         'ATX',             'bench_press',       55,  4),
    ('Leg Press',          'Cybex',           'leg_press',         60,  6),
    ('Lat Pulldown',       'Nautilus',        'lat_pulldown',      70,  3),
    ('Shoulder Press',     'Precor',          'shoulder_press',    45,  5),
    ('Hack Squat',         'Cybex',           'hack_squat',        80,  7),
    ('Overhead Press',     'Cybex',           'overhead_press',    35,  2),
    ('Chest Press',        'Gymleco',         'chest_press',       50,  1),
    ('Tricep Extensions',  'Gymleco',         'tricep_extensions', 40,  8),
    ('Row',                'Gym80',           'row',               60,  9),
    ('Abductor',           'Schnell',         'hip_abduction',     30,  10)
  ) AS t(eq_name, mfr, ex_key, xp, days_ago)
  WHERE (SELECT id FROM public.gym_equipment WHERE gym_id = v_gym_id AND name = eq_name AND (manufacturer = mfr OR (manufacturer IS NULL AND mfr IS NULL)) LIMIT 1) IS NOT NULL

  ON CONFLICT (idempotency_key) DO NOTHING;

  RAISE NOTICE '00031: equipment XP seed complete for ironbronz (%) and ironwood (%)', v_bronz_id, v_wood_id;

END;
$$;

-- ─── Recompute aggregates for both users ──────────────────────────────────────

DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, gym_id
    FROM   public.xp_events
    WHERE  axis = 'exercise_equipment'::public.xp_axis
      AND  gym_id     = 'a0000000-0000-0000-0000-000000000001'
  LOOP
    PERFORM public.recompute_user_gym_xp(rec.user_id, rec.gym_id);
  END LOOP;
END;
$$;
