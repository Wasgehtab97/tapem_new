-- =============================================================================
-- 00073_enforce_rls_all_tables.sql
-- Security: Enable RLS on all public tables + backfill missing policies
--
-- Root cause: Migration 00005 re-applied missing RLS policies after 00002 was
-- marked applied but not executed — however 00005 omitted:
--   (a) the ENABLE ROW LEVEL SECURITY statements on all tables, and
--   (b) policies for non-core tables (challenges, achievements, level_snapshots,
--       user_muscle_group_xp, ranking_events, ranking_snapshots, feed_events,
--       equipment_tags, username_reservations).
--
-- Fix strategy:
--   1. ENABLE ROW LEVEL SECURITY on every public table (idempotent).
--   2. Backfill missing policies with DO/EXCEPTION blocks (idempotent).
--   3. Harden workout_sessions and user_custom_exercises policies to also
--      enforce has_active_membership() as originally intended in 00002.
--   4. Ensure service_role GRANT coverage for every table.
-- =============================================================================

-- =============================================================================
-- STEP 1: Enable RLS on all public tables (idempotent — safe if already enabled)
-- =============================================================================

-- Core user / gym
ALTER TABLE public.tenant_gyms                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.username_reservations            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memberships                      ENABLE ROW LEVEL SECURITY;

-- Equipment & exercises
ALTER TABLE public.gym_equipment                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_tags                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_templates               ENABLE ROW LEVEL SECURITY;
-- muscle_group_weights was dropped in 00055 (superseded by exercise_muscle_groups)
ALTER TABLE public.exercise_muscle_groups           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_custom_exercises            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_custom_exercise_muscle_groups ENABLE ROW LEVEL SECURITY;

-- Workout sessions
ALTER TABLE public.workout_sessions                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_exercises                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.set_entries                      ENABLE ROW LEVEL SECURITY;

-- Plans
ALTER TABLE public.workout_plans                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_items                       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_assignments                 ENABLE ROW LEVEL SECURITY;

-- XP & leveling
ALTER TABLE public.xp_events                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_gym_xp                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_exercise_xp                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_muscle_group_xp             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.level_snapshots                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements                     ENABLE ROW LEVEL SECURITY;

-- Community / social
ALTER TABLE public.challenges                       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ranking_events                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ranking_snapshots                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_events                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications                    ENABLE ROW LEVEL SECURITY;

-- Catalog / misc
ALTER TABLE public.global_equipment_catalog         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_feedback               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_equipment_name_overrides    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_machine_exercise_best       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_machine_equipment_best      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gym_deals                        ENABLE ROW LEVEL SECURITY;

-- Nutrition
ALTER TABLE public.nutrition_goals                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_goal_defaults          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_logs                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_year_summaries         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_recipes                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_products               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_weight_logs            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_weight_year_summaries  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_weight_meta            ENABLE ROW LEVEL SECURITY;


-- =============================================================================
-- STEP 2: Backfill policies that were never applied to the live DB
-- These tables showed "RLS Disabled in Public" without "Policy Exists" —
-- confirmed absent from pg_policies at time of this migration.
-- Pattern: DO/EXCEPTION WHEN duplicate_object — safe if already present.
-- =============================================================================

-- ─── username_reservations ────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE POLICY "reservations_manage_own"
    ON public.username_reservations FOR ALL
    TO authenticated
    USING   (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── equipment_tags ───────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE POLICY "equipment_tags_read_members"
    ON public.equipment_tags FOR SELECT
    TO authenticated
    USING (public.has_active_membership(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "equipment_tags_admin_manage"
    ON public.equipment_tags FOR ALL
    TO authenticated
    USING   (public.is_gym_admin(gym_id))
    WITH CHECK (public.is_gym_admin(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── challenges ───────────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE POLICY "challenges_read_members"
    ON public.challenges FOR SELECT
    TO authenticated
    USING (public.has_active_membership(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "challenges_admin_manage"
    ON public.challenges FOR ALL
    TO authenticated
    USING   (public.is_gym_admin(gym_id))
    WITH CHECK (public.is_gym_admin(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── user_muscle_group_xp ────────────────────────────────────────────────────
-- Read-only for users. Service role writes via Edge Functions.
DO $$ BEGIN
  CREATE POLICY "user_muscle_group_xp_read_own"
    ON public.user_muscle_group_xp FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── user_exercise_xp ────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE POLICY "user_exercise_xp_read_own"
    ON public.user_exercise_xp FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── level_snapshots ──────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE POLICY "level_snapshots_read_own"
    ON public.level_snapshots FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── achievements ─────────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE POLICY "achievements_read_own"
    ON public.achievements FOR SELECT
    TO authenticated
    USING (user_id = auth.uid() AND public.has_active_membership(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  -- are_friends() is pair-global after 00049; gym_id param kept for compat
  CREATE POLICY "achievements_read_friends"
    ON public.achievements FOR SELECT
    TO authenticated
    USING (
      public.are_friends(auth.uid(), user_id, gym_id)
      AND (SELECT privacy_level FROM public.user_profiles WHERE id = user_id) != 'private'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── ranking_events ───────────────────────────────────────────────────────────
-- Write: service_role only (via Edge Functions / triggers)
DO $$ BEGIN
  CREATE POLICY "ranking_events_read_members"
    ON public.ranking_events FOR SELECT
    TO authenticated
    USING (public.has_active_membership(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── ranking_snapshots ────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE POLICY "ranking_snapshots_read_members"
    ON public.ranking_snapshots FOR SELECT
    TO authenticated
    USING (public.has_active_membership(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── feed_events ──────────────────────────────────────────────────────────────
-- Write: service_role only (inserted by Edge Functions on session finish)
DO $$ BEGIN
  CREATE POLICY "feed_events_read_own"
    ON public.feed_events FOR SELECT
    TO authenticated
    USING (actor_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "feed_events_read_friends"
    ON public.feed_events FOR SELECT
    TO authenticated
    USING (
      public.are_friends(auth.uid(), actor_id, gym_id)
      AND (SELECT privacy_level FROM public.user_profiles WHERE id = actor_id) != 'private'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- =============================================================================
-- STEP 3: Harden policies that 00005 applied with weaker conditions than 00002
-- Replace the simplified versions with membership-scoped originals.
-- =============================================================================

-- ─── workout_sessions: re-apply membership check ──────────────────────────────
-- 00005 applied: USING (user_id = auth.uid())
-- 00002 intent:  USING (user_id = auth.uid() AND has_active_membership(gym_id))
-- Replacing with the stricter form to prevent orphan access from lapsed members.
DROP POLICY IF EXISTS "sessions_own" ON public.workout_sessions;
CREATE POLICY "sessions_own"
  ON public.workout_sessions FOR ALL
  TO authenticated
  USING   (user_id = auth.uid() AND public.has_active_membership(gym_id))
  WITH CHECK (user_id = auth.uid() AND public.has_active_membership(gym_id));

-- ─── user_custom_exercises: re-apply membership check ─────────────────────────
-- 00005 applied: USING (user_id = auth.uid()) — no gym membership check
-- 00002 intent:  also require has_active_membership(gym_id)
DROP POLICY IF EXISTS "custom_exercises_own" ON public.user_custom_exercises;
CREATE POLICY "custom_exercises_own"
  ON public.user_custom_exercises FOR ALL
  TO authenticated
  USING   (user_id = auth.uid() AND public.has_active_membership(gym_id))
  WITH CHECK (user_id = auth.uid() AND public.has_active_membership(gym_id));


-- =============================================================================
-- STEP 4: Ensure service_role GRANT coverage for tables added after 00036
-- (00036 covers all original tables; later migrations add their own grants,
--  but this ensures nothing was missed.)
-- =============================================================================

GRANT ALL ON public.ranking_events              TO service_role;
GRANT ALL ON public.ranking_snapshots           TO service_role;
GRANT ALL ON public.feed_events                 TO service_role;
GRANT ALL ON public.achievements                TO service_role;
GRANT ALL ON public.level_snapshots             TO service_role;
GRANT ALL ON public.challenges                  TO service_role;
GRANT ALL ON public.user_muscle_group_xp        TO service_role;
GRANT ALL ON public.user_exercise_xp            TO service_role;
GRANT ALL ON public.plan_items                  TO service_role;
GRANT ALL ON public.plan_assignments            TO service_role;
GRANT ALL ON public.global_equipment_catalog    TO service_role;
