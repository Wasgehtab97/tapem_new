import '../entities/nutrition/nutrition_enums.dart';

/// Determines the calorie status for a day.
abstract final class NutritionStatusService {
  static NutritionStatus statusFor(int totalKcal, int targetKcal) {
    if (targetKcal <= 0) return NutritionStatus.under;
    if (totalKcal == targetKcal) return NutritionStatus.on;
    if (totalKcal < targetKcal) return NutritionStatus.under;
    return NutritionStatus.over;
  }
}
