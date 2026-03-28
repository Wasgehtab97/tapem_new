import '../entities/nutrition/nutrition_entry.dart';
import '../entities/nutrition/nutrition_enums.dart';
import '../entities/nutrition/nutrition_recipe.dart';

/// Summary of a recipe's nutritional content (at a given scale factor).
class RecipeSummary {
  const RecipeSummary({
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalGrams,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
  });

  final int totalKcal;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final double totalGrams;
  final int kcalPer100;
  final int proteinPer100;
  final int carbsPer100;
  final int fatPer100;
}

/// Nutritional math for recipes: scaling, summarising, entry expansion.
abstract final class NutritionRecipeMath {
  static const double _minFactor = 0.1;
  static const double _maxFactor = 10.0;
  static const double _maxGrams = 100000;

  /// Clamp a scale factor to the valid range.
  static double clampFactor(double factor) {
    if (factor <= 0) return 1.0;
    return factor.clamp(_minFactor, _maxFactor);
  }

  /// Summarise a recipe's ingredients at the given scale factor.
  static RecipeSummary summarize(
    List<RecipeIngredient> ingredients,
    double factor,
  ) {
    final f = clampFactor(factor);
    var kcal = 0, protein = 0, carbs = 0, fat = 0;
    var totalGrams = 0.0;

    for (final ing in ingredients) {
      final g = (ing.grams * f).clamp(0, _maxGrams).toDouble();
      kcal += (ing.kcalPer100 * g / 100).round();
      protein += (ing.proteinPer100 * g / 100).round();
      carbs += (ing.carbsPer100 * g / 100).round();
      fat += (ing.fatPer100 * g / 100).round();
      totalGrams += g;
    }

    final kcalPer100 = totalGrams > 0 ? (kcal / totalGrams * 100).round() : 0;
    final proteinPer100 =
        totalGrams > 0 ? (protein / totalGrams * 100).round() : 0;
    final carbsPer100 = totalGrams > 0 ? (carbs / totalGrams * 100).round() : 0;
    final fatPer100 = totalGrams > 0 ? (fat / totalGrams * 100).round() : 0;

    return RecipeSummary(
      totalKcal: kcal,
      totalProtein: protein,
      totalCarbs: carbs,
      totalFat: fat,
      totalGrams: totalGrams,
      kcalPer100: kcalPer100,
      proteinPer100: proteinPer100,
      carbsPer100: carbsPer100,
      fatPer100: fatPer100,
    );
  }

  /// Build one [NutritionEntry] per ingredient for use in addEntries.
  static List<NutritionEntry> buildIngredientEntries({
    required NutritionRecipe recipe,
    required MealType meal,
    required double factor,
    required String Function() idGen,
  }) {
    final f = clampFactor(factor);
    return recipe.ingredients.map((ing) {
      final scaledGrams = (ing.grams * f).clamp(0, _maxGrams).toDouble();
      return NutritionEntry(
        id: idGen(),
        name: ing.name.isNotEmpty ? ing.name : recipe.name,
        kcal: (ing.kcalPer100 * scaledGrams / 100).round(),
        protein: (ing.proteinPer100 * scaledGrams / 100).round(),
        carbs: (ing.carbsPer100 * scaledGrams / 100).round(),
        fat: (ing.fatPer100 * scaledGrams / 100).round(),
        meal: meal,
        loggedAt: DateTime.now(),
        qty: scaledGrams,
        recipeId: recipe.id,
      );
    }).toList();
  }
}
