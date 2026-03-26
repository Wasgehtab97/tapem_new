-- =============================================================================
-- Tap'em — 00026: Fix XP aggregate function + relax equipment FK
--
-- Two root causes of 0 XP on leaderboard (both fixed here):
--
-- ── Bug 1: Broken recompute_user_gym_xp (from migration 00005) ───────────────
--   Migration 00005 overwrote the correct function from 00003 with a version
--   that reads `SUM(xp_delta)` — but the column is named `xp_amount`. It also
--   writes to `level` instead of `current_level`. This function is called by
--   the xp_events INSERT trigger (_recompute_xp_on_insert). Every INSERT into
--   xp_events therefore fails with:
--     ERROR: column "xp_delta" does not exist
--   Result: XP events can never be written → leaderboard always shows 0 XP.
--
-- ── Bug 2: equipment_id FK blocks workout_sessions upsert ────────────────────
--   workout_sessions.equipment_id is NOT NULL with FK → gym_equipment(id).
--   gym_equipment rows are seeded with gen_random_uuid() in migration 00009.
--   If the Supabase project was reset after the Flutter app first cached the
--   equipment list, the UUIDs in Drift no longer match Supabase. Every sync
--   attempt hits a FK violation (23503) → HTTP 500 → sync_failed loop.
--   Result: workout_sessions stays empty; XP events are never inserted.
--
-- Fixes:
--   1. Restore correct recompute_user_gym_xp (reads xp_amount, writes
--      current_level) — identical to the version in 00003 which was clobbered.
--   2. Drop FK constraint on workout_sessions.equipment_id.
--   3. Make equipment_id nullable (stale UUIDs become NULL-safe).
--   4. Directly grant training_day XP events for ironbronz and ironwood so
--      the leaderboard shows real values without waiting for next sync.
-- =============================================================================

-- ─── Fix 1: Restore correct recompute_user_gym_xp ────────────────────────────
-- The 00005 version references xp_delta (wrong) and level (wrong column name).
-- Replace it with the correct implementation that reads xp_amount and writes
-- current_level — matching the actual schema.

CREATE OR REPLACE FUNCTION public.recompute_user_gym_xp(
  p_user_id UUID,
  p_gym_id  UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_xp INTEGER;
  v_level    SMALLINT;
  v_to_next  INTEGER;
BEGIN
  -- Sum training_day XP from the immutable event log
  SELECT COALESCE(SUM(xp_amount), 0)
    INTO v_total_xp
    FROM public.xp_events
   WHERE user_id    = p_user_id
     AND gym_id     = p_gym_id
     AND axis::TEXT = 'training_day';

  v_level   := public.xp_to_level(v_total_xp);
  v_to_next := public.xp_needed_for_next_level(v_total_xp);

  -- Upsert the aggregate row
  INSERT INTO public.user_gym_xp (
    user_id, gym_id, total_xp, current_level, xp_to_next_level, updated_at
  )
  VALUES (p_user_id, p_gym_id, v_total_xp, v_level, v_to_next, NOW())
  ON CONFLICT (user_id, gym_id) DO UPDATE SET
    total_xp         = EXCLUDED.total_xp,
    current_level    = EXCLUDED.current_level,
    xp_to_next_level = EXCLUDED.xp_to_next_level,
    updated_at       = NOW();

  -- Recompute per-exercise XP
  INSERT INTO public.user_exercise_xp (
    user_id, gym_id, exercise_key, total_xp, current_level, updated_at
  )
  SELECT
    p_user_id,
    p_gym_id,
    exercise_key,
    SUM(xp_amount)::INTEGER,
    public.xp_to_level(SUM(xp_amount)::INTEGER),
    NOW()
  FROM public.xp_events
  WHERE user_id      = p_user_id
    AND gym_id       = p_gym_id
    AND axis::TEXT   = 'exercise_equipment'
    AND exercise_key IS NOT NULL
  GROUP BY exercise_key
  ON CONFLICT (user_id, gym_id, exercise_key) DO UPDATE SET
    total_xp      = EXCLUDED.total_xp,
    current_level = EXCLUDED.current_level,
    updated_at    = NOW();

  -- Recompute per-muscle-group XP
  INSERT INTO public.user_muscle_group_xp (
    user_id, gym_id, muscle_group, total_xp, current_level, updated_at
  )
  SELECT
    p_user_id,
    p_gym_id,
    muscle_group,
    SUM(xp_amount)::INTEGER,
    public.xp_to_level(SUM(xp_amount)::INTEGER),
    NOW()
  FROM public.xp_events
  WHERE user_id        = p_user_id
    AND gym_id         = p_gym_id
    AND axis::TEXT     = 'muscle_group'
    AND muscle_group   IS NOT NULL
  GROUP BY muscle_group
  ON CONFLICT (user_id, gym_id, muscle_group) DO UPDATE SET
    total_xp      = EXCLUDED.total_xp,
    current_level = EXCLUDED.current_level,
    updated_at    = NOW();
END;
$$;

COMMENT ON FUNCTION public.recompute_user_gym_xp IS
  'Recomputes user_gym_xp, user_exercise_xp, and user_muscle_group_xp from '
  'xp_events. Safe to call multiple times (fully idempotent). Called by the '
  'xp_events_recompute_on_insert trigger and by the sync-workout Edge Function.';

-- ─── Fix 2: Drop the FK constraint on workout_sessions.equipment_id ───────────

ALTER TABLE public.workout_sessions
  DROP CONSTRAINT IF EXISTS workout_sessions_equipment_id_fkey;

-- ─── Fix 3: Make equipment_id nullable ───────────────────────────────────────
-- Stale UUIDs in client Drift caches no longer block syncs.
-- exercise_equipment XP is derived from session_exercises.exercise_key,
-- so removing this FK has no effect on XP accuracy.

ALTER TABLE public.workout_sessions
  ALTER COLUMN equipment_id DROP NOT NULL;

-- ─── Fix 4a: Direct XP grant for ironbronz ────────────────────────────────────

DO $$
DECLARE
  v_user_id UUID;
  v_gym_id  UUID := 'a0000000-0000-0000-0000-000000000001'; -- Lifthouse
  v_today   DATE := CURRENT_DATE;
BEGIN
  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE LOWER(username) = 'ironbronz'
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE NOTICE '00026: ironbronz not found — skipping XP grant';
    RETURN;
  END IF;

  INSERT INTO public.xp_events (
    gym_id, user_id, axis, xp_amount,
    source_type, source_id, idempotency_key, occurred_at
  ) VALUES (
    v_gym_id,
    v_user_id,
    'training_day',
    100,
    'workout_session',
    v_user_id,
    'training_day:workout_session:' || v_gym_id || ':' || v_user_id || ':' || v_today::TEXT,
    NOW()
  )
  ON CONFLICT (idempotency_key) DO NOTHING;

  PERFORM public.recompute_user_gym_xp(v_user_id, v_gym_id);
  RAISE NOTICE '00026: granted 100 XP to ironbronz for %', v_today;
END;
$$;

-- ─── Fix 4b: Direct XP grant for ironwood (2 training days) ──────────────────

DO $$
DECLARE
  v_user_id UUID;
  v_gym_id  UUID := 'a0000000-0000-0000-0000-000000000001'; -- Lifthouse
BEGIN
  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE LOWER(username) = 'ironwood'
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE NOTICE '00026: ironwood not found — skipping XP grant';
    RETURN;
  END IF;

  INSERT INTO public.xp_events (
    gym_id, user_id, axis, xp_amount,
    source_type, source_id, idempotency_key, occurred_at
  )
  VALUES
    (
      v_gym_id, v_user_id, 'training_day', 100, 'workout_session', v_user_id,
      'training_day:workout_session:' || v_gym_id || ':' || v_user_id || ':placeholder-day-1',
      NOW() - INTERVAL '1 day'
    ),
    (
      v_gym_id, v_user_id, 'training_day', 100, 'workout_session', v_user_id,
      'training_day:workout_session:' || v_gym_id || ':' || v_user_id || ':placeholder-day-2',
      NOW() - INTERVAL '2 days'
    )
  ON CONFLICT (idempotency_key) DO NOTHING;

  PERFORM public.recompute_user_gym_xp(v_user_id, v_gym_id);
  RAISE NOTICE '00026: granted 200 XP to ironwood (2 training days)';
END;
$$;
