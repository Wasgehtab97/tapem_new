import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_entry.dart';
import '../../../../domain/entities/nutrition/nutrition_enums.dart';
import '../../../../domain/entities/nutrition/nutrition_product.dart';
import '../../../../domain/utils/nutrition_date_utils.dart';
import '../providers/nutrition_providers.dart';

class NutritionEntryScreen extends HookConsumerWidget {
  const NutritionEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;

    final meal = args?['meal'] as MealType? ?? MealType.snack;
    final dateKey = args?['dateKey'] as String? ?? NutritionDateUtils.today();
    final uid = args?['uid'] as String? ?? '';
    final existingEntry = args?['entry'] as NutritionEntry?;
    final prefillProduct = args?['product'] as NutritionProduct?;
    final recipeId = args?['recipeId'] as String?;

    final isEditMode = existingEntry != null;

    // ── Form state ───────────────────────────────────────────────────────────

    final selectedMeal = useState<MealType>(existingEntry?.meal ?? meal);

    final nameCtrl = useTextEditingController(
      text: existingEntry?.name ?? prefillProduct?.name ?? '',
    );
    final gramsCtrl = useTextEditingController(
      text: existingEntry?.qty != null
          ? existingEntry!.qty!.toStringAsFixed(0)
          : prefillProduct != null
              ? '100'
              : '',
    );
    final kcalPer100Ctrl = useTextEditingController(
      text: existingEntry != null && existingEntry.qty != null && existingEntry.qty! > 0
          ? '${(existingEntry.kcal / existingEntry.qty! * 100).round()}'
          : prefillProduct != null
              ? '${prefillProduct.kcalPer100}'
              : '',
    );
    final proteinPer100Ctrl = useTextEditingController(
      text: existingEntry != null && existingEntry.qty != null && existingEntry.qty! > 0
          ? '${(existingEntry.protein / existingEntry.qty! * 100).round()}'
          : prefillProduct != null
              ? '${prefillProduct.proteinPer100}'
              : '',
    );
    final carbsPer100Ctrl = useTextEditingController(
      text: existingEntry != null && existingEntry.qty != null && existingEntry.qty! > 0
          ? '${(existingEntry.carbs / existingEntry.qty! * 100).round()}'
          : prefillProduct != null
              ? '${prefillProduct.carbsPer100}'
              : '',
    );
    final fatPer100Ctrl = useTextEditingController(
      text: existingEntry != null && existingEntry.qty != null && existingEntry.qty! > 0
          ? '${(existingEntry.fat / existingEntry.qty! * 100).round()}'
          : prefillProduct != null
              ? '${prefillProduct.fatPer100}'
              : '',
    );

    // Computed actual values (derived from per100 * grams/100)
    final actualKcal = useState<int>(existingEntry?.kcal ?? 0);
    final actualProtein = useState<int>(existingEntry?.protein ?? 0);
    final actualCarbs = useState<int>(existingEntry?.carbs ?? 0);
    final actualFat = useState<int>(existingEntry?.fat ?? 0);

    final isSaving = useState(false);
    final errorMsg = useState<String?>(null);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    // ── Recalculate when grams or per100 values change ───────────────────────

    void recalculate() {
      final grams = double.tryParse(gramsCtrl.text.trim()) ?? 0;
      final effectiveGrams = grams > 0 ? grams : 100;

      final k100 = int.tryParse(kcalPer100Ctrl.text.trim()) ?? 0;
      final p100 = int.tryParse(proteinPer100Ctrl.text.trim()) ?? 0;
      final c100 = int.tryParse(carbsPer100Ctrl.text.trim()) ?? 0;
      final f100 = int.tryParse(fatPer100Ctrl.text.trim()) ?? 0;

      actualKcal.value = (k100 * effectiveGrams / 100).round();
      actualProtein.value = (p100 * effectiveGrams / 100).round();
      actualCarbs.value = (c100 * effectiveGrams / 100).round();
      actualFat.value = (f100 * effectiveGrams / 100).round();
    }

    // Wire up listeners once
    useEffect(() {
      void listener() => recalculate();
      gramsCtrl.addListener(listener);
      kcalPer100Ctrl.addListener(listener);
      proteinPer100Ctrl.addListener(listener);
      carbsPer100Ctrl.addListener(listener);
      fatPer100Ctrl.addListener(listener);
      // Initial calculation
      recalculate();
      return () {
        gramsCtrl.removeListener(listener);
        kcalPer100Ctrl.removeListener(listener);
        proteinPer100Ctrl.removeListener(listener);
        carbsPer100Ctrl.removeListener(listener);
        fatPer100Ctrl.removeListener(listener);
      };
    }, []);

    // ── Pre-fill from product when navigating back from search/scan ──────────

    // Watch for product passed back via route args (handled on re-push)
    // The search/scan screens push back a NutritionProduct via context.pop(product)
    // We handle that via a separate callback approach below.

    // ── Save ─────────────────────────────────────────────────────────────────

    final notifier = ref.read(nutritionNotifierProvider.notifier);

    Future<void> handleSave() async {
      errorMsg.value = null;
      if (!(formKey.currentState?.validate() ?? false)) return;

      final name = nameCtrl.text.trim();
      final grams = double.tryParse(gramsCtrl.text.trim());
      final effectiveGrams = (grams != null && grams > 0) ? grams : 100.0;

      final kcal = actualKcal.value;
      if (kcal <= 0) {
        errorMsg.value = 'Kalorien müssen größer als 0 sein.';
        return;
      }

      isSaving.value = true;
      try {
        if (isEditMode) {
          final updated = existingEntry.copyWith(
            name: name,
            kcal: kcal,
            protein: actualProtein.value,
            carbs: actualCarbs.value,
            fat: actualFat.value,
            meal: selectedMeal.value,
            qty: effectiveGrams,
          );
          await notifier.updateEntry(updated);
          if (context.mounted) context.pop();
        } else {
          final entry = NutritionEntry(
            id: notifier.generateId(),
            name: name,
            kcal: kcal,
            protein: actualProtein.value,
            carbs: actualCarbs.value,
            fat: actualFat.value,
            meal: selectedMeal.value,
            loggedAt: DateTime.now(),
            qty: effectiveGrams,
            recipeId: recipeId,
          );
          await notifier.addEntries([entry]);

          if (context.mounted) {
            // Reset form for next entry
            nameCtrl.clear();
            gramsCtrl.text = '100';
            kcalPer100Ctrl.clear();
            proteinPer100Ctrl.clear();
            carbsPer100Ctrl.clear();
            fatPer100Ctrl.clear();
            actualKcal.value = 0;
            actualProtein.value = 0;
            actualCarbs.value = 0;
            actualFat.value = 0;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name gespeichert'),
                backgroundColor: AppColors.surface700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        errorMsg.value = e.toString();
      } finally {
        isSaving.value = false;
      }
    }

    // ── UI ───────────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        backgroundColor: AppColors.surface900,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isEditMode ? 'EINTRAG BEARBEITEN' : 'EINTRAG HINZUFÜGEN',
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
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Search / Scan shortcuts ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.search, size: 18),
                    label: Text('SUCHEN', style: AppTextStyles.buttonMd),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neonCyan,
                      side: const BorderSide(color: AppColors.neonCyanDim),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final result = await context.push<NutritionProduct>(
                        '/nutrition/search',
                        extra: {
                          'meal': selectedMeal.value,
                          'dateKey': dateKey,
                          'uid': uid,
                        },
                      );
                      if (result != null) {
                        nameCtrl.text = result.name;
                        kcalPer100Ctrl.text = '${result.kcalPer100}';
                        proteinPer100Ctrl.text = '${result.proteinPer100}';
                        carbsPer100Ctrl.text = '${result.carbsPer100}';
                        fatPer100Ctrl.text = '${result.fatPer100}';
                        if (gramsCtrl.text.isEmpty) gramsCtrl.text = '100';
                      }
                    },
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: Text('SCAN', style: AppTextStyles.buttonMd),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neonCyan,
                      side: const BorderSide(color: AppColors.neonCyanDim),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final result = await context.push<NutritionProduct>(
                        '/nutrition/scan',
                        extra: {
                          'meal': selectedMeal.value,
                          'dateKey': dateKey,
                          'uid': uid,
                        },
                      );
                      if (result != null) {
                        nameCtrl.text = result.name;
                        kcalPer100Ctrl.text = '${result.kcalPer100}';
                        proteinPer100Ctrl.text = '${result.proteinPer100}';
                        carbsPer100Ctrl.text = '${result.carbsPer100}';
                        fatPer100Ctrl.text = '${result.fatPer100}';
                        if (gramsCtrl.text.isEmpty) gramsCtrl.text = '100';
                      }
                    },
                  ),
                ),
              ],
            ),
            const Gap(16),

            // ── Meal selector ──────────────────────────────────────────
            Text(
              'MAHLZEIT',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(8),
            _MealSelector(
              selected: selectedMeal.value,
              onChanged: (m) => selectedMeal.value = m,
            ),
            const Gap(16),

            // ── Product name ───────────────────────────────────────────
            _EntryField(
              controller: nameCtrl,
              label: 'Name',
              hintText: 'z. B. Hühnerbrust',
              keyboardType: TextInputType.text,
              inputFormatters: const [],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name ist erforderlich';
                return null;
              },
            ),
            const Gap(12),

            // ── Menge ──────────────────────────────────────────────────
            _EntryField(
              controller: gramsCtrl,
              label: 'Menge (g)',
              hintText: '100',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: null,
            ),
            const Gap(16),

            // ── Per-100g values ────────────────────────────────────────
            Text(
              'NÄHRWERTE PRO 100 G',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: _EntryField(
                    controller: kcalPer100Ctrl,
                    label: 'kcal',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Ungültig';
                      return null;
                    },
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: _EntryField(
                    controller: proteinPer100Ctrl,
                    label: 'Protein (g)',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: null,
                  ),
                ),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: _EntryField(
                    controller: carbsPer100Ctrl,
                    label: 'Kohlenh. (g)',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: null,
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: _EntryField(
                    controller: fatPer100Ctrl,
                    label: 'Fett (g)',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: null,
                  ),
                ),
              ],
            ),
            const Gap(16),

            // ── Calculated preview ─────────────────────────────────────
            _CalcPreview(
              kcal: actualKcal.value,
              protein: actualProtein.value,
              carbs: actualCarbs.value,
              fat: actualFat.value,
              grams: double.tryParse(gramsCtrl.text.trim()) ?? 100,
            ),
            const Gap(24),

            // ── Error ──────────────────────────────────────────────────
            if (errorMsg.value != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorGlow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Text(
                  errorMsg.value!,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                ),
              ),
              const Gap(16),
            ],

            // ── Save button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving.value ? null : handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  foregroundColor: AppColors.textOnAction,
                  disabledBackgroundColor: AppColors.neonCyanDim,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                        isEditMode ? 'AKTUALISIEREN' : 'SPEICHERN',
                        style: AppTextStyles.buttonMd,
                      ),
              ),
            ),

            if (!isEditMode) ...[
              const Gap(8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'FERTIG',
                    style: AppTextStyles.buttonMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],

            const Gap(32),
          ],
        ),
      ),
    );
  }
}

// ─── Meal selector chips ──────────────────────────────────────────────────────

class _MealSelector extends StatelessWidget {
  const _MealSelector({
    required this.selected,
    required this.onChanged,
  });

  final MealType selected;
  final ValueChanged<MealType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MealType.values.map((meal) {
          final isSelected = meal == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(meal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neonCyan : AppColors.surface700,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.neonCyan
                        : AppColors.surface500,
                  ),
                ),
                child: Text(
                  meal.displayName,
                  style: AppTextStyles.labelLg.copyWith(
                    color: isSelected
                        ? AppColors.textOnAction
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Calculated preview card ──────────────────────────────────────────────────

class _CalcPreview extends StatelessWidget {
  const _CalcPreview({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.grams,
  });

  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final double grams;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FÜR ${grams.toStringAsFixed(0)} G',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$kcal kcal',
                style: AppTextStyles.h3.copyWith(color: AppColors.neonCyan),
              ),
            ],
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroChip(label: 'Protein', value: protein, color: Colors.blueAccent),
              _MacroChip(label: 'Kohlenh.', value: carbs, color: Colors.amberAccent),
              _MacroChip(label: 'Fett', value: fat, color: Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value}g',
          style: AppTextStyles.labelLg.copyWith(color: color),
        ),
        Text(label, style: AppTextStyles.bodySm),
      ],
    );
  }
}

// ─── Reusable text form field ─────────────────────────────────────────────────

class _EntryField extends StatelessWidget {
  const _EntryField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.keyboardType,
    required this.inputFormatters,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyLg,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: AppTextStyles.labelLg.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.bodySm,
        filled: true,
        fillColor: AppColors.surface600,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.surface500),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.surface500),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neonCyan),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
