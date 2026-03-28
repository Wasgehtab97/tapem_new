import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_enums.dart';
import '../../../../domain/entities/nutrition/nutrition_recipe.dart';
import '../../../../domain/services/nutrition_recipe_math.dart';
import '../providers/nutrition_providers.dart';

class NutritionRecipesScreen extends HookConsumerWidget {
  const NutritionRecipesScreen({super.key, required this.extra});

  final Map<String, dynamic> extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = extra['uid'] as String? ?? '';
    final meal = extra['meal'] as MealType?;
    final dateKey = extra['dateKey'] as String? ?? '';
    final isSelectionMode = extra['isSelectionMode'] as bool? ?? false;

    // Load recipes on first render
    useEffect(() {
      if (uid.isNotEmpty) {
        ref.read(recipesNotifierProvider.notifier).load(uid);
      }
      return null;
    }, [uid]);

    final recipesAsync = ref.watch(recipesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        backgroundColor: AppColors.surface900,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isSelectionMode ? 'REZEPT WÄHLEN' : 'MEINE REZEPTE',
          style: AppTextStyles.h3,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.neonCyan,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.neonCyan,
              foregroundColor: AppColors.textOnAction,
              icon: const Icon(Icons.add),
              label: Text('NEUES REZEPT', style: AppTextStyles.buttonMd.copyWith(color: AppColors.textOnAction)),
              onPressed: () => context.push('/nutrition/recipe-edit', extra: {
                'uid': uid,
                'recipe': null,
              }),
            ),
      body: recipesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonCyan),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const Gap(12),
              Text(
                'Fehler beim Laden der Rezepte.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
              const Gap(8),
              TextButton(
                onPressed: () => ref.read(recipesNotifierProvider.notifier).load(uid),
                child: Text(
                  'ERNEUT VERSUCHEN',
                  style: AppTextStyles.buttonMd.copyWith(color: AppColors.neonCyan),
                ),
              ),
            ],
          ),
        ),
        data: (recipes) {
          if (recipes.isEmpty) {
            return _EmptyState(
              isSelectionMode: isSelectionMode,
              onCreateTap: () => context.push('/nutrition/recipe-edit', extra: {
                'uid': uid,
                'recipe': null,
              }),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 12, 16, isSelectionMode ? 16 : 96),
            itemCount: recipes.length,
            itemBuilder: (context, i) {
              final recipe = recipes[i];
              return _RecipeTile(
                recipe: recipe,
                isSelectionMode: isSelectionMode,
                onTap: () => _handleTap(context, ref, recipe, uid, meal, dateKey, isSelectionMode),
                onEdit: isSelectionMode
                    ? null
                    : () => context.push('/nutrition/recipe-edit', extra: {
                          'uid': uid,
                          'recipe': recipe,
                        }),
                onDelete: isSelectionMode
                    ? null
                    : () => _confirmDelete(context, ref, recipe),
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    NutritionRecipe recipe,
    String uid,
    MealType? meal,
    String dateKey,
    bool isSelectionMode,
  ) {
    if (isSelectionMode && meal != null) {
      _showFactorSheet(context, ref, recipe, meal, dateKey);
    } else if (!isSelectionMode) {
      context.push('/nutrition/recipe-edit', extra: {
        'uid': uid,
        'recipe': recipe,
      });
    }
  }

  void _showFactorSheet(
    BuildContext context,
    WidgetRef ref,
    NutritionRecipe recipe,
    MealType meal,
    String dateKey,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FactorSheet(
        recipe: recipe,
        onConfirm: (factor) async {
          Navigator.of(context).pop();
          await ref.read(nutritionNotifierProvider.notifier).addRecipeToMeal(
                recipe: recipe,
                meal: meal,
                factor: factor,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surface700,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  '${recipe.name} hinzugefügt.',
                  style: AppTextStyles.bodyMd,
                ),
              ),
            );
            context.pop();
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    NutritionRecipe recipe,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface800,
        title: Text('Rezept löschen?', style: AppTextStyles.h3),
        content: Text(
          '"${recipe.name}" wird dauerhaft gelöscht.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'ABBRECHEN',
              style: AppTextStyles.buttonMd.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'LÖSCHEN',
              style: AppTextStyles.buttonMd.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(recipesNotifierProvider.notifier).delete(recipe.id);
    }
  }
}

// ─── Recipe tile ──────────────────────────────────────────────────────────────

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({
    required this.recipe,
    required this.isSelectionMode,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final NutritionRecipe recipe;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final summary = NutritionRecipeMath.summarize(recipe.ingredients, 1.0);

    final tile = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surface500),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.neonCyanGlow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.neonCyan,
                  size: 22,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: AppTextStyles.labelLg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Text(
                      '${recipe.ingredients.length} Zutaten  ·  ${summary.totalKcal} kcal',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              if (isSelectionMode) ...[
                const Gap(8),
                const Icon(Icons.add_circle_outline, color: AppColors.neonCyan),
              ] else ...[
                const Gap(8),
                const Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ],
            ],
          ),
        ),
      ),
    );

    if (isSelectionMode || onDelete == null) return tile;

    return Dismissible(
      key: ValueKey(recipe.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.errorGlow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        onDelete?.call();
        return false; // deletion handled by dialog
      },
      child: tile,
    );
  }
}

// ─── Factor bottom sheet ──────────────────────────────────────────────────────

class _FactorSheet extends HookWidget {
  const _FactorSheet({required this.recipe, required this.onConfirm});

  final NutritionRecipe recipe;
  final void Function(double factor) onConfirm;

  static const _presets = [0.5, 0.75, 1.0, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final selectedFactor = useState(1.0);
    final summary = useMemoized(
      () => NutritionRecipeMath.summarize(recipe.ingredients, selectedFactor.value),
      [selectedFactor.value],
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surface500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Text(recipe.name, style: AppTextStyles.h3),
            const Gap(4),
            Text(
              'Wähle eine Portion',
              style: AppTextStyles.bodySm,
            ),
            const Gap(16),

            // Factor presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets.map((f) {
                  final isSelected = selectedFactor.value == f;
                  return GestureDetector(
                    onTap: () => selectedFactor.value = f,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.neonCyan : AppColors.surface700,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.neonCyan : AppColors.surface500,
                        ),
                      ),
                      child: Text(
                        '${f}x',
                        style: AppTextStyles.labelLg.copyWith(
                          color: isSelected ? AppColors.textOnAction : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Gap(16),

            // Nutrition preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface700,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surface500),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NutritionCell('KCAL', '${summary.totalKcal}', Colors.orangeAccent),
                  _NutritionCell('PROTEIN', '${summary.totalProtein}g', Colors.blueAccent),
                  _NutritionCell('KOHLENH.', '${summary.totalCarbs}g', Colors.amberAccent),
                  _NutritionCell('FETT', '${summary.totalFat}g', Colors.lightGreenAccent),
                ],
              ),
            ),
            const Gap(20),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onConfirm(selectedFactor.value),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  foregroundColor: AppColors.textOnAction,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('HINZUFÜGEN', style: AppTextStyles.buttonLg),
              ),
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}

class _NutritionCell extends StatelessWidget {
  const _NutritionCell(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.labelLg.copyWith(color: color),
        ),
        const Gap(2),
        Text(label, style: AppTextStyles.labelSm),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSelectionMode, required this.onCreateTap});

  final bool isSelectionMode;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              color: AppColors.textDisabled,
              size: 56,
            ),
            const Gap(16),
            Text(
              'Keine Rezepte vorhanden',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              isSelectionMode
                  ? 'Erstelle zuerst ein Rezept über das Rezepte-Menü.'
                  : 'Erstelle dein erstes Rezept und logge Mahlzeiten schneller.',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            if (!isSelectionMode) ...[
              const Gap(24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text('REZEPT ERSTELLEN', style: AppTextStyles.buttonMd),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  foregroundColor: AppColors.textOnAction,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onCreateTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
