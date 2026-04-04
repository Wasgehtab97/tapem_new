-- DEV ONLY: Allows a user to promote themselves to owner in a gym.
-- DELETE THIS MIGRATION AND DROP THIS FUNCTION BEFORE PRODUCTION LAUNCH.
CREATE OR REPLACE FUNCTION public.dev_promote_to_owner(p_gym_id UUID)
RETURNS VOID
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.memberships
     SET role = 'owner'
   WHERE gym_id = p_gym_id AND user_id = auth.uid();
END;
$$;

GRANT EXECUTE ON FUNCTION public.dev_promote_to_owner(UUID) TO authenticated;
