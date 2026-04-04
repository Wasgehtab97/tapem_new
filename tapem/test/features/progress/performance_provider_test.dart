import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/presentation/features/progress/providers/performance_provider.dart';
import 'package:tapem/presentation/features/workout/providers/equipment_detail_provider.dart';

E1rmDataPoint _pt(String day, double e1rm) => E1rmDataPoint(
  sessionDayAnchor: day,
  e1rm: e1rm,
  weightKg: e1rm / 1.2,
  reps: 6,
);

void main() {
  group('Progress performance sorting', () {
    test('improving exercise ranks above stagnant exercise', () {
      final improving = ProgressPerformanceExercise.fromPoints(
        exerciseKey: 'fixed:bench_press',
        displayName: 'Bench Press',
        points: [
          _pt('2026-01-01', 100),
          _pt('2026-02-01', 112),
          _pt('2026-03-01', 124),
        ],
      );
      final stagnant = ProgressPerformanceExercise.fromPoints(
        exerciseKey: 'fixed:lat_pull',
        displayName: 'Lat Pulldown',
        points: [
          _pt('2026-01-01', 80),
          _pt('2026-02-01', 80.5),
          _pt('2026-03-01', 80.0),
        ],
      );

      final sorted = sortProgressPerformanceExercises([stagnant, improving]);
      expect(sorted.first.exerciseKey, improving.exerciseKey);
    });

    test('declining exercise ranks below improving exercise', () {
      final improving = ProgressPerformanceExercise.fromPoints(
        exerciseKey: 'fixed:row',
        displayName: 'Row',
        points: [
          _pt('2026-01-01', 70),
          _pt('2026-02-01', 80),
          _pt('2026-03-01', 92),
        ],
      );
      final declining = ProgressPerformanceExercise.fromPoints(
        exerciseKey: 'fixed:press',
        displayName: 'Shoulder Press',
        points: [
          _pt('2026-01-01', 70),
          _pt('2026-02-01', 65),
          _pt('2026-03-01', 60),
        ],
      );

      final sorted = sortProgressPerformanceExercises([declining, improving]);
      expect(sorted.last.exerciseKey, declining.exerciseKey);
    });

    test(
      'insufficient-data exercises are sorted after trend-data exercises',
      () {
        final withTrend = ProgressPerformanceExercise.fromPoints(
          exerciseKey: 'custom:a',
          displayName: 'Custom A',
          points: [_pt('2026-02-01', 40), _pt('2026-03-01', 48)],
        );
        final insufficient = ProgressPerformanceExercise.fromPoints(
          exerciseKey: 'custom:b',
          displayName: 'Custom B',
          points: [_pt('2026-03-01', 50)],
        );

        final sorted = sortProgressPerformanceExercises([
          insufficient,
          withTrend,
        ]);
        expect(sorted.first.hasTrendData, isTrue);
        expect(sorted.last.hasTrendData, isFalse);
      },
    );

    test('tie-break is deterministic by latest e1rm then name', () {
      final sameScoreA = ProgressPerformanceExercise(
        exerciseKey: 'exercise:a',
        displayName: 'A Raise',
        points: [_pt('2026-01-01', 10), _pt('2026-02-01', 12)],
        trendScore: 0.2,
        absoluteGainKg: 2,
        relativeGain: 0.2,
        confidence: 1,
        latestE1rm: 90,
        bestE1rm: 90,
        baselineE1rm: 80,
        recentE1rm: 82,
        hasTrendData: true,
      );
      final sameScoreB = ProgressPerformanceExercise(
        exerciseKey: 'exercise:b',
        displayName: 'B Raise',
        points: [_pt('2026-01-01', 10), _pt('2026-02-01', 12)],
        trendScore: 0.2,
        absoluteGainKg: 2,
        relativeGain: 0.2,
        confidence: 1,
        latestE1rm: 88,
        bestE1rm: 88,
        baselineE1rm: 80,
        recentE1rm: 82,
        hasTrendData: true,
      );
      final sameScoreSameLatestNameB = ProgressPerformanceExercise(
        exerciseKey: 'exercise:c',
        displayName: 'C Raise',
        points: [_pt('2026-01-01', 10), _pt('2026-02-01', 12)],
        trendScore: 0.2,
        absoluteGainKg: 2,
        relativeGain: 0.2,
        confidence: 1,
        latestE1rm: 88,
        bestE1rm: 88,
        baselineE1rm: 80,
        recentE1rm: 82,
        hasTrendData: true,
      );

      final sorted = sortProgressPerformanceExercises([
        sameScoreSameLatestNameB,
        sameScoreB,
        sameScoreA,
      ]);

      expect(sorted[0].exerciseKey, sameScoreA.exerciseKey);
      expect(sorted[1].displayName, 'B Raise');
      expect(sorted[2].displayName, 'C Raise');
    });
  });
}
