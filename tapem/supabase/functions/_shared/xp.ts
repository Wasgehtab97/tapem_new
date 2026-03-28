// =============================================================================
// Tap'em — Shared XP constants and calculation logic.
// Single source of truth imported by sync-workout, finish-session, and
// process-xp-event. Mirrors AppConfig.dart + XpRules.dart on the client.
// =============================================================================

export const XP_TRAINING_DAY  = 25;
export const XP_PER_SET_BASE  = 5;
export const XP_EXERCISE_CAP  = 120;

/** Flat XP per primary muscle group per exercise (≥1 set required). */
export const XP_MG_PRIMARY    = 10.0;
/** Flat XP per secondary muscle group per exercise. */
export const XP_MG_SECONDARY  =  2.5;

/** Minimal set shape for sync-workout / finish-session payloads. */
export interface SetLike {
  reps?: number | null;
  duration_seconds?: number | null;
}

/** Set shape used by process-xp-event (pre-classified by isCardio flag). */
export interface SetSummaryLike {
  reps?: number;
  isCardio: boolean;
}

/**
 * Per-set XP formula (authoritative, mirrors XpRules.dart):
 *   Strength set: XP_PER_SET_BASE + floor(reps / 5)
 *   Timed/cardio set: XP_PER_SET_BASE
 *   Total capped at XP_EXERCISE_CAP per exercise.
 *
 * Used by sync-workout and finish-session.
 */
export function calcVariableExerciseXp(sets: SetLike[]): number {
  let total = 0;
  for (const s of sets) {
    const reps = s.reps ?? 0;
    total += s.duration_seconds != null
      ? XP_PER_SET_BASE
      : XP_PER_SET_BASE + Math.floor(reps / 5);
  }
  return Math.min(total, XP_EXERCISE_CAP);
}

/**
 * Identical formula for pre-classified sets (process-xp-event).
 * Uses the isCardio boolean flag instead of duration_seconds presence.
 */
export function calcVariableExerciseXpFromSummary(sets: SetSummaryLike[]): number {
  let total = 0;
  for (const s of sets) {
    const reps = s.reps ?? 0;
    total += s.isCardio ? XP_PER_SET_BASE : XP_PER_SET_BASE + Math.floor(reps / 5);
  }
  return Math.min(total, XP_EXERCISE_CAP);
}
