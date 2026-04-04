import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/presentation/features/workout/providers/equipment_detail_provider.dart';

ScopedSetSample _sample({
  required String exerciseKey,
  required String? equipmentId,
  required String day,
  required int reps,
  required double weightKg,
}) {
  return ScopedSetSample(
    exerciseKey: exerciseKey,
    equipmentId: equipmentId,
    sessionDayAnchor: day,
    reps: reps,
    weightKg: weightKg,
  );
}

void main() {
  group('equipment-scoped e1RM aggregation', () {
    test('same exercise key is isolated across fixed equipment ids', () {
      final samples = [
        _sample(
          exerciseKey: 'fixed:bench_press',
          equipmentId: 'bench-a',
          day: '2026-01-01',
          reps: 5,
          weightKg: 100,
        ),
        _sample(
          exerciseKey: 'fixed:bench_press',
          equipmentId: 'bench-a',
          day: '2026-02-01',
          reps: 5,
          weightKg: 110,
        ),
        _sample(
          exerciseKey: 'fixed:bench_press',
          equipmentId: 'bench-b',
          day: '2026-01-01',
          reps: 5,
          weightKg: 80,
        ),
        _sample(
          exerciseKey: 'fixed:bench_press',
          equipmentId: 'bench-b',
          day: '2026-02-01',
          reps: 5,
          weightKg: 84,
        ),
      ];

      final machineA = aggregateScopedE1rmPoints(
        samples: samples,
        scope: const PerformanceScope.fixedEquipment(
          exerciseKey: 'fixed:bench_press',
          equipmentId: 'bench-a',
        ),
        includeLegacyEquipmentlessRows: false,
      );

      final machineB = aggregateScopedE1rmPoints(
        samples: samples,
        scope: const PerformanceScope.fixedEquipment(
          exerciseKey: 'fixed:bench_press',
          equipmentId: 'bench-b',
        ),
        includeLegacyEquipmentlessRows: false,
      );

      expect(machineA.length, 2);
      expect(machineB.length, 2);
      expect(machineA.first.e1rm, closeTo(116.666, 0.01));
      expect(machineB.first.e1rm, closeTo(93.333, 0.01));
      expect(machineA.last.e1rm, greaterThan(machineB.last.e1rm));
    });

    test('open-station custom exercises stay isolated by station scope', () {
      final samples = [
        _sample(
          exerciseKey: 'custom:lat_raise',
          equipmentId: 'open-cable-1',
          day: '2026-01-01',
          reps: 10,
          weightKg: 20,
        ),
        _sample(
          exerciseKey: 'custom:lat_raise',
          equipmentId: 'open-cable-2',
          day: '2026-01-01',
          reps: 10,
          weightKg: 30,
        ),
      ];

      final station1 = aggregateScopedE1rmPoints(
        samples: samples,
        scope: const PerformanceScope.exerciseOnStation(
          exerciseKey: 'custom:lat_raise',
          equipmentId: 'open-cable-1',
        ),
        includeLegacyEquipmentlessRows: false,
      );

      final station2 = aggregateScopedE1rmPoints(
        samples: samples,
        scope: const PerformanceScope.exerciseOnStation(
          exerciseKey: 'custom:lat_raise',
          equipmentId: 'open-cable-2',
        ),
        includeLegacyEquipmentlessRows: false,
      );

      expect(station1, hasLength(1));
      expect(station2, hasLength(1));
      expect(station1.single.e1rm, isNot(station2.single.e1rm));
      expect(station1.single.e1rm, closeTo(26.666, 0.01));
      expect(station2.single.e1rm, closeTo(40.0, 0.01));
    });

    test('legacy equipment-less rows are included only when safe', () {
      expect(includeLegacyFixedRows(fixedVariantCount: 1), isTrue);
      expect(includeLegacyFixedRows(fixedVariantCount: 4), isFalse);

      final samples = [
        _sample(
          exerciseKey: 'fixed:bench_press',
          equipmentId: 'bench-a',
          day: '2026-01-01',
          reps: 5,
          weightKg: 100,
        ),
        _sample(
          exerciseKey: 'fixed:bench_press',
          equipmentId: null,
          day: '2026-02-01',
          reps: 5,
          weightKg: 105,
        ),
      ];

      final strict = aggregateScopedE1rmPoints(
        samples: samples,
        scope: const PerformanceScope.fixedEquipment(
          exerciseKey: 'fixed:bench_press',
          equipmentId: 'bench-a',
        ),
        includeLegacyEquipmentlessRows: false,
      );

      final withLegacy = aggregateScopedE1rmPoints(
        samples: samples,
        scope: const PerformanceScope.fixedEquipment(
          exerciseKey: 'fixed:bench_press',
          equipmentId: 'bench-a',
        ),
        includeLegacyEquipmentlessRows: true,
      );

      expect(strict, hasLength(1));
      expect(withLegacy, hasLength(2));
      expect(withLegacy.last.sessionDayAnchor, '2026-02-01');
    });
  });
}
