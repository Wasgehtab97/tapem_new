import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/domain/entities/gym/gym_equipment.dart';
import 'package:tapem/presentation/features/workout/providers/equipment_provider.dart';

GymEquipment _equipment({
  required String id,
  required String canonicalName,
  String? manufacturer,
}) => GymEquipment(
  id: id,
  gymId: 'gym-1',
  name: canonicalName,
  equipmentType: EquipmentType.fixedMachine,
  canonicalExerciseKey: 'bench_press',
  manufacturer: manufacturer,
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  group('equipment aliases', () {
    test('applies personal alias while keeping canonical identity', () {
      final canonical = _equipment(
        id: 'eq-1',
        canonicalName: 'Bench Press',
        manufacturer: 'Eleiko',
      );

      final resolved = applyEquipmentAliasMap(
        [canonical],
        {'eq-1': 'My Monday Bench'},
      ).single;

      expect(resolved.id, 'eq-1');
      expect(resolved.name, 'Bench Press');
      expect(resolved.displayName, 'My Monday Bench');
      expect(resolved.hasPersonalNameOverride, isTrue);
    });

    test('reset falls back to canonical name', () {
      final canonical = _equipment(id: 'eq-1', canonicalName: 'Leg Press');
      final withAlias = applyEquipmentAliasMap(
        [canonical],
        {'eq-1': 'Heavy Sled'},
      ).single;
      final reset = applyEquipmentAliasMap([canonical], const {}).single;

      expect(withAlias.displayName, 'Heavy Sled');
      expect(reset.displayName, 'Leg Press');
      expect(reset.hasPersonalNameOverride, isFalse);
      expect(reset.id, canonical.id);
    });

    test('search matches alias, canonical name, and manufacturer once', () {
      final canonical = _equipment(
        id: 'eq-1',
        canonicalName: 'Incline Press',
        manufacturer: 'Nautilus',
      );
      final resolved = applyEquipmentAliasMap(
        [canonical],
        {'eq-1': 'Upper Chest Press'},
      );

      final aliasMatches = resolved
          .where((e) => equipmentMatchesSearchQuery(e, 'upper chest'))
          .toList();
      final canonicalMatches = resolved
          .where((e) => equipmentMatchesSearchQuery(e, 'incline press'))
          .toList();
      final manufacturerMatches = resolved
          .where((e) => equipmentMatchesSearchQuery(e, 'nautilus'))
          .toList();

      expect(aliasMatches, hasLength(1));
      expect(canonicalMatches, hasLength(1));
      expect(manufacturerMatches, hasLength(1));
      expect(aliasMatches.single.id, canonical.id);
      expect(canonicalMatches.single.id, canonical.id);
      expect(manufacturerMatches.single.id, canonical.id);
    });
  });
}
