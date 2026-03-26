-- =============================================================================
-- Tap'em — Diagnostic: check for orphan workout sessions for pumpingerskatze
--
-- Shows any unfinished sessions on the remote DB (workout_sessions).
-- These would be sessions that started but never received a finish-session
-- event — i.e., sessions lost due to the auth-token-expiry bug.
-- =============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_row     RECORD;
  v_count   INT := 0;
BEGIN
  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE lower(username::TEXT) = 'pumpingerskatze';

  IF v_user_id IS NULL THEN
    RAISE NOTICE 'User pumpingerskatze not found';
    RETURN;
  END IF;

  RAISE NOTICE 'Checking workout_sessions for user % (pumpingerskatze):', v_user_id;

  FOR v_row IN
    SELECT id, gym_id, started_at, finished_at, sync_status
    FROM public.workout_sessions
    WHERE user_id = v_user_id
    ORDER BY started_at DESC
    LIMIT 10
  LOOP
    v_count := v_count + 1;
    RAISE NOTICE '  session % | gym % | started % | finished % | status %',
      v_row.id,
      v_row.gym_id,
      v_row.started_at,
      COALESCE(v_row.finished_at::TEXT, 'NULL (orphan!)'),
      v_row.sync_status;
  END LOOP;

  IF v_count = 0 THEN
    RAISE NOTICE '  No server-side sessions found. Session may have been local-only (never synced).';
  ELSE
    RAISE NOTICE 'Total: % sessions found (most recent first).', v_count;
  END IF;
END $$;
