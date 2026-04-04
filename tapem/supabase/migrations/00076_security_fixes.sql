-- =============================================================================
-- Tap'em — 00076: Security fixes from adversarial review
--
-- 1. Drop dev_promote_to_owner (privilege-escalation backdoor)
-- 2. Fix join_gym_with_code:
--    a) Approval branch: handle existing inactive rows via ON CONFLICT
--    b) Non-approval rejoin: reset role to 'member' on conflict
-- 3. Fix get_equipment_usage_stats: attribute sets to the exercise's
--    equipment (COALESCE fallback to session equipment for legacy nulls)
-- =============================================================================

-- =============================================================================
-- SECTION 1 — Drop dev_promote_to_owner
-- =============================================================================

REVOKE EXECUTE ON FUNCTION public.dev_promote_to_owner(UUID) FROM authenticated;
DROP FUNCTION IF EXISTS public.dev_promote_to_owner(UUID);

-- =============================================================================
-- SECTION 2 — Fix join_gym_with_code
--
-- Two bugs fixed:
-- a) Approval branch: bare INSERT collides with existing inactive/declined rows.
--    Now uses ON CONFLICT to reset the row to pending instead of raising.
-- b) Non-approval branch: ON CONFLICT did not reset role, allowing deactivated
--    admins/coaches to regain elevated privileges by re-entering the join code.
--    Now explicitly sets role = 'member' on conflict.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.join_gym_with_code(p_code TEXT)
RETURNS JSONB
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
AS $$
DECLARE
  v_gym_id            UUID;
  v_gym_name          TEXT;
  v_requires_approval BOOLEAN := FALSE;
  v_existing_status   TEXT;
BEGIN
  -- Look up gym by code (case-insensitive)
  SELECT id, name, COALESCE(requires_approval, FALSE)
    INTO v_gym_id, v_gym_name, v_requires_approval
    FROM public.tenant_gyms
   WHERE LOWER(join_code) = LOWER(TRIM(p_code))
   LIMIT 1;

  IF v_gym_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error',   'invalid_code',
      'message', 'No gym found with this code. Please check and try again.'
    );
  END IF;

  -- Check for any existing membership (any status)
  SELECT status INTO v_existing_status
    FROM public.memberships
   WHERE user_id = auth.uid() AND gym_id = v_gym_id
   LIMIT 1;

  IF v_existing_status = 'active' THEN
    RETURN jsonb_build_object(
      'success',        TRUE,
      'gym_id',         v_gym_id,
      'gym_name',       v_gym_name,
      'already_member', TRUE
    );
  END IF;

  IF v_existing_status = 'pending' THEN
    RETURN jsonb_build_object(
      'success',          TRUE,
      'gym_id',           v_gym_id,
      'gym_name',         v_gym_name,
      'pending_approval', TRUE
    );
  END IF;

  IF v_requires_approval THEN
    -- Fix (a): use ON CONFLICT so declined/deactivated users can re-apply
    -- without a unique-constraint error. Role is reset to 'member' for safety.
    INSERT INTO public.memberships (id, gym_id, user_id, role, is_active, status, joined_at)
    VALUES (gen_random_uuid(), v_gym_id, auth.uid(), 'member', FALSE, 'pending', NOW())
    ON CONFLICT (user_id, gym_id) DO UPDATE
      SET is_active = FALSE,
          status    = 'pending',
          role      = 'member';

    RETURN jsonb_build_object(
      'success',          TRUE,
      'gym_id',           v_gym_id,
      'gym_name',         v_gym_name,
      'pending_approval', TRUE
    );
  ELSE
    -- Fix (b): explicitly reset role to 'member' so deactivated staff cannot
    -- self-restore elevated privileges by re-entering the join code.
    INSERT INTO public.memberships (id, gym_id, user_id, role, is_active, status, joined_at)
    VALUES (gen_random_uuid(), v_gym_id, auth.uid(), 'member', TRUE, 'active', NOW())
    ON CONFLICT (user_id, gym_id) DO UPDATE
      SET is_active = TRUE,
          status    = 'active',
          role      = 'member';

    RETURN jsonb_build_object(
      'success',        TRUE,
      'gym_id',         v_gym_id,
      'gym_name',       v_gym_name,
      'already_member', FALSE
    );
  END IF;
END;
$$;

-- Grant already exists; re-applying is safe
GRANT EXECUTE ON FUNCTION public.join_gym_with_code(TEXT) TO authenticated;

-- =============================================================================
-- SECTION 3 — Fix get_equipment_usage_stats
--
-- Old query joined workout_sessions → session_exercises → set_entries, which
-- attributed ALL sets in a session to the session's primary equipment_id.
-- Mixed-machine sessions (multiple exercises on different equipment) were
-- therefore systematically miscounted.
--
-- Fix: join through session_exercises.equipment_id (COALESCE to
-- workout_sessions.equipment_id for legacy rows where the column is NULL).
-- =============================================================================

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

  SELECT COALESCE(json_agg(row_to_json(t)), '[]'::JSON) INTO v_result
  FROM (
    SELECT
      ge.id                                                            AS equipment_id,
      ge.name                                                          AS equipment_name,
      ge.equipment_type,
      ge.is_active,
      COUNT(se2.id)                                                    AS total_sets_all_time,
      COUNT(se2.id) FILTER (
        WHERE ex.session_day_anchor >= CURRENT_DATE - INTERVAL '30 days'
      )                                                                AS total_sets_last_30d,
      COUNT(DISTINCT ex.user_id)                                       AS unique_users,
      MAX(ex.session_day_anchor)::TEXT                                 AS last_used_date
    FROM public.gym_equipment ge
    LEFT JOIN (
      -- Resolve the effective equipment per exercise:
      -- prefer se.equipment_id (set since migration 00062); fall back to
      -- ws.equipment_id for older rows where only the session had the ID.
      SELECT
        se.id                                                          AS exercise_id,
        COALESCE(se.equipment_id, ws.equipment_id)                    AS effective_equipment_id,
        ws.user_id,
        ws.session_day_anchor
      FROM public.session_exercises se
      JOIN public.workout_sessions ws
        ON ws.id        = se.session_id
       AND ws.gym_id    = p_gym_id
       AND ws.finished_at IS NOT NULL
    ) ex ON ex.effective_equipment_id = ge.id
    LEFT JOIN public.set_entries se2
      ON se2.session_exercise_id = ex.exercise_id
    WHERE ge.gym_id = p_gym_id
    GROUP BY ge.id, ge.name, ge.equipment_type, ge.is_active
    ORDER BY total_sets_last_30d DESC NULLS LAST, ge.name ASC
  ) t;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_equipment_usage_stats(UUID) TO authenticated;
