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

// ─── Nutrition accent colors ───────────────────────────────────────────────────
const _accentColor = Color(0xFFFF7043);
const _proteinColor = Color(0xFF42A5F5);
const _carbsColor = Color(0xFFFFCA28);
const _fatColor = Color(0xFF66BB6A);

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

    final actualKcal = useState<int>(existingEntry?.kcal ?? 0);
    final actualProtein = useState<int>(existingEntry?.protein ?? 0);
    final actualCarbs = useState<int>(existingEntry?.carbs ?? 0);
    final actualFat = useState<int>(existingEntry?.fat ?? 0);

    final isSaving = useState(false);
    final errorMsg = useState<String?>(null);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    // ── Recalculate when any value changes ───────────────────────────────────

    void recalculate() {
      final raw = gramsCtrl.text.trim().replaceAll(',', '.');
      final grams = double.tryParse(raw) ?? 0;
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

    useEffect(() {
      void listener() => recalculate();
      gramsCtrl.addListener(listener);
      kcalPer100Ctrl.addListener(listener);
      proteinPer100Ctrl.addListener(listener);
      carbsPer100Ctrl.addListener(listener);
      fatPer100Ctrl.addListener(listener);
      recalculate();
      return () {
        gramsCtrl.removeListener(listener);
        kcalPer100Ctrl.removeListener(listener);
        proteinPer100Ctrl.removeListener(listener);
        carbsPer100Ctrl.removeListener(listener);
        fatPer100Ctrl.removeListener(listener);
      };
    }, []);

    // ── Save ─────────────────────────────────────────────────────────────────

    final notifier = ref.read(nutritionNotifierProvider.notifier);

    Future<void> handleSave() async {
      FocusScope.of(context).unfocus();
      errorMsg.value = null;
      if (!(formKey.currentState?.validate() ?? false)) return;

      final name = nameCtrl.text.trim();
      final raw = gramsCtrl.text.trim().replaceAll(',', '.');
      final grams = double.tryParse(raw);
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
                content: Text('$name gespeichert', style: AppTextStyles.labelMd.copyWith(color: Colors.white)),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.surface900,
        appBar: AppBar(
          backgroundColor: AppColors.surface900.withValues(alpha: 0.9),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            isEditMode ? 'EINTRAG BEARBEITEN' : 'EINTRAG HINZUFÜGEN',
            style: AppTextStyles.h3.copyWith(letterSpacing: 1.2),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, _accentColor.withValues(alpha: 0.8), Colors.transparent],
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
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  children: [
                    // ── Search / Scan shortcuts ────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _ShortcutButton(
                            icon: Icons.search,
                            label: 'SUCHEN',
                            onTap: () async {
                              FocusScope.of(context).unfocus();
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
                        const Gap(16),
                        Expanded(
                          child: _ShortcutButton(
                            icon: Icons.qr_code_scanner,
                            label: 'SCAN',
                            onTap: () async {
                              FocusScope.of(context).unfocus();
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
                    const Gap(24),
                    Divider(color: AppColors.surface500.withValues(alpha: 0.3), height: 1),
                    const Gap(24),

                    // ── Meal selector ──────────────────────────────────────
                    Text(
                      'MAHLZEIT',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textDisabled,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const Gap(12),
                    _MealSelector(
                      selected: selectedMeal.value,
                      onChanged: (m) => selectedMeal.value = m,
                    ),
                    const Gap(32),

                    // ── Product name ───────────────────────────────────────
                    _EntryField(
                      controller: nameCtrl,
                      label: 'Name',
                      hintText: 'z. B. Hühnerbrust',
                      keyboardType: TextInputType.text,
                      inputFormatters: const [],
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Name ist erforderlich';
                        return null;
                      },
                    ),
                    const Gap(20),

                    // ── Menge ──────────────────────────────────────────────
                    _EntryField(
                      controller: gramsCtrl,
                      label: 'Menge (g)',
                      hintText: '100',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      selectAllOnFocus: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const Gap(32),

                    // ── Per-100g section ───────────────────────────────────
                    Text(
                      'NÄHRWERTE PRO 100 G',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textDisabled,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: _EntryField(
                            controller: kcalPer100Ctrl,
                            label: 'kcal',
                            hintText: '0',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            selectAllOnFocus: true,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 0) return 'Ungültig';
                              return null;
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _EntryField(
                            controller: proteinPer100Ctrl,
                            label: 'Protein (g)',
                            hintText: '0',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            selectAllOnFocus: true,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: _EntryField(
                            controller: carbsPer100Ctrl,
                            label: 'Kohlenh. (g)',
                            hintText: '0',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            selectAllOnFocus: true,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _EntryField(
                            controller: fatPer100Ctrl,
                            label: 'Fett (g)',
                            hintText: '0',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            selectAllOnFocus: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          ),
                        ),
                      ],
                    ),
                    const Gap(40),

                    // ── Preview card ───────────────────────────────────────
                    _CalcPreview(
                      kcal: actualKcal.value,
                      protein: actualProtein.value,
                      carbs: actualCarbs.value,
                      fat: actualFat.value,
                      grams: double.tryParse(
                            gramsCtrl.text.trim().replaceAll(',', '.'),
                          ) ??
                          100,
                    ),
                    const Gap(32),

                    // ── Error ──────────────────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: errorMsg.value != null
                          ? Container(
                              key: const ValueKey('error'),
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.errorGlow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                  const Gap(12),
                                  Expanded(
                                    child: Text(
                                      errorMsg.value!,
                                      style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('no_error')),
                    ),
                  ],
                ),
              ),
            ),
            
            // ── Sticky Bottom Action Bar ────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: AppColors.surface800.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(top: BorderSide(color: AppColors.surface500.withValues(alpha: 0.5))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: isSaving.value ? null : handleSave,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSaving.value ? _accentColor.withValues(alpha: 0.5) : _accentColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isSaving.value)
                            BoxShadow(
                              color: _accentColor.withValues(alpha: 0.3),
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                isEditMode ? 'AKTUALISIEREN' : 'SPEICHERN',
                                style: AppTextStyles.buttonLg.copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  if (!isEditMode) ...[
                    const Gap(12),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Text(
                          'ABBRECHEN',
                          style: AppTextStyles.buttonMd.copyWith(color: AppColors.textDisabled),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search / Scan Button Helper ──────────────────────────────────────────────
class _ShortcutButton extends HookWidget {
  const _ShortcutButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);

    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) {
        isPressed.value = false;
        onTap();
      },
      onTapCancel: () => isPressed.value = false,
      child: AnimatedScale(
        scale: isPressed.value ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: _accentColor),
              const Gap(8),
              Text(label, style: AppTextStyles.labelMd.copyWith(color: _accentColor)),
            ],
          ),
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
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: MealType.values.map((meal) {
          final isSelected = meal == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onChanged(meal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _accentColor.withValues(alpha: 0.15) : AppColors.surface800,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? _accentColor.withValues(alpha: 0.8) : AppColors.surface500.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  meal.displayName,
                  style: AppTextStyles.labelLg.copyWith(
                    color: isSelected ? _accentColor : AppColors.textSecondary,
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
    final hasData = kcal > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface800.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasData ? _accentColor.withValues(alpha: 0.3) : AppColors.surface500.withValues(alpha: 0.5),
          width: hasData ? 1.5 : 1.0,
        ),
        boxShadow: hasData
            ? [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FÜR ${grams.toStringAsFixed(0)} G',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textDisabled,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '$kcal',
                style: AppTextStyles.displayMd.copyWith(color: hasData ? _accentColor : AppColors.textSecondary, fontSize: 32),
              ),
              const Gap(4),
              Text(
                'kcal',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.textDisabled),
              ),
            ],
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MacroChip(label: 'PROTEIN', value: protein, color: _proteinColor),
              Container(height: 30, width: 1, color: AppColors.surface500.withValues(alpha: 0.5)),
              _MacroChip(label: 'KOHLENH.', value: carbs, color: _carbsColor),
              Container(height: 30, width: 1, color: AppColors.surface500.withValues(alpha: 0.5)),
              _MacroChip(label: 'FETT', value: fat, color: _fatColor),
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
          style: AppTextStyles.h3.copyWith(color: color),
        ),
        const Gap(4),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(color: AppColors.textDisabled, letterSpacing: 1.2, fontSize: 9),
        ),
      ],
    );
  }
}

// ─── Reusable text form field ─────────────────────────────────────────────────

class _EntryField extends HookWidget {
  const _EntryField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.keyboardType,
    required this.inputFormatters,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.selectAllOnFocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool selectAllOnFocus;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final isFocused = useState(focusNode.hasFocus);

    useEffect(() {
      void listener() => isFocused.value = focusNode.hasFocus;
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyLg,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted ?? (_) => FocusScope.of(context).nextFocus(),
      onTap: selectAllOnFocus
          ? () {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: AppTextStyles.labelMd.copyWith(
          color: isFocused.value ? _accentColor : AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: isFocused.value ? AppColors.surface800 : AppColors.surface700.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.surface500.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
