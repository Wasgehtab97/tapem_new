import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/database_service.dart';
import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../plans/providers/plans_provider.dart';
import '../providers/xp_provider.dart';

void showSessionDetailSheet(BuildContext context, SessionSummary session) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SessionDetailSheet(session: session),
    ),
  );
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class _SessionDetailSheet extends ConsumerWidget {
  const _SessionDetailSheet({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    final user = ref.watch(currentUserProvider);

    final detailAsync = (gymId != null && user != null)
        ? ref.watch(
            sessionDetailProvider((
              sessionId: session.id,
              gymId: gymId,
              userId: user.id,
            )),
          )
        : const AsyncValue<List<ExerciseWithSets>>.loading();

    final duration = session.duration;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.neonMagenta.withAlpha(40)),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonMagenta.withAlpha(12),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.neonMagenta.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.sessionDayAnchor,
                          style: AppTextStyles.labelLg,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _buildSubtitle(session, duration, context.l10n),
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Create-plan button ───────────────────────────────────
                  if (gymId != null && user != null)
                    IconButton(
                      tooltip: context.l10n.createPlanFromSessionTooltip,
                      icon: const Icon(Icons.playlist_add),
                      color: AppColors.neonCyan,
                      onPressed: () => _showCreatePlanDialog(
                        context,
                        ref,
                        gymId: gymId,
                        userId: user.id,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.neonMagenta.withAlpha(40),
                    AppColors.surface500.withAlpha(180),
                    AppColors.neonMagenta.withAlpha(40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // ── Exercise list ────────────────────────────────────────────────
            Expanded(
              child: detailAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    context.l10n.failedToLoadSessionDetails,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                data: (exercises) => exercises.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.noExercisesRecorded,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: exercises.length,
                        itemBuilder: (context, i) =>
                            _ExerciseBlock(exercise: exercises[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _buildSubtitle(
    SessionSummary session,
    Duration? duration,
    AppLocalizations l10n,
  ) {
    final parts = <String>[
      l10n.exerciseCount(session.exerciseCount),
      l10n.setCount(session.totalSets),
      if (duration != null) _formatDuration(duration),
    ];
    return parts.join('  ·  ');
  }

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  Future<void> _showCreatePlanDialog(
    BuildContext sheetContext,
    WidgetRef ref, {
    required String gymId,
    required String userId,
  }) async {
    final l10n = sheetContext.l10n;

    // Capture messenger before any navigation so we can show a snackbar after
    // the sheet has been popped (context would be invalid otherwise).
    final messenger = ScaffoldMessenger.of(sheetContext);

    // ── Step 1: collect plan name via dialog ──────────────────────────────
    // _PlanNameDialog owns the TextEditingController in its State.dispose(),
    // guaranteeing disposal only after the exit animation fully completes.
    final planName = await showDialog<String>(
      context: sheetContext,
      barrierDismissible: true,
      builder: (_) => _PlanNameDialog(l10n: l10n),
    );

    if (planName == null || planName.isEmpty) return;
    if (!sheetContext.mounted) return;

    // ── Step 2: close sheet synchronously before async work ───────────────
    Navigator.of(sheetContext).pop();

    // ── Step 3: persist plan ──────────────────────────────────────────────
    final db = ref.read(appDatabaseProvider);
    final supabase = ref.read(supabaseClientProvider);

    final planId = await createPlanFromSession(
      db: db,
      supabase: supabase,
      gymId: gymId,
      userId: userId,
      sessionId: session.id,
      planName: planName,
    );

    // ── Step 4: show result (using pre-captured messenger) ────────────────
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          planId != null
              ? l10n.planCreatedFromSessionSuccess(planName)
              : l10n.planCreatedFromSessionFailed,
        ),
      ),
    );
  }
}

// ─── Exercise block ───────────────────────────────────────────────────────────

class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({required this.exercise});

  final ExerciseWithSets exercise;

  @override
  Widget build(BuildContext context) {
    final progressWidget = _progressBadge();

    // Best set for e1RM badge (strength only — cardio yields no e1RM)
    final bestIdx = _bestSetIndex();
    final bestE1rm = bestIdx != null ? _e1rm(exercise.sets[bestIdx]) : null;
    final showE1rmCrown = !exercise.isFirstTime &&
        bestE1rm != null &&
        exercise.previousBestE1rm != null &&
        bestE1rm > exercise.previousBestE1rm!;

    // Total volume (reps × weight_kg, strength sets only)
    final volume = _totalVolume();
    final showVolumeCrown = !exercise.isFirstTime &&
        volume > 0 &&
        exercise.previousBestVolume != null &&
        volume > exercise.previousBestVolume!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row + progress badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(exercise.displayName, style: AppTextStyles.labelMd),
              ),
              if (progressWidget != null) ...[
                const SizedBox(width: 8),
                progressWidget,
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Set rows
          if (exercise.sets.isEmpty)
            Text(
              context.l10n.noSetsLogged,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            ...exercise.sets.asMap().entries.map((entry) {
              final i = entry.key;
              final set = entry.value;
              final isBest = i == bestIdx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isBest
                                ? AppColors.neonCyan.withAlpha(20)
                                : AppColors.surface600,
                            border: Border.all(
                              color: isBest
                                  ? AppColors.neonCyan.withAlpha(120)
                                  : AppColors.surface500,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: AppTextStyles.monoSm.copyWith(
                                color: isBest
                                    ? AppColors.neonCyan
                                    : AppColors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(_formatSet(set), style: AppTextStyles.bodyMd),
                    ),
                    if (isBest && bestE1rm != null)
                      _e1rmBadge(bestE1rm, showE1rmCrown),
                  ],
                ),
              );
            }),
            // Volume summary
            if (volume > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (showVolumeCrown) ...[
                    const Icon(
                      Icons.emoji_events,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'Total: ${_fmtWeight(volume)} kg',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  int? _bestSetIndex() {
    double? best;
    int? bestIdx;
    for (int i = 0; i < exercise.sets.length; i++) {
      final e = _e1rm(exercise.sets[i]);
      if (e != null && (best == null || e > best)) {
        best = e;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  static double? _e1rm(LocalSetEntry set) {
    final reps = set.reps;
    final weight = set.weightKg;
    if (reps == null || weight == null || reps <= 0 || weight <= 0) return null;
    return weight * (1 + reps / 30.0);
  }

  double _totalVolume() {
    return exercise.sets.fold(0.0, (sum, s) {
      final r = s.reps;
      final w = s.weightKg;
      if (r == null || w == null) return sum;
      return sum + r * w;
    });
  }

  static Widget _e1rmBadge(double e1rm, bool showCrown) {
    final e1rmStr = e1rm.toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neonCyan.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.neonCyan.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCrown) ...[
            const Icon(
              Icons.emoji_events,
              size: 10,
              color: AppColors.neonCyan,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            'e1RM: ${e1rmStr}kg',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.neonCyan,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a compact progress badge, or null if there's nothing to show.
  Widget? _progressBadge() {
    if (exercise.sets.isEmpty) return null;

    if (exercise.isFirstTime) {
      return _badge('FIRST SESSION', AppColors.neonCyan);
    }

    final cur = exercise.sets;
    final prev = exercise.previousSets;

    // ── Cardio ──────────────────────────────────────────────────────────────
    final isCardio = cur.any((s) => s.durationSeconds != null);
    if (isCardio) {
      final curBest = cur.fold<int>(
        0,
        (m, s) => (s.durationSeconds ?? 0) > m ? s.durationSeconds! : m,
      );
      final prevBest = prev.fold<int>(
        0,
        (m, s) => (s.durationSeconds ?? 0) > m ? s.durationSeconds! : m,
      );
      if (curBest > prevBest) {
        return _badge('↑ NEW BEST', AppColors.success);
      }
      return null;
    }

    // ── Strength ────────────────────────────────────────────────────────────
    final curMaxW = cur.fold<double>(
      0,
      (m, s) => (s.weightKg ?? 0) > m ? s.weightKg! : m,
    );
    final prevMaxW = prev.fold<double>(
      0,
      (m, s) => (s.weightKg ?? 0) > m ? s.weightKg! : m,
    );
    final curMaxR = cur.fold<int>(0, (m, s) => (s.reps ?? 0) > m ? s.reps! : m);
    final prevMaxR = prev.fold<int>(
      0,
      (m, s) => (s.reps ?? 0) > m ? s.reps! : m,
    );

    if (curMaxW > prevMaxW) {
      final wStr = _fmtWeight(curMaxW);
      return _badge('↑ ${wStr}kg PR', AppColors.success);
    }
    if (curMaxW == prevMaxW && curMaxR > prevMaxR) {
      return _badge('↑ $curMaxR REPS PR', AppColors.success);
    }
    if (cur.length > prev.length) {
      final diff = cur.length - prev.length;
      return _badge('↑ +$diff SET${diff > 1 ? 'S' : ''}', AppColors.neonCyan);
    }

    return null; // Same or worse — nothing shown
  }

  static Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(30), color.withAlpha(12)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100)),
        boxShadow: [
          BoxShadow(color: color.withAlpha(25), blurRadius: 8),
        ],
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static String _fmtWeight(double w) =>
      w == w.truncateToDouble() ? w.toInt().toString() : w.toString();

  static String _formatSet(LocalSetEntry set) {
    if (set.durationSeconds != null) {
      final dur = Duration(seconds: set.durationSeconds!);
      final timeStr = dur.inMinutes > 0
          ? '${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}'
          : '${dur.inSeconds}s';
      return set.distanceMeters != null
          ? '$timeStr  ·  ${set.distanceMeters}m'
          : timeStr;
    }
    final reps = set.reps;
    final weight = set.weightKg;
    if (weight != null && reps != null) {
      return '$reps × ${_fmtWeight(weight)}kg';
    }
    if (reps != null) return '$reps reps';
    if (weight != null) return '${_fmtWeight(weight)}kg';
    return '—';
  }
}

// ─── Plan-name dialog ─────────────────────────────────────────────────────────
//
// Owns the TextEditingController in State so that dispose() is called only
// after the dialog's exit animation fully completes — not when showDialog()'s
// Future resolves (which happens the moment Navigator.pop() is called, while
// the animation is still running).

class _PlanNameDialog extends StatefulWidget {
  const _PlanNameDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_PlanNameDialog> createState() => _PlanNameDialogState();
}

class _PlanNameDialogState extends State<_PlanNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface800,
      title: Text(
        widget.l10n.createPlanFromSessionTitle,
        style: AppTextStyles.labelMd,
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(
          hintText: widget.l10n.planNameHintCreateFromSession,
          hintStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            widget.l10n.cancel,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.l10n.createPlanBtn,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.neonCyan),
          ),
        ),
      ],
    );
  }
}
