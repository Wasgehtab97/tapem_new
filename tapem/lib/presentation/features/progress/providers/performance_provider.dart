import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_service.dart';
import '../../../../core/services/gym_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../workout/providers/equipment_detail_provider.dart';

class ProgressPerformanceExercise {
  const ProgressPerformanceExercise({
    required this.exerciseKey,
    required this.displayName,
    required this.points,
    required this.trendScore,
    required this.absoluteGainKg,
    required this.relativeGain,
    required this.confidence,
    required this.latestE1rm,
    required this.bestE1rm,
    required this.baselineE1rm,
    required this.recentE1rm,
    required this.hasTrendData,
  });

  factory ProgressPerformanceExercise.fromPoints({
    required String exerciseKey,
    required String displayName,
    required List<E1rmDataPoint> points,
  }) {
    final sorted = [...points]
      ..sort((a, b) => a.sessionDayAnchor.compareTo(b.sessionDayAnchor));
    final pointCount = sorted.length;
    final hasTrendData = pointCount >= 2;

    final baselineWindow = sorted
        .take(math.min(3, pointCount))
        .map((p) => p.e1rm)
        .toList();
    final recentWindow = sorted
        .skip(math.max(0, pointCount - 3))
        .map((p) => p.e1rm)
        .toList();

    final baselineE1rm = baselineWindow.isEmpty
        ? null
        : medianValue(baselineWindow);
    final recentE1rm = recentWindow.isEmpty ? null : medianValue(recentWindow);
    final absoluteGainKg = baselineE1rm == null || recentE1rm == null
        ? 0.0
        : recentE1rm - baselineE1rm;
    final relativeGain = baselineE1rm == null
        ? 0.0
        : absoluteGainKg / math.max(baselineE1rm, 1.0);
    final confidence = ((pointCount / 6.0).clamp(0.25, 1.0)).toDouble();
    final trendScore = hasTrendData ? relativeGain * confidence : 0.0;

    final latestE1rm = sorted.isEmpty ? null : sorted.last.e1rm;
    final bestE1rm = sorted.isEmpty
        ? null
        : sorted.fold<double>(0, (m, p) => p.e1rm > m ? p.e1rm : m);

    return ProgressPerformanceExercise(
      exerciseKey: exerciseKey,
      displayName: displayName,
      points: sorted,
      trendScore: trendScore,
      absoluteGainKg: absoluteGainKg,
      relativeGain: relativeGain,
      confidence: confidence,
      latestE1rm: latestE1rm,
      bestE1rm: bestE1rm,
      baselineE1rm: baselineE1rm,
      recentE1rm: recentE1rm,
      hasTrendData: hasTrendData,
    );
  }

  final String exerciseKey;
  final String displayName;
  final List<E1rmDataPoint> points;

  /// Deterministic rank score based on relative gain and sample confidence.
  final double trendScore;
  final double absoluteGainKg;
  final double relativeGain;
  final double confidence;

  final double? latestE1rm;
  final double? bestE1rm;
  final double? baselineE1rm;
  final double? recentE1rm;
  final bool hasTrendData;

  int get trackedSessionsCount => points.length;
}

@visibleForTesting
double medianValue(List<double> values) {
  if (values.isEmpty) return 0.0;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2.0;
}

@visibleForTesting
List<ProgressPerformanceExercise> sortProgressPerformanceExercises(
  Iterable<ProgressPerformanceExercise> entries,
) {
  final sorted = entries.toList();
  sorted.sort((a, b) {
    if (a.hasTrendData != b.hasTrendData) {
      return a.hasTrendData ? -1 : 1;
    }

    final trendCmp = b.trendScore.compareTo(a.trendScore);
    if (trendCmp != 0) return trendCmp;

    final absCmp = b.absoluteGainKg.compareTo(a.absoluteGainKg);
    if (absCmp != 0) return absCmp;

    final latestCmp = (b.latestE1rm ?? double.negativeInfinity).compareTo(
      a.latestE1rm ?? double.negativeInfinity,
    );
    if (latestCmp != 0) return latestCmp;

    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
  return sorted;
}

typedef _BestPerDayMeta = ({double e1rm, double weightKg, int reps});

class _ExerciseAggregation {
  _ExerciseAggregation({required this.displayName});

  String displayName;
  final Map<String, _BestPerDayMeta> bestByDay = <String, _BestPerDayMeta>{};
}

final progressPerformanceExercisesProvider =
    FutureProvider<List<ProgressPerformanceExercise>>((ref) async {
      final user = ref.watch(currentUserProvider);
      final gymId = ref.watch(activeGymIdProvider);
      if (user == null || gymId == null) return [];

      final db = ref.watch(appDatabaseProvider);
      final client = ref.watch(supabaseClientProvider);

      final map = <String, _ExerciseAggregation>{};

      void ingest({
        required String exerciseKeyRaw,
        required String displayNameRaw,
        required String sessionDayAnchor,
        required int? reps,
        required double? weightKg,
      }) {
        final exerciseKey = exerciseKeyRaw.trim();
        if (exerciseKey.isEmpty || exerciseKey.startsWith('cardio:')) return;

        final displayName = displayNameRaw.trim();
        final agg = map.putIfAbsent(
          exerciseKey,
          () => _ExerciseAggregation(
            displayName: displayName.isEmpty ? exerciseKey : displayName,
          ),
        );
        if (displayName.isNotEmpty) agg.displayName = displayName;

        if (reps == null || weightKg == null || reps <= 0 || weightKg <= 0) {
          return;
        }

        final e1rm = weightKg * (1 + reps / 30.0);
        final prev = agg.bestByDay[sessionDayAnchor];
        if (prev == null || e1rm > prev.e1rm) {
          agg.bestByDay[sessionDayAnchor] = (
            e1rm: e1rm,
            weightKg: weightKg,
            reps: reps,
          );
        }
      }

      final localRows = await db.getFinishedExerciseSetRows(gymId, user.id);
      for (final row in localRows) {
        ingest(
          exerciseKeyRaw: row.exerciseKey,
          displayNameRaw: row.displayName,
          sessionDayAnchor: row.sessionDayAnchor,
          reps: row.reps,
          weightKg: row.weightKg,
        );
      }

      // get_user_exercise_performance_summary returns the best e1rm set per
      // (exercise_key, session_day_anchor), pre-aggregated server-side.
      // Payload: ~600 rows × 80 bytes ≈ 50 KB (was: 250 sessions × nested
      // exercises × sets ≈ 250 KB, or 1 000 rows on reinstall ≈ 750 KB).
      // ingest() is idempotent (keeps best e1rm per day), so overlap with
      // local SQLite rows is harmless — the best value wins.
      try {
        final remoteRows = await client.rpc(
          'get_user_exercise_performance_summary',
          params: {'p_user_id': user.id, 'p_gym_id': gymId},
        );

        for (final row in (remoteRows as List)) {
          final r = Map<String, Object?>.from(row as Map);
          final sessionDayAnchor = r['session_day_anchor'] as String? ?? '';
          if (sessionDayAnchor.isEmpty) continue;

          ingest(
            exerciseKeyRaw: r['exercise_key'] as String? ?? '',
            displayNameRaw: r['display_name'] as String? ?? '',
            sessionDayAnchor: sessionDayAnchor,
            reps: (r['best_reps'] as num?)?.toInt(),
            weightKg: (r['best_weight_kg'] as num?)?.toDouble(),
          );
        }
      } catch (_) {
        // Offline: local rows already provide immediate performance feedback.
      }

      final entries = map.entries.map((entry) {
        final points = entry.value.bestByDay.entries
            .map(
              (e) => E1rmDataPoint(
                sessionDayAnchor: e.key,
                e1rm: e.value.e1rm,
                weightKg: e.value.weightKg,
                reps: e.value.reps,
              ),
            )
            .toList();

        return ProgressPerformanceExercise.fromPoints(
          exerciseKey: entry.key,
          displayName: entry.value.displayName,
          points: points,
        );
      });

      return sortProgressPerformanceExercises(entries);
    });
