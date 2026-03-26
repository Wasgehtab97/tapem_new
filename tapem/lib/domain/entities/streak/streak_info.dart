/// Immutable value object representing a user's gym streak state.
///
/// A streak is a chain of training days where no consecutive pair of sessions
/// is separated by more than [StreakInfo.kGracePeriodDays] calendar days.
class StreakInfo {
  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.graceDaysRemaining,
    this.lastTrainingDate,
  });

  /// Maximum allowed gap (in days) between consecutive training sessions
  /// before the chain breaks.
  static const int kGracePeriodDays = 7;

  /// Number of training days in the current unbroken chain.
  final int currentStreak;

  /// All-time maximum [currentStreak] ever reached.
  final int longestStreak;

  /// Days remaining until the streak expires (0–[kGracePeriodDays]).
  ///
  /// 7 = trained today; 1 = must train today or tomorrow; 0 = last day.
  final int graceDaysRemaining;

  /// UTC date of the most recent finished training session.
  final DateTime? lastTrainingDate;

  /// Whether the streak is currently active (at least one session in the chain).
  bool get isActive => currentStreak > 0;

  /// Whether the streak is alive but close to expiring (≤ 3 days of grace left).
  bool get isAtRisk => isActive && graceDaysRemaining <= 3;

  /// Whether the streak expires today (last possible day to train and keep it).
  bool get expiresImminently => isActive && graceDaysRemaining == 0;

  /// Canonical empty / no-history state.
  static const StreakInfo empty = StreakInfo(
    currentStreak: 0,
    longestStreak: 0,
    graceDaysRemaining: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakInfo &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          graceDaysRemaining == other.graceDaysRemaining &&
          lastTrainingDate == other.lastTrainingDate;

  @override
  int get hashCode => Object.hash(
    currentStreak,
    longestStreak,
    graceDaysRemaining,
    lastTrainingDate,
  );
}
