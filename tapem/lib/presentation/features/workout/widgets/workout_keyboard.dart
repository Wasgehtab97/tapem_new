import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/workout_drafts_provider.dart';
import '../providers/workout_keyboard_provider.dart';
import '../providers/workout_provider.dart';

// ─── Height constant ──────────────────────────────────────────────────────────
//
// Layout breakdown (5dp padding × 2 = 10dp overhead):
//   Header row (field indicator + close)   20dp
//   Gap after header                         4dp
//   4 key rows × 44dp                      176dp
//   3 inter-row gaps × 4dp                  12dp
//   ────────────────────────────────────────────
//   Total inner                             212dp  ✓
//   Total outer (+ 10dp padding)            222dp

const kWorkoutKeyboardBodyHeight = 222.0;

// ─── Root widget ──────────────────────────────────────────────────────────────

class WorkoutKeyboard extends ConsumerWidget {
  const WorkoutKeyboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(workoutKeyboardProvider);
    if (target == null) return const SizedBox.shrink();
    return _KeyboardBody(target: target);
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _KeyboardBody extends ConsumerWidget {
  const _KeyboardBody({required this.target});

  final WorkoutKeyboardTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(workoutKeyboardProvider.notifier);
    final workoutState = ref.watch(workoutProvider);
    final allDrafts = ref.watch(workoutDraftsProvider);
    final isKg = target.field == WorkoutKeyboardField.kg;
    final exerciseDrafts = allDrafts[target.exerciseId] ?? [];
    final activeWorkout =
        workoutState is WorkoutActive ? workoutState : null;

    final numStyle = AppTextStyles.monoLg.copyWith(fontSize: 20);

    return Container(
      height: kWorkoutKeyboardBodyHeight,
      decoration: BoxDecoration(
        color: AppColors.surface800,
        border: Border(
          top: BorderSide(
            color: AppColors.neonCyan.withAlpha(70),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: field indicator + close ──────────────────────────────
          SizedBox(
            height: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _FieldIndicator(isKg: isKg),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    notifier.close();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.keyboard_hide_outlined,
                      size: 17,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Row 1: 1 2 3 | ← → ───────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _KeyBtn(onTap: () => notifier.type('1'), child: Text('1', style: numStyle))),
                const SizedBox(width: 4),
                Expanded(child: _KeyBtn(onTap: () => notifier.type('2'), child: Text('2', style: numStyle))),
                const SizedBox(width: 4),
                Expanded(child: _KeyBtn(onTap: () => notifier.type('3'), child: Text('3', style: numStyle))),
                const SizedBox(width: 4),
                // Nav arrows — split within one column cell
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.chevron_left_rounded,
                          color: AppColors.neonCyan,
                          onTap: activeWorkout != null
                              ? () => unawaited(notifier.navigateLeft(
                                    workoutState: activeWorkout,
                                    allDrafts: allDrafts,
                                  ))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.chevron_right_rounded,
                          color: AppColors.neonCyan,
                          onTap: activeWorkout != null
                              ? () => unawaited(notifier.navigateRight(
                                    workoutState: activeWorkout,
                                    allDrafts: allDrafts,
                                  ))
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Row 2: 4 5 6 | −1 ────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _KeyBtn(onTap: () => notifier.type('4'), child: Text('4', style: numStyle))),
                const SizedBox(width: 4),
                Expanded(child: _KeyBtn(onTap: () => notifier.type('5'), child: Text('5', style: numStyle))),
                const SizedBox(width: 4),
                Expanded(child: _KeyBtn(onTap: () => notifier.type('6'), child: Text('6', style: numStyle))),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionBtn(
                    label: '−1',
                    color: AppColors.textSecondary,
                    onTap: notifier.decrement,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Row 3: 7 8 9 | +1 ────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _KeyBtn(onTap: () => notifier.type('7'), child: Text('7', style: numStyle))),
                const SizedBox(width: 4),
                Expanded(child: _KeyBtn(onTap: () => notifier.type('8'), child: Text('8', style: numStyle))),
                const SizedBox(width: 4),
                Expanded(child: _KeyBtn(onTap: () => notifier.type('9'), child: Text('9', style: numStyle))),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionBtn(
                    label: '+1',
                    color: AppColors.neonCyan,
                    onTap: notifier.increment,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Row 4: , 0 ⌫ | copy↓ ─────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Comma — disabled on reps field (now on the left)
                Expanded(
                  child: _KeyBtn(
                    onTap: isKg ? () => notifier.type(',') : null,
                    dimmed: !isKg,
                    child: Text(
                      ',',
                      style: numStyle.copyWith(
                        fontSize: 22,
                        color: isKg
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // 0 — moved to center
                Expanded(
                  child: _KeyBtn(
                    onTap: () => notifier.type('0'),
                    child: Text('0', style: numStyle),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete
                Expanded(
                  child: _KeyBtn(
                    onTap: notifier.delete,
                    child: const Icon(
                      Icons.backspace_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Copy from previous → auto-advance to next field
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.vertical_align_bottom_rounded,
                    color: AppColors.neonMagenta,
                    onTap: () {
                      notifier.copyFromPrevious(exerciseDrafts);
                      if (activeWorkout != null) {
                        unawaited(notifier.navigateRight(
                          workoutState: activeWorkout,
                          allDrafts: allDrafts,
                        ));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Field indicator strip ────────────────────────────────────────────────────

class _FieldIndicator extends StatelessWidget {
  const _FieldIndicator({required this.isKg});

  final bool isKg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.neonCyan.withAlpha(100),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.neonCyan.withAlpha(12),
      ),
      child: Text(
        isKg ? 'KG' : 'WDHL',
        style: AppTextStyles.monoSm.copyWith(
          color: AppColors.neonCyan,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          height: 1,
        ),
      ),
    );
  }
}

// ─── Numpad key ───────────────────────────────────────────────────────────────

class _KeyBtn extends HookWidget {
  const _KeyBtn({
    required this.onTap,
    required this.child,
    this.dimmed = false,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);

    return GestureDetector(
      onTapDown: (_) {
        if (onTap == null) return;
        pressed.value = true;
        unawaited(HapticFeedback.selectionClick());
      },
      onTapUp: (_) => pressed.value = false,
      onTapCancel: () => pressed.value = false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        decoration: BoxDecoration(
          color: pressed.value
              ? AppColors.surface600
              : AppColors.surface700,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: dimmed
                ? AppColors.surface500.withAlpha(30)
                : AppColors.surface500.withAlpha(90),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

// ─── Action strip button ──────────────────────────────────────────────────────

class _ActionBtn extends HookWidget {
  const _ActionBtn({
    this.icon,
    this.label,
    required this.color,
    required this.onTap,
  }) : assert(icon != null || label != null);

  final IconData? icon;
  final String? label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);

    return GestureDetector(
      onTapDown: (_) {
        if (onTap == null) return;
        pressed.value = true;
        unawaited(HapticFeedback.selectionClick());
      },
      onTapUp: (_) => pressed.value = false,
      onTapCancel: () => pressed.value = false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        decoration: BoxDecoration(
          color: pressed.value
              ? color.withAlpha(28)
              : AppColors.surface700,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap == null
                ? AppColors.surface500.withAlpha(40)
                : color.withAlpha(60),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(
                icon,
                size: 20,
                color: onTap == null ? AppColors.textDisabled : color,
              )
            : Text(
                label!,
                style: AppTextStyles.monoSm.copyWith(
                  color: onTap == null ? AppColors.textDisabled : color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
