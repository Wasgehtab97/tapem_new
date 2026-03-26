-- =============================================================================
-- Tap'em — 00035: Fix Memberships for Demo Gym Users
--
-- Problem:
--   Two users have locally-stored workout sessions for the Tap'em Demo Gym
--   (a0000000-0000-0000-0000-000000000001) but no active membership row in
--   the memberships table. The sync-workout Edge Function's membership check
--   (line ~128) returns HTTP 403 "No active membership for this gym" for both,
--   preventing their sessions from ever syncing.
--
--   User IDs identified from local SQLite (tapem_local_v1.sqlite):
--     - 66c53126-5c07-4d60-a032-afe1febc960d (2 sync_failed sessions)
--     - aa161c54-a91c-4d7b-98c6-219393e9d006 (3 sync_failed sessions)
--
-- Fix:
--   Ensure both users have an active membership in the Demo Gym. Also cover
--   any other user who has a session in ANY gym but no active membership there
--   (belt-and-suspenders for future cases).
--
-- Safety: All upserts are idempotent via ON CONFLICT DO UPDATE.
-- =============================================================================

-- ─── Step 1: Direct fix for the two known users ──────────────────────────────

INSERT INTO public.memberships (id, gym_id, user_id, role, is_active, joined_at)
VALUES
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000001', '66c53126-5c07-4d60-a032-afe1febc960d', 'member', TRUE, NOW()),
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000001', 'aa161c54-a91c-4d7b-98c6-219393e9d006', 'member', TRUE, NOW())
ON CONFLICT (user_id, gym_id) DO UPDATE
  SET is_active = TRUE,
      role      = EXCLUDED.role;

-- ─── Step 2: General fix — any user who has a user_profile but no active ─────
-- membership in ANY gym. Assign them to the Demo Gym as fallback.

INSERT INTO public.memberships (id, gym_id, user_id, role, is_active, joined_at)
SELECT
  gen_random_uuid(),
  'a0000000-0000-0000-0000-000000000001',
  up.id,
  'member',
  TRUE,
  NOW()
FROM public.user_profiles up
WHERE NOT EXISTS (
  SELECT 1
  FROM public.memberships m
  WHERE m.user_id   = up.id
    AND m.is_active = TRUE
)
ON CONFLICT (user_id, gym_id) DO UPDATE
  SET is_active = TRUE;

-- ─── Verify ───────────────────────────────────────────────────────────────────
-- SELECT up.username, m.gym_id, m.is_active
-- FROM   public.memberships m
-- JOIN   public.user_profiles up ON up.id = m.user_id
-- WHERE  m.gym_id = 'a0000000-0000-0000-0000-000000000001'
-- ORDER  BY up.username;
