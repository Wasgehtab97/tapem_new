-- =============================================================================
-- Tap'em — RLS Policies
-- deny-by-default: all tables start with RLS enabled, no implicit access
-- =============================================================================

-- ─── Enable RLS on all tables ─────────────────────────────────────────────────

ALTER TABLE public.tenant_gyms              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.username_reservations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memberships              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gym_equipment            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_tags           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_templates       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.muscle_group_weights     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_custom_exercises    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_assignments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_exercises        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.set_entries              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_gym_xp             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_exercise_xp        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_muscle_group_xp    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.level_snapshots         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ranking_events          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ranking_snapshots       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_events             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications           ENABLE ROW LEVEL SECURITY;

-- ─── Helper functions ─────────────────────────────────────────────────────────

-- Returns the current user's ID from JWT
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT auth.uid();
$$;

-- Returns true if user has an active membership in the given gym
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

-- Returns true if user has role >= admin in the given gym
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

-- Returns true if user has role coach or above in the given gym
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

-- Returns true if two users are accepted friends in the same gym
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

-- ─── tenant_gyms ─────────────────────────────────────────────────────────────
-- Any authenticated user can read gyms (needed for signup flow).
-- Only service role can insert/update.

CREATE POLICY "gyms_read_authenticated"
  ON public.tenant_gyms FOR SELECT
  TO authenticated
  USING (TRUE);

-- ─── user_profiles ───────────────────────────────────────────────────────────
-- Users can read their own profile and gym-members' profiles.
-- Users can only write their own profile.

CREATE POLICY "profiles_read_own"
  ON public.user_profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Members of the same gym can read each other's profiles (for friend search etc.)
CREATE POLICY "profiles_read_gym_member"
  ON public.user_profiles FOR SELECT
  TO authenticated
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

CREATE POLICY "profiles_insert_own"
  ON public.user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update_own"
  ON public.user_profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ─── username_reservations ────────────────────────────────────────────────────

CREATE POLICY "reservations_manage_own"
  ON public.username_reservations FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ─── memberships ─────────────────────────────────────────────────────────────
-- Members can read their own memberships and co-member memberships in shared gyms.

CREATE POLICY "memberships_read_own"
  ON public.memberships FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "memberships_read_same_gym"
  ON public.memberships FOR SELECT
  TO authenticated
  USING (public.has_active_membership(gym_id));

-- Admins can manage memberships in their gym
CREATE POLICY "memberships_admin_manage"
  ON public.memberships FOR ALL
  TO authenticated
  USING (public.is_gym_admin(gym_id))
  WITH CHECK (public.is_gym_admin(gym_id));

-- ─── gym_equipment ────────────────────────────────────────────────────────────
-- Members can read equipment in their gym. Admins can manage it.

CREATE POLICY "equipment_read_members"
  ON public.gym_equipment FOR SELECT
  TO authenticated
  USING (public.has_active_membership(gym_id));

CREATE POLICY "equipment_admin_manage"
  ON public.gym_equipment FOR ALL
  TO authenticated
  USING (public.is_gym_admin(gym_id))
  WITH CHECK (public.is_gym_admin(gym_id));

-- ─── equipment_tags ───────────────────────────────────────────────────────────

CREATE POLICY "equipment_tags_read_members"
  ON public.equipment_tags FOR SELECT
  TO authenticated
  USING (public.has_active_membership(gym_id));

CREATE POLICY "equipment_tags_admin_manage"
  ON public.equipment_tags FOR ALL
  TO authenticated
  USING (public.is_gym_admin(gym_id))
  WITH CHECK (public.is_gym_admin(gym_id));

-- ─── exercise_templates ───────────────────────────────────────────────────────

CREATE POLICY "exercise_templates_read_members"
  ON public.exercise_templates FOR SELECT
  TO authenticated
  USING (public.has_active_membership(gym_id));

CREATE POLICY "exercise_templates_admin_manage"
  ON public.exercise_templates FOR ALL
  TO authenticated
  USING (public.is_gym_admin(gym_id))
  WITH CHECK (public.is_gym_admin(gym_id));

-- ─── muscle_group_weights ─────────────────────────────────────────────────────

CREATE POLICY "muscle_group_weights_read_members"
  ON public.muscle_group_weights FOR SELECT
  TO authenticated
  USING (public.has_active_membership(gym_id));

CREATE POLICY "muscle_group_weights_admin_manage"
  ON public.muscle_group_weights FOR ALL
  TO authenticated
  USING (public.is_gym_admin(gym_id))
  WITH CHECK (public.is_gym_admin(gym_id));

-- ─── user_custom_exercises ────────────────────────────────────────────────────
-- Users can CRUD their own exercises. Cannot read others' custom exercises.

CREATE POLICY "custom_exercises_own"
  ON public.user_custom_exercises FOR ALL
  TO authenticated
  USING (user_id = auth.uid() AND public.has_active_membership(gym_id))
  WITH CHECK (user_id = auth.uid() AND public.has_active_membership(gym_id));

-- ─── workout_plans ────────────────────────────────────────────────────────────

CREATE POLICY "workout_plans_read_own_or_assigned"
  ON public.workout_plans FOR SELECT
  TO authenticated
  USING (
    created_by = auth.uid()
    OR is_public = TRUE
    OR EXISTS (
      SELECT 1 FROM public.plan_assignments
      WHERE plan_id = workout_plans.id AND assigned_to = auth.uid()
    )
  );

CREATE POLICY "workout_plans_manage_own"
  ON public.workout_plans FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid() AND public.has_active_membership(gym_id));

CREATE POLICY "workout_plans_update_own"
  ON public.workout_plans FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "workout_plans_coach_manage"
  ON public.workout_plans FOR ALL
  TO authenticated
  USING (public.is_gym_coach(gym_id))
  WITH CHECK (public.is_gym_coach(gym_id));

-- ─── plan_assignments ─────────────────────────────────────────────────────────

CREATE POLICY "plan_assignments_read_own"
  ON public.plan_assignments FOR SELECT
  TO authenticated
  USING (assigned_to = auth.uid() OR assigned_by = auth.uid());

CREATE POLICY "plan_assignments_coach_manage"
  ON public.plan_assignments FOR ALL
  TO authenticated
  USING (public.is_gym_coach(gym_id))
  WITH CHECK (public.is_gym_coach(gym_id));

-- ─── workout_sessions ─────────────────────────────────────────────────────────
-- Users can read/write only their own sessions in their active gyms.

CREATE POLICY "sessions_own"
  ON public.workout_sessions FOR ALL
  TO authenticated
  USING (user_id = auth.uid() AND public.has_active_membership(gym_id))
  WITH CHECK (user_id = auth.uid() AND public.has_active_membership(gym_id));

-- Coaches/admins can read sessions in their gym (for progress coaching)
CREATE POLICY "sessions_coach_read"
  ON public.workout_sessions FOR SELECT
  TO authenticated
  USING (public.is_gym_coach(gym_id));

-- ─── session_exercises ────────────────────────────────────────────────────────

CREATE POLICY "session_exercises_own"
  ON public.session_exercises FOR ALL
  TO authenticated
  USING (
    public.has_active_membership(gym_id)
    AND EXISTS (
      SELECT 1 FROM public.workout_sessions
      WHERE id = session_exercises.session_id AND user_id = auth.uid()
    )
  )
  WITH CHECK (
    public.has_active_membership(gym_id)
    AND EXISTS (
      SELECT 1 FROM public.workout_sessions
      WHERE id = session_exercises.session_id AND user_id = auth.uid()
    )
  );

-- ─── set_entries ──────────────────────────────────────────────────────────────

CREATE POLICY "set_entries_own"
  ON public.set_entries FOR ALL
  TO authenticated
  USING (
    public.has_active_membership(gym_id)
    AND EXISTS (
      SELECT 1
      FROM public.session_exercises se
      JOIN public.workout_sessions ws ON ws.id = se.session_id
      WHERE se.id = set_entries.session_exercise_id
        AND ws.user_id = auth.uid()
    )
  )
  WITH CHECK (
    public.has_active_membership(gym_id)
    AND EXISTS (
      SELECT 1
      FROM public.session_exercises se
      JOIN public.workout_sessions ws ON ws.id = se.session_id
      WHERE se.id = set_entries.session_exercise_id
        AND ws.user_id = auth.uid()
    )
  );

-- ─── xp_events ───────────────────────────────────────────────────────────────
-- Read-only for users. Service role writes these via Edge Functions.

CREATE POLICY "xp_events_read_own"
  ON public.xp_events FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() AND public.has_active_membership(gym_id));

-- ─── user_gym_xp / user_exercise_xp / user_muscle_group_xp ───────────────────

CREATE POLICY "user_gym_xp_read_own"
  ON public.user_gym_xp FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "user_gym_xp_read_gym_members"
  ON public.user_gym_xp FOR SELECT
  TO authenticated
  USING (public.has_active_membership(gym_id)); -- for rankings

CREATE POLICY "user_exercise_xp_read_own"
  ON public.user_exercise_xp FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "user_muscle_group_xp_read_own"
  ON public.user_muscle_group_xp FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- ─── level_snapshots ──────────────────────────────────────────────────────────

CREATE POLICY "level_snapshots_read_own"
  ON public.level_snapshots FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- ─── achievements ─────────────────────────────────────────────────────────────

CREATE POLICY "achievements_read_own"
  ON public.achievements FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() AND public.has_active_membership(gym_id));

CREATE POLICY "achievements_read_friends"
  ON public.achievements FOR SELECT
  TO authenticated
  USING (
    public.are_friends(auth.uid(), user_id, gym_id)
    AND (
      SELECT privacy_level FROM public.user_profiles WHERE id = user_id
    ) != 'private'
  );

-- ─── challenges ───────────────────────────────────────────────────────────────

CREATE POLICY "challenges_read_members"
  ON public.challenges FOR SELECT
  TO authenticated
  USING (public.has_active_membership(gym_id));

CREATE POLICY "challenges_admin_manage"
  ON public.challenges FOR ALL
  TO authenticated
  USING (public.is_gym_admin(gym_id))
  WITH CHECK (public.is_gym_admin(gym_id));

-- ─── ranking_events ───────────────────────────────────────────────────────────
-- Read: members of same gym. Write: server-side only via service role.

CREATE POLICY "ranking_events_read_members"
  ON public.ranking_events FOR SELECT
  TO authenticated
  USING (public.has_active_membership(gym_id));

-- ─── ranking_snapshots ────────────────────────────────────────────────────────

CREATE POLICY "ranking_snapshots_read_members"
  ON public.ranking_snapshots FOR SELECT
  TO authenticated
  USING (public.has_active_membership(gym_id));

-- ─── feed_events ──────────────────────────────────────────────────────────────
-- Privacy-controlled. Read respects user privacy_level setting.

CREATE POLICY "feed_events_read_own"
  ON public.feed_events FOR SELECT
  TO authenticated
  USING (actor_id = auth.uid());

CREATE POLICY "feed_events_read_friends"
  ON public.feed_events FOR SELECT
  TO authenticated
  USING (
    public.are_friends(auth.uid(), actor_id, gym_id)
    AND (
      SELECT privacy_level FROM public.user_profiles WHERE id = actor_id
    ) != 'private'
  );

-- ─── friendships ──────────────────────────────────────────────────────────────

CREATE POLICY "friendships_read_own"
  ON public.friendships FOR SELECT
  TO authenticated
  USING (
    (requester_id = auth.uid() OR addressee_id = auth.uid())
    AND public.has_active_membership(gym_id)
  );

CREATE POLICY "friendships_insert_requester"
  ON public.friendships FOR INSERT
  TO authenticated
  WITH CHECK (
    requester_id = auth.uid()
    AND public.has_active_membership(gym_id)
    -- Addressee must also be a member
    AND EXISTS (
      SELECT 1 FROM public.memberships
      WHERE user_id = addressee_id AND gym_id = friendships.gym_id AND is_active = TRUE
    )
  );

CREATE POLICY "friendships_update_addressee"
  ON public.friendships FOR UPDATE
  TO authenticated
  USING (addressee_id = auth.uid())
  WITH CHECK (addressee_id = auth.uid());

-- ─── notifications ────────────────────────────────────────────────────────────

CREATE POLICY "notifications_read_own"
  ON public.notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own"
  ON public.notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
