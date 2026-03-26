-- =============================================================================
-- Tap'em — 00036: Grant service_role table-level privileges
--
-- Problem:
--   The sync-workout Edge Function uses a service_role Supabase client to
--   bypass RLS and write session/exercise/XP data. However, PostgREST still
--   enforces table-level GRANT privileges even for the service_role.
--
--   Migration 00006 only grants CRUD to `authenticated`. The `service_role`
--   was missing explicit grants, causing "permission denied for table X" errors
--   when the edge function attempts to write (INSERT/UPDATE via upsert).
--
--   The specific failure observed: membership upsert in sync-workout returned
--   "permission denied for table memberships" (PostgreSQL error 42501).
--
-- Fix:
--   Grant ALL privileges on all app tables to service_role.
--   The service_role already has BYPASSRLS — these grants enable table access.
-- =============================================================================

GRANT ALL ON public.memberships           TO service_role;
GRANT ALL ON public.workout_sessions      TO service_role;
GRANT ALL ON public.session_exercises     TO service_role;
GRANT ALL ON public.set_entries           TO service_role;
GRANT ALL ON public.xp_events             TO service_role;
GRANT ALL ON public.user_gym_xp           TO service_role;
GRANT ALL ON public.user_exercise_xp      TO service_role;
GRANT ALL ON public.user_muscle_group_xp  TO service_role;
GRANT ALL ON public.user_profiles         TO service_role;
GRANT ALL ON public.tenant_gyms           TO service_role;
GRANT ALL ON public.gym_equipment         TO service_role;
GRANT ALL ON public.muscle_group_weights  TO service_role;
GRANT ALL ON public.exercise_templates    TO service_role;
GRANT ALL ON public.user_custom_exercises TO service_role;
GRANT ALL ON public.level_snapshots       TO service_role;
GRANT ALL ON public.achievements          TO service_role;
GRANT ALL ON public.challenges            TO service_role;
GRANT ALL ON public.ranking_events        TO service_role;
GRANT ALL ON public.ranking_snapshots     TO service_role;
GRANT ALL ON public.feed_events           TO service_role;
GRANT ALL ON public.friendships           TO service_role;
GRANT ALL ON public.notifications         TO service_role;
GRANT ALL ON public.equipment_tags        TO service_role;
GRANT ALL ON public.username_reservations TO service_role;
