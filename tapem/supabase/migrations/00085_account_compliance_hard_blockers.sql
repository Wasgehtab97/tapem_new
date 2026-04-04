-- =============================================================================
-- Tap'em — 00085: Compliance hard-blockers (account delete/export readiness)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Fix FK nullability mismatch that can block auth user deletion
-- -----------------------------------------------------------------------------
-- ON DELETE SET NULL requires nullable FK columns.
ALTER TABLE public.workout_plans
  ALTER COLUMN created_by DROP NOT NULL;

ALTER TABLE public.plan_assignments
  ALTER COLUMN assigned_by DROP NOT NULL;

-- -----------------------------------------------------------------------------
-- 2) Storage bucket for GDPR data exports
-- -----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-exports',
  'user-exports',
  false,
  10485760, -- 10 MB export payload cap
  ARRAY['application/json']
)
ON CONFLICT (id) DO NOTHING;

-- Authenticated users can read only their own export files.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'user_exports_owner_read'
  ) THEN
    CREATE POLICY "user_exports_owner_read"
      ON storage.objects FOR SELECT
      USING (
        bucket_id = 'user-exports'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
      );
  END IF;
END $$;

-- Authenticated users can delete only their own export files.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'user_exports_owner_delete'
  ) THEN
    CREATE POLICY "user_exports_owner_delete"
      ON storage.objects FOR DELETE
      USING (
        bucket_id = 'user-exports'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
      );
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 3) User self-service export payload RPC (auth-scoped)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_my_account_data_export()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_payload JSONB;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT jsonb_build_object(
    'generated_at', NOW(),
    'user_id', v_user_id,

    -- Identity / profile
    'user_profile', COALESCE(
      (SELECT to_jsonb(up) FROM public.user_profiles up WHERE up.id = v_user_id),
      '{}'::jsonb
    ),
    'username_reservations', COALESCE(
      (SELECT jsonb_agg(to_jsonb(ur) ORDER BY ur.reserved_at)
         FROM public.username_reservations ur
        WHERE ur.user_id = v_user_id),
      '[]'::jsonb
    ),

    -- Membership / social
    'memberships', COALESCE(
      (SELECT jsonb_agg(to_jsonb(m) ORDER BY m.created_at)
         FROM public.memberships m
        WHERE m.user_id = v_user_id),
      '[]'::jsonb
    ),
    'friendships_as_requester', COALESCE(
      (SELECT jsonb_agg(to_jsonb(f) ORDER BY f.created_at)
         FROM public.friendships f
        WHERE f.requester_id = v_user_id),
      '[]'::jsonb
    ),
    'friendships_as_addressee', COALESCE(
      (SELECT jsonb_agg(to_jsonb(f) ORDER BY f.created_at)
         FROM public.friendships f
        WHERE f.addressee_id = v_user_id),
      '[]'::jsonb
    ),
    'notifications', COALESCE(
      (SELECT jsonb_agg(to_jsonb(n) ORDER BY n.created_at)
         FROM public.notifications n
        WHERE n.user_id = v_user_id),
      '[]'::jsonb
    ),

    -- Workout / XP
    'workout_sessions', COALESCE(
      (SELECT jsonb_agg(to_jsonb(ws) ORDER BY ws.started_at)
         FROM public.workout_sessions ws
        WHERE ws.user_id = v_user_id),
      '[]'::jsonb
    ),
    'session_exercises', COALESCE(
      (SELECT jsonb_agg(to_jsonb(se) ORDER BY se.created_at)
         FROM public.session_exercises se
         JOIN public.workout_sessions ws ON ws.id = se.session_id
        WHERE ws.user_id = v_user_id),
      '[]'::jsonb
    ),
    'set_entries', COALESCE(
      (SELECT jsonb_agg(to_jsonb(st) ORDER BY st.created_at)
         FROM public.set_entries st
         JOIN public.session_exercises se ON se.id = st.session_exercise_id
         JOIN public.workout_sessions ws ON ws.id = se.session_id
        WHERE ws.user_id = v_user_id),
      '[]'::jsonb
    ),
    'xp_events', COALESCE(
      (SELECT jsonb_agg(to_jsonb(xe) ORDER BY xe.occurred_at)
         FROM public.xp_events xe
        WHERE xe.user_id = v_user_id),
      '[]'::jsonb
    ),
    'user_gym_xp', COALESCE(
      (SELECT jsonb_agg(to_jsonb(ugx) ORDER BY ugx.updated_at)
         FROM public.user_gym_xp ugx
        WHERE ugx.user_id = v_user_id),
      '[]'::jsonb
    ),
    'user_exercise_xp', COALESCE(
      (SELECT jsonb_agg(to_jsonb(uex) ORDER BY uex.updated_at)
         FROM public.user_exercise_xp uex
        WHERE uex.user_id = v_user_id),
      '[]'::jsonb
    ),
    'user_muscle_group_xp', COALESCE(
      (SELECT jsonb_agg(to_jsonb(umx) ORDER BY umx.updated_at)
         FROM public.user_muscle_group_xp umx
        WHERE umx.user_id = v_user_id),
      '[]'::jsonb
    ),

    -- User-authored content
    'user_custom_exercises', COALESCE(
      (SELECT jsonb_agg(to_jsonb(ucx) ORDER BY ucx.created_at)
         FROM public.user_custom_exercises ucx
        WHERE ucx.user_id = v_user_id),
      '[]'::jsonb
    ),
    'user_custom_exercise_muscle_groups', COALESCE(
      (SELECT jsonb_agg(to_jsonb(ucmg))
         FROM public.user_custom_exercise_muscle_groups ucmg
        WHERE ucmg.user_id = v_user_id),
      '[]'::jsonb
    ),

    -- Plans
    'workout_plans_created', COALESCE(
      (SELECT jsonb_agg(to_jsonb(wp) ORDER BY wp.created_at)
         FROM public.workout_plans wp
        WHERE wp.created_by = v_user_id),
      '[]'::jsonb
    ),
    'plan_assignments_assigned_to', COALESCE(
      (SELECT jsonb_agg(to_jsonb(pa) ORDER BY pa.assigned_at)
         FROM public.plan_assignments pa
        WHERE pa.assigned_to = v_user_id),
      '[]'::jsonb
    ),
    'plan_assignments_assigned_by', COALESCE(
      (SELECT jsonb_agg(to_jsonb(pa) ORDER BY pa.assigned_at)
         FROM public.plan_assignments pa
        WHERE pa.assigned_by = v_user_id),
      '[]'::jsonb
    ),

    -- Activity / ranking / feed
    'level_snapshots', COALESCE(
      (SELECT jsonb_agg(to_jsonb(ls) ORDER BY ls.snapshotted_at)
         FROM public.level_snapshots ls
        WHERE ls.user_id = v_user_id),
      '[]'::jsonb
    ),
    'achievements', COALESCE(
      (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.unlocked_at)
         FROM public.achievements a
        WHERE a.user_id = v_user_id),
      '[]'::jsonb
    ),
    'ranking_events', COALESCE(
      (SELECT jsonb_agg(to_jsonb(re) ORDER BY re.occurred_at)
         FROM public.ranking_events re
        WHERE re.user_id = v_user_id),
      '[]'::jsonb
    ),
    'ranking_snapshots', COALESCE(
      (SELECT jsonb_agg(to_jsonb(rs) ORDER BY rs.snapshotted_at)
         FROM public.ranking_snapshots rs
        WHERE rs.user_id = v_user_id),
      '[]'::jsonb
    ),
    'feed_events', COALESCE(
      (SELECT jsonb_agg(to_jsonb(fe) ORDER BY fe.created_at)
         FROM public.feed_events fe
        WHERE fe.actor_id = v_user_id),
      '[]'::jsonb
    ),

    -- Machine performance
    'user_machine_exercise_best', COALESCE(
      (SELECT jsonb_agg(to_jsonb(ub) ORDER BY ub.computed_at)
         FROM public.user_machine_exercise_best ub
        WHERE ub.user_id = v_user_id),
      '[]'::jsonb
    ),
    'user_machine_equipment_best', COALESCE(
      (SELECT jsonb_agg(to_jsonb(ub) ORDER BY ub.computed_at)
         FROM public.user_machine_equipment_best ub
        WHERE ub.user_id = v_user_id),
      '[]'::jsonb
    ),

    -- Moderation / support traces
    'equipment_feedback_reports', COALESCE(
      (SELECT jsonb_agg(to_jsonb(ef) ORDER BY ef.created_at)
         FROM public.equipment_feedback ef
        WHERE ef.user_id = v_user_id),
      '[]'::jsonb
    ),
    'content_reports_as_reporter', COALESCE(
      (SELECT jsonb_agg(to_jsonb(cr) ORDER BY cr.created_at)
         FROM public.content_reports cr
        WHERE cr.reporter_id = v_user_id),
      '[]'::jsonb
    ),
    'content_reports_as_target', COALESCE(
      (SELECT jsonb_agg(to_jsonb(cr) ORDER BY cr.created_at)
         FROM public.content_reports cr
        WHERE cr.target_user_id = v_user_id),
      '[]'::jsonb
    ),
    'content_reports_resolved_by_user', COALESCE(
      (SELECT jsonb_agg(to_jsonb(cr) ORDER BY cr.resolved_at)
         FROM public.content_reports cr
        WHERE cr.resolved_by = v_user_id),
      '[]'::jsonb
    ),
    'admin_audit_log_actor', COALESCE(
      (SELECT jsonb_agg(to_jsonb(al) ORDER BY al.created_at)
         FROM public.admin_audit_log al
        WHERE al.actor_id = v_user_id),
      '[]'::jsonb
    ),

    -- Nutrition
    'nutrition_goals', COALESCE(
      (SELECT jsonb_agg(to_jsonb(ng) ORDER BY ng.updated_at)
         FROM public.nutrition_goals ng
        WHERE ng.user_id = v_user_id),
      '[]'::jsonb
    ),
    'nutrition_goal_defaults', COALESCE(
      (SELECT jsonb_agg(to_jsonb(nd) ORDER BY nd.updated_at)
         FROM public.nutrition_goal_defaults nd
        WHERE nd.user_id = v_user_id),
      '[]'::jsonb
    ),
    'nutrition_logs', COALESCE(
      (SELECT jsonb_agg(to_jsonb(nl) ORDER BY nl.updated_at)
         FROM public.nutrition_logs nl
        WHERE nl.user_id = v_user_id),
      '[]'::jsonb
    ),
    'nutrition_year_summaries', COALESCE(
      (SELECT jsonb_agg(to_jsonb(nys) ORDER BY nys.updated_at)
         FROM public.nutrition_year_summaries nys
        WHERE nys.user_id = v_user_id),
      '[]'::jsonb
    ),
    'nutrition_recipes', COALESCE(
      (SELECT jsonb_agg(to_jsonb(nr) ORDER BY nr.updated_at)
         FROM public.nutrition_recipes nr
        WHERE nr.user_id = v_user_id),
      '[]'::jsonb
    ),
    'nutrition_weight_logs', COALESCE(
      (SELECT jsonb_agg(to_jsonb(nwl) ORDER BY nwl.updated_at)
         FROM public.nutrition_weight_logs nwl
        WHERE nwl.user_id = v_user_id),
      '[]'::jsonb
    ),
    'nutrition_weight_year_summaries', COALESCE(
      (SELECT jsonb_agg(to_jsonb(nwys) ORDER BY nwys.updated_at)
         FROM public.nutrition_weight_year_summaries nwys
        WHERE nwys.user_id = v_user_id),
      '[]'::jsonb
    ),
    'nutrition_weight_meta', COALESCE(
      (SELECT jsonb_agg(to_jsonb(nwm) ORDER BY nwm.updated_at)
         FROM public.nutrition_weight_meta nwm
        WHERE nwm.user_id = v_user_id),
      '[]'::jsonb
    )
  )
  INTO v_payload;

  RETURN v_payload;
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_account_data_export() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_account_data_export() TO authenticated;

COMMENT ON FUNCTION public.get_my_account_data_export() IS
  'Returns a full user-scoped JSONB export for DSGVO access/export requests.';
