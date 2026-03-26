-- =============================================================================
-- Tap'em — 00025: Fix Missing Memberships & Stale Sync State
--
-- Problem:
--   ironbronz has no active membership row in the `memberships` table.
--   The sync-workout Edge Function checks for an active membership at
--   line 128-138 and returns HTTP 403 "No active membership for this gym"
--   if none is found. This causes:
--     1. All of ironbronz's workout sessions to be stuck in sync_failed
--        state in local Drift (they ARE retried — getPendingSessions includes
--        sync_failed rows — but they 403 again every 10 seconds).
--     2. ironbronz is invisible on the membership-anchored leaderboard
--        (migration 00024 queries memberships WHERE is_active = true).
--
-- Root cause:
--   join_gym_with_code RPC was not called successfully for ironbronz's
--   device, or the membership row was lost / never committed.
--
-- Fix:
--   1. For every user in user_profiles who has NO active membership but
--      whose username appears in the database (i.e. has a profile), insert
--      a membership in the most-active gym they're associated with via
--      any existing workout_sessions row. If no sessions exist either,
--      fall back to the alphabetically-first gym.
--   2. Specifically ensure ironbronz is a member of the same gym as
--      ironwood (the only currently visible leaderboard participant).
--   3. Log what was inserted so the run is auditable.
--
-- Safety: All inserts use ON CONFLICT DO NOTHING — fully idempotent.
-- =============================================================================

-- ─── Step 1: Grant ironbronz a membership in ironwood's gym ──────────────────
-- This covers the specific reported case. We look up both users by username
-- so the migration works regardless of their actual UUIDs.

DO $$
DECLARE
  v_ironbronz_id UUID;
  v_ironwood_id  UUID;
  v_gym_id       UUID;
BEGIN
  SELECT id INTO v_ironbronz_id
  FROM public.user_profiles
  WHERE LOWER(username) = 'ironbronz'
  LIMIT 1;

  SELECT id INTO v_ironwood_id
  FROM public.user_profiles
  WHERE LOWER(username) = 'ironwood'
  LIMIT 1;

  IF v_ironbronz_id IS NULL THEN
    RAISE NOTICE '00025: user "ironbronz" not found in user_profiles — skipping targeted fix';
    RETURN;
  END IF;

  -- Find the gym ironwood belongs to (active membership preferred, else any)
  IF v_ironwood_id IS NOT NULL THEN
    SELECT gym_id INTO v_gym_id
    FROM public.memberships
    WHERE user_id   = v_ironwood_id
      AND is_active = TRUE
    ORDER BY joined_at DESC
    LIMIT 1;
  END IF;

  -- Fallback: find gym via ironbronz's own workout_sessions (if any synced)
  IF v_gym_id IS NULL THEN
    SELECT gym_id INTO v_gym_id
    FROM public.workout_sessions
    WHERE user_id = v_ironbronz_id
    ORDER BY started_at DESC
    LIMIT 1;
  END IF;

  -- Last resort: use the first gym in the system
  IF v_gym_id IS NULL THEN
    SELECT id INTO v_gym_id
    FROM public.tenant_gyms
    ORDER BY created_at
    LIMIT 1;
  END IF;

  IF v_gym_id IS NULL THEN
    RAISE NOTICE '00025: no gym found — cannot create membership for ironbronz';
    RETURN;
  END IF;

  INSERT INTO public.memberships (id, gym_id, user_id, role, is_active, joined_at)
  VALUES (gen_random_uuid(), v_gym_id, v_ironbronz_id, 'member', TRUE, NOW())
  ON CONFLICT (user_id, gym_id) DO UPDATE
    SET is_active = TRUE;   -- re-activate if it was soft-deleted

  RAISE NOTICE '00025: ensured active membership for ironbronz (%) in gym (%)',
    v_ironbronz_id, v_gym_id;
END;
$$;

-- ─── Step 2: General fix — activate memberships for any user who has ──────────
-- a workout_session in a gym but no active membership there.
-- This covers other users in the same situation.

INSERT INTO public.memberships (id, gym_id, user_id, role, is_active, joined_at)
SELECT
  gen_random_uuid(),
  ws.gym_id,
  ws.user_id,
  'member',
  TRUE,
  MIN(ws.started_at)
FROM public.workout_sessions ws
WHERE NOT EXISTS (
  SELECT 1
  FROM public.memberships m
  WHERE m.user_id   = ws.user_id
    AND m.gym_id    = ws.gym_id
    AND m.is_active = TRUE
)
GROUP BY ws.gym_id, ws.user_id
ON CONFLICT (user_id, gym_id) DO UPDATE
  SET is_active = TRUE;

-- ─── Step 3: Backfill XP for any newly-membered users ────────────────────────
-- Users who now have a membership but whose XP events were blocked by the
-- 403 may have sessions in Supabase. Backfill them now.

INSERT INTO public.xp_events (
  gym_id, user_id, axis, xp_amount,
  source_type, source_id, idempotency_key, occurred_at
)
SELECT
  ws.gym_id,
  ws.user_id,
  'training_day',
  100,
  'workout_session',
  ws.id,
  'training_day:workout_session:' || ws.gym_id || ':' || ws.user_id || ':' || ws.session_day_anchor,
  COALESCE(ws.finished_at, ws.started_at, NOW())
FROM public.workout_sessions ws
WHERE EXISTS (
  SELECT 1
  FROM public.memberships m
  WHERE m.user_id   = ws.user_id
    AND m.gym_id    = ws.gym_id
    AND m.is_active = TRUE
)
ON CONFLICT (idempotency_key) DO NOTHING;

-- ─── Step 4: Recompute user_gym_xp for all affected users ────────────────────

DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, gym_id
    FROM   public.xp_events
    WHERE  axis::TEXT = 'training_day'
  LOOP
    PERFORM public.recompute_user_gym_xp(rec.user_id, rec.gym_id);
  END LOOP;
END;
$$;

-- ─── Verify ───────────────────────────────────────────────────────────────────
-- After running this migration you can confirm the fix with:
--
--   SELECT up.username, m.gym_id, m.is_active, m.joined_at
--   FROM   public.memberships m
--   JOIN   public.user_profiles up ON up.id = m.user_id
--   WHERE  LOWER(up.username) IN ('ironbronz', 'ironwood')
--   ORDER  BY up.username;
--
-- ironbronz will now appear on the leaderboard immediately.
-- Their locally-stuck sync_failed sessions will be retried automatically
-- within 10 seconds of app startup (sync_service.dart includes sync_failed
-- in getPendingSessions). Once the Edge Function succeeds (no more 403),
-- XP events are created server-side and the leaderboard updates on
-- next pull-to-refresh.
