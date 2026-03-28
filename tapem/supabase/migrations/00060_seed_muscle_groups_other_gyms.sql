-- =============================================================================
-- Tap'em — Seed muscle groups for exercise keys unique to non-Lifthouse gyms
--
-- Covers:
--   Fitseveneleven Schwalbach (00002): ab_lying, ab_crunch_machine,
--     bicep_curl_barbell, low_row_isolateral, back_extension, cable_row,
--     calf_raise_machine
--   Club Aktiv (00003): bootymizer, mid_row
--   MediFitness (00004): ab_swing, lateral_raise_seated, sled, farmers_walk
--
-- KSV Eisenschmiede (00005): all exercise keys were already covered by
-- migration 00055 — no new entries needed.
--
-- Uses the same JOIN-on-exercise_templates pattern as 00055 so each gym
-- that has the template gets its own row automatically.
-- ON CONFLICT DO NOTHING — fully idempotent.
-- =============================================================================

INSERT INTO public.exercise_muscle_groups (id, exercise_key, gym_id, muscle_group, role)
SELECT gen_random_uuid(), s.exercise_key, et.gym_id, s.muscle_group, s.role
FROM (VALUES

  -- ── Core machines ────────────────────────────────────────────────────────────
  ('ab_lying',           'core',        'primary'),
  ('ab_crunch_machine',  'core',        'primary'),
  ('ab_swing',           'core',        'primary'),

  -- ── Biceps ───────────────────────────────────────────────────────────────────
  ('bicep_curl_barbell', 'biceps',      'primary'),
  ('bicep_curl_barbell', 'forearms',    'secondary'),

  -- ── Back rows ────────────────────────────────────────────────────────────────
  -- low_row_isolateral: same muscle pattern as low_row + row_isolateral
  ('low_row_isolateral', 'upper_back',  'primary'),
  ('low_row_isolateral', 'lats',        'secondary'),
  ('low_row_isolateral', 'biceps',      'secondary'),

  -- cable_row: horizontal cable pull, identical to seated row
  ('cable_row',          'upper_back',  'primary'),
  ('cable_row',          'lats',        'secondary'),
  ('cable_row',          'biceps',      'secondary'),

  -- mid_row: mid-height row, same pattern
  ('mid_row',            'upper_back',  'primary'),
  ('mid_row',            'lats',        'secondary'),
  ('mid_row',            'biceps',      'secondary'),

  -- ── Lower back ───────────────────────────────────────────────────────────────
  -- back_extension: same as hyperextensions
  ('back_extension',     'lower_back',  'primary'),
  ('back_extension',     'glutes',      'secondary'),

  -- ── Calves ───────────────────────────────────────────────────────────────────
  ('calf_raise_machine', 'calves',      'primary'),

  -- ── Glutes ───────────────────────────────────────────────────────────────────
  -- bootymizer: glute-kickback / hip-extension isolation machine
  ('bootymizer',         'glutes',      'primary'),
  ('bootymizer',         'hamstrings',  'secondary'),

  -- ── Shoulders ────────────────────────────────────────────────────────────────
  ('lateral_raise_seated','side_shoulder','primary'),

  -- ── Legs ─────────────────────────────────────────────────────────────────────
  -- sled push: lower-body compound, similar to leg press
  ('sled',               'quads',       'primary'),
  ('sled',               'glutes',      'secondary'),
  ('sled',               'hamstrings',  'secondary'),

  -- ── Full body / functional ───────────────────────────────────────────────────
  -- farmer's walk: grip-dominant carry — forearms primary, core + traps secondary
  ('farmers_walk',       'forearms',    'primary'),
  ('farmers_walk',       'core',        'secondary'),
  ('farmers_walk',       'upper_back',  'secondary')

) AS s(exercise_key, muscle_group, role)
JOIN public.exercise_templates et ON et.key = s.exercise_key
ON CONFLICT (exercise_key, gym_id, muscle_group) DO NOTHING;
