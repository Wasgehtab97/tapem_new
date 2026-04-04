import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../providers/admin_providers.dart';

class AdminModerationScreen extends HookConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) return _errorScaffold('Kein aktives Gym.');

    final reportsAsync = ref.watch(contentReportsProvider(gymId));
    final showResolved = useState(false);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('MODERATION'),
        backgroundColor: AppColors.surface900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(contentReportsProvider(gymId)),
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
        ),
        data: (reports) {
          final pending = reports.where((r) => r.isPending).toList();
          final resolved =
              reports.where((r) => !r.isPending).toList();

          return Column(
            children: [
              // Filter toggle
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'OFFEN (${pending.length})',
                      selected: !showResolved.value,
                      color: pending.isNotEmpty
                          ? AppColors.error
                          : AppColors.textSecondary,
                      onTap: () => showResolved.value = false,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'ERLEDIGT (${resolved.length})',
                      selected: showResolved.value,
                      color: AppColors.textSecondary,
                      onTap: () => showResolved.value = true,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Builder(
                  builder: (ctx) {
                    final list =
                        showResolved.value ? resolved : pending;
                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              showResolved.value
                                  ? Icons.check_circle_outline
                                  : Icons.shield_outlined,
                              size: 48,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              showResolved.value
                                  ? 'Keine erledigten Meldungen.'
                                  : 'Keine offenen Meldungen.',
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ReportCard(
                        report: list[i],
                        gymId: gymId,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Report card ──────────────────────────────────────────────────────────────

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report, required this.gymId});

  final ContentReport report;
  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd.MM.yy HH:mm');
    final notifier = ref.watch(moderationNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: report.isPending
              ? AppColors.error.withAlpha(60)
              : AppColors.surface500,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor(report.reportType).withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _typeColor(report.reportType).withAlpha(80),
                    ),
                  ),
                  child: Text(
                    _typeLabel(report.reportType).toUpperCase(),
                    style: AppTextStyles.bodySm.copyWith(
                      color: _typeColor(report.reportType),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (report.targetUsername != null) ...[
                  const Icon(Icons.person_outline,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '@${report.targetUsername}',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(
                  fmt.format(report.createdAt.toLocal()),
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),

          // Description
          if (report.description != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(report.description!, style: AppTextStyles.bodyMd),
            ),

          // Reporter
          if (report.reporterUsername != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Gemeldet von: @${report.reporterUsername}',
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),

          // Admin note (if resolved)
          if (report.adminNote != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface700,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.surface500),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report.adminNote!,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Actions — only for pending reports
          if (report.isPending) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: notifier.isLoading
                          ? null
                          : () => _resolve(context, ref, 'dismiss'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side:
                            const BorderSide(color: AppColors.surface500),
                      ),
                      child: const Text('ABLEHNEN'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: notifier.isLoading
                          ? null
                          : () => _showResolveDialog(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: const Text('MASSNAHME'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    String action, {
    String? note,
  }) async {
    await ref.read(moderationNotifierProvider.notifier).resolveReport(
          gymId: gymId,
          reportId: report.id,
          action: action,
          note: note,
        );
    if (!context.mounted) return;
    final err = ref.read(moderationNotifierProvider).error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $err'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meldung bearbeitet.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref) {
    unawaited(showDialog<void>(
      context: context,
      builder: (_) => _ResolveDialog(
        onResolve: (action, note) => _resolve(context, ref, action, note: note),
      ),
    ));
  }

  Color _typeColor(String type) => switch (type) {
        'spam' => AppColors.neonYellow,
        'harassment' => AppColors.error,
        'inappropriate_content' => AppColors.neonMagenta,
        _ => AppColors.textSecondary,
      };

  String _typeLabel(String type) => switch (type) {
        'spam' => 'Spam',
        'harassment' => 'Belästigung',
        'inappropriate_content' => 'Unangemessen',
        _ => type,
      };
}

// ─── Resolve dialog ───────────────────────────────────────────────────────────

class _ResolveDialog extends HookWidget {
  const _ResolveDialog({required this.onResolve});

  final Future<void> Function(String action, String? note) onResolve;

  @override
  Widget build(BuildContext context) {
    final noteCtrl = useTextEditingController();
    final action = useState('warn');

    return AlertDialog(
      backgroundColor: AppColors.surface800,
      title: Text('MASSNAHME ERGREIFEN', style: AppTextStyles.h3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AKTION', style: AppTextStyles.labelSm),
          const SizedBox(height: 8),
          _ActionChoice(
            options: const [
              ('warn', 'Verwarnen'),
              ('remove_content', 'Inhalt entfernen'),
              ('ban', 'Mitglied sperren'),
            ],
            selected: action.value,
            onChanged: (v) => action.value = v,
          ),
          const SizedBox(height: 16),
          TapemTextField(
            label: 'NOTIZ (optional)',
            controller: noteCtrl,
            hintText: 'Interne Admin-Notiz',
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ABBRECHEN'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(onResolve(
              action.value,
              noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.textPrimary,
          ),
          child: const Text('BESTÄTIGEN'),
        ),
      ],
    );
  }
}

class _ActionChoice extends StatelessWidget {
  const _ActionChoice({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((o) {
        final isSelected = o.$1 == selected;
        return GestureDetector(
          onTap: () => onChanged(o.$1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.error.withAlpha(20)
                  : AppColors.surface700,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppColors.error : AppColors.surface500,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color: isSelected ? AppColors.error : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  o.$2,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(25) : AppColors.surface700,
          borderRadius: BorderRadius.circular(6),
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
        title: const Text('MODERATION'),
        backgroundColor: AppColors.surface900,
      ),
      body: Center(
        child: Text(message,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
      ),
    );
