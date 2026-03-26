-- =============================================================================
-- Tap'em — Schema Baseline Migration
-- Phase 1 Foundation
-- Region: EU (Frankfurt preferred)
-- RLS: deny-by-default on all public tables
-- =============================================================================

-- ─── Extensions ──────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext"; -- case-insensitive text for usernames

-- ─── Enums ───────────────────────────────────────────────────────────────────

CREATE TYPE equipment_type AS ENUM ('fixed_machine', 'open_station', 'cardio');

CREATE TYPE member_role AS ENUM ('member', 'coach', 'admin', 'owner');

CREATE TYPE privacy_level AS ENUM (
  'private',
  'friends_training_days',
  'friends_training_and_summary'
);

CREATE TYPE sync_status AS ENUM (
  'local_saved',
  'sync_pending',
  'sync_confirmed',
  'sync_failed'
);

CREATE TYPE xp_axis AS ENUM ('training_day', 'exercise_equipment', 'muscle_group');

CREATE TYPE friendship_status AS ENUM ('pending', 'accepted', 'declined', 'blocked');

CREATE TYPE notification_type AS ENUM (
  'friend_request',
  'friend_accepted',
  'achievement_unlocked',
  'xp_level_up',
  'challenge_started',
  'challenge_completed',
  'plan_assigned'
);

-- ─── tenant_gyms ─────────────────────────────────────────────────────────────

CREATE TABLE public.tenant_gyms (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  slug            CITEXT NOT NULL UNIQUE,
  region          TEXT NOT NULL DEFAULT 'eu-central-1',
  logo_url        TEXT,
  address_line1   TEXT,
  city            TEXT,
  country_code    CHAR(2) NOT NULL DEFAULT 'DE',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── user_profiles ───────────────────────────────────────────────────────────
-- id references auth.users — created immediately after user signs up.
-- Username is mandatory before any gym access is granted.

CREATE TABLE public.user_profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username        CITEXT NOT NULL UNIQUE
                    CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]{3,24}$'),
  display_name    TEXT,
  avatar_url      TEXT,
  theme_key       TEXT NOT NULL DEFAULT 'default'
                    CONSTRAINT valid_theme CHECK (theme_key IN ('default', 'energy', 'minimal')),
  privacy_level   privacy_level NOT NULL DEFAULT 'friends_training_days',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Case-insensitive index — enforces uniqueness and powers fast username lookup
CREATE UNIQUE INDEX idx_user_profiles_username ON public.user_profiles (lower(username::TEXT));

-- ─── username_reservations ────────────────────────────────────────────────────
-- Prevents race conditions during username setup.

CREATE TABLE public.username_reservations (
  username        CITEXT PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reserved_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at      TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '10 minutes'
);

CREATE INDEX idx_username_reservations_user ON public.username_reservations (user_id);

-- ─── memberships ─────────────────────────────────────────────────────────────

CREATE TABLE public.memberships (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  role            member_role NOT NULL DEFAULT 'member',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, gym_id)
);

CREATE INDEX idx_memberships_gym ON public.memberships (gym_id);
CREATE INDEX idx_memberships_user ON public.memberships (user_id);

-- ─── gym_equipment ────────────────────────────────────────────────────────────

CREATE TABLE public.gym_equipment (
  id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id                   UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  name                     TEXT NOT NULL,
  equipment_type           equipment_type NOT NULL,
  zone_name                TEXT NOT NULL,
  nfc_tag_uid              TEXT,
  canonical_exercise_key   TEXT, -- only for fixed_machine
  ranking_eligible_override BOOLEAN,
  manufacturer             TEXT,
  model                    TEXT,
  equipment_external_id    TEXT, -- gym's own ID for import reconciliation
  is_active                BOOLEAN NOT NULL DEFAULT TRUE,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (gym_id, equipment_external_id),
  UNIQUE (gym_id, nfc_tag_uid) -- one NFC tag per gym
);

-- Enforce: fixed_machine must have canonical_exercise_key
ALTER TABLE public.gym_equipment
  ADD CONSTRAINT fixed_machine_has_canonical
  CHECK (equipment_type != 'fixed_machine' OR canonical_exercise_key IS NOT NULL);

CREATE INDEX idx_gym_equipment_gym ON public.gym_equipment (gym_id);
CREATE INDEX idx_gym_equipment_nfc ON public.gym_equipment (nfc_tag_uid) WHERE nfc_tag_uid IS NOT NULL;

-- ─── equipment_tags ───────────────────────────────────────────────────────────

CREATE TABLE public.equipment_tags (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  equipment_id    UUID NOT NULL REFERENCES public.gym_equipment(id) ON DELETE CASCADE,
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  tag             TEXT NOT NULL,
  UNIQUE (equipment_id, tag)
);

-- ─── exercise_templates ───────────────────────────────────────────────────────

CREATE TABLE public.exercise_templates (
  key                     TEXT NOT NULL,
  gym_id                  UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  name                    TEXT NOT NULL,
  description             TEXT,
  primary_muscle_group    TEXT,
  is_ranking_eligible     BOOLEAN NOT NULL DEFAULT FALSE,
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (key, gym_id)
);

CREATE INDEX idx_exercise_templates_gym ON public.exercise_templates (gym_id);

-- ─── muscle_group_weights ─────────────────────────────────────────────────────
-- Normalized from ExerciseTemplate. Sum of weights must equal 1.0 per exercise.

CREATE TABLE public.muscle_group_weights (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  exercise_key        TEXT NOT NULL,
  gym_id              UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  muscle_group        TEXT NOT NULL,
  weight              NUMERIC(5,4) NOT NULL CHECK (weight > 0 AND weight <= 1),
  UNIQUE (exercise_key, gym_id, muscle_group),
  FOREIGN KEY (exercise_key, gym_id) REFERENCES public.exercise_templates(key, gym_id) ON DELETE CASCADE
);

-- ─── user_custom_exercises ────────────────────────────────────────────────────
-- Scoped per user + gym. Never ranking-eligible by default.

CREATE TABLE public.user_custom_exercises (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id              UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name                TEXT NOT NULL,
  is_ranking_eligible BOOLEAN NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (gym_id, user_id, name) -- prevent near-identical duplicates at DB level
);

CREATE INDEX idx_user_custom_exercises_user_gym ON public.user_custom_exercises (user_id, gym_id);

-- ─── workout_plans ────────────────────────────────────────────────────────────

CREATE TABLE public.workout_plans (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  created_by      UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  name            TEXT NOT NULL,
  description     TEXT,
  is_public       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workout_plans_gym ON public.workout_plans (gym_id);

-- ─── plan_assignments ─────────────────────────────────────────────────────────

CREATE TABLE public.plan_assignments (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  plan_id         UUID NOT NULL REFERENCES public.workout_plans(id) ON DELETE CASCADE,
  assigned_to     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_by     UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  assigned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  active_until    TIMESTAMPTZ,
  UNIQUE (plan_id, assigned_to)
);

-- ─── workout_sessions ─────────────────────────────────────────────────────────
-- session_day_anchor: local calendar date (yyyy-MM-dd) at gym at session start.
-- Immutable once set — used for training_day XP deduplication.

CREATE TABLE public.workout_sessions (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id              UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  equipment_id        UUID NOT NULL REFERENCES public.gym_equipment(id) ON DELETE RESTRICT,
  session_day_anchor  DATE NOT NULL,   -- immutable, set at session start
  started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at         TIMESTAMPTZ,
  sync_status         sync_status NOT NULL DEFAULT 'local_saved',
  idempotency_key     UUID UNIQUE,     -- client-generated, prevents duplicate sessions
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workout_sessions_user_gym ON public.workout_sessions (user_id, gym_id);
CREATE INDEX idx_workout_sessions_day ON public.workout_sessions (gym_id, session_day_anchor);
CREATE INDEX idx_workout_sessions_active ON public.workout_sessions (user_id) WHERE finished_at IS NULL;

-- ─── session_exercises ────────────────────────────────────────────────────────

CREATE TABLE public.session_exercises (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id          UUID NOT NULL REFERENCES public.workout_sessions(id) ON DELETE CASCADE,
  gym_id              UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  exercise_key        TEXT NOT NULL,
  display_name        TEXT NOT NULL,
  sort_order          SMALLINT NOT NULL DEFAULT 0,
  custom_exercise_id  UUID REFERENCES public.user_custom_exercises(id) ON DELETE SET NULL,
  notes               TEXT,
  sync_status         sync_status NOT NULL DEFAULT 'local_saved',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_session_exercises_session ON public.session_exercises (session_id);

-- ─── set_entries ──────────────────────────────────────────────────────────────

CREATE TABLE public.set_entries (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_exercise_id     UUID NOT NULL REFERENCES public.session_exercises(id) ON DELETE CASCADE,
  gym_id                  UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  set_number              SMALLINT NOT NULL CHECK (set_number > 0),
  reps                    SMALLINT CHECK (reps > 0),
  weight_kg               NUMERIC(6,2) CHECK (weight_kg >= 0),
  duration_seconds        INTEGER CHECK (duration_seconds > 0), -- primary for cardio
  distance_meters         NUMERIC(8,2) CHECK (distance_meters > 0),
  notes                   TEXT,
  sync_status             sync_status NOT NULL DEFAULT 'local_saved',
  logged_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  idempotency_key         UUID UNIQUE, -- prevents duplicate set events
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_exercise_id, set_number)
);

CREATE INDEX idx_set_entries_session_exercise ON public.set_entries (session_exercise_id);

-- ─── xp_events ───────────────────────────────────────────────────────────────
-- Immutable append-only event log. Deduplicated by idempotency_key.

CREATE TABLE public.xp_events (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id              UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  axis                xp_axis NOT NULL,
  xp_amount           INTEGER NOT NULL CHECK (xp_amount > 0),
  source_type         TEXT NOT NULL, -- 'workout_session' | 'session_exercise' | 'set_entry'
  source_id           UUID NOT NULL,
  idempotency_key     TEXT NOT NULL UNIQUE, -- '{axis}:{source_type}:{source_id}'
  exercise_key        TEXT,
  muscle_group        TEXT,
  occurred_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_xp_events_user_gym ON public.xp_events (user_id, gym_id);
CREATE INDEX idx_xp_events_axis ON public.xp_events (user_id, gym_id, axis);
CREATE INDEX idx_xp_events_idempotency ON public.xp_events (idempotency_key);

-- ─── user_gym_xp ──────────────────────────────────────────────────────────────
-- Materialized XP totals per user+gym. Updated by server-side triggers.

CREATE TABLE public.user_gym_xp (
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  total_xp        INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
  current_level   SMALLINT NOT NULL DEFAULT 1 CHECK (current_level >= 1),
  xp_to_next_level INTEGER NOT NULL DEFAULT 500,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, gym_id)
);

-- ─── user_exercise_xp ─────────────────────────────────────────────────────────

CREATE TABLE public.user_exercise_xp (
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  exercise_key    TEXT NOT NULL,
  total_xp        INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
  current_level   SMALLINT NOT NULL DEFAULT 1,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, gym_id, exercise_key)
);

-- ─── user_muscle_group_xp ────────────────────────────────────────────────────

CREATE TABLE public.user_muscle_group_xp (
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  muscle_group    TEXT NOT NULL,
  total_xp        INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
  current_level   SMALLINT NOT NULL DEFAULT 1,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, gym_id, muscle_group)
);

-- ─── level_snapshots ──────────────────────────────────────────────────────────

CREATE TABLE public.level_snapshots (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  axis            xp_axis NOT NULL,
  level_reached   SMALLINT NOT NULL,
  xp_at_level     INTEGER NOT NULL,
  snapshotted_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_level_snapshots_user_gym ON public.level_snapshots (user_id, gym_id, axis);

-- ─── achievements ─────────────────────────────────────────────────────────────

CREATE TABLE public.achievements (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  key             TEXT NOT NULL,
  label           TEXT NOT NULL,
  description     TEXT,
  unlocked_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (gym_id, user_id, key)
);

-- ─── challenges ───────────────────────────────────────────────────────────────

CREATE TABLE public.challenges (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  starts_at       TIMESTAMPTZ NOT NULL,
  ends_at         TIMESTAMPTZ NOT NULL,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_challenges_gym ON public.challenges (gym_id);

-- ─── ranking_events ───────────────────────────────────────────────────────────

CREATE TABLE public.ranking_events (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_key    TEXT NOT NULL,
  metric_value    NUMERIC(10,2) NOT NULL,
  metric_type     TEXT NOT NULL DEFAULT 'weight_kg',
  set_entry_id    UUID REFERENCES public.set_entries(id) ON DELETE SET NULL,
  occurred_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ranking_events_exercise ON public.ranking_events (gym_id, exercise_key);

-- ─── ranking_snapshots ────────────────────────────────────────────────────────

CREATE TABLE public.ranking_snapshots (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  exercise_key    TEXT NOT NULL,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rank            INTEGER NOT NULL,
  metric_value    NUMERIC(10,2) NOT NULL,
  snapshotted_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (gym_id, exercise_key, user_id, snapshotted_at)
);

-- ─── feed_events ──────────────────────────────────────────────────────────────

CREATE TABLE public.feed_events (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  actor_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type      TEXT NOT NULL,
  payload         JSONB NOT NULL DEFAULT '{}',
  privacy_level   privacy_level NOT NULL DEFAULT 'friends_training_days',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_feed_events_gym_actor ON public.feed_events (gym_id, actor_id);
CREATE INDEX idx_feed_events_created ON public.feed_events (created_at DESC);

-- ─── friendships ──────────────────────────────────────────────────────────────
-- Gym-internal only in V1. Both users must have active membership in the gym.

CREATE TABLE public.friendships (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  requester_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  addressee_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status          friendship_status NOT NULL DEFAULT 'pending',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at    TIMESTAMPTZ,
  UNIQUE (gym_id, requester_id, addressee_id),
  CHECK (requester_id != addressee_id)
);

CREATE INDEX idx_friendships_requester ON public.friendships (requester_id, gym_id);
CREATE INDEX idx_friendships_addressee ON public.friendships (addressee_id, gym_id);

-- ─── notifications ────────────────────────────────────────────────────────────

CREATE TABLE public.notifications (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id          UUID NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type            notification_type NOT NULL,
  payload         JSONB NOT NULL DEFAULT '{}',
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON public.notifications (user_id, is_read, created_at DESC);

-- ─── Updated-at trigger ───────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_updated_at_tenant_gyms
  BEFORE UPDATE ON public.tenant_gyms
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_user_profiles
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_gym_equipment
  BEFORE UPDATE ON public.gym_equipment
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_workout_sessions
  BEFORE UPDATE ON public.workout_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_exercise_templates
  BEFORE UPDATE ON public.exercise_templates
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─── session_day_anchor immutability guard ────────────────────────────────────

CREATE OR REPLACE FUNCTION public.guard_session_day_anchor()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.session_day_anchor IS DISTINCT FROM NEW.session_day_anchor THEN
    RAISE EXCEPTION 'session_day_anchor is immutable once set';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER guard_session_day_anchor
  BEFORE UPDATE ON public.workout_sessions
  FOR EACH ROW EXECUTE FUNCTION public.guard_session_day_anchor();
