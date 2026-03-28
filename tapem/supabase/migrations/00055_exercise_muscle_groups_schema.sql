-- =============================================================================
-- Tap'em — Exercise muscle group schema
--
-- Replaces the proportional weight model (muscle_group_weights) with a flat
-- primary/secondary role classification.
--
-- XP awards (enforced in edge functions and mirrored in XpRules.dart):
--   primary   → 10.0 XP per exercise per training day
--   secondary →  2.5 XP per exercise per training day
--
-- New tables:
--   exercise_muscle_groups             — for fixed-machine exercise templates
--   user_custom_exercise_muscle_groups — for user-created open-station exercises
--
-- Schema changes:
--   user_muscle_group_xp.total_xp     → NUMERIC(8,1)   (supports 2.5 XP steps)
--   xp_events.xp_amount               → NUMERIC(6,1)   (supports 2.5 XP values)
-- =============================================================================

-- ─── 1. New table: exercise_muscle_groups ────────────────────────────────────

CREATE TABLE public.exercise_muscle_groups (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_key TEXT NOT NULL,
  gym_id       UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  muscle_group TEXT NOT NULL,
  role         TEXT NOT NULL CHECK (role IN ('primary', 'secondary')),
  UNIQUE (exercise_key, gym_id, muscle_group),
  FOREIGN KEY (exercise_key, gym_id)
    REFERENCES public.exercise_templates(key, gym_id) ON DELETE CASCADE
);

CREATE INDEX idx_emg_key_gym ON public.exercise_muscle_groups(exercise_key, gym_id);

-- ─── 2. New table: user_custom_exercise_muscle_groups ─────────────────────────

CREATE TABLE public.user_custom_exercise_muscle_groups (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_custom_exercise_id UUID NOT NULL
    REFERENCES public.user_custom_exercises(id) ON DELETE CASCADE,
  user_id                 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  muscle_group            TEXT NOT NULL,
  role                    TEXT NOT NULL CHECK (role IN ('primary', 'secondary')),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_custom_exercise_id, muscle_group)
);

CREATE INDEX idx_ucemg_user_id ON public.user_custom_exercise_muscle_groups(user_id);
CREATE INDEX idx_ucemg_exercise_id
  ON public.user_custom_exercise_muscle_groups(user_custom_exercise_id);

-- ─── 3. Alter user_muscle_group_xp.total_xp to NUMERIC ───────────────────────
--
-- total_xp can be fractional (e.g. 12.5) because secondary muscle groups
-- award 2.5 XP each. NUMERIC(8,1) allows up to 9,999,999.9 XP.

ALTER TABLE public.user_muscle_group_xp
  ALTER COLUMN total_xp TYPE NUMERIC(8,1) USING total_xp::NUMERIC(8,1);

-- ─── 4. Alter xp_events.xp_amount to NUMERIC ─────────────────────────────────
--
-- muscle_group XP events use 10.0 or 2.5 — existing integer events cast safely.

ALTER TABLE public.xp_events
  ALTER COLUMN xp_amount TYPE NUMERIC(6,1) USING xp_amount::NUMERIC(6,1);

-- ─── 5. Migrate data from muscle_group_weights → exercise_muscle_groups ──────
--
-- Infers role from the old fractional weight:
--   weight > 0.5  → primary
--   weight ≤ 0.5  → secondary
--
-- This preserves the existing muscle-group structure for any gym that had
-- weights configured. The new flat XP amounts will be used from this point
-- forward by all edge functions.

INSERT INTO public.exercise_muscle_groups (id, exercise_key, gym_id, muscle_group, role)
SELECT
  gen_random_uuid(),
  exercise_key,
  gym_id,
  muscle_group,
  CASE WHEN weight > 0.5 THEN 'primary' ELSE 'secondary' END AS role
FROM public.muscle_group_weights
ON CONFLICT (exercise_key, gym_id, muscle_group) DO NOTHING;

-- ─── 6. Seed all standard exercise muscle groups ──────────────────────────────
--
-- Covers every exercise_template key present across all gym migrations.
-- Uses a key-based INSERT that works across all gym_ids automatically.
-- ON CONFLICT ensures idempotency and protects custom overrides.

DO $$
DECLARE
  seed RECORD;
BEGIN
  FOR seed IN
    SELECT
      et.key     AS exercise_key,
      et.gym_id  AS gym_id,
      s.muscle_group,
      s.role
    FROM public.exercise_templates et
    JOIN (VALUES
      -- ── Chest ──────────────────────────────────────────────────────────────
      ('bench_press',                'chest',          'primary'),
      ('bench_press',                'front_shoulder',  'secondary'),
      ('bench_press',                'triceps',         'secondary'),
      ('chest_press',                'chest',          'primary'),
      ('chest_press',                'front_shoulder',  'secondary'),
      ('chest_press',                'triceps',         'secondary'),
      ('chest_press_isolateral',     'chest',          'primary'),
      ('chest_press_isolateral',     'front_shoulder',  'secondary'),
      ('incline_press',              'chest',          'primary'),
      ('incline_press',              'front_shoulder',  'secondary'),
      ('incline_press',              'triceps',         'secondary'),
      ('incline_press_isolateral',   'chest',          'primary'),
      ('incline_press_isolateral',   'front_shoulder',  'secondary'),
      ('decline_press',              'chest',          'primary'),
      ('decline_press',              'triceps',         'secondary'),
      ('decline_press_isolateral',   'chest',          'primary'),
      ('decline_press_isolateral',   'triceps',         'secondary'),
      ('fly_press',                  'chest',          'primary'),
      ('fly_press',                  'front_shoulder',  'secondary'),
      ('chest_fly',                  'chest',          'primary'),
      ('chest_fly',                  'front_shoulder',  'secondary'),
      ('pec_fly',                    'chest',          'primary'),
      ('pectoral_fly',               'chest',          'primary'),
      ('pectoral_fly_rear_delt',     'chest',          'primary'),
      ('pectoral_fly_rear_delt',     'rear_shoulder',   'secondary'),
      ('pectoralis',                 'chest',          'primary'),
      ('narrow_press',               'chest',          'primary'),
      ('narrow_press',               'triceps',         'secondary'),
      ('plate_loaded_chest_press',   'chest',          'primary'),
      ('plate_loaded_chest_press',   'front_shoulder',  'secondary'),
      ('plate_loaded_press',         'chest',          'primary'),
      ('plate_loaded_press',         'front_shoulder',  'secondary'),
      ('wide_chest_press_isolateral','chest',          'primary'),
      ('wide_chest_press_isolateral','front_shoulder',  'secondary'),
      ('super_incline_isolateral',   'chest',          'primary'),
      ('super_incline_isolateral',   'front_shoulder',  'secondary'),

      -- ── Back (lats / upper_back) ────────────────────────────────────────────
      ('lat_pulldown',               'lats',            'primary'),
      ('lat_pulldown',               'biceps',          'secondary'),
      ('lat_pulldown',               'upper_back',      'secondary'),
      ('lat_pulldown_isolateral',    'lats',            'primary'),
      ('lat_pulldown_isolateral',    'biceps',          'secondary'),
      ('front_pulldown',             'lats',            'primary'),
      ('front_pulldown',             'biceps',          'secondary'),
      ('pullovers',                  'lats',            'primary'),
      ('pullovers',                  'chest',           'secondary'),
      ('row',                        'upper_back',      'primary'),
      ('row',                        'lats',            'secondary'),
      ('row',                        'biceps',          'secondary'),
      ('row_isolateral',             'upper_back',      'primary'),
      ('row_isolateral',             'biceps',          'secondary'),
      ('compound_row',               'upper_back',      'primary'),
      ('compound_row',               'lats',            'secondary'),
      ('compound_row',               'biceps',          'secondary'),
      ('high_row',                   'upper_back',      'primary'),
      ('high_row',                   'lats',            'secondary'),
      ('high_row',                   'biceps',          'secondary'),
      ('high_row_isolateral',        'upper_back',      'primary'),
      ('high_row_isolateral',        'biceps',          'secondary'),
      ('low_row',                    'upper_back',      'primary'),
      ('low_row',                    'lats',            'secondary'),
      ('wide_row',                   'upper_back',      'primary'),
      ('wide_row',                   'lats',            'secondary'),
      ('t_bar_row',                  'upper_back',      'primary'),
      ('t_bar_row',                  'lats',            'secondary'),
      ('t_bar_row',                  'biceps',          'secondary'),
      ('rhomboideus',                'upper_back',      'primary'),
      ('rhomboideus',                'rear_shoulder',   'secondary'),

      -- ── Lower back ──────────────────────────────────────────────────────────
      ('deadlift',                   'lower_back',      'primary'),
      ('deadlift',                   'glutes',          'primary'),
      ('deadlift',                   'hamstrings',      'secondary'),
      ('deadlift',                   'upper_back',      'secondary'),
      ('hyperextensions',            'lower_back',      'primary'),
      ('hyperextensions',            'glutes',          'secondary'),

      -- ── Shoulders ───────────────────────────────────────────────────────────
      ('shoulder_press',             'front_shoulder',  'primary'),
      ('shoulder_press',             'side_shoulder',   'secondary'),
      ('shoulder_press',             'triceps',         'secondary'),
      ('shoulder_press_isolateral',  'front_shoulder',  'primary'),
      ('shoulder_press_isolateral',  'side_shoulder',   'secondary'),
      ('shoulder_press_isolateral',  'triceps',         'secondary'),
      ('overhead_press',             'front_shoulder',  'primary'),
      ('overhead_press',             'side_shoulder',   'secondary'),
      ('overhead_press',             'triceps',         'secondary'),
      ('standing_press',             'front_shoulder',  'primary'),
      ('standing_press',             'side_shoulder',   'secondary'),
      ('vertical_press',             'front_shoulder',  'primary'),
      ('vertical_press',             'triceps',         'secondary'),
      ('shoulder_front_press',       'front_shoulder',  'primary'),
      ('shoulder_front_press',       'triceps',         'secondary'),
      ('lateral_raise',              'side_shoulder',   'primary'),
      ('lateral_raise_standing',     'side_shoulder',   'primary'),
      ('reverse_flys',               'rear_shoulder',   'primary'),
      ('reverse_flys',               'upper_back',      'secondary'),

      -- ── Biceps ──────────────────────────────────────────────────────────────
      ('bicep_curl',                 'biceps',          'primary'),
      ('bicep_curl',                 'forearms',        'secondary'),
      ('bicep_curl_overhead',        'biceps',          'primary'),
      ('bicep_curl_overhead',        'forearms',        'secondary'),
      ('preacher_curl',              'biceps',          'primary'),

      -- ── Triceps ─────────────────────────────────────────────────────────────
      ('tricep_extensions',          'triceps',         'primary'),
      ('tricep_extensions',          'forearms',        'secondary'),
      ('dips',                       'triceps',         'primary'),
      ('dips',                       'chest',           'secondary'),
      ('dips',                       'front_shoulder',  'secondary'),

      -- ── Core ────────────────────────────────────────────────────────────────
      ('crunches',                   'core',            'primary'),
      ('ground_base',                'core',            'primary'),
      ('ground_base',                'lower_back',      'secondary'),

      -- ── Glutes / Hip ────────────────────────────────────────────────────────
      ('hip_thrust',                 'glutes',          'primary'),
      ('hip_thrust',                 'hamstrings',      'secondary'),
      ('hip_abduction',              'glutes',          'primary'),
      ('hip_adduction',              'quads',           'primary'),

      -- ── Quads / Legs ────────────────────────────────────────────────────────
      ('leg_press',                  'quads',           'primary'),
      ('leg_press',                  'glutes',          'secondary'),
      ('leg_press',                  'hamstrings',      'secondary'),
      ('leg_press_vertical',         'quads',           'primary'),
      ('leg_press_vertical',         'glutes',          'secondary'),
      ('leg_extensions',             'quads',           'primary'),
      ('hack_squat',                 'quads',           'primary'),
      ('hack_squat',                 'glutes',          'secondary'),
      ('pendulum_squat',             'quads',           'primary'),
      ('pendulum_squat',             'glutes',          'secondary'),
      ('belt_squat',                 'quads',           'primary'),
      ('belt_squat',                 'glutes',          'secondary'),
      ('belt_squat',                 'hamstrings',      'secondary'),
      ('squats',                     'quads',           'primary'),
      ('squats',                     'glutes',          'secondary'),
      ('squats',                     'hamstrings',      'secondary'),
      ('super_squat',                'quads',           'primary'),
      ('super_squat',                'glutes',          'secondary'),

      -- ── Hamstrings ──────────────────────────────────────────────────────────
      ('leg_curl',                   'hamstrings',      'primary'),
      ('leg_curl',                   'glutes',          'secondary'),
      ('leg_curl_isolateral',        'hamstrings',      'primary'),
      ('seated_leg_curl',            'hamstrings',      'primary'),
      ('lying_leg_curl',             'hamstrings',      'primary'),

      -- ── Calves ──────────────────────────────────────────────────────────────
      ('calf_raise_donkey',          'calves',          'primary'),
      ('calf_raise_seated',          'calves',          'primary'),
      ('calf_raise_standing',        'calves',          'primary')

    ) AS s(exercise_key, muscle_group, role)
      ON et.key = s.exercise_key
  LOOP
    INSERT INTO public.exercise_muscle_groups (id, exercise_key, gym_id, muscle_group, role)
    VALUES (gen_random_uuid(), seed.exercise_key, seed.gym_id, seed.muscle_group, seed.role)
    ON CONFLICT (exercise_key, gym_id, muscle_group) DO NOTHING;
  END LOOP;
END;
$$;

-- ─── 7. Drop muscle_group_weights (superseded by exercise_muscle_groups) ──────

DROP TABLE IF EXISTS public.muscle_group_weights CASCADE;

-- ─── 8. Update recompute functions to handle NUMERIC total_xp ────────────────
--
-- recompute_user_gym_xp (from 00026) still casts muscle group XP to INTEGER,
-- which would truncate 2.5 XP awards. Replace the muscle_group section with a
-- NUMERIC(8,1) cast so fractional XP is preserved. The other two axes
-- (training_day, exercise_equipment) still use INTEGER — their XP amounts are
-- always whole numbers.

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
  -- ── Training-day XP ────────────────────────────────────────────────────────
  SELECT COALESCE(SUM(xp_amount), 0)
    INTO v_total_xp
    FROM public.xp_events
   WHERE user_id    = p_user_id
     AND gym_id     = p_gym_id
     AND axis::TEXT = 'training_day';

  v_level   := public.xp_to_level(v_total_xp);
  v_to_next := public.xp_needed_for_next_level(v_total_xp);

  INSERT INTO public.user_gym_xp (
    user_id, gym_id, total_xp, current_level, xp_to_next_level, updated_at
  )
  VALUES (p_user_id, p_gym_id, v_total_xp, v_level, v_to_next, NOW())
  ON CONFLICT (user_id, gym_id) DO UPDATE SET
    total_xp         = EXCLUDED.total_xp,
    current_level    = EXCLUDED.current_level,
    xp_to_next_level = EXCLUDED.xp_to_next_level,
    updated_at       = NOW();

  -- ── Per-exercise (equipment) XP ────────────────────────────────────────────
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

  -- ── Per-muscle-group XP (NUMERIC — supports 2.5 XP steps) ─────────────────
  INSERT INTO public.user_muscle_group_xp (
    user_id, gym_id, muscle_group, total_xp, current_level, updated_at
  )
  SELECT
    p_user_id,
    p_gym_id,
    muscle_group,
    SUM(xp_amount)::NUMERIC(8,1)                         AS total_xp,
    (FLOOR(SUM(xp_amount)) / 100 + 1)::SMALLINT          AS current_level,
    NOW()
  FROM public.xp_events
  WHERE user_id      = p_user_id
    AND gym_id       = p_gym_id
    AND axis::TEXT   = 'muscle_group'
    AND muscle_group IS NOT NULL
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
  'xp_events_recompute_on_insert trigger on every INSERT into xp_events. '
  'Muscle-group XP uses NUMERIC(8,1) to preserve 2.5 XP fractional awards.';

-- Standalone function called by the old process-xp-event edge function.
-- Delegates to recompute_user_gym_xp which now covers all three axes.
CREATE OR REPLACE FUNCTION public.recompute_user_muscle_group_xp(
  p_user_id UUID,
  p_gym_id  UUID
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM public.recompute_user_gym_xp(p_user_id, p_gym_id);
END;
$$;
