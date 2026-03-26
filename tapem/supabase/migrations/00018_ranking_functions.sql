-- =============================================================================
-- Tap'em — Privacy-Aware Ranking Functions & Friendship Policies
-- All ranking RPCs use SECURITY DEFINER so they can read across user rows
-- while enforcing privacy_level filtering internally.
-- =============================================================================

-- ─── Grant execute on RPCs to authenticated role (applied at end) ─────────────

-- ─── 1. Training Day Ranking ──────────────────────────────────────────────────
-- Ranks all non-private gym members by training_day XP (user_gym_xp.total_xp).
-- Returns RANK() so ties share the same position.
-- Includes derived training_days count (total_xp / 25, see XpRules).

CREATE OR REPLACE FUNCTION public.get_gym_training_day_ranking(p_gym_id UUID)
RETURNS TABLE (
  rank           BIGINT,
  user_id        UUID,
  username       TEXT,
  total_xp       INTEGER,
  current_level  SMALLINT,
  training_days  INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    RANK() OVER (ORDER BY ugx.total_xp DESC)::BIGINT,
    ugx.user_id,
    up.username,
    ugx.total_xp,
    ugx.current_level,
    (ugx.total_xp / 100)::INTEGER AS training_days   -- 100 XP per training day (see finish-session edge fn)
  FROM public.user_gym_xp ugx
  JOIN public.user_profiles up ON up.id = ugx.user_id
  WHERE ugx.gym_id         = p_gym_id
    AND up.privacy_level  != 'private'
    AND ugx.total_xp       > 0
  ORDER BY ugx.total_xp DESC
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_gym_training_day_ranking IS
  'Returns gym members ranked by training_day XP. Excludes users with '
  'privacy_level = ''private''. Uses RANK() for correct tie handling.';

GRANT EXECUTE ON FUNCTION public.get_gym_training_day_ranking(UUID)
  TO authenticated;

-- ─── 2. Equipment XP Ranking ──────────────────────────────────────────────────
-- Ranks all non-private gym members by total equipment XP
-- (SUM of user_exercise_xp.total_xp per user per gym).
-- current_level derived from sum: floor(sum / 100) + 1 (XpRules.exerciseXpPerLevel = 100).

CREATE OR REPLACE FUNCTION public.get_gym_equipment_ranking(p_gym_id UUID)
RETURNS TABLE (
  rank             BIGINT,
  user_id          UUID,
  username         TEXT,
  total_xp         INTEGER,
  current_level    SMALLINT,
  equipment_count  INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    RANK() OVER (ORDER BY SUM(uex.total_xp) DESC)::BIGINT,
    uex.user_id,
    up.username,
    SUM(uex.total_xp)::INTEGER,
    (SUM(uex.total_xp) / 100 + 1)::SMALLINT,
    COUNT(DISTINCT uex.exercise_key)::INTEGER
  FROM public.user_exercise_xp uex
  JOIN public.user_profiles up ON up.id = uex.user_id
  WHERE uex.gym_id        = p_gym_id
    AND up.privacy_level != 'private'
  GROUP BY uex.user_id, up.username
  HAVING SUM(uex.total_xp) > 0
  ORDER BY SUM(uex.total_xp) DESC
  LIMIT 100;
$$;

COMMENT ON FUNCTION public.get_gym_equipment_ranking IS
  'Returns gym members ranked by total equipment XP across all exercises. '
  'Excludes users with privacy_level = ''private''. Uses RANK() for correct ties.';

GRANT EXECUTE ON FUNCTION public.get_gym_equipment_ranking(UUID)
  TO authenticated;

-- ─── 3. Friends Last Training Day ─────────────────────────────────────────────
-- Returns the most recent session_day_anchor per friend, respecting their
-- privacy_level. Returns NULL last_training_day for private users.
-- Caller passes the active gym_id and an array of friend user_ids.

CREATE OR REPLACE FUNCTION public.get_friends_last_training_day(
  p_gym_id     UUID,
  p_friend_ids UUID[]
)
RETURNS TABLE (
  user_id           UUID,
  last_training_day TEXT    -- 'yyyy-MM-dd' format, or NULL if private
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    up.id AS user_id,
    CASE
      WHEN up.privacy_level = 'private' THEN NULL
      ELSE (
        SELECT ws.session_day_anchor
        FROM   public.workout_sessions ws
        WHERE  ws.user_id    = up.id
          AND  ws.gym_id     = p_gym_id
          AND  ws.finished_at IS NOT NULL
        ORDER  BY ws.session_day_anchor DESC
        LIMIT  1
      )
    END AS last_training_day
  FROM public.user_profiles up
  WHERE up.id = ANY(p_friend_ids);
$$;

COMMENT ON FUNCTION public.get_friends_last_training_day IS
  'Returns the latest finished session_day_anchor per friend. '
  'Returns NULL for users with privacy_level = ''private''.';

GRANT EXECUTE ON FUNCTION public.get_friends_last_training_day(UUID, UUID[])
  TO authenticated;

-- ─── 4. Friend Session Summary (privacy_level = friends_training_and_summary) ──
-- Returns session count + exercise count for a friend's last session,
-- only if their privacy_level is friends_training_and_summary.

CREATE OR REPLACE FUNCTION public.get_friend_last_session_summary(
  p_gym_id   UUID,
  p_friend_id UUID
)
RETURNS TABLE (
  session_id     UUID,
  session_day    TEXT,
  exercise_count INTEGER,
  set_count      INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    ws.id                                              AS session_id,
    ws.session_day_anchor                              AS session_day,
    COUNT(DISTINCT se.id)::INTEGER                     AS exercise_count,
    COUNT(st.id)::INTEGER                              AS set_count
  FROM public.workout_sessions ws
  LEFT JOIN public.session_exercises se ON se.session_id = ws.id
  LEFT JOIN public.set_entries       st ON st.session_exercise_id = se.id
  WHERE ws.user_id     = p_friend_id
    AND ws.gym_id      = p_gym_id
    AND ws.finished_at IS NOT NULL
    AND (
      SELECT privacy_level FROM public.user_profiles WHERE id = p_friend_id
    ) = 'friends_training_and_summary'
  GROUP BY ws.id, ws.session_day_anchor
  ORDER BY ws.session_day_anchor DESC
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_friend_last_session_summary(UUID, UUID)
  TO authenticated;

-- ─── 5. Friendship DELETE policy (friend removal) ─────────────────────────────
-- Either party in an accepted friendship may delete it.
-- Requester can also cancel a pending request they sent.

CREATE POLICY "friendships_delete_own"
  ON public.friendships FOR DELETE
  TO authenticated
  USING (
    requester_id = auth.uid() OR addressee_id = auth.uid()
  );

-- ─── 6. user_exercise_xp: policy for gym-member read (ranking use) ─────────────
-- The ranking RPC (SECURITY DEFINER) bypasses RLS, so this policy is not
-- strictly required for the RPC. However, it allows future direct queries
-- from authenticated sessions when RLS check is needed (e.g. coach screens).

CREATE POLICY "user_exercise_xp_read_gym_members"
  ON public.user_exercise_xp FOR SELECT
  TO authenticated
  USING (public.has_active_membership(gym_id));

-- ─── 7. Index: user_gym_xp ranking performance ────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_user_gym_xp_ranking
  ON public.user_gym_xp (gym_id, total_xp DESC);

CREATE INDEX IF NOT EXISTS idx_user_exercise_xp_gym_user
  ON public.user_exercise_xp (gym_id, user_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_privacy
  ON public.user_profiles (id, privacy_level);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_gym_day
  ON public.workout_sessions (user_id, gym_id, session_day_anchor DESC)
  WHERE finished_at IS NOT NULL;
