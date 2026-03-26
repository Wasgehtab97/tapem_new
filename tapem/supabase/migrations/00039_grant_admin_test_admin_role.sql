-- =============================================================================
-- Tap'em — Grant admin role to admin_test user at Lifthouse test gym
-- =============================================================================

UPDATE public.memberships
SET role = 'admin'
WHERE user_id = (
    SELECT id FROM public.user_profiles WHERE lower(username) = 'admin_test'
)
AND gym_id = 'a0000000-0000-0000-0000-000000000099';
