import 'package:equatable/equatable.dart';
import 'nutrition_enums.dart';

/// A single food item logged in a day's nutrition log.
class NutritionEntry extends Equatable {
  const NutritionEntry({
    required this.id,
    required this.name,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meal,
    required this.loggedAt,
    this.qty,
    this.barcode,
    this.recipeId,
  });

  final String id;
  final String name;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final MealType meal;
  final DateTime loggedAt;

  /// Quantity in grams (optional, informational).
  final double? qty;
  final String? barcode;
  final String? recipeId;

  NutritionEntry copyWith({
    String? id,
    String? name,
    int? kcal,
    int? protein,
    int? carbs,
    int? fat,
    MealType? meal,
    DateTime? loggedAt,
    double? qty,
    String? barcode,
    String? recipeId,
  }) =>
      NutritionEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        kcal: kcal ?? this.kcal,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        meal: meal ?? this.meal,
        loggedAt: loggedAt ?? this.loggedAt,
        qty: qty ?? this.qty,
        barcode: barcode ?? this.barcode,
        recipeId: recipeId ?? this.recipeId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'meal': meal.value,
        'logged_at': loggedAt.toUtc().toIso8601String(),
        if (qty != null) 'qty': qty,
        if (barcode != null) 'barcode': barcode,
        if (recipeId != null) 'recipe_id': recipeId,
      };

  factory NutritionEntry.fromJson(Map<String, dynamic> j) => NutritionEntry(
        id: j['id'] as String,
        name: j['name'] as String,
        kcal: (j['kcal'] as num).toInt(),
        protein: (j['protein'] as num).toInt(),
        carbs: (j['carbs'] as num).toInt(),
        fat: (j['fat'] as num).toInt(),
        meal: MealType.fromValue(j['meal'] as String),
        loggedAt: DateTime.parse(j['logged_at'] as String).toLocal(),
        qty: (j['qty'] as num?)?.toDouble(),
        barcode: j['barcode'] as String?,
        recipeId: j['recipe_id'] as String?,
      );

  @override
  List<Object?> get props => [id];
}
