-- =============================================================================
-- Tap'em — Table grants for authenticated and anon roles
-- RLS policies control row-level access; these grants give the roles
-- the basic table-level privileges required for PostgREST to attempt them.
-- =============================================================================

-- authenticated role: full CRUD on all app tables (RLS enforces row access)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tenant_gyms              TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_profiles            TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.username_reservations    TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.memberships              TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.gym_equipment            TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.equipment_tags           TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.exercise_templates       TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.muscle_group_weights     TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_custom_exercises    TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_sessions         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.session_exercises        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.set_entries              TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.xp_events               TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_gym_xp             TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_exercise_xp        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_muscle_group_xp    TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.level_snapshots         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.achievements            TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.challenges              TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ranking_events          TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ranking_snapshots       TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.feed_events             TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.friendships             TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications           TO authenticated;

-- anon role: read-only on public gym directory (needed for signup flow)
GRANT SELECT ON public.tenant_gyms TO anon;
