import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_enums.dart';
import '../../../../domain/entities/nutrition/nutrition_year_summary.dart';
import '../providers/nutrition_providers.dart';

class NutritionCalendarScreen extends HookConsumerWidget {
  const NutritionCalendarScreen({super.key, required this.extra});

  final Map<String, dynamic> extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = extra['uid'] as String? ?? '';
    final currentYear = useState(DateTime.now().year);

    final summaryAsync = ref.watch(
      nutritionYearSummaryProvider((uid: uid, year: currentYear.value)),
    );

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        backgroundColor: AppColors.surface900,
        surfaceTintColor: Colors.transparent,
        title: Text('JAHRESÜBERSICHT', style: AppTextStyles.h3),
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
          // ── Year selector ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.neonCyan),
                  onPressed: () => currentYear.value--,
                ),
                const Gap(8),
                Text(
                  '${currentYear.value}',
                  style: AppTextStyles.h2,
                ),
                const Gap(8),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: currentYear.value >= DateTime.now().year
                        ? AppColors.textDisabled
                        : AppColors.neonCyan,
                  ),
                  onPressed: currentYear.value >= DateTime.now().year
                      ? null
                      : () => currentYear.value++,
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: summaryAsync.when(
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
                      'Fehler beim Laden.',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                    ),
                    const Gap(8),
                    TextButton(
                      onPressed: () => ref.invalidate(
                        nutritionYearSummaryProvider((uid: uid, year: currentYear.value)),
                      ),
                      child: Text(
                        'ERNEUT VERSUCHEN',
                        style: AppTextStyles.buttonMd.copyWith(color: AppColors.neonCyan),
                      ),
                    ),
                  ],
                ),
              ),
              data: (summary) => _CalendarBody(
                year: currentYear.value,
                summary: summary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calendar body ────────────────────────────────────────────────────────────

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({required this.year, required this.summary});

  final int year;
  final NutritionYearSummary? summary;

  static const _monthNames = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  @override
  Widget build(BuildContext context) {
    final days = summary?.days ?? {};
    final isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    final totalDays = isLeap ? 366 : 365;

    // Count stats
    var logged = 0;
    var goalMet = 0;
    for (final day in days.values) {
      logged++;
      if (day.status == NutritionStatus.on || day.status == NutritionStatus.under) {
        goalMet++;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // ── Stats row ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surface500),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCell(
                label: 'GELOGGT',
                value: '$logged',
                total: '$totalDays',
                color: AppColors.neonCyan,
              ),
              Container(width: 1, height: 40, color: AppColors.surface500),
              _StatCell(
                label: 'ZIEL ERREICHT',
                value: '$goalMet',
                total: '$logged',
                color: AppColors.success,
              ),
              Container(width: 1, height: 40, color: AppColors.surface500),
              _StatCell(
                label: 'ÜBER ZIEL',
                value: '${logged - goalMet}',
                total: '$logged',
                color: AppColors.error,
              ),
            ],
          ),
        ),
        const Gap(16),

        // ── Legend ─────────────────────────────────────────────────
        Row(
          children: [
            _LegendDot(AppColors.success, 'Im/Unter Ziel'),
            const Gap(16),
            _LegendDot(AppColors.error, 'Über Ziel'),
            const Gap(16),
            _LegendDot(AppColors.surface600, 'Keine Daten'),
          ],
        ),
        const Gap(12),

        // ── Month grid ─────────────────────────────────────────────
        ...List.generate(12, (monthIndex) {
          return _MonthGrid(
            year: year,
            month: monthIndex + 1,
            monthName: _monthNames[monthIndex],
            days: days,
          );
        }),
      ],
    );
  }
}

// ─── Month grid ───────────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.year,
    required this.month,
    required this.monthName,
    required this.days,
  });

  final int year;
  final int month;
  final String monthName;
  final Map<String, NutritionDaySummary> days;

  Color _colorForDay(String dateKey) {
    final day = days[dateKey];
    if (day == null) return AppColors.surface600;
    switch (day.status) {
      case NutritionStatus.on:
      case NutritionStatus.under:
        // Intensity based on ratio: totalKcal / goalKcal
        final ratio = day.goalKcal > 0 ? (day.totalKcal / day.goalKcal).clamp(0.0, 1.2) : 0.5;
        // Green, darker = closer to goal
        final intensity = (ratio * 0.8 + 0.2).clamp(0.2, 1.0);
        return AppColors.success.withValues(alpha: intensity);
      case NutritionStatus.over:
        final ratio = day.goalKcal > 0 ? (day.totalKcal / day.goalKcal).clamp(1.0, 2.0) : 1.5;
        final excess = ((ratio - 1.0) * 0.8 + 0.3).clamp(0.3, 1.0);
        return AppColors.error.withValues(alpha: excess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon ... 7=Sun

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthName.toUpperCase(),
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary),
          ),
          const Gap(6),
          // Day-of-week header
          Row(
            children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.textDisabled),
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(4),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: firstWeekday - 1 + daysInMonth,
            itemBuilder: (context, index) {
              // Empty cells before the first of the month
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }
              final day = index - (firstWeekday - 1) + 1;
              final monthStr = month.toString().padLeft(2, '0');
              final dayStr = day.toString().padLeft(2, '0');
              final dateKey = '$year$monthStr$dayStr';

              final color = _colorForDay(dateKey);
              final isToday = dateKey ==
                  '${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}';

              return Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  border: isToday
                      ? Border.all(color: AppColors.neonCyan, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 8,
                      color: color == AppColors.surface600
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final String value;
  final String total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTextStyles.monoMd.copyWith(color: color),
              ),
              TextSpan(
                text: '/$total',
                style: AppTextStyles.monoSm,
              ),
            ],
          ),
        ),
        const Gap(2),
        Text(label, style: AppTextStyles.labelSm),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(4),
        Text(label, style: AppTextStyles.bodySm),
      ],
    );
  }
}
