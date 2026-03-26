import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../router/route_names.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/workout_drafts_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/equipment_detail_sheet.dart';
import 'equipment_picker_screen.dart';

// ─── Column widths ────────────────────────────────────────────────────────────

const _kSetW = 32.0;
const _kPrevW = 72.0;
const _kKgW = 72.0;
const _kRepsW = 72.0;
const _kCheckW = 40.0;

// ─── Active workout screen ────────────────────────────────────────────────────

class ActiveWorkoutScreen extends HookConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider);
    final l10n = context.l10n;

    if (workoutState is! WorkoutActive) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = workoutState.session;
    final elapsed = _useElapsedTimer(session.startedAt);

    final exerciseKeys = useMemoized(() => <String, GlobalKey>{});

    ref.listen<String?>(focusedExerciseIdProvider, (_, exerciseId) {
      if (exerciseId == null) return;
      unawaited(
        Future.delayed(const Duration(milliseconds: 250), () {
          final key = exerciseKeys[exerciseId];
          if (key?.currentContext != null) {
            unawaited(
              Scrollable.ensureVisible(
                key!.currentContext!,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                alignment: 0.05,
              ),
            );
          }
        }),
      );
      unawaited(
        Future.delayed(const Duration(milliseconds: 2000), () {
          ref.read(focusedExerciseIdProvider.notifier).state = null;
        }),
      );
    });

    final restDuration = useState(0);
    final restRemaining = useState<int?>(null);
    final restTimerHandle = useRef<Timer?>(null);
    // Absolute end-time used to recompute remaining correctly after background.
    final restEndTime = useRef<DateTime?>(null);

    useEffect(
      () =>
          () => restTimerHandle.value?.cancel(),
      const [],
    );

    // Recompute remaining when the app returns from background — the periodic
    // timer was suspended by the OS, so remaining would otherwise be stale.
    useEffect(() {
      final listener = AppLifecycleListener(
        onResume: () {
          final end = restEndTime.value;
          if (end == null) return;
          final remaining = end.difference(DateTime.now()).inSeconds;
          if (remaining <= 0) {
            restTimerHandle.value?.cancel();
            restEndTime.value = null;
            restRemaining.value = null;
            unawaited(SystemSound.play(SystemSoundType.alert));
          } else {
            restRemaining.value = remaining;
          }
        },
      );
      return listener.dispose;
    }, const []);

    void startRestTimer() {
      if (restDuration.value == 0) return;
      restTimerHandle.value?.cancel();
      final endTime = DateTime.now().add(Duration(seconds: restDuration.value));
      restEndTime.value = endTime;
      restRemaining.value = restDuration.value;
      restTimerHandle.value = Timer.periodic(const Duration(seconds: 1), (t) {
        final remaining = endTime.difference(DateTime.now()).inSeconds;
        if (remaining <= 0) {
          t.cancel();
          restEndTime.value = null;
          restRemaining.value = null;
          unawaited(SystemSound.play(SystemSoundType.alert));
        } else {
          restRemaining.value = remaining;
        }
      });
    }

    void stopRestTimer() {
      restTimerHandle.value?.cancel();
      restEndTime.value = null;
      restRemaining.value = null;
    }

    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_formatElapsed(elapsed), style: AppTextStyles.monoSm),
        actions: [
          _RestTimerButton(
            remaining: restRemaining.value,
            duration: restDuration.value,
            onDurationSelected: (d) {
              restDuration.value = d;
              if (d > 0) {
                startRestTimer();
              } else {
                stopRestTimer();
              }
            },
            onCancel: stopRestTimer,
          ),
          PopupMenuButton<_WorkoutAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              if (action == _WorkoutAction.discard) {
                unawaited(_discardWorkout(context, ref));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _WorkoutAction.discard,
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_forever_outlined,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.discardWorkoutMenu,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => unawaited(_finishWorkout(context, ref)),
            child: Text(
              l10n.finish,
              style: AppTextStyles.labelLg.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
        children: [
          Expanded(
            child: workoutState.exercises.isEmpty
                ? const _EmptyExerciseState()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: workoutState.exercises.length,
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      unawaited(
                        ref
                            .read(workoutProvider.notifier)
                            .reorderExercises(oldIndex, newIndex),
                      );
                    },
                    itemBuilder: (context, i) {
                      final exerciseState = workoutState.exercises[i];
                      final cardKey = exerciseKeys.putIfAbsent(
                        exerciseState.exercise.id,
                        GlobalKey.new,
                      );
                      return Padding(
                        key: ValueKey(exerciseState.exercise.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ExerciseCard(
                          cardKey: cardKey,
                          index: i,
                          state: exerciseState,
                          gymId: session.gymId,
                          userId: user?.id ?? '',
                          sessionId: session.id,
                          onSetChecked: startRestTimer,
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TapemButton(
                label: l10n.addExercise,
                icon: Icons.add,
                variant: TapemButtonVariant.outlined,
                onPressed: () => unawaited(_addExercise(context, ref)),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final active = ref.read(workoutProvider);
    if (active is! WorkoutActive) return;

    final result = await Navigator.of(context)
        .push<
          ({
            String exerciseKey,
            String displayName,
            String? customExerciseId,
            String equipmentId,
          })
        >(
          MaterialPageRoute(
            builder: (_) => EquipmentPickerScreen(
              gymId: active.session.gymId,
              addToActiveWorkout: true,
            ),
          ),
        );

    if (result == null) return;

    final current = ref.read(workoutProvider);
    if (current is! WorkoutActive) return;

    // Same machine + same exercise key = already in workout → just focus it.
    // Different machines that share a canonical key are allowed simultaneously.
    final existing = current.exercises
        .where(
          (e) =>
              e.exercise.exerciseKey == result.exerciseKey &&
              e.exercise.equipmentId == result.equipmentId,
        )
        .firstOrNull;
    if (existing != null) {
      ref.read(focusedExerciseIdProvider.notifier).state = existing.exercise.id;
      return;
    }

    await ref
        .read(workoutProvider.notifier)
        .addExercise(
          exerciseKey: result.exerciseKey,
          displayName: result.displayName,
          customExerciseId: result.customExerciseId,
          equipmentId: result.equipmentId,
        );

    final updated = ref.read(workoutProvider);
    if (updated is WorkoutActive) {
      final added = updated.exercises
          .where(
            (e) =>
                e.exercise.exerciseKey == result.exerciseKey &&
                e.exercise.equipmentId == result.equipmentId,
          )
          .lastOrNull;
      if (added != null) {
        ref.read(focusedExerciseIdProvider.notifier).state = added.exercise.id;
      }
    }
  }

  Future<void> _discardWorkout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discardWorkoutFullTitle),
        content: Text(l10n.discardWorkoutFullContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.keep),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.discard,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(workoutProvider.notifier).discardSession();
    if (context.mounted) {
      context.go(RouteNames.home);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.workoutDiscardedSnack),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _finishWorkout(BuildContext context, WidgetRef ref) async {
    final workoutState = ref.read(workoutProvider);
    if (workoutState is! WorkoutActive) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.finishWorkoutTitle),
        content: Text(l10n.finishWorkoutContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.finish,
              style: const TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    // Re-read state after the dialog await — it may have changed.
    final currentState = ref.read(workoutProvider);
    if (currentState is! WorkoutActive) return;

    final notifier = ref.read(workoutProvider.notifier);

    // Sets are persisted to SQLite immediately on check, so exerciseState.sets
    // is the authoritative list of confirmed sets at this point.
    // Delete any exercises that have no persisted sets (user added the exercise
    // but never checked a single set).
    for (final exerciseState in currentState.exercises) {
      if (exerciseState.sets.isEmpty) {
        await notifier.deleteExercise(exerciseState.exercise.id);
      }
    }

    await notifier.finishSession();
    if (context.mounted) context.go(RouteNames.home);
  }
}

// ─── Workout action enum ──────────────────────────────────────────────────────

enum _WorkoutAction { discard }

// ─── Rest timer button ────────────────────────────────────────────────────────

class _RestTimerButton extends StatelessWidget {
  const _RestTimerButton({
    required this.remaining,
    required this.duration,
    required this.onDurationSelected,
    required this.onCancel,
  });

  final int? remaining;
  final int duration;
  final void Function(int seconds) onDurationSelected;
  final VoidCallback onCancel;

  static const _options = [30, 60, 90, 120, 150, 180];

  @override
  Widget build(BuildContext context) {
    final isRunning = remaining != null;
    final noTimer = duration == 0;
    final l10n = context.l10n;

    return PopupMenuButton<int>(
      tooltip: 'Rest timer',
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == -1) {
          onCancel();
        } else {
          onDurationSelected(value);
        }
      },
      itemBuilder: (_) => [
        if (isRunning)
          PopupMenuItem<int>(
            value: -1,
            child: Row(
              children: [
                const Icon(Icons.timer_off_outlined, size: 18),
                const SizedBox(width: 8),
                Text(l10n.cancelTimer),
              ],
            ),
          ),
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(
                Icons.timer_off_outlined,
                size: 18,
                color: noTimer && !isRunning ? AppColors.neonCyan : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Kein Timer',
                style: noTimer && !isRunning
                    ? AppTextStyles.bodyMd.copyWith(color: AppColors.neonCyan)
                    : AppTextStyles.bodyMd,
              ),
            ],
          ),
        ),
        ..._options.map(
          (s) => PopupMenuItem<int>(
            value: s,
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: s == duration && !isRunning
                      ? AppColors.neonCyan
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  '${s}s',
                  style: s == duration && !isRunning
                      ? AppTextStyles.bodyMd.copyWith(color: AppColors.neonCyan)
                      : AppTextStyles.bodyMd,
                ),
              ],
            ),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRunning ? Icons.timer : Icons.timer_outlined,
              size: 18,
              color: isRunning
                  ? AppColors.neonCyan
                  : noTimer
                  ? AppColors.textDisabled
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              isRunning
                  ? _formatCountdown(remaining!)
                  : noTimer
                  ? '–'
                  : '${duration}s',
              style: AppTextStyles.monoSm.copyWith(
                color: isRunning
                    ? AppColors.neonCyan
                    : noTimer
                    ? AppColors.textDisabled
                    : AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Elapsed timer hook ───────────────────────────────────────────────────────

Duration _useElapsedTimer(DateTime startedAt) {
  final elapsed = useState(DateTime.now().difference(startedAt));
  useEffect(() {
    final timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value = DateTime.now().difference(startedAt);
    });
    // Force a sync update the instant the app returns to foreground —
    // Timer.periodic is suspended by the OS during background.
    final lifecycleListener = AppLifecycleListener(
      onResume: () => elapsed.value = DateTime.now().difference(startedAt),
    );
    return () {
      timer.cancel();
      lifecycleListener.dispose();
    };
  }, const []);
  return elapsed.value;
}

String _formatElapsed(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyExerciseState extends StatelessWidget {
  const _EmptyExerciseState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(l10n.sessionStarted, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            l10n.addExerciseHint,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Exercise card ────────────────────────────────────────────────────────────

class _ExerciseCard extends HookConsumerWidget {
  const _ExerciseCard({
    required this.cardKey,
    required this.index,
    required this.state,
    required this.gymId,
    required this.userId,
    required this.sessionId,
    required this.onSetChecked,
  });

  final GlobalKey cardKey;
  final int index;
  final SessionExerciseState state;
  final String gymId;
  final String userId;
  final String sessionId;
  final VoidCallback onSetChecked;

  bool get _isCardio => state.exercise.exerciseKey.startsWith('cardio:');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final equipment = ref
        .watch(gymEquipmentProvider(gymId))
        .maybeWhen(
          data: (list) {
            final key = state.exercise.exerciseKey;
            if (key.startsWith('cardio:')) {
              final eqId = key.substring(6);
              return list.where((e) => e.id == eqId).firstOrNull;
            }
            if (key.startsWith('custom:')) {
              final eqId = state.exercise.equipmentId;
              if (eqId == null) return null;
              return list.where((e) => e.id == eqId).firstOrNull;
            }
            return list.where((e) => e.canonicalExerciseKey == key).firstOrNull;
          },
          orElse: () => null,
        );
    final manufacturer = equipment?.manufacturer;

    final prevSetsAsync = ref.watch(
      previousSetsProvider((
        gymId: gymId,
        userId: userId,
        exerciseKey: state.exercise.exerciseKey,
        currentSessionId: sessionId,
      )),
    );
    final prevSets = prevSetsAsync.maybeWhen(
      data: (s) => s,
      orElse: () => <LocalSetEntry>[],
    );

    final drafts = ref.watch(
      workoutDraftsProvider.select(
        (m) => m[state.exercise.id] ?? const <SetDraft>[],
      ),
    );

    final isFocused = ref.watch(
      focusedExerciseIdProvider.select((id) => id == state.exercise.id),
    );

    final initialized = useState(false);
    useEffect(() {
      if (initialized.value) return null;

      List<SetDraft>? drafts;

      if (state.sets.isNotEmpty) {
        // Restore checked drafts from SQLite-persisted sets.
        // persistedSetId links each draft to its SQLite row so that
        // unchecking later calls deleteSet with the correct ID.
        drafts = state.sets
            .map(
              (s) => SetDraft(
                weightKg: s.weightKg,
                reps: s.reps,
                isChecked: true,
                persistedSetId: s.id,
              ),
            )
            .toList();
      } else if (!prevSetsAsync.isLoading) {
        final count = prevSets.isNotEmpty ? prevSets.length : 3;
        drafts = List.generate(count, (_) => SetDraft());
      }

      if (drafts == null) return null;

      initialized.value = true;

      final exerciseId = state.exercise.id;
      final snapshot = drafts;

      unawaited(
        Future(
          () => ref
              .read(workoutDraftsProvider.notifier)
              .initExercise(exerciseId, snapshot),
        ),
      );

      return null;
    }, [prevSetsAsync]);

    return AnimatedContainer(
      key: cardKey,
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFocused ? AppColors.neonCyan : AppColors.surface500,
          width: isFocused ? 2.0 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.neonCyan.withAlpha(40),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.drag_handle,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.exercise.displayName.toUpperCase(),
                        style: AppTextStyles.h3,
                      ),
                      if (manufacturer != null && manufacturer.isNotEmpty)
                        Text(
                          manufacturer,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (equipment != null)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: l10n.equipmentDetails,
                      icon: const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => unawaited(
                        showEquipmentDetailSheet(context, equipment, gymId),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        unawaited(_confirmDeleteExercise(context, ref)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (!_isCardio) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: _kSetW,
                    child: Text(
                      l10n.setColumnHeader,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _kPrevW,
                    child: Text(
                      l10n.prevColumnHeader,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: _kKgW,
                    child: Text(
                      l10n.kgColumnHeader,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: _kRepsW,
                    child: Text(
                      l10n.repsColumnHeader,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: _kCheckW),
                ],
              ),
            ),

            const SizedBox(height: 4),

            if (drafts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              ...drafts.asMap().entries.map((entry) {
                final draftIndex = entry.key;
                final draft = entry.value;
                return Dismissible(
                  key: ValueKey(draft.id),
                  direction: DismissDirection.endToStart,
                  secondaryBackground: Container(
                    color: AppColors.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  background: const SizedBox.shrink(),
                  onDismissed: (_) {
                    // If the draft was persisted (checked), also remove the
                    // SQLite row. Fire-and-forget: the draft is already gone
                    // from the UI via removeSet below; a DB failure here just
                    // leaves an orphan set entry that won't affect UX.
                    final swipedDraft = ref
                        .read(workoutDraftsProvider)[state.exercise.id]
                        ?.elementAtOrNull(draftIndex);
                    if (swipedDraft?.persistedSetId != null) {
                      unawaited(
                        ref
                            .read(workoutProvider.notifier)
                            .deleteSet(
                              swipedDraft!.persistedSetId!,
                              state.exercise.id,
                            ),
                      );
                    }
                    ref
                        .read(workoutDraftsProvider.notifier)
                        .removeSet(state.exercise.id, draftIndex);
                  },
                  child: _EditableSetRow(
                    key: ValueKey(draft.id),
                    exerciseId: state.exercise.id,
                    index: draftIndex,
                    initialDraft: draft,
                    prevSet: draftIndex < prevSets.length
                        ? prevSets[draftIndex]
                        : null,
                    onSetChecked: onSetChecked,
                  ),
                );
              }),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const SizedBox(width: _kSetW + _kPrevW + _kKgW + _kRepsW),
                  SizedBox(
                    width: _kCheckW,
                    height: _kCheckW,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 22,
                        color: AppColors.neonCyan,
                      ),
                      onPressed: () => ref
                          .read(workoutDraftsProvider.notifier)
                          .addSet(state.exercise.id),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...state.sets.asMap().entries.map(
              (entry) => _CardioSetRow(
                setIndex: entry.key,
                set: entry.value,
                onDelete: () => ref
                    .read(workoutProvider.notifier)
                    .deleteSet(entry.value.id, state.exercise.id),
              ),
            ),
            if (state.sets.isNotEmpty) const Divider(height: 1),
            _CardioSetLogger(
              exerciseId: state.exercise.id,
              onSetLogged: onSetChecked,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDeleteExercise(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeExerciseTitle),
        content: Text(l10n.removeExerciseContent(state.exercise.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.remove,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(workoutProvider.notifier)
          .deleteExercise(state.exercise.id);
    }
  }
}

// ─── Editable strength set row ────────────────────────────────────────────────

class _EditableSetRow extends HookConsumerWidget {
  const _EditableSetRow({
    super.key,
    required this.exerciseId,
    required this.index,
    required this.initialDraft,
    required this.onSetChecked,
    this.prevSet,
  });

  final String exerciseId;
  final int index;
  final SetDraft initialDraft;
  final LocalSetEntry? prevSet;
  final VoidCallback onSetChecked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightCtrl = useTextEditingController(
      text:
          initialDraft.weightKg?.toStringAsFixed(
            initialDraft.weightKg! % 1 == 0 ? 0 : 1,
          ) ??
          '',
    );
    final repsCtrl = useTextEditingController(
      text: initialDraft.reps?.toString() ?? '',
    );

    final isChecked = ref.watch(
      workoutDraftsProvider.select(
        (m) =>
            m[exerciseId]?.elementAtOrNull(index)?.isChecked ??
            initialDraft.isChecked,
      ),
    );

    // Guards against double-tap while logSet() is in-flight.
    final isLogging = useState(false);

    final prevText = prevSet != null
        ? '${_fmt(prevSet!.weightKg)}×${prevSet!.reps ?? 0}'
        : '—';

    return Container(
      color: isChecked ? AppColors.success.withAlpha(10) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: _kSetW,
              child: Text(
                '${index + 1}',
                style: AppTextStyles.monoSm.copyWith(
                  color: isChecked
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              width: _kPrevW,
              child: Text(
                prevText,
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: _kKgW,
              child: TextFormField(
                controller: weightCtrl,
                textAlign: TextAlign.center,
                // Locked once checked — uncheck first to edit.
                readOnly: isChecked,
                style: AppTextStyles.bodyLg.copyWith(
                  color: isChecked ? AppColors.textSecondary : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  // Accept both '.' and ',' as decimal separator so European
                  // users can enter e.g. "97,5" or "97.5".
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: prevSet?.weightKg != null
                      ? _fmt(prevSet!.weightKg)
                      : '0',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: isChecked
                    ? null
                    : (text) => ref
                          .read(workoutDraftsProvider.notifier)
                          .updateWeight(
                            exerciseId,
                            index,
                            // Normalise comma → dot so double.tryParse handles
                            // both "97,5" (European) and "97.5" correctly.
                            double.tryParse(text.replaceAll(',', '.')),
                          ),
              ),
            ),
            SizedBox(
              width: _kRepsW,
              child: TextFormField(
                controller: repsCtrl,
                textAlign: TextAlign.center,
                // Locked once checked — uncheck first to edit.
                readOnly: isChecked,
                style: AppTextStyles.bodyLg.copyWith(
                  color: isChecked ? AppColors.textSecondary : null,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: prevSet?.reps != null ? '${prevSet!.reps}' : '0',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: isChecked
                    ? null
                    : (text) => ref
                          .read(workoutDraftsProvider.notifier)
                          .updateReps(
                            exerciseId,
                            index,
                            int.tryParse(text),
                          ),
              ),
            ),
            SizedBox(
              width: _kCheckW,
              height: _kCheckW,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  isChecked ? Icons.check_circle : Icons.check_circle_outline,
                  color: isChecked
                      ? AppColors.success
                      : AppColors.textSecondary,
                  size: 26,
                ),
                onPressed: isLogging.value
                    ? null
                    : () async {
                        if (!isChecked) {
                          // ── Check: persist immediately to SQLite ──────────
                          // Reading from controllers (source of truth) rather
                          // than the draft so we always capture the latest text.
                          final kg = double.tryParse(
                            weightCtrl.text.replaceAll(',', '.'),
                          );
                          final reps = int.tryParse(repsCtrl.text);
                          isLogging.value = true;
                          try {
                            final setId = await ref
                                .read(workoutProvider.notifier)
                                .logSet(
                                  sessionExerciseId: exerciseId,
                                  weightKg: kg,
                                  reps: reps,
                                );
                            ref
                                .read(workoutDraftsProvider.notifier)
                                .checkSet(exerciseId, index, setId);
                            onSetChecked();
                          } finally {
                            isLogging.value = false;
                          }
                        } else {
                          // ── Uncheck: remove from SQLite ───────────────────
                          final currentDraft = ref
                              .read(workoutDraftsProvider)[exerciseId]
                              ?.elementAtOrNull(index);
                          if (currentDraft?.persistedSetId != null) {
                            await ref
                                .read(workoutProvider.notifier)
                                .deleteSet(
                                  currentDraft!.persistedSetId!,
                                  exerciseId,
                                );
                          }
                          ref
                              .read(workoutDraftsProvider.notifier)
                              .uncheckSet(exerciseId, index);
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double? v) {
    if (v == null) return '—';
    return v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
  }
}

// ─── Logged cardio set row ────────────────────────────────────────────────────

class _CardioSetRow extends StatelessWidget {
  const _CardioSetRow({
    required this.setIndex,
    required this.set,
    required this.onDelete,
  });

  final int setIndex;
  final LocalSetEntry set;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(set.id),
      direction: DismissDirection.endToStart,
      secondaryBackground: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      background: const SizedBox.shrink(),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: _kSetW,
              child: Text(
                '${setIndex + 1}',
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                _formatDuration(set.durationSeconds ?? 0),
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.neonYellow,
                  fontSize: 15,
                ),
              ),
            ),
            if (set.distanceMeters != null)
              Text(
                '${(set.distanceMeters! / 1000).toStringAsFixed(2)} km',
                style: AppTextStyles.monoSm,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Cardio set logger ────────────────────────────────────────────────────────

class _CardioSetLogger extends HookConsumerWidget {
  const _CardioSetLogger({required this.exerciseId, required this.onSetLogged});

  final String exerciseId;
  final VoidCallback onSetLogged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = useState(false);
    final elapsed = useState(Duration.zero);
    final timerRef = useRef<Timer?>(null);
    final startedAt = useRef<DateTime?>(null);
    final l10n = context.l10n;

    useEffect(
      () =>
          () => timerRef.value?.cancel(),
      const [],
    );

    // Sync elapsed display the instant the app returns from background.
    useEffect(() {
      final listener = AppLifecycleListener(
        onResume: () {
          if (isRunning.value && startedAt.value != null) {
            elapsed.value = DateTime.now().difference(startedAt.value!);
          }
        },
      );
      return listener.dispose;
    }, const []);

    void startTimer() {
      startedAt.value = DateTime.now();
      isRunning.value = true;
      timerRef.value = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsed.value = DateTime.now().difference(startedAt.value!);
      });
    }

    Future<void> stopAndLog() async {
      timerRef.value?.cancel();
      isRunning.value = false;
      final seconds = elapsed.value.inSeconds;
      elapsed.value = Duration.zero;
      if (seconds > 0) {
        await ref
            .read(workoutProvider.notifier)
            .logSet(sessionExerciseId: exerciseId, durationSeconds: seconds);
        onSetLogged();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            _formatElapsed(elapsed.value),
            style: AppTextStyles.monoLg.copyWith(
              color: isRunning.value
                  ? AppColors.neonCyan
                  : AppColors.textSecondary,
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isRunning.value)
                TapemButton(
                  label: l10n.startTimer,
                  icon: Icons.play_arrow,
                  onPressed: startTimer,
                )
              else
                TapemButton(
                  label: l10n.stopAndLog,
                  icon: Icons.stop,
                  onPressed: stopAndLog,
                  variant: TapemButtonVariant.outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
