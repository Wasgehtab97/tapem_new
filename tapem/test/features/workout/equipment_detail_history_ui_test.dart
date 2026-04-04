import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapem/core/services/gym_service.dart';
import 'package:tapem/data/datasources/local/app_database.dart';
import 'package:tapem/domain/entities/gym/gym_equipment.dart';
import 'package:tapem/l10n/generated/app_localizations.dart';
import 'package:tapem/presentation/features/auth/providers/auth_provider.dart';
import 'package:tapem/presentation/features/progress/providers/xp_provider.dart';
import 'package:tapem/presentation/features/workout/providers/equipment_detail_provider.dart';
import 'package:tapem/presentation/features/workout/providers/equipment_provider.dart';
import 'package:tapem/presentation/features/workout/widgets/equipment_detail_sheet.dart';

LocalSetEntry _set(int number, {int? reps, double? weightKg}) => LocalSetEntry(
  id: 'set-$number',
  sessionExerciseId: 'ex-1',
  gymId: 'gym-1',
  setNumber: number,
  reps: reps,
  weightKg: weightKg,
  durationSeconds: null,
  distanceMeters: null,
  notes: null,
  syncStatus: 'sync_confirmed',
  loggedAt: DateTime(2026, 3, 1, 10, number),
  idempotencyKey: 'ik-$number',
);

final _openEquipment = GymEquipment(
  id: 'open-1',
  gymId: 'gym-1',
  name: 'Cable Tower',
  equipmentType: EquipmentType.openStation,
  manufacturer: 'Life Fitness',
  isActive: true,
  createdAt: DateTime(2026),
);

final _fixedEquipment = GymEquipment(
  id: 'fixed-1',
  gymId: 'gym-1',
  name: 'Bench Main',
  equipmentType: EquipmentType.fixedMachine,
  canonicalExerciseKey: 'bench_press',
  manufacturer: 'Eleiko',
  isActive: true,
  createdAt: DateTime(2026),
);

Widget _buildApp(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWith((ref) => null),
      equipmentByIdProvider.overrideWith((ref, args) async => _openEquipment),
      customExercisesForEquipmentProvider.overrideWith(
        (ref, args) async => const [
          CustomExerciseSummary(exerciseKey: 'custom:flys', name: 'Flys'),
          CustomExerciseSummary(
            exerciseKey: 'custom:lateral_raise',
            name: 'Lateral Raise',
          ),
        ],
      ),
      exerciseKeyHistoryProvider.overrideWith((ref, args) async {
        if (args.exerciseKey == 'custom:flys') {
          return [
            EquipmentHistorySummary(
              sessionId: 'fly-session',
              sessionExerciseId: 'fly-ex-1',
              exerciseName: 'Flys',
              sessionDayAnchor: '2026-03-01',
              startedAt: DateTime(2026, 3, 1, 10, 0),
              finishedAt: DateTime(2026, 3, 1, 10, 40),
              setCount: 3,
              totalReps: 9,
              totalVolumeKg: 297,
              totalXp: 25,
            ),
          ];
        }
        return const <EquipmentHistorySummary>[];
      }),
      equipmentHistoryProvider.overrideWith(
        (ref, args) async => [
          EquipmentHistorySummary(
            sessionId: 'aggregated-session',
            sessionDayAnchor: '2026-03-01',
            startedAt: DateTime(2026, 3, 1, 10, 0),
            finishedAt: DateTime(2026, 3, 1, 11, 0),
            setCount: 5,
            totalReps: 36,
            totalVolumeKg: 1755,
            totalXp: 50,
          ),
        ],
      ),
      equipmentHistoryDetailProvider.overrideWith((ref, args) async {
        if (args.sessionId != 'fly-session') return null;
        return EquipmentHistoryDetail(
          sessionId: 'fly-session',
          sessionDayAnchor: '2026-03-01',
          startedAt: DateTime(2026, 3, 1, 10, 0),
          finishedAt: DateTime(2026, 3, 1, 10, 40),
          exerciseName: 'Flys',
          sets: [
            _set(1, reps: 12, weightKg: 22),
            _set(2, reps: 10, weightKg: 24),
          ],
          totalReps: 22,
          totalVolumeKg: 504,
          totalXp: 25,
        );
      }),
      e1rmChartProvider.overrideWith((ref, args) async => const []),
      userExerciseXpProvider.overrideWith((ref) async => const <ExerciseXp>[]),
      equipmentRankingProvider.overrideWith(
        (ref, args) async => const <EquipmentRankingEntry>[],
      ),
      exerciseMuscleGroupsProvider.overrideWith(
        (ref, args) async => const <ExerciseMuscleGroupEntry>[],
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EquipmentDetailSheet(equipment: _openEquipment, gymId: 'gym-1'),
      ),
    ),
  );
}

Widget _buildFixedApp(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWith((ref) => null),
      equipmentByIdProvider.overrideWith((ref, args) async => _fixedEquipment),
      customExercisesForEquipmentProvider.overrideWith(
        (ref, args) async => const <CustomExerciseSummary>[],
      ),
      exerciseKeyHistoryProvider.overrideWith((ref, args) async {
        if (args.exerciseKey == 'bench_press' &&
            args.equipmentId == _fixedEquipment.id) {
          return [
            EquipmentHistorySummary(
              sessionId: 'fixed-session',
              sessionExerciseId: 'fixed-ex-1',
              exerciseName: 'Bench Main',
              sessionDayAnchor: '2026-03-01',
              startedAt: DateTime(2026, 3, 1, 10, 0),
              finishedAt: DateTime(2026, 3, 1, 10, 40),
              setCount: 3,
              totalReps: 9,
              totalVolumeKg: 297,
              totalXp: 25,
            ),
          ];
        }
        return const <EquipmentHistorySummary>[];
      }),
      equipmentHistoryProvider.overrideWith(
        (ref, args) async => [
          EquipmentHistorySummary(
            sessionId: 'aggregated-session',
            sessionDayAnchor: '2026-03-01',
            startedAt: DateTime(2026, 3, 1, 10, 0),
            finishedAt: DateTime(2026, 3, 1, 11, 0),
            setCount: 5,
            totalReps: 36,
            totalVolumeKg: 1755,
            totalXp: 50,
          ),
        ],
      ),
      equipmentHistoryDetailProvider.overrideWith((ref, args) async {
        if (args.sessionId != 'fixed-session') return null;
        return EquipmentHistoryDetail(
          sessionId: 'fixed-session',
          sessionDayAnchor: '2026-03-01',
          startedAt: DateTime(2026, 3, 1, 10, 0),
          finishedAt: DateTime(2026, 3, 1, 10, 40),
          exerciseName: 'Bench Main',
          sets: [
            _set(1, reps: 12, weightKg: 22),
            _set(2, reps: 10, weightKg: 24),
          ],
          totalReps: 22,
          totalVolumeKg: 504,
          totalXp: 25,
        );
      }),
      e1rmChartProvider.overrideWith((ref, args) async => const []),
      userExerciseXpProvider.overrideWith((ref) async => const <ExerciseXp>[]),
      equipmentRankingProvider.overrideWith(
        (ref, args) async => const <EquipmentRankingEntry>[],
      ),
      exerciseMuscleGroupsProvider.overrideWith(
        (ref, args) async => const <ExerciseMuscleGroupEntry>[],
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EquipmentDetailSheet(equipment: _fixedEquipment, gymId: 'gym-1'),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'open-station history is exercise-scoped and not mixed with aggregated all-session rows',
    (tester) async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(prefs));
      await tester.pumpAndSettle();

      expect(
        find.text('Select an exercise to view its history.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('equipment-history-row-aggregated-session')),
        findsNothing,
      );

      await tester.tap(find.text('Flys'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('equipment-history-row-fly-session')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('equipment-history-row-aggregated-session')),
        findsNothing,
      );
    },
  );

  testWidgets('tapping history row opens set-level history detail sheet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flys'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('equipment-history-row-fly-session')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('equipment-history-detail-sheet')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('history-detail-set-1')), findsOneWidget);
    expect(find.byKey(const Key('history-detail-set-2')), findsOneWidget);
  });

  testWidgets(
    'fixed-equipment history uses exercise-scoped rows and supports drill-down',
    (tester) async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildFixedApp(prefs));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('equipment-history-row-fixed-session')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('equipment-history-row-aggregated-session')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const Key('equipment-history-row-fixed-session')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('equipment-history-detail-sheet')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('history-detail-set-1')), findsOneWidget);
    },
  );
}
