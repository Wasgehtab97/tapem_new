-- =============================================================================
-- Tap'em — MediFitness gym + equipment seed
-- 19 fixed machines, 2 cardio, 6 open stations, 19 exercise templates
-- Gym ID  : a0000000-0000-0000-0000-000000000004
-- Join code: MEDI1
-- =============================================================================

-- ─── Insert gym ──────────────────────────────────────────────────────────────

INSERT INTO public.tenant_gyms (id, name, slug, join_code)
VALUES (
  'a0000000-0000-0000-0000-000000000004',
  'MediFitness',
  'medifitness',
  'MEDI1'
)
ON CONFLICT (id) DO UPDATE
  SET join_code = 'MEDI1',
      name      = 'MediFitness',
      slug      = 'medifitness';

-- ─── Exercise templates for MediFitness ──────────────────────────────────────
-- Cardio equipment (Airbike, Ruder Ergometer) needs no template.

INSERT INTO public.exercise_templates
  (key, gym_id, name, primary_muscle_group, is_ranking_eligible, is_active)
VALUES
  ('bench_press',          'a0000000-0000-0000-0000-000000000004', 'Bench Press',             'Chest',       true,  true),
  ('ab_swing',             'a0000000-0000-0000-0000-000000000004', 'Ab Swing',                'Core',        false, true),
  ('leg_curl',             'a0000000-0000-0000-0000-000000000004', 'Leg Curl',                'Hamstrings',  true,  true),
  ('leg_press',            'a0000000-0000-0000-0000-000000000004', 'Leg Press',               'Quadriceps',  true,  true),
  ('leg_extensions',       'a0000000-0000-0000-0000-000000000004', 'Leg Extensions',          'Quadriceps',  true,  true),
  ('chest_press',          'a0000000-0000-0000-0000-000000000004', 'Chest Press',             'Chest',       true,  true),
  ('farmers_walk',         'a0000000-0000-0000-0000-000000000004', 'Farmer''s Walk',          'Full Body',   false, true),
  ('hack_squat',           'a0000000-0000-0000-0000-000000000004', 'Hack Squat',              'Quadriceps',  false, true),
  ('hip_thrust',           'a0000000-0000-0000-0000-000000000004', 'Hip Thrust',              'Glutes',      false, true),
  ('lateral_raise_seated', 'a0000000-0000-0000-0000-000000000004', 'Seated Lateral Raise',    'Shoulders',   false, true),
  ('lat_pulldown',         'a0000000-0000-0000-0000-000000000004', 'Lat Pulldown',            'Back',        true,  true),
  ('preacher_curl',        'a0000000-0000-0000-0000-000000000004', 'Preacher Curl',           'Biceps',      false, true),
  ('row_isolateral',       'a0000000-0000-0000-0000-000000000004', 'Isolateral Row',          'Back',        false, true),
  ('sled',                 'a0000000-0000-0000-0000-000000000004', 'Sled',                    'Legs',        false, true),
  ('incline_press',        'a0000000-0000-0000-0000-000000000004', 'Incline Press',           'Chest',       false, true),
  ('hyperextensions',      'a0000000-0000-0000-0000-000000000004', 'Hyperextensions',         'Lower Back',  false, true),
  ('t_bar_row',            'a0000000-0000-0000-0000-000000000004', 'T-Bar Row',               'Back',        false, true),
  ('overhead_press',       'a0000000-0000-0000-0000-000000000004', 'Overhead Press',          'Shoulders',   true,  true),
  ('calf_raise_machine',   'a0000000-0000-0000-0000-000000000004', 'Calf Machine',            'Calves',      false, true)
ON CONFLICT (key, gym_id) DO NOTHING;

-- ─── Gym equipment — MediFitness ─────────────────────────────────────────────
-- isMulti = Nein → fixed_machine (or cardio)  |  isMulti = Ja → open_station
-- "(leer)" manufacturer → NULL

INSERT INTO public.gym_equipment
  (id, gym_id, name, equipment_type, zone_name, canonical_exercise_key, manufacturer, is_active)
VALUES

-- ── FIXED MACHINES (isMulti = Nein) ──────────────────────────────────────────
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Bankdrücky',                   'fixed_machine', NULL, 'bench_press',          NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Bauchschaukel',                'fixed_machine', NULL, 'ab_swing',             NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Beinbeuger',                   'fixed_machine', NULL, 'leg_curl',             NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Beinpresse',                   'fixed_machine', NULL, 'leg_press',            NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Beinstrecker',                 'fixed_machine', NULL, 'leg_extensions',       NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Brustdrück Maschine',          'fixed_machine', NULL, 'chest_press',          NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Farmerwalk oder so',           'fixed_machine', NULL, 'farmers_walk',         NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Hackeschmitt',                 'fixed_machine', NULL, 'hack_squat',           NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Hip Thrust',                   'fixed_machine', NULL, 'hip_thrust',           NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Lateral Raise Seated',         'fixed_machine', NULL, 'lateral_raise_seated', NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Latzug Maschine',              'fixed_machine', NULL, 'lat_pulldown',         NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Preachercurls',                'fixed_machine', NULL, 'preacher_curl',        NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Rudermaschine Isolateral',     'fixed_machine', NULL, 'row_isolateral',       NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Schlitten',                    'fixed_machine', NULL, 'sled',                 NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Schrägbank Maschine',          'fixed_machine', NULL, 'incline_press',        NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Streckbank',                   'fixed_machine', NULL, 'hyperextensions',      NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'T-Bar Rudern',                 'fixed_machine', NULL, 't_bar_row',            NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Überkopfdrücken Maschine',     'fixed_machine', NULL, 'overhead_press',       NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Wadenheben',                   'fixed_machine', NULL, 'calf_raise_machine',   NULL, true),

-- ── CARDIO (isMulti = Nein, no exercise template) ─────────────────────────────
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Airbike',                      'cardio',        NULL, NULL,                  NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Ruder Ergometer',              'cardio',        NULL, NULL,                  NULL, true),

-- ── OPEN STATIONS (isMulti = Ja) ──────────────────────────────────────────────
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Gerüst',                       'open_station',  NULL, NULL,                  NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Kabelrudern',                  'open_station',  NULL, NULL,                  NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Kabelturm',                    'open_station',  NULL, NULL,                  NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Kurzhanteln',                  'open_station',  NULL, NULL,                  NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Latzug',                       'open_station',  NULL, NULL,                  NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000004', 'Squat Rack',                   'open_station',  NULL, NULL,                  NULL, true);
