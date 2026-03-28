-- =============================================================================
-- Tap'em — Add adductors & abductors as distinct muscle groups
--
-- hip_adduction was incorrectly mapped to 'quads'.
-- hip_abduction was mapped to 'glutes' (acceptable but imprecise).
-- Both now get their own dedicated muscle group keys.
-- =============================================================================

-- ─── Fix hip_adduction: quads → adductors ────────────────────────────────────

UPDATE public.exercise_muscle_groups
   SET muscle_group = 'adductors'
 WHERE exercise_key = 'hip_adduction'
   AND muscle_group = 'quads';

-- ─── Fix hip_abduction: glutes → abductors ───────────────────────────────────

UPDATE public.exercise_muscle_groups
   SET muscle_group = 'abductors'
 WHERE exercise_key = 'hip_abduction'
   AND muscle_group = 'glutes';

-- ─── Backfill any existing XP events that used the old muscle group keys ─────
--
-- If users have already synced sessions on these machines, their xp_events
-- rows still reference 'quads' / 'glutes'. Re-label them so the recompute
-- function produces correct user_muscle_group_xp aggregates.

UPDATE public.xp_events
   SET muscle_group = 'adductors'
 WHERE exercise_key = 'hip_adduction'
   AND muscle_group = 'quads'
   AND axis = 'muscle_group';

UPDATE public.xp_events
   SET muscle_group = 'abductors'
 WHERE exercise_key = 'hip_abduction'
   AND muscle_group = 'glutes'
   AND axis = 'muscle_group';

-- ─── Recompute affected users' muscle-group XP aggregates ────────────────────
--
-- Only users who have xp_events for these two exercises need recomputing.
-- The DO block collects distinct (user_id, gym_id) pairs and calls
-- recompute_user_gym_xp for each.

DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, gym_id
      FROM public.xp_events
     WHERE exercise_key IN ('hip_adduction', 'hip_abduction')
       AND axis = 'muscle_group'
  LOOP
    PERFORM public.recompute_user_gym_xp(rec.user_id, rec.gym_id);
  END LOOP;
END;
$$;
