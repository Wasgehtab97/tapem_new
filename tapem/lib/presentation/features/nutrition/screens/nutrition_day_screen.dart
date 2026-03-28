import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_entry.dart';
import '../../../../domain/entities/nutrition/nutrition_enums.dart';
import '../../../../domain/utils/nutrition_date_utils.dart';
import '../providers/nutrition_providers.dart';

class NutritionDayScreen extends HookConsumerWidget {
  const NutritionDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final uid = args?['uid'] as String? ?? '';
    final dateKey = args?['dateKey'] as String? ?? NutritionDateUtils.today();

    final nutritionState = ref.watch(nutritionNotifierProvider);
    final notifier = ref.read(nutritionNotifierProvider.notifier);

    useEffect(() {
      if (uid.isNotEmpty) {
        Future.microtask(() => notifier.load(uid, dateKey: dateKey));
      }
      return null;
    }, [uid, dateKey]);

    final displayDate = _formatDateKey(dateKey);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        backgroundColor: AppColors.surface900,
        surfaceTintColor: Colors.transparent,
        title: Text(displayDate, style: AppTextStyles.h3),
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
              ? _ErrorBanner(message: nutritionState.error!)
              : _DayBody(
                  state: nutritionState,
                  uid: uid,
                  dateKey: dateKey,
                  notifier: notifier,
                ),
    );
  }

  String _formatDateKey(String key) {
    final dt = NutritionDateUtils.fromDateKey(key);
    if (dt == null) return key;
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ─── Day body ─────────────────────────────────────────────────────────────────

class _DayBody extends StatelessWidget {
  const _DayBody({
    required this.state,
    required this.uid,
    required this.dateKey,
    required this.notifier,
  });

  final NutritionDayState state;
  final String uid;
  final String dateKey;
  final NutritionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final log = state.log;
    final goal = state.goal;
    final entries = log?.entries ?? [];

    return Column(
      children: [
        // ── Compact summary ─────────────────────────────────────────────
        _CompactSummary(state: state),

        // ── Meal sections ───────────────────────────────────────────────
        Expanded(
          child: entries.isEmpty
              ? _EmptyState(uid: uid, dateKey: dateKey, goal: goal)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    for (final meal in MealType.values)
                      _MealSection(
                        meal: meal,
                        entries: entries
                            .where((e) => e.meal == meal)
                            .toList(),
                        uid: uid,
                        dateKey: dateKey,
                        onDelete: (id) => notifier.removeEntry(id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ─── Compact summary bar ──────────────────────────────────────────────────────

class _CompactSummary extends StatelessWidget {
  const _CompactSummary({required this.state});

  final NutritionDayState state;

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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface800,
        border: Border(bottom: BorderSide(color: AppColors.surface500)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$consumed',
                style: AppTextStyles.h2.copyWith(color: statusColor),
              ),
              const Gap(6),
              Text(
                '/ $target kcal',
                style: AppTextStyles.bodySm,
              ),
              const Spacer(),
              // Macro chips
              _MiniMacro(label: 'P', value: log?.totalProtein ?? 0, color: Colors.blueAccent),
              const Gap(8),
              _MiniMacro(label: 'K', value: log?.totalCarbs ?? 0, color: Colors.amberAccent),
              const Gap(8),
              _MiniMacro(label: 'F', value: log?.totalFat ?? 0, color: Colors.orangeAccent),
            ],
          ),
          const Gap(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surface500,
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMacro extends StatelessWidget {
  const _MiniMacro({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: AppTextStyles.labelSm.copyWith(color: color),
        ),
        Text(
          '${value}g',
          style: AppTextStyles.labelSm,
        ),
      ],
    );
  }
}

// ─── Meal section ─────────────────────────────────────────────────────────────

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.meal,
    required this.entries,
    required this.uid,
    required this.dateKey,
    required this.onDelete,
  });

  final MealType meal;
  final List<NutritionEntry> entries;
  final String uid;
  final String dateKey;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final mealKcal = entries.fold(0, (sum, e) => sum + e.kcal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(16),
        // Meal header
        Row(
          children: [
            Text(
              meal.displayName.toUpperCase(),
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.neonCyan,
                letterSpacing: 1.2,
              ),
            ),
            const Gap(8),
            if (entries.isNotEmpty)
              Text(
                '$mealKcal kcal',
                style: AppTextStyles.labelSm,
              ),
            const Spacer(),
            // Add entry button for this meal
            InkWell(
              onTap: () => context.push(
                '/nutrition/entry',
                extra: {
                  'meal': meal,
                  'dateKey': dateKey,
                  'uid': uid,
                },
              ),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface700,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.surface500),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.neonCyan),
                    const Gap(4),
                    Text(
                      'HINZUFÜGEN',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.neonCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Gap(6),
        Container(height: 1, color: AppColors.surface500),
        const Gap(4),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Noch nichts eingetragen',
              style: AppTextStyles.bodySm,
            ),
          )
        else
          ...entries.map(
            (entry) => _EntryTile(
              entry: entry,
              onDelete: () => onDelete(entry.id),
              onTap: () => context.push(
                '/nutrition/entry',
                extra: {
                  'meal': entry.meal,
                  'dateKey': dateKey,
                  'uid': uid,
                  'entry': entry,
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Entry tile ───────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onDelete,
    required this.onTap,
  });

  final NutritionEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name, style: AppTextStyles.labelLg),
                    const Gap(2),
                    Text(
                      [
                        if (entry.qty != null) '${entry.qty!.toStringAsFixed(0)} g',
                        'P ${entry.protein}g',
                        'K ${entry.carbs}g',
                        'F ${entry.fat}g',
                      ].join('  ·  '),
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              const Gap(12),
              Text(
                '${entry.kcal} kcal',
                style: AppTextStyles.labelLg.copyWith(color: AppColors.neonCyan),
              ),
              const Gap(4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.textDisabled,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.uid,
    required this.dateKey,
    this.goal,
  });

  final String uid;
  final String dateKey;
  final dynamic goal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const Gap(16),
            Text(
              'Noch keine Einträge',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            ),
            const Gap(8),
            Text(
              'Füge deine erste Mahlzeit hinzu.',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text('EINTRAG HINZUFÜGEN', style: AppTextStyles.buttonMd),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: AppColors.textOnAction,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => context.push(
                '/nutrition/entry',
                extra: {
                  'meal': MealType.breakfast,
                  'dateKey': dateKey,
                  'uid': uid,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

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
          ],
        ),
      ),
    );
  }
}
