/// Meal category for a nutrition entry.
enum MealType {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner'),
  snack('snack');

  const MealType(this.value);
  final String value;

  static MealType fromValue(String v) => MealType.values.firstWhere(
        (e) => e.value == v,
        orElse: () => MealType.snack,
      );

  String get displayName {
    switch (this) {
      case MealType.breakfast: return 'Frühstück';
      case MealType.lunch:     return 'Mittagessen';
      case MealType.dinner:    return 'Abendessen';
      case MealType.snack:     return 'Snack';
    }
  }
}

/// Day-level calorie status.
enum NutritionStatus {
  under('under'),
  on('on'),
  over('over');

  const NutritionStatus(this.value);
  final String value;

  static NutritionStatus fromValue(String v) => NutritionStatus.values.firstWhere(
        (e) => e.value == v,
        orElse: () => NutritionStatus.under,
      );
}

/// Time range for weight history charts.
enum WeightRange {
  week('week'),
  month('month'),
  quarter('quarter'),
  year('year');

  const WeightRange(this.value);
  final String value;

  static WeightRange fromValue(String v) => WeightRange.values.firstWhere(
        (e) => e.value == v,
        orElse: () => WeightRange.month,
      );
}
