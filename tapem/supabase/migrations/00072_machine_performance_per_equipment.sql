-- =============================================================================
-- Tap'em — 00072: Machine performance leaderboard per equipment piece
--
-- Why:
--   00071 grouped by canonical exercise key. This collapsed multiple machines
--   (e.g. multiple bench/incline press variants) into one board.
--
-- Goal:
--   Keep sex-separated + opt-in rules, but rank per fixed machine equipment_id.
-- =============================================================================

-- ─── 1) Per-equipment best-set materialized table ────────────────────────────

CREATE TABLE IF NOT EXISTS public.user_machine_equipment_best (
  gym_id            UUID         NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  equipment_id      UUID         NOT NULL REFERENCES public.gym_equipment(id) ON DELETE CASCADE,
  user_id           UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  best_e1rm_kg      NUMERIC(8,3) NOT NULL CHECK (best_e1rm_kg > 0),
  best_weight_kg    NUMERIC(6,2) NOT NULL CHECK (best_weight_kg > 0),
  best_reps         SMALLINT     NOT NULL CHECK (best_reps >= 1 AND best_reps <= 500),
  best_set_entry_id UUID         NOT NULL REFERENCES public.set_entries(id) ON DELETE CASCADE,
  best_session_id   UUID         NOT NULL REFERENCES public.workout_sessions(id) ON DELETE CASCADE,
  achieved_at       TIMESTAMPTZ  NOT NULL,
  formula_version   SMALLINT     NOT NULL DEFAULT 1 CHECK (formula_version = 1),
  computed_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  PRIMARY KEY (gym_id, equipment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_machine_equipment_best_rank
  ON public.user_machine_equipment_best (
    gym_id,
    equipment_id,
    best_e1rm_kg DESC,
    best_weight_kg DESC,
    best_reps ASC,
    achieved_at ASC,
    user_id ASC
  );

CREATE INDEX IF NOT EXISTS idx_user_machine_equipment_best_user
  ON public.user_machine_equipment_best (user_id, gym_id);

CREATE INDEX IF NOT EXISTS idx_user_machine_equipment_best_session
  ON public.user_machine_equipment_best (best_session_id, user_id, gym_id);

COMMENT ON TABLE public.user_machine_equipment_best IS
  'Per user+gym+equipment best strength set by e1RM (Epley), fixed machines only.';

ALTER TABLE public.user_machine_equipment_best ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_machine_equipment_best'
      AND policyname = 'user_machine_equipment_best_read_members'
  ) THEN
    CREATE POLICY "user_machine_equipment_best_read_members"
      ON public.user_machine_equipment_best
      FOR SELECT
      TO authenticated
      USING (public.has_active_membership(gym_id));
  END IF;
END
$$;

GRANT SELECT ON public.user_machine_equipment_best TO authenticated;
GRANT ALL ON public.user_machine_equipment_best TO service_role;

-- ─── 2) Recompute functions (per equipment piece) ───────────────────────────

CREATE OR REPLACE FUNCTION public.recompute_machine_perf_best_for_equipment(
  p_gym_id       UUID,
  p_user_id      UUID,
  p_equipment_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_best RECORD;
BEGIN
  IF p_equipment_id IS NULL THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.gym_equipment ge
    WHERE ge.id = p_equipment_id
      AND ge.gym_id = p_gym_id
      AND ge.equipment_type = 'fixed_machine'
  ) THEN
    DELETE FROM public.user_machine_equipment_best
    WHERE gym_id = p_gym_id
      AND user_id = p_user_id
      AND equipment_id = p_equipment_id;
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
    AND ge.id = p_equipment_id
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
    DELETE FROM public.user_machine_equipment_best
    WHERE gym_id = p_gym_id
      AND user_id = p_user_id
      AND equipment_id = p_equipment_id;
    RETURN;
  END IF;

  INSERT INTO public.user_machine_equipment_best (
    gym_id,
    equipment_id,
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
    p_equipment_id,
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
  ON CONFLICT (gym_id, equipment_id, user_id) DO UPDATE
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

COMMENT ON FUNCTION public.recompute_machine_perf_best_for_equipment(UUID, UUID, UUID) IS
  'Recomputes one user+gym+equipment best-set e1RM row from raw set data. Fixed machines only.';

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
  v_equipment_id UUID;
  v_count INTEGER := 0;
BEGIN
  SELECT ws.user_id, ws.gym_id
  INTO v_user_id, v_gym_id
  FROM public.workout_sessions ws
  WHERE ws.id = p_session_id;

  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  FOR v_equipment_id IN
    SELECT DISTINCT x.equipment_id
    FROM (
      -- Equipment currently referenced by this session.
      SELECT ge.id AS equipment_id
      FROM public.session_exercises se
      JOIN public.workout_sessions ws
        ON ws.id = se.session_id
      JOIN public.gym_equipment ge
        ON ge.id = COALESCE(se.equipment_id, ws.equipment_id)
       AND ge.gym_id = ws.gym_id
      WHERE se.session_id = p_session_id
        AND ws.finished_at IS NOT NULL
        AND ge.equipment_type = 'fixed_machine'

      UNION

      -- Previously materialized rows sourced from this session (cleanup path
      -- when a session edit removes sets or exercise rows).
      SELECT ub.equipment_id
      FROM public.user_machine_equipment_best ub
      WHERE ub.gym_id = v_gym_id
        AND ub.user_id = v_user_id
        AND ub.best_session_id = p_session_id
    ) x
  LOOP
    PERFORM public.recompute_machine_perf_best_for_equipment(
      v_gym_id,
      v_user_id,
      v_equipment_id
    );
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.recompute_machine_performance_for_session(UUID) IS
  'Recomputes machine-performance best-set rows for all fixed-machine equipment pieces touched by the session.';

GRANT EXECUTE ON FUNCTION public.recompute_machine_perf_best_for_equipment(UUID, UUID, UUID)
  TO service_role;

GRANT EXECUTE ON FUNCTION public.recompute_machine_performance_for_session(UUID)
  TO authenticated, service_role;

-- ─── 3) Historical backfill for new per-equipment table ─────────────────────

WITH ranked_sets AS (
  SELECT
    ws.gym_id,
    ge.id                                AS equipment_id,
    ws.user_id,
    st.id                                AS set_entry_id,
    ws.id                                AS session_id,
    ws.finished_at                       AS achieved_at,
    st.weight_kg::NUMERIC(6,2)           AS weight_kg,
    st.reps::SMALLINT                    AS reps,
    (st.weight_kg::NUMERIC * (1 + st.reps::NUMERIC / 30.0)) AS e1rm_kg,
    ROW_NUMBER() OVER (
      PARTITION BY ws.gym_id, ge.id, ws.user_id
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
    AND st.weight_kg IS NOT NULL
    AND st.weight_kg > 0
    AND st.reps IS NOT NULL
    AND st.reps BETWEEN 1 AND 15
)
INSERT INTO public.user_machine_equipment_best (
  gym_id,
  equipment_id,
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
  rs.equipment_id,
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
ON CONFLICT (gym_id, equipment_id, user_id) DO UPDATE
SET
  best_e1rm_kg      = EXCLUDED.best_e1rm_kg,
  best_weight_kg    = EXCLUDED.best_weight_kg,
  best_reps         = EXCLUDED.best_reps,
  best_set_entry_id = EXCLUDED.best_set_entry_id,
  best_session_id   = EXCLUDED.best_session_id,
  achieved_at       = EXCLUDED.achieved_at,
  formula_version   = EXCLUDED.formula_version,
  computed_at       = NOW();

-- Defensive cleanup for stale rows tied to non-fixed/removed equipment.
DELETE FROM public.user_machine_equipment_best ub
WHERE NOT EXISTS (
  SELECT 1
  FROM public.gym_equipment ge
  WHERE ge.id = ub.equipment_id
    AND ge.gym_id = ub.gym_id
    AND ge.equipment_type = 'fixed_machine'
);

-- ─── 4) Read RPCs (equipment boards, leaderboard, dashboard, activity) ──────

CREATE OR REPLACE FUNCTION public.get_machine_performance_equipment_boards(
  p_gym_id UUID,
  p_sex    public.machine_perf_sex,
  p_query  TEXT DEFAULT NULL
)
RETURNS TABLE (
  equipment_id      UUID,
  equipment_name    TEXT,
  manufacturer      TEXT,
  exercise_key      TEXT,
  exercise_name     TEXT,
  participant_count INTEGER,
  top_e1rm_kg       NUMERIC(8,3),
  top_weight_kg     NUMERIC(6,2),
  top_reps          SMALLINT,
  top_user_id       UUID,
  top_username      TEXT,
  top_achieved_at   TIMESTAMPTZ
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
  active_equipment AS (
    SELECT
      ge.id AS equipment_id,
      ge.name AS equipment_name,
      ge.manufacturer,
      ge.canonical_exercise_key AS exercise_key,
      COALESCE(et.name, ge.canonical_exercise_key) AS exercise_name
    FROM public.gym_equipment ge
    LEFT JOIN public.exercise_templates et
      ON et.gym_id = ge.gym_id
     AND et.key = ge.canonical_exercise_key
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
      ub.equipment_id,
      ub.user_id,
      ub.best_e1rm_kg,
      ub.best_weight_kg,
      ub.best_reps,
      ub.achieved_at,
      RANK() OVER (
        PARTITION BY ub.equipment_id
        ORDER BY
          ub.best_e1rm_kg DESC,
          ub.best_weight_kg DESC,
          ub.best_reps ASC,
          ub.achieved_at ASC,
          ub.user_id ASC
      ) AS rn,
      COUNT(*) OVER (PARTITION BY ub.equipment_id)::INTEGER AS participants
    FROM public.user_machine_equipment_best ub
    JOIN eligible_users eu
      ON eu.id = ub.user_id
    WHERE ub.gym_id = p_gym_id
  )
  SELECT
    ae.equipment_id,
    ae.equipment_name,
    ae.manufacturer,
    ae.exercise_key,
    ae.exercise_name,
    COALESCE(r.participants, 0)      AS participant_count,
    r.best_e1rm_kg                   AS top_e1rm_kg,
    r.best_weight_kg                 AS top_weight_kg,
    r.best_reps                      AS top_reps,
    r.user_id                        AS top_user_id,
    eu.username                      AS top_username,
    r.achieved_at                    AS top_achieved_at
  FROM active_equipment ae
  LEFT JOIN ranked r
    ON r.equipment_id = ae.equipment_id
   AND r.rn = 1
  LEFT JOIN eligible_users eu
    ON eu.id = r.user_id
  WHERE (SELECT ok FROM authz)
    AND (
      p_query IS NULL
      OR BTRIM(p_query) = ''
      OR ae.equipment_name ILIKE ('%' || p_query || '%')
      OR COALESCE(ae.manufacturer, '') ILIKE ('%' || p_query || '%')
      OR COALESCE(ae.exercise_name, '') ILIKE ('%' || p_query || '%')
    )
  ORDER BY
    CASE WHEN r.best_e1rm_kg IS NULL THEN 1 ELSE 0 END,
    COALESCE(r.participants, 0) DESC,
    r.best_e1rm_kg DESC NULLS LAST,
    ae.equipment_name ASC
  LIMIT 500;
$$;

COMMENT ON FUNCTION public.get_machine_performance_equipment_boards(UUID, public.machine_perf_sex, TEXT) IS
  'Returns fixed-machine equipment boards for one gym and sex bucket (opt-in users only).';

CREATE OR REPLACE FUNCTION public.get_machine_performance_equipment_leaderboard(
  p_gym_id       UUID,
  p_equipment_id UUID,
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
    FROM public.user_machine_equipment_best ub
    JOIN active_members am
      ON am.user_id = ub.user_id
    JOIN public.user_profiles up
      ON up.id = ub.user_id
     AND up.machine_perf_opt_in = TRUE
     AND up.machine_perf_sex = p_sex
     AND up.username IS NOT NULL
    WHERE ub.gym_id = p_gym_id
      AND ub.equipment_id = p_equipment_id
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

COMMENT ON FUNCTION public.get_machine_performance_equipment_leaderboard(UUID, UUID, public.machine_perf_sex, INTEGER, INTEGER) IS
  'Ranked machine-performance leaderboard for one fixed machine (equipment piece) and one sex bucket.';

CREATE OR REPLACE FUNCTION public.get_machine_performance_dashboard_stats(
  p_gym_id UUID,
  p_sex    public.machine_perf_sex
)
RETURNS TABLE (
  fixed_machine_count INTEGER,
  active_boards_count INTEGER,
  ranked_athletes_count INTEGER,
  best_e1rm_kg NUMERIC(8,3),
  best_equipment_id UUID,
  best_equipment_name TEXT,
  best_username TEXT
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
  active_equipment AS (
    SELECT ge.id, ge.name
    FROM public.gym_equipment ge
    WHERE ge.gym_id = p_gym_id
      AND ge.is_active = TRUE
      AND ge.equipment_type = 'fixed_machine'
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
  scored AS (
    SELECT ub.*
    FROM public.user_machine_equipment_best ub
    JOIN eligible_users eu
      ON eu.id = ub.user_id
    WHERE ub.gym_id = p_gym_id
  ),
  best_global AS (
    SELECT
      s.best_e1rm_kg,
      s.equipment_id,
      ae.name AS equipment_name,
      eu.username
    FROM scored s
    JOIN active_equipment ae
      ON ae.id = s.equipment_id
    JOIN eligible_users eu
      ON eu.id = s.user_id
    ORDER BY
      s.best_e1rm_kg DESC,
      s.best_weight_kg DESC,
      s.best_reps ASC,
      s.achieved_at ASC,
      s.user_id ASC
    LIMIT 1
  )
  SELECT
    (SELECT COUNT(*)::INTEGER FROM active_equipment) AS fixed_machine_count,
    (SELECT COUNT(DISTINCT s.equipment_id)::INTEGER FROM scored s) AS active_boards_count,
    (SELECT COUNT(DISTINCT s.user_id)::INTEGER FROM scored s) AS ranked_athletes_count,
    bg.best_e1rm_kg,
    bg.equipment_id AS best_equipment_id,
    bg.equipment_name AS best_equipment_name,
    bg.username AS best_username
  FROM authz a
  LEFT JOIN best_global bg
    ON TRUE
  WHERE a.ok;
$$;

COMMENT ON FUNCTION public.get_machine_performance_dashboard_stats(UUID, public.machine_perf_sex) IS
  'Returns high-level performance dashboard stats for one gym and sex bucket.';

CREATE OR REPLACE FUNCTION public.get_machine_performance_recent_records(
  p_gym_id UUID,
  p_sex    public.machine_perf_sex,
  p_limit  INTEGER DEFAULT 12
)
RETURNS TABLE (
  equipment_id      UUID,
  equipment_name    TEXT,
  manufacturer      TEXT,
  exercise_name     TEXT,
  user_id           UUID,
  username          TEXT,
  best_e1rm_kg      NUMERIC(8,3),
  best_weight_kg    NUMERIC(6,2),
  best_reps         SMALLINT,
  achieved_at       TIMESTAMPTZ
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
  eligible_users AS (
    SELECT up.id, up.username
    FROM public.user_profiles up
    JOIN active_members am
      ON am.user_id = up.id
    WHERE up.machine_perf_opt_in = TRUE
      AND up.machine_perf_sex = p_sex
      AND up.username IS NOT NULL
  ),
  ranked_top AS (
    SELECT
      ub.*,
      RANK() OVER (
        PARTITION BY ub.equipment_id
        ORDER BY
          ub.best_e1rm_kg DESC,
          ub.best_weight_kg DESC,
          ub.best_reps ASC,
          ub.achieved_at ASC,
          ub.user_id ASC
      ) AS rn
    FROM public.user_machine_equipment_best ub
    JOIN eligible_users eu
      ON eu.id = ub.user_id
    WHERE ub.gym_id = p_gym_id
  )
  SELECT
    ge.id AS equipment_id,
    ge.name AS equipment_name,
    ge.manufacturer,
    COALESCE(et.name, ge.canonical_exercise_key) AS exercise_name,
    rt.user_id,
    eu.username,
    rt.best_e1rm_kg,
    rt.best_weight_kg,
    rt.best_reps,
    rt.achieved_at
  FROM ranked_top rt
  JOIN public.gym_equipment ge
    ON ge.id = rt.equipment_id
   AND ge.gym_id = p_gym_id
   AND ge.is_active = TRUE
   AND ge.equipment_type = 'fixed_machine'
  JOIN eligible_users eu
    ON eu.id = rt.user_id
  LEFT JOIN public.exercise_templates et
    ON et.gym_id = p_gym_id
   AND et.key = ge.canonical_exercise_key
  WHERE (SELECT ok FROM authz)
    AND rt.rn = 1
  ORDER BY rt.achieved_at DESC, rt.best_e1rm_kg DESC
  LIMIT LEAST(GREATEST(p_limit, 1), 30);
$$;

COMMENT ON FUNCTION public.get_machine_performance_recent_records(UUID, public.machine_perf_sex, INTEGER) IS
  'Returns recent current gym records (rank 1 per machine) for activity/news cards.';

GRANT EXECUTE ON FUNCTION public.get_machine_performance_equipment_boards(UUID, public.machine_perf_sex, TEXT)
  TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_machine_performance_equipment_leaderboard(UUID, UUID, public.machine_perf_sex, INTEGER, INTEGER)
  TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_machine_performance_dashboard_stats(UUID, public.machine_perf_sex)
  TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_machine_performance_recent_records(UUID, public.machine_perf_sex, INTEGER)
  TO authenticated;
