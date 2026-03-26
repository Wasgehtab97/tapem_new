-- =============================================================================
-- Tap'em — KSV Eisenschmiede gym + equipment seed
-- 10 fixed machines, 7 open stations, 10 exercise templates
-- Gym ID  : a0000000-0000-0000-0000-000000000005
-- Join code: EISEN1
-- =============================================================================

-- ─── Insert gym ──────────────────────────────────────────────────────────────

INSERT INTO public.tenant_gyms (id, name, slug, join_code)
VALUES (
  'a0000000-0000-0000-0000-000000000005',
  'KSV Eisenschmiede',
  'ksv-eisenschmiede',
  'EISEN1'
)
ON CONFLICT (id) DO UPDATE
  SET join_code = 'EISEN1',
      name      = 'KSV Eisenschmiede',
      slug      = 'ksv-eisenschmiede';

-- ─── Exercise templates for KSV Eisenschmiede ────────────────────────────────

INSERT INTO public.exercise_templates
  (key, gym_id, name, primary_muscle_group, is_ranking_eligible, is_active)
VALUES
  ('hip_abduction',    'a0000000-0000-0000-0000-000000000005', 'Hip Abduction',     'Abductors',   false, true),
  ('hip_adduction',    'a0000000-0000-0000-0000-000000000005', 'Hip Adduction',     'Adductors',   false, true),
  ('lying_leg_curl',   'a0000000-0000-0000-0000-000000000005', 'Lying Leg Curl',    'Hamstrings',  false, true),
  ('leg_press',        'a0000000-0000-0000-0000-000000000005', 'Leg Press',         'Quadriceps',  true,  true),
  ('leg_extensions',   'a0000000-0000-0000-0000-000000000005', 'Leg Extensions',    'Quadriceps',  true,  true),
  ('deadlift',         'a0000000-0000-0000-0000-000000000005', 'Deadlift',          'Back',        true,  true),
  ('hack_squat',       'a0000000-0000-0000-0000-000000000005', 'Hack Squat',        'Quadriceps',  false, true),
  ('hip_thrust',       'a0000000-0000-0000-0000-000000000005', 'Hip Thrust',        'Glutes',      false, true),
  ('hyperextensions',  'a0000000-0000-0000-0000-000000000005', 'Hyperextensions',   'Lower Back',  false, true),
  ('calf_raise_seated','a0000000-0000-0000-0000-000000000005', 'Seated Calf Raise', 'Calves',      false, true)
ON CONFLICT (key, gym_id) DO NOTHING;

-- ─── Gym equipment — KSV Eisenschmiede ───────────────────────────────────────
-- isMulti = Nein → fixed_machine  |  isMulti = Ja → open_station
-- "(leer)" manufacturer → NULL

INSERT INTO public.gym_equipment
  (id, gym_id, name, equipment_type, zone_name, canonical_exercise_key, manufacturer, is_active)
VALUES

-- ── FIXED MACHINES (isMulti = Nein) ──────────────────────────────────────────
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Abductor Maschine',              'fixed_machine', NULL, 'hip_abduction',    NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Adductor Maschine',              'fixed_machine', NULL, 'hip_adduction',    NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Beinbeuger liegend Maschine',    'fixed_machine', NULL, 'lying_leg_curl',   NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Beinpresse',                     'fixed_machine', NULL, 'leg_press',        NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Beinstrecker sitzend Maschine',  'fixed_machine', NULL, 'leg_extensions',   NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Deadlift',                       'fixed_machine', NULL, 'deadlift',         NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Hack Squat Maschine',            'fixed_machine', NULL, 'hack_squat',       NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Hipthrust Maschine',             'fixed_machine', NULL, 'hip_thrust',       NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Hyperextension oder Nordic Ding','fixed_machine', NULL, 'hyperextensions',  NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Wadenmaschine sitzend',          'fixed_machine', NULL, 'calf_raise_seated',NULL, true),

-- ── OPEN STATIONS (isMulti = Ja) ──────────────────────────────────────────────
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Flachbank',                      'open_station',  NULL, NULL, NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Kettlebells',                    'open_station',  NULL, NULL, NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Kurzhantel',                     'open_station',  NULL, NULL, NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Latzug',                         'open_station',  NULL, NULL, NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Multipresse',                    'open_station',  NULL, NULL, NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Rack',                           'open_station',  NULL, NULL, NULL, true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000005', 'Schrägbank',                     'open_station',  NULL, NULL, NULL, true);
