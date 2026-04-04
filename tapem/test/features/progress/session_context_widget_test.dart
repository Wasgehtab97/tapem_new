import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tapem/data/datasources/local/app_database.dart';
import 'package:tapem/l10n/generated/app_localizations.dart';
import 'package:tapem/presentation/features/progress/providers/performance_provider.dart';
import 'package:tapem/presentation/features/progress/providers/xp_provider.dart';
import 'package:tapem/presentation/features/progress/screens/progress_screen.dart';
import 'package:tapem/presentation/features/progress/widgets/session_detail_sheet.dart';

Widget _progressApp({required List<SessionSummary> sessions}) {
  return ProviderScope(
    overrides: [
      userGymXpProvider.overrideWith((ref) async => null),
      userExerciseXpProvider.overrideWith((ref) async => const <ExerciseXp>[]),
      userMuscleGroupXpProvider.overrideWith(
        (ref) async => const <MuscleGroupXp>[],
      ),
      progressPerformanceExercisesProvider.overrideWith(
        (ref) async => const <ProgressPerformanceExercise>[],
      ),
      recentSessionsProvider.overrideWith((ref) async => sessions),
      allSessionsProvider.overrideWith((ref) async => sessions),
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
  testWidgets('recent session summary shows precise equipment context', (
    tester,
  ) async {
    final sessions = [
      SessionSummary(
        id: 'session-1',
        sessionDayAnchor: '2026-03-20',
        startedAt: DateTime(2026, 3, 20, 8),
        finishedAt: DateTime(2026, 3, 20, 9),
        exerciseLabels: const ['Bench Press · Bench Alpha · Hammer Strength'],
        totalSets: 5,
      ),
    ];

    await tester.pumpWidget(_progressApp(sessions: sessions));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('SEE ALL'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Hammer Strength'), findsOneWidget);
  });

  testWidgets('session detail shows equipment/manufacturer context label', (
    tester,
  ) async {
    const exercise = ExerciseWithSets(
      displayName: 'Bench Press',
      equipmentContextLabel: 'Bench Alpha · Hammer Strength',
      sets: <LocalSetEntry>[],
      previousSets: <LocalSetEntry>[],
      previousBestE1rm: null,
      previousBestVolume: null,
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SessionDetailExerciseBlock(exercise: exercise),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bench Alpha · Hammer Strength'), findsOneWidget);
  });
}
