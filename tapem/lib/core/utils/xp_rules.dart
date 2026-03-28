/// Single source of truth for all XP award rules and level mathematics.
///
/// Keep all constants here so future tuning (streak bonuses, milestone grants,
/// level-curve changes) touches exactly one file.
abstract final class XpRules {
  // ─── Award amounts ──────────────────────────────────────────────────────────

  /// XP granted once per unique calendar day on which the user completes at
  /// least one workout session.
  static const int trainingDayBase = 25;

  /// XP granted once per piece of equipment used in a completed session,
  /// regardless of set count.  Anti-cheat: warmup spam yields no bonus.
  static const int exerciseSessionBase = 25;

  /// XP granted per primary muscle group targeted in a completed exercise
  /// (at least one set logged).  Flat rate — set count does not matter.
  static const double muscleGroupPrimaryXp = 10.0;

  /// XP granted per secondary muscle group targeted in a completed exercise.
  /// Lower than [muscleGroupPrimaryXp] to reflect lower training stimulus.
  static const double muscleGroupSecondaryXp = 2.5;

  // ─── Level curves ───────────────────────────────────────────────────────────

  /// XP needed to advance one level on the Training-Days axis.
  /// 100 XP ÷ 25 XP/day = 4 training days per level.
  static const int trainingDayXpPerLevel = 100;

  /// XP needed to advance one level on a per-equipment axis.
  /// 100 XP ÷ 25 XP/session = 4 sessions per level.
  static const int exerciseXpPerLevel = 100;

  /// XP needed to advance one level on the muscle group axis.
  /// 100 XP = 10 primary exercises → level up.
  static const int muscleGroupXpPerLevel = 100;

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// 1-based level for [xp] with [xpPerLevel] required per level.
  static int levelFromXp(int xp, int xpPerLevel) => xp ~/ xpPerLevel + 1;

  /// XP still needed to reach the next level (integer axis).
  static int xpToNextLevel(int xp, int xpPerLevel) =>
      xpPerLevel - (xp % xpPerLevel);

  /// 1-based level for a fractional [xp] value (muscle group axis).
  static int levelFromXpDouble(double xp, int xpPerLevel) =>
      xp.toInt() ~/ xpPerLevel + 1;

  /// XP progress within the current level as a 0.0–1.0 fraction.
  /// Used to fill a progress bar.
  static double levelProgressDouble(double xp, int xpPerLevel) {
    final remainder = xp % xpPerLevel;
    return (remainder / xpPerLevel).clamp(0.0, 1.0);
  }

  /// XP still needed to reach the next level (fractional axis).
  static double xpToNextLevelDouble(double xp, int xpPerLevel) =>
      xpPerLevel - (xp % xpPerLevel);
}
