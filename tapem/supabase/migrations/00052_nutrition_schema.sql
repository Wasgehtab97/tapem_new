-- Migration 00052: Nutrition/Calorie Tracker schema
-- All tables are user-scoped under users/{uid}
-- nutrition_products is globally shared (all authenticated users can read, validated writes)

-- ── Per-user daily goal ──────────────────────────────────────────────────────
CREATE TABLE nutrition_goals (
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date_key    CHAR(8)     NOT NULL CHECK (date_key ~ '^\d{8}$'),
  kcal        INTEGER     NOT NULL CHECK (kcal >= 0),
  protein     INTEGER     NOT NULL DEFAULT 0 CHECK (protein >= 0),
  carbs       INTEGER     NOT NULL DEFAULT 0 CHECK (carbs >= 0),
  fat         INTEGER     NOT NULL DEFAULT 0 CHECK (fat >= 0),
  source      TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, date_key)
);

-- ── Per-user default goal ────────────────────────────────────────────────────
CREATE TABLE nutrition_goal_defaults (
  user_id     UUID        NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  kcal        INTEGER     NOT NULL DEFAULT 2000 CHECK (kcal >= 0),
  protein     INTEGER     NOT NULL DEFAULT 150 CHECK (protein >= 0),
  carbs       INTEGER     NOT NULL DEFAULT 250 CHECK (carbs >= 0),
  fat         INTEGER     NOT NULL DEFAULT 67 CHECK (fat >= 0),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Per-user daily log ───────────────────────────────────────────────────────
-- entries is a JSONB array (max 50 enforced by CHECK + app logic)
CREATE TABLE nutrition_logs (
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date_key      CHAR(8)     NOT NULL CHECK (date_key ~ '^\d{8}$'),
  total_kcal    INTEGER     NOT NULL DEFAULT 0 CHECK (total_kcal >= 0),
  total_protein INTEGER     NOT NULL DEFAULT 0 CHECK (total_protein >= 0),
  total_carbs   INTEGER     NOT NULL DEFAULT 0 CHECK (total_carbs >= 0),
  total_fat     INTEGER     NOT NULL DEFAULT 0 CHECK (total_fat >= 0),
  entries       JSONB       NOT NULL DEFAULT '[]',
  status        TEXT        NOT NULL DEFAULT 'under' CHECK (status IN ('under', 'on', 'over')),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, date_key),
  CONSTRAINT entries_max_50 CHECK (jsonb_array_length(entries) <= 50)
);

-- ── Per-user year summary ────────────────────────────────────────────────────
-- days is a JSONB map: { "20260101": { "status": "under", "total_kcal": 1800, "goal_kcal": 2000 } }
CREATE TABLE nutrition_year_summaries (
  user_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  year       SMALLINT    NOT NULL CHECK (year >= 2020 AND year <= 2100),
  days       JSONB       NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, year)
);

-- ── Per-user recipes ─────────────────────────────────────────────────────────
-- ingredients stored as JSONB array
CREATE TABLE nutrition_recipes (
  id          UUID        NOT NULL DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL CHECK (length(name) BETWEEN 1 AND 200),
  ingredients JSONB       NOT NULL DEFAULT '[]',
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (id)
);
CREATE INDEX idx_nutrition_recipes_user ON nutrition_recipes(user_id);

-- ── Per-user weight logs ─────────────────────────────────────────────────────
CREATE TABLE nutrition_weight_logs (
  user_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date_key   CHAR(8)     NOT NULL CHECK (date_key ~ '^\d{8}$'),
  kg         NUMERIC(6,2) NOT NULL CHECK (kg >= 20 AND kg <= 400),
  source     TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, date_key)
);

-- ── Per-user weight year summary ──────────────────────────────────────────────
CREATE TABLE nutrition_weight_year_summaries (
  user_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  year       SMALLINT    NOT NULL CHECK (year >= 2020 AND year <= 2100),
  days       JSONB       NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, year)
);

-- ── Per-user weight meta (current weight pointer) ────────────────────────────
CREATE TABLE nutrition_weight_meta (
  user_id    UUID        NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  kg         NUMERIC(6,2) NOT NULL CHECK (kg >= 20 AND kg <= 400),
  date_key   CHAR(8)     NOT NULL CHECK (date_key ~ '^\d{8}$'),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Global product database (all authenticated users can read) ────────────────
-- barcode lengths: 8/12/13/14 digits (EAN-8, UPC-A, EAN-13, ITF-14)
CREATE TABLE nutrition_products (
  barcode      TEXT        NOT NULL PRIMARY KEY
                           CHECK (barcode ~ '^\d{8}$|^\d{12}$|^\d{13}$|^\d{14}$'),
  name         TEXT        NOT NULL CHECK (length(name) BETWEEN 1 AND 300),
  kcal_per100  INTEGER     NOT NULL CHECK (kcal_per100 >= 0 AND kcal_per100 <= 9000),
  protein_per100 INTEGER   NOT NULL DEFAULT 0 CHECK (protein_per100 >= 0 AND protein_per100 <= 500),
  carbs_per100 INTEGER     NOT NULL DEFAULT 0 CHECK (carbs_per100 >= 0 AND carbs_per100 <= 1000),
  fat_per100   INTEGER     NOT NULL DEFAULT 0 CHECK (fat_per100 >= 0 AND fat_per100 <= 1000),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Helper RPC: upsert a single day in nutrition_year_summaries ───────────────
CREATE OR REPLACE FUNCTION nutrition_upsert_year_day(
  p_user_id  UUID,
  p_year     SMALLINT,
  p_date_key TEXT,
  p_status   TEXT,
  p_total_kcal INTEGER,
  p_goal_kcal  INTEGER
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO nutrition_year_summaries (user_id, year, days)
  VALUES (p_user_id, p_year, jsonb_build_object(
    p_date_key,
    jsonb_build_object('status', p_status, 'total_kcal', p_total_kcal, 'goal_kcal', p_goal_kcal)
  ))
  ON CONFLICT (user_id, year) DO UPDATE
    SET days = nutrition_year_summaries.days ||
               jsonb_build_object(
                 p_date_key,
                 jsonb_build_object('status', p_status, 'total_kcal', p_total_kcal, 'goal_kcal', p_goal_kcal)
               ),
        updated_at = now();
END;
$$;

-- ── Helper RPC: upsert a single day in nutrition_weight_year_summaries ────────
CREATE OR REPLACE FUNCTION nutrition_upsert_weight_day(
  p_user_id  UUID,
  p_year     SMALLINT,
  p_date_key TEXT,
  p_kg       NUMERIC
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO nutrition_weight_year_summaries (user_id, year, days)
  VALUES (p_user_id, p_year, jsonb_build_object(
    p_date_key,
    jsonb_build_object('kg', p_kg, 'updated_at', now()::text)
  ))
  ON CONFLICT (user_id, year) DO UPDATE
    SET days = nutrition_weight_year_summaries.days ||
               jsonb_build_object(
                 p_date_key,
                 jsonb_build_object('kg', p_kg, 'updated_at', now()::text)
               ),
        updated_at = now();
END;
$$;
