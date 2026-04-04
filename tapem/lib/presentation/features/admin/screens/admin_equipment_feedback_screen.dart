import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_providers.dart';

class AdminEquipmentFeedbackScreen extends HookConsumerWidget {
  const AdminEquipmentFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) return _errorScaffold('Kein aktives Gym.');

    final feedbackAsync = ref.watch(equipmentFeedbackAdminProvider(gymId));
    final statusFilter = useState<String?>('open'); // null = all

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('GERÄTE-FEEDBACK'),
        backgroundColor: AppColors.surface900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(equipmentFeedbackAdminProvider(gymId)),
          ),
        ],
      ),
      body: feedbackAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
        ),
        data: (allItems) {
          // Status filter
          final items = statusFilter.value == null
              ? allItems
              : allItems
                  .where((i) => i.status == statusFilter.value)
                  .toList();

          // Badge counts
          final openCount =
              allItems.where((i) => i.status == 'open').length;
          final inProgressCount =
              allItems.where((i) => i.status == 'in_progress').length;
          final resolvedCount =
              allItems.where((i) => i.status == 'resolved').length;

          return Column(
            children: [
              // ── Status filter bar ─────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterPill(
                      label: 'ALLE (${allItems.length})',
                      selected: statusFilter.value == null,
                      color: AppColors.textSecondary,
                      onTap: () => statusFilter.value = null,
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'OFFEN ($openCount)',
                      selected: statusFilter.value == 'open',
                      color: AppColors.error,
                      onTap: () => statusFilter.value = 'open',
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'IN BEARBEITUNG ($inProgressCount)',
                      selected: statusFilter.value == 'in_progress',
                      color: AppColors.neonYellow,
                      onTap: () => statusFilter.value = 'in_progress',
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'GELÖST ($resolvedCount)',
                      selected: statusFilter.value == 'resolved',
                      color: AppColors.success,
                      onTap: () => statusFilter.value = 'resolved',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── List ─────────────────────────────────────────────────────
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.thumb_up_outlined,
                              size: 48,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              statusFilter.value == 'open'
                                  ? 'Kein offenes Feedback — alles erledigt!'
                                  : 'Keine Einträge in dieser Kategorie.',
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _FeedbackCard(
                          item: items[i],
                          gymId: gymId,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Feedback card ────────────────────────────────────────────────────────────

class _FeedbackCard extends ConsumerWidget {
  const _FeedbackCard({required this.item, required this.gymId});

  final EquipmentFeedbackItem item;
  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd.MM.yy HH:mm');
    final notifier = ref.watch(feedbackManagementProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _statusBorderColor(item.status),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor(item.feedbackType).withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _typeColor(item.feedbackType).withAlpha(80),
                    ),
                  ),
                  child: Text(
                    _typeLabel(item.feedbackType).toUpperCase(),
                    style: AppTextStyles.bodySm.copyWith(
                      color: _typeColor(item.feedbackType),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.equipmentName,
                    style: AppTextStyles.bodyMd,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status menu
                if (item.status != 'resolved')
                  notifier.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              color: AppColors.textSecondary, size: 20),
                          onSelected: (newStatus) =>
                              _updateStatus(context, ref, newStatus),
                          itemBuilder: (_) => [
                            if (item.status != 'in_progress')
                              const PopupMenuItem(
                                value: 'in_progress',
                                child: Text('In Bearbeitung setzen'),
                              ),
                            const PopupMenuItem(
                              value: 'resolved',
                              child: Text('Als gelöst markieren'),
                            ),
                          ],
                        ),
              ],
            ),
          ),

          // Message
          if (item.message != null && item.message!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(item.message!, style: AppTextStyles.bodyMd),
            ),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    size: 12, color: AppColors.textDisabled),
                const SizedBox(width: 4),
                Text(
                  fmt.format(item.createdAt.toLocal()),
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textDisabled, fontSize: 10),
                ),
                if (item.reporterUsername != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.person_outline,
                      size: 12, color: AppColors.textDisabled),
                  const SizedBox(width: 4),
                  Text(
                    '@${item.reporterUsername}',
                    style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textDisabled, fontSize: 10),
                  ),
                ],
                const Spacer(),
                _StatusBadge(status: item.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String newStatus,
  ) async {
    await ref.read(feedbackManagementProvider.notifier).updateStatus(
          gymId: gymId,
          feedbackId: item.id,
          newStatus: newStatus,
        );
    if (!context.mounted) return;
    final err = ref.read(feedbackManagementProvider).error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $err'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color _statusBorderColor(String status) => switch (status) {
        'open' => AppColors.error.withAlpha(60),
        'in_progress' => AppColors.neonYellow.withAlpha(60),
        'resolved' => AppColors.success.withAlpha(40),
        _ => AppColors.surface500,
      };

  Color _typeColor(String type) => switch (type) {
        'broken' => AppColors.error,
        'maintenance' => AppColors.neonYellow,
        'suggestion' => AppColors.neonCyan,
        _ => AppColors.textSecondary,
      };

  String _typeLabel(String type) => switch (type) {
        'broken' => 'Defekt',
        'maintenance' => 'Wartung',
        'suggestion' => 'Vorschlag',
        _ => type,
      };
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color get _color => switch (status) {
        'open' => AppColors.error,
        'in_progress' => AppColors.neonYellow,
        'resolved' => AppColors.success,
        _ => AppColors.textSecondary,
      };

  String get _label => switch (status) {
        'open' => 'OFFEN',
        'in_progress' => 'IN ARBEIT',
        'resolved' => 'GELÖST',
        _ => status.toUpperCase(),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withAlpha(60)),
      ),
      child: Text(
        _label,
        style: AppTextStyles.bodySm.copyWith(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Filter pill ──────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(25) : AppColors.surface700,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.surface500,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySm.copyWith(
            color: selected ? color : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ─── Error scaffold ───────────────────────────────────────────────────────────

Scaffold _errorScaffold(String message) => Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('GERÄTE-FEEDBACK'),
        backgroundColor: AppColors.surface900,
      ),
      body: Center(
        child: Text(message,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
      ),
    );
