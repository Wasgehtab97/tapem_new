-- =============================================================================
-- Tap'em — Link user_custom_exercises to gym_equipment
-- =============================================================================

ALTER TABLE public.user_custom_exercises
  ADD COLUMN IF NOT EXISTS equipment_id UUID
    REFERENCES public.gym_equipment(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_custom_exercises_equipment
  ON public.user_custom_exercises (gym_id, user_id, equipment_id)
  WHERE equipment_id IS NOT NULL;
