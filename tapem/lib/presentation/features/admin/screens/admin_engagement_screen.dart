import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_providers.dart';

class AdminEngagementScreen extends ConsumerWidget {
  const AdminEngagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) return _errorScaffold('Kein aktives Gym.');

    final statsAsync = ref.watch(gymEngagementStatsProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('ENGAGEMENT-METRIKEN'),
        backgroundColor: AppColors.surface900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(gymEngagementStatsProvider(gymId)),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
        ),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Summary cards ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'AKTIVE MITGLIEDER',
                    value: '${stats.totalActiveMembers}',
                    color: AppColors.neonCyan,
                    icon: Icons.people_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    label: 'AKTIVE CHALLENGES',
                    value: '${stats.activeChallenges}',
                    color: AppColors.neonMagenta,
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Level distribution ────────────────────────────────────────────
            const Text('LEVEL-VERTEILUNG', style: AppTextStyles.labelMd),
            const SizedBox(height: 12),
            if (stats.levelDistribution.isEmpty)
              const _EmptyBlock(message: 'Noch keine Level-Daten.')
            else
              _LevelDistributionChart(buckets: stats.levelDistribution),
            const SizedBox(height: 24),

            // ── Top members ──────────────────────────────────────────────────
            const Text('TOP MITGLIEDER (DIESEN MONAT)', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            if (stats.topMembers.isEmpty)
              const _EmptyBlock(message: 'Noch keine Aktivität diesen Monat.')
            else
              ...List.generate(
                stats.topMembers.length,
                (i) => _TopMemberTile(
                  rank: i + 1,
                  entry: stats.topMembers[i],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.displayMd.copyWith(
                  color: color,
                  fontSize: 28,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Level distribution chart ─────────────────────────────────────────────────

class _LevelDistributionChart extends StatelessWidget {
  const _LevelDistributionChart({required this.buckets});
  final List<LevelBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        buckets.map((b) => b.count).fold(0, (a, b) => a > b ? a : b);
    final colors = [
      AppColors.neonCyan,
      AppColors.neonMagenta,
      AppColors.neonYellow,
      AppColors.success,
      AppColors.textSecondary,
      AppColors.neonCyanDim,
    ];

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCount * 1.2 + 1,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface700,
              getTooltipItem: (group, _, rod, __) {
                final bucket = buckets[group.x.toInt()];
                return BarTooltipItem(
                  '${bucket.range}\n${rod.toY.toInt()} Mitglieder',
                  AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
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
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      buckets[idx].range,
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.surface500,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(buckets.length, (i) {
            final color = colors[i % colors.length];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: buckets[i].count.toDouble(),
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─── Top member tile ──────────────────────────────────────────────────────────

class _TopMemberTile extends StatelessWidget {
  const _TopMemberTile({required this.rank, required this.entry});

  final int rank;
  final TopMemberEntry entry;

  Color get _rankColor => switch (rank) {
        1 => AppColors.neonYellow,
        2 => AppColors.textSecondary,
        3 => AppColors.neonYellowDim,
        _ => AppColors.textDisabled,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rank <= 3
              ? _rankColor.withAlpha(60)
              : AppColors.surface500,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: AppTextStyles.labelMd.copyWith(color: _rankColor),
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surface600,
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.username.isNotEmpty
                        ? entry.username[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.neonCyan),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${entry.username}', style: AppTextStyles.bodyMd),
                Text(
                  'Level ${entry.level} · ${entry.trainingDaysThisMonth} Trainingstage',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmtXp(entry.totalXp)} XP',
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.neonMagenta),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return '$xp';
  }
}

// ─── Empty block ──────────────────────────────────────────────────────────────

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─── Error scaffold ───────────────────────────────────────────────────────────

Scaffold _errorScaffold(String message) => Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('ENGAGEMENT-METRIKEN'),
        backgroundColor: AppColors.surface900,
      ),
      body: Center(
        child: Text(message,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
      ),
    );
