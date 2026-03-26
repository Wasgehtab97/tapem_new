-- =============================================================================
-- Tap'em — Gym self-creation
-- Authenticated users can create their own gym and become its owner.
-- =============================================================================

-- Allow any authenticated user to insert a new gym
CREATE POLICY "gyms_insert_authenticated"
  ON public.tenant_gyms FOR INSERT
  TO authenticated
  WITH CHECK (TRUE);

-- Automatically create an 'owner' membership for the user who created the gym
CREATE OR REPLACE FUNCTION public.auto_create_gym_owner_membership()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.memberships (
    id, gym_id, user_id, role, is_active, joined_at
  ) VALUES (
    gen_random_uuid(), NEW.id, auth.uid(), 'owner', TRUE, NOW()
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_gym_owner
  AFTER INSERT ON public.tenant_gyms
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_gym_owner_membership();
