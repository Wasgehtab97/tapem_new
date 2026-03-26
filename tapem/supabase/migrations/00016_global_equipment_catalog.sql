-- =============================================================================
-- Tap'em — Global Equipment Catalog
-- Normalizes manufacturer + model across gyms.
-- Enables future cross-gym leaderboards by equipment model.
-- Additive only — no existing data is removed or modified beyond catalog_id FK.
-- =============================================================================

-- ─── global_equipment_catalog ─────────────────────────────────────────────────

CREATE TABLE public.global_equipment_catalog (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer           TEXT NOT NULL,
  model_name             TEXT NOT NULL,
  model_number           TEXT,          -- OEM model / product number (optional)
  equipment_type         equipment_type NOT NULL,
  canonical_exercise_key TEXT,          -- for fixed_machine entries
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_global_equipment_catalog_unique
  ON public.global_equipment_catalog (LOWER(manufacturer), LOWER(model_name));

COMMENT ON TABLE public.global_equipment_catalog IS
  'Platform-managed catalog of equipment models. Gym equipment rows reference '
  'this table to enable cross-gym comparisons and future leaderboards.';

COMMENT ON COLUMN public.global_equipment_catalog.model_number IS
  'Manufacturer product / model number for barcode or NFC-based identification.';

-- ─── RLS ──────────────────────────────────────────────────────────────────────

ALTER TABLE public.global_equipment_catalog ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read the catalog (display manufacturer, model).
CREATE POLICY "catalog_read_authenticated"
  ON public.global_equipment_catalog FOR SELECT
  TO authenticated
  USING (TRUE);

-- INSERT / UPDATE / DELETE only via service role (no authenticated policy).

-- ─── gym_equipment: catalog_id FK ─────────────────────────────────────────────

ALTER TABLE public.gym_equipment
  ADD COLUMN IF NOT EXISTS catalog_id UUID
    REFERENCES public.global_equipment_catalog(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.gym_equipment.catalog_id IS
  'FK to global_equipment_catalog. Nullable — not all equipment is catalogued. '
  'When set, enables cross-gym ranking by this specific model.';

CREATE INDEX IF NOT EXISTS idx_gym_equipment_catalog_id
  ON public.gym_equipment (catalog_id)
  WHERE catalog_id IS NOT NULL;

-- ─── Seed catalog from existing gym equipment ──────────────────────────────────
-- Insert one catalog entry per distinct (manufacturer, name) pair.
-- Gym equipment that shares manufacturer + name across multiple gyms will map
-- to the same catalog row after the UPDATE below.

INSERT INTO public.global_equipment_catalog
  (manufacturer, model_name, equipment_type, canonical_exercise_key)
SELECT DISTINCT ON (LOWER(manufacturer), LOWER(name))
  manufacturer,
  name                   AS model_name,
  equipment_type,
  canonical_exercise_key
FROM public.gym_equipment
WHERE manufacturer IS NOT NULL
  AND TRIM(manufacturer) <> ''
ORDER BY LOWER(manufacturer), LOWER(name), created_at
ON CONFLICT DO NOTHING;

-- Wire existing gym_equipment rows to the catalog entries created above.
UPDATE public.gym_equipment ge
SET    catalog_id = gc.id
FROM   public.global_equipment_catalog gc
WHERE  ge.manufacturer IS NOT NULL
  AND  LOWER(ge.manufacturer) = LOWER(gc.manufacturer)
  AND  LOWER(ge.name)         = LOWER(gc.model_name)
  AND  ge.catalog_id IS NULL;
