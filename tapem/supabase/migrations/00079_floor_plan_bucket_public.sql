-- =============================================================================
-- Tap'em — 00079: Make floor-plans bucket public
--
-- Floor plan images are not sensitive (it's a map of a gym).
-- Making the bucket public allows Image.network() in Flutter to load
-- the image without Supabase auth headers.
-- Write access is still governed by the RLS policies from migration 00078.
-- =============================================================================

UPDATE storage.buckets
   SET public = true
 WHERE id = 'floor-plans';
