-- =============================================================================
-- Tap'em — Fix missing secondary muscle groups across all Lifthouse exercises
--
-- All entries use ON CONFLICT DO NOTHING — fully idempotent.
-- =============================================================================

INSERT INTO public.exercise_muscle_groups (id, exercise_key, gym_id, muscle_group, role)
SELECT gen_random_uuid(), s.exercise_key, et.gym_id, s.muscle_group, s.role
FROM (VALUES
  -- ── Chest presses: all press variants extend the elbow → triceps secondary ──
  ('chest_press_isolateral',     'triceps',    'secondary'),
  ('incline_press_isolateral',   'triceps',    'secondary'),
  ('plate_loaded_chest_press',   'triceps',    'secondary'),
  ('plate_loaded_press',         'triceps',    'secondary'),
  ('wide_chest_press_isolateral','triceps',    'secondary'),
  ('super_incline_isolateral',   'triceps',    'secondary'),

  -- ── Back: pulldowns also hit upper_back ────────────────────────────────────
  ('front_pulldown',             'upper_back', 'secondary'),
  ('lat_pulldown_isolateral',    'upper_back', 'secondary'),

  -- ── Back: isolateral rows also hit lats ────────────────────────────────────
  ('high_row_isolateral',        'lats',       'secondary'),
  ('row_isolateral',             'lats',       'secondary'),

  -- ── Back: every rowing movement uses biceps ────────────────────────────────
  ('low_row',                    'biceps',     'secondary'),
  ('wide_row',                   'biceps',     'secondary'),

  -- ── Shoulders: standing overhead press uses triceps ────────────────────────
  ('standing_press',             'triceps',    'secondary'),

  -- ── Legs: isolateral leg curl same as regular (has glutes secondary) ───────
  ('leg_curl_isolateral',        'glutes',     'secondary'),

  -- ── Arms: preacher curl engages forearms (consistent with bicep_curl) ──────
  ('preacher_curl',              'forearms',   'secondary')

) AS s(exercise_key, muscle_group, role)
JOIN public.exercise_templates et ON et.key = s.exercise_key
ON CONFLICT (exercise_key, gym_id, muscle_group) DO NOTHING;
