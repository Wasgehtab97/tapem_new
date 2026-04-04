import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_providers.dart';

enum _SortField { name, totalSets, last30d, uniqueUsers, lastUsed }

class AdminEquipmentAnalyticsScreen extends HookConsumerWidget {
  const AdminEquipmentAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) return _errorScaffold('Kein aktives Gym.');

    final statsAsync = ref.watch(equipmentUsageStatsProvider(gymId));
    final sortField = useState(_SortField.totalSets);
    final sortAsc = useState(false);
    final showInactive = useState(false);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('EQUIPMENT-NUTZUNG'),
        backgroundColor: AppColors.surface900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(equipmentUsageStatsProvider(gymId)),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
        data: (rawStats) {
          var stats = showInactive.value
              ? rawStats
              : rawStats.where((s) => s.isActive).toList();

          stats = _sortStats(stats, sortField.value, sortAsc.value);
          final nfcTagged = stats.where((s) => s.hasNfcTag).length;
          final nfcMissing = stats.length - nfcTagged;
          final feedbackOpen = stats.fold<int>(
            0,
            (sum, s) => sum + s.feedbackOpenCount,
          );
          final feedbackTotal = stats.fold<int>(
            0,
            (sum, s) => sum + s.feedbackTotalCount,
          );
          final nfcCoveragePct = stats.isEmpty
              ? 0
              : ((nfcTagged / stats.length) * 100).round();

          return Column(
            children: [
              // ── Filters / controls ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${stats.length} Geräte',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => showInactive.value = !showInactive.value,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: showInactive.value
                              ? AppColors.neonCyan.withAlpha(20)
                              : AppColors.surface700,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: showInactive.value
                                ? AppColors.neonCyan
                                : AppColors.surface500,
                          ),
                        ),
                        child: Text(
                          showInactive.value ? 'Inkl. Inaktive' : 'Nur Aktive',
                          style: AppTextStyles.bodySm.copyWith(
                            color: showInactive.value
                                ? AppColors.neonCyan
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TopMetricCard(
                        label: 'NFC Abdeckung',
                        value: '$nfcCoveragePct%',
                        sublabel: '$nfcTagged/${stats.length} getaggt',
                        color: nfcCoveragePct >= 70
                            ? AppColors.success
                            : nfcCoveragePct >= 40
                            ? AppColors.neonYellow
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TopMetricCard(
                        label: 'Offene Feedbacks',
                        value: '$feedbackOpen',
                        sublabel: '$feedbackTotal gesamt',
                        color: feedbackOpen == 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TopMetricCard(
                        label: 'Ohne NFC',
                        value: '$nfcMissing',
                        sublabel: 'Tagging-Potenzial',
                        color: nfcMissing == 0
                            ? AppColors.success
                            : AppColors.neonCyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Table header ───────────────────────────────────────────────
              Container(
                color: AppColors.surface800,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _SortableHeader(
                        label: 'GERÄT',
                        field: _SortField.name,
                        current: sortField.value,
                        asc: sortAsc.value,
                        onTap: () =>
                            _toggleSort(sortField, sortAsc, _SortField.name),
                      ),
                    ),
                    Expanded(
                      child: _SortableHeader(
                        label: 'GESAMT',
                        field: _SortField.totalSets,
                        current: sortField.value,
                        asc: sortAsc.value,
                        onTap: () => _toggleSort(
                          sortField,
                          sortAsc,
                          _SortField.totalSets,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _SortableHeader(
                        label: '30T',
                        field: _SortField.last30d,
                        current: sortField.value,
                        asc: sortAsc.value,
                        onTap: () =>
                            _toggleSort(sortField, sortAsc, _SortField.last30d),
                      ),
                    ),
                    Expanded(
                      child: _SortableHeader(
                        label: 'USER',
                        field: _SortField.uniqueUsers,
                        current: sortField.value,
                        asc: sortAsc.value,
                        onTap: () => _toggleSort(
                          sortField,
                          sortAsc,
                          _SortField.uniqueUsers,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Rows ────────────────────────────────────────────────────────
              Expanded(
                child: stats.isEmpty
                    ? Center(
                        child: Text(
                          'Noch keine Nutzungsdaten vorhanden.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: stats.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) =>
                            _EquipmentStatRow(stat: stats[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleSort(
    ValueNotifier<_SortField> field,
    ValueNotifier<bool> asc,
    _SortField tapped,
  ) {
    if (field.value == tapped) {
      asc.value = !asc.value;
    } else {
      field.value = tapped;
      asc.value = false;
    }
  }

  List<EquipmentUsageStat> _sortStats(
    List<EquipmentUsageStat> stats,
    _SortField field,
    bool ascending,
  ) {
    final sorted = [...stats];
    sorted.sort((a, b) {
      int cmp;
      switch (field) {
        case _SortField.name:
          cmp = a.equipmentName.compareTo(b.equipmentName);
        case _SortField.totalSets:
          cmp = a.totalSetsAllTime.compareTo(b.totalSetsAllTime);
        case _SortField.last30d:
          cmp = a.totalSetsLast30d.compareTo(b.totalSetsLast30d);
        case _SortField.uniqueUsers:
          cmp = a.uniqueUsers.compareTo(b.uniqueUsers);
        case _SortField.lastUsed:
          final aDate =
              a.lastUsedDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              b.lastUsedDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = aDate.compareTo(bDate);
      }
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }
}

// ─── Sortable header ──────────────────────────────────────────────────────────

class _SortableHeader extends StatelessWidget {
  const _SortableHeader({
    required this.label,
    required this.field,
    required this.current,
    required this.asc,
    required this.onTap,
  });

  final String label;
  final _SortField field;
  final _SortField current;
  final bool asc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = field == current;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: isActive ? AppColors.neonCyan : AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 2),
            Icon(
              asc ? Icons.arrow_upward : Icons.arrow_downward,
              size: 10,
              color: AppColors.neonCyan,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Equipment stat row ───────────────────────────────────────────────────────

class _EquipmentStatRow extends StatelessWidget {
  const _EquipmentStatRow({required this.stat});
  final EquipmentUsageStat stat;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yy');

    // Activity indicator: high/mid/low based on sets in last 30 days
    final activity = stat.totalSetsLast30d;
    final activityColor = activity >= 50
        ? AppColors.success
        : activity >= 10
        ? AppColors.neonYellow
        : AppColors.textDisabled;

    return Container(
      color: stat.isActive ? Colors.transparent : AppColors.surface800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Equipment name + type
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stat.isActive
                            ? activityColor
                            : AppColors.textDisabled,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stat.equipmentName,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: stat.isActive
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    stat.lastUsedDate != null
                        ? 'Zuletzt: ${dateFmt.format(stat.lastUsedDate!)}'
                        : 'Nie genutzt',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _RowInfoPill(
                        icon: Icons.nfc,
                        label: stat.hasNfcTag ? 'NFC' : 'Kein NFC',
                        color: stat.hasNfcTag
                            ? AppColors.success
                            : AppColors.textDisabled,
                      ),
                      _RowInfoPill(
                        icon: Icons.feedback_outlined,
                        label:
                            '${stat.feedbackOpenCount} offen / ${stat.feedbackTotalCount} total',
                        color: stat.feedbackOpenCount > 0
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Total sets
          Expanded(
            child: Text(
              _fmt(stat.totalSetsAllTime),
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Last 30d
          Expanded(
            child: Text(
              _fmt(stat.totalSetsLast30d),
              style: AppTextStyles.bodyMd.copyWith(
                color: activityColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Unique users
          Expanded(
            child: Text(
              _fmt(stat.uniqueUsers),
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _TopMetricCard extends StatelessWidget {
  const _TopMetricCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
            style: AppTextStyles.h3.copyWith(
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
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RowInfoPill extends StatelessWidget {
  const _RowInfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error scaffold ───────────────────────────────────────────────────────────

Scaffold _errorScaffold(String message) => Scaffold(
  backgroundColor: AppColors.surface900,
  appBar: AppBar(
    title: const Text('EQUIPMENT-NUTZUNG'),
    backgroundColor: AppColors.surface900,
  ),
  body: Center(
    child: Text(
      message,
      style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
    ),
  ),
);
