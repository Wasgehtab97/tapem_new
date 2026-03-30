import 'dart:async' show unawaited;

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
        unawaited(Future.microtask(() => notifier.load(uid, dateKey: dateKey)));
      }
      return null;
    }, [uid, dateKey]);

    final displayDate = _formatDateKey(dateKey);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      body: nutritionState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            )
          : nutritionState.error != null
              ? _ErrorBanner(message: nutritionState.error!)
              : CustomScrollView(
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
                          displayDate,
                          style: AppTextStyles.h2.copyWith(letterSpacing: 1.2),
                        ),
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
                    _DayBody(
                      state: nutritionState,
                      uid: uid,
                      dateKey: dateKey,
                      notifier: notifier,
                    ),
                  ],
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

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // ── Compact summary ─────────────────────────────────────────────
          _CompactSummary(state: state),

          if (entries.isEmpty)
            _EmptyState(uid: uid, dateKey: dateKey, goal: goal)
          else ...[
            const Gap(16),
            for (int i = 0; i < MealType.values.length; i++)
              _AnimatedMealSection(
                meal: MealType.values[i],
                entries: entries
                    .where((e) => e.meal == MealType.values[i])
                    .toList(),
                uid: uid,
                dateKey: dateKey,
                onDelete: (id) => notifier.removeEntry(id),
                index: i,
              ),
          ],
        ]),
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface800.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: AppColors.surface500.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$consumed',
                style: AppTextStyles.h1.copyWith(color: statusColor, fontSize: 32),
              ),
              const Gap(6),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '/ $target kcal',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const Spacer(),
              // Macro chips
              _MiniMacro(label: 'P', value: log?.totalProtein ?? 0, color: const Color(0xFF42A5F5)),
              const Gap(12),
              _MiniMacro(label: 'K', value: log?.totalCarbs ?? 0, color: const Color(0xFFFFCA28)),
              const Gap(12),
              _MiniMacro(label: 'F', value: log?.totalFat ?? 0, color: const Color(0xFF66BB6A)),
            ],
          ),
          const Gap(16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: AppColors.surface500.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation(statusColor),
                minHeight: 6,
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 10),
        ),
        const Gap(2),
        Text(
          '${value}g',
          style: AppTextStyles.labelMd.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

// ─── Meal section ─────────────────────────────────────────────────────────────

class _AnimatedMealSection extends HookWidget {
  const _AnimatedMealSection({
    required this.meal,
    required this.entries,
    required this.uid,
    required this.dateKey,
    required this.onDelete,
    required this.index,
  });

  final MealType meal;
  final List<NutritionEntry> entries;
  final String uid;
  final String dateKey;
  final void Function(String id) onDelete;
  final int index;

  @override
  Widget build(BuildContext context) {
    final mealKcal = entries.fold(0, (sum, e) => sum + e.kcal);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(16),
            // Meal header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    meal.displayName.toUpperCase(),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.neonCyan,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Gap(12),
                if (entries.isNotEmpty)
                  Text(
                    '$mealKcal kcal',
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary),
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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface700,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surface500),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 14, color: AppColors.textPrimary),
                        const Gap(6),
                        Text(
                          'HINZUFÜGEN',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Gap(12),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Noch nichts eingetragen',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textDisabled,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface800.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surface500.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: entries.map((entry) {
                    final isLast = entry == entries.last;
                    return Column(
                      children: [
                        _EntryTile(
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
                        if (!isLast)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.surface500.withValues(alpha: 0.4),
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const Gap(16),
          ],
        ),
      ),
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
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: AppTextStyles.labelLg.copyWith(fontSize: 15),
                    ),
                    const Gap(4),
                    Text(
                      [
                        if (entry.qty != null) '${entry.qty!.toStringAsFixed(0)} g',
                        'P ${entry.protein}g',
                        'K ${entry.carbs}g',
                        'F ${entry.fat}g',
                      ].join('  ·  '),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.kcal}',
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.neonCyan,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                    ),
                  ),
                ],
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
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface800.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCyan.withValues(alpha: 0.05),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: AppColors.neonCyanDim,
            ),
          ),
          const Gap(24),
          Text(
            'Noch keine Einträge',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          const Gap(12),
          Text(
            'Füge deine erste Mahlzeit hinzu und verfolge deine Ziele.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          GestureDetector(
            onTap: () => context.push(
              '/nutrition/entry',
              extra: {
                'meal': MealType.breakfast,
                'dateKey': dateKey,
                'uid': uid,
              },
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.neonCyan,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: AppColors.textOnAction, size: 20),
                  const Gap(8),
                  Text(
                    'EINTRAG HINZUFÜGEN',
                    style: AppTextStyles.buttonMd.copyWith(color: AppColors.textOnAction),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.errorGlow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            ),
            const Gap(16),
            Text(
              message,
              style: AppTextStyles.bodyLg,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
