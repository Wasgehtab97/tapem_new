import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_providers.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) return _errorScaffold('Kein aktives Gym.');

    final statsAsync = ref.watch(gymActivityStatsProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('AKTIVITÄTS-DASHBOARD'),
        backgroundColor: AppColors.surface900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(gymActivityStatsProvider(gymId)),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(),
                  style:
                      AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.invalidate(gymActivityStatsProvider(gymId)),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── DAU / WAU / MAU ──────────────────────────────────────────────
            const Text('AKTIVE MITGLIEDER', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'DAU',
                    sublabel: 'Heute',
                    value: '${stats.dau}',
                    color: AppColors.neonCyan,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'WAU',
                    sublabel: '7 Tage',
                    value: '${stats.wau}',
                    color: AppColors.neonMagenta,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'MAU',
                    sublabel: '30 Tage',
                    value: '${stats.mau}',
                    color: AppColors.neonYellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Member overview ───────────────────────────────────────────────
            const Text('MITGLIEDER ÜBERSICHT', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'GESAMT',
                    sublabel: 'Mitglieder',
                    value: '${stats.totalMembers}',
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'NEU',
                    sublabel: 'Diesen Monat',
                    value: '${stats.newMembersThisMonth}',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'SESSIONS',
                    sublabel: 'Diesen Monat',
                    value: '${stats.totalSessionsThisMonth}',
                    color: AppColors.neonCyan,
                  ),
                ),
              ],
            ),
            if (stats.pendingApprovals > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.neonYellow.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neonYellow.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_empty,
                        color: AppColors.neonYellow, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${stats.pendingApprovals} Beitrittsanfragen warten auf Genehmigung',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.neonYellow),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Daily activity chart ──────────────────────────────────────────
            const Text('TÄGLICHE AKTIVITÄT (30 TAGE)', style: AppTextStyles.labelMd),
            const SizedBox(height: 12),
            if (stats.dailyActivity.isEmpty)
              Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surface500),
                ),
                child: Text(
                  'Keine Daten vorhanden',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              _DailyActivityChart(points: stats.dailyActivity),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.color,
  });

  final String label;
  final String sublabel;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.displayMd.copyWith(
              color: color,
              fontSize: 28,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: AppTextStyles.bodySm
                .copyWith(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─── Daily activity chart ─────────────────────────────────────────────────────

class _DailyActivityChart extends StatelessWidget {
  const _DailyActivityChart({required this.points});

  final List<DailyActivityPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = points
            .map((p) => p.activeUsers.toDouble())
            .fold(0.0, (a, b) => a > b ? a : b) *
        1.2;

    final spots = List.generate(
      points.length,
      (i) => FlSpot(i.toDouble(), points[i].activeUsers.toDouble()),
    );

    final labelFmt = DateFormat('dd.MM');

    // Show ~5 date labels evenly spaced
    final step = (points.length / 5).ceil().clamp(1, points.length);

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? (maxY / 4).clamp(1, double.infinity) : 1,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.surface500,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxY > 0 ? (maxY / 4).clamp(1, double.infinity) : 1,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: step.toDouble(),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labelFmt.format(points[idx].date),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxY > 0 ? maxY : 4,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.neonCyan,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.neonCyan.withAlpha(60),
                    AppColors.neonCyan.withAlpha(0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error scaffold ───────────────────────────────────────────────────────────

Scaffold _errorScaffold(String message) => Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('AKTIVITÄTS-DASHBOARD'),
        backgroundColor: AppColors.surface900,
      ),
      body: Center(
        child: Text(message,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
      ),
    );
