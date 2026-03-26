-- =============================================================================
-- Tap'em — Fix training_day ranking: correct XP divisor (100, not 25).
-- The finish-session edge function awards 100 XP per training day.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_gym_training_day_ranking(p_gym_id UUID)
RETURNS TABLE (
  rank           BIGINT,
  user_id        UUID,
  username       TEXT,
  total_xp       INTEGER,
  current_level  SMALLINT,
  training_days  INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    RANK() OVER (ORDER BY ugx.total_xp DESC)::BIGINT,
    ugx.user_id,
    up.username,
    ugx.total_xp,
    ugx.current_level,
    (ugx.total_xp / 100)::INTEGER AS training_days   -- 100 XP per training day
  FROM public.user_gym_xp ugx
  JOIN public.user_profiles up ON up.id = ugx.user_id
  WHERE ugx.gym_id         = p_gym_id
    AND up.privacy_level  != 'private'
    AND ugx.total_xp       > 0
  ORDER BY ugx.total_xp DESC
  LIMIT 100;
$$;

GRANT EXECUTE ON FUNCTION public.get_gym_training_day_ranking(UUID)
  TO authenticated;
