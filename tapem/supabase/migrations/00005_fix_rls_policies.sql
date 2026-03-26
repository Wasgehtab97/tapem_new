-- =============================================================================
-- Tap'em — Re-apply missing RLS policies and helper functions
-- Migration 00002 was marked applied but not executed. This restores all
-- policies and functions needed for the core app flow.
-- Uses DO blocks with EXCEPTION WHEN duplicate_object so re-runs are safe.
-- =============================================================================

-- ─── Helper functions (idempotent via CREATE OR REPLACE) ──────────────────────

CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.has_active_membership(p_gym_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = auth.uid()
      AND gym_id = p_gym_id
      AND is_active = TRUE
      AND (expires_at IS NULL OR expires_at > NOW())
  );
$$;

CREATE OR REPLACE FUNCTION public.is_gym_admin(p_gym_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = auth.uid()
      AND gym_id = p_gym_id
      AND is_active = TRUE
      AND role IN ('admin', 'owner')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_gym_coach(p_gym_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = auth.uid()
      AND gym_id = p_gym_id
      AND is_active = TRUE
      AND role IN ('coach', 'admin', 'owner')
  );
$$;

CREATE OR REPLACE FUNCTION public.are_friends(p_user_a UUID, p_user_b UUID, p_gym_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.friendships
    WHERE gym_id = p_gym_id
      AND status = 'accepted'
      AND (
        (requester_id = p_user_a AND addressee_id = p_user_b)
        OR (requester_id = p_user_b AND addressee_id = p_user_a)
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.xp_to_level(p_total_xp BIGINT)
RETURNS INT LANGUAGE sql IMMUTABLE AS $$
  SELECT FLOOR((-1 + SQRT(1 + 8 * p_total_xp::FLOAT / 500)) / 2)::INT;
$$;

CREATE OR REPLACE FUNCTION public.recompute_user_gym_xp(p_user_id UUID, p_gym_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_total BIGINT;
BEGIN
  SELECT COALESCE(SUM(xp_delta), 0)
    INTO v_total
    FROM public.xp_events
   WHERE user_id = p_user_id AND gym_id = p_gym_id;

  INSERT INTO public.user_gym_xp (user_id, gym_id, total_xp, level, updated_at)
  VALUES (p_user_id, p_gym_id, v_total, public.xp_to_level(v_total), NOW())
  ON CONFLICT (user_id, gym_id) DO UPDATE
    SET total_xp   = EXCLUDED.total_xp,
        level      = EXCLUDED.level,
        updated_at = NOW();
END;
$$;

-- ─── Policies (safe: duplicate_object exception is swallowed) ─────────────────

DO $$ BEGIN
  CREATE POLICY "gyms_read_authenticated" ON public.tenant_gyms
    FOR SELECT TO authenticated USING (TRUE);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "gyms_update_owner" ON public.tenant_gyms
    FOR UPDATE TO authenticated
    USING (public.is_gym_admin(id)) WITH CHECK (public.is_gym_admin(id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- user_profiles
DO $$ BEGIN
  CREATE POLICY "profiles_read_own" ON public.user_profiles
    FOR SELECT TO authenticated USING (id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "profiles_read_gym_member" ON public.user_profiles
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM public.memberships m1
        JOIN public.memberships m2
          ON m1.gym_id = m2.gym_id
          AND m1.user_id = auth.uid()
          AND m2.user_id = user_profiles.id
          AND m1.is_active = TRUE
          AND m2.is_active = TRUE
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "profiles_insert_own" ON public.user_profiles
    FOR INSERT TO authenticated WITH CHECK (id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "profiles_update_own" ON public.user_profiles
    FOR UPDATE TO authenticated
    USING (id = auth.uid()) WITH CHECK (id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- memberships
DO $$ BEGIN
  CREATE POLICY "memberships_read_own" ON public.memberships
    FOR SELECT TO authenticated USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "memberships_read_same_gym" ON public.memberships
    FOR SELECT TO authenticated USING (public.has_active_membership(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "memberships_admin_manage" ON public.memberships
    FOR ALL TO authenticated
    USING (public.is_gym_admin(gym_id)) WITH CHECK (public.is_gym_admin(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- gym_equipment
DO $$ BEGIN
  CREATE POLICY "equipment_read_members" ON public.gym_equipment
    FOR SELECT TO authenticated USING (public.has_active_membership(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "equipment_admin_manage" ON public.gym_equipment
    FOR ALL TO authenticated
    USING (public.is_gym_admin(gym_id)) WITH CHECK (public.is_gym_admin(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- exercise_templates
DO $$ BEGIN
  CREATE POLICY "exercise_templates_read_members" ON public.exercise_templates
    FOR SELECT TO authenticated USING (public.has_active_membership(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "exercise_templates_admin_manage" ON public.exercise_templates
    FOR ALL TO authenticated
    USING (public.is_gym_admin(gym_id)) WITH CHECK (public.is_gym_admin(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- user_custom_exercises
DO $$ BEGIN
  CREATE POLICY "custom_exercises_own" ON public.user_custom_exercises
    FOR ALL TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- workout_sessions
DO $$ BEGIN
  CREATE POLICY "sessions_own" ON public.workout_sessions
    FOR ALL TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "sessions_coach_read" ON public.workout_sessions
    FOR SELECT TO authenticated USING (public.is_gym_coach(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- session_exercises
DO $$ BEGIN
  CREATE POLICY "session_exercises_own" ON public.session_exercises
    FOR ALL TO authenticated
    USING (
      EXISTS (SELECT 1 FROM public.workout_sessions s
              WHERE s.id = session_exercises.session_id AND s.user_id = auth.uid())
    )
    WITH CHECK (
      EXISTS (SELECT 1 FROM public.workout_sessions s
              WHERE s.id = session_exercises.session_id AND s.user_id = auth.uid())
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- set_entries
DO $$ BEGIN
  CREATE POLICY "set_entries_own" ON public.set_entries
    FOR ALL TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM public.session_exercises se
        JOIN public.workout_sessions s ON s.id = se.session_id
        WHERE se.id = set_entries.session_exercise_id AND s.user_id = auth.uid()
      )
    )
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM public.session_exercises se
        JOIN public.workout_sessions s ON s.id = se.session_id
        WHERE se.id = set_entries.session_exercise_id AND s.user_id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- xp_events
DO $$ BEGIN
  CREATE POLICY "xp_events_read_own" ON public.xp_events
    FOR SELECT TO authenticated USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- user_gym_xp
DO $$ BEGIN
  CREATE POLICY "user_gym_xp_read_own" ON public.user_gym_xp
    FOR SELECT TO authenticated USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_gym_xp_read_gym_members" ON public.user_gym_xp
    FOR SELECT TO authenticated USING (public.has_active_membership(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- friendships
DO $$ BEGIN
  CREATE POLICY "friendships_own" ON public.friendships
    FOR ALL TO authenticated
    USING (requester_id = auth.uid() OR addressee_id = auth.uid())
    WITH CHECK (requester_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- notifications
DO $$ BEGIN
  CREATE POLICY "notifications_own" ON public.notifications
    FOR SELECT TO authenticated USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "notifications_update_own" ON public.notifications
    FOR UPDATE TO authenticated USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
