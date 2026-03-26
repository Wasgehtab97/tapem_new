-- =============================================================================
-- Tap'em — Create "Lifthouse test" gym for developer testing
-- Duplicates all exercise_templates and gym_equipment from Lifthouse
-- (a0000000-0000-0000-0000-000000000001) into a new isolated test gym.
-- Join code: LHTEST
-- =============================================================================

-- ─── New gym row ──────────────────────────────────────────────────────────────

INSERT INTO public.tenant_gyms (id, name, slug, join_code, country_code, is_active)
VALUES (
  'a0000000-0000-0000-0000-000000000099',
  'Lifthouse test',
  'lifthouse-test',
  'LHTEST',
  'DE',
  TRUE
)
ON CONFLICT (id) DO UPDATE
  SET name      = 'Lifthouse test',
      slug      = 'lifthouse-test',
      join_code = 'LHTEST';

-- ─── Copy exercise templates ──────────────────────────────────────────────────
-- Same exercise keys as Lifthouse, just bound to the new gym_id.

INSERT INTO public.exercise_templates
  (key, gym_id, name, primary_muscle_group, is_ranking_eligible, is_active)
SELECT
  key,
  'a0000000-0000-0000-0000-000000000099',
  name,
  primary_muscle_group,
  is_ranking_eligible,
  is_active
FROM public.exercise_templates
WHERE gym_id = 'a0000000-0000-0000-0000-000000000001'
ON CONFLICT (key, gym_id) DO NOTHING;

-- ─── Copy gym equipment ───────────────────────────────────────────────────────
-- New UUIDs, new gym_id. canonical_exercise_key references stay valid because
-- the exercise templates above share the same keys in the new gym.

INSERT INTO public.gym_equipment
  (id, gym_id, name, equipment_type, zone_name, canonical_exercise_key, manufacturer, is_active)
SELECT
  gen_random_uuid(),
  'a0000000-0000-0000-0000-000000000099',
  name,
  equipment_type,
  zone_name,
  canonical_exercise_key,
  manufacturer,
  is_active
FROM public.gym_equipment
WHERE gym_id = 'a0000000-0000-0000-0000-000000000001';
