-- =============================================================================
-- Tap'em — 00080: Assign floor plan to "Lifthouse test"
--
-- Uses the committed public GitHub SVG as the initial floor plan so the
-- feature works immediately without a manual in-app upload step.
-- =============================================================================

UPDATE public.tenant_gyms
   SET floor_plan_image_url = 'https://raw.githubusercontent.com/Wasgehtab97/tapem_new/main/lifthouse_floorplan.svg',
       floor_plan_aspect_ratio = 1500.0 / 700.0
 WHERE id = 'a0000000-0000-0000-0000-000000000099';
