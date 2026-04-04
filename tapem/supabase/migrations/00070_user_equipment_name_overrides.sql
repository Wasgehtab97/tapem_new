-- =============================================================================
-- Tap'em — user_equipment_name_overrides
--
-- Purpose:
--   Per-user, per-equipment personal display names (aliases).
--   Canonical gym_equipment.name remains the global source of truth.
--
-- Security model:
--   • Users can only read/write/delete their own override rows.
--   • Membership in the gym is required.
--   • service_role bypasses RLS for admin tooling.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.user_equipment_name_overrides (
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  gym_id        UUID        NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  equipment_id  UUID        NOT NULL REFERENCES public.gym_equipment(id) ON DELETE CASCADE,
  display_name  TEXT        NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_equipment_name_overrides_pkey
    PRIMARY KEY (user_id, equipment_id),
  CONSTRAINT user_equipment_name_overrides_display_name_nonempty
    CHECK (char_length(trim(display_name)) >= 1),
  CONSTRAINT user_equipment_name_overrides_display_name_maxlen
    CHECK (char_length(trim(display_name)) <= 80)
);

CREATE INDEX IF NOT EXISTS idx_user_equipment_name_overrides_user_gym
  ON public.user_equipment_name_overrides (user_id, gym_id);

CREATE OR REPLACE FUNCTION public.tg_user_equipment_name_overrides_timestamps_lww()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := COALESCE(NEW.updated_at, NEW.created_at);
    RETURN NEW;
  END IF;

  -- UPDATE
  NEW.created_at := OLD.created_at;
  NEW.updated_at := COALESCE(NEW.updated_at, NOW());

  -- Deterministic LWW: reject stale writes.
  IF NEW.updated_at < OLD.updated_at THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_equipment_name_overrides_timestamps_lww
  ON public.user_equipment_name_overrides;

CREATE TRIGGER trg_user_equipment_name_overrides_timestamps_lww
BEFORE INSERT OR UPDATE
ON public.user_equipment_name_overrides
FOR EACH ROW
EXECUTE FUNCTION public.tg_user_equipment_name_overrides_timestamps_lww();

ALTER TABLE public.user_equipment_name_overrides ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "user_equipment_name_overrides_select_own"
    ON public.user_equipment_name_overrides FOR SELECT
    TO authenticated
    USING (
      user_id = auth.uid()
      AND public.has_active_membership(gym_id)
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_equipment_name_overrides_insert_own"
    ON public.user_equipment_name_overrides FOR INSERT
    TO authenticated
    WITH CHECK (
      user_id = auth.uid()
      AND public.has_active_membership(gym_id)
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_equipment_name_overrides_update_own"
    ON public.user_equipment_name_overrides FOR UPDATE
    TO authenticated
    USING (
      user_id = auth.uid()
      AND public.has_active_membership(gym_id)
    )
    WITH CHECK (
      user_id = auth.uid()
      AND public.has_active_membership(gym_id)
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_equipment_name_overrides_delete_own"
    ON public.user_equipment_name_overrides FOR DELETE
    TO authenticated
    USING (
      user_id = auth.uid()
      AND public.has_active_membership(gym_id)
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.user_equipment_name_overrides TO authenticated;
GRANT ALL
  ON public.user_equipment_name_overrides TO service_role;
