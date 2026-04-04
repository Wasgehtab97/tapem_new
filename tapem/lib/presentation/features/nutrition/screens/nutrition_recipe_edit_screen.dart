import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_product.dart';
import '../../../../domain/entities/nutrition/nutrition_recipe.dart';
import '../../../../domain/services/nutrition_recipe_math.dart';
import '../providers/nutrition_providers.dart';

class NutritionRecipeEditScreen extends HookConsumerWidget {
  const NutritionRecipeEditScreen({super.key, required this.extra});

  final Map<String, dynamic> extra;
  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // uid is available via extra for child widgets
    final existingRecipe = extra['recipe'] as NutritionRecipe?;
    final isNew = existingRecipe == null;

    // Recipe name
    final nameCtrl = useTextEditingController(text: existingRecipe?.name ?? '');

    // Ingredients list (mutable copy)
    final ingredients = useState<List<RecipeIngredient>>(
      existingRecipe?.ingredients.toList() ?? [],
    );

    final isSaving = useState(false);
    final nameError = useState<String?>(null);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    // Live summary
    final summary = useMemoized(
      () => NutritionRecipeMath.summarize(ingredients.value, 1.0),
      [ingredients.value],
    );

    Future<void> handleSave() async {
      FocusScope.of(context).unfocus();
      nameError.value = null;
      final name = nameCtrl.text.trim();
      if (name.isEmpty) {
        nameError.value = 'Rezeptname ist erforderlich.';
        return;
      }
      if (!(formKey.currentState?.validate() ?? false)) return;

      isSaving.value = true;
      try {
        final recipe = NutritionRecipe(
          id: existingRecipe?.id ?? _uuid.v4(),
          name: name,
          ingredients: ingredients.value,
          updatedAt: DateTime.now(),
        );
        await ref.read(recipesNotifierProvider.notifier).save(recipe);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.errorGlow,
              content: Text(
                'Fehler: ${e.toString()}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
            ),
          );
        }
      } finally {
        isSaving.value = false;
      }
    }

    void addIngredient() {
      ingredients.value = [
        ...ingredients.value,
        const RecipeIngredient(
          name: '',
          kcalPer100: 0,
          proteinPer100: 0,
          carbsPer100: 0,
          fatPer100: 0,
          grams: 100,
        ),
      ];
    }

    void removeIngredient(int index) {
      final list = [...ingredients.value];
      list.removeAt(index);
      ingredients.value = list;
    }

    void updateIngredient(int index, RecipeIngredient updated) {
      final list = [...ingredients.value];
      list[index] = updated;
      ingredients.value = list;
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.surface900,
        appBar: AppBar(
          backgroundColor: AppColors.surface900.withValues(alpha: 0.9),
          surfaceTintColor: Colors.transparent,
          title: Text(
            isNew ? 'NEUES REZEPT' : 'REZEPT BEARBEITEN',
            style: AppTextStyles.h3.copyWith(letterSpacing: 1.2),
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
        body: Column(
          children: [
            Expanded(
              child: Form(
                key: formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  children: [
                    // ── Recipe name ──────────────────────────────────────────
                    TextFormField(
                      controller: nameCtrl,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: AppTextStyles.h3,
                      decoration: InputDecoration(
                        labelText: 'Rezeptname',
                        labelStyle: AppTextStyles.labelLg.copyWith(
                          color: AppColors.neonCyan,
                        ),
                        hintText: 'z. B. Haferflocken Frühstück',
                        hintStyle: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textDisabled,
                        ),
                        filled: true,
                        fillColor: AppColors.surface700.withValues(alpha: 0.5),
                        errorText: nameError.value,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.surface500.withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.neonCyan,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                      ),
                    ),
                    const Gap(24),

                    // ── Summary card ─────────────────────────────────────────
                    _SummaryCard(
                      summary: summary,
                      ingredientCount: ingredients.value.length,
                    ),
                    const Gap(32),

                    // ── Ingredients header ────────────────────────────────────
                    Row(
                      children: [
                        Text(
                          'ZUTATEN',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.textDisabled,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface800,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${ingredients.value.length} Einträge',
                            style: AppTextStyles.labelSm,
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),

                    // ── Add ingredient button ─────────────────────────────────
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add, color: AppColors.neonCyan),
                      label: Text(
                        'ZUTAT HINZUFÜGEN',
                        style: AppTextStyles.buttonMd.copyWith(
                          color: AppColors.neonCyan,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: AppColors.neonCyan.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.neonCyan.withValues(
                          alpha: 0.05,
                        ),
                      ),
                      onPressed: addIngredient,
                    ),
                    const Gap(16),

                    // ── Ingredient forms ──────────────────────────────────────
                    ...ingredients.value.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ing = entry.value;
                      return _IngredientForm(
                        key: ValueKey('ing_$i'),
                        ingredient: ing,
                        index: i,
                        onUpdate: (updated) => updateIngredient(i, updated),
                        onDelete: () => removeIngredient(i),
                        onBarcodeScanned: (product) {
                          updateIngredient(
                            i,
                            ing.copyWith(
                              name: ing.name.isEmpty ? product.name : ing.name,
                              kcalPer100: product.kcalPer100,
                              proteinPer100: product.proteinPer100,
                              carbsPer100: product.carbsPer100,
                              fatPer100: product.fatPer100,
                            ),
                          );
                        },
                        extra: extra,
                      );
                    }),
                    const Gap(32),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom Action Bar ────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface800.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: AppColors.surface500.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: isSaving.value ? null : handleSave,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSaving.value
                        ? AppColors.neonCyan.withValues(alpha: 0.5)
                        : AppColors.neonCyan,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!isSaving.value)
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Center(
                    child: isSaving.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnAction,
                            ),
                          )
                        : Text(
                            isNew ? 'REZEPT SPEICHERN' : 'ÄNDERUNGEN SPEICHERN',
                            style: AppTextStyles.buttonLg.copyWith(
                              color: AppColors.textOnAction,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.ingredientCount});

  final RecipeSummary summary;
  final int ingredientCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface800.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ZUSAMMENFASSUNG',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textDisabled,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${summary.totalGrams.toStringAsFixed(0)} g gesamt',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryCell('KCAL', '${summary.totalKcal}', Colors.orangeAccent),
              _SummaryCell(
                'PROTEIN',
                '${summary.totalProtein}g',
                const Color(0xFF42A5F5),
              ),
              _SummaryCell(
                'KOHLENH.',
                '${summary.totalCarbs}g',
                const Color(0xFFFFCA28),
              ),
              _SummaryCell(
                'FETT',
                '${summary.totalFat}g',
                const Color(0xFF66BB6A),
              ),
            ],
          ),
          if (ingredientCount == 0) ...[
            const Gap(16),
            Center(
              child: Text(
                'Füge Zutaten hinzu.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell(this.label, this.value, this.color);

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
          style: AppTextStyles.h2.copyWith(color: color, fontSize: 22),
        ),
        const Gap(4),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.textDisabled,
            letterSpacing: 1.2,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// ─── Ingredient form ──────────────────────────────────────────────────────────

class _IngredientForm extends HookWidget {
  const _IngredientForm({
    super.key,
    required this.ingredient,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
    required this.onBarcodeScanned,
    required this.extra,
  });

  final RecipeIngredient ingredient;
  final int index;
  final void Function(RecipeIngredient) onUpdate;
  final VoidCallback onDelete;
  final void Function(NutritionProduct) onBarcodeScanned;
  final Map<String, dynamic> extra;

  @override
  Widget build(BuildContext context) {
    final nameCtrl = useTextEditingController(text: ingredient.name);
    final gramsCtrl = useTextEditingController(
      text: ingredient.grams > 0 ? ingredient.grams.toStringAsFixed(0) : '',
    );
    final kcalCtrl = useTextEditingController(
      text: ingredient.kcalPer100 > 0 ? '${ingredient.kcalPer100}' : '',
    );
    final proteinCtrl = useTextEditingController(
      text: ingredient.proteinPer100 > 0 ? '${ingredient.proteinPer100}' : '',
    );
    final carbsCtrl = useTextEditingController(
      text: ingredient.carbsPer100 > 0 ? '${ingredient.carbsPer100}' : '',
    );
    final fatCtrl = useTextEditingController(
      text: ingredient.fatPer100 > 0 ? '${ingredient.fatPer100}' : '',
    );

    void notifyUpdate() {
      onUpdate(
        RecipeIngredient(
          name: nameCtrl.text.trim(),
          grams: double.tryParse(gramsCtrl.text.trim()) ?? 100,
          kcalPer100: int.tryParse(kcalCtrl.text.trim()) ?? 0,
          proteinPer100: int.tryParse(proteinCtrl.text.trim()) ?? 0,
          carbsPer100: int.tryParse(carbsCtrl.text.trim()) ?? 0,
          fatPer100: int.tryParse(fatCtrl.text.trim()) ?? 0,
        ),
      );
    }

    useEffect(() {
      nameCtrl.addListener(notifyUpdate);
      gramsCtrl.addListener(notifyUpdate);
      kcalCtrl.addListener(notifyUpdate);
      proteinCtrl.addListener(notifyUpdate);
      carbsCtrl.addListener(notifyUpdate);
      fatCtrl.addListener(notifyUpdate);
      return () {
        nameCtrl.removeListener(notifyUpdate);
        gramsCtrl.removeListener(notifyUpdate);
        kcalCtrl.removeListener(notifyUpdate);
        proteinCtrl.removeListener(notifyUpdate);
        carbsCtrl.removeListener(notifyUpdate);
        fatCtrl.removeListener(notifyUpdate);
      };
    }, []);

    // When ingredient prop changes externally
    useEffect(() {
      if (nameCtrl.text != ingredient.name) nameCtrl.text = ingredient.name;
      final gramsStr = ingredient.grams > 0
          ? ingredient.grams.toStringAsFixed(0)
          : '';
      if (gramsCtrl.text != gramsStr) gramsCtrl.text = gramsStr;
      final kcalStr = ingredient.kcalPer100 > 0
          ? '${ingredient.kcalPer100}'
          : '';
      if (kcalCtrl.text != kcalStr) kcalCtrl.text = kcalStr;
      final proteinStr = ingredient.proteinPer100 > 0
          ? '${ingredient.proteinPer100}'
          : '';
      if (proteinCtrl.text != proteinStr) proteinCtrl.text = proteinStr;
      final carbsStr = ingredient.carbsPer100 > 0
          ? '${ingredient.carbsPer100}'
          : '';
      if (carbsCtrl.text != carbsStr) carbsCtrl.text = carbsStr;
      final fatStr = ingredient.fatPer100 > 0 ? '${ingredient.fatPer100}' : '';
      if (fatCtrl.text != fatStr) fatCtrl.text = fatStr;
      return null;
    }, [ingredient]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface500.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with index and delete
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ZUTAT ${index + 1}',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.neonCyan,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              // Barcode scan button
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: Text(
                  'SCAN',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.neonCyan,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neonCyan,
                  side: BorderSide(
                    color: AppColors.neonCyan.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  final result = await context.push<NutritionProduct>(
                    '/nutrition/scan',
                    extra: {...extra, 'returnProduct': true},
                  );
                  if (result != null) onBarcodeScanned(result);
                },
              ),
              const Gap(12),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.errorGlow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),

          // Name field
          _IngField(
            controller: nameCtrl,
            label: 'Name',
            hint: 'z. B. Haferflocken',
            keyboardType: TextInputType.text,
            isNumeric: false,
          ),
          const Gap(12),

          // Grams field
          _IngField(
            controller: gramsCtrl,
            label: 'Menge (g)',
            hint: '100',
            keyboardType: TextInputType.number,
            isNumeric: true,
          ),
          const Gap(24),

          Text(
            'PRO 100 G',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.textDisabled,
              letterSpacing: 1.5,
            ),
          ),
          const Gap(12),

          // Per-100g row 1
          Row(
            children: [
              Expanded(
                child: _IngField(
                  controller: kcalCtrl,
                  label: 'kcal',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  isNumeric: true,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _IngField(
                  controller: proteinCtrl,
                  label: 'Protein (g)',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  isNumeric: true,
                ),
              ),
            ],
          ),
          const Gap(12),

          // Per-100g row 2
          Row(
            children: [
              Expanded(
                child: _IngField(
                  controller: carbsCtrl,
                  label: 'Kohlenh. (g)',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  isNumeric: true,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _IngField(
                  controller: fatCtrl,
                  label: 'Fett (g)',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  isNumeric: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Compact ingredient text field ────────────────────────────────────────────

class _IngField extends HookWidget {
  const _IngField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboardType,
    required this.isNumeric,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool isNumeric;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final isFocused = useState(focusNode.hasFocus);

    useEffect(() {
      void listener() => isFocused.value = focusNode.hasFocus;
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: keyboardType,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
          : null,
      style: AppTextStyles.bodyLg,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.labelMd.copyWith(
          color: isFocused.value ? AppColors.neonCyan : AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: isFocused.value
            ? AppColors.surface800
            : AppColors.surface700.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.surface500.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
