import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';

/// Cyberpunk shimmer skeleton for loading states.
///
/// Usage:
///   TapemSkeleton.card(height: 80)
///   TapemSkeleton.text(width: 120)
///   TapemSkeleton.circle(size: 48)
///   TapemSkeleton.listTile()
class TapemSkeleton extends StatelessWidget {
  const TapemSkeleton._({required this.child});

  final Widget child;

  // ─── Named constructors ───────────────────────────────────────────────────

  factory TapemSkeleton.card({
    double? height,
    double? width,
    double radius = 16,
  }) => TapemSkeleton._(
    child: _SkeletonBox(
      height: height,
      width: width,
      borderRadius: BorderRadius.circular(radius),
    ),
  );

  factory TapemSkeleton.text({double? width, double height = 14}) =>
      TapemSkeleton._(
        child: _SkeletonBox(
          height: height,
          width: width,
          borderRadius: BorderRadius.circular(4),
        ),
      );

  factory TapemSkeleton.circle({double size = 48}) => TapemSkeleton._(
    child: _SkeletonBox(
      height: size,
      width: size,
      borderRadius: BorderRadius.circular(size / 2),
    ),
  );

  /// A full list-tile-style skeleton row (avatar + two text lines).
  factory TapemSkeleton.listTile() => const TapemSkeleton._(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SkeletonBox(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(
                  height: 13,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: _SkeletonBox(
                    height: 11,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  /// Stacked list of [count] list-tile skeletons.
  static Widget listTiles({int count = 3}) => Column(
    children: List.generate(count, (_) => TapemSkeleton.listTile()),
  );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface700,
      highlightColor: AppColors.surface600,
      child: child,
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: borderRadius,
      ),
    );
  }
}
