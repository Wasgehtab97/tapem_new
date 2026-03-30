import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/community_provider.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _hexColor(String hex) {
  final code = hex.replaceFirst('#', '').padLeft(6, '0');
  final value = int.tryParse('FF$code', radix: 16);
  return value != null ? Color(value) : AppColors.surface800;
}

(Color accent, Color glow) _categoryColors(String category) =>
    switch (category) {
      'supplements' => (AppColors.neonCyan, AppColors.neonCyanGlow),
      'clothing'    => (AppColors.neonMagenta, AppColors.neonMagentaGlow),
      'food'        => (AppColors.success, AppColors.successGlow),
      'equipment'   => (AppColors.neonYellow, AppColors.neonYellowGlow),
      _             => (AppColors.textSecondary, AppColors.surface500),
    };

String _categoryLabel(String category, AppLocalizations l10n) =>
    switch (category) {
      'supplements' => l10n.dealsCategorySupplements,
      'clothing'    => l10n.dealsCategoryClothing,
      'food'        => l10n.dealsCategoryFood,
      'equipment'   => l10n.dealsCategoryEquipment,
      _             => l10n.dealsCategoryWellness,
    };

// ─── DealsTab (entry point) ───────────────────────────────────────────────────

class DealsTab extends ConsumerWidget {
  const DealsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(gymDealsProvider);
    return dealsAsync.when(
      loading: () => const _DealsLoading(),
      error: (_, __) => const _DealsError(),
      data: (deals) {
        if (deals.isEmpty) return const _DealsEmpty();
        return _DealsCarousel(deals: deals);
      },
    );
  }
}

// ─── Carousel (infinite circular PageView) ────────────────────────────────────

class _DealsCarousel extends StatefulWidget {
  const _DealsCarousel({required this.deals});
  final List<GymDeal> deals;

  @override
  State<_DealsCarousel> createState() => _DealsCarouselState();
}

class _DealsCarouselState extends State<_DealsCarousel> {
  // Large multiplier so user can swipe in both directions indefinitely.
  static const _kMultiplier = 1000;

  late final PageController _ctrl;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.deals.length * _kMultiplier;
    _ctrl = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _currentIndex => _page % widget.deals.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _ctrl,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, index) {
              final deal = widget.deals[index % widget.deals.length];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _SwipeCardContent(deal: deal, key: ValueKey(index % widget.deals.length)),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _DotIndicators(count: widget.deals.length, current: _currentIndex),
        ),
      ],
    );
  }
}

// ─── Dot indicators ───────────────────────────────────────────────────────────

class _DotIndicators extends StatelessWidget {
  const _DotIndicators({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current % count;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.neonCyan : AppColors.surface500,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Full-height swipeable card ───────────────────────────────────────────────

class _SwipeCardContent extends StatefulWidget {
  const _SwipeCardContent({required this.deal, super.key});
  final GymDeal deal;

  @override
  State<_SwipeCardContent> createState() => _SwipeCardContentState();
}

class _SwipeCardContentState extends State<_SwipeCardContent> {
  bool _codeCopied = false;

  Future<void> _copyCode() async {
    final code = widget.deal.discountCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _codeCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _codeCopied = false);
  }

  Future<void> _openLink() async {
    final uri = Uri.tryParse(widget.deal.affiliateUrl);
    if (uri == null) return;
    unawaited(HapticFeedback.lightImpact());
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    final (accent, glow) = _categoryColors(deal.category);
    final l10n = context.l10n;
    final categoryLabel = _categoryLabel(deal.category, l10n);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withAlpha(70), width: 1),
        boxShadow: [
          BoxShadow(color: glow, blurRadius: 28, spreadRadius: 2),
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Banner (top ~45%) ────────────────────────────────────────────
            Expanded(
              flex: 45,
              child: _CardBanner(
                deal: deal,
                accent: accent,
                categoryLabel: categoryLabel,
              ),
            ),
            // ── Content (bottom ~55%) ────────────────────────────────────────
            Expanded(
              flex: 55,
              child: _CardBody(
                deal: deal,
                accent: accent,
                codeCopied: _codeCopied,
                onCopy: _copyCode,
                onShop: _openLink,
                l10n: l10n,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card banner ──────────────────────────────────────────────────────────────

class _CardBanner extends StatelessWidget {
  const _CardBanner({
    required this.deal,
    required this.accent,
    required this.categoryLabel,
  });

  final GymDeal deal;
  final Color accent;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final gradStart = _hexColor(deal.bannerGradientStart);
    final gradEnd = _hexColor(deal.bannerGradientEnd);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradStart, gradEnd],
        ),
      ),
      child: Stack(
        children: [
          // Diagonal texture
          Positioned.fill(
            child: CustomPaint(
              painter: _DiagonalLinePainter(color: accent),
            ),
          ),
          // Large glow orb top-right
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withAlpha(40), Colors.transparent],
                ),
              ),
            ),
          ),
          // Second glow orb bottom-left
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withAlpha(20), Colors.transparent],
                ),
              ),
            ),
          ),
          // Brand initial letter (large background watermark)
          Positioned(
            right: 20,
            bottom: -10,
            child: Text(
              deal.brandName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 160,
                fontWeight: FontWeight.w900,
                color: accent.withAlpha(18),
                height: 1,
              ),
            ),
          ),
          // Category badge + brand name (bottom-left)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _CategoryBadge(label: categoryLabel, accent: accent),
                const SizedBox(height: 10),
                Text(
                  deal.brandName,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 32,
                    color: AppColors.textPrimary,
                    shadows: [
                      Shadow(color: accent.withAlpha(100), blurRadius: 16),
                    ],
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

// ─── Card body ────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.deal,
    required this.accent,
    required this.codeCopied,
    required this.onCopy,
    required this.onShop,
    required this.l10n,
  });

  final GymDeal deal;
  final Color accent;
  final bool codeCopied;
  final VoidCallback onCopy;
  final VoidCallback onShop;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface800,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              deal.tagline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLg.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          if (deal.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                deal.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textDisabled,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const Spacer(),
          Container(height: 1, color: AppColors.surface500.withAlpha(100)),
          const SizedBox(height: 18),
          if (deal.discountCode != null) ...[
            _DiscountCodeRow(
              code: deal.discountCode!,
              label: deal.discountLabel,
              accent: accent,
              copied: codeCopied,
              onCopy: onCopy,
              l10n: l10n,
            ),
            const SizedBox(height: 16),
          ],
          _CtaButton(accent: accent, onTap: onShop, l10n: l10n),
        ],
      ),
    );
  }
}

// ─── Category badge ───────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withAlpha(100), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: accent,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

// ─── Diagonal line texture painter ────────────────────────────────────────────

class _DiagonalLinePainter extends CustomPainter {
  const _DiagonalLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(10)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 32.0;
    for (double x = spacing; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(0, x), paint);
    }
  }

  @override
  bool shouldRepaint(_DiagonalLinePainter old) => old.color != color;
}

// ─── Discount code row ────────────────────────────────────────────────────────

class _DiscountCodeRow extends StatelessWidget {
  const _DiscountCodeRow({
    required this.code,
    required this.label,
    required this.accent,
    required this.copied,
    required this.onCopy,
    required this.l10n,
  });

  final String code;
  final String? label;
  final Color accent;
  final bool copied;
  final VoidCallback onCopy;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelSm.copyWith(
              color: accent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: onCopy,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: copied ? accent.withAlpha(30) : AppColors.surface700,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: copied ? accent : AppColors.surface500,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: AppTextStyles.monoMd.copyWith(
                      color: copied ? accent : AppColors.textPrimary,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    copied ? Icons.check_rounded : Icons.copy_rounded,
                    key: ValueKey(copied),
                    color: copied ? accent : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (copied) ...[
          const SizedBox(height: 6),
          Text(
            l10n.dealsCopied,
            style: AppTextStyles.bodySm.copyWith(color: accent),
          ),
        ],
      ],
    );
  }
}

// ─── CTA button ───────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.accent,
    required this.onTap,
    required this.l10n,
  });

  final Color accent;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.textOnAction,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonMd,
        ),
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: Text(l10n.dealsShopNow),
      ),
    );
  }
}

// ─── Loading shimmer ──────────────────────────────────────────────────────────

class _DealsLoading extends StatelessWidget {
  const _DealsLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      child: Shimmer.fromColors(
        baseColor: AppColors.surface800,
        highlightColor: AppColors.surface700,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _DealsEmpty extends StatelessWidget {
  const _DealsEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.dealsNoDeals,
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dealsNoDealsSubtitle,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _DealsError extends StatelessWidget {
  const _DealsError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Deals konnten nicht geladen werden.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
