-- =============================================================================
-- Tap'em — Rename user 'eisen1' → 'coach' at KSV Eisenschmiede
--
-- Finds the user with username 'eisen1' who has a membership at KSV
-- Eisenschmiede (a0000000-0000-0000-0000-000000000005) and renames them
-- to 'coach'.
--
-- Safety checks:
--   • Aborts if 'eisen1' is not found in user_profiles.
--   • Aborts if they have no membership at KSV Eisenschmiede.
--   • Aborts if the username 'coach' is already taken.
-- =============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_gym_id  UUID := 'a0000000-0000-0000-0000-000000000005'; -- KSV Eisenschmiede
BEGIN
  -- ── Resolve user ─────────────────────────────────────────────────────────

  SELECT id INTO v_user_id
  FROM public.user_profiles
  WHERE lower(username::TEXT) = 'eisen1';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User ''eisen1'' not found in user_profiles';
  END IF;

  -- ── Verify membership at KSV Eisenschmiede ────────────────────────────────

  IF NOT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = v_user_id AND gym_id = v_gym_id
  ) THEN
    RAISE EXCEPTION 'User ''eisen1'' has no membership at KSV Eisenschmiede (%)' , v_gym_id;
  END IF;

  -- ── Check target username is available ────────────────────────────────────

  IF EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE lower(username::TEXT) = 'coach'
      AND id <> v_user_id
  ) THEN
    RAISE EXCEPTION 'Username ''coach'' is already taken by another user';
  END IF;

  -- ── Rename ────────────────────────────────────────────────────────────────

  UPDATE public.user_profiles
  SET username   = 'coach',
      updated_at = NOW()
  WHERE id = v_user_id;

  RAISE NOTICE 'Renamed user % from ''eisen1'' to ''coach''', v_user_id;
END $$;
