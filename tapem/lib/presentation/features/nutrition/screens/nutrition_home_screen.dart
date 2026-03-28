import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_enums.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/nutrition_providers.dart';

class NutritionHomeScreen extends HookConsumerWidget {
  const NutritionHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final nutritionState = ref.watch(nutritionNotifierProvider);
    final notifier = ref.read(nutritionNotifierProvider.notifier);

    useEffect(() {
      if (user != null) {
        Future.microtask(() => notifier.load(user.id));
      }
      return null;
    }, [user?.id]);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        backgroundColor: AppColors.surface900,
        surfaceTintColor: Colors.transparent,
        title: Text('ERNÄHRUNG', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: AppColors.textSecondary),
            onPressed: () => context.push('/nutrition/goals'),
            tooltip: 'Ziele',
          ),
        ],
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
      body: nutritionState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            )
          : nutritionState.error != null
              ? _ErrorState(
                  message: nutritionState.error!,
                  onRetry: user != null
                      ? () => notifier.load(user.id)
                      : null,
                )
              : _HomeBody(state: nutritionState, uid: user?.id ?? ''),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state, required this.uid});

  final NutritionDayState state;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final log = state.log;
    final goal = state.goal;
    final consumed = log?.totalKcal ?? 0;
    final target = goal?.kcal ?? 2000;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    final statusColor = switch (log?.status) {
      NutritionStatus.over => AppColors.error,
      NutritionStatus.on => AppColors.neonCyan,
      _ => AppColors.neonCyanDim,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Calorie summary card ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface500),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HEUTE',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Gap(8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$consumed',
                    style: AppTextStyles.h1.copyWith(
                      color: statusColor,
                      fontSize: 48,
                    ),
                  ),
                  const Gap(8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '/ $target kcal',
                      style: AppTextStyles.bodyLg.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surface500,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                  minHeight: 6,
                ),
              ),
              const Gap(16),
              _MacroRow(
                label: 'PROTEIN',
                value: log?.totalProtein ?? 0,
                target: goal?.protein ?? 150,
                color: Colors.blueAccent,
              ),
              const Gap(8),
              _MacroRow(
                label: 'KOHLENH.',
                value: log?.totalCarbs ?? 0,
                target: goal?.carbs ?? 250,
                color: Colors.amberAccent,
              ),
              const Gap(8),
              _MacroRow(
                label: 'FETT',
                value: log?.totalFat ?? 0,
                target: goal?.fat ?? 67,
                color: Colors.orangeAccent,
              ),
            ],
          ),
        ),
        const Gap(16),

        // ── Quick-log button ───────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: Text('HEUTE LOGGEN', style: AppTextStyles.buttonMd),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonCyan,
              foregroundColor: AppColors.textOnAction,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => context.push(
              '/nutrition/day',
              extra: {'uid': uid},
            ),
          ),
        ),
        const Gap(16),

        // ── Nav tiles ─────────────────────────────────────────────────────
        _NavTile(
          icon: Icons.restaurant_menu_outlined,
          label: 'REZEPTE',
          onTap: () => context.push(
            '/nutrition/recipes',
            extra: {'uid': uid},
          ),
        ),
        const Gap(8),
        _NavTile(
          icon: Icons.monitor_weight_outlined,
          label: 'GEWICHT TRACKEN',
          onTap: () => context.push('/nutrition/weight'),
        ),
        const Gap(8),
        _NavTile(
          icon: Icons.calendar_month_outlined,
          label: 'JAHRESÜBERSICHT',
          onTap: () => context.push(
            '/nutrition/calendar',
            extra: {'uid': uid},
          ),
        ),
        const Gap(32),
        // ── Data attribution (ODbL compliance) ────────────────────────────
        Center(
          child: Column(
            children: [
              Text(
                'DATENQUELLEN',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
              const Gap(4),
              Text(
                'Produktdaten von Open Food Facts (openfoodfacts.org)',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Lizenz: Open Database License (ODbL)',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(2),
              Text(
                'Nährwertdaten von USDA FoodData Central',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const Gap(16),
      ],
    );
  }
}

// ─── Macro progress row ───────────────────────────────────────────────────────

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final int value;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: p,
              backgroundColor: AppColors.surface500,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ),
        const Gap(8),
        Text('$value g', style: AppTextStyles.labelSm),
      ],
    );
  }
}

// ─── Nav tile ─────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const Gap(12),
            Text(label, style: AppTextStyles.labelLg),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const Gap(12),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const Gap(16),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'ERNEUT VERSUCHEN',
                  style: AppTextStyles.buttonMd.copyWith(
                    color: AppColors.neonCyan,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
