-- =============================================================================
-- Tap'em — Muscle group grants
-- =============================================================================

GRANT ALL ON public.exercise_muscle_groups               TO authenticated;
GRANT ALL ON public.user_custom_exercise_muscle_groups   TO authenticated;
GRANT ALL ON public.exercise_muscle_groups               TO service_role;
GRANT ALL ON public.user_custom_exercise_muscle_groups   TO service_role;
