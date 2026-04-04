-- =============================================================================
-- Tap'em — 00081: Let an existing owner claim owner role in another gym
--
-- Intended for internal/operator workflows only:
-- a user who already owns at least one gym may promote their own active
-- membership in another gym to owner. This replaces the removed unsafe
-- dev_promote_to_owner backdoor with a narrower, auditable rule.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.claim_owner_membership_if_existing_owner(
  p_gym_id UUID
) RETURNS VOID
  SECURITY DEFINER
  LANGUAGE plpgsql
  SET search_path = public
AS $$
DECLARE
  v_current_role public.member_role;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT role
    INTO v_current_role
    FROM public.memberships
   WHERE user_id   = auth.uid()
     AND gym_id    = p_gym_id
     AND is_active = TRUE
   LIMIT 1;

  IF v_current_role IS NULL THEN
    RAISE EXCEPTION 'membership_not_found';
  END IF;

  IF v_current_role = 'owner' THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1
      FROM public.memberships
     WHERE user_id   = auth.uid()
       AND is_active = TRUE
       AND role      = 'owner'
       AND gym_id   <> p_gym_id
  ) THEN
    RAISE EXCEPTION 'not_existing_owner';
  END IF;

  UPDATE public.memberships
     SET role   = 'owner',
         status = COALESCE(status, 'active')
   WHERE user_id   = auth.uid()
     AND gym_id    = p_gym_id
     AND is_active = TRUE;

  PERFORM public._log_admin_action(
    p_gym_id,
    'self_claim_owner',
    auth.uid(),
    jsonb_build_object('old_role', v_current_role, 'new_role', 'owner')
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.claim_owner_membership_if_existing_owner(UUID)
  TO authenticated;
