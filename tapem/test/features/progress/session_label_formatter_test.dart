import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/data/datasources/local/app_database.dart';
import 'package:tapem/presentation/features/progress/providers/xp_provider.dart';

LocalGymEquipmentData _equipment({
  required String id,
  required String name,
  required String type,
  String? manufacturer,
}) {
  return LocalGymEquipmentData(
    id: id,
    gymId: 'gym-1',
    name: name,
    equipmentType: type,
    zoneName: 'A',
    nfcTagUid: null,
    canonicalExerciseKey: null,
    rankingEligibleOverride: null,
    manufacturer: manufacturer,
    isActive: true,
    cachedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  test('fixed equipment label uses effective name + manufacturer only', () {
    final byId = {
      'eq-fixed': _equipment(
        id: 'eq-fixed',
        name: 'Bench Press',
        type: 'fixed_machine',
        manufacturer: 'Hammer Strength',
      ),
    };

    final label = formatSessionExerciseLabel(
      displayName: 'Bench Press',
      equipmentId: 'eq-fixed',
      equipmentById: byId,
      equipmentAliasesById: const {'eq-fixed': 'Benchpress Main'},
    );

    expect(label, 'Benchpress Main · Hammer Strength');
  });

  test('open station label includes exercise + station + manufacturer', () {
    final byId = {
      'eq-open': _equipment(
        id: 'eq-open',
        name: 'Cable Tower',
        type: 'open_station',
        manufacturer: 'Life Fitness',
      ),
    };

    final label = formatSessionExerciseLabel(
      displayName: 'Flys',
      equipmentId: 'eq-open',
      equipmentById: byId,
      equipmentAliasesById: const {},
    );

    expect(label, 'Flys · Cable Tower · Life Fitness');
  });

  test('equipment context label uses same effective naming rules', () {
    final byId = {
      'eq-open': _equipment(
        id: 'eq-open',
        name: 'Cable Tower',
        type: 'open_station',
        manufacturer: 'Life Fitness',
      ),
    };

    final context = exerciseEquipmentContextLabel(
      equipmentId: 'eq-open',
      equipmentById: byId,
      equipmentAliasesById: const {'eq-open': 'Cable Pull Station'},
    );

    expect(context, 'Cable Pull Station · Life Fitness');
  });
}
