import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/xp_rules.dart';
import '../../../../domain/entities/gym/muscle_group.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../router/route_names.dart';
import '../providers/xp_provider.dart';
import '../widgets/muscle_body_map_widget.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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

            // ── Nutrition tile ────────────────────────────────────────────
            _NutritionTile(),
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
    // userGymXpProvider has a Supabase fallback — works after reinstall.
    final gymXp = ref.watch(userGymXpProvider);
    final trainingDayXp = gymXp.valueOrNull?.totalXp ?? 0;
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
            isLoading: gymXp.isLoading,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Accent dot
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withAlpha(120), blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTextStyles.labelMd.copyWith(fontSize: 13))),
            if (!isEmpty && !isLoading) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withAlpha(80)),
                  boxShadow: [BoxShadow(color: color.withAlpha(18), blurRadius: 8)],
                ),
                child: Text(
                  'LVL $level',
                  style: AppTextStyles.monoSm.copyWith(color: color, fontSize: 11),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$totalXp XP',
                style: AppTextStyles.monoSm.copyWith(fontSize: 12, color: AppColors.textSecondary),
              ),
            ] else if (isEmpty && !isLoading) ...[
              Text('—', style: AppTextStyles.bodySm.copyWith(color: AppColors.textDisabled)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (isLoading)
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.surface600,
              borderRadius: BorderRadius.circular(3),
            ),
          )
        else
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => Stack(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.surface600,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: val,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withAlpha(160)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 8)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!isEmpty && !isLoading) ...[
          const SizedBox(height: 4),
          Text(
            'noch $xpToNext XP bis Lvl ${level + 1}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 10),
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
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: AppColors.surface800,
        child: InkWell(
          onTap: exerciseXp.valueOrNull?.isNotEmpty == true
              ? () => _openSheet(context, exerciseXp.requireValue)
              : null,
          splashColor: AppColors.neonMagenta.withAlpha(15),
          highlightColor: AppColors.neonMagenta.withAlpha(8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonMagenta.withAlpha(40)),
              boxShadow: [
                BoxShadow(color: AppColors.neonMagenta.withAlpha(12), blurRadius: 20),
                BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 12),
              ],
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

// ─── Muscle group card — body map + trained/neglected breakdown ───────────────

class _MuscleGroupCard extends StatefulWidget {
  const _MuscleGroupCard({required this.muscleXp});
  final AsyncValue<List<MuscleGroupXp>> muscleXp;

  @override
  State<_MuscleGroupCard> createState() => _MuscleGroupCardState();
}

class _MuscleGroupCardState extends State<_MuscleGroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tappable header ───────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(l10n.muscleGroups, style: AppTextStyles.labelMd),
                const Spacer(),
                if (!_expanded)
                  widget.muscleXp.maybeWhen(
                    data: (list) {
                      final trained =
                          list.where((m) => m.totalXp > 0).toList();
                      if (trained.isEmpty) return const SizedBox.shrink();
                      return Text(
                        _trainedPreview(trained),
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                const SizedBox(width: 6),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // ── Expanded detail ───────────────────────────────────────────────
          if (_expanded) ...[
            const SizedBox(height: 16),
            widget.muscleXp.when(
              data: (list) => _MuscleGroupContent(list: list, l10n: l10n),
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.neonYellow,
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (_, __) => Text(
                'Fehler beim Laden.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _trainedPreview(List<MuscleGroupXp> trained) {
    const maxVisible = 2;
    final names = trained
        .take(maxVisible)
        .map((m) => m.muscleGroupEnum?.displayNameDe ?? m.muscleGroup)
        .join(' · ');
    if (trained.length <= maxVisible) return names;
    return '$names · +${trained.length - maxVisible}';
  }
}

class _MuscleGroupContent extends StatelessWidget {
  const _MuscleGroupContent({required this.list, required this.l10n});
  final List<MuscleGroupXp> list;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final xpMap = <MuscleGroup, double>{};
    for (final entry in list) {
      final mg = entry.muscleGroupEnum;
      if (mg != null) xpMap[mg] = entry.totalXp;
    }

    final trained = list.where((m) => m.totalXp > 0).toList();
    final neglected = list.where((m) => m.totalXp == 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuscleBodyMapWidget(xpMap: xpMap),

        if (trained.isEmpty) ...[
          const SizedBox(height: 16),
          _MuscleGroupEmptyState(l10n: l10n),
        ] else ...[
          const SizedBox(height: 20),
          Text(
            l10n.muscleGroupTrained,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.neonYellow,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          ...trained.map((m) => _MuscleGroupBar(entry: m)),

          if (neglected.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.muscleGroupNeglected,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: neglected.map((m) {
                final name = m.muscleGroupEnum?.displayNameDe ?? m.muscleGroup;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface700,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.surface500),
                  ),
                  child: Text(
                    name,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ],
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
  const _MuscleGroupBar({required this.entry});
  final MuscleGroupXp entry;

  @override
  Widget build(BuildContext context) {
    final levelProgress = XpRules.levelProgressDouble(
      entry.totalXp,
      XpRules.muscleGroupXpPerLevel,
    );
    final xpToNext = XpRules.xpToNextLevelDouble(
      entry.totalXp,
      XpRules.muscleGroupXpPerLevel,
    );
    // Format XP: drop the decimal if it's a whole number (e.g. "10 XP" not "10.0 XP").
    final xpLabel = entry.totalXp == entry.totalXp.roundToDouble()
        ? '${entry.totalXp.round()} XP'
        : '${entry.totalXp.toStringAsFixed(1)} XP';
    final name = entry.muscleGroupEnum?.displayNameDe ?? entry.muscleGroup;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 12, color: AppColors.neonYellow),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: AppTextStyles.bodyMd)),
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
                xpLabel,
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
          const SizedBox(height: 2),
          Text(
            '${xpToNext.toStringAsFixed(xpToNext == xpToNext.roundToDouble() ? 0 : 1)} XP → LVL ${entry.currentLevel + 1}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textDisabled,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nutrition tile ───────────────────────────────────────────────────────────

class _NutritionTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _NavTile(
      color: AppColors.neonCyan,
      icon: Icons.restaurant_rounded,
      title: 'KALORIEN & ERNÄHRUNG',
      subtitle: 'Mahlzeiten loggen & Makros tracken',
      onTap: () => context.push(RouteNames.nutrition),
    );
  }
}

// ─── Training plans tile ──────────────────────────────────────────────────────

class _TrainingPlansTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _NavTile(
      color: AppColors.neonMagenta,
      icon: Icons.list_alt_rounded,
      title: l10n.trainingPlansTile,
      subtitle: l10n.createManagePlans,
      onTap: () => context.push(RouteNames.plans),
    );
  }
}

// ─── Shared premium nav tile ──────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: AppColors.surface800,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withAlpha(20),
          highlightColor: color.withAlpha(10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(50)),
              boxShadow: [
                BoxShadow(color: color.withAlpha(15), blurRadius: 20),
                BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withAlpha(35), color.withAlpha(12)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withAlpha(80)),
                    boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 10)],
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.labelLg.copyWith(fontSize: 13)),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color.withAlpha(180), size: 22),
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
              onTap: () => _showAllSessionsSheet(context),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface500.withAlpha(150)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 12),
        ],
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

  static void _showAllSessionsSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const _AllSessionsSheet(),
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

class _AllSessionsSheet extends ConsumerWidget {
  const _AllSessionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sessionsAsync = ref.watch(allSessionsProvider);

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
                  if (sessionsAsync.hasValue)
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
                        '${sessionsAsync.value!.length}',
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
              child: sessionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.neonCyan),
                ),
                error: (_, __) => Center(
                  child: Text(
                    l10n.couldNotLoadSessions,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                data: (sessions) => ListView.builder(
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface500.withAlpha(150)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}
