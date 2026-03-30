import 'dart:async';
import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../../domain/entities/gym/muscle_group.dart';
import '../../../../core/utils/xp_rules.dart';
import '../../auth/providers/auth_provider.dart';
import '../../progress/providers/xp_provider.dart';
import '../providers/equipment_detail_provider.dart';

const _uuid = Uuid();

// ─── Public entry point ───────────────────────────────────────────────────────

Future<void> showEquipmentDetailSheet(
  BuildContext context,
  GymEquipment equipment,
  String gymId,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => EquipmentDetailSheet(equipment: equipment, gymId: gymId),
);

// ─── Main sheet ───────────────────────────────────────────────────────────────

class EquipmentDetailSheet extends HookConsumerWidget {
  const EquipmentDetailSheet({
    super.key,
    required this.equipment,
    required this.gymId,
  });

  final GymEquipment equipment;
  final String gymId;

  String get _exerciseKey => switch (equipment.equipmentType) {
    EquipmentType.fixedMachine => equipment.canonicalExerciseKey ?? '',
    EquipmentType.openStation => '',
    EquipmentType.cardio => 'cardio:${equipment.id}',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id ?? '';
    final isOpenStation = equipment.equipmentType == EquipmentType.openStation;
    final l10n = context.l10n;

    final selectedExerciseKey = useState<String?>(null);

    final isFav = ref.watch(
      favouritesProvider.select((s) => s.contains('$gymId:${equipment.id}')),
    );

    final equipmentHistoryAsync = ref.watch(
      equipmentHistoryProvider((
        gymId: gymId,
        userId: userId,
        equipmentId: equipment.id,
      )),
    );

    final customExercisesAsync = ref.watch(
      customExercisesForEquipmentProvider((
        gymId: gymId,
        userId: userId,
        equipmentId: equipment.id,
      )),
    );

    final exerciseHistoryAsync = ref.watch(
      exerciseKeyHistoryProvider((
        gymId: gymId,
        userId: userId,
        exerciseKey: selectedExerciseKey.value ?? '',
      )),
    );

    final historyAsync = (isOpenStation && selectedExerciseKey.value != null)
        ? exerciseHistoryAsync
        : equipmentHistoryAsync;

    final activeExerciseKey = isOpenStation
        ? (selectedExerciseKey.value ?? '')
        : _exerciseKey;

    final showRanking =
        activeExerciseKey.isNotEmpty &&
        equipment.equipmentType == EquipmentType.fixedMachine;

    final allExerciseXp = ref.watch(userExerciseXpProvider);
    final allXpList = allExerciseXp.valueOrNull ?? [];

    final relevantKeys = <String>{equipment.id};
    switch (equipment.equipmentType) {
      case EquipmentType.fixedMachine:
        if (equipment.canonicalExerciseKey != null) {
          relevantKeys.add(equipment.canonicalExerciseKey!);
        }
      case EquipmentType.cardio:
        relevantKeys.add('cardio:${equipment.id}');
      case EquipmentType.openStation:
        for (final e
            in customExercisesAsync.valueOrNull ??
                const <CustomExerciseSummary>[]) {
          relevantKeys.add(e.exerciseKey);
        }
    }

    final matchingXp = allXpList.where(
      (e) => relevantKeys.contains(e.equipmentKey),
    );
    final equipmentXpTotal = matchingXp.fold(0, (sum, e) => sum + e.totalXp);
    final equipmentLevel = XpRules.levelFromXp(
      equipmentXpTotal,
      XpRules.exerciseXpPerLevel,
    );

    final rankingAsync = showRanking
        ? ref.watch(
            equipmentRankingProvider((
              gymId: gymId,
              userId: userId,
              exerciseKey: activeExerciseKey,
            )),
          )
        : null;

    final savedNote = ref.watch(
      equipmentNoteNotifierProvider((
        gymId: gymId,
        userId: userId,
        equipmentId: equipment.id,
      )),
    );

    final noteCtrl = useTextEditingController(text: savedNote);

    useEffect(() {
      if (noteCtrl.text.isEmpty && savedNote.isNotEmpty) {
        noteCtrl.text = savedNote;
        noteCtrl.selection = TextSelection.collapsed(
          offset: noteCtrl.text.length,
        );
      }
      return null;
    }, const []);

    final feedbackCtrl = useTextEditingController();
    final isSubmittingFeedback = useState(false);
    final feedbackSubmitted = useState(false);

    final selectedExerciseName =
        isOpenStation && selectedExerciseKey.value != null
        ? customExercisesAsync.valueOrNull
              ?.where((e) => e.exerciseKey == selectedExerciseKey.value)
              .map((e) => e.name)
              .firstOrNull
        : null;

    final (badgeLabel, badgeColor) = switch (equipment.equipmentType) {
      EquipmentType.fixedMachine => (l10n.fixedBadge, AppColors.neonCyan),
      EquipmentType.openStation => (l10n.openBadge, AppColors.neonMagenta),
      EquipmentType.cardio => (l10n.cardioBadge, AppColors.neonYellow),
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.neonCyan.withAlpha(40)),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withAlpha(15),
                blurRadius: 30,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _TypeBadge(label: badgeLabel, color: badgeColor),
                              if (equipment.supportsNfc) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.nfc,
                                  size: 14,
                                  color: AppColors.neonCyan.withAlpha(180),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'NFC',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.neonCyan,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(equipment.name, style: AppTextStyles.h2),
                          if (equipment.manufacturer != null)
                            Text(
                              equipment.manufacturer!,
                              style: AppTextStyles.bodySm,
                            ),
                        ],
                      ),
                    ),

                    _FavouriteButton(
                      isFavourite: isFav,
                      onTap: () => ref
                          .read(favouritesProvider.notifier)
                          .toggle(gymId, equipment.id),
                    ),
                    const SizedBox(width: 4),

                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.neonCyan.withAlpha(40),
                      AppColors.surface500.withAlpha(180),
                      AppColors.neonCyan.withAlpha(40),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: [
                    // ── EXERCISE SELECTOR (open station only) ───────────────
                    if (isOpenStation) ...[
                      _SectionHeader(label: l10n.myExercises),
                      const SizedBox(height: 10),
                      customExercisesAsync.when(
                        data: (exercises) => exercises.isEmpty
                            ? _EmptySection(message: l10n.noExercisesAtStation)
                            : _ExerciseChipRow(
                                exercises: exercises,
                                selectedKey: selectedExerciseKey.value,
                                onSelected: (key) =>
                                    selectedExerciseKey.value = key,
                              ),
                        loading: () => const _SectionSkeleton(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── E1RM PROGRESS CHART ─────────────────────────────────
                    if (activeExerciseKey.isNotEmpty &&
                        !activeExerciseKey.startsWith('cardio:')) ...[
                      _SectionHeader(label: l10n.strengthProgressTitle),
                      const SizedBox(height: 12),
                      ref
                          .watch(
                            e1rmChartProvider((
                              gymId: gymId,
                              userId: userId,
                              exerciseKey: activeExerciseKey,
                            )),
                          )
                          .when(
                            data: (points) => _E1rmChart(points: points),
                            loading: () => const _SectionSkeleton(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                      const SizedBox(height: 24),
                    ],

                    // ── MUSCLE GROUPS (fixed machines only) ─────────────────
                    if (equipment.equipmentType == EquipmentType.fixedMachine &&
                        activeExerciseKey.isNotEmpty) ...[
                      _SectionHeader(label: l10n.muscleGroups),
                      const SizedBox(height: 12),
                      ref
                          .watch(
                            exerciseMuscleGroupsProvider((
                              gymId: gymId,
                              exerciseKey: activeExerciseKey,
                            )),
                          )
                          .when(
                            data: (entries) => entries.isEmpty
                                ? const SizedBox.shrink()
                                : _MuscleGroupChips(entries: entries),
                            loading: () => const _SectionSkeleton(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                      const SizedBox(height: 24),
                    ],

                    // ── MY HISTORY ──────────────────────────────────────────
                    _SectionHeader(
                      label: selectedExerciseName != null
                          ? l10n.historyFor(selectedExerciseName)
                          : l10n.myHistory,
                    ),
                    const SizedBox(height: 12),
                    historyAsync.when(
                      data: (history) => history.isEmpty
                          ? _EmptySection(
                              message: selectedExerciseName != null
                                  ? l10n.noSessionsWithExercise(
                                      selectedExerciseName,
                                    )
                                  : l10n.noSessionsOnEquipment,
                            )
                          : Column(
                              children: history
                                  .take(10)
                                  .map((h) => _HistoryRow(entry: h))
                                  .toList(),
                            ),
                      loading: () => const _SectionSkeleton(),
                      error: (_, __) =>
                          _EmptySection(message: l10n.historyCouldNotLoad),
                    ),
                    const SizedBox(height: 24),

                    // ── MY XP ──────────────────────────────────────────────
                    _SectionHeader(label: l10n.myXpOnEquipment),
                    const SizedBox(height: 12),
                    allExerciseXp.when(
                      data: (_) => _XpCard(
                        totalXp: equipmentXpTotal,
                        level: equipmentLevel,
                      ),
                      loading: () => const _SectionSkeleton(),
                      error: (_, __) =>
                          _EmptySection(message: l10n.xpDataUnavailable),
                    ),
                    const SizedBox(height: 24),

                    // ── GYM RANKING ─────────────────────────────────────────
                    if (rankingAsync != null) ...[
                      _SectionHeader(label: l10n.gymRanking),
                      const SizedBox(height: 12),
                      rankingAsync.when(
                        data: (entries) => entries.isEmpty
                            ? _EmptySection(message: l10n.noRankingYet)
                            : Column(
                                children: entries
                                    .map((e) => _RankingRow(entry: e))
                                    .toList(),
                              ),
                        loading: () => const _SectionSkeleton(),
                        error: (_, __) =>
                            _EmptySection(message: l10n.rankingUnavailable),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── MY NOTE ─────────────────────────────────────────────
                    _SectionHeader(label: l10n.myNote),
                    const SizedBox(height: 12),
                    _NoteField(
                      controller: noteCtrl,
                      onSave: () {
                        unawaited(
                          ref
                              .read(
                                equipmentNoteNotifierProvider((
                                  gymId: gymId,
                                  userId: userId,
                                  equipmentId: equipment.id,
                                )).notifier,
                              )
                              .save(noteCtrl.text.trim()),
                        );
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.noteSaved),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── FEEDBACK ─────────────────────────────────────────────
                    _SectionHeader(label: l10n.feedbackToGym),
                    const SizedBox(height: 12),
                    feedbackSubmitted.value
                        ? const _FeedbackConfirmation()
                        : _FeedbackField(
                            controller: feedbackCtrl,
                            isSubmitting: isSubmittingFeedback.value,
                            onSubmit: () => _submitFeedback(
                              context,
                              ref,
                              userId,
                              feedbackCtrl,
                              isSubmittingFeedback,
                              feedbackSubmitted,
                            ),
                          ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitFeedback(
    BuildContext context,
    WidgetRef ref,
    String userId,
    TextEditingController ctrl,
    ValueNotifier<bool> isLoading,
    ValueNotifier<bool> submitted,
  ) async {
    final message = ctrl.text.trim();
    if (message.isEmpty) return;

    isLoading.value = true;
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('equipment_feedback').insert({
        'id': _uuid.v4(),
        'gym_id': gymId,
        'equipment_id': equipment.id,
        'equipment_name': equipment.name,
        'user_id': userId,
        'message': message,
      });
      submitted.value = true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.failedToSendFeedback)),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(28), color.withAlpha(10)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100)),
        boxShadow: [
          BoxShadow(color: color.withAlpha(30), blurRadius: 8),
        ],
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.isFavourite, required this.onTap});

  final bool isFavourite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isFavourite
              ? AppColors.neonYellow.withAlpha(20)
              : AppColors.surface700,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFavourite
                ? AppColors.neonYellow.withAlpha(120)
                : AppColors.surface500,
          ),
        ),
        child: Icon(
          isFavourite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFavourite ? AppColors.neonYellow : AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.labelMd),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final EquipmentHistorySummary entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = DateFormat(
      'dd MMM yyyy',
    ).format(DateTime.parse(entry.sessionDayAnchor));

    final dur = entry.duration;
    final durLabel = dur != null
        ? dur.inHours > 0
              ? '${dur.inHours}h ${dur.inMinutes.remainder(60)}min'
              : '${dur.inMinutes}min'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface500.withAlpha(160)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: AppTextStyles.labelLg),
                const SizedBox(height: 2),
                Text(
                  l10n.setsRepsLabel(entry.setCount, entry.totalReps, durLabel),
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${entry.totalXp} XP',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.neonMagenta,
                ),
              ),
              if (entry.totalVolumeKg > 0)
                Text(
                  '${entry.totalVolumeKg.toStringAsFixed(0)} kg vol',
                  style: AppTextStyles.bodySm,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _XpCard extends StatelessWidget {
  const _XpCard({required this.totalXp, required this.level});

  final int totalXp;
  final int level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonMagenta.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.neonMagenta, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalXp XP',
                  style: AppTextStyles.monoMd.copyWith(
                    color: AppColors.neonMagenta,
                  ),
                ),
                Text(
                  l10n.xpEarnedOnEquipment(level),
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});

  final EquipmentRankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final Color rankColor;
    if (entry.rank == 1) {
      rankColor = AppColors.neonYellow;
    } else if (entry.rank == 2) {
      rankColor = AppColors.textSecondary;
    } else if (entry.rank == 3) {
      rankColor = AppColors.neonYellowDim;
    } else {
      rankColor = AppColors.textDisabled;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.neonCyan.withAlpha(12)
            : AppColors.surface700,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: entry.isCurrentUser
              ? AppColors.neonCyan.withAlpha(80)
              : AppColors.surface500,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: AppTextStyles.monoSm.copyWith(color: rankColor),
            ),
          ),
          Expanded(
            child: Text(
              entry.username,
              style: AppTextStyles.bodyMd.copyWith(
                color: entry.isCurrentUser
                    ? AppColors.neonCyan
                    : AppColors.textPrimary,
                fontWeight: entry.isCurrentUser
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(entry.score.toStringAsFixed(1), style: AppTextStyles.monoSm),
        ],
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller, required this.onSave});

  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 2,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: l10n.noteHint,
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textDisabled,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onSave,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.save,
                style: AppTextStyles.labelMd.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackField extends StatelessWidget {
  const _FeedbackField({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 2,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: l10n.feedbackHint,
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textDisabled,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: isSubmitting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: onSubmit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.send,
                      style: AppTextStyles.labelMd.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Exercise chip row (open station) ─────────────────────────────────────────

class _ExerciseChipRow extends StatelessWidget {
  const _ExerciseChipRow({
    required this.exercises,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<CustomExerciseSummary> exercises;
  final String? selectedKey;
  final void Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ExerciseChip(
            label: l10n.allExercisesChip,
            isSelected: selectedKey == null,
            onTap: () => onSelected(null),
          ),
          ...exercises.map(
            (e) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _ExerciseChip(
                label: e.name,
                isSelected: selectedKey == e.exerciseKey,
                onTap: () => onSelected(
                  selectedKey == e.exerciseKey ? null : e.exerciseKey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  const _ExerciseChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonMagenta.withAlpha(20)
              : AppColors.surface700,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.neonMagenta.withAlpha(140)
                : AppColors.surface500,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: isSelected ? AppColors.neonMagenta : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── E1RM progress chart ──────────────────────────────────────────────────────

class _E1rmChart extends StatelessWidget {
  const _E1rmChart({required this.points});

  final List<E1rmDataPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return _EmptySection(message: context.l10n.e1rmChartEmptyState);
    }

    final minY = points.fold(
      double.infinity,
      (m, p) => p.e1rm < m ? p.e1rm : m,
    );
    final maxY = points.fold(0.0, (m, p) => p.e1rm > m ? p.e1rm : m);
    final yPad = max((maxY - minY) * 0.15, 5.0);
    final yMin = (minY - yPad).clamp(0.0, double.infinity);
    final yMax = maxY + yPad;

    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.e1rm))
        .toList();

    final labelInterval = max(1.0, (spots.length / 4).floorToDouble());

    return Container(
      height: 190,
      padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: LineChart(
        LineChartData(
          minY: yMin,
          maxY: yMax,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.surface500, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${v.toInt()}',
                    style: AppTextStyles.monoSm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: labelInterval,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final parts = points[idx].sessionDayAnchor.split('-');
                  return Text(
                    '${parts[2]}.${parts[1]}',
                    style: AppTextStyles.monoSm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface800,
              tooltipBorder: const BorderSide(
                color: AppColors.neonCyan,
                width: 0.5,
              ),
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                final p = points[s.spotIndex];
                final wStr = p.weightKg == p.weightKg.truncateToDouble()
                    ? p.weightKg.toInt().toString()
                    : p.weightKg.toStringAsFixed(1);
                return LineTooltipItem(
                  '${p.e1rm.toStringAsFixed(1)} kg\n${p.reps} × ${wStr}kg',
                  AppTextStyles.monoSm.copyWith(
                    color: AppColors.neonCyan,
                    fontSize: 11,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.neonCyan,
              barWidth: 2,
              dotData: FlDotData(
                show: spots.length <= 30,
                getDotPainter: (spot, pct, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.neonCyan,
                  strokeWidth: 1.5,
                  strokeColor: AppColors.surface800,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.neonCyan.withAlpha(50),
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

// ─── Muscle group chips ───────────────────────────────────────────────────────

class _MuscleGroupChips extends StatelessWidget {
  const _MuscleGroupChips({required this.entries});
  final List<ExerciseMuscleGroupEntry> entries;

  @override
  Widget build(BuildContext context) {
    final primary = entries.where((e) => e.role == 'primary').toList();
    final secondary = entries.where((e) => e.role == 'secondary').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (primary.isNotEmpty) ...[
          Text(
            'PRIMÄR',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.neonCyan,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: primary.map((e) => _MgChip(entry: e, isPrimary: true)).toList(),
          ),
        ],
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'SEKUNDÄR',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: secondary.map((e) => _MgChip(entry: e, isPrimary: false)).toList(),
          ),
        ],
      ],
    );
  }
}

class _MgChip extends StatelessWidget {
  const _MgChip({required this.entry, required this.isPrimary});
  final ExerciseMuscleGroupEntry entry;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final mg = MuscleGroup.tryFromValue(entry.muscleGroup);
    final label = mg?.displayNameDe ?? entry.muscleGroup;
    final color = isPrimary ? AppColors.neonCyan : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(isPrimary ? 20 : 12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(isPrimary ? 80 : 40)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _FeedbackConfirmation extends StatelessWidget {
  const _FeedbackConfirmation();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.feedbackSent,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
