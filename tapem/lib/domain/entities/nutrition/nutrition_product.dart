import 'package:equatable/equatable.dart';

/// A food product with per-100g macronutrient data.
class NutritionProduct extends Equatable {
  const NutritionProduct({
    required this.name,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    required this.updatedAt,
    this.barcode,
  });

  final String name;
  final int kcalPer100;
  final int proteinPer100;
  final int carbsPer100;
  final int fatPer100;
  final DateTime updatedAt;
  final String? barcode;

  /// A product is considered valid if name is non-empty and kcal is positive.
  bool get isValid =>
      name.isNotEmpty &&
      kcalPer100 > 0 &&
      proteinPer100 >= 0 &&
      carbsPer100 >= 0 &&
      fatPer100 >= 0;

  /// Compute per-entry macros for a given gram amount.
  ({int kcal, int protein, int carbs, int fat}) macrosForGrams(double grams) {
    if (grams <= 0) grams = 100;
    return (
      kcal: (kcalPer100 * grams / 100).round(),
      protein: (proteinPer100 * grams / 100).round(),
      carbs: (carbsPer100 * grams / 100).round(),
      fat: (fatPer100 * grams / 100).round(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'kcal_per100': kcalPer100,
        'protein_per100': proteinPer100,
        'carbs_per100': carbsPer100,
        'fat_per100': fatPer100,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        if (barcode != null) 'barcode': barcode,
      };

  factory NutritionProduct.fromJson(Map<String, dynamic> j) =>
      NutritionProduct(
        name: j['name'] as String,
        kcalPer100: (j['kcal_per100'] as num).toInt(),
        proteinPer100: (j['protein_per100'] as num).toInt(),
        carbsPer100: (j['carbs_per100'] as num).toInt(),
        fatPer100: (j['fat_per100'] as num).toInt(),
        barcode: j['barcode'] as String?,
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String).toLocal()
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [barcode, name, kcalPer100];
}
