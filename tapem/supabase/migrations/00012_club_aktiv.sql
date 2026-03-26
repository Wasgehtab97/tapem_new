-- =============================================================================
-- Tap'em — Club Aktiv gym + equipment seed
-- 13 fixed machines, 9 open stations, 13 exercise templates
-- Gym ID  : a0000000-0000-0000-0000-000000000003
-- Join code: AKTIV1
-- =============================================================================

-- ─── Insert gym ──────────────────────────────────────────────────────────────

INSERT INTO public.tenant_gyms (id, name, slug, join_code)
VALUES (
  'a0000000-0000-0000-0000-000000000003',
  'Club Aktiv',
  'club-aktiv',
  'AKTIV1'
)
ON CONFLICT (id) DO UPDATE
  SET join_code = 'AKTIV1',
      name      = 'Club Aktiv',
      slug      = 'club-aktiv';

-- ─── Exercise templates for Club Aktiv ────────────────────────────────────────

INSERT INTO public.exercise_templates
  (key, gym_id, name, primary_muscle_group, is_ranking_eligible, is_active)
VALUES
  ('hip_abduction',           'a0000000-0000-0000-0000-000000000003', 'Hip Abduction',             'Abductors',   false, true),
  ('hip_adduction',           'a0000000-0000-0000-0000-000000000003', 'Hip Adduction',             'Adductors',   false, true),
  ('leg_press',               'a0000000-0000-0000-0000-000000000003', 'Leg Press',                 'Quadriceps',  true,  true),
  ('bootymizer',              'a0000000-0000-0000-0000-000000000003', 'Bootymizer',                'Glutes',      false, true),
  ('chest_press',             'a0000000-0000-0000-0000-000000000003', 'Chest Press',               'Chest',       true,  true),
  ('incline_press',           'a0000000-0000-0000-0000-000000000003', 'Incline Press',             'Chest',       false, true),
  ('lying_leg_curl',          'a0000000-0000-0000-0000-000000000003', 'Lying Leg Curl',            'Hamstrings',  false, true),
  ('seated_leg_curl',         'a0000000-0000-0000-0000-000000000003', 'Seated Leg Curl',           'Hamstrings',  false, true),
  ('leg_extensions',          'a0000000-0000-0000-0000-000000000003', 'Leg Extensions',            'Quadriceps',  true,  true),
  ('mid_row',                 'a0000000-0000-0000-0000-000000000003', 'Mid Row',                   'Back',        false, true),
  ('overhead_press',          'a0000000-0000-0000-0000-000000000003', 'Overhead Press',            'Shoulders',   true,  true),
  ('lateral_raise',           'a0000000-0000-0000-0000-000000000003', 'Lateral Raise',             'Shoulders',   true,  true),
  ('lat_pulldown_isolateral', 'a0000000-0000-0000-0000-000000000003', 'Unilateral Lat Pulldown',   'Back',        false, true)
ON CONFLICT (key, gym_id) DO NOTHING;

-- ─── Gym equipment — Club Aktiv ───────────────────────────────────────────────
-- isMulti = Nein → fixed_machine  |  isMulti = Ja → open_station

INSERT INTO public.gym_equipment
  (id, gym_id, name, equipment_type, zone_name, canonical_exercise_key, manufacturer, is_active)
VALUES

-- ── FIXED MACHINES (isMulti = Nein) ──────────────────────────────────────────
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Abduktor',                 'fixed_machine', NULL, 'hip_abduction',           'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Adduktor',                 'fixed_machine', NULL, 'hip_adduction',           'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Beinpresse',               'fixed_machine', NULL, 'leg_press',               'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Bootymizer',               'fixed_machine', NULL, 'bootymizer',              'gym80',              true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Brustpresse',              'fixed_machine', NULL, 'chest_press',             'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Incline Press',            'fixed_machine', NULL, 'incline_press',           'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Leg Curl liegend',         'fixed_machine', NULL, 'lying_leg_curl',          'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Leg Curl sitzend',         'fixed_machine', NULL, 'seated_leg_curl',         'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Leg Extensions',           'fixed_machine', NULL, 'leg_extensions',          'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Mid Row',                  'fixed_machine', NULL, 'mid_row',                 'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Overhead Press',           'fixed_machine', NULL, 'overhead_press',          'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Seitheben',                'fixed_machine', NULL, 'lateral_raise',           'Schnell',            true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Unilaterales Latziehen',   'fixed_machine', NULL, 'lat_pulldown_isolateral', 'Nautilus',           true),

-- ── OPEN STATIONS (isMulti = Ja) ──────────────────────────────────────────────
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Fly / Reverse Fly',        'open_station',  NULL, NULL, 'Hammer Strength',    true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Hacksquat',                'open_station',  NULL, NULL, 'SportsArt Fitness',  true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Kabelturm',                'open_station',  NULL, NULL, 'BHFitness',          true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Kabelturm',                'open_station',  NULL, NULL, 'LifeFitness',        true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Kabelturm',                'open_station',  NULL, NULL, 'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Kraken',                   'open_station',  NULL, NULL, 'Matrix',             true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Kurzhanteln',              'open_station',  NULL, NULL, NULL,                 true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Multipresse',              'open_station',  NULL, NULL, 'Nautilus',           true),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000003', 'Tbar',                     'open_station',  NULL, NULL, 'Titanium Strength',  true);
