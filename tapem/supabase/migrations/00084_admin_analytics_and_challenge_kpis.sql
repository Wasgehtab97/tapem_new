-- =============================================================================
-- Tap'em — Admin analytics depth + challenge KPI aggregation
-- Date: 2026-04-03
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SECTION 1 — Extend equipment analytics with NFC + feedback breakdown
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_equipment_usage_stats(p_gym_id UUID)
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

  WITH exercise_scope AS (
    SELECT
      se.id                                       AS exercise_id,
      COALESCE(se.equipment_id, ws.equipment_id) AS effective_equipment_id,
      ws.user_id                                  AS user_id,
      ws.session_day_anchor                       AS session_day_anchor
    FROM public.session_exercises se
    JOIN public.workout_sessions ws
      ON ws.id           = se.session_id
     AND ws.gym_id       = p_gym_id
     AND ws.finished_at IS NOT NULL
  ),
  usage_stats AS (
    SELECT
      es.effective_equipment_id                   AS equipment_id,
      COUNT(se2.id)                               AS total_sets_all_time,
      COUNT(se2.id) FILTER (
        WHERE es.session_day_anchor >= CURRENT_DATE - INTERVAL '30 days'
      )                                           AS total_sets_last_30d,
      COUNT(DISTINCT es.user_id)                  AS unique_users,
      MAX(es.session_day_anchor)::TEXT            AS last_used_date
    FROM exercise_scope es
    LEFT JOIN public.set_entries se2
      ON se2.session_exercise_id = es.exercise_id
    GROUP BY es.effective_equipment_id
  ),
  feedback_stats AS (
    SELECT
      ef.equipment_id,
      COUNT(*) FILTER (WHERE ef.status IN ('open', 'in_progress'))
                                                  AS feedback_open_count,
      COUNT(*)                                    AS feedback_total_count,
      MAX(ef.created_at)::DATE::TEXT             AS last_feedback_date
    FROM public.equipment_feedback ef
    WHERE ef.gym_id = p_gym_id
    GROUP BY ef.equipment_id
  )
  SELECT COALESCE(json_agg(row_to_json(t)), '[]'::JSON) INTO v_result
  FROM (
    SELECT
      ge.id                                       AS equipment_id,
      ge.name                                     AS equipment_name,
      ge.equipment_type,
      ge.is_active,
      (ge.nfc_tag_uid IS NOT NULL)               AS has_nfc_tag,
      COALESCE(us.total_sets_all_time, 0)        AS total_sets_all_time,
      COALESCE(us.total_sets_last_30d, 0)        AS total_sets_last_30d,
      COALESCE(us.unique_users, 0)               AS unique_users,
      us.last_used_date,
      COALESCE(fs.feedback_open_count, 0)        AS feedback_open_count,
      COALESCE(fs.feedback_total_count, 0)       AS feedback_total_count,
      fs.last_feedback_date
    FROM public.gym_equipment ge
    LEFT JOIN usage_stats us
      ON us.equipment_id = ge.id
    LEFT JOIN feedback_stats fs
      ON fs.equipment_id = ge.id
    WHERE ge.gym_id = p_gym_id
    ORDER BY
      COALESCE(us.total_sets_last_30d, 0) DESC,
      COALESCE(fs.feedback_open_count, 0) DESC,
      ge.name ASC
  ) t;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_equipment_usage_stats(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- SECTION 2 — Challenge KPIs for admin view
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_challenge_kpis(p_gym_id UUID)
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

  WITH challenge_scope AS (
    SELECT
      c.id,
      c.challenge_type,
      c.visibility,
      c.target_metric,
      c.starts_at,
      c.ends_at
    FROM public.challenges c
    WHERE c.gym_id = p_gym_id
  ),
  active_members AS (
    SELECT m.user_id
    FROM public.memberships m
    WHERE m.gym_id    = p_gym_id
      AND m.is_active = TRUE
      AND m.status    = 'active'
  ),
  per_user_progress AS (
    SELECT
      c.id                                    AS challenge_id,
      c.challenge_type,
      c.visibility,
      c.target_metric,
      m.user_id,
      CASE c.challenge_type
        WHEN 'training_days' THEN (
          SELECT COUNT(DISTINCT ws.session_day_anchor)::NUMERIC
          FROM public.workout_sessions ws
          WHERE ws.gym_id             = p_gym_id
            AND ws.user_id            = m.user_id
            AND ws.finished_at       IS NOT NULL
            AND ws.session_day_anchor BETWEEN c.starts_at::DATE AND c.ends_at::DATE
        )
        WHEN 'total_xp' THEN (
          SELECT COALESCE(SUM(xe.xp_amount), 0)::NUMERIC
          FROM public.xp_events xe
          WHERE xe.gym_id      = p_gym_id
            AND xe.user_id     = m.user_id
            AND xe.occurred_at >= c.starts_at
            AND xe.occurred_at <= c.ends_at
        )
        WHEN 'exercise_volume' THEN (
          SELECT COALESCE(
            SUM(COALESCE(se.weight_kg, 0)::NUMERIC * COALESCE(se.reps, 0)::NUMERIC),
            0
          )
          FROM public.set_entries se
          JOIN public.session_exercises sx
            ON sx.id = se.session_exercise_id
          JOIN public.workout_sessions ws
            ON ws.id                = sx.session_id
           AND ws.gym_id            = p_gym_id
           AND ws.user_id           = m.user_id
           AND ws.finished_at      IS NOT NULL
          WHERE ws.session_day_anchor BETWEEN c.starts_at::DATE AND c.ends_at::DATE
        )
        ELSE 0::NUMERIC
      END                                     AS progress_value
    FROM challenge_scope c
    CROSS JOIN active_members m
  ),
  aggregated AS (
    SELECT
      p.challenge_id,
      MIN(p.challenge_type)                                            AS challenge_type,
      MIN(p.visibility)                                                AS visibility,
      MIN(p.target_metric)                                             AS target_metric,
      COUNT(*)                                                         AS eligible_members,
      COUNT(*) FILTER (WHERE p.progress_value > 0)                     AS participants_started,
      COUNT(*) FILTER (WHERE p.progress_value >= p.target_metric)      AS participants_completed,
      COALESCE(AVG(p.progress_value), 0)::NUMERIC                      AS avg_progress_value,
      COALESCE(MAX(p.progress_value), 0)::NUMERIC                      AS best_progress_value
    FROM per_user_progress p
    GROUP BY p.challenge_id
  )
  SELECT COALESCE(json_agg(row_to_json(t)), '[]'::JSON) INTO v_result
  FROM (
    SELECT
      c.id                                                             AS challenge_id,
      COALESCE(a.challenge_type, c.challenge_type)                     AS challenge_type,
      COALESCE(a.visibility, c.visibility)                             AS visibility,
      COALESCE(a.target_metric, c.target_metric)                       AS target_metric,
      COALESCE(a.eligible_members, 0)                                  AS eligible_members,
      COALESCE(a.participants_started, 0)                              AS participants_started,
      COALESCE(a.participants_completed, 0)                            AS participants_completed,
      CASE
        WHEN COALESCE(a.eligible_members, 0) = 0 THEN 0
        ELSE ROUND(
          (COALESCE(a.participants_started, 0)::NUMERIC
            / a.eligible_members::NUMERIC) * 100,
          1
        )
      END                                                              AS participation_rate_pct,
      CASE
        WHEN COALESCE(a.visibility, c.visibility) = 'opt_in' THEN
          CASE
            WHEN COALESCE(a.participants_started, 0) = 0 THEN 0
            ELSE ROUND(
              (COALESCE(a.participants_completed, 0)::NUMERIC
                / a.participants_started::NUMERIC) * 100,
              1
            )
          END
        ELSE
          CASE
            WHEN COALESCE(a.eligible_members, 0) = 0 THEN 0
            ELSE ROUND(
              (COALESCE(a.participants_completed, 0)::NUMERIC
                / a.eligible_members::NUMERIC) * 100,
              1
            )
          END
      END                                                              AS completion_rate_pct,
      ROUND(COALESCE(a.avg_progress_value, 0), 1)                      AS avg_progress_value,
      ROUND(COALESCE(a.best_progress_value, 0), 1)                     AS best_progress_value
    FROM challenge_scope c
    LEFT JOIN aggregated a
      ON a.challenge_id = c.id
    ORDER BY c.starts_at DESC
  ) t;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_challenge_kpis(UUID) TO authenticated;
