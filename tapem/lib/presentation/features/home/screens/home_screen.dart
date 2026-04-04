import 'dart:async' show Timer, unawaited;
import 'dart:math' show pi, cos, sin;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../router/route_names.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_skeleton.dart';
import '../../auth/providers/profile_provider.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../../domain/entities/streak/streak_info.dart';
import '../../../../core/utils/xp_rules.dart';
import '../../plans/providers/plans_provider.dart';
import '../../progress/providers/xp_provider.dart';
import '../../progress/widgets/session_detail_sheet.dart';
import '../../progress/widgets/training_heatmap.dart';
import '../../workout/providers/workout_provider.dart';
import '../providers/streak_provider.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One-shot stagger controller — plays once on mount.
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 700),
    );
    useEffect(() {
      ctrl.forward();
      return null;
    }, const []);

    // 5 staggered fade+slide animations with 80ms offsets.
    Animation<double> stagger(double start) => CurvedAnimation(
      parent: ctrl,
      curve: Interval(start, (start + 0.35).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );

    final a0 = stagger(0.00);
    final a1 = stagger(0.12);
    final a2 = stagger(0.24);
    final a3 = stagger(0.36);
    final a4 = stagger(0.48);

    Widget animated(Widget child, Animation<double> anim) =>
        FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        backgroundColor: AppColors.surface900,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'TAP',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 3,
                ),
              ),
              TextSpan(
                text: "'EM",
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.neonCyan,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              label: context.l10n.profileNavLabel,
              button: true,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface700,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surface500),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                tooltip: context.l10n.profileNavLabel,
                onPressed: () => context.push(RouteNames.profile),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.neonCyan,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.neonCyan,
        backgroundColor: AppColors.surface800,
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          ref.invalidate(trainingDaysProvider);
          ref.invalidate(streakProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            animated(const _HeroCard(), a0),
            const SizedBox(height: 16),
            animated(const _StatsRow(), a1),
            const SizedBox(height: 20),
            animated(const _WorkoutQuickStart(), a2),
            const SizedBox(height: 20),
            animated(const _CalendarCard(), a3),
            const SizedBox(height: 20),
            animated(const _RecentActivityCard(), a4),
          ],
        ),
      ),
    );
  }
}

// ─── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends ConsumerWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final gymXp = ref.watch(userGymXpProvider);
    final l10n = context.l10n;
    final accent = Theme.of(context).colorScheme.primary;

    final xpData = gymXp.valueOrNull;
    final totalXp = xpData?.totalXp ?? 0;
    final xpToNext = xpData?.xpToNextLevel ?? XpRules.trainingDayXpPerLevel;
    final level = XpRules.levelFromXp(totalXp, XpRules.trainingDayXpPerLevel);
    const xpPerLevel = XpRules.trainingDayXpPerLevel;
    final ringProgress = (totalXp > 0 && !gymXp.isLoading)
        ? (1.0 - xpToNext / xpPerLevel).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface800,
            AppColors.surface900,
            accent.withAlpha(15),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withAlpha(55)),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(28),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Greeting + ring badge side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _timeGreeting(),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // XP level ring badge
              Semantics(
                label: 'Level $level, ${(ringProgress * 100).round()}% zum nächsten Level',
                child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: ringProgress),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => SizedBox(
                  width: 72,
                  height: 72,
                  child: CustomPaint(
                    painter: _XpRingPainter(
                      progress: value,
                      accentColor: accent,
                      trackColor: AppColors.surface600,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LVL',
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 8,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '$level',
                            style: AppTextStyles.monoLg.copyWith(
                              color: accent,
                              fontSize: 20,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ), // Semantics
            ],
          ),
          const SizedBox(height: 8),

          // Full-width username — never clipped
          profile.when(
            data: (p) {
              if (p == null) return const SizedBox.shrink();
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [accent, AppColors.textPrimary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: Text(
                  p.username.toUpperCase(),
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              );
            },
            loading: () => Container(
              height: 32,
              width: 160,
              decoration: BoxDecoration(
                color: AppColors.surface700,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            error: (_, __) =>
                Text(l10n.errorLoadingProfile, style: AppTextStyles.bodyMd),
          ),
        ],
      ),
    );
  }

  static String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'GUTEN MORGEN';
    if (hour >= 12 && hour < 17) return 'GUTEN TAG';
    if (hour >= 17 && hour < 22) return 'GUTEN ABEND';
    return 'GUTE NACHT';
  }
}

// ─── XP ring painter ───────────────────────────────────────────────────────────

class _XpRingPainter extends CustomPainter {
  const _XpRingPainter({
    required this.progress,
    required this.accentColor,
    required this.trackColor,
  });

  final double progress;
  final Color accentColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 7;
    const strokeWidth = 5.5;
    const startAngle = -pi / 2;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * pi,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * pi * progress;

    // Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = accentColor.withAlpha(70)
        ..strokeWidth = strokeWidth + 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = accentColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Tip dot
    if (progress > 0.02) {
      final endAngle = startAngle + sweepAngle;
      final dotX = center.dx + radius * cos(endAngle);
      final dotY = center.dy + radius * sin(endAngle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth / 2 + 1,
        Paint()..color = accentColor,
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth / 2 + 4,
        Paint()
          ..color = accentColor.withAlpha(55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  @override
  bool shouldRepaint(_XpRingPainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentYear = DateTime.now().year;
    final trainingDays = ref.watch(trainingDaysProvider(currentYear));
    final gymXp = ref.watch(userGymXpProvider);
    final streakInfo = ref.watch(streakProvider);

    final days = trainingDays.valueOrNull ?? {};
    final streak = streakInfo.valueOrNull ?? StreakInfo.empty;
    final totalXp = gymXp.valueOrNull?.totalXp;

    final streakColor = streak.isAtRisk
        ? AppColors.neonYellowDim
        : AppColors.neonYellow;

    return Row(
      children: [
        _StatChip(
          value: '${days.length}',
          label: 'TAGE',
          icon: Icons.fitness_center_rounded,
          color: AppColors.neonCyan,
        ),
        const SizedBox(width: 8),
        _StatChip(
          value: streak.isActive ? '${streak.currentStreak}' : '—',
          label: 'STREAK',
          icon: Icons.local_fire_department_rounded,
          color: streakColor,
          subtitle: streak.isAtRisk
              ? streak.expiresImminently
                    ? 'LÄUFT AB!'
                    : 'NOCH ${streak.graceDaysRemaining} T.'
              : null,
          subtitleColor: streak.expiresImminently
              ? AppColors.error
              : AppColors.neonYellowDim,
        ),
        const SizedBox(width: 8),
        _StatChip(
          value: totalXp != null ? _fmtXp(totalXp) : '—',
          label: 'GES. XP',
          icon: Icons.bolt_rounded,
          color: AppColors.neonMagenta,
        ),
      ],
    );
  }

  static String _fmtXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return '$xp';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.subtitle,
    this.subtitleColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  /// Optional warning text shown below [label].  Null = hidden.
  final String? subtitle;

  /// Color for [subtitle] text.  Ignored when [subtitle] is null.
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface800, AppColors.surface900],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color.withAlpha(220)),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.monoSm.copyWith(
                color: color,
                fontSize: 20,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppTextStyles.labelSm.copyWith(
                  color: subtitleColor ?? AppColors.neonYellowDim,
                  fontSize: 8,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Training calendar card ───────────────────────────────────────────────────

class _CalendarCard extends ConsumerStatefulWidget {
  const _CalendarCard();

  @override
  ConsumerState<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends ConsumerState<_CalendarCard> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  void _prevYear() => setState(() => _year--);

  void _nextYear() {
    if (_year < DateTime.now().year) setState(() => _year++);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentYear = DateTime.now().year;
    final trainingDays = ref.watch(trainingDaysProvider(_year));
    final days = trainingDays.valueOrNull ?? {};
    final canGoForward = _year < currentYear;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonCyan.withAlpha(35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withAlpha(15),
            blurRadius: 28,
            offset: const Offset(0, 4),
          ),
          BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 12),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openDialog(context, days),
            splashColor: AppColors.neonCyan.withAlpha(18),
            highlightColor: AppColors.neonCyan.withAlpha(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.trainingCalendar,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMd,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _YearNavButton(
                        icon: Icons.chevron_left_rounded,
                        onPressed: _prevYear,
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '$_year',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.monoSm.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _YearNavButton(
                        icon: Icons.chevron_right_rounded,
                        onPressed: canGoForward ? _nextYear : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  trainingDays.when(
                    data: (d) => TrainingHeatmap(year: _year, trainingDays: d),
                    loading: () => TapemSkeleton.card(height: 56),
                    error: (_, __) => Text(
                      l10n.failedToLoadCalendar,
                      style: AppTextStyles.bodySm,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Spacer(),
                      Icon(
                        Icons.open_in_full_rounded,
                        size: 13,
                        color: AppColors.textDisabled,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDialog(BuildContext context, Set<String> days) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => TrainingHeatmapDialog(year: _year, trainingDays: days),
      ),
    );
  }
}

// ─── Year navigation button ───────────────────────────────────────────────────

class _YearNavButton extends StatelessWidget {
  const _YearNavButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
        ),
      ),
    );
  }
}

// ─── Workout quick-start (adapts to current workout state) ────────────────────

class _WorkoutQuickStart extends ConsumerWidget {
  const _WorkoutQuickStart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutProvider);
    final l10n = context.l10n;

    if (state is WorkoutResuming || state is WorkoutStarting) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neonCyan.withAlpha(40)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.neonCyan,
              ),
            ),
            const SizedBox(width: 12),
            Text(l10n.checkingForSession, style: AppTextStyles.bodySm),
          ],
        ),
      );
    }

    if (state is WorkoutActive) {
      return _ActiveWorkoutCard(session: state.session);
    }

    return _StartWorkoutCard();
  }
}

// ─── Active workout card ──────────────────────────────────────────────────────

class _ActiveWorkoutCard extends HookConsumerWidget {
  const _ActiveWorkoutCard({required this.session});

  final LocalWorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = _useElapsedTimer(session.startedAt);
    final l10n = context.l10n;

    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final elapsedStr = elapsed.inHours > 0 ? '$h:$m:$s' : '$m:$s';

    final startH = session.startedAt.hour.toString().padLeft(2, '0');
    final startM = session.startedAt.minute.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1),
          radius: 1.8,
          colors: [AppColors.neonCyan.withAlpha(22), AppColors.surface800],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonCyan.withAlpha(120)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withAlpha(35),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neonCyan.withAlpha(60)),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.neonCyan,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(l10n.workoutInProgress, style: AppTextStyles.labelLg),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.neonCyan,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            elapsedStr,
            style: AppTextStyles.monoLg.copyWith(
              color: AppColors.neonCyan,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.startedAt('$startH:$startM'),
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCyan.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TapemButton(
              label: l10n.continueWorkout,
              icon: Icons.play_arrow,
              onPressed: () => context.go(RouteNames.activeWorkout),
            ),
          ),
          const SizedBox(height: 10),
          TapemButton(
            label: l10n.discard,
            icon: Icons.delete_forever_outlined,
            variant: TapemButtonVariant.ghost,
            onPressed: () => unawaited(_discard(context, ref)),
          ),
        ],
      ),
    );
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discardWorkoutTitle),
        content: Text(l10n.discardWorkoutContent),
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
    if (confirmed == true) {
      await ref.read(workoutProvider.notifier).discardSession();
    }
  }
}

Duration _useElapsedTimer(DateTime startedAt) {
  final elapsed = useState(DateTime.now().difference(startedAt));
  useEffect(() {
    final timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value = DateTime.now().difference(startedAt);
    });
    return timer.cancel;
  }, const []);
  return elapsed.value;
}

// ─── Start workout card ───────────────────────────────────────────────────────

class _StartWorkoutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonCyan.withAlpha(35)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neonCyan.withAlpha(30)),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.neonCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'SCHNELLSTART',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.neonCyan,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCyan.withAlpha(30),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TapemButton(
              label: l10n.startWorkout,
              icon: Icons.bolt_rounded,
              variant: TapemButtonVariant.outlined,
              onPressed: () => _showStartSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showStartSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const _StartWorkoutSheet(),
      ),
    );
  }
}

// ─── Start-workout bottom sheet ───────────────────────────────────────────────

class _StartWorkoutSheet extends HookConsumerWidget {
  const _StartWorkoutSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStartingFreestyle = useState(false);
    final isStartingPlan = useState(false);
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 20),
          Text(l10n.startWorkout, style: AppTextStyles.h3),
          const SizedBox(height: 20),
          _WorkoutTypeCard(
            icon: Icons.bolt_outlined,
            iconColor: AppColors.neonCyan,
            title: l10n.freestyleTitle,
            description: l10n.freestyleDescription,
            isLoading: isStartingFreestyle.value,
            onTap: () =>
                unawaited(_startFreestyle(context, ref, isStartingFreestyle)),
          ),
          const SizedBox(height: 12),
          _WorkoutTypeCard(
            icon: Icons.list_alt_outlined,
            iconColor: AppColors.neonMagenta,
            title: l10n.fromPlanTitle,
            description: l10n.fromPlanDescription,
            isLoading: isStartingPlan.value,
            onTap: () =>
                unawaited(_startFromPlan(context, ref, isStartingPlan)),
          ),
        ],
      ),
    );
  }

  Future<void> _startFreestyle(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isStarting,
  ) async {
    if (isStarting.value) return;
    isStarting.value = true;

    try {
      await ref
          .read(workoutProvider.notifier)
          .startSession(
            equipmentId: 'freestyle',
            equipmentName: 'Freestyle',
            canonicalExerciseKey: '',
          );
    } finally {
      isStarting.value = false;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();
    context.go(RouteNames.gym);
  }

  Future<void> _startFromPlan(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isStarting,
  ) async {
    if (isStarting.value) return;

    final plans = ref.read(plansProvider).valueOrNull ?? [];

    if (plans.isEmpty) {
      Navigator.of(context).pop();
      unawaited(context.push(RouteNames.plans));
      return;
    }

    if (plans.length == 1) {
      isStarting.value = true;
      try {
        final items = await ref.read(planItemsProvider(plans.first.id).future);
        await ref.read(workoutProvider.notifier).startPlanSession(items);
      } finally {
        isStarting.value = false;
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      context.go(RouteNames.activeWorkout);
      return;
    }

    if (!context.mounted) return;
    final selected = await showModalBottomSheet<LocalWorkoutPlan>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlanPickerSheet(plans: plans),
    );
    if (selected == null || !context.mounted) return;

    isStarting.value = true;
    try {
      final items = await ref.read(planItemsProvider(selected.id).future);
      await ref.read(workoutProvider.notifier).startPlanSession(items);
    } finally {
      isStarting.value = false;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    context.go(RouteNames.activeWorkout);
  }
}

// ─── Plan picker sheet ────────────────────────────────────────────────────────

class _PlanPickerSheet extends StatelessWidget {
  const _PlanPickerSheet({required this.plans});

  final List<LocalWorkoutPlan> plans;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Container(
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
                  Text(l10n.choosePlan, style: AppTextStyles.labelLg),
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
            const Divider(color: AppColors.surface500, height: 20),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                itemCount: plans.length,
                itemBuilder: (_, index) {
                  final plan = plans[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Material(
                        color: AppColors.surface900,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(plan),
                          splashColor: AppColors.neonMagenta.withAlpha(15),
                          highlightColor: AppColors.neonMagenta.withAlpha(8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.neonMagenta.withAlpha(40),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.neonMagenta.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.neonMagenta.withAlpha(
                                        60,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.list_alt_outlined,
                                    color: AppColors.neonMagenta,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    plan.name,
                                    style: AppTextStyles.bodyMd,
                                  ),
                                ),
                                const Icon(
                                  Icons.play_circle_outline,
                                  color: AppColors.neonMagenta,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
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

// ─── Workout type selection card ──────────────────────────────────────────────

class _WorkoutTypeCard extends StatefulWidget {
  const _WorkoutTypeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_WorkoutTypeCard> createState() => _WorkoutTypeCardState();
}

class _WorkoutTypeCardState extends State<_WorkoutTypeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.iconColor.withAlpha(70)),
            boxShadow: [
              BoxShadow(color: widget.iconColor.withAlpha(15), blurRadius: 16),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.iconColor.withAlpha(60)),
                ),
                child: widget.isLoading
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.iconColor,
                          ),
                        ),
                      )
                    : Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTextStyles.labelLg),
                    const SizedBox(height: 2),
                    Text(widget.description, style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: widget.iconColor.withAlpha(160),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent activity card ─────────────────────────────────────────────────────

class _RecentActivityCard extends ConsumerWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(recentSessionsProvider);
    final l10n = context.l10n;

    return sessions.when(
      loading: () => _shell(
        title: l10n.recentSessions,
        child: TapemSkeleton.listTiles(count: 2),
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
            centered: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.fitness_center_outlined,
                      color: AppColors.textDisabled,
                      size: 32,
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
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: AppColors.surface800,
            child: InkWell(
              onTap: () => _showAllSessionsSheet(context, list),
              splashColor: AppColors.neonCyan.withAlpha(15),
              highlightColor: AppColors.neonCyan.withAlpha(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.surface500.withAlpha(160),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 12,
                    ),
                  ],
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

  static Widget _shell({
    required String title,
    required Widget child,
    bool centered = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface500.withAlpha(160)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: AppTextStyles.labelMd,
          ),
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

// ─── Session row content ──────────────────────────────────────────────────────

class _SessionRowContent extends StatelessWidget {
  const _SessionRowContent({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final duration = session.duration;
    // Non-uniform border + borderRadius is not supported by Flutter's Border.
    // Use ClipRRect + a left accent Container instead.
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
                        color: AppColors.surface900,
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
