-- =============================================================================
-- Tap'em — Fitseveneleven Schwalbach gym + equipment seed
-- 27 fixed machines, 5 open stations, 27 exercise templates
-- Gym ID  : a0000000-0000-0000-0000-000000000002
-- Join code: FIT711
-- =============================================================================

-- ─── Insert gym ──────────────────────────────────────────────────────────────

INSERT INTO public.tenant_gyms (id, name, slug, join_code)
VALUES (
  'a0000000-0000-0000-0000-000000000002',
  'Fitseveneleven Schwalbach',
  'fitseveneleven-schwalbach',
  'FIT711'
)
ON CONFLICT (id) DO UPDATE
  SET join_code = 'FIT711',
      name      = 'Fitseveneleven Schwalbach',
      slug      = 'fitseveneleven-schwalbach';

-- ─── Exercise templates for Fitseveneleven Schwalbach ─────────────────────────
-- One template per distinct exercise. "(leer)" manufacturer → NULL.

INSERT INTO public.exercise_templates
  (key, gym_id, name, primary_muscle_group, is_ranking_eligible, is_active)
VALUES
  ('bench_press',             'a0000000-0000-0000-0000-000000000002', 'Bench Press',                    'Chest',       true,  true),
  ('chest_press',             'a0000000-0000-0000-0000-000000000002', 'Chest Press Machine',            'Chest',       false, true),
  ('ab_lying',                'a0000000-0000-0000-0000-000000000002', 'Ab Lying',                       'Core',        false, true),
  ('lying_leg_curl',          'a0000000-0000-0000-0000-000000000002', 'Lying Leg Curl',                 'Hamstrings',  false, true),
  ('seated_leg_curl',         'a0000000-0000-0000-0000-000000000002', 'Seated Leg Curl',                'Hamstrings',  false, true),
  ('leg_press',               'a0000000-0000-0000-0000-000000000002', 'Leg Press',                      'Quadriceps',  true,  true),
  ('leg_extensions',          'a0000000-0000-0000-0000-000000000002', 'Leg Extensions',                 'Quadriceps',  true,  true),
  ('bicep_curl_barbell',      'a0000000-0000-0000-0000-000000000002', 'Barbell Bicep Curl',             'Biceps',      false, true),
  ('bicep_curl',              'a0000000-0000-0000-0000-000000000002', 'Bicep Curl',                     'Biceps',      true,  true),
  ('chest_fly',               'a0000000-0000-0000-0000-000000000002', 'Butterfly',                      'Chest',       false, true),
  ('dips',                    'a0000000-0000-0000-0000-000000000002', 'Dips',                           'Triceps',     false, true),
  ('hyperextensions',         'a0000000-0000-0000-0000-000000000002', 'Hyperextensions',                'Lower Back',  false, true),
  ('high_row_isolateral',     'a0000000-0000-0000-0000-000000000002', 'Iso-Lateral Front High Row',     'Back',        false, true),
  ('lat_pulldown_isolateral', 'a0000000-0000-0000-0000-000000000002', 'Iso-Lateral Front Lat Pulldown', 'Back',        false, true),
  ('low_row_isolateral',      'a0000000-0000-0000-0000-000000000002', 'Iso-Lateral Front Low Row',      'Back',        false, true),
  ('ab_crunch_machine',       'a0000000-0000-0000-0000-000000000002', 'Ab Crunch Machine',              'Core',        false, true),
  ('deadlift',                'a0000000-0000-0000-0000-000000000002', 'Deadlift',                       'Back',        true,  true),
  ('lat_pulldown',            'a0000000-0000-0000-0000-000000000002', 'Lat Pulldown',                   'Back',        true,  true),
  ('reverse_flys',            'a0000000-0000-0000-0000-000000000002', 'Reverse Butterfly',              'Shoulders',   false, true),
  ('back_extension',          'a0000000-0000-0000-0000-000000000002', 'Back Extension Machine',         'Lower Back',  false, true),
  ('cable_row',               'a0000000-0000-0000-0000-000000000002', 'Cable Row',                      'Back',        false, true),
  ('incline_press',           'a0000000-0000-0000-0000-000000000002', 'Incline Press',                  'Chest',       false, true),
  ('shoulder_press',          'a0000000-0000-0000-0000-000000000002', 'Shoulder Press',                 'Shoulders',   true,  true),
  ('lateral_raise',           'a0000000-0000-0000-0000-000000000002', 'Lateral Raise',                  'Shoulders',   true,  true),
  ('squats',                  'a0000000-0000-0000-0000-000000000002', 'Squats',                         'Legs',        false, true),
  ('t_bar_row',               'a0000000-0000-0000-0000-000000000002', 'T-Bar Row',                      'Back',        false, true),
  ('calf_raise_machine',      'a0000000-0000-0000-0000-000000000002', 'Calf Machine',                   'Calves',      false, true)
ON CONFLICT (key, gym_id) DO NOTHING;

-- ─── Gym equipment — Fitseveneleven Schwalbach ────────────────────────────────
-- Manufacturers: "(leer)" → NULL.
-- isMulti = Nein → fixed_machine  |  isMulti = Ja → open_station

INSERT INTO public.gym_equipment
  (id, gym_id, name, equipment_type, zone_name, canonical_exercise_key, manufacturer, is_active)
VALUES

-- ── FIXED MACHINES (isMulti = Nein) ──────────────────────────────────────────
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Bankdrücken',                    'fixed_machine', NULL, 'bench_press',             NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Bankdrücken Maschine',           'fixed_machine', NULL, 'chest_press',             NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Bauch liegend',                  'fixed_machine', NULL, 'ab_lying',                NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Beinbeuger liegend',             'fixed_machine', NULL, 'lying_leg_curl',          NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Beinbeuger sitzend',             'fixed_machine', NULL, 'seated_leg_curl',         NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Beinpresse',                     'fixed_machine', NULL, 'leg_press',               NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Beinstrecker',                   'fixed_machine', NULL, 'leg_extensions',          NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Bizeps Langhantel',              'fixed_machine', NULL, 'bicep_curl_barbell',      NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Bizepsmaschine',                 'fixed_machine', NULL, 'bicep_curl',              NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Butterfly',                      'fixed_machine', NULL, 'chest_fly',               NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Dips',                           'fixed_machine', NULL, 'dips',                    NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Hyperextension Bank',            'fixed_machine', NULL, 'hyperextensions',         NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Iso-Lateral Front High Row',     'fixed_machine', NULL, 'high_row_isolateral',     NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Iso-Lateral Front Lat Pulldown', 'fixed_machine', NULL, 'lat_pulldown_isolateral', NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Iso-Lateral Front Low Row',      'fixed_machine', NULL, 'low_row_isolateral',      NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Klappsitz',                      'fixed_machine', NULL, 'ab_crunch_machine',       NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Kreuzheben',                     'fixed_machine', NULL, 'deadlift',                NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Latzugmaschine',                 'fixed_machine', NULL, 'lat_pulldown',            NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Reverse Butterfly',              'fixed_machine', NULL, 'reverse_flys',            NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Rückenstrecker Maschine',        'fixed_machine', NULL, 'back_extension',          NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Rudern Kabel',                   'fixed_machine', NULL, 'cable_row',               NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Schrägbankdrücken',              'fixed_machine', NULL, 'incline_press',           NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Schulterpresse',                 'fixed_machine', NULL, 'shoulder_press',          NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Seitheben Maschine',             'fixed_machine', NULL, 'lateral_raise',           NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Squats',                         'fixed_machine', NULL, 'squats',                  NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'T-Bar',                          'fixed_machine', NULL, 't_bar_row',               NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Wadenmaschine',                  'fixed_machine', NULL, 'calf_raise_machine',      NULL, true),

-- ── OPEN STATIONS (isMulti = Ja) ──────────────────────────────────────────────
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Kabelturm',                      'open_station',  NULL, NULL, NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Kurzhanteln',                    'open_station',  NULL, NULL, NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Latzug Kabel',                   'open_station',  NULL, NULL, NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'Multifunktionsgerät Seilzug',    'open_station',  NULL, NULL, NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000002', 'SZ-Stange',                      'open_station',  NULL, NULL, NULL, true);
