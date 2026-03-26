-- =============================================================================
-- Tap'em — XP Recomputation Functions
-- Called from Edge Function (service role) after xp_events insert.
-- =============================================================================

-- Level thresholds: each level requires 500 * level XP from the previous level.
-- E.g. level 1 → 2 requires 500 XP, level 2 → 3 requires 1000 XP, etc.
CREATE OR REPLACE FUNCTION public.xp_to_level(p_total_xp INTEGER)
RETURNS SMALLINT LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
  v_level SMALLINT := 1;
  v_threshold INTEGER := 0;
  v_increment INTEGER := 500;
BEGIN
  LOOP
    v_threshold := v_threshold + (v_increment * v_level);
    IF p_total_xp < v_threshold THEN
      RETURN v_level;
    END IF;
    v_level := v_level + 1;
    IF v_level > 100 THEN -- safety cap
      RETURN 100;
    END IF;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.xp_needed_for_next_level(p_total_xp INTEGER)
RETURNS INTEGER LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
  v_level SMALLINT := public.xp_to_level(p_total_xp);
  v_current_threshold INTEGER := 0;
  v_next_threshold INTEGER := 0;
  v_i INTEGER;
BEGIN
  FOR v_i IN 1..v_level LOOP
    v_current_threshold := v_current_threshold + (500 * v_i);
  END LOOP;
  v_next_threshold := v_current_threshold + (500 * (v_level + 1));
  RETURN v_next_threshold - p_total_xp;
END;
$$;

-- ─── Recompute user_gym_xp from xp_events ─────────────────────────────────────

CREATE OR REPLACE FUNCTION public.recompute_user_gym_xp(
  p_user_id UUID,
  p_gym_id  UUID
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_total_xp INTEGER;
  v_level SMALLINT;
  v_to_next INTEGER;
BEGIN
  -- Aggregate training_day XP (axis = training_day)
  SELECT COALESCE(SUM(xp_amount), 0)
  INTO v_total_xp
  FROM public.xp_events
  WHERE user_id = p_user_id AND gym_id = p_gym_id AND axis = 'training_day';

  v_level := public.xp_to_level(v_total_xp);
  v_to_next := public.xp_needed_for_next_level(v_total_xp);

  INSERT INTO public.user_gym_xp (user_id, gym_id, total_xp, current_level, xp_to_next_level, updated_at)
  VALUES (p_user_id, p_gym_id, v_total_xp, v_level, v_to_next, NOW())
  ON CONFLICT (user_id, gym_id) DO UPDATE SET
    total_xp = EXCLUDED.total_xp,
    current_level = EXCLUDED.current_level,
    xp_to_next_level = EXCLUDED.xp_to_next_level,
    updated_at = NOW();

  -- Recompute per-exercise XP
  INSERT INTO public.user_exercise_xp (user_id, gym_id, exercise_key, total_xp, current_level, updated_at)
  SELECT
    p_user_id,
    p_gym_id,
    exercise_key,
    SUM(xp_amount),
    public.xp_to_level(SUM(xp_amount)::INTEGER),
    NOW()
  FROM public.xp_events
  WHERE user_id = p_user_id
    AND gym_id = p_gym_id
    AND axis = 'exercise_equipment'
    AND exercise_key IS NOT NULL
  GROUP BY exercise_key
  ON CONFLICT (user_id, gym_id, exercise_key) DO UPDATE SET
    total_xp = EXCLUDED.total_xp,
    current_level = EXCLUDED.current_level,
    updated_at = NOW();

  -- Recompute per-muscle-group XP
  INSERT INTO public.user_muscle_group_xp (user_id, gym_id, muscle_group, total_xp, current_level, updated_at)
  SELECT
    p_user_id,
    p_gym_id,
    muscle_group,
    SUM(xp_amount),
    public.xp_to_level(SUM(xp_amount)::INTEGER),
    NOW()
  FROM public.xp_events
  WHERE user_id = p_user_id
    AND gym_id = p_gym_id
    AND axis = 'muscle_group'
    AND muscle_group IS NOT NULL
  GROUP BY muscle_group
  ON CONFLICT (user_id, gym_id, muscle_group) DO UPDATE SET
    total_xp = EXCLUDED.total_xp,
    current_level = EXCLUDED.current_level,
    updated_at = NOW();
END;
$$;
