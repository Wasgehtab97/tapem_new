import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../router/route_names.dart';
import '../providers/admin_providers.dart';

/// Consolidated owner overview — all key KPIs on a single screen.
/// Designed to be scan-readable in under 2 minutes.
class AdminOwnerOverviewScreen extends ConsumerWidget {
  const AdminOwnerOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) {
      return Scaffold(
        backgroundColor: AppColors.surface900,
        appBar: AppBar(
          title: const Text('OWNER OVERVIEW'),
          backgroundColor: AppColors.surface900,
        ),
        body: const Center(child: Text('Kein aktives Gym.')),
      );
    }

    final statsAsync = ref.watch(ownerOverviewProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('OWNER OVERVIEW'),
        backgroundColor: AppColors.surface900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(ownerOverviewProvider(gymId)),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.toString(),
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(ownerOverviewProvider(gymId)),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Open tasks banner (only shown when there are tasks) ────────
            if (stats.openTasksTotal > 0) ...[
              _OpenTasksBanner(stats: stats),
              const SizedBox(height: 16),
            ],

            // ── Activation funnel ──────────────────────────────────────────
            const Text('AKTIVIERUNGS-FUNNEL', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            _FunnelCard(stats: stats),
            const SizedBox(height: 16),

            // ── Activity metrics ───────────────────────────────────────────
            const Text('NUTZUNG', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'Workouts',
                    sublabel: 'Diesen Monat',
                    value: '${stats.sessionsThisMonth}',
                    color: AppColors.neonCyan,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiCard(
                    label: 'Workouts/User',
                    sublabel: '30 Tage',
                    value: stats.workoutsPerActiveUser30d.toStringAsFixed(1),
                    color: AppColors.neonMagenta,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiCard(
                    label: 'Aktiv',
                    sublabel: '30 Tage',
                    value: '${stats.funnelActive30d}',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Equipment NFC coverage ─────────────────────────────────────
            const Text('EQUIPMENT & NFC', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            _NfcCoverageCard(stats: stats),
            const SizedBox(height: 16),

            // ── Challenges ─────────────────────────────────────────────────
            const Text('CHALLENGES', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            _KpiCard(
              label: 'Aktive Challenges',
              sublabel: 'Laufen gerade',
              value: '${stats.activeChallenges}',
              color: AppColors.neonYellow,
            ),
            const SizedBox(height: 16),

            // ── Quick links ────────────────────────────────────────────────
            const Text('SCHNELLZUGRIFF', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            _QuickLinksGrid(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Open tasks banner ────────────────────────────────────────────────────────

class _OpenTasksBanner extends StatelessWidget {
  const _OpenTasksBanner({required this.stats});
  final OwnerOverviewStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offene Aufgaben: ${stats.openTasksTotal}',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 2),
                _buildTaskList(stats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(OwnerOverviewStats stats) {
    final parts = <String>[];
    if (stats.openJoinRequests > 0) {
      parts.add('${stats.openJoinRequests} Beitrittsanfragen');
    }
    if (stats.openFeedbacks > 0) {
      parts.add('${stats.openFeedbacks} Geräte-Feedbacks');
    }
    if (stats.openReports > 0) {
      parts.add('${stats.openReports} Moderationsfälle');
    }
    return Text(
      parts.join(' · '),
      style: AppTextStyles.bodySm.copyWith(color: AppColors.error.withAlpha(200)),
    );
  }
}

// ─── Activation funnel card ───────────────────────────────────────────────────

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({required this.stats});
  final OwnerOverviewStats stats;

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
        children: [
          _FunnelStep(
            label: 'Beigetreten',
            value: stats.funnelJoined,
            total: stats.funnelRegistered,
            color: AppColors.neonCyan,
            isFirst: true,
          ),
          _FunnelStep(
            label: '1. Workout absolviert',
            value: stats.funnelFirstWorkout,
            total: stats.funnelJoined,
            color: AppColors.neonMagenta,
          ),
          _FunnelStep(
            label: 'Aktiv in 7 Tagen',
            value: stats.funnelActive7d,
            total: stats.funnelJoined,
            color: AppColors.success,
          ),
          _FunnelStep(
            label: 'Aktiv in 30 Tagen',
            value: stats.funnelActive30d,
            total: stats.funnelJoined,
            color: AppColors.neonYellow,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _FunnelStep extends StatelessWidget {
  const _FunnelStep({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final int value;
  final int total;
  final Color color;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.bodySm),
              const Spacer(),
              Text(
                '$value',
                style: AppTextStyles.labelMd.copyWith(color: color),
              ),
              const SizedBox(width: 6),
              Text(
                total > 0 ? '(${(pct * 100).round()}%)' : '',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: AppColors.surface600,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── NFC coverage card ────────────────────────────────────────────────────────

class _NfcCoverageCard extends StatelessWidget {
  const _NfcCoverageCard({required this.stats});
  final OwnerOverviewStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = stats.nfcCoveragePercent;
    final color = pct >= 70
        ? AppColors.success
        : pct >= 40
            ? AppColors.neonYellow
            : AppColors.error;

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
              const Icon(Icons.nfc, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'NFC-Abdeckung: $pct%',
                style: AppTextStyles.labelMd.copyWith(color: color),
              ),
              const Spacer(),
              Text(
                '${stats.equipmentWithNfc}/${stats.equipmentTotal} Geräte',
                style: AppTextStyles.bodySm,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: stats.equipmentTotal == 0
                  ? 0
                  : stats.equipmentWithNfc / stats.equipmentTotal,
              backgroundColor: AppColors.surface600,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
          if (stats.equipmentTotal > 0 && stats.equipmentWithNfc < stats.equipmentTotal) ...[
            const SizedBox(height: 6),
            Text(
              '${stats.equipmentTotal - stats.equipmentWithNfc} Geräte noch ohne NFC-Tag',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── KPI card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
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
        border: Border.all(color: AppColors.surface500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.labelSm),
          Text(
            sublabel,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick links ──────────────────────────────────────────────────────────────

class _QuickLinksGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuickLink(
          label: 'Mitglieder',
          icon: Icons.people_outline,
          route: RouteNames.adminMembers,
        ),
        _QuickLink(
          label: 'Challenges',
          icon: Icons.emoji_events_outlined,
          route: RouteNames.adminChallenges,
        ),
        _QuickLink(
          label: 'Equipment',
          icon: Icons.precision_manufacturing_outlined,
          route: RouteNames.adminEquipment,
        ),
        _QuickLink(
          label: 'NFC Tags',
          icon: Icons.nfc,
          route: RouteNames.adminNfc,
        ),
        _QuickLink(
          label: 'Feedback',
          icon: Icons.feedback_outlined,
          route: RouteNames.adminEquipmentFeedback,
        ),
        _QuickLink(
          label: 'Aktivität',
          icon: Icons.analytics_outlined,
          route: RouteNames.adminAnalytics,
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface700,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.labelSm),
          ],
        ),
      ),
    );
  }
}
