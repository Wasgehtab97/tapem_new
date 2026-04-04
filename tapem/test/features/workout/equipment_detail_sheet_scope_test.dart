import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapem/core/services/gym_service.dart';
import 'package:tapem/domain/entities/gym/gym_equipment.dart';
import 'package:tapem/l10n/generated/app_localizations.dart';
import 'package:tapem/presentation/features/auth/providers/auth_provider.dart';
import 'package:tapem/presentation/features/progress/providers/xp_provider.dart';
import 'package:tapem/presentation/features/workout/providers/equipment_detail_provider.dart';
import 'package:tapem/presentation/features/workout/providers/equipment_provider.dart';
import 'package:tapem/presentation/features/workout/widgets/equipment_detail_sheet.dart';

E1rmDataPoint _point(String day, double e1rm) => E1rmDataPoint(
  sessionDayAnchor: day,
  e1rm: e1rm,
  weightKg: e1rm / 1.2,
  reps: 6,
);

GymEquipment _equipment({required String id, required String manufacturer}) {
  return GymEquipment(
    id: id,
    gymId: 'gym-1',
    name: 'Bench Press',
    equipmentType: EquipmentType.fixedMachine,
    canonicalExerciseKey: 'fixed:bench_press',
    manufacturer: manufacturer,
    isActive: true,
    createdAt: DateTime(2026),
  );
}

Widget _buildApp({
  required SharedPreferences prefs,
  required GymEquipment equipment,
}) {
  final equipmentById = {
    'bench-a': _equipment(id: 'bench-a', manufacturer: 'Hammer Strength'),
    'bench-b': _equipment(id: 'bench-b', manufacturer: 'Technogym'),
  };

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWith((ref) => null),
      equipmentByIdProvider.overrideWith((ref, args) async {
        return equipmentById[args.equipmentId];
      }),
      customExercisesForEquipmentProvider.overrideWith(
        (ref, args) async => const <CustomExerciseSummary>[],
      ),
      exerciseKeyHistoryProvider.overrideWith(
        (ref, args) async => const <EquipmentHistorySummary>[],
      ),
      equipmentHistoryProvider.overrideWith(
        (ref, args) async => const <EquipmentHistorySummary>[],
      ),
      userExerciseXpProvider.overrideWith((ref) async => const <ExerciseXp>[]),
      equipmentRankingProvider.overrideWith(
        (ref, args) async => const <EquipmentRankingEntry>[],
      ),
      exerciseMuscleGroupsProvider.overrideWith(
        (ref, args) async => const <ExerciseMuscleGroupEntry>[],
      ),
      e1rmChartProvider.overrideWith((ref, args) async {
        if (args.scope.equipmentId == 'bench-a') {
          return [_point('2026-01-01', 90), _point('2026-02-01', 110)];
        }
        if (args.scope.equipmentId == 'bench-b') {
          return [_point('2026-01-01', 70)];
        }
        return const <E1rmDataPoint>[];
      }),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EquipmentDetailSheet(equipment: equipment, gymId: 'gym-1'),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('equipment detail shows scoped e1RM chart per fixed machine id', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        equipment: _equipment(id: 'bench-a', manufacturer: 'Hammer Strength'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('e1rm-progress-chart')), findsOneWidget);
    expect(find.byKey(const Key('e1rm-progress-empty')), findsNothing);

    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        equipment: _equipment(id: 'bench-b', manufacturer: 'Technogym'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('e1rm-progress-chart')), findsOneWidget);
    expect(find.byKey(const Key('e1rm-progress-empty')), findsNothing);
  });
}
