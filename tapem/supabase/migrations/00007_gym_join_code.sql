-- =============================================================================
-- Tap'em — Gym join-code model
-- Reverts member gym-creation (wrong product model).
-- Adds join_code to tenant_gyms and a secure join function.
-- Gyms are created by the platform operator (service role only).
-- Members join via a short unique code distributed by the gym.
-- =============================================================================

-- ─── Revert member gym-creation from migration 00004 ─────────────────────────

DROP TRIGGER IF EXISTS trg_auto_gym_owner ON public.tenant_gyms;
DROP FUNCTION IF EXISTS public.auto_create_gym_owner_membership();

DO $$ BEGIN
  DROP POLICY "gyms_insert_authenticated" ON public.tenant_gyms;
EXCEPTION WHEN undefined_object THEN NULL; END $$;

-- Also revoke the INSERT grant on tenant_gyms from authenticated
-- (SELECT remains so members can read gym info after joining)
REVOKE INSERT, UPDATE, DELETE ON public.tenant_gyms FROM authenticated;

-- ─── Add join_code to tenant_gyms ────────────────────────────────────────────

ALTER TABLE public.tenant_gyms
  ADD COLUMN IF NOT EXISTS join_code TEXT;

-- Unique, case-insensitive index
CREATE UNIQUE INDEX IF NOT EXISTS tenant_gyms_join_code_idx
  ON public.tenant_gyms (LOWER(join_code))
  WHERE join_code IS NOT NULL;

-- ─── Secure join function (SECURITY DEFINER bypasses RLS) ────────────────────

CREATE OR REPLACE FUNCTION public.join_gym_with_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_gym_id   UUID;
  v_gym_name TEXT;
  v_already  BOOLEAN := FALSE;
BEGIN
  -- Look up gym by code (case-insensitive)
  SELECT id, name
    INTO v_gym_id, v_gym_name
    FROM public.tenant_gyms
   WHERE LOWER(join_code) = LOWER(TRIM(p_code))
   LIMIT 1;

  IF v_gym_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error',   'invalid_code',
      'message', 'No gym found with this code. Please check and try again.'
    );
  END IF;

  -- Check for existing active membership
  SELECT EXISTS(
    SELECT 1 FROM public.memberships
     WHERE user_id  = auth.uid()
       AND gym_id   = v_gym_id
       AND is_active = TRUE
  ) INTO v_already;

  IF NOT v_already THEN
    INSERT INTO public.memberships (id, gym_id, user_id, role, is_active, joined_at)
    VALUES (gen_random_uuid(), v_gym_id, auth.uid(), 'member', TRUE, NOW());
  END IF;

  RETURN jsonb_build_object(
    'success',        TRUE,
    'gym_id',         v_gym_id,
    'gym_name',       v_gym_name,
    'already_member', v_already
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.join_gym_with_code(TEXT) TO authenticated;

-- ─── Seed: create the first test gym ─────────────────────────────────────────
-- Platform operator runs this; members will never have INSERT on tenant_gyms.

INSERT INTO public.tenant_gyms (id, name, slug, join_code)
VALUES (
  'a0000000-0000-0000-0000-000000000001',
  'Tap''em Demo Gym',
  'tapem-demo-gym',
  'TAPEM1'
)
ON CONFLICT (id) DO UPDATE
  SET join_code = 'TAPEM1',
      name      = 'Tap''em Demo Gym';
