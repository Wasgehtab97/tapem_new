import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tapem/l10n/generated/app_localizations.dart';
import 'package:tapem/presentation/features/progress/providers/performance_provider.dart';
import 'package:tapem/presentation/features/progress/providers/xp_provider.dart';
import 'package:tapem/presentation/features/progress/screens/progress_screen.dart';
import 'package:tapem/presentation/features/workout/providers/equipment_detail_provider.dart';

E1rmDataPoint _point(String day, double e1rm) => E1rmDataPoint(
  sessionDayAnchor: day,
  e1rm: e1rm,
  weightKg: e1rm / 1.2,
  reps: 6,
);

Widget _buildTestApp({
  required List<ProgressPerformanceExercise> performanceEntries,
}) {
  return ProviderScope(
    overrides: [
      userGymXpProvider.overrideWith((ref) async => null),
      userExerciseXpProvider.overrideWith((ref) async => const <ExerciseXp>[]),
      userMuscleGroupXpProvider.overrideWith(
        (ref) async => const <MuscleGroupXp>[],
      ),
      recentSessionsProvider.overrideWith(
        (ref) async => const <SessionSummary>[],
      ),
      progressPerformanceExercisesProvider.overrideWith(
        (ref) async => performanceEntries,
      ),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProgressScreen(),
    ),
  );
}

void main() {
  testWidgets('performance tile renders, filters, and opens chart detail', (
    tester,
  ) async {
    final entries = [
      ProgressPerformanceExercise.fromPoints(
        exerciseKey: 'fixed:bench_press',
        displayName: 'Bench Press',
        points: [
          _point('2026-01-01', 90),
          _point('2026-02-01', 100),
          _point('2026-03-01', 112),
        ],
      ),
      ProgressPerformanceExercise.fromPoints(
        exerciseKey: 'custom:uuid-1',
        displayName: 'Cable Lateral Raise',
        points: [_point('2026-02-01', 22), _point('2026-03-01', 24)],
      ),
    ];

    await tester.pumpWidget(_buildTestApp(performanceEntries: entries));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('progress-performance-tile')), findsOneWidget);
    expect(find.text('PERFORMANCE'), findsOneWidget);

    await tester.tap(find.byKey(const Key('progress-performance-tile')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('progress-performance-list-sheet')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('progress-performance-search')),
      'bench',
    );
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('progress-performance-list-sheet'));
    expect(
      find.descendant(of: sheet, matching: find.text('Bench Press')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Cable Lateral Raise')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('progress-performance-row-0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('progress-performance-detail-sheet')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('e1rm-progress-chart')), findsOneWidget);
  });
}
