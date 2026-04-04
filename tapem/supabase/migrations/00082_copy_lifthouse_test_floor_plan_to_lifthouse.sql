-- =============================================================================
-- Tap'em — 00082: Copy the Lifthouse test floor plan to Lifthouse
-- =============================================================================

UPDATE public.tenant_gyms AS target
   SET floor_plan_image_url    = source.floor_plan_image_url,
       floor_plan_aspect_ratio = source.floor_plan_aspect_ratio
  FROM public.tenant_gyms AS source
 WHERE target.id = 'a0000000-0000-0000-0000-000000000001'
   AND LOWER(source.name) = 'lifthouse test';
