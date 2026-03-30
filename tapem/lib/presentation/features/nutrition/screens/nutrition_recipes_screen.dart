import 'dart:async' show unawaited;

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
        unawaited(ref.read(recipesNotifierProvider.notifier).load(uid));
      }
      return null;
    }, [uid]);

    final recipesAsync = ref.watch(recipesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.surface900.withValues(alpha: 0.85),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                isSelectionMode ? 'REZEPT WÄHLEN' : 'MEINE REZEPTE',
                style: AppTextStyles.h2.copyWith(letterSpacing: 1.2),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, AppColors.neonCyan, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          recipesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: AppColors.errorGlow, shape: BoxShape.circle),
                      child: const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                    ),
                    const Gap(16),
                    const Text('Fehler beim Laden der Rezepte.', style: AppTextStyles.bodyLg, textAlign: TextAlign.center),
                    const Gap(24),
                    OutlinedButton(
                      onPressed: () => ref.read(recipesNotifierProvider.notifier).load(uid),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonCyan,
                        side: const BorderSide(color: AppColors.neonCyan),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('ERNEUT VERSUCHEN', style: AppTextStyles.buttonMd),
                    ),
                  ],
                ),
              ),
            ),
            data: (recipes) {
              if (recipes.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    isSelectionMode: isSelectionMode,
                    onCreateTap: () => context.push('/nutrition/recipe-edit', extra: {'uid': uid, 'recipe': null}),
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, isSelectionMode ? 40 : 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final recipe = recipes[i];
                      return _AnimatedRecipeTile(
                        index: i,
                        recipe: recipe,
                        isSelectionMode: isSelectionMode,
                        onTap: () => _handleTap(context, ref, recipe, uid, meal, dateKey, isSelectionMode),
                        onEdit: isSelectionMode ? null : () => context.push('/nutrition/recipe-edit', extra: {'uid': uid, 'recipe': recipe}),
                        onDelete: isSelectionMode ? null : () => _confirmDelete(context, ref, recipe),
                      );
                    },
                    childCount: recipes.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: isSelectionMode
          ? null
          : AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton.extended(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: AppColors.textOnAction,
                elevation: 4,
                highlightElevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.add),
                label: Text('NEUES REZEPT', style: AppTextStyles.buttonLg.copyWith(color: AppColors.textOnAction)),
                onPressed: () => context.push('/nutrition/recipe-edit', extra: {'uid': uid, 'recipe': null}),
              ),
            ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, NutritionRecipe recipe, String uid, MealType? meal, String dateKey, bool isSelectionMode) {
    if (isSelectionMode && meal != null) {
      _showFactorSheet(context, ref, recipe, meal, dateKey);
    } else if (!isSelectionMode) {
      unawaited(context.push('/nutrition/recipe-edit', extra: {'uid': uid, 'recipe': recipe}));
    }
  }

  void _showFactorSheet(BuildContext context, WidgetRef ref, NutritionRecipe recipe, MealType meal, String dateKey) {
    unawaited(showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FactorSheet(
        recipe: recipe,
        onConfirm: (factor) async {
          Navigator.of(context).pop();
          await ref.read(nutritionNotifierProvider.notifier).addRecipeToMeal(recipe: recipe, meal: meal, factor: factor);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 backgroundColor: AppColors.surface700,
                 behavior: SnackBarBehavior.floating,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 content: Text('${recipe.name} hinzugefügt.', style: AppTextStyles.bodyMd),
               ),
            );
            context.pop();
          }
        },
      ),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, NutritionRecipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rezept löschen?', style: AppTextStyles.h3),
        content: Text('"${recipe.name}" wird dauerhaft gelöscht.', style: AppTextStyles.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('ABBRECHEN', style: AppTextStyles.buttonMd.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('LÖSCHEN', style: AppTextStyles.buttonMd.copyWith(color: Colors.white)),
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

class _AnimatedRecipeTile extends HookWidget {
  const _AnimatedRecipeTile({
    required this.index,
    required this.recipe,
    required this.isSelectionMode,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final int index;
  final NutritionRecipe recipe;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final summary = NutritionRecipeMath.summarize(recipe.ingredients, 1.0);
    final isPressed = useState(false);

    final tileContent = GestureDetector(
       onTapDown: (_) => isPressed.value = true,
       onTapUp: (_) { isPressed.value = false; onTap(); },
       onTapCancel: () => isPressed.value = false,
       child: AnimatedScale(
         scale: isPressed.value ? 0.98 : 1.0,
         duration: const Duration(milliseconds: 150),
         curve: Curves.easeOutCubic,
         child: Container(
           margin: const EdgeInsets.only(bottom: 16),
           decoration: BoxDecoration(
             color: AppColors.surface800.withValues(alpha: 0.8),
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: AppColors.surface500.withValues(alpha: 0.5)),
             boxShadow: [
               BoxShadow(
                 color: AppColors.neonCyan.withValues(alpha: 0.03),
                 blurRadius: 10,
                 offset: const Offset(0, 4),
               ),
             ],
           ),
           child: Padding(
             padding: const EdgeInsets.all(16),
             child: Row(
               children: [
                 Container(
                   width: 50,
                   height: 50,
                   decoration: BoxDecoration(
                     color: AppColors.neonCyanGlow,
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: const Icon(Icons.menu_book_outlined, color: AppColors.neonCyan, size: 24),
                 ),
                 const Gap(16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(recipe.name, style: AppTextStyles.labelLg.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                       const Gap(4),
                       Text('${recipe.ingredients.length} Zutaten  ·  ${summary.totalKcal} kcal', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                     ],
                   ),
                 ),
                 if (isSelectionMode) ...[
                   const Gap(12),
                   const Icon(Icons.add_circle_outline, color: AppColors.neonCyan, size: 28),
                 ] else ...[
                   const Gap(12),
                   const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                 ],
               ],
             ),
           ),
         ),
       ),
    );

    final animatedTile = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: isSelectionMode || onDelete == null
          ? tileContent
          : Dismissible(
              key: ValueKey(recipe.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
              ),
              confirmDismiss: (_) async {
                onDelete?.call();
                return false;
              },
              child: tileContent,
            ),
    );

    return animatedTile;
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
    final summary = useMemoized(() => NutritionRecipeMath.summarize(recipe.ingredients, selectedFactor.value), [selectedFactor.value]);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: AppColors.surface500, borderRadius: BorderRadius.circular(3)))),
              const Gap(24),
              Text(recipe.name, style: AppTextStyles.h2),
              const Gap(4),
              Text('Wähle eine Portion für die Mahlzeit.', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              const Gap(24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _presets.map((f) {
                    final isSelected = selectedFactor.value == f;
                    return GestureDetector(
                      onTap: () => selectedFactor.value = f,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.neonCyan : AppColors.surface700,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.neonCyan : AppColors.surface500),
                          boxShadow: isSelected ? [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.3), blurRadius: 10)] : [],
                        ),
                        child: Text(
                          '${f}x',
                          style: AppTextStyles.labelLg.copyWith(color: isSelected ? AppColors.textOnAction : AppColors.textSecondary, fontSize: 16),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Gap(24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface700.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surface500.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NutritionCell('KCAL', '${summary.totalKcal}', Colors.orangeAccent),
                    _NutritionCell('PROTEIN', '${summary.totalProtein}g', const Color(0xFF42A5F5)),
                    _NutritionCell('KOHLENH.', '${summary.totalCarbs}g', const Color(0xFFFFCA28)),
                    _NutritionCell('FETT', '${summary.totalFat}g', const Color(0xFF66BB6A)),
                  ],
                ),
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onConfirm(selectedFactor.value),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('HINZUFÜGEN', style: AppTextStyles.buttonLg.copyWith(color: AppColors.textOnAction)),
                ),
              ),
            ],
          ),
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
        Text(value, style: AppTextStyles.h3.copyWith(color: color, fontSize: 20)),
        const Gap(4),
        Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.textDisabled, letterSpacing: 1.2)),
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
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface800.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              boxShadow: [
                 BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.05), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: const Icon(Icons.menu_book_outlined, color: AppColors.neonCyanDim, size: 64),
          ),
          const Gap(24),
          Text('Keine Rezepte', style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.center),
          const Gap(12),
          Text(
            isSelectionMode ? 'Erstelle zuerst ein Rezept über das Rezepte-Menü.' : 'Erstelle dein erstes Rezept und logge Mahlzeiten schneller.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (!isSelectionMode) ...[
            const Gap(32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: AppColors.textOnAction),
              label: Text('REZEPT ERSTELLEN', style: AppTextStyles.buttonMd.copyWith(color: AppColors.textOnAction)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onCreateTap,
            ),
          ],
        ],
      ),
    );
  }
}
