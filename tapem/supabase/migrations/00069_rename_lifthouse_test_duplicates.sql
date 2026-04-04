-- =============================================================================
-- Tap'em — Rename duplicate equipment in "Lifthouse test" gym
-- Gym ID: a0000000-0000-0000-0000-000000000099
--
-- Problem: Equipment pieces with the same name AND same manufacturer are
-- indistinguishable for gym members. This migration appends " 1", " 2", etc.
-- to disambiguate them.
--
-- Affected groups (same name + same manufacturer):
--   Abductor          (Schnell ×2)
--   Adductor          (Schnell ×2)
--   Benchpress        (Eleiko ×2)
--   Compound Row      (Nautilus ×2)
--   Incline Press     (Nautilus ×2)
--   Leg Press         (Cybex ×2)
--   Cable Tower       (Matrix ×2)
--   Rack              (Eleiko ×2)
--   Vertical Press    (Nautilus ×2)
-- =============================================================================

DO $$
DECLARE
  r RECORD;
BEGIN
  -- Find all equipment rows in the Lifthouse test gym that share the exact
  -- same (name, manufacturer) with at least one other row, then number them.
  FOR r IN
    WITH numbered AS (
      SELECT
        id,
        name,
        manufacturer,
        ROW_NUMBER() OVER (
          PARTITION BY name, COALESCE(manufacturer, '__NULL__')
          ORDER BY id   -- deterministic ordering by UUID
        ) AS rn,
        COUNT(*) OVER (
          PARTITION BY name, COALESCE(manufacturer, '__NULL__')
        ) AS cnt
      FROM public.gym_equipment
      WHERE gym_id = 'a0000000-0000-0000-0000-000000000099'
        AND is_active = true
    )
    SELECT id, name, manufacturer, rn
    FROM numbered
    WHERE cnt > 1
  LOOP
    UPDATE public.gym_equipment
    SET name = r.name || ' ' || r.rn
    WHERE id = r.id;
  END LOOP;
END $$;
