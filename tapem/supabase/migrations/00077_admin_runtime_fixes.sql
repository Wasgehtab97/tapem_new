-- =============================================================================
-- Tap'em — 00077: Admin runtime fixes
--
-- Fixes four runtime errors surfaced in the admin area:
--
-- 1. PGRST200: memberships → user_profiles
--    memberships.user_id FKs to auth.users, which is invisible to PostgREST.
--    Fix: add a second FK to public.user_profiles so the embedded join works.
--
-- 2. PGRST200: equipment_feedback → user_profiles!equipment_feedback_user_id_fkey
--    The Flutter client uses the hint 'equipment_feedback_user_id_fkey', which
--    resolves to the existing FK pointing at auth.users — not user_profiles.
--    Fix: drop and recreate the constraint pointing at public.user_profiles
--    (same name so the hint still resolves). Cascades work because
--    user_profiles.id → auth.users(id) ON DELETE CASCADE.
--
-- 3. column ls.level does not exist (42703)
--    get_gym_engagement_stats references ls.level but level_snapshots stores
--    the value in level_reached.
--    Fix: replace ls.level with ls.level_reached throughout the function.
-- =============================================================================

-- =============================================================================
-- SECTION 1 — memberships: add FK to public.user_profiles
-- =============================================================================

ALTER TABLE public.memberships
  ADD CONSTRAINT memberships_user_profiles_fkey
  FOREIGN KEY (user_id)
  REFERENCES public.user_profiles(id)
  ON DELETE CASCADE;

-- =============================================================================
-- SECTION 2 — equipment_feedback: redirect FK to public.user_profiles
--
-- Drop the existing auth.users FK (keeping the same constraint name so the
-- PostgREST hint 'equipment_feedback_user_id_fkey' keeps resolving).
-- =============================================================================

ALTER TABLE public.equipment_feedback
  DROP CONSTRAINT IF EXISTS equipment_feedback_user_id_fkey;

ALTER TABLE public.equipment_feedback
  ADD CONSTRAINT equipment_feedback_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES public.user_profiles(id)
  ON DELETE CASCADE;

-- =============================================================================
-- SECTION 3 — Fix get_gym_engagement_stats: ls.level → ls.level_reached
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_gym_engagement_stats(p_gym_id UUID)
RETURNS JSON
  SECURITY DEFINER
  LANGUAGE plpgsql
AS $$
DECLARE
  v_result JSON;
BEGIN
  IF NOT public.is_gym_admin(p_gym_id) THEN
    RAISE EXCEPTION 'not_admin';
  END IF;

  SELECT json_build_object(
    'level_distribution',
      (SELECT COALESCE(json_agg(row_to_json(t) ORDER BY (t).min_level), '[]'::JSON)
         FROM (
           SELECT
             CASE
               WHEN ls.level_reached BETWEEN 1  AND 3  THEN '1–3'
               WHEN ls.level_reached BETWEEN 4  AND 6  THEN '4–6'
               WHEN ls.level_reached BETWEEN 7  AND 10 THEN '7–10'
               ELSE '11+'
             END                                AS level_range,
             MIN(ls.level_reached)              AS min_level,
             COUNT(DISTINCT m.user_id)::INT     AS member_count
           FROM public.memberships m
           JOIN public.level_snapshots ls
             ON ls.user_id = m.user_id
             AND ls.gym_id = p_gym_id
             AND ls.axis   = 'training_day'
          WHERE m.gym_id    = p_gym_id
            AND m.is_active = TRUE
            AND m.status    = 'active'
          GROUP BY 1
         ) t),
    'top_members',
      (SELECT COALESCE(json_agg(row_to_json(t)), '[]'::JSON)
         FROM (
           SELECT
             up.username,
             up.avatar_url,
             COALESCE(ugx.total_xp, 0)::INT       AS total_xp,
             COALESCE(ugx.current_level, 1)::INT   AS level,
             COUNT(DISTINCT ws.session_day_anchor)::INT AS training_days_this_month
           FROM public.memberships m
           JOIN public.user_profiles up ON up.id = m.user_id
           LEFT JOIN public.user_gym_xp ugx
             ON ugx.user_id = m.user_id AND ugx.gym_id = p_gym_id
           LEFT JOIN public.workout_sessions ws
             ON ws.user_id             = m.user_id
             AND ws.gym_id             = p_gym_id
             AND ws.finished_at        IS NOT NULL
             AND ws.session_day_anchor >= date_trunc('month', CURRENT_DATE)
          WHERE m.gym_id    = p_gym_id
            AND m.is_active = TRUE
            AND m.status    = 'active'
          GROUP BY up.username, up.avatar_url, ugx.total_xp, ugx.current_level
          ORDER BY training_days_this_month DESC NULLS LAST,
                   ugx.total_xp DESC NULLS LAST
          LIMIT 10
         ) t),
    'active_challenges',
      (SELECT COUNT(*)::INT
         FROM public.challenges
        WHERE gym_id    = p_gym_id
          AND is_active = TRUE
          AND ends_at   > NOW()),
    'total_active_members',
      (SELECT COUNT(*)::INT
         FROM public.memberships
        WHERE gym_id    = p_gym_id
          AND is_active = TRUE
          AND status    = 'active')
  ) INTO v_result;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_gym_engagement_stats(UUID) TO authenticated;
