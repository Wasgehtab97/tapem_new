-- =============================================================================
-- Tap'em — Admin Portal
-- Schema extensions, new tables, and RPCs for the gym-owner admin area.
--
-- Every statement is written idempotently (IF NOT EXISTS / DO…EXCEPTION).
-- All RPCs use SECURITY DEFINER and verify the caller's role before acting.
-- All privileged mutations write to admin_audit_log automatically.
-- =============================================================================

-- =============================================================================
-- SECTION 1 — Schema extensions on existing tables
-- =============================================================================

-- ─── tenant_gyms: description + approval toggle ────────────────────────────

ALTER TABLE public.tenant_gyms
  ADD COLUMN IF NOT EXISTS description      TEXT,
  ADD COLUMN IF NOT EXISTS requires_approval BOOLEAN NOT NULL DEFAULT FALSE;

-- ─── memberships: status column for approval workflow ─────────────────────
-- 'active'   — full member (default for existing + new-without-approval rows)
-- 'pending'  — awaiting admin approval (requires_approval gyms only)
-- 'inactive' — deactivated by admin

ALTER TABLE public.memberships
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';

-- Backfill: all existing is_active=TRUE rows are active
UPDATE public.memberships
   SET status = 'active'
 WHERE status IS NULL OR status = '';

-- Add constraint after backfill (idempotent via separate DDL)
DO $$ BEGIN
  ALTER TABLE public.memberships
    ADD CONSTRAINT memberships_status_check
    CHECK (status IN ('pending', 'active', 'inactive'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── challenges: type, target, visibility ─────────────────────────────────

ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS challenge_type TEXT    NOT NULL DEFAULT 'training_days',
  ADD COLUMN IF NOT EXISTS target_metric  NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS visibility     TEXT    NOT NULL DEFAULT 'all_members',
  ADD COLUMN IF NOT EXISTS updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$ BEGIN
  ALTER TABLE public.challenges
    ADD CONSTRAINT challenges_type_check
    CHECK (challenge_type IN ('training_days', 'total_xp', 'exercise_volume'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE public.challenges
    ADD CONSTRAINT challenges_visibility_check
    CHECK (visibility IN ('all_members', 'opt_in'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── equipment_feedback: feedback_type + status ────────────────────────────

ALTER TABLE public.equipment_feedback
  ADD COLUMN IF NOT EXISTS feedback_type TEXT NOT NULL DEFAULT 'broken',
  ADD COLUMN IF NOT EXISTS status        TEXT NOT NULL DEFAULT 'open';

DO $$ BEGIN
  ALTER TABLE public.equipment_feedback
    ADD CONSTRAINT equipment_feedback_type_check
    CHECK (feedback_type IN ('broken', 'maintenance', 'suggestion'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE public.equipment_feedback
    ADD CONSTRAINT equipment_feedback_status_check
    CHECK (status IN ('open', 'in_progress', 'resolved'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Add updated_at for status tracking
ALTER TABLE public.equipment_feedback
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.equipment_feedback
  ADD COLUMN IF NOT EXISTS resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- =============================================================================
-- SECTION 2 — New tables
-- =============================================================================

-- ─── admin_audit_log ──────────────────────────────────────────────────────
-- Append-only log of all privileged admin actions. Written only by RPCs
-- (SECURITY DEFINER). No client INSERT permitted.

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id      UUID        NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  actor_id    UUID        NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  action      TEXT        NOT NULL,
  target_id   UUID,
  metadata    JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_gym
  ON public.admin_audit_log (gym_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_actor
  ON public.admin_audit_log (actor_id);

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Admins/owners can read the audit log for their gym; no client can INSERT.
DO $$ BEGIN
  CREATE POLICY "audit_log_admin_read"
    ON public.admin_audit_log FOR SELECT
    TO authenticated
    USING (public.is_gym_admin(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

GRANT SELECT                    ON public.admin_audit_log TO authenticated;
GRANT ALL                       ON public.admin_audit_log TO service_role;

-- ─── content_reports ──────────────────────────────────────────────────────
-- Members can file conduct reports. Admins resolve or dismiss them.

CREATE TABLE IF NOT EXISTS public.content_reports (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id          UUID        NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  reporter_id     UUID        NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  target_user_id  UUID        REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  report_type     TEXT        NOT NULL,
  description     TEXT,
  status          TEXT        NOT NULL DEFAULT 'pending',
  admin_note      TEXT,
  resolved_by     UUID        REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  resolved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$ BEGIN
  ALTER TABLE public.content_reports
    ADD CONSTRAINT content_reports_type_check
    CHECK (report_type IN ('inappropriate_username', 'spam', 'harassment', 'other'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE public.content_reports
    ADD CONSTRAINT content_reports_status_check
    CHECK (status IN ('pending', 'resolved', 'dismissed'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS idx_content_reports_gym
  ON public.content_reports (gym_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_content_reports_reporter
  ON public.content_reports (reporter_id);

ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "content_reports_member_insert"
    ON public.content_reports FOR INSERT
    TO authenticated
    WITH CHECK (
      reporter_id = auth.uid()
      AND public.has_active_membership(gym_id)
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "content_reports_admin_read"
    ON public.content_reports FOR SELECT
    TO authenticated
    USING (public.is_gym_admin(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "content_reports_admin_update"
    ON public.content_reports FOR UPDATE
    TO authenticated
    USING (public.is_gym_admin(gym_id))
    WITH CHECK (public.is_gym_admin(gym_id));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

GRANT SELECT, INSERT            ON public.content_reports TO authenticated;
GRANT ALL                       ON public.content_reports TO service_role;

-- =============================================================================
-- SECTION 3 — Private helper: _log_admin_action
-- Called internally by every privileged RPC; never called directly by clients.
-- =============================================================================

CREATE OR REPLACE FUNCTION public._log_admin_action(
  p_gym_id    UUID,
  p_action    TEXT,
  p_target_id UUID  DEFAULT NULL,
  p_metadata  JSONB DEFAULT NULL
) RETURNS VOID
  SECURITY DEFINER
  LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.admin_audit_log (gym_id, actor_id, action, target_id, metadata)
  VALUES (p_gym_id, auth.uid(), p_action, p_target_id, p_metadata);
END;
$$;

-- =============================================================================
-- SECTION 4 — Gym-management RPCs
-- =============================================================================

-- ─── update_gym_profile ───────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_gym_profile(
  p_gym_id            UUID,
  p_name              TEXT,
  p_description       TEXT,
  p_requires_approval BOOLEAN DEFAULT NULL
) RETURNS VOID
  SECURITY DEFINER
  LANGUAGE plpgsql
AS $$
DECLARE
  v_old_name TEXT;
  v_old_desc TEXT;
BEGIN
  IF NOT public.is_gym_admin(p_gym_id) THEN
    RAISE EXCEPTION 'not_admin';
  END IF;

  IF LENGTH(TRIM(p_name)) < 3 OR LENGTH(TRIM(p_name)) > 60 THEN
    RAISE EXCEPTION 'invalid_gym_name: must be 3–60 characters';
  END IF;

  SELECT name, description
    INTO v_old_name, v_old_desc
    FROM public.tenant_gyms
   WHERE id = p_gym_id;

  UPDATE public.tenant_gyms
     SET name               = TRIM(p_name),
         description        = p_description,
         requires_approval  = COALESCE(p_requires_approval, requires_approval),
         updated_at         = NOW()
   WHERE id = p_gym_id;

  PERFORM public._log_admin_action(
    p_gym_id,
    'update_gym_profile',
    p_gym_id,
    jsonb_build_object(
      'old_name',        v_old_name,
      'new_name',        TRIM(p_name),
      'old_description', v_old_desc,
      'new_description', p_description
    )
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_gym_profile(UUID, TEXT, TEXT, BOOLEAN) TO authenticated;

-- =============================================================================
-- SECTION 5 — Member-management RPCs
-- =============================================================================

-- ─── set_member_role ──────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.set_member_role(
  p_gym_id    UUID,
  p_target_id UUID,
  p_new_role  TEXT
) RETURNS VOID
  SECURITY DEFINER
  LANGUAGE plpgsql
AS $$
DECLARE
  v_old_role TEXT;
  v_caller_role TEXT;
BEGIN
  -- Validate role value
  IF p_new_role NOT IN ('member', 'coach', 'admin') THEN
    RAISE EXCEPTION 'invalid_role: must be member, coach, or admin';
  END IF;

  -- Caller must be admin/owner
  IF NOT public.is_gym_admin(p_gym_id) THEN
    RAISE EXCEPTION 'not_admin';
  END IF;

  -- Fetch target's current role
  SELECT role INTO v_old_role
    FROM public.memberships
   WHERE gym_id = p_gym_id AND user_id = p_target_id;

  IF v_old_role IS NULL THEN
    RAISE EXCEPTION 'member_not_found';
  END IF;

  -- Owner role is immutable via this function
  IF v_old_role = 'owner' THEN
    RAISE EXCEPTION 'cannot_change_owner: use transfer_ownership instead';
  END IF;

  -- Admins cannot demote themselves
  IF p_target_id = auth.uid() THEN
    RAISE EXCEPTION 'cannot_change_own_role';
  END IF;

  -- Non-owners cannot promote to admin
  SELECT role INTO v_caller_role
    FROM public.memberships
   WHERE gym_id = p_gym_id AND user_id = auth.uid() AND is_active = TRUE;

  IF p_new_role = 'admin' AND v_caller_role != 'owner' THEN
    RAISE EXCEPTION 'only_owner_can_promote_admin';
  END IF;

  UPDATE public.memberships
     SET role = p_new_role
   WHERE gym_id = p_gym_id AND user_id = p_target_id;

  PERFORM public._log_admin_action(
    p_gym_id,
    'role_change',
    p_target_id,
    jsonb_build_object('old_role', v_old_role, 'new_role', p_new_role)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_member_role(UUID, UUID, TEXT) TO authenticated;

-- ─── approve_member_request ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.approve_member_request(
  p_gym_id  UUID,
  p_user_id UUID
) RETURNS VOID
  SECURITY DEFINER
  LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT public.is_gym_admin(p_gym_id) THEN
    RAISE EXCEPTION 'not_admin';
  END IF;

  UPDATE public.memberships
     SET status    = 'active',
         is_active = TRUE
   WHERE gym_id   = p_gym_id
     AND user_id  = p_user_id
     AND status   = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'member_not_pending';
  END IF;

  PERFORM public._log_admin_action(p_gym_id, 'approve_member', p_user_id, NULL);
END;
$$;

GRANT EXECUTE ON FUNCTION public.approve_member_request(UUID, UUID) TO authenticated;

-- ─── decline_member_request ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.decline_member_request(
  p_gym_id  UUID,
  p_user_id UUID
) RETURNS VOID
  SECURITY DEFINER
  LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT public.is_gym_admin(p_gym_id) THEN
    RAISE EXCEPTION 'not_admin';
  END IF;

  UPDATE public.memberships
     SET status    = 'inactive',
         is_active = FALSE
   WHERE gym_id   = p_gym_id
     AND user_id  = p_user_id
     AND status   = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'member_not_pending';
  END IF;

  PERFORM public._log_admin_action(p_gym_id, 'decline_member', p_user_id, NULL);
END;
$$;

GRANT EXECUTE ON FUNCTION public.decline_member_request(UUID, UUID) TO authenticated;

-- ─── deactivate_member ────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.deactivate_member(
  p_gym_id  UUID,
  p_user_id UUID,
  p_reason  TEXT DEFAULT NULL
) RETURNS VOID
  SECURITY DEFINER
  LANGUAGE plpgsql
AS $$
DECLARE
  v_old_role TEXT;
BEGIN
  IF NOT public.is_gym_admin(p_gym_id) THEN
    RAISE EXCEPTION 'not_admin';
  END IF;

  SELECT role INTO v_old_role
    FROM public.memberships
   WHERE gym_id = p_gym_id AND user_id = p_user_id;

  IF v_old_role IS NULL THEN
    RAISE EXCEPTION 'member_not_found';
  END IF;

  IF v_old_role = 'owner' THEN
    RAISE EXCEPTION 'cannot_deactivate_owner';
  END IF;

  UPDATE public.memberships
     SET status    = 'inactive',
         is_active = FALSE
   WHERE gym_id   = p_gym_id
     AND user_id  = p_user_id;

  PERFORM public._log_admin_action(
    p_gym_id,
    'deactivate_member',
    p_user_id,
    jsonb_build_object('reason', p_reason, 'old_role', v_old_role)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.deactivate_member(UUID, UUID, TEXT) TO authenticated;

-- =============================================================================
-- SECTION 6 — Analytics RPCs (SECURITY DEFINER, admin-gated)
-- =============================================================================

-- ─── get_gym_activity_stats ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_gym_activity_stats(p_gym_id UUID)
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
    'dau',
      (SELECT COUNT(DISTINCT user_id)
         FROM public.workout_sessions
        WHERE gym_id           = p_gym_id
          AND finished_at      IS NOT NULL
          AND session_day_anchor = CURRENT_DATE),
    'wau',
      (SELECT COUNT(DISTINCT user_id)
         FROM public.workout_sessions
        WHERE gym_id             = p_gym_id
          AND finished_at        IS NOT NULL
          AND session_day_anchor >= CURRENT_DATE - INTERVAL '7 days'),
    'mau',
      (SELECT COUNT(DISTINCT user_id)
         FROM public.workout_sessions
        WHERE gym_id             = p_gym_id
          AND finished_at        IS NOT NULL
          AND session_day_anchor >= CURRENT_DATE - INTERVAL '30 days'),
    'total_members',
      (SELECT COUNT(*)
         FROM public.memberships
        WHERE gym_id    = p_gym_id
          AND is_active = TRUE
          AND status    = 'active'),
    'pending_approvals',
      (SELECT COUNT(*)
         FROM public.memberships
        WHERE gym_id = p_gym_id AND status = 'pending'),
    'new_members_this_month',
      (SELECT COUNT(*)
         FROM public.memberships
        WHERE gym_id    = p_gym_id
          AND is_active = TRUE
          AND status    = 'active'
          AND joined_at >= date_trunc('month', CURRENT_DATE)),
    'total_sessions_this_month',
      (SELECT COUNT(*)
         FROM public.workout_sessions
        WHERE gym_id             = p_gym_id
          AND finished_at        IS NOT NULL
          AND session_day_anchor >= date_trunc('month', CURRENT_DATE)),
    'daily_activity',
      (SELECT COALESCE(json_agg(row_to_json(t) ORDER BY (t).date), '[]'::JSON)
         FROM (
           SELECT
             session_day_anchor::TEXT                  AS date,
             COUNT(DISTINCT user_id)::INT              AS active_users
           FROM public.workout_sessions
          WHERE gym_id             = p_gym_id
            AND finished_at        IS NOT NULL
            AND session_day_anchor >= CURRENT_DATE - INTERVAL '30 days'
          GROUP BY session_day_anchor
         ) t)
  ) INTO v_result;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_gym_activity_stats(UUID) TO authenticated;

-- ─── get_equipment_usage_stats ────────────────────────────────────────────

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
      ge.id                                                          AS equipment_id,
      ge.name                                                        AS equipment_name,
      ge.equipment_type,
      ge.is_active,
      COUNT(se2.id)                                                  AS total_sets_all_time,
      COUNT(se2.id) FILTER (
        WHERE ws.session_day_anchor >= CURRENT_DATE - INTERVAL '30 days'
      )                                                              AS total_sets_last_30d,
      COUNT(DISTINCT ws.user_id)                                     AS unique_users,
      MAX(ws.session_day_anchor)::TEXT                               AS last_used_date
    FROM public.gym_equipment ge
    LEFT JOIN public.workout_sessions ws
      ON ws.gym_id        = p_gym_id
      AND ws.equipment_id = ge.id
      AND ws.finished_at  IS NOT NULL
    LEFT JOIN public.session_exercises sex
      ON sex.session_id = ws.id
    LEFT JOIN public.set_entries se2
      ON se2.session_exercise_id = sex.id
    WHERE ge.gym_id = p_gym_id
    GROUP BY ge.id, ge.name, ge.equipment_type, ge.is_active
    ORDER BY total_sets_last_30d DESC NULLS LAST, ge.name ASC
  ) t;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_equipment_usage_stats(UUID) TO authenticated;

-- ─── get_gym_engagement_stats ─────────────────────────────────────────────

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
               WHEN ls.level BETWEEN 1  AND 3  THEN '1–3'
               WHEN ls.level BETWEEN 4  AND 6  THEN '4–6'
               WHEN ls.level BETWEEN 7  AND 10 THEN '7–10'
               ELSE '11+'
             END                                AS level_range,
             MIN(ls.level)                      AS min_level,
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

-- =============================================================================
-- SECTION 7 — Moderation and feedback RPCs
-- =============================================================================

-- ─── resolve_content_report ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.resolve_content_report(
  p_report_id UUID,
  p_action    TEXT,
  p_note      TEXT DEFAULT NULL
) RETURNS VOID
  SECURITY DEFINER
  LANGUAGE plpgsql
AS $$
DECLARE
  v_gym_id UUID;
BEGIN
  IF p_action NOT IN ('resolve', 'dismiss') THEN
    RAISE EXCEPTION 'invalid_action: must be resolve or dismiss';
  END IF;

  SELECT gym_id INTO v_gym_id
    FROM public.content_reports
   WHERE id = p_report_id;

  IF v_gym_id IS NULL THEN
    RAISE EXCEPTION 'report_not_found';
  END IF;

  IF NOT public.is_gym_admin(v_gym_id) THEN
    RAISE EXCEPTION 'not_admin';
  END IF;

  UPDATE public.content_reports
     SET status      = CASE WHEN p_action = 'dismiss' THEN 'dismissed' ELSE 'resolved' END,
         admin_note  = p_note,
         resolved_by = auth.uid(),
         resolved_at = NOW()
   WHERE id = p_report_id;

  PERFORM public._log_admin_action(
    v_gym_id,
    'resolve_report',
    p_report_id,
    jsonb_build_object('action', p_action, 'note', p_note)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.resolve_content_report(UUID, TEXT, TEXT) TO authenticated;

-- ─── update_equipment_feedback_status ────────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_equipment_feedback_status(
  p_feedback_id UUID,
  p_status      TEXT
) RETURNS VOID
  SECURITY DEFINER
  LANGUAGE plpgsql
AS $$
DECLARE
  v_gym_id UUID;
BEGIN
  IF p_status NOT IN ('open', 'in_progress', 'resolved') THEN
    RAISE EXCEPTION 'invalid_status';
  END IF;

  SELECT gym_id INTO v_gym_id
    FROM public.equipment_feedback
   WHERE id = p_feedback_id;

  IF v_gym_id IS NULL THEN
    RAISE EXCEPTION 'feedback_not_found';
  END IF;

  IF NOT public.is_gym_coach(v_gym_id) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  UPDATE public.equipment_feedback
     SET status      = p_status,
         updated_at  = NOW(),
         resolved_by = CASE WHEN p_status = 'resolved' THEN auth.uid() ELSE resolved_by END
   WHERE id = p_feedback_id;

  PERFORM public._log_admin_action(
    v_gym_id,
    'update_feedback_status',
    p_feedback_id,
    jsonb_build_object('new_status', p_status)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_equipment_feedback_status(UUID, TEXT) TO authenticated;

-- =============================================================================
-- SECTION 8 — Update join_gym_with_code to honour requires_approval
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
    INSERT INTO public.memberships (id, gym_id, user_id, role, is_active, status, joined_at)
    VALUES (gen_random_uuid(), v_gym_id, auth.uid(), 'member', FALSE, 'pending', NOW());

    RETURN jsonb_build_object(
      'success',          TRUE,
      'gym_id',           v_gym_id,
      'gym_name',         v_gym_name,
      'pending_approval', TRUE
    );
  ELSE
    INSERT INTO public.memberships (id, gym_id, user_id, role, is_active, status, joined_at)
    VALUES (gen_random_uuid(), v_gym_id, auth.uid(), 'member', TRUE, 'active', NOW())
    ON CONFLICT (user_id, gym_id) DO UPDATE
      SET is_active = TRUE, status = 'active';

    RETURN jsonb_build_object(
      'success',        TRUE,
      'gym_id',         v_gym_id,
      'gym_name',       v_gym_name,
      'already_member', FALSE
    );
  END IF;
END;
$$;

-- Grant already exists from 00007; re-applying is safe
GRANT EXECUTE ON FUNCTION public.join_gym_with_code(TEXT) TO authenticated;

-- =============================================================================
-- SECTION 9 — Grant UPDATE on equipment_feedback to authenticated
-- (Previously only SELECT, INSERT were granted; coaches need UPDATE for status)
-- =============================================================================

GRANT UPDATE ON public.equipment_feedback TO authenticated;
