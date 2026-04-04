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
import '../providers/workout_keyboard_provider.dart';
import '../providers/workout_provider.dart';
import '../utils/workout_kg_format.dart';
import '../widgets/equipment_detail_sheet.dart';
import '../widgets/sync_state_badge.dart';
import '../widgets/workout_keyboard.dart';
import 'equipment_picker_screen.dart';

// ─── Column widths ────────────────────────────────────────────────────────────

const _kSetW = 32.0;
const _kPrevW = 72.0;
const _kKgW = 76.0;
const _kRepsW = 76.0;
const _kCheckW = 44.0;

// Extra bottom padding added to the exercise list when the custom keyboard is visible,
// so the user can scroll the last set row above the keyboard panel.
const _kKbScrollPad = kWorkoutKeyboardBodyHeight + 16.0;

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
    final restEndTime = useRef<DateTime?>(null);

    useEffect(
      () =>
          () => restTimerHandle.value?.cancel(),
      const [],
    );

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

    // Compute live stats for the header bar
    final totalSets = workoutState.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.length,
    );
    final totalVolume = workoutState.exercises.fold<double>(
      0,
      (sum, e) =>
          sum +
          e.sets.fold<double>(
            0,
            (s, set) => s + (set.weightKg ?? 0) * (set.reps ?? 0),
          ),
    );

    final isKeyboardVisible = ref.watch(workoutKeyboardProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.surface900,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          ref.read(workoutKeyboardProvider.notifier).close();
        },
        child: Column(
          children: [
            // ── Premium header ────────────────────────────────────────────
            _WorkoutHeader(
              elapsed: elapsed,
              restRemaining: restRemaining.value,
              restDuration: restDuration.value,
              totalSets: totalSets,
              totalVolume: totalVolume,
              exerciseCount: workoutState.exercises.length,
              onDurationSelected: (d) {
                restDuration.value = d;
                if (d > 0) {
                  startRestTimer();
                } else {
                  stopRestTimer();
                }
              },
              onCancelRest: stopRestTimer,
              onDiscard: () => unawaited(_discardWorkout(context, ref)),
              onFinish: () => unawaited(_finishWorkout(context, ref)),
            ),
            // ── Exercise list ─────────────────────────────────────────────
            Expanded(
              child: workoutState.exercises.isEmpty
                  ? const _EmptyExerciseState()
                  : ReorderableListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        isKeyboardVisible ? _kKbScrollPad : 24,
                      ),
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
            // ── Add exercise button — always visible, above the keyboard ──
            _AddExerciseBar(
              onPressed: () {
                ref.read(workoutKeyboardProvider.notifier).close();
                unawaited(_addExercise(context, ref));
              },
              label: l10n.addExercise,
            ),
            // ── Custom keyboard slides in below the add bar ───────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: isKeyboardVisible
                  ? const WorkoutKeyboard()
                  : const SizedBox.shrink(),
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

    final currentState = ref.read(workoutProvider);
    if (currentState is! WorkoutActive) return;

    final notifier = ref.read(workoutProvider.notifier);

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

// ─── Premium workout header ───────────────────────────────────────────────────

class _WorkoutHeader extends ConsumerWidget {
  const _WorkoutHeader({
    required this.elapsed,
    required this.restRemaining,
    required this.restDuration,
    required this.totalSets,
    required this.totalVolume,
    required this.exerciseCount,
    required this.onDurationSelected,
    required this.onCancelRest,
    required this.onDiscard,
    required this.onFinish,
  });

  final Duration elapsed;
  final int? restRemaining;
  final int restDuration;
  final int totalSets;
  final double totalVolume;
  final int exerciseCount;
  final void Function(int seconds) onDurationSelected;
  final VoidCallback onCancelRest;
  final VoidCallback onDiscard;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.of(context).padding.top;
    final isRestRunning = restRemaining != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface900,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surface500.withAlpha(100),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: top + 2),

          // ── Single compact header row ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Timer — inline, medium size
                _PulsingTimer(elapsed: elapsed),
                const SizedBox(width: 10),

                // Rest timer chip — shown inline next to timer
                if (isRestRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withAlpha(18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.neonCyan.withAlpha(70),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _fmtCountdown(restRemaining!),
                      style: AppTextStyles.monoSm.copyWith(
                        color: AppColors.neonCyan,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),

                const Spacer(),

                // Rest timer picker button
                _RestTimerButton(
                  remaining: restRemaining,
                  duration: restDuration,
                  onDurationSelected: onDurationSelected,
                  onCancel: onCancelRest,
                ),

                // More menu
                PopupMenuButton<_WorkoutAction>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  color: AppColors.surface700,
                  onSelected: (action) {
                    if (action == _WorkoutAction.discard) onDiscard();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _WorkoutAction.discard,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_forever_outlined,
                            color: AppColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Training verwerfen',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),

                // FERTIG pill
                _FertigButton(onTap: onFinish),
              ],
            ),
          ),

          // ── Stats strip ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.surface500.withAlpha(80),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.fitness_center,
                  value: '$exerciseCount',
                  label: exerciseCount == 1 ? 'Übung' : 'Übungen',
                ),
                const SizedBox(width: 20),
                _StatChip(
                  icon: Icons.check_circle_outline,
                  value: '$totalSets',
                  label: totalSets == 1 ? 'Satz' : 'Sätze',
                ),
                const SizedBox(width: 20),
                if (totalVolume > 0)
                  _StatChip(
                    icon: Icons.bar_chart,
                    value: totalVolume >= 1000
                        ? '${(totalVolume / 1000).toStringAsFixed(1)}t'
                        : '${totalVolume.toStringAsFixed(0)} kg',
                    label: 'Volumen',
                  ),
                const Spacer(),
                const SyncStateBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── FERTIG button with press animation ──────────────────────────────────────

class _FertigButton extends StatefulWidget {
  const _FertigButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_FertigButton> createState() => _FertigButtonState();
}

class _FertigButtonState extends State<_FertigButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.success.withAlpha(_pressed ? 50 : 30),
            border: Border.all(
              color: AppColors.success.withAlpha(_pressed ? 200 : 140),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withAlpha(_pressed ? 60 : 30),
                blurRadius: _pressed ? 12 : 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_rounded,
                size: 14,
                color: AppColors.success.withAlpha(220),
              ),
              const SizedBox(width: 5),
              Text(
                'FERTIG',
                style: AppTextStyles.labelLg.copyWith(
                  color: AppColors.success.withAlpha(220),
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing timer display ────────────────────────────────────────────────────

class _PulsingTimer extends HookWidget {
  const _PulsingTimer({required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 2),
    );
    useEffect(() {
      controller.repeat(reverse: true);
      return null;
    }, const []);

    final glowAlpha = useAnimation(
      Tween<double>(
        begin: 60,
        end: 140,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
    );

    return Text(
      _formatElapsed(elapsed),
      style: AppTextStyles.monoLg.copyWith(
        fontSize: 28,
        color: AppColors.neonCyan,
        letterSpacing: 2,
        fontFeatures: const [FontFeature.tabularFigures()],
        shadows: [
          Shadow(
            color: AppColors.neonCyan.withAlpha(glowAlpha.toInt()),
            blurRadius: 16,
          ),
        ],
      ),
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textDisabled),
        const SizedBox(width: 5),
        Text(
          value,
          style: AppTextStyles.monoSm.copyWith(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(color: AppColors.textDisabled),
        ),
      ],
    );
  }
}

// ─── Add exercise bottom bar ──────────────────────────────────────────────────

class _AddExerciseBar extends StatefulWidget {
  const _AddExerciseBar({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  State<_AddExerciseBar> createState() => _AddExerciseBarState();
}

class _AddExerciseBarState extends State<_AddExerciseBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface900,
        border: Border(
          top: BorderSide(color: AppColors.surface500.withAlpha(100), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottom),
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.neonCyan.withAlpha(60),
                width: 1,
              ),
              color: AppColors.neonCyan.withAlpha(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: 15,
                  color: AppColors.neonCyan.withAlpha(160),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label.toUpperCase(),
                  style: AppTextStyles.buttonMd.copyWith(
                    color: AppColors.neonCyan.withAlpha(160),
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

    return PopupMenuButton<int>(
      tooltip: 'Pause Timer',
      color: AppColors.surface700,
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
          const PopupMenuItem<int>(
            value: -1,
            child: Row(
              children: [
                Icon(Icons.timer_off_outlined, size: 16),
                SizedBox(width: 8),
                Text('Timer stoppen'),
              ],
            ),
          ),
        const PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.timer_off_outlined, size: 16),
              SizedBox(width: 8),
              Text('Kein Timer'),
            ],
          ),
        ),
        ..._options.map(
          (s) => PopupMenuItem<int>(
            value: s,
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16),
                const SizedBox(width: 8),
                Text('${s}s'),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: isRunning
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.neonCyan.withAlpha(15),
                border: Border.all(
                  color: AppColors.neonCyan.withAlpha(60),
                  width: 1,
                ),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRunning ? Icons.timer : Icons.timer_outlined,
              size: 16,
              color: isRunning
                  ? AppColors.neonCyan
                  : noTimer
                  ? AppColors.textDisabled
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
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
                fontSize: 13,
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

class _EmptyExerciseState extends HookWidget {
  const _EmptyExerciseState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );
    useEffect(() {
      ctrl.repeat(reverse: true);
      return null;
    }, const []);
    final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
    );
    final accent = Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: scale,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface800,
                border: Border.all(color: accent.withAlpha(60), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accent.withAlpha(20),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.fitness_center, size: 32, color: accent.withAlpha(160)),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.sessionStarted, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            l10n.addExerciseHint,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
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

    // Keep keyboard notifier's prev-sets cache current for the copy button
    useEffect(() {
      ref
          .read(workoutKeyboardProvider.notifier)
          .setPrevSets(state.exercise.id, prevSets);
      return null;
    }, [prevSets]);

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

    // Count checked sets for the card header badge
    final checkedCount = drafts.where((d) => d.isChecked).length;

    return AnimatedContainer(
      key: cardKey,
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? AppColors.neonCyan.withAlpha(200)
              : AppColors.surface500.withAlpha(120),
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.neonCyan.withAlpha(40),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ───────────────────────────────────────────────
            _ExerciseCardHeader(
              index: index,
              state: state,
              manufacturer: manufacturer,
              checkedCount: checkedCount,
              totalDrafts: drafts.length,
              gymId: gymId,
              onInfo: equipment != null
                  ? () => unawaited(
                      showEquipmentDetailSheet(context, equipment, gymId),
                    )
                  : null,
              onDelete: () => unawaited(_confirmDeleteExercise(context, ref)),
            ),

            // ── Sets ──────────────────────────────────────────────────────
            if (!_isCardio) ...[
              const _SetTableHeader(),

              if (drafts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
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
                      color: AppColors.error.withAlpha(200),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    background: const SizedBox.shrink(),
                    onDismissed: (_) {
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

              // Add set row
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 2, 16, 10),
                child: Row(
                  children: [
                    const SizedBox(
                      width: _kSetW + _kPrevW + _kKgW + _kRepsW + 16,
                    ),
                    SizedBox(
                      width: _kCheckW,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Satz hinzufügen',
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 20,
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
              if (state.sets.isNotEmpty)
                Divider(height: 1, color: AppColors.surface600.withAlpha(180)),
              _CardioSetLogger(
                exerciseId: state.exercise.id,
                onSetLogged: onSetChecked,
              ),
            ],
          ],
        ),
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

// ─── Exercise card header ─────────────────────────────────────────────────────

class _ExerciseCardHeader extends StatelessWidget {
  const _ExerciseCardHeader({
    required this.index,
    required this.state,
    required this.manufacturer,
    required this.checkedCount,
    required this.totalDrafts,
    required this.gymId,
    required this.onDelete,
    this.onInfo,
  });

  final int index;
  final SessionExerciseState state;
  final String? manufacturer;
  final int checkedCount;
  final int totalDrafts;
  final String gymId;
  final VoidCallback? onInfo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasProgress = totalDrafts > 0;
    final isComplete = hasProgress && checkedCount == totalDrafts;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface700.withAlpha(200), AppColors.surface800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.surface500.withAlpha(80),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.drag_indicator,
                color: AppColors.textDisabled,
                size: 18,
              ),
            ),
          ),

          // Exercise name + manufacturer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.exercise.displayName.toUpperCase(),
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 15,
                    letterSpacing: 1.0,
                    height: 1.2,
                  ),
                ),
                if (manufacturer != null && manufacturer!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      manufacturer!,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.neonCyan.withAlpha(160),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Progress badge
          if (hasProgress) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isComplete
                    ? AppColors.success.withAlpha(25)
                    : AppColors.surface600,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isComplete
                      ? AppColors.success.withAlpha(120)
                      : AppColors.surface500,
                  width: 1,
                ),
              ),
              child: Text(
                '$checkedCount/$totalDrafts',
                style: AppTextStyles.monoSm.copyWith(
                  color: isComplete
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Info button
          if (onInfo != null)
            SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Info',
                icon: const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textDisabled,
                ),
                onPressed: onInfo,
              ),
            ),

          // Delete button
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Übung entfernen',
              icon: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.textDisabled,
              ),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Set table column headers ─────────────────────────────────────────────────

class _SetTableHeader extends StatelessWidget {
  const _SetTableHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          SizedBox(
            width: _kSetW,
            child: Text(
              l10n.setColumnHeader,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SizedBox(
            width: _kPrevW,
            child: Text(
              l10n.prevColumnHeader,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _kKgW,
            child: Text(
              l10n.kgColumnHeader,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _kRepsW,
            child: Text(
              l10n.repsColumnHeader,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: _kCheckW),
        ],
      ),
    );
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
      text: formatWorkoutKgNullable(initialDraft.weightKg) ?? '',
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

    final isLogging = useState(false);
    final isPressed = useState(false);

    // Ref always reflects the latest isChecked — safe to capture in closures
    final isCheckedRef = useRef(false);
    isCheckedRef.value = isChecked;

    // Focus nodes for auto-scroll when keyboard appears
    final weightFocus = useFocusNode();
    final repsFocus = useFocusNode();
    final rowKey = useMemoized(GlobalKey.new);

    useEffect(() {
      void scrollRowIntoView() {
        // Wait for the keyboard to finish animating up, then scroll
        // We capture the ScrollableState before the async gap to avoid the
        // BuildContext-across-async-gap lint.
        final scrollable = Scrollable.maybeOf(rowKey.currentContext!);
        Future.delayed(const Duration(milliseconds: 380), () {
          final renderObj = rowKey.currentContext?.findRenderObject();
          if (scrollable != null && renderObj != null) {
            unawaited(
              scrollable.position.ensureVisible(
                renderObj,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                alignment: 0.4,
              ),
            );
          }
        });
      }

      void onWeightFocus() {
        if (weightFocus.hasFocus) scrollRowIntoView();
      }

      void onRepsFocus() {
        if (repsFocus.hasFocus) scrollRowIntoView();
      }

      weightFocus.addListener(onWeightFocus);
      repsFocus.addListener(onRepsFocus);
      return () {
        weightFocus.removeListener(onWeightFocus);
        repsFocus.removeListener(onRepsFocus);
      };
    }, [weightFocus, repsFocus]);

    // Register weight + reps fields with the custom keyboard notifier.
    // Closures capture stable refs; isCheckedRef provides latest isChecked.
    useEffect(() {
      final kb = ref.read(workoutKeyboardProvider.notifier);
      kb.registerField(
        exerciseId: exerciseId,
        setIndex: index,
        field: WorkoutKeyboardField.kg,
        controller: weightCtrl,
        onUpdate: (text) {
          if (isCheckedRef.value) return;
          ref
              .read(workoutDraftsProvider.notifier)
              .updateWeight(
                exerciseId,
                index,
                double.tryParse(text.replaceAll(',', '.')),
              );
        },
        focusNode: weightFocus,
      );
      kb.registerField(
        exerciseId: exerciseId,
        setIndex: index,
        field: WorkoutKeyboardField.reps,
        controller: repsCtrl,
        onUpdate: (text) {
          if (isCheckedRef.value) return;
          ref
              .read(workoutDraftsProvider.notifier)
              .updateReps(exerciseId, index, int.tryParse(text));
        },
        focusNode: repsFocus,
      );
      return () {
        kb.unregisterField(
          exerciseId: exerciseId,
          setIndex: index,
          field: WorkoutKeyboardField.kg,
        );
        kb.unregisterField(
          exerciseId: exerciseId,
          setIndex: index,
          field: WorkoutKeyboardField.reps,
        );
      };
    }, const []);

    // Register the toggle-check callback so keyboard navigation can
    // auto-check/uncheck when advancing past the checkmark button.
    useEffect(() {
      Future<void> toggleCheck() async {
        if (isLogging.value) return;
        if (!isCheckedRef.value) {
          final kg = double.tryParse(weightCtrl.text.replaceAll(',', '.'));
          final reps = int.tryParse(repsCtrl.text);
          isLogging.value = true;
          unawaited(HapticFeedback.lightImpact());
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
          final currentDraft = ref
              .read(workoutDraftsProvider)[exerciseId]
              ?.elementAtOrNull(index);
          if (currentDraft?.persistedSetId != null) {
            await ref
                .read(workoutProvider.notifier)
                .deleteSet(currentDraft!.persistedSetId!, exerciseId);
          }
          ref
              .read(workoutDraftsProvider.notifier)
              .uncheckSet(exerciseId, index);
        }
      }

      ref
          .read(workoutKeyboardProvider.notifier)
          .registerCheck(
            exerciseId: exerciseId,
            setIndex: index,
            callback: toggleCheck,
          );
      return () => ref
          .read(workoutKeyboardProvider.notifier)
          .unregisterCheck(exerciseId: exerciseId, setIndex: index);
    }, const []);

    final prevText = prevSet != null
        ? '${_fmt(prevSet!.weightKg)}×${prevSet!.reps ?? 0}'
        : '—';

    return AnimatedContainer(
      key: rowKey,
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isChecked ? AppColors.success.withAlpha(12) : Colors.transparent,
        border: isChecked
            ? const Border(left: BorderSide(color: AppColors.success, width: 2))
            : const Border(
                left: BorderSide(color: Colors.transparent, width: 2),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            // Set number badge
            SizedBox(
              width: _kSetW,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isChecked
                        ? AppColors.success.withAlpha(30)
                        : AppColors.surface600,
                    border: Border.all(
                      color: isChecked
                          ? AppColors.success.withAlpha(180)
                          : AppColors.surface500,
                      width: 1,
                    ),
                    boxShadow: isChecked
                        ? [
                            BoxShadow(
                              color: AppColors.success.withAlpha(50),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.monoSm.copyWith(
                        color: isChecked
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontSize: 10,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Previous value
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

            // KG input — pill shaped
            SizedBox(
              width: _kKgW,
              child: _PillInput(
                controller: weightCtrl,
                focusNode: weightFocus,
                hintText: prevSet?.weightKg != null
                    ? _fmt(prevSet!.weightKg)
                    : '0',
                readOnly: isChecked,
                isChecked: isChecked,
                onChanged: isChecked
                    ? null
                    : (text) => ref
                          .read(workoutDraftsProvider.notifier)
                          .updateWeight(
                            exerciseId,
                            index,
                            double.tryParse(text.replaceAll(',', '.')),
                          ),
                onTap: isChecked
                    ? null
                    : () => ref
                          .read(workoutKeyboardProvider.notifier)
                          .focus(exerciseId, index, WorkoutKeyboardField.kg),
              ),
            ),

            const SizedBox(width: 4),

            // Reps input — pill shaped
            SizedBox(
              width: _kRepsW,
              child: _PillInput(
                controller: repsCtrl,
                focusNode: repsFocus,
                hintText: prevSet?.reps != null ? '${prevSet!.reps}' : '0',
                readOnly: isChecked,
                isChecked: isChecked,
                onChanged: isChecked
                    ? null
                    : (text) => ref
                          .read(workoutDraftsProvider.notifier)
                          .updateReps(exerciseId, index, int.tryParse(text)),
                onTap: isChecked
                    ? null
                    : () => ref
                          .read(workoutKeyboardProvider.notifier)
                          .focus(exerciseId, index, WorkoutKeyboardField.reps),
              ),
            ),

            // Check button with scale animation
            SizedBox(
              width: _kCheckW,
              height: _kCheckW,
              child: GestureDetector(
                onTapDown: (_) => isPressed.value = true,
                onTapUp: (_) => isPressed.value = false,
                onTapCancel: () => isPressed.value = false,
                onTap: isLogging.value
                    ? null
                    : () => unawaited(
                        ref
                            .read(workoutKeyboardProvider.notifier)
                            .callCheck(exerciseId: exerciseId, setIndex: index),
                      ),
                child: AnimatedScale(
                  scale: isPressed.value ? 0.82 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: isChecked
                        ? Container(
                            key: const ValueKey('checked'),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withAlpha(80),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.surface900,
                            ),
                          )
                        : Container(
                            key: const ValueKey('unchecked'),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface500,
                                width: 1.5,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double? v) {
    return formatWorkoutKgNullable(v) ?? '—';
  }
}

// ─── Pill input field ─────────────────────────────────────────────────────────

class _PillInput extends StatelessWidget {
  const _PillInput({
    required this.controller,
    required this.hintText,
    required this.readOnly,
    required this.isChecked,
    this.focusNode,
    this.onChanged,
    this.onTap,
  });

  final TextEditingController controller;
  final String hintText;
  final bool readOnly;
  final bool isChecked;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autocorrect: false,
      enableSuggestions: false,
      textAlign: TextAlign.center,
      readOnly: readOnly,
      showCursor: true,
      // Suppress system keyboard — all input goes through the custom keyboard.
      keyboardType: TextInputType.none,
      style: AppTextStyles.bodyLg.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: isChecked ? AppColors.textSecondary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyLg.copyWith(
          fontSize: 17,
          color: AppColors.textDisabled,
        ),
        filled: true,
        fillColor: isChecked
            ? AppColors.surface700.withAlpha(80)
            : AppColors.surface600,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      onChanged: onChanged,
      onTap: onTap,
    );
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
        color: AppColors.error.withAlpha(200),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
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
