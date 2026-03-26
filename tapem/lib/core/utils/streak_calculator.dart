import '../../domain/entities/streak/streak_info.dart';

/// Pure, deterministic, stateless streak computation engine.
///
/// All public methods are free of side effects and depend only on their
/// arguments, making them trivially unit-testable.
///
/// ## Streak definition
/// Two consecutive training sessions are "linked" when the gap between their
/// dates is ≤ [StreakInfo.kGracePeriodDays] calendar days.
/// The *current streak* is the length of the chain that includes the most
/// recent session, provided that session is itself within the grace window
/// of today.
abstract final class StreakCalculator {
  /// Computes [StreakInfo] from an arbitrary set of training date strings.
  ///
  /// [trainingDateStrings] — collection of 'yyyy-MM-dd' strings (may contain
  ///   duplicates; duplicates are deduplicated before calculation).
  ///
  /// [today] — injectable for deterministic unit testing.
  ///   Defaults to [DateTime.now()] normalized to UTC midnight.
  ///
  /// Returns [StreakInfo.empty] when [trainingDateStrings] is empty.
  static StreakInfo compute(
    Iterable<String> trainingDateStrings, {
    DateTime? today,
  }) {
    if (trainingDateStrings.isEmpty) return StreakInfo.empty;

    final nowUtcMidnight = _utcMidnight(today ?? DateTime.now());

    // Parse, deduplicate, sort descending (most-recent first).
    final dates = trainingDateStrings
        .map(_parseUtcDate)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final lastTraining = dates.first;
    final daysSinceLast = nowUtcMidnight.difference(lastTraining).inDays;

    // ── Longest streak (full history) ────────────────────────────────────
    final longest = _computeLongest(dates);

    // ── Current streak ────────────────────────────────────────────────────
    if (daysSinceLast > StreakInfo.kGracePeriodDays) {
      // Streak window expired — chain is dead.
      return StreakInfo(
        currentStreak: 0,
        longestStreak: longest,
        graceDaysRemaining: 0,
        lastTrainingDate: lastTraining,
      );
    }

    final current = _countChainFromStart(dates);
    final graceRemaining =
        (StreakInfo.kGracePeriodDays - daysSinceLast).clamp(0, StreakInfo.kGracePeriodDays);

    return StreakInfo(
      currentStreak: current,
      longestStreak: longest,
      graceDaysRemaining: graceRemaining,
      lastTrainingDate: lastTraining,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Counts the contiguous chain starting at index 0 of [dates] (sorted
  /// descending).  Stops as soon as a gap exceeds [StreakInfo.kGracePeriodDays].
  static int _countChainFromStart(List<DateTime> dates) {
    var count = 1;
    for (var i = 0; i < dates.length - 1; i++) {
      final gap = dates[i].difference(dates[i + 1]).inDays;
      if (gap <= StreakInfo.kGracePeriodDays) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Finds the longest contiguous chain across all of [dates].
  static int _computeLongest(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    var longest = 1;
    var run = 1;
    for (var i = 0; i < dates.length - 1; i++) {
      final gap = dates[i].difference(dates[i + 1]).inDays;
      if (gap <= StreakInfo.kGracePeriodDays) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    return longest;
  }

  /// Parses a 'yyyy-MM-dd' string into a UTC midnight [DateTime].
  static DateTime _parseUtcDate(String dateStr) {
    final parts = dateStr.split('-');
    assert(parts.length == 3, 'Expected yyyy-MM-dd format, got: $dateStr');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Normalises any [DateTime] to UTC midnight (discards time-of-day).
  static DateTime _utcMidnight(DateTime dt) =>
      DateTime.utc(dt.year, dt.month, dt.day);
}
