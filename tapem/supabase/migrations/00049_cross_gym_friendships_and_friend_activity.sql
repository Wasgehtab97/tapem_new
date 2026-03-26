-- =============================================================================
-- Tap'em — 00049: Cross-Gym Friendships + Secure Friend Activity RPCs
--
-- Purpose:
--   1) Enable friendships across gyms (global user-to-user relationship).
--   2) Keep one friendship row per user pair (no reverse duplicates).
--   3) Harden friend activity RPCs to enforce auth + accepted friendship.
--   4) Provide typed RPCs for friend search and friend profile/calendar UX.
-- =============================================================================

-- ─── 1. De-duplicate existing friendship pairs (keep most relevant row) ───────
WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY LEAST(requester_id, addressee_id),
                   GREATEST(requester_id, addressee_id)
      ORDER BY
        CASE status
          WHEN 'accepted' THEN 0
          WHEN 'pending'  THEN 1
          ELSE 2
        END,
        COALESCE(responded_at, created_at) DESC,
        created_at DESC
    ) AS rn
  FROM public.friendships
)
DELETE FROM public.friendships f
USING ranked r
WHERE f.id = r.id
  AND r.rn > 1;

-- Enforce exactly one friendship row per user pair globally.
CREATE UNIQUE INDEX IF NOT EXISTS uq_friendships_user_pair_global
  ON public.friendships (
    LEAST(requester_id, addressee_id),
    GREATEST(requester_id, addressee_id)
  );

-- ─── 2. RLS: normalize friendship policies for cross-gym usage ────────────────
DROP POLICY IF EXISTS "friendships_own" ON public.friendships;
DROP POLICY IF EXISTS "friendships_read_own" ON public.friendships;
DROP POLICY IF EXISTS "friendships_insert_requester" ON public.friendships;
DROP POLICY IF EXISTS "friendships_update_addressee" ON public.friendships;
DROP POLICY IF EXISTS "friendships_delete_own" ON public.friendships;

CREATE POLICY "friendships_read_own"
  ON public.friendships FOR SELECT
  TO authenticated
  USING (requester_id = auth.uid() OR addressee_id = auth.uid());

CREATE POLICY "friendships_insert_requester"
  ON public.friendships FOR INSERT
  TO authenticated
  WITH CHECK (
    requester_id = auth.uid()
    AND requester_id != addressee_id
    AND public.has_active_membership(gym_id)
  );

CREATE POLICY "friendships_update_addressee"
  ON public.friendships FOR UPDATE
  TO authenticated
  USING (addressee_id = auth.uid())
  WITH CHECK (addressee_id = auth.uid());

CREATE POLICY "friendships_delete_own"
  ON public.friendships FOR DELETE
  TO authenticated
  USING (requester_id = auth.uid() OR addressee_id = auth.uid());

-- ─── 3. are_friends(): now pair-global (p_gym_id kept for API compatibility) ──
CREATE OR REPLACE FUNCTION public.are_friends(
  p_user_a UUID,
  p_user_b UUID,
  p_gym_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.friendships f
    WHERE f.status = 'accepted'
      AND (
        (f.requester_id = p_user_a AND f.addressee_id = p_user_b)
        OR
        (f.requester_id = p_user_b AND f.addressee_id = p_user_a)
      )
  );
$$;

-- ─── 4. Harden existing friend-activity RPCs ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_friends_last_training_day(
  p_gym_id     UUID,
  p_friend_ids UUID[]
)
RETURNS TABLE (
  user_id           UUID,
  last_training_day TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH viewer AS (
    SELECT auth.uid() AS uid
  ),
  allowed_friends AS (
    SELECT
      pf.friend_id
    FROM unnest(COALESCE(p_friend_ids, ARRAY[]::UUID[])) AS pf(friend_id)
    CROSS JOIN viewer v
    WHERE v.uid IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.friendships f
        WHERE f.status = 'accepted'
          AND (
            (f.requester_id = v.uid AND f.addressee_id = pf.friend_id)
            OR
            (f.addressee_id = v.uid AND f.requester_id = pf.friend_id)
          )
      )
  )
  SELECT
    af.friend_id AS user_id,
    CASE
      WHEN up.privacy_level = 'private' THEN NULL
      ELSE (
        SELECT ws.session_day_anchor::TEXT
        FROM public.workout_sessions ws
        WHERE ws.user_id = af.friend_id
          AND ws.finished_at IS NOT NULL
          AND (p_gym_id IS NULL OR ws.gym_id = p_gym_id)
        ORDER BY ws.session_day_anchor DESC
        LIMIT 1
      )
    END AS last_training_day
  FROM allowed_friends af
  JOIN public.user_profiles up ON up.id = af.friend_id;
$$;

CREATE OR REPLACE FUNCTION public.get_friend_last_session_summary(
  p_gym_id    UUID,
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
SET search_path = public
AS $$
  WITH viewer AS (
    SELECT auth.uid() AS uid
  ),
  allowed AS (
    SELECT 1
    FROM viewer v
    JOIN public.user_profiles up ON up.id = p_friend_id
    WHERE v.uid IS NOT NULL
      AND up.privacy_level = 'friends_training_and_summary'
      AND EXISTS (
        SELECT 1
        FROM public.friendships f
        WHERE f.status = 'accepted'
          AND (
            (f.requester_id = v.uid AND f.addressee_id = p_friend_id)
            OR
            (f.addressee_id = v.uid AND f.requester_id = p_friend_id)
          )
      )
  )
  SELECT
    ws.id AS session_id,
    ws.session_day_anchor::TEXT AS session_day,
    COUNT(DISTINCT se.id)::INTEGER AS exercise_count,
    COUNT(st.id)::INTEGER AS set_count
  FROM public.workout_sessions ws
  LEFT JOIN public.session_exercises se ON se.session_id = ws.id
  LEFT JOIN public.set_entries st ON st.session_exercise_id = se.id
  WHERE ws.user_id = p_friend_id
    AND ws.finished_at IS NOT NULL
    AND (p_gym_id IS NULL OR ws.gym_id = p_gym_id)
    AND EXISTS (SELECT 1 FROM allowed)
  GROUP BY ws.id, ws.session_day_anchor
  ORDER BY ws.session_day_anchor DESC
  LIMIT 1;
$$;

-- ─── 5. New RPC: friend search (my gym + other gyms) ──────────────────────────
CREATE OR REPLACE FUNCTION public.search_users_for_friendship(
  p_query         TEXT,
  p_limit         INTEGER DEFAULT 20,
  p_active_gym_id UUID DEFAULT NULL
)
RETURNS TABLE (
  user_id              UUID,
  username             TEXT,
  display_name         TEXT,
  avatar_url           TEXT,
  friendship_id        UUID,
  relationship_status  TEXT,
  shared_gym_count     INTEGER,
  shares_active_gym    BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH viewer AS (
    SELECT auth.uid() AS uid
  ),
  q AS (
    SELECT lower(trim(COALESCE(p_query, ''))) AS needle
  )
  SELECT
    up.id AS user_id,
    up.username::TEXT AS username,
    up.display_name,
    up.avatar_url,
    rel.friendship_id,
    CASE
      WHEN rel.friendship_id IS NULL THEN 'none'
      WHEN rel.status = 'accepted' THEN 'accepted'
      WHEN rel.status = 'pending' AND rel.requester_id = v.uid THEN 'pending_sent'
      WHEN rel.status = 'pending' THEN 'pending_received'
      ELSE rel.status::TEXT
    END AS relationship_status,
    COALESCE(shared.shared_gym_count, 0)::INTEGER AS shared_gym_count,
    COALESCE(shared.shares_active_gym, FALSE) AS shares_active_gym
  FROM viewer v
  JOIN q ON TRUE
  JOIN public.user_profiles up
    ON up.id != v.uid
  LEFT JOIN LATERAL (
    SELECT
      f.id AS friendship_id,
      f.status,
      f.requester_id
    FROM public.friendships f
    WHERE (f.requester_id = v.uid AND f.addressee_id = up.id)
       OR (f.addressee_id = v.uid AND f.requester_id = up.id)
    LIMIT 1
  ) rel ON TRUE
  LEFT JOIN LATERAL (
    SELECT
      COUNT(*) FILTER (WHERE m1.is_active = TRUE AND m2.is_active = TRUE)::INTEGER
        AS shared_gym_count,
      BOOL_OR(
        p_active_gym_id IS NOT NULL
        AND m1.gym_id = p_active_gym_id
        AND m1.is_active = TRUE
        AND m2.is_active = TRUE
      ) AS shares_active_gym
    FROM public.memberships m1
    JOIN public.memberships m2
      ON m2.gym_id = m1.gym_id
     AND m2.user_id = up.id
    WHERE m1.user_id = v.uid
  ) shared ON TRUE
  WHERE v.uid IS NOT NULL
    AND length(q.needle) >= 2
    AND lower(up.username::TEXT) LIKE '%' || q.needle || '%'
  ORDER BY
    COALESCE(shared.shares_active_gym, FALSE) DESC,
    COALESCE(shared.shared_gym_count, 0) DESC,
    lower(up.username::TEXT) ASC
  LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 20), 50));
$$;

GRANT EXECUTE ON FUNCTION public.search_users_for_friendship(TEXT, INTEGER, UUID)
  TO authenticated;

-- ─── 6. New RPC: overview for current user's friendships ──────────────────────
CREATE OR REPLACE FUNCTION public.get_my_friendships_overview(
  p_active_gym_id UUID DEFAULT NULL
)
RETURNS TABLE (
  friendship_id        UUID,
  friend_user_id       UUID,
  username             TEXT,
  display_name         TEXT,
  avatar_url           TEXT,
  status               TEXT,
  shared_gym_count     INTEGER,
  shares_active_gym    BOOLEAN,
  created_at           TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH viewer AS (
    SELECT auth.uid() AS uid
  ),
  normalized AS (
    SELECT
      f.id AS friendship_id,
      CASE
        WHEN f.requester_id = v.uid THEN f.addressee_id
        ELSE f.requester_id
      END AS friend_user_id,
      CASE
        WHEN f.status = 'accepted' THEN 'accepted'
        WHEN f.requester_id = v.uid THEN 'pending_sent'
        ELSE 'pending_received'
      END AS status,
      f.created_at
    FROM public.friendships f
    CROSS JOIN viewer v
    WHERE v.uid IS NOT NULL
      AND f.status IN ('accepted', 'pending')
      AND (f.requester_id = v.uid OR f.addressee_id = v.uid)
  )
  SELECT
    n.friendship_id,
    n.friend_user_id,
    up.username::TEXT AS username,
    up.display_name,
    up.avatar_url,
    n.status,
    COALESCE(shared.shared_gym_count, 0)::INTEGER AS shared_gym_count,
    COALESCE(shared.shares_active_gym, FALSE) AS shares_active_gym,
    n.created_at
  FROM normalized n
  JOIN public.user_profiles up ON up.id = n.friend_user_id
  CROSS JOIN viewer v
  LEFT JOIN LATERAL (
    SELECT
      COUNT(*) FILTER (WHERE m1.is_active = TRUE AND m2.is_active = TRUE)::INTEGER
        AS shared_gym_count,
      BOOL_OR(
        p_active_gym_id IS NOT NULL
        AND m1.gym_id = p_active_gym_id
        AND m1.is_active = TRUE
        AND m2.is_active = TRUE
      ) AS shares_active_gym
    FROM public.memberships m1
    JOIN public.memberships m2
      ON m2.gym_id = m1.gym_id
     AND m2.user_id = n.friend_user_id
    WHERE m1.user_id = v.uid
  ) shared ON TRUE
  ORDER BY n.created_at DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_friendships_overview(UUID)
  TO authenticated;

-- ─── 7. New RPC: friend training calendar days (privacy-aware) ────────────────
CREATE OR REPLACE FUNCTION public.get_friend_training_calendar_days(
  p_friend_id UUID,
  p_year      INTEGER,
  p_gym_id    UUID DEFAULT NULL
)
RETURNS TABLE (
  session_day TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH viewer AS (
    SELECT auth.uid() AS uid
  ),
  allowed AS (
    SELECT 1
    FROM viewer v
    JOIN public.user_profiles up ON up.id = p_friend_id
    WHERE v.uid IS NOT NULL
      AND up.privacy_level IN ('friends_training_days', 'friends_training_and_summary')
      AND EXISTS (
        SELECT 1
        FROM public.friendships f
        WHERE f.status = 'accepted'
          AND (
            (f.requester_id = v.uid AND f.addressee_id = p_friend_id)
            OR
            (f.addressee_id = v.uid AND f.requester_id = p_friend_id)
          )
      )
  )
  SELECT DISTINCT
    ws.session_day_anchor::TEXT AS session_day
  FROM public.workout_sessions ws
  WHERE ws.user_id = p_friend_id
    AND ws.finished_at IS NOT NULL
    AND EXTRACT(YEAR FROM ws.session_day_anchor) = p_year
    AND (p_gym_id IS NULL OR ws.gym_id = p_gym_id)
    AND EXISTS (SELECT 1 FROM allowed)
  ORDER BY session_day DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_friend_training_calendar_days(UUID, INTEGER, UUID)
  TO authenticated;

-- ─── 8. Supporting indexes ─────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_friendships_pair_status
  ON public.friendships (
    LEAST(requester_id, addressee_id),
    GREATEST(requester_id, addressee_id),
    status
  );
