import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../floor_plan/providers/floor_plan_provider.dart';
import '../../workout/widgets/equipment_detail_sheet.dart';

/// Read-only gymgoer map view.
///
/// Displays the gym floor plan with coloured dots for each positioned piece
/// of equipment.  Tapping a dot opens the [EquipmentDetailSheet] — the same
/// sheet shown on NFC scan and long-press in the list view.
///
/// Renders an empty state if no floor plan has been uploaded yet.
class GymMapView extends HookConsumerWidget {
  const GymMapView({
    super.key,
    required this.gymId,
    required this.equipment,
  });

  final String gymId;

  /// All active equipment for the gym (already loaded by the parent screen).
  final List<GymEquipment> equipment;

  static const double _kDotRadius = 11.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floorPlanAsync = ref.watch(gymFloorPlanProvider(gymId));
    final transformCtrl = useTransformationController();

    return floorPlanAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _ErrorState(),
      data: (floorPlan) {
        if (floorPlan == null) return _EmptyState();

        final positioned = equipment.where((e) => e.isPositioned).toList();

        return InteractiveViewer(
          transformationController: transformCtrl,
          minScale: 0.5,
          maxScale: 8.0,
          constrained: false,
          child: AspectRatio(
            aspectRatio: floorPlan.aspectRatio,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Floor plan image ──────────────────────────────────
                    Positioned.fill(
                      child: _FloorPlanImage(url: floorPlan.imageUrl),
                    ),

                    // ── Equipment dots ──────────────────────────────────────
                    for (final eq in positioned)
                      _EquipmentDot(
                        equipment: eq,
                        gymId: gymId,
                        canvasSize: Size(w, h),
                        dotRadius: _kDotRadius,
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FloorPlanImage extends StatelessWidget {
  const _FloorPlanImage({required this.url});

  final String url;

  bool get _isSvg => url.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      return SvgPicture.network(
        url,
        fit: BoxFit.fill,
        placeholderBuilder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.fill,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (_, __, ___) => Center(
        child: Text(
          'Bild konnte nicht geladen werden',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Dot ─────────────────────────────────────────────────────────────────────

class _EquipmentDot extends StatelessWidget {
  const _EquipmentDot({
    required this.equipment,
    required this.gymId,
    required this.canvasSize,
    required this.dotRadius,
  });

  final GymEquipment equipment;
  final String gymId;
  final Size canvasSize;
  final double dotRadius;

  @override
  Widget build(BuildContext context) {
    final posX = equipment.posX!;
    final posY = equipment.posY!;

    final left = posX * canvasSize.width - dotRadius;
    final top = posY * canvasSize.height - dotRadius;

    final color = switch (equipment.equipmentType) {
      EquipmentType.fixedMachine => AppColors.neonCyan,
      EquipmentType.openStation => AppColors.neonMagenta,
      EquipmentType.cardio => AppColors.neonYellow,
    };

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showEquipmentDetailSheet(context, equipment, gymId),
        child: SizedBox(
          width: dotRadius * 2,
          height: dotRadius * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withAlpha(220),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(120),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.map_outlined,
            size: 56,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 12),
          Text(
            'Kein Grundriss verfügbar',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Der Gym-Admin muss zunächst\neinen Grundriss hochladen.',
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

class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Grundriss konnte nicht geladen werden',
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
