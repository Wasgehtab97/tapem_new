import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/domain/entities/nutrition/nutrition_enums.dart';
import 'package:tapem/domain/entities/nutrition/nutrition_recipe.dart';
import 'package:tapem/domain/services/nutrition_recipe_math.dart';

void main() {
  final ingredients = [
    const RecipeIngredient(
      name: 'Oats',
      kcalPer100: 350,
      proteinPer100: 12,
      carbsPer100: 60,
      fatPer100: 6,
      grams: 100,
    ),
    const RecipeIngredient(
      name: 'Milk',
      kcalPer100: 60,
      proteinPer100: 3,
      carbsPer100: 5,
      fatPer100: 3,
      grams: 200,
    ),
  ];

  group('NutritionRecipeMath.summarize', () {
    test('calculates totals correctly at factor 1.0', () {
      final summary = NutritionRecipeMath.summarize(ingredients, 1.0);
      // Oats 100g: 350 kcal, 12 prot, 60 carbs, 6 fat
      // Milk 200g: 120 kcal, 6 prot, 10 carbs, 6 fat
      expect(summary.totalKcal, 470);
      expect(summary.totalProtein, 18);
      expect(summary.totalCarbs, 70);
      expect(summary.totalFat, 12);
      expect(summary.totalGrams, 300);
    });

    test('scales by factor 2.0', () {
      final summary = NutritionRecipeMath.summarize(ingredients, 2.0);
      expect(summary.totalKcal, 940);
      expect(summary.totalGrams, 600);
    });

    test('scales by factor 0.5', () {
      final summary = NutritionRecipeMath.summarize(ingredients, 0.5);
      expect(summary.totalKcal, 235);
      expect(summary.totalGrams, 150);
    });

    test('factor <= 0 defaults to 1.0', () {
      final s1 = NutritionRecipeMath.summarize(ingredients, 0.0);
      final s2 = NutritionRecipeMath.summarize(ingredients, 1.0);
      expect(s1.totalKcal, s2.totalKcal);
    });

    test('factor is clamped to max 10', () {
      final s1 = NutritionRecipeMath.summarize(ingredients, 20.0);
      final s2 = NutritionRecipeMath.summarize(ingredients, 10.0);
      expect(s1.totalKcal, s2.totalKcal);
    });
  });

  group('NutritionRecipeMath.clampFactor', () {
    test('clamps to minimum 0.1', () {
      expect(NutritionRecipeMath.clampFactor(0.05), 0.1);
    });

    test('clamps to maximum 10.0', () {
      expect(NutritionRecipeMath.clampFactor(15.0), 10.0);
    });

    test('factor 0 becomes 1.0', () {
      expect(NutritionRecipeMath.clampFactor(0), 1.0);
    });

    test('valid factor passes through', () {
      expect(NutritionRecipeMath.clampFactor(1.5), 1.5);
    });
  });

  group('NutritionRecipeMath.buildIngredientEntries', () {
    final recipe = NutritionRecipe(
      id: 'test-recipe',
      name: 'Breakfast Bowl',
      ingredients: ingredients,
      updatedAt: DateTime(2026, 1, 1),
    );

    test('creates one entry per ingredient', () {
      var counter = 0;
      final entries = NutritionRecipeMath.buildIngredientEntries(
        recipe: recipe,
        meal: MealType.breakfast,
        factor: 1.0,
        idGen: () => 'id-${++counter}',
      );
      expect(entries.length, 2);
    });

    test('entry qty matches scaled grams', () {
      var counter = 0;
      final entries = NutritionRecipeMath.buildIngredientEntries(
        recipe: recipe,
        meal: MealType.breakfast,
        factor: 2.0,
        idGen: () => 'id-${++counter}',
      );
      expect(entries[0].qty, 200.0); // Oats: 100g * 2 = 200g
      expect(entries[1].qty, 400.0); // Milk: 200g * 2 = 400g
    });

    test('entries have correct meal', () {
      var counter = 0;
      final entries = NutritionRecipeMath.buildIngredientEntries(
        recipe: recipe,
        meal: MealType.dinner,
        factor: 1.0,
        idGen: () => 'id-${++counter}',
      );
      for (final e in entries) {
        expect(e.meal, MealType.dinner);
      }
    });

    test('entries have recipeId set', () {
      var counter = 0;
      final entries = NutritionRecipeMath.buildIngredientEntries(
        recipe: recipe,
        meal: MealType.snack,
        factor: 1.0,
        idGen: () => 'id-${++counter}',
      );
      for (final e in entries) {
        expect(e.recipeId, 'test-recipe');
      }
    });
  });
}
