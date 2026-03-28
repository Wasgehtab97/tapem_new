import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/domain/entities/nutrition/nutrition_entry.dart';
import 'package:tapem/domain/entities/nutrition/nutrition_enums.dart';
import 'package:tapem/domain/entities/nutrition/nutrition_log.dart';

void main() {
  group('NutritionLog.recompute', () {
    NutritionEntry entry(String id, int kcal) => NutritionEntry(
          id: id,
          name: 'Test $id',
          kcal: kcal,
          protein: 10,
          carbs: 20,
          fat: 5,
          meal: MealType.lunch,
          loggedAt: DateTime(2026, 1, 1),
        );

    test('computes correct totals', () {
      final entries = [entry('1', 300), entry('2', 400)];
      final log = NutritionLog.recompute(
        dateKey: '20260101',
        entries: entries,
        status: NutritionStatus.under,
      );
      expect(log.totalKcal, 700);
      expect(log.totalProtein, 20);
      expect(log.totalCarbs, 40);
      expect(log.totalFat, 10);
    });

    test('returns zeros for empty entries', () {
      final log = NutritionLog.recompute(
        dateKey: '20260101',
        entries: [],
        status: NutritionStatus.under,
      );
      expect(log.totalKcal, 0);
      expect(log.entries, isEmpty);
    });
  });

  group('NutritionLog serialization', () {
    test('round-trips through toJson/fromJson', () {
      final entry = NutritionEntry(
        id: 'entry1',
        name: 'Oatmeal',
        kcal: 350,
        protein: 12,
        carbs: 60,
        fat: 6,
        meal: MealType.breakfast,
        loggedAt: DateTime(2026, 3, 26, 8, 0),
        qty: 100,
      );
      final log = NutritionLog(
        dateKey: '20260326',
        totalKcal: 350,
        totalProtein: 12,
        totalCarbs: 60,
        totalFat: 6,
        entries: [entry],
        status: NutritionStatus.under,
        updatedAt: DateTime(2026, 3, 26, 12, 0),
      );

      final json = log.toJson();
      final restored = NutritionLog.fromJson(json);

      expect(restored.dateKey, log.dateKey);
      expect(restored.totalKcal, log.totalKcal);
      expect(restored.entries.length, 1);
      expect(restored.entries.first.name, 'Oatmeal');
      expect(restored.status, NutritionStatus.under);
    });
  });
}
