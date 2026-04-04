-- =============================================================================
-- Tap'em — 00071: Machine performance leaderboard (best-set e1RM)
--
-- Adds a dedicated, opt-in leaderboard that ranks athletes by their best set
-- (highest Epley e1RM) per fixed-machine canonical exercise.
--
-- Rules enforced by this migration:
--   1) Scope: fixed machines only (gym_equipment.equipment_type='fixed_machine').
--   2) Metric: highest single-set e1RM (Epley: weight * (1 + reps / 30)).
--   3) Explicit profile opt-in is required.
--   4) Opt-in requires sex selection (male/female) on user profile.
--   5) Leaderboards are separated by sex.
--   6) Non-opted-in users are excluded.
--   7) Existing XP leaderboards remain unchanged.
-- =============================================================================

-- ─── 1) Profile fields for explicit opt-in + sex ─────────────────────────────

DO $$
BEGIN
  CREATE TYPE public.machine_perf_sex AS ENUM ('male', 'female');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS machine_perf_opt_in BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS machine_perf_sex public.machine_perf_sex,
  ADD COLUMN IF NOT EXISTS machine_perf_opted_at TIMESTAMPTZ;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'user_profiles_machine_perf_opt_in_requires_sex'
      AND conrelid = 'public.user_profiles'::regclass
  ) THEN
    ALTER TABLE public.user_profiles
      ADD CONSTRAINT user_profiles_machine_perf_opt_in_requires_sex
      CHECK (
        machine_perf_opt_in = FALSE
        OR machine_perf_sex IS NOT NULL
      );
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_user_profiles_machine_perf_opt_in
  ON public.user_profiles (machine_perf_opt_in, machine_perf_sex, id)
  WHERE machine_perf_opt_in = TRUE;

COMMENT ON COLUMN public.user_profiles.machine_perf_opt_in IS
  'Explicit opt-in for machine-performance leaderboard visibility.';

COMMENT ON COLUMN public.user_profiles.machine_perf_sex IS
  'Required when machine_perf_opt_in=true. Used to segment leaderboard by sex.';

COMMENT ON COLUMN public.user_profiles.machine_perf_opted_at IS
  'Timestamp of latest opt-in enable action for machine-performance leaderboard.';

-- ─── 2) Materialized best-set table ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.user_machine_exercise_best (
  gym_id            UUID         NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  exercise_key      TEXT         NOT NULL CHECK (BTRIM(exercise_key) <> ''),
  user_id           UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  best_e1rm_kg      NUMERIC(8,3) NOT NULL CHECK (best_e1rm_kg > 0),
  best_weight_kg    NUMERIC(6,2) NOT NULL CHECK (best_weight_kg > 0),
  best_reps         SMALLINT     NOT NULL CHECK (best_reps >= 1 AND best_reps <= 500),
  best_set_entry_id UUID         NOT NULL REFERENCES public.set_entries(id) ON DELETE CASCADE,
  best_session_id   UUID         NOT NULL REFERENCES public.workout_sessions(id) ON DELETE CASCADE,
  achieved_at       TIMESTAMPTZ  NOT NULL,
  formula_version   SMALLINT     NOT NULL DEFAULT 1 CHECK (formula_version = 1),
  computed_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  PRIMARY KEY (gym_id, exercise_key, user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_machine_exercise_best_rank
  ON public.user_machine_exercise_best (
    gym_id,
    exercise_key,
    best_e1rm_kg DESC,
    best_weight_kg DESC,
    best_reps ASC,
    achieved_at ASC,
    user_id ASC
  );

CREATE INDEX IF NOT EXISTS idx_user_machine_exercise_best_user
  ON public.user_machine_exercise_best (user_id, gym_id);

COMMENT ON TABLE public.user_machine_exercise_best IS
  'Per user+gym+exercise canonical best strength set by e1RM (Epley), fixed machines only.';

ALTER TABLE public.user_machine_exercise_best ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_machine_exercise_best'
      AND policyname = 'user_machine_exercise_best_read_members'
  ) THEN
    CREATE POLICY "user_machine_exercise_best_read_members"
      ON public.user_machine_exercise_best
      FOR SELECT
      TO authenticated
      USING (public.has_active_membership(gym_id));
  END IF;
END
$$;

GRANT SELECT ON public.user_machine_exercise_best TO authenticated;
GRANT ALL ON public.user_machine_exercise_best TO service_role;

-- ─── 3) Recompute functions (deterministic and auditable) ─────────────────────

CREATE OR REPLACE FUNCTION public.recompute_machine_perf_best_for_exercise(
  p_gym_id       UUID,
  p_user_id      UUID,
  p_exercise_key TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_best RECORD;
BEGIN
  IF p_exercise_key IS NULL OR p_exercise_key = '' THEN
    RETURN;
  END IF;

  SELECT
    st.id                               AS set_entry_id,
    ws.id                               AS session_id,
    ws.finished_at                      AS achieved_at,
    st.weight_kg::NUMERIC(6,2)          AS weight_kg,
    st.reps::SMALLINT                   AS reps,
    (st.weight_kg::NUMERIC * (1 + st.reps::NUMERIC / 30.0)) AS e1rm_kg
  INTO v_best
  FROM public.set_entries st
  JOIN public.session_exercises se
    ON se.id = st.session_exercise_id
  JOIN public.workout_sessions ws
    ON ws.id = se.session_id
  JOIN public.gym_equipment ge
    ON ge.id = COALESCE(se.equipment_id, ws.equipment_id)
   AND ge.gym_id = p_gym_id
  WHERE ws.gym_id = p_gym_id
    AND ws.user_id = p_user_id
    AND ws.finished_at IS NOT NULL
    AND ge.equipment_type = 'fixed_machine'
    AND ge.canonical_exercise_key = p_exercise_key
    AND st.weight_kg IS NOT NULL
    AND st.weight_kg > 0
    AND st.reps IS NOT NULL
    AND st.reps BETWEEN 1 AND 15
  ORDER BY
    (st.weight_kg::NUMERIC * (1 + st.reps::NUMERIC / 30.0)) DESC,
    st.weight_kg DESC,
    st.reps ASC,
    ws.finished_at ASC,
    st.id ASC
  LIMIT 1;

  IF NOT FOUND THEN
    DELETE FROM public.user_machine_exercise_best
    WHERE gym_id = p_gym_id
      AND user_id = p_user_id
      AND exercise_key = p_exercise_key;
    RETURN;
  END IF;

  INSERT INTO public.user_machine_exercise_best (
    gym_id,
    exercise_key,
    user_id,
    best_e1rm_kg,
    best_weight_kg,
    best_reps,
    best_set_entry_id,
    best_session_id,
    achieved_at,
    formula_version,
    computed_at
  )
  VALUES (
    p_gym_id,
    p_exercise_key,
    p_user_id,
    ROUND(v_best.e1rm_kg::NUMERIC, 3),
    v_best.weight_kg,
    v_best.reps,
    v_best.set_entry_id,
    v_best.session_id,
    v_best.achieved_at,
    1,
    NOW()
  )
  ON CONFLICT (gym_id, exercise_key, user_id) DO UPDATE
  SET
    best_e1rm_kg      = EXCLUDED.best_e1rm_kg,
    best_weight_kg    = EXCLUDED.best_weight_kg,
    best_reps         = EXCLUDED.best_reps,
    best_set_entry_id = EXCLUDED.best_set_entry_id,
    best_session_id   = EXCLUDED.best_session_id,
    achieved_at       = EXCLUDED.achieved_at,
    formula_version   = EXCLUDED.formula_version,
    computed_at       = NOW();
END;
$$;

COMMENT ON FUNCTION public.recompute_machine_perf_best_for_exercise(UUID, UUID, TEXT) IS
  'Recomputes one user+gym+exercise best-set e1RM row from raw set data. Fixed machines only.';

CREATE OR REPLACE FUNCTION public.recompute_machine_performance_for_session(
  p_session_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_gym_id  UUID;
  v_exercise_key TEXT;
  v_count INTEGER := 0;
BEGIN
  SELECT ws.user_id, ws.gym_id
  INTO v_user_id, v_gym_id
  FROM public.workout_sessions ws
  WHERE ws.id = p_session_id;

  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  FOR v_exercise_key IN
    SELECT DISTINCT ge.canonical_exercise_key
    FROM public.session_exercises se
    JOIN public.workout_sessions ws
      ON ws.id = se.session_id
    JOIN public.gym_equipment ge
      ON ge.id = COALESCE(se.equipment_id, ws.equipment_id)
     AND ge.gym_id = ws.gym_id
    WHERE se.session_id = p_session_id
      AND ws.finished_at IS NOT NULL
      AND ge.equipment_type = 'fixed_machine'
      AND ge.canonical_exercise_key IS NOT NULL
  LOOP
    PERFORM public.recompute_machine_perf_best_for_exercise(
      v_gym_id,
      v_user_id,
      v_exercise_key
    );
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.recompute_machine_performance_for_session(UUID) IS
  'Recomputes machine-performance best-set rows for all fixed-machine exercises touched by the session.';

GRANT EXECUTE ON FUNCTION public.recompute_machine_perf_best_for_exercise(UUID, UUID, TEXT)
  TO service_role;

GRANT EXECUTE ON FUNCTION public.recompute_machine_performance_for_session(UUID)
  TO authenticated, service_role;

-- Historical backfill (set-based): recompute all user+gym+exercise best rows
-- in one deterministic pass (far more efficient than per-session replay).
WITH ranked_sets AS (
  SELECT
    ws.gym_id,
    ge.canonical_exercise_key            AS exercise_key,
    ws.user_id,
    st.id                                AS set_entry_id,
    ws.id                                AS session_id,
    ws.finished_at                       AS achieved_at,
    st.weight_kg::NUMERIC(6,2)           AS weight_kg,
    st.reps::SMALLINT                    AS reps,
    (st.weight_kg::NUMERIC * (1 + st.reps::NUMERIC / 30.0)) AS e1rm_kg,
    ROW_NUMBER() OVER (
      PARTITION BY ws.gym_id, ge.canonical_exercise_key, ws.user_id
      ORDER BY
        (st.weight_kg::NUMERIC * (1 + st.reps::NUMERIC / 30.0)) DESC,
        st.weight_kg DESC,
        st.reps ASC,
        ws.finished_at ASC,
        st.id ASC
    ) AS rn
  FROM public.set_entries st
  JOIN public.session_exercises se
    ON se.id = st.session_exercise_id
  JOIN public.workout_sessions ws
    ON ws.id = se.session_id
  JOIN public.gym_equipment ge
    ON ge.id = COALESCE(se.equipment_id, ws.equipment_id)
   AND ge.gym_id = ws.gym_id
  WHERE ws.finished_at IS NOT NULL
    AND ge.equipment_type = 'fixed_machine'
    AND ge.canonical_exercise_key IS NOT NULL
    AND st.weight_kg IS NOT NULL
    AND st.weight_kg > 0
    AND st.reps IS NOT NULL
    AND st.reps BETWEEN 1 AND 15
)
INSERT INTO public.user_machine_exercise_best (
  gym_id,
  exercise_key,
  user_id,
  best_e1rm_kg,
  best_weight_kg,
  best_reps,
  best_set_entry_id,
  best_session_id,
  achieved_at,
  formula_version,
  computed_at
)
SELECT
  rs.gym_id,
  rs.exercise_key,
  rs.user_id,
  ROUND(rs.e1rm_kg::NUMERIC, 3) AS best_e1rm_kg,
  rs.weight_kg,
  rs.reps,
  rs.set_entry_id,
  rs.session_id,
  rs.achieved_at,
  1 AS formula_version,
  NOW() AS computed_at
FROM ranked_sets rs
WHERE rs.rn = 1
ON CONFLICT (gym_id, exercise_key, user_id) DO UPDATE
SET
  best_e1rm_kg      = EXCLUDED.best_e1rm_kg,
  best_weight_kg    = EXCLUDED.best_weight_kg,
  best_reps         = EXCLUDED.best_reps,
  best_set_entry_id = EXCLUDED.best_set_entry_id,
  best_session_id   = EXCLUDED.best_session_id,
  achieved_at       = EXCLUDED.achieved_at,
  formula_version   = EXCLUDED.formula_version,
  computed_at       = NOW();

-- ─── 4) Read RPCs (overview + ranked leaderboard) ────────────────────────────

CREATE OR REPLACE FUNCTION public.get_machine_performance_exercises(
  p_gym_id UUID,
  p_sex    public.machine_perf_sex
)
RETURNS TABLE (
  exercise_key      TEXT,
  exercise_name     TEXT,
  participant_count INTEGER,
  top_e1rm_kg       NUMERIC(8,3),
  top_user_id       UUID,
  top_username      TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
  authz AS (
    SELECT EXISTS (
      SELECT 1
      FROM public.memberships m
      WHERE m.user_id = auth.uid()
        AND m.gym_id = p_gym_id
        AND m.is_active = TRUE
    ) AS ok
  ),
  gym_exercises AS (
    SELECT DISTINCT ge.canonical_exercise_key AS exercise_key
    FROM public.gym_equipment ge
    WHERE ge.gym_id = p_gym_id
      AND ge.is_active = TRUE
      AND ge.equipment_type = 'fixed_machine'
      AND ge.canonical_exercise_key IS NOT NULL
  ),
  active_members AS (
    SELECT m.user_id
    FROM public.memberships m
    WHERE m.gym_id = p_gym_id
      AND m.is_active = TRUE
  ),
  eligible_users AS (
    SELECT up.id, up.username
    FROM public.user_profiles up
    JOIN active_members am
      ON am.user_id = up.id
    WHERE up.machine_perf_opt_in = TRUE
      AND up.machine_perf_sex = p_sex
      AND up.username IS NOT NULL
  ),
  ranked AS (
    SELECT
      ub.exercise_key,
      ub.user_id,
      ub.best_e1rm_kg,
      RANK() OVER (
        PARTITION BY ub.exercise_key
        ORDER BY
          ub.best_e1rm_kg DESC,
          ub.best_weight_kg DESC,
          ub.best_reps ASC,
          ub.achieved_at ASC,
          ub.user_id ASC
      ) AS rn,
      COUNT(*) OVER (PARTITION BY ub.exercise_key)::INTEGER AS participants
    FROM public.user_machine_exercise_best ub
    JOIN eligible_users eu
      ON eu.id = ub.user_id
    WHERE ub.gym_id = p_gym_id
  )
  SELECT
    gx.exercise_key,
    COALESCE(et.name, gx.exercise_key) AS exercise_name,
    COALESCE(r.participants, 0)        AS participant_count,
    r.best_e1rm_kg                     AS top_e1rm_kg,
    r.user_id                          AS top_user_id,
    eu.username                        AS top_username
  FROM gym_exercises gx
  LEFT JOIN ranked r
    ON r.exercise_key = gx.exercise_key
   AND r.rn = 1
  LEFT JOIN eligible_users eu
    ON eu.id = r.user_id
  LEFT JOIN public.exercise_templates et
    ON et.gym_id = p_gym_id
   AND et.key = gx.exercise_key
  WHERE (SELECT ok FROM authz)
  ORDER BY
    CASE WHEN r.best_e1rm_kg IS NULL THEN 1 ELSE 0 END,
    r.best_e1rm_kg DESC NULLS LAST,
    COALESCE(et.name, gx.exercise_key) ASC
  LIMIT 300;
$$;

COMMENT ON FUNCTION public.get_machine_performance_exercises(UUID, public.machine_perf_sex) IS
  'Returns fixed-machine exercise list for a gym with top score preview, segmented by sex and explicit opt-in.';

CREATE OR REPLACE FUNCTION public.get_machine_performance_leaderboard(
  p_gym_id       UUID,
  p_exercise_key TEXT,
  p_sex          public.machine_perf_sex,
  p_limit        INTEGER DEFAULT 100,
  p_offset       INTEGER DEFAULT 0
)
RETURNS TABLE (
  rank           BIGINT,
  user_id        UUID,
  username       TEXT,
  avatar_url     TEXT,
  best_e1rm_kg   NUMERIC(8,3),
  best_weight_kg NUMERIC(6,2),
  best_reps      SMALLINT,
  achieved_at    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
  authz AS (
    SELECT EXISTS (
      SELECT 1
      FROM public.memberships m
      WHERE m.user_id = auth.uid()
        AND m.gym_id = p_gym_id
        AND m.is_active = TRUE
    ) AS ok
  ),
  active_members AS (
    SELECT m.user_id
    FROM public.memberships m
    WHERE m.gym_id = p_gym_id
      AND m.is_active = TRUE
  ),
  ranked AS (
    SELECT
      RANK() OVER (
        ORDER BY
          ub.best_e1rm_kg DESC,
          ub.best_weight_kg DESC,
          ub.best_reps ASC,
          ub.achieved_at ASC,
          ub.user_id ASC
      )::BIGINT AS rank,
      ub.user_id,
      up.username,
      up.avatar_url,
      ub.best_e1rm_kg,
      ub.best_weight_kg,
      ub.best_reps,
      ub.achieved_at
    FROM public.user_machine_exercise_best ub
    JOIN active_members am
      ON am.user_id = ub.user_id
    JOIN public.user_profiles up
      ON up.id = ub.user_id
     AND up.machine_perf_opt_in = TRUE
     AND up.machine_perf_sex = p_sex
     AND up.username IS NOT NULL
    WHERE ub.gym_id = p_gym_id
      AND ub.exercise_key = p_exercise_key
  )
  SELECT
    r.rank,
    r.user_id,
    r.username,
    r.avatar_url,
    r.best_e1rm_kg,
    r.best_weight_kg,
    r.best_reps,
    r.achieved_at
  FROM ranked r
  WHERE (SELECT ok FROM authz)
  ORDER BY r.rank, r.username
  LIMIT LEAST(GREATEST(p_limit, 1), 200)
  OFFSET GREATEST(p_offset, 0);
$$;

COMMENT ON FUNCTION public.get_machine_performance_leaderboard(UUID, TEXT, public.machine_perf_sex, INTEGER, INTEGER) IS
  'Ranked machine-performance leaderboard for one fixed-machine exercise in one gym, segmented by sex and explicit opt-in.';

GRANT EXECUTE ON FUNCTION public.get_machine_performance_exercises(UUID, public.machine_perf_sex)
  TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_machine_performance_leaderboard(UUID, TEXT, public.machine_perf_sex, INTEGER, INTEGER)
  TO authenticated;
