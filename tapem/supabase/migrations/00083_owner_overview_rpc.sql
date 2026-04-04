-- =============================================================================
-- Tap'em — Owner Overview RPC
-- Single-call endpoint returning all KPIs needed for the owner overview screen.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_owner_overview(p_gym_id UUID)
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
    -- ── Activation funnel ────────────────────────────────────────────────────
    -- Step 1: All users who have ever joined (any status)
    'funnel_registered',
      (SELECT COUNT(*)
         FROM public.memberships
        WHERE gym_id = p_gym_id),

    -- Step 2: Active members
    'funnel_joined',
      (SELECT COUNT(*)
         FROM public.memberships
        WHERE gym_id    = p_gym_id
          AND is_active = TRUE
          AND status    = 'active'),

    -- Step 3: Members who have completed at least one workout
    'funnel_first_workout',
      (SELECT COUNT(DISTINCT ws.user_id)
         FROM public.workout_sessions ws
         JOIN public.memberships m
           ON m.user_id = ws.user_id AND m.gym_id = p_gym_id
        WHERE ws.gym_id       = p_gym_id
          AND ws.finished_at  IS NOT NULL),

    -- Step 4: Active in last 7 days
    'funnel_active_7d',
      (SELECT COUNT(DISTINCT user_id)
         FROM public.workout_sessions
        WHERE gym_id             = p_gym_id
          AND finished_at        IS NOT NULL
          AND session_day_anchor >= CURRENT_DATE - INTERVAL '7 days'),

    -- Step 5: Active in last 30 days
    'funnel_active_30d',
      (SELECT COUNT(DISTINCT user_id)
         FROM public.workout_sessions
        WHERE gym_id             = p_gym_id
          AND finished_at        IS NOT NULL
          AND session_day_anchor >= CURRENT_DATE - INTERVAL '30 days'),

    -- ── Usage this month ────────────────────────────────────────────────────
    'sessions_this_month',
      (SELECT COUNT(*)
         FROM public.workout_sessions
        WHERE gym_id             = p_gym_id
          AND finished_at        IS NOT NULL
          AND session_day_anchor >= date_trunc('month', CURRENT_DATE)),

    -- Workouts per active user (30d) — rounded to 1 decimal
    'workouts_per_active_user_30d',
      CASE
        WHEN (SELECT COUNT(DISTINCT user_id)
                FROM public.workout_sessions
               WHERE gym_id             = p_gym_id
                 AND finished_at        IS NOT NULL
                 AND session_day_anchor >= CURRENT_DATE - INTERVAL '30 days') = 0
        THEN 0.0
        ELSE ROUND(
          (SELECT COUNT(*)
             FROM public.workout_sessions
            WHERE gym_id             = p_gym_id
              AND finished_at        IS NOT NULL
              AND session_day_anchor >= CURRENT_DATE - INTERVAL '30 days')::NUMERIC
          /
          (SELECT COUNT(DISTINCT user_id)
             FROM public.workout_sessions
            WHERE gym_id             = p_gym_id
              AND finished_at        IS NOT NULL
              AND session_day_anchor >= CURRENT_DATE - INTERVAL '30 days')::NUMERIC,
          1
        )
      END,

    -- ── Equipment NFC coverage ──────────────────────────────────────────────
    'equipment_total',
      (SELECT COUNT(*)
         FROM public.gym_equipment
        WHERE gym_id    = p_gym_id
          AND is_active = TRUE),

    'equipment_with_nfc',
      (SELECT COUNT(*)
         FROM public.gym_equipment
        WHERE gym_id       = p_gym_id
          AND is_active    = TRUE
          AND nfc_tag_uid  IS NOT NULL),

    -- ── Challenges ──────────────────────────────────────────────────────────
    'active_challenges',
      (SELECT COUNT(*)
         FROM public.challenges
        WHERE gym_id    = p_gym_id
          AND is_active = TRUE
          AND starts_at <= NOW()
          AND ends_at   >= NOW()),

    -- ── Open admin tasks ────────────────────────────────────────────────────
    'open_join_requests',
      (SELECT COUNT(*)
         FROM public.memberships
        WHERE gym_id  = p_gym_id
          AND status  = 'pending'),

    'open_feedbacks',
      (SELECT COUNT(*)
         FROM public.equipment_feedback
        WHERE gym_id  = p_gym_id
          AND status  IN ('open', 'in_progress')),

    'open_reports',
      (SELECT COUNT(*)
         FROM public.content_reports
        WHERE gym_id  = p_gym_id
          AND status  = 'pending')

  ) INTO v_result;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_owner_overview(UUID) TO authenticated;
