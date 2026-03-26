-- =============================================================================
-- Tap'em — 00037: Fix exercise_equipment XP amounts and seed ironwood's events
--
-- Problems:
--   1. sync-workout used a variable XP formula (5/set + floor(reps/5)) instead
--      of the flat 25 XP per exercise-session defined in XpRules.exerciseSessionBase.
--      Result: ironbronz has 3 exercise_equipment events with 21 XP each.
--
--   2. ironbronz's chest_press exercise was done without NFC scan — equipment_id
--      came through as empty string "", which isValidUuid rejects → stored as NULL
--      in xp_events. The get_gym_equipment_overview RPC filters out NULL equipment_id
--      entries, so Chest Press never appears in the Equipment XP tab.
--
--   3. ironwood has ZERO exercise_equipment xp_events because their device sessions
--      are sync_failed (different device). Their XP from those sessions must be
--      seeded directly from local SQLite data. Only exercises with a valid
--      equipment_id (NFC-scanned mid-session) are seeded here; freestyle exercises
--      remain invisible in the equipment leaderboard (correct per-product behaviour).
--
-- Fix:
--   1. Correct all existing exercise_equipment xp_events for ironbronz to 25 XP.
--   2. Set chest_press equipment_id to the correct Chest Press machine UUID.
--   3. INSERT 3 exercise_equipment events for ironwood (only equipment-linked exercises).
--   4. Recompute user_exercise_xp aggregates for both affected users.
--
-- Safety: All INSERTs use ON CONFLICT (idempotency_key) DO NOTHING.
--         UPDATEs are scoped to the specific user_id.
-- =============================================================================

-- ─── User IDs ────────────────────────────────────────────────────────────────
-- ironbronz: 66c53126-5c07-4d60-a032-afe1febc960d
-- ironwood:  aa161c54-a91c-4d7b-98c6-219393e9d006
-- Demo Gym:  a0000000-0000-0000-0000-000000000001

-- ─── Step 1: Fix XP amounts — ironbronz exercise_equipment events → 25 XP ───

UPDATE public.xp_events
SET    xp_amount = 25
WHERE  axis        = 'exercise_equipment'
  AND  user_id     = '66c53126-5c07-4d60-a032-afe1febc960d'
  AND  xp_amount  != 25;

-- ─── Step 2: Fix chest_press equipment_id (ironbronz) ────────────────────────
-- Exercise was done without NFC scan → equipment_id stored as NULL.
-- Assign to the physical Chest Press machine (e6fd53f3-...) in Demo Gym.

UPDATE public.xp_events
SET    equipment_id = 'e6fd53f3-90ac-4e31-9bcb-4251c5e4fa64'
WHERE  axis         = 'exercise_equipment'
  AND  user_id      = '66c53126-5c07-4d60-a032-afe1febc960d'
  AND  exercise_key = 'chest_press'
  AND  equipment_id IS NULL;

-- ─── Step 3: Seed ironwood's exercise_equipment XP events ────────────────────
-- Only the 3 session_exercises where a valid equipment_id was recorded.
-- Freestyle exercises (hip_abduction, bench_press session 1, bicep_curl,
-- custom exercise) had no equipment_id and are correctly absent from equipment
-- leaderboards — no backfill for those.
--
-- Source IDs from local SQLite (real UUIDs):
--   5a9a25a3-b5b0-4fcf-9566-7be3da81f3c3  bench_press   49d8a729-f3bf-4fc8-9769-a34f3cd0e20a  2026-03-20
--   933e0c64-ee94-4afd-978f-a620f8723064  belt_squat    81c288aa-d974-4c7c-82ca-098b53dbd6ef  2026-03-21
--   80656df5-0b32-444c-a9bf-d8ea17b2e0f2  decline_press 41abc882-5169-41ae-83ae-3b76b373ec5e  2026-03-21

INSERT INTO public.xp_events (
  id, gym_id, user_id, axis, xp_amount,
  source_type, source_id,
  idempotency_key, exercise_key, equipment_id,
  occurred_at
) VALUES
  (
    gen_random_uuid(),
    'a0000000-0000-0000-0000-000000000001',
    'aa161c54-a91c-4d7b-98c6-219393e9d006',
    'exercise_equipment', 25,
    'session_exercise', '5a9a25a3-b5b0-4fcf-9566-7be3da81f3c3',
    'exercise_equipment:session_exercise:5a9a25a3-b5b0-4fcf-9566-7be3da81f3c3',
    'bench_press', '49d8a729-f3bf-4fc8-9769-a34f3cd0e20a',
    '2026-03-20 00:00:00+00'
  ),
  (
    gen_random_uuid(),
    'a0000000-0000-0000-0000-000000000001',
    'aa161c54-a91c-4d7b-98c6-219393e9d006',
    'exercise_equipment', 25,
    'session_exercise', '933e0c64-ee94-4afd-978f-a620f8723064',
    'exercise_equipment:session_exercise:933e0c64-ee94-4afd-978f-a620f8723064',
    'belt_squat', '81c288aa-d974-4c7c-82ca-098b53dbd6ef',
    '2026-03-21 00:00:00+00'
  ),
  (
    gen_random_uuid(),
    'a0000000-0000-0000-0000-000000000001',
    'aa161c54-a91c-4d7b-98c6-219393e9d006',
    'exercise_equipment', 25,
    'session_exercise', '80656df5-0b32-444c-a9bf-d8ea17b2e0f2',
    'exercise_equipment:session_exercise:80656df5-0b32-444c-a9bf-d8ea17b2e0f2',
    'decline_press', '41abc882-5169-41ae-83ae-3b76b373ec5e',
    '2026-03-21 00:00:00+00'
  )
ON CONFLICT (idempotency_key) DO NOTHING;

-- ─── Step 4: Recompute user_exercise_xp aggregates ───────────────────────────
-- The DB trigger fires on INSERT into xp_events but NOT on UPDATE.
-- Steps 1+2 were UPDATEs — the aggregate table is stale for ironbronz.
-- Recalculate from scratch for both users.

DELETE FROM public.user_exercise_xp
WHERE user_id IN (
  '66c53126-5c07-4d60-a032-afe1febc960d',
  'aa161c54-a91c-4d7b-98c6-219393e9d006'
);

INSERT INTO public.user_exercise_xp (user_id, gym_id, exercise_key, total_xp, updated_at)
SELECT
  user_id,
  gym_id,
  exercise_key,
  SUM(xp_amount) AS total_xp,
  NOW()          AS updated_at
FROM public.xp_events
WHERE axis    = 'exercise_equipment'
  AND user_id IN (
    '66c53126-5c07-4d60-a032-afe1febc960d',
    'aa161c54-a91c-4d7b-98c6-219393e9d006'
  )
GROUP BY user_id, gym_id, exercise_key
ON CONFLICT (user_id, gym_id, exercise_key) DO UPDATE
  SET total_xp   = EXCLUDED.total_xp,
      updated_at = NOW();

-- ─── Verify ───────────────────────────────────────────────────────────────────
-- SELECT xe.user_id, xe.exercise_key, xe.equipment_id, xe.xp_amount
-- FROM   public.xp_events xe
-- WHERE  xe.axis    = 'exercise_equipment'
--   AND  xe.gym_id  = 'a0000000-0000-0000-0000-000000000001'
-- ORDER  BY xe.user_id, xe.exercise_key;
--
-- SELECT uex.user_id, uex.exercise_key, uex.total_xp
-- FROM   public.user_exercise_xp uex
-- WHERE  uex.user_id IN (
--   '66c53126-5c07-4d60-a032-afe1febc960d',  -- ironbronz
--   'aa161c54-a91c-4d7b-98c6-219393e9d006'   -- ironwood
-- )
-- ORDER BY uex.user_id, uex.exercise_key;
