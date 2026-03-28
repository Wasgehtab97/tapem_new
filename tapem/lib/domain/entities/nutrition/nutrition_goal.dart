import 'package:equatable/equatable.dart';

/// Daily calorie + macro target for a specific date.
class NutritionGoal extends Equatable {
  const NutritionGoal({
    required this.dateKey,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.updatedAt,
    this.source,
  });

  /// Date in yyyyMMdd format.
  final String dateKey;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final String? source;
  final DateTime updatedAt;

  /// Built-in default if no user-configured goal exists.
  factory NutritionGoal.defaultGoal(String dateKey) => NutritionGoal(
        dateKey: dateKey,
        kcal: 2000,
        protein: 150,
        carbs: 250,
        fat: 67,
        updatedAt: DateTime.now(),
      );

  NutritionGoal copyWith({
    String? dateKey,
    int? kcal,
    int? protein,
    int? carbs,
    int? fat,
    String? source,
    DateTime? updatedAt,
  }) =>
      NutritionGoal(
        dateKey: dateKey ?? this.dateKey,
        kcal: kcal ?? this.kcal,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        source: source ?? this.source,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'date_key': dateKey,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'source': source,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory NutritionGoal.fromJson(Map<String, dynamic> j) => NutritionGoal(
        dateKey: j['date_key'] as String,
        kcal: (j['kcal'] as num).toInt(),
        protein: (j['protein'] as num).toInt(),
        carbs: (j['carbs'] as num).toInt(),
        fat: (j['fat'] as num).toInt(),
        source: j['source'] as String?,
        updatedAt: DateTime.parse(j['updated_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [dateKey];
}
