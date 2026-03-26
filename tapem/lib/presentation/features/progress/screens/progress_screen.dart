import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/xp_rules.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../router/route_names.dart';
import '../providers/xp_provider.dart';
import '../widgets/session_detail_sheet.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseXp = ref.watch(userExerciseXpProvider);
    final muscleXp = ref.watch(userMuscleGroupXpProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(localXpBaseProvider);
          ref.invalidate(userGymXpProvider);
          ref.invalidate(userExerciseXpProvider);
          ref.invalidate(userMuscleGroupXpProvider);
          ref.invalidate(recentSessionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── XP Overview (Konsistenz axis) ─────────────────────────────
            const _XpOverviewCard(),
            const SizedBox(height: 16),

            // ── Equipment XP breakdown ────────────────────────────────────
            _EquipmentXpCard(exerciseXp: exerciseXp),
            const SizedBox(height: 16),

            // ── Muscle group bar chart ────────────────────────────────────
            _MuscleGroupCard(muscleXp: muscleXp),
            const SizedBox(height: 16),

            // ── Training plans tile ───────────────────────────────────────
            _TrainingPlansTile(),
            const SizedBox(height: 16),

            // ── Recent sessions ───────────────────────────────────────────
            _RecentSessionsCard(),
          ],
        ),
      ),
    );
  }
}

// ─── XP Overview — Konsistenz axis only ──────────────────────────────────────
//
// Reads from localXpBaseProvider (local SQLite) — NOT from trainingDaysProvider.
//
// This is the correct separation of concerns:
//   • Calendar heatmap  → Supabase workout_sessions  (full history, cross-device)
//   • XP display        → local SQLite               (only sessions on this device)
//   • Server XP / rank  → xp_events + user_gym_xp    (written by edge functions on sync)
//
// Seeded demo sessions in Supabase therefore do NOT inflate the XP display —
// only real workouts completed and synced on this device count.

class _XpOverviewCard extends ConsumerWidget {
  const _XpOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final localBase = ref.watch(localXpBaseProvider);

    final trainingDayXp = localBase.valueOrNull?.trainingDayXp ?? 0;
    final trainingDayLevel = XpRules.levelFromXp(
      trainingDayXp,
      XpRules.trainingDayXpPerLevel,
    );
    final trainingDayToNext = XpRules.xpToNextLevel(
      trainingDayXp,
      XpRules.trainingDayXpPerLevel,
    );

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.xpOverviewTitle, style: AppTextStyles.labelMd),
          const SizedBox(height: 14),
          _XpAxisRow(
            label: l10n.consistencyAxisLabel,
            totalXp: trainingDayXp,
            level: trainingDayLevel,
            xpToNext: trainingDayToNext,
            xpPerLevel: XpRules.trainingDayXpPerLevel,
            color: AppColors.neonCyan,
            isLoading: localBase.isLoading,
          ),
        ],
      ),
    );
  }
}

class _XpAxisRow extends StatelessWidget {
  const _XpAxisRow({
    required this.label,
    required this.totalXp,
    required this.level,
    required this.xpToNext,
    required this.xpPerLevel,
    required this.color,
    required this.isLoading,
  });

  final String label;
  final int totalXp;
  final int level;
  final int xpToNext;
  final int xpPerLevel;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEmpty = totalXp <= 0;
    final progress = isEmpty || isLoading
        ? 0.0
        : (1.0 - xpToNext / xpPerLevel).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: AppTextStyles.labelSm)),
            if (!isEmpty && !isLoading) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color.withAlpha(70)),
                ),
                child: Text(
                  'LVL $level',
                  style: AppTextStyles.monoSm.copyWith(
                    color: color,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$totalXp XP',
                style: AppTextStyles.monoSm.copyWith(fontSize: 11),
              ),
            ] else if (isEmpty) ...[
              Text(
                '—',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        if (isLoading)
          const LinearProgressIndicator(minHeight: 4)
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surface600,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        if (!isEmpty && !isLoading) ...[
          const SizedBox(height: 3),
          Text(
            '$xpToNext XP → LVL ${level + 1}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textDisabled,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Equipment XP card — shows top 3, tap opens full search sheet ─────────────

class _EquipmentXpCard extends StatelessWidget {
  const _EquipmentXpCard({required this.exerciseXp});
  final AsyncValue<List<ExerciseXp>> exerciseXp;

  static const int _previewCount = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: AppColors.surface800,
        child: InkWell(
          onTap: exerciseXp.valueOrNull?.isNotEmpty == true
              ? () => _openSheet(context, exerciseXp.requireValue)
              : null,
          splashColor: AppColors.neonMagenta.withAlpha(15),
          highlightColor: AppColors.neonMagenta.withAlpha(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surface500),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(l10n.equipmentXpTitle, style: AppTextStyles.labelMd),
                    const Spacer(),
                    if (exerciseXp.valueOrNull?.isNotEmpty == true)
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                exerciseXp.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Text(
                        l10n.noExerciseData,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    final preview = list.take(_previewCount).toList();
                    final maxXp = list.first.totalXp;
                    final remaining = list.length - _previewCount;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...preview.map(
                          (e) => _EquipmentXpRow(entry: e, maxXp: maxXp),
                        ),
                        if (remaining > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '+ $remaining weitere',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.neonMagenta,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(
                    color: AppColors.neonMagenta,
                    backgroundColor: AppColors.surface600,
                  ),
                  error: (_, __) => const Text('Error'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, List<ExerciseXp> exercises) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ExerciseSearchSheet(exercises: exercises),
      ),
    );
  }
}

// ─── Exercise search bottom sheet ─────────────────────────────────────────────

class _ExerciseSearchSheet extends StatefulWidget {
  const _ExerciseSearchSheet({required this.exercises});
  final List<ExerciseXp> exercises;

  @override
  State<_ExerciseSearchSheet> createState() => _ExerciseSearchSheetState();
}

class _ExerciseSearchSheetState extends State<_ExerciseSearchSheet> {
  late final TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ExerciseXp> get _filtered {
    if (_query.isEmpty) return widget.exercises;
    return widget.exercises
        .where((e) => e.label.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxXp =
        widget.exercises.isNotEmpty ? widget.exercises.first.totalXp : 1;
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surface500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    context.l10n.equipmentXpTitle,
                    style: AppTextStyles.labelLg,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonMagenta.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.neonMagenta.withAlpha(60),
                      ),
                    ),
                    child: Text(
                      '${widget.exercises.length}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.neonMagenta,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Search bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  hintText: 'Übung suchen…',
                  hintStyle: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface700,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.surface500),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.surface500),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.neonMagenta,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const Divider(color: AppColors.surface500, height: 20),

            // ── Exercise list ────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Keine Übungen gefunden.',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: filtered.length,
                      itemBuilder: (_, index) => _EquipmentXpRow(
                        entry: filtered[index],
                        maxXp: maxXp,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentXpRow extends StatelessWidget {
  const _EquipmentXpRow({required this.entry, required this.maxXp});
  final ExerciseXp entry;
  final int maxXp;

  @override
  Widget build(BuildContext context) {
    final levelProgress =
        (1.0 -
                XpRules.xpToNextLevel(
                      entry.totalXp,
                      XpRules.exerciseXpPerLevel,
                    ) /
                    XpRules.exerciseXpPerLevel)
            .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 12, color: AppColors.neonMagenta),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.label,
                  style: AppTextStyles.bodyMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LVL ${entry.currentLevel}',
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.neonMagenta,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry.totalXp} XP',
                style: AppTextStyles.monoSm.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress bar: shows how far in current level.
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 3,
              backgroundColor: AppColors.surface600,
              valueColor: const AlwaysStoppedAnimation(AppColors.neonMagenta),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Muscle group bar chart ───────────────────────────────────────────────────

class _MuscleGroupCard extends StatelessWidget {
  const _MuscleGroupCard({required this.muscleXp});
  final AsyncValue<List<MuscleGroupXp>> muscleXp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.muscleGroups, style: AppTextStyles.labelMd),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.neonYellow.withAlpha(12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.neonYellow.withAlpha(70)),
                ),
                child: Text(
                  'Coming Soon!',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.neonYellow,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          muscleXp.when(
            data: (list) {
              if (list.isEmpty) {
                return _MuscleGroupEmptyState(l10n: l10n);
              }
              final maxXp = list.first.totalXp;
              return Column(
                children: list
                    .map((m) => _MuscleGroupBar(entry: m, maxXp: maxXp))
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error'),
          ),
        ],
      ),
    );
  }
}

class _MuscleGroupEmptyState extends StatelessWidget {
  const _MuscleGroupEmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.noMuscleGroupData,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.neonYellow.withAlpha(10),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.neonYellow.withAlpha(40)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.neonYellow,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.muscleGroupEmptyState,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MuscleGroupBar extends StatelessWidget {
  const _MuscleGroupBar({required this.entry, required this.maxXp});
  final MuscleGroupXp entry;
  final int maxXp;

  @override
  Widget build(BuildContext context) {
    final levelProgress =
        (1.0 -
                XpRules.xpToNextLevel(
                      entry.totalXp,
                      XpRules.exerciseXpPerLevel,
                    ) /
                    XpRules.exerciseXpPerLevel)
            .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 12, color: AppColors.neonYellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatMuscleGroup(entry.muscleGroup),
                  style: AppTextStyles.bodyMd,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LVL ${entry.currentLevel}',
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.neonYellow,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry.totalXp} XP',
                style: AppTextStyles.monoSm.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 4,
              backgroundColor: AppColors.surface600,
              valueColor: AlwaysStoppedAnimation(
                AppColors.neonYellow.withAlpha(200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMuscleGroup(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty
              ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}

// ─── Training plans tile ──────────────────────────────────────────────────────

class _TrainingPlansTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: AppColors.surface800,
        child: InkWell(
          onTap: () => context.push(RouteNames.plans),
          splashColor: AppColors.neonMagenta.withAlpha(15),
          highlightColor: AppColors.neonMagenta.withAlpha(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surface500),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.neonMagenta.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.neonMagenta.withAlpha(60),
                    ),
                  ),
                  child: const Icon(
                    Icons.list_alt_outlined,
                    color: AppColors.neonMagenta,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.trainingPlansTile,
                        style: AppTextStyles.labelMd,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.createManagePlans,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Recent sessions card — shows latest 1, tap opens full sheet ──────────────

class _RecentSessionsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(recentSessionsProvider);
    final l10n = context.l10n;

    return sessions.when(
      loading: () => _shell(
        title: l10n.recentSessions,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(
            color: AppColors.neonCyan,
            backgroundColor: AppColors.surface600,
          ),
        ),
      ),
      error: (_, __) => _shell(
        title: l10n.recentSessions,
        child: Text(
          l10n.couldNotLoadSessions,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _shell(
            title: l10n.recentSessions,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fitness_center_outlined,
                      color: AppColors.textDisabled,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noSessionsYetShort,
                      style: AppTextStyles.bodySm,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final latest = list.first;

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: AppColors.surface800,
            child: InkWell(
              onTap: () => _showAllSessionsSheet(context, list),
              splashColor: AppColors.neonCyan.withAlpha(15),
              highlightColor: AppColors.neonCyan.withAlpha(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surface500),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(l10n.recentSessions, style: AppTextStyles.labelMd),
                        const Spacer(),
                        Text(
                          l10n.seeAll,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.neonCyan,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.neonCyan,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SessionRowContent(session: latest),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _shell({required String title, required Widget child}) {
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
          Text(title, style: AppTextStyles.labelMd),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  static void _showAllSessionsSheet(
    BuildContext context,
    List<SessionSummary> sessions,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _AllSessionsSheet(sessions: sessions),
      ),
    );
  }
}

// ─── Session row (cyan left accent, duration badge) ───────────────────────────

class _SessionRowContent extends StatelessWidget {
  const _SessionRowContent({required this.session});
  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final duration = session.duration;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface900,
          border: Border.all(color: AppColors.surface500),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: AppColors.neonCyan.withAlpha(140)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.sessionDayAnchor,
                              style: AppTextStyles.bodyMd,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${l10n.exerciseCount(session.exerciseCount)}  ·  ${l10n.setCount(session.totalSets)}',
                              style: AppTextStyles.bodySm,
                            ),
                          ],
                        ),
                      ),
                      if (duration != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatDuration(duration),
                            style: AppTextStyles.monoSm.copyWith(fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textDisabled,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }
}

// ─── All-sessions bottom sheet ────────────────────────────────────────────────

class _AllSessionsSheet extends StatelessWidget {
  const _AllSessionsSheet({required this.sessions});
  final List<SessionSummary> sessions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surface500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(l10n.allSessions, style: AppTextStyles.labelLg),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.neonCyan.withAlpha(60),
                      ),
                    ),
                    child: Text(
                      '${sessions.length}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.neonCyan,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.surface500, height: 24),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            showSessionDetailSheet(context, session);
                          },
                          splashColor: AppColors.neonCyan.withAlpha(15),
                          highlightColor: AppColors.neonCyan.withAlpha(8),
                          child: _SessionRowContent(session: session),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section card shell ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: child,
    );
  }
}
