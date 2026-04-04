import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_goal.dart';
import '../../../../domain/utils/nutrition_date_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/nutrition_providers.dart';

class NutritionGoalsScreen extends HookConsumerWidget {
  const NutritionGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final nutritionState = ref.watch(nutritionNotifierProvider);
    final notifier = ref.read(nutritionNotifierProvider.notifier);

    final goal = nutritionState.goal;

    // Controllers pre-filled with current goal values
    final kcalCtrl = useTextEditingController(
      text: goal != null ? '${goal.kcal}' : '2000',
    );
    final proteinCtrl = useTextEditingController(
      text: goal != null ? '${goal.protein}' : '150',
    );
    final carbsCtrl = useTextEditingController(
      text: goal != null ? '${goal.carbs}' : '250',
    );
    final fatCtrl = useTextEditingController(
      text: goal != null ? '${goal.fat}' : '67',
    );

    final isSaving = useState(false);
    final errorMsg = useState<String?>(null);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    // Update controllers if goal loads after screen opens
    useEffect(() {
      if (goal != null) {
        kcalCtrl.text = '${goal.kcal}';
        proteinCtrl.text = '${goal.protein}';
        carbsCtrl.text = '${goal.carbs}';
        fatCtrl.text = '${goal.fat}';
      }
      return null;
    }, [goal?.kcal, goal?.protein, goal?.carbs, goal?.fat]);

    Future<void> handleSave() async {
      errorMsg.value = null;
      if (!(formKey.currentState?.validate() ?? false)) return;

      final kcal = int.tryParse(kcalCtrl.text.trim()) ?? 0;
      final protein = int.tryParse(proteinCtrl.text.trim()) ?? 0;
      final carbs = int.tryParse(carbsCtrl.text.trim()) ?? 0;
      final fat = int.tryParse(fatCtrl.text.trim()) ?? 0;

      final uid = user?.id;
      if (uid == null) {
        errorMsg.value = 'Nicht eingeloggt.';
        return;
      }

      // Ensure notifier has uid loaded
      if (nutritionState.goal == null) {
        await notifier.load(uid);
      }

      isSaving.value = true;
      try {
        final newGoal = NutritionGoal(
          dateKey: NutritionDateUtils.today(),
          kcal: kcal,
          protein: protein,
          carbs: carbs,
          fat: fat,
          updatedAt: DateTime.now(),
        );
        await notifier.saveGoal(newGoal);
        if (context.mounted) context.pop();
      } catch (e) {
        errorMsg.value = e.toString();
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        backgroundColor: AppColors.surface900,
        surfaceTintColor: Colors.transparent,
        title: Text('ZIELE', style: AppTextStyles.h3),
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text(
              'TÄGLICHE ZIELE',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const Gap(16),

            // ── Kalorien ──────────────────────────────────────────────────
            _GoalField(
              controller: kcalCtrl,
              label: 'Kalorien',
              unit: 'kcal',
              icon: Icons.local_fire_department_outlined,
              iconColor: AppColors.error,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Muss größer als 0 sein';
                return null;
              },
            ),
            const Gap(12),

            // ── Protein ───────────────────────────────────────────────────
            _GoalField(
              controller: proteinCtrl,
              label: 'Protein',
              unit: 'g',
              icon: Icons.fitness_center_outlined,
              iconColor: Colors.blueAccent,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Darf nicht negativ sein';
                return null;
              },
            ),
            const Gap(12),

            // ── Kohlenhydrate ─────────────────────────────────────────────
            _GoalField(
              controller: carbsCtrl,
              label: 'Kohlenhydrate',
              unit: 'g',
              icon: Icons.grain_outlined,
              iconColor: Colors.amberAccent,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Darf nicht negativ sein';
                return null;
              },
            ),
            const Gap(12),

            // ── Fett ──────────────────────────────────────────────────────
            _GoalField(
              controller: fatCtrl,
              label: 'Fett',
              unit: 'g',
              icon: Icons.water_drop_outlined,
              iconColor: Colors.orangeAccent,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Darf nicht negativ sein';
                return null;
              },
            ),
            const Gap(24),

            // ── Error ─────────────────────────────────────────────────────
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

            // ── Save button ───────────────────────────────────────────────
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
                    : const Text('SPEICHERN', style: AppTextStyles.buttonMd),
              ),
            ),

            const Gap(32),

            // ── Hint card ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surface500),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HINWEIS',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.neonCyan,
                    ),
                  ),
                  const Gap(8),
                  const Text(
                    'Diese Ziele gelten als Standardwert für alle Tage. '
                    'Änderungen wirken sich sofort auf die heutige Anzeige aus.',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Goal input field ─────────────────────────────────────────────────────────

class _GoalField extends StatelessWidget {
  const _GoalField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.bodyLg,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelLg.copyWith(
          color: AppColors.textSecondary,
        ),
        suffixText: unit,
        suffixStyle: AppTextStyles.bodySm,
        prefixIcon: Icon(icon, color: iconColor, size: 20),
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
