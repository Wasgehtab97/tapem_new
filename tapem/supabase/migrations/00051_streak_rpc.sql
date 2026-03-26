-- ─────────────────────────────────────────────────────────────────────────────
-- Migration 00051 — server-side streak computation
--
-- Introduces get_user_streak(p_user_id), a SECURITY DEFINER function that
-- computes the current and longest training streak for any given user.
--
-- Streak rule (matches StreakCalculator in the Flutter app):
--   • Two consecutive training days are "linked" when the gap between them
--     is ≤ 7 calendar days.
--   • The current streak is the length of the chain ending at the most recent
--     training day, provided that day is itself within 7 days of TODAY.
--   • Longest streak is the all-time maximum chain length.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_user_streak(p_user_id UUID)
RETURNS TABLE(
  current_streak       INT,
  longest_streak       INT,
  grace_days_remaining INT,
  last_training_date   DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  k_grace   CONSTANT INT  := 7;
  v_today   DATE           := CURRENT_DATE;
  v_dates   DATE[];
  v_n       INT;
  v_last    DATE;
  v_since   INT;
  v_cur     INT;
  v_longest INT;
  v_run     INT;
  i         INT;
BEGIN
  -- ── Collect all unique, finished training days (cross-gym, all time) ────
  SELECT ARRAY_AGG(d ORDER BY d DESC)
  INTO v_dates
  FROM (
    SELECT DISTINCT session_day_anchor AS d
    FROM   public.workout_sessions
    WHERE  user_id     = p_user_id
      AND  finished_at IS NOT NULL
  ) sub;

  -- No finished sessions at all.
  IF v_dates IS NULL THEN
    RETURN QUERY SELECT 0::INT, 0::INT, 0::INT, NULL::DATE;
    RETURN;
  END IF;

  v_n     := array_length(v_dates, 1);
  v_last  := v_dates[1];
  v_since := v_today - v_last;   -- days since last training

  -- ── Current streak ──────────────────────────────────────────────────────
  IF v_since > k_grace THEN
    -- Grace window expired; chain is dead.
    v_cur := 0;
  ELSE
    v_cur := 1;
    FOR i IN 1 .. v_n - 1 LOOP
      IF (v_dates[i] - v_dates[i + 1]) <= k_grace THEN
        v_cur := v_cur + 1;
      ELSE
        EXIT;
      END IF;
    END LOOP;
  END IF;

  -- ── Longest streak (full history scan) ─────────────────────────────────
  v_longest := 1;
  v_run     := 1;
  FOR i IN 1 .. v_n - 1 LOOP
    IF (v_dates[i] - v_dates[i + 1]) <= k_grace THEN
      v_run     := v_run + 1;
      v_longest := GREATEST(v_longest, v_run);
    ELSE
      v_run := 1;
    END IF;
  END LOOP;

  -- ── Return ──────────────────────────────────────────────────────────────
  RETURN QUERY
    SELECT
      v_cur,
      v_longest,
      GREATEST(0, k_grace - v_since),
      v_last;
END;
$$;

-- Grant execution rights.
GRANT EXECUTE ON FUNCTION public.get_user_streak(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_streak(UUID) TO service_role;
