import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/domain/utils/nutrition_date_utils.dart';

void main() {
  group('NutritionDateUtils', () {
    test('toDateKey formats date correctly', () {
      final d = DateTime(2026, 3, 26);
      expect(NutritionDateUtils.toDateKey(d), '20260326');
    });

    test('toDateKey pads month and day', () {
      final d = DateTime(2026, 1, 5);
      expect(NutritionDateUtils.toDateKey(d), '20260105');
    });

    test('fromDateKey parses correctly', () {
      final result = NutritionDateUtils.fromDateKey('20260326');
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 3);
      expect(result.day, 26);
    });

    test('fromDateKey returns null for invalid key', () {
      expect(NutritionDateUtils.fromDateKey('invalid'), isNull);
      expect(NutritionDateUtils.fromDateKey('2026032'), isNull);
    });

    test('yearFromKey extracts year', () {
      expect(NutritionDateUtils.yearFromKey('20260326'), 2026);
    });
  });
}
