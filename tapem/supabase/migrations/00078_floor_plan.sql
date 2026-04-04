-- =============================================================================
-- Tap'em — 00078: Gym Floor Plan
--
-- Adds support for an interactive gym floor plan:
--   1. pos_x / pos_y on gym_equipment  — normalised (0.0–1.0) dot coordinates
--   2. floor_plan_image_url / floor_plan_aspect_ratio on tenant_gyms
--   3. Supabase Storage bucket "floor-plans" with RLS
--
-- Gymgoers use the floor plan to tap on a piece of equipment instead of
-- scanning an NFC tag or using text search.  Admins position each device
-- by uploading a floor-plan image and dragging / tapping dots on the canvas.
-- =============================================================================

-- =============================================================================
-- SECTION 1 — gym_equipment: position coordinates
-- =============================================================================

ALTER TABLE public.gym_equipment
  ADD COLUMN IF NOT EXISTS pos_x DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS pos_y DOUBLE PRECISION;

COMMENT ON COLUMN public.gym_equipment.pos_x IS
  'Normalised X position (0.0 = left edge, 1.0 = right edge) on the gym floor plan image. NULL = not yet positioned.';
COMMENT ON COLUMN public.gym_equipment.pos_y IS
  'Normalised Y position (0.0 = top edge, 1.0 = bottom edge) on the gym floor plan image. NULL = not yet positioned.';

-- =============================================================================
-- SECTION 2 — tenant_gyms: floor plan metadata
-- =============================================================================

ALTER TABLE public.tenant_gyms
  ADD COLUMN IF NOT EXISTS floor_plan_image_url      TEXT,
  ADD COLUMN IF NOT EXISTS floor_plan_aspect_ratio   DOUBLE PRECISION;

COMMENT ON COLUMN public.tenant_gyms.floor_plan_image_url IS
  'Public URL of the gym floor plan image stored in the "floor-plans" Storage bucket.';
COMMENT ON COLUMN public.tenant_gyms.floor_plan_aspect_ratio IS
  'Image width ÷ height, stored at upload time so the client can layout the canvas without fetching image dimensions at runtime.';

-- =============================================================================
-- SECTION 3 — Storage bucket "floor-plans"
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'floor-plans',
  'floor-plans',
  false,            -- not publicly listed; URLs are authenticated
  10485760,         -- 10 MB per image
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- SECTION 4 — Storage RLS policies
--
-- Authenticated members of a gym can read its floor plan.
-- Only gym admins/owners may write (INSERT / UPDATE / DELETE).
--
-- File path convention: {gym_id}/{timestamp}_floor_plan.{ext}
-- The first path component is always the gym UUID.
-- =============================================================================

-- SELECT: any authenticated member can download the image.
CREATE POLICY "floor_plans_read"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'floor-plans');

-- INSERT: only gym admins may upload a floor plan for their gym.
CREATE POLICY "floor_plans_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'floor-plans'
    AND public.is_gym_admin(
      (split_part(name, '/', 1))::UUID
    )
  );

-- UPDATE: same restriction as INSERT.
CREATE POLICY "floor_plans_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'floor-plans'
    AND public.is_gym_admin(
      (split_part(name, '/', 1))::UUID
    )
  );

-- DELETE: same restriction.
CREATE POLICY "floor_plans_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'floor-plans'
    AND public.is_gym_admin(
      (split_part(name, '/', 1))::UUID
    )
  );
