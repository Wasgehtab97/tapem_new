import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_enums.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/nutrition_providers.dart';

// ─── Nutrition accent palette (distinct from gym neon) ────────────────────────
const _kcalColor = Color(0xFFFF7043);
const _proteinColor = Color(0xFF42A5F5);
const _carbsColor = Color(0xFFFFCA28);
const _fatColor = Color(0xFF66BB6A);

class NutritionHomeScreen extends HookConsumerWidget {
  const NutritionHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final nutritionState = ref.watch(nutritionNotifierProvider);
    final notifier = ref.read(nutritionNotifierProvider.notifier);

    useEffect(() {
      if (user != null) {
        unawaited(Future.microtask(() => notifier.load(user.id)));
      }
      return null;
    }, [user?.id]);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      body: nutritionState.isLoading
          ? const Center(child: CircularProgressIndicator(color: _kcalColor))
          : nutritionState.error != null
              ? _ErrorState(
                  message: nutritionState.error!,
                  onRetry: user != null ? () => notifier.load(user.id) : null,
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: AppColors.surface900.withValues(alpha: 0.85),
                      surfaceTintColor: Colors.transparent,
                      pinned: true,
                      expandedHeight: 120,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text(
                          'ERNÄHRUNG',
                          style: AppTextStyles.h2.copyWith(letterSpacing: 1.2),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.tune_outlined, color: AppColors.textSecondary),
                          onPressed: () => context.push('/nutrition/goals'),
                          tooltip: 'Ziele',
                        ),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(1),
                        child: Container(
                          height: 1,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, _kcalColor, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _HomeBody(state: nutritionState, uid: user?.id ?? ''),
                  ],
                ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state, required this.uid});

  final NutritionDayState state;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final log = state.log;
    final goal = state.goal;
    final consumed = log?.totalKcal ?? 0;
    final target = goal?.kcal ?? 2000;
    final isOver = log?.status == NutritionStatus.over;
    final remaining = isOver ? 0 : (target - consumed);
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // ── Calorie ring card ──────────────────────────────────────────
          _CalorieCard(
            consumed: consumed,
            target: target,
            remaining: remaining,
            progress: progress,
            isOver: isOver,
            protein: log?.totalProtein ?? 0,
            proteinTarget: goal?.protein ?? 150,
            carbs: log?.totalCarbs ?? 0,
            carbsTarget: goal?.carbs ?? 250,
            fat: log?.totalFat ?? 0,
            fatTarget: goal?.fat ?? 67,
          ),
          const Gap(32),

          // ── Log button ─────────────────────────────────────────────────
          _HoverScaleButton(
            onTap: () => context.push('/nutrition/day', extra: {'uid': uid}),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _kcalColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _kcalColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 24, color: Colors.white),
                  const Gap(10),
                  Text(
                    'HEUTE LOGGEN',
                    style: AppTextStyles.buttonLg.copyWith(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          const Gap(24),

          // ── Nav tiles ─────────────────────────────────────────────────
          Text(
            'TOOLS & VERLAUF',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.textDisabled,
              letterSpacing: 1.5,
            ),
          ),
          const Gap(12),
          _NavTile(
            icon: Icons.restaurant_menu_outlined,
            label: 'REZEPTE',
            subtitle: 'Mahlzeiten schneller erfassen',
            accentColor: _kcalColor,
            onTap: () => context.push('/nutrition/recipes', extra: {'uid': uid}),
          ),
          const Gap(12),
          _NavTile(
            icon: Icons.monitor_weight_outlined,
            label: 'GEWICHT TRACKEN',
            subtitle: 'Gewichtsverlauf verfolgen',
            accentColor: _proteinColor,
            onTap: () => context.push('/nutrition/weight'),
          ),
          const Gap(12),
          _NavTile(
            icon: Icons.calendar_month_outlined,
            label: 'JAHRESÜBERSICHT',
            subtitle: 'Kalorienziele im Überblick',
            accentColor: _carbsColor,
            onTap: () => context.push('/nutrition/calendar', extra: {'uid': uid}),
          ),
          const Gap(48),

          // ── Attribution ───────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  'DATENQUELLEN',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
                const Gap(4),
                Text(
                  'Open Food Facts (ODbL) · USDA FoodData Central',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Reusable Scale Button ─────────────────────────────────────────────────────

class _HoverScaleButton extends HookWidget {
  const _HoverScaleButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);

    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) {
        isPressed.value = false;
        onTap();
      },
      onTapCancel: () => isPressed.value = false,
      child: AnimatedScale(
        scale: isPressed.value ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}

// ─── Calorie card with ring ────────────────────────────────────────────────────

class _CalorieCard extends StatelessWidget {
  const _CalorieCard({
    required this.consumed,
    required this.target,
    required this.remaining,
    required this.progress,
    required this.isOver,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
  });

  final int consumed;
  final int target;
  final int remaining;
  final double progress;
  final bool isOver;
  final int protein;
  final int proteinTarget;
  final int carbs;
  final int carbsTarget;
  final int fat;
  final int fatTarget;

  @override
  Widget build(BuildContext context) {
    final accentColor = isOver ? AppColors.error : _kcalColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface800.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.05),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Calorie ring ─────────────────────────────────────────
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, __) => CustomPaint(
                            painter: _RingPainter(
                              progress: value,
                              trackColor: AppColors.surface500,
                              progressColor: accentColor,
                            ),
                            size: const Size(130, 130),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$consumed',
                              style: AppTextStyles.displayMd.copyWith(
                                fontSize: 32,
                                color: accentColor,
                                height: 1.0,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'kcal',
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  
                  // ── Stats column ──────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HEUTE',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Gap(12),
                        _StatLine(
                          label: 'Ziel',
                          value: '$target',
                          unit: 'kcal',
                          color: AppColors.textSecondary,
                        ),
                        const Gap(8),
                        _StatLine(
                          label: 'Verbraucht',
                          value: '$consumed',
                          unit: 'kcal',
                          color: accentColor,
                          bold: true,
                        ),
                        const Gap(8),
                        _StatLine(
                          label: isOver ? 'Über Limit' : 'Verbleibend',
                          value: '${isOver ? consumed - target : remaining}',
                          unit: 'kcal',
                          color: isOver ? AppColors.error : AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(28),
              Container(height: 1, color: AppColors.surface500.withValues(alpha: 0.5)),
              const Gap(24),

              // ── Macro strips ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MacroStrip(
                      label: 'PROTEIN',
                      value: protein,
                      target: proteinTarget,
                      color: _proteinColor,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: _MacroStrip(
                      label: 'KOHLENH.',
                      value: carbs,
                      target: carbsTarget,
                      color: _carbsColor,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: _MacroStrip(
                      label: 'FETT',
                      value: fat,
                      target: fatTarget,
                      color: _fatColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textDisabled),
        ),
        RichText(
          text: TextSpan(
            text: value,
            style: AppTextStyles.labelLg.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroStrip extends StatelessWidget {
  const _MacroStrip({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final int value;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '${value}g',
              style: AppTextStyles.labelMd.copyWith(color: color, fontSize: 11),
            ),
          ],
        ),
        const Gap(6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: p),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutBack,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              backgroundColor: AppColors.surface500.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const Gap(4),
        Text(
          '/ ${target}g',
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.textDisabled,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ─── Ring painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  static const _strokeWidth = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      // Glow effect on the stroke
      ..imageFilter = ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5);

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}

// ─── Nav tile ─────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HoverScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface800.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface500.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.25),
                    accentColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelLg.copyWith(letterSpacing: 0.8)),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textDisabled.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.errorGlow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            ),
            const Gap(16),
            Text(
              message,
              style: AppTextStyles.bodyLg,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const Gap(24),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kcalColor,
                  side: const BorderSide(color: _kcalColor),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('ERNEUT VERSUCHEN', style: AppTextStyles.buttonMd),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
