import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../../domain/entities/gym/muscle_group.dart';
import '../../../../core/utils/xp_rules.dart';
import '../../../widgets/charts/e1rm_progress_chart.dart';
import '../../auth/providers/auth_provider.dart';
import '../../progress/providers/xp_provider.dart';
import '../providers/equipment_detail_provider.dart';
import '../providers/equipment_provider.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id ?? '';
    final liveEquipment =
        ref
            .watch(
              equipmentByIdProvider((gymId: gymId, equipmentId: equipment.id)),
            )
            .valueOrNull ??
        equipment;
    final isOpenStation =
        liveEquipment.equipmentType == EquipmentType.openStation;
    final l10n = context.l10n;

    final selectedExerciseKey = useState<String?>(null);

    final isFav = ref.watch(
      favouritesProvider.select((s) => s.contains('$gymId:${equipment.id}')),
    );

    final customExercisesAsync = ref.watch(
      customExercisesForEquipmentProvider((
        gymId: gymId,
        userId: userId,
        equipmentId: liveEquipment.id,
      )),
    );

    final activeExerciseKey = isOpenStation
        ? (selectedExerciseKey.value ?? '')
        : switch (liveEquipment.equipmentType) {
            EquipmentType.fixedMachine =>
              liveEquipment.canonicalExerciseKey ?? '',
            EquipmentType.openStation => '',
            EquipmentType.cardio => 'cardio:${liveEquipment.id}',
          };

    final historyByExerciseAsync = ref.watch(
      exerciseKeyHistoryProvider((
        gymId: gymId,
        userId: userId,
        exerciseKey: activeExerciseKey,
        equipmentId: liveEquipment.id,
      )),
    );

    final isOpenWithoutSelection =
        isOpenStation && selectedExerciseKey.value == null;
    final historyAsync = (isOpenWithoutSelection || activeExerciseKey.isEmpty)
        ? const AsyncValue<List<EquipmentHistorySummary>>.data(
            <EquipmentHistorySummary>[],
          )
        : historyByExerciseAsync;

    final showRanking =
        activeExerciseKey.isNotEmpty &&
        liveEquipment.equipmentType == EquipmentType.fixedMachine;

    final allExerciseXp = ref.watch(userExerciseXpProvider);
    final allXpList = allExerciseXp.valueOrNull ?? [];

    final relevantKeys = <String>{liveEquipment.id};
    switch (liveEquipment.equipmentType) {
      case EquipmentType.fixedMachine:
        if (liveEquipment.canonicalExerciseKey != null) {
          relevantKeys.add(liveEquipment.canonicalExerciseKey!);
        }
      case EquipmentType.cardio:
        relevantKeys.add('cardio:${liveEquipment.id}');
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
        equipmentId: liveEquipment.id,
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

    final (badgeLabel, badgeColor) = switch (liveEquipment.equipmentType) {
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
                              if (liveEquipment.supportsNfc) ...[
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
                          Text(
                            liveEquipment.displayName,
                            style: AppTextStyles.h2,
                          ),
                          if (liveEquipment.hasPersonalNameOverride)
                            Text(
                              'Personal name',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.neonMagenta,
                              ),
                            ),
                          if (liveEquipment.manufacturer != null)
                            Text(
                              liveEquipment.manufacturer!,
                              style: AppTextStyles.bodySm,
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _InlineActionButton(
                                label: 'Rename for me',
                                icon: Icons.edit_outlined,
                                onTap: userId.isEmpty
                                    ? null
                                    : () => _renameForMe(
                                        context: context,
                                        ref: ref,
                                        gymId: gymId,
                                        equipment: liveEquipment,
                                      ),
                              ),
                              if (liveEquipment.hasPersonalNameOverride)
                                _InlineActionButton(
                                  label: 'Reset to gym name',
                                  icon: Icons.undo,
                                  onTap: userId.isEmpty
                                      ? null
                                      : () => _resetToGymName(
                                          context: context,
                                          ref: ref,
                                          gymId: gymId,
                                          equipment: liveEquipment,
                                        ),
                                ),
                            ],
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
                              scope: isOpenStation
                                  ? PerformanceScope.exerciseOnStation(
                                      exerciseKey: activeExerciseKey,
                                      equipmentId: liveEquipment.id,
                                    )
                                  : PerformanceScope.fixedEquipment(
                                      exerciseKey: activeExerciseKey,
                                      equipmentId: liveEquipment.id,
                                    ),
                            )),
                          )
                          .when(
                            data: (points) => E1rmProgressChart(
                              points: points,
                              emptyMessage: context.l10n.e1rmChartEmptyState,
                            ),
                            loading: () => const _SectionSkeleton(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                      const SizedBox(height: 24),
                    ],

                    // ── MUSCLE GROUPS (fixed machines only) ─────────────────
                    if (liveEquipment.equipmentType ==
                            EquipmentType.fixedMachine &&
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
                    if (isOpenWithoutSelection)
                      _EmptySection(message: l10n.selectExerciseForHistory)
                    else
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
                                    .map(
                                      (h) => _HistoryRow(
                                        entry: h,
                                        onTap: activeExerciseKey.isEmpty
                                            ? null
                                            : () => _openHistoryDetailSheet(
                                                context: context,
                                                gymId: gymId,
                                                userId: userId,
                                                equipmentId: liveEquipment.id,
                                                exerciseKey: activeExerciseKey,
                                                entry: h,
                                              ),
                                      ),
                                    )
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
                                  equipmentId: liveEquipment.id,
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

  Future<void> _renameForMe({
    required BuildContext context,
    required WidgetRef ref,
    required String gymId,
    required GymEquipment equipment,
  }) async {
    final ctrl = TextEditingController(text: equipment.displayName);
    final nextName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Rename for me'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  maxLength: kEquipmentAliasMaxLength,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Personal name',
                    errorText: errorText,
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setState(() => errorText = null);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Gym name: ${equipment.name}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final trimmed = ctrl.text.trim();
                  if (trimmed.isEmpty) {
                    setState(() => errorText = 'Name cannot be empty.');
                    return;
                  }
                  Navigator.of(ctx).pop(trimmed);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    if (nextName == null || !context.mounted) return;

    try {
      await ref
          .read(equipmentNameOverrideServiceProvider)
          .setPersonalName(
            gymId: gymId,
            equipmentId: equipment.id,
            displayName: nextName,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Personal name saved.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save personal name: $e')),
      );
    }
  }

  Future<void> _resetToGymName({
    required BuildContext context,
    required WidgetRef ref,
    required String gymId,
    required GymEquipment equipment,
  }) async {
    try {
      await ref
          .read(equipmentNameOverrideServiceProvider)
          .resetToCanonical(gymId: gymId, equipmentId: equipment.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reverted to gym name.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not reset name: $e')));
    }
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

  void _openHistoryDetailSheet({
    required BuildContext context,
    required String gymId,
    required String userId,
    required String equipmentId,
    required String exerciseKey,
    required EquipmentHistorySummary entry,
  }) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _HistoryDetailSheet(
          args: (
            gymId: gymId,
            userId: userId,
            sessionId: entry.sessionId,
            equipmentId: equipmentId,
            exerciseKey: exerciseKey,
          ),
        ),
      ),
    );
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
        boxShadow: [BoxShadow(color: color.withAlpha(30), blurRadius: 8)],
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: color, letterSpacing: 0.8),
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

class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? AppColors.neonCyan : AppColors.textDisabled;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(72)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.labelSm.copyWith(color: color)),
          ],
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

class _HistoryDetailSheet extends ConsumerWidget {
  const _HistoryDetailSheet({required this.args});

  final ({
    String gymId,
    String userId,
    String sessionId,
    String equipmentId,
    String exerciseKey,
  })
  args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detailAsync = ref.watch(equipmentHistoryDetailProvider(args));

    return DraggableScrollableSheet(
      initialChildSize: 0.74,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        key: const Key('equipment-history-detail-sheet'),
        decoration: const BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: detailAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan),
          ),
          error: (_, __) => Center(
            child: Text(
              l10n.historyCouldNotLoad,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          data: (detail) {
            if (detail == null) {
              return Center(
                child: Text(
                  l10n.noSetsLogged,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            final dateLabel = DateFormat(
              'dd MMM yyyy',
            ).format(DateTime.parse(detail.sessionDayAnchor));
            final dur = detail.duration;
            final durLabel = dur != null
                ? dur.inHours > 0
                      ? '${dur.inHours}h ${dur.inMinutes.remainder(60)}min'
                      : '${dur.inMinutes}min'
                : '—';

            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.historyFor(detail.exerciseName),
                        style: AppTextStyles.labelLg,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateLabel  ·  ${l10n.setsRepsLabel(detail.setCount, detail.totalReps, durLabel)}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (detail.totalVolumeKg > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${detail.totalVolumeKg.toStringAsFixed(0)} kg vol',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ...detail.sets.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final set = entry.value;
                  return Container(
                    key: Key('history-detail-set-$index'),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface900,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surface500),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '#$index',
                            style: AppTextStyles.monoSm.copyWith(
                              color: AppColors.neonCyan,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _setPrimaryValue(set),
                            style: AppTextStyles.bodyMd,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _setPrimaryValue(LocalSetEntry set) {
  final reps = set.reps;
  final weight = set.weightKg;
  if (reps != null && reps > 0 && weight != null && weight > 0) {
    final weightLabel = weight == weight.truncateToDouble()
        ? weight.toInt().toString()
        : weight.toStringAsFixed(1);
    return '$reps × ${weightLabel}kg';
  }
  final duration = set.durationSeconds;
  if (duration != null && duration > 0) return '${duration}s';
  final distance = set.distanceMeters;
  if (distance != null && distance > 0) {
    return '${distance.toStringAsFixed(0)}m';
  }
  return '—';
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, this.onTap});

  final EquipmentHistorySummary entry;
  final VoidCallback? onTap;

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: AppColors.surface700,
          child: InkWell(
            onTap: onTap,
            child: Container(
              key: Key('equipment-history-row-${entry.sessionId}'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
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
                          l10n.setsRepsLabel(
                            entry.setCount,
                            entry.totalReps,
                            durLabel,
                          ),
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
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
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
            autocorrect: false,
            enableSuggestions: false,
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
            autocorrect: false,
            enableSuggestions: false,
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
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...exercises.map(
            (e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ExerciseChip(
                label: e.name,
                isSelected: selectedKey == e.exerciseKey,
                onTap: () => onSelected(e.exerciseKey),
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
            children: primary
                .map((e) => _MgChip(entry: e, isPrimary: true))
                .toList(),
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
            children: secondary
                .map((e) => _MgChip(entry: e, isPrimary: false))
                .toList(),
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
        style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 11),
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
