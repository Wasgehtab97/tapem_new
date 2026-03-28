import 'package:equatable/equatable.dart';

/// A single ingredient in a recipe.
class RecipeIngredient extends Equatable {
  const RecipeIngredient({
    required this.name,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    required this.grams,
    this.barcode,
  });

  final String name;
  final int kcalPer100;
  final int proteinPer100;
  final int carbsPer100;
  final int fatPer100;
  final double grams;
  final String? barcode;

  RecipeIngredient copyWith({
    String? name,
    int? kcalPer100,
    int? proteinPer100,
    int? carbsPer100,
    int? fatPer100,
    double? grams,
    String? barcode,
  }) =>
      RecipeIngredient(
        name: name ?? this.name,
        kcalPer100: kcalPer100 ?? this.kcalPer100,
        proteinPer100: proteinPer100 ?? this.proteinPer100,
        carbsPer100: carbsPer100 ?? this.carbsPer100,
        fatPer100: fatPer100 ?? this.fatPer100,
        grams: grams ?? this.grams,
        barcode: barcode ?? this.barcode,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'kcal_per100': kcalPer100,
        'protein_per100': proteinPer100,
        'carbs_per100': carbsPer100,
        'fat_per100': fatPer100,
        'grams': grams,
        if (barcode != null) 'barcode': barcode,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) =>
      RecipeIngredient(
        name: j['name'] as String,
        kcalPer100: (j['kcal_per100'] as num).toInt(),
        proteinPer100: (j['protein_per100'] as num).toInt(),
        carbsPer100: (j['carbs_per100'] as num).toInt(),
        fatPer100: (j['fat_per100'] as num).toInt(),
        grams: (j['grams'] as num).toDouble(),
        barcode: j['barcode'] as String?,
      );

  @override
  List<Object?> get props => [name, grams, kcalPer100];
}

/// A user-created recipe with ingredients.
class NutritionRecipe extends Equatable {
  const NutritionRecipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<RecipeIngredient> ingredients;
  final DateTime updatedAt;

  NutritionRecipe copyWith({
    String? id,
    String? name,
    List<RecipeIngredient>? ingredients,
    DateTime? updatedAt,
  }) =>
      NutritionRecipe(
        id: id ?? this.id,
        name: name ?? this.name,
        ingredients: ingredients ?? this.ingredients,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory NutritionRecipe.fromJson(Map<String, dynamic> j) => NutritionRecipe(
        id: j['id'] as String,
        name: j['name'] as String,
        ingredients: (j['ingredients'] as List<dynamic>)
            .map((i) => RecipeIngredient.fromJson(i as Map<String, dynamic>))
            .toList(),
        updatedAt: DateTime.parse(j['updated_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [id];
}
