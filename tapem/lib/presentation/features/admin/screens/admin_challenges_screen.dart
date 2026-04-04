import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../providers/admin_providers.dart';

class _ChallengeTemplatePreset {
  const _ChallengeTemplatePreset({
    required this.name,
    required this.description,
    required this.title,
    required this.challengeType,
    required this.targetMetric,
    required this.durationDays,
  });

  final String name;
  final String description;
  final String title;
  final String challengeType;
  final double targetMetric;
  final int durationDays;
}

const _challengeTemplatePresets = <_ChallengeTemplatePreset>[
  _ChallengeTemplatePreset(
    name: 'Wöchentliche Trainingstage',
    description: '3 Trainingstage in 7 Tagen',
    title: 'Weekly Streak',
    challengeType: 'training_days',
    targetMetric: 3,
    durationDays: 7,
  ),
  _ChallengeTemplatePreset(
    name: 'Monatlicher Streak',
    description: '12 Trainingstage in 30 Tagen',
    title: 'Monthly Streak',
    challengeType: 'training_days',
    targetMetric: 12,
    durationDays: 30,
  ),
  _ChallengeTemplatePreset(
    name: 'XP Push',
    description: '1500 XP in 30 Tagen',
    title: 'XP Push',
    challengeType: 'total_xp',
    targetMetric: 1500,
    durationDays: 30,
  ),
  _ChallengeTemplatePreset(
    name: 'Volumen Boost',
    description: '20.000 kg Volumen in 30 Tagen',
    title: 'Volume Boost',
    challengeType: 'exercise_volume',
    targetMetric: 20000,
    durationDays: 30,
  ),
];

class AdminChallengesScreen extends HookConsumerWidget {
  const AdminChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) return _errorScaffold('Kein aktives Gym.');

    final challengesAsync = ref.watch(adminChallengesProvider(gymId));
    final kpisAsync = ref.watch(challengeKpisProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('CHALLENGES'),
        backgroundColor: AppColors.surface900,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Templates',
            onPressed: () => _showTemplatePicker(context, ref, gymId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.textOnAction,
        onPressed: () => _showCreateChallengeOptions(context, ref, gymId),
        child: const Icon(Icons.add),
      ),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
        data: (challenges) {
          final now = DateTime.now();
          final kpisByChallenge =
              kpisAsync.valueOrNull ?? const <String, ChallengeKpi>{};
          final kpis = challenges
              .map((c) => kpisByChallenge[c.id])
              .whereType<ChallengeKpi>()
              .toList();
          final running = challenges
              .where(
                (c) =>
                    c.isActive &&
                    c.startsAt.isBefore(now) &&
                    c.endsAt.isAfter(now),
              )
              .toList();
          final upcoming = challenges
              .where((c) => c.isActive && c.startsAt.isAfter(now))
              .toList();
          final ended = challenges
              .where((c) => !c.isActive || c.endsAt.isBefore(now))
              .toList();

          if (challenges.isEmpty) {
            return _EmptyState(
              onCreateTap: () =>
                  _showCreateChallengeOptions(context, ref, gymId),
              onTemplateTap: () => _showTemplatePicker(context, ref, gymId),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (kpisAsync.isLoading && kpisByChallenge.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              _ChallengeKpiOverview(kpis: kpis),
              const SizedBox(height: 16),
              if (running.isNotEmpty) ...[
                _SectionHeader(
                  label: 'AKTIV (${running.length})',
                  color: AppColors.success,
                ),
                const SizedBox(height: 8),
                ...running.map(
                  (c) => _ChallengeTile(
                    challenge: c,
                    gymId: gymId,
                    kpi: kpisByChallenge[c.id],
                    onDeactivate: () =>
                        _confirmDeactivate(context, ref, gymId, c.id),
                    onEdit: () => _showChallengeForm(context, ref, gymId, c),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(
                  label: 'GEPLANT (${upcoming.length})',
                  color: AppColors.neonCyan,
                ),
                const SizedBox(height: 8),
                ...upcoming.map(
                  (c) => _ChallengeTile(
                    challenge: c,
                    gymId: gymId,
                    kpi: kpisByChallenge[c.id],
                    onDeactivate: () =>
                        _confirmDeactivate(context, ref, gymId, c.id),
                    onEdit: () => _showChallengeForm(context, ref, gymId, c),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (ended.isNotEmpty) ...[
                _SectionHeader(
                  label: 'BEENDET / INAKTIV (${ended.length})',
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                ...ended.map(
                  (c) => _ChallengeTile(
                    challenge: c,
                    gymId: gymId,
                    kpi: kpisByChallenge[c.id],
                    onDeactivate: null,
                    onEdit: null,
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    String gymId,
    String challengeId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface800,
        title: Text('Challenge beenden?', style: AppTextStyles.h3),
        content: const Text(
          'Die Challenge wird sofort deaktiviert. Laufende Teilnahmen bleiben gespeichert.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'BEENDEN',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(challengeManagementProvider.notifier)
        .deactivateChallenge(gymId: gymId, challengeId: challengeId);

    if (!context.mounted) return;
    final err = ref.read(challengeManagementProvider).error;
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
          content: Text('Challenge wurde beendet.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

void _showCreateChallengeOptions(
  BuildContext context,
  WidgetRef ref,
  String gymId,
) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: AppColors.neonCyan,
              ),
              title: const Text('Leere Challenge erstellen'),
              subtitle: const Text('Volle Kontrolle über alle Felder'),
              onTap: () {
                Navigator.of(context).pop();
                _showChallengeForm(context, ref, gymId, null);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.auto_awesome,
                color: AppColors.neonYellow,
              ),
              title: const Text('Template auswählen'),
              subtitle: const Text('Schnellstart mit vorkonfigurierten Zielen'),
              onTap: () {
                Navigator.of(context).pop();
                _showTemplatePicker(context, ref, gymId);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void _showTemplatePicker(BuildContext context, WidgetRef ref, String gymId) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
              title: Text('CHALLENGE-TEMPLATES', style: AppTextStyles.labelMd),
              subtitle: Text('4 startfertige Formate für schnellen Rollout'),
            ),
            ..._challengeTemplatePresets.map((preset) {
              return ListTile(
                leading: const Icon(
                  Icons.bolt_outlined,
                  color: AppColors.neonCyan,
                ),
                title: Text(preset.name),
                subtitle: Text(preset.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _showChallengeForm(context, ref, gymId, null, preset: preset);
                },
              );
            }),
          ],
        ),
      ),
    ),
  );
}

// ─── Challenge tile ───────────────────────────────────────────────────────────

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.challenge,
    required this.gymId,
    required this.kpi,
    required this.onDeactivate,
    required this.onEdit,
  });

  final AdminChallenge challenge;
  final String gymId;
  final ChallengeKpi? kpi;
  final VoidCallback? onDeactivate;
  final VoidCallback? onEdit;

  Color get _statusColor {
    if (!challenge.isActive || challenge.endsAt.isBefore(DateTime.now())) {
      return AppColors.textDisabled;
    }
    if (challenge.startsAt.isAfter(DateTime.now())) return AppColors.neonCyan;
    return AppColors.success;
  }

  String get _statusLabel {
    if (!challenge.isActive) return 'INAKTIV';
    if (challenge.endsAt.isBefore(DateTime.now())) return 'BEENDET';
    if (challenge.startsAt.isAfter(DateTime.now())) return 'GEPLANT';
    return 'AKTIV';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yy');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(child: Text(challenge.title, style: AppTextStyles.bodyMd)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _statusColor.withAlpha(80)),
              ),
              child: Text(
                _statusLabel,
                style: AppTextStyles.bodySm.copyWith(
                  color: _statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${fmt.format(challenge.startsAt)} – ${fmt.format(challenge.endsAt)}',
                  style: AppTextStyles.bodySm,
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.bar_chart,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _typeLabel(challenge.challengeType),
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
            if (challenge.description != null) ...[
              const SizedBox(height: 4),
              Text(
                challenge.description!,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (kpi != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _KpiPill(
                    label:
                        'Teilnahme ${kpi!.participantsStarted}/${kpi!.eligibleMembers} (${kpi!.participationRatePct.toStringAsFixed(0)}%)',
                    color: AppColors.neonCyan,
                  ),
                  _KpiPill(
                    label:
                        'Completion ${kpi!.participantsCompleted} (${kpi!.completionRatePct.toStringAsFixed(0)}%)',
                    color: kpi!.completionRatePct >= 60
                        ? AppColors.success
                        : kpi!.completionRatePct >= 30
                        ? AppColors.neonYellow
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: (onDeactivate != null || onEdit != null)
            ? PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'deactivate') onDeactivate?.call();
                },
                itemBuilder: (_) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Bearbeiten'),
                    ),
                  if (onDeactivate != null)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Text('Beenden'),
                    ),
                ],
              )
            : null,
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
    'training_days' => 'Trainingstage',
    'total_xp' => 'Gesamt-XP',
    'exercise_volume' => 'Volumen',
    _ => type,
  };
}

class _ChallengeKpiOverview extends StatelessWidget {
  const _ChallengeKpiOverview({required this.kpis});

  final List<ChallengeKpi> kpis;

  @override
  Widget build(BuildContext context) {
    final eligible = kpis.fold<int>(0, (sum, k) => sum + k.eligibleMembers);
    final started = kpis.fold<int>(0, (sum, k) => sum + k.participantsStarted);
    final completed = kpis.fold<int>(
      0,
      (sum, k) => sum + k.participantsCompleted,
    );
    final participationAvg = kpis.isEmpty
        ? 0.0
        : kpis.map((k) => k.participationRatePct).reduce((a, b) => a + b) /
              kpis.length;
    final completionAvg = kpis.isEmpty
        ? 0.0
        : kpis.map((k) => k.completionRatePct).reduce((a, b) => a + b) /
              kpis.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Row(
        children: [
          Expanded(
            child: _KpiMetric(
              label: 'Eligible',
              value: '$eligible',
              color: AppColors.textPrimary,
              sublabel: '$started gestartet',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiMetric(
              label: 'Teilnahme Ø',
              value: '${participationAvg.toStringAsFixed(0)}%',
              color: AppColors.neonCyan,
              sublabel: '${kpis.length} Challenges',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiMetric(
              label: 'Completion Ø',
              value: '${completionAvg.toStringAsFixed(0)}%',
              color: completionAvg >= 60
                  ? AppColors.success
                  : completionAvg >= 30
                  ? AppColors.neonYellow
                  : AppColors.textSecondary,
              sublabel: '$completed completed',
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiMetric extends StatelessWidget {
  const _KpiMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.sublabel,
  });

  final String label;
  final String value;
  final Color color;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: AppTextStyles.labelSm),
        Text(
          sublabel,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _KpiPill extends StatelessWidget {
  const _KpiPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Challenge form sheet ─────────────────────────────────────────────────────

void _showChallengeForm(
  BuildContext context,
  WidgetRef ref,
  String gymId,
  AdminChallenge? existing, {
  _ChallengeTemplatePreset? preset,
}) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ChallengeFormSheet(gymId: gymId, existing: existing, preset: preset),
    ),
  );
}

class _ChallengeFormSheet extends HookConsumerWidget {
  const _ChallengeFormSheet({required this.gymId, this.existing, this.preset});

  final String gymId;
  final AdminChallenge? existing;
  final _ChallengeTemplatePreset? preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final normalizedStart = DateTime(now.year, now.month, now.day);
    final defaultEnd = normalizedStart.add(
      Duration(days: preset?.durationDays ?? 30),
    );

    final titleCtrl = useTextEditingController(
      text: existing?.title ?? preset?.title ?? '',
    );
    final descCtrl = useTextEditingController(
      text: existing?.description ?? preset?.description ?? '',
    );
    final targetCtrl = useTextEditingController(
      text: existing?.targetMetric != null
          ? existing!.targetMetric.toStringAsFixed(0)
          : preset != null
          ? preset!.targetMetric.toStringAsFixed(0)
          : '',
    );
    final challengeType = useState(
      existing?.challengeType ?? preset?.challengeType ?? 'training_days',
    );
    final visibility = useState(existing?.visibility ?? 'all_members');
    final startsAt = useState<DateTime?>(existing?.startsAt ?? normalizedStart);
    final endsAt = useState<DateTime?>(existing?.endsAt ?? defaultEnd);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final notifier = ref.watch(challengeManagementProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surface500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    existing == null
                        ? 'CHALLENGE ERSTELLEN'
                        : 'CHALLENGE BEARBEITEN',
                    style: AppTextStyles.h3,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TapemTextField(
                          label: 'TITEL',
                          controller: titleCtrl,
                          hintText: 'z.B. January Streak Challenge',
                          validator: (v) {
                            if ((v?.trim().length ?? 0) < 3) {
                              return 'Mindestens 3 Zeichen';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TapemTextField(
                          label: 'BESCHREIBUNG (optional)',
                          controller: descCtrl,
                          hintText: 'Kurze Beschreibung der Challenge',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),

                        // Challenge type
                        const Text('TYP', style: AppTextStyles.labelSm),
                        const SizedBox(height: 8),
                        _ChoiceGroup<String>(
                          options: const [
                            ('training_days', 'Trainingstage'),
                            ('total_xp', 'Gesamt-XP'),
                            ('exercise_volume', 'Volumen (kg)'),
                          ],
                          selected: challengeType.value,
                          onChanged: (v) => challengeType.value = v,
                        ),
                        const SizedBox(height: 20),

                        // Target metric
                        TapemTextField(
                          label: 'ZIELWERT',
                          controller: targetCtrl,
                          hintText: challengeType.value == 'training_days'
                              ? 'z.B. 20 (Trainingstage)'
                              : challengeType.value == 'total_xp'
                              ? 'z.B. 500 (XP)'
                              : 'z.B. 10000 (kg)',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = double.tryParse(v?.trim() ?? '');
                            if (n == null || n <= 0) {
                              return 'Gültige Zahl eingeben';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Visibility
                        const Text(
                          'SICHTBARKEIT',
                          style: AppTextStyles.labelSm,
                        ),
                        const SizedBox(height: 8),
                        _ChoiceGroup<String>(
                          options: const [
                            ('all_members', 'Alle Mitglieder'),
                            ('opt_in', 'Freiwillig (Opt-in)'),
                          ],
                          selected: visibility.value,
                          onChanged: (v) => visibility.value = v,
                        ),
                        const SizedBox(height: 20),

                        // Date range
                        Row(
                          children: [
                            Expanded(
                              child: _DatePickerField(
                                label: 'START',
                                value: startsAt.value,
                                onPicked: (d) => startsAt.value = d,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DatePickerField(
                                label: 'ENDE',
                                value: endsAt.value,
                                onPicked: (d) => endsAt.value = d,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        TapemButton(
                          label: existing == null ? 'ERSTELLEN' : 'SPEICHERN',
                          isLoading: notifier.isLoading,
                          onPressed: () async {
                            if (formKey.currentState?.validate() != true) {
                              return;
                            }
                            if (startsAt.value == null ||
                                endsAt.value == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Start- und Enddatum angeben.'),
                                ),
                              );
                              return;
                            }
                            if (!endsAt.value!.isAfter(startsAt.value!)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ende muss nach dem Start liegen.',
                                  ),
                                ),
                              );
                              return;
                            }

                            await ref
                                .read(challengeManagementProvider.notifier)
                                .createChallenge(
                                  gymId: gymId,
                                  title: titleCtrl.text.trim(),
                                  description: descCtrl.text.trim().isEmpty
                                      ? null
                                      : descCtrl.text.trim(),
                                  challengeType: challengeType.value,
                                  targetMetric: double.parse(
                                    targetCtrl.text.trim(),
                                  ),
                                  startsAt: startsAt.value!,
                                  endsAt: endsAt.value!,
                                  visibility: visibility.value,
                                );

                            if (!context.mounted) return;
                            final err = ref
                                .read(challengeManagementProvider)
                                .error;
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Fehler: $err'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            } else {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Challenge gespeichert.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable choice group ────────────────────────────────────────────────────

class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o.$1 == selected;
        return GestureDetector(
          onTap: () => onChanged(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.neonCyan.withAlpha(25)
                  : AppColors.surface700,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppColors.neonCyan : AppColors.surface500,
              ),
            ),
            child: Text(
              o.$2,
              style: AppTextStyles.bodySm.copyWith(
                color: isSelected
                    ? AppColors.neonCyan
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Date picker field ────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.neonCyan,
                onSurface: AppColors.textPrimary,
                surface: AppColors.surface700,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface600,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.neonCyan,
                ),
                const SizedBox(width: 6),
                Text(
                  value != null ? fmt.format(value!) : 'Datum wählen',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: value != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.labelMd.copyWith(color: color)),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap, required this.onTemplateTap});
  final VoidCallback onCreateTap;
  final VoidCallback onTemplateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 56,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Challenges',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Erstelle die erste Challenge für dein Gym.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TapemButton(label: 'CHALLENGE ERSTELLEN', onPressed: onCreateTap),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onTemplateTap,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('TEMPLATE WÄHLEN'),
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
    title: const Text('CHALLENGES'),
    backgroundColor: AppColors.surface900,
  ),
  body: Center(
    child: Text(
      message,
      style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
    ),
  ),
);
