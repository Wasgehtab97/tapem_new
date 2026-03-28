import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/domain/entities/nutrition/nutrition_enums.dart';
import 'package:tapem/domain/services/nutrition_status_service.dart';

void main() {
  group('NutritionStatusService', () {
    test('returns under when totalKcal < targetKcal', () {
      expect(NutritionStatusService.statusFor(1500, 2000), NutritionStatus.under);
    });

    test('returns on when totalKcal == targetKcal', () {
      expect(NutritionStatusService.statusFor(2000, 2000), NutritionStatus.on);
    });

    test('returns over when totalKcal > targetKcal', () {
      expect(NutritionStatusService.statusFor(2500, 2000), NutritionStatus.over);
    });

    test('returns under when targetKcal is 0', () {
      expect(NutritionStatusService.statusFor(500, 0), NutritionStatus.under);
    });

    test('returns under when targetKcal is negative', () {
      expect(NutritionStatusService.statusFor(100, -1), NutritionStatus.under);
    });

    test('returns under when both are 0', () {
      expect(NutritionStatusService.statusFor(0, 0), NutritionStatus.under);
    });
  });
}
