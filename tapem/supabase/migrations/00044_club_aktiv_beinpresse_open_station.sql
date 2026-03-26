-- =============================================================================
-- Club Aktiv — Beinpresse (Nautilus): fixed_machine → open_station
--
-- The Leg Press Nautilus at Club Aktiv was seeded as fixed_machine with
-- canonical_exercise_key = 'leg_press'.  The gym operator has confirmed it
-- should be classified as open_station (multiple exercises possible).
--
-- Changes:
--   equipment_type         : fixed_machine → open_station
--   canonical_exercise_key : 'leg_press'  → NULL
--   updated_at             : refreshed
--
-- The exercise_template 'leg_press' for Club Aktiv is kept active so that
-- existing session history referencing that key remains intact and readable
-- in the UI.  New users will create custom exercises on the open station.
-- =============================================================================

UPDATE public.gym_equipment
SET
  equipment_type         = 'open_station',
  canonical_exercise_key = NULL,
  updated_at             = NOW()
WHERE
  gym_id                 = 'a0000000-0000-0000-0000-000000000003'
  AND name               = 'Beinpresse'
  AND manufacturer       = 'Nautilus'
  AND canonical_exercise_key = 'leg_press';
