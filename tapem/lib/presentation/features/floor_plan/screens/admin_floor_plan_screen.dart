import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../features/workout/providers/equipment_provider.dart';
import '../providers/floor_plan_provider.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Admin editor for the gym floor plan.
///
/// Flow:
///   1. If no floor plan exists → empty state with upload button.
///   2. After upload (or if one exists) → canvas with [InteractiveViewer].
///   3. Bottom panel lists equipment split into two tabs:
///      "Ohne Position" (unplaced) and "Platziert" (placed).
///   4. Selecting equipment from "Ohne Position" shows a placement banner;
///      tapping the canvas places the dot.
///   5. Tapping a positioned dot arms "move mode"; the next tap on the map
///      saves the new position. Dragging remains available for fine tuning.
class AdminFloorPlanScreen extends HookConsumerWidget {
  const AdminFloorPlanScreen({super.key});

  static const double _kBottomPanelHeight = 260.0;
  static const double _kDotVisualRadius = 5.0;
  static const double _kDotHitDiameter = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) {
      return const Scaffold(
        body: Center(child: Text('Kein aktives Gym')),
      );
    }

    final floorPlanAsync = ref.watch(gymFloorPlanProvider(gymId));
    final equipmentAsync = ref.watch(gymEquipmentProvider(gymId));

    // ── Local editor state ────────────────────────────────────────────────
    final transformCtrl = useTransformationController();
    // Equipment selected for placement (tap on canvas to place).
    final selectedForPlacement = useState<GymEquipment?>(null);
    // Equipment selected for tap-to-move repositioning.
    final selectedForMove = useState<GymEquipment?>(null);
    // Local (pre-save) overrides while a dot is being dragged.
    final pendingPositions = useState<Map<String, Offset>>({});
    // Disables InteractiveViewer pan/scale while a dot drag is in progress.
    final isDraggingDot = useState(false);
    // Tracks async upload / save state for the loading overlay.
    final isBusy = useState(false);
    // Tab controller for the bottom panel.
    final tabController = useTabController(initialLength: 2);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        backgroundColor: AppColors.surface900,
        title: Text(
          'GRUNDRISS',
          style: AppTextStyles.h2.copyWith(color: AppColors.neonCyan),
        ),
        actions: [
          floorPlanAsync.maybeWhen(
            data: (_) => _UploadButton(
              gymId: gymId,
              isBusy: isBusy,
              onUploaded: () {
                pendingPositions.value = {};
                selectedForPlacement.value = null;
                selectedForMove.value = null;
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: equipmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Fehler beim Laden der Geräte',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        data: (equipment) => floorPlanAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Fehler beim Laden des Grundrisses',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          data: (floorPlan) {
            if (floorPlan == null) {
              return _EmptyFloorPlanState(gymId: gymId, isBusy: isBusy);
            }

            final unpositioned =
                equipment.where((e) => !e.isPositioned).toList()
                  ..sort((a, b) => a.displayName.compareTo(b.displayName));
            final positioned =
                equipment.where((e) => e.isPositioned).toList()
                  ..sort((a, b) => a.displayName.compareTo(b.displayName));

            return Stack(
              children: [
                Column(
                  children: [
                    // ── Canvas ──────────────────────────────────────────
                    Expanded(
                      child: _FloorPlanCanvas(
                        floorPlan: floorPlan,
                        equipment: equipment,
                        gymId: gymId,
                        transformCtrl: transformCtrl,
                        selectedForPlacement: selectedForPlacement,
                        selectedForMove: selectedForMove,
                        pendingPositions: pendingPositions,
                        isDraggingDot: isDraggingDot,
                        isBusy: isBusy,
                        visualRadius: _kDotVisualRadius,
                        hitDiameter: _kDotHitDiameter,
                      ),
                    ),

                    // ── Placement banner or bottom panel ─────────────────
                    if (selectedForPlacement.value != null ||
                        selectedForMove.value != null)
                      _MapActionBanner(
                        equipment:
                            selectedForPlacement.value ?? selectedForMove.value!,
                        isMoveMode: selectedForMove.value != null,
                        onCancel: () {
                          selectedForPlacement.value = null;
                          selectedForMove.value = null;
                        },
                      )
                    else
                      _BottomPanel(
                        tabController: tabController,
                        unpositioned: unpositioned,
                        positioned: positioned,
                        onSelectForPlacement: (e) {
                          selectedForPlacement.value = e;
                          selectedForMove.value = null;
                        },
                        onClearPosition: (e) => _clearPosition(
                          context,
                          ref,
                          gymId,
                          e,
                          isBusy,
                        ),
                        panelHeight: _kBottomPanelHeight,
                      ),
                  ],
                ),

                // Busy overlay
                if (isBusy.value)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Future<void> _clearPosition(
    BuildContext context,
    WidgetRef ref,
    String gymId,
    GymEquipment equipment,
    ValueNotifier<bool> isBusy,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface800,
        title: const Text('Position entfernen'),
        content: Text(
          'Position von "${equipment.displayName}" vom Grundriss entfernen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Entfernen',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    isBusy.value = true;
    try {
      await ref
          .read(floorPlanServiceProvider)
          .clearEquipmentPosition(gymId, equipment.id);
    } catch (e, st) {
      AppLogger.e('[floor_plan] clear position error', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position konnte nicht entfernt werden')),
        );
      }
    } finally {
      isBusy.value = false;
    }
  }
}

// ─── Upload button ────────────────────────────────────────────────────────────

class _UploadButton extends ConsumerWidget {
  const _UploadButton({
    required this.gymId,
    required this.isBusy,
    required this.onUploaded,
  });

  final String gymId;
  final ValueNotifier<bool> isBusy;
  final VoidCallback onUploaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Grundriss-Bild ersetzen',
      icon: const Icon(Icons.upload_outlined, color: AppColors.neonCyan),
      onPressed: isBusy.value ? null : () => _upload(context, ref),
    );
  }

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    isBusy.value = true;
    try {
      final result = await ref
          .read(floorPlanServiceProvider)
          .uploadFloorPlan(gymId);
      if (result != null && context.mounted) {
        onUploaded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grundriss erfolgreich hochgeladen')),
        );
      }
    } catch (e, st) {
      AppLogger.e('[floor_plan] upload error', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload fehlgeschlagen')),
        );
      }
    } finally {
      isBusy.value = false;
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyFloorPlanState extends ConsumerWidget {
  const _EmptyFloorPlanState({required this.gymId, required this.isBusy});

  final String gymId;
  final ValueNotifier<bool> isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.map_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'Kein Grundriss vorhanden',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Lade ein Bild des Hallenlayouts hoch,\num Geräte zu positionieren.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: isBusy.value ? null : () => _upload(context, ref),
            icon: const Icon(Icons.upload_outlined),
            label: const Text('Grundriss hochladen'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.neonCyan,
              foregroundColor: AppColors.textOnAction,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    isBusy.value = true;
    try {
      final result = await ref
          .read(floorPlanServiceProvider)
          .uploadFloorPlan(gymId);
      if (result == null && context.mounted) return; // user cancelled
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grundriss erfolgreich hochgeladen')),
        );
      }
    } catch (e, st) {
      AppLogger.e('[floor_plan] upload error', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload fehlgeschlagen')),
        );
      }
    } finally {
      isBusy.value = false;
    }
  }
}

// ─── Canvas ───────────────────────────────────────────────────────────────────

class _FloorPlanCanvas extends HookConsumerWidget {
  const _FloorPlanCanvas({
    required this.floorPlan,
    required this.equipment,
    required this.gymId,
    required this.transformCtrl,
    required this.selectedForPlacement,
    required this.selectedForMove,
    required this.pendingPositions,
    required this.isDraggingDot,
    required this.isBusy,
    required this.visualRadius,
    required this.hitDiameter,
  });

  final GymFloorPlan floorPlan;
  final List<GymEquipment> equipment;
  final String gymId;
  final TransformationController transformCtrl;
  final ValueNotifier<GymEquipment?> selectedForPlacement;
  final ValueNotifier<GymEquipment?> selectedForMove;
  final ValueNotifier<Map<String, Offset>> pendingPositions;
  final ValueNotifier<bool> isDraggingDot;
  final ValueNotifier<bool> isBusy;
  final double visualRadius;
  final double hitDiameter;
  static const double _kSnapThreshold = 0.015;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positioned = equipment.where((e) => e.isPositioned).toList();

    return ExcludeSemantics(
      child: InteractiveViewer(
        transformationController: transformCtrl,
        panEnabled: !isDraggingDot.value,
        scaleEnabled: !isDraggingDot.value,
        minScale: 0.35,
        maxScale: 16.0,
        boundaryMargin: const EdgeInsets.all(240),
        clipBehavior: Clip.hardEdge,
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

                  // ── Tap handler (place/move selected equipment) ───────
                  if (selectedForPlacement.value != null ||
                      selectedForMove.value != null)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: (details) => _commitCanvasTap(
                          context,
                          ref,
                          details.localPosition,
                          Size(w, h),
                        ),
                      ),
                    ),

                  // ── Equipment dots ────────────────────────────────────
                  for (final eq in positioned)
                    _buildDot(context, ref, eq, Size(w, h)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDot(
    BuildContext context,
    WidgetRef ref,
    GymEquipment equipment,
    Size canvasSize,
  ) {
    // Prefer any locally-pending (dragged) position, fall back to persisted.
    final pending = pendingPositions.value[equipment.id];
    final posX = pending?.dx ?? equipment.posX!;
    final posY = pending?.dy ?? equipment.posY!;

    final left = posX * canvasSize.width - hitDiameter / 2;
    final top = posY * canvasSize.height - hitDiameter / 2;

    final color = switch (equipment.equipmentType) {
      EquipmentType.fixedMachine => AppColors.neonCyan,
      EquipmentType.openStation => AppColors.neonMagenta,
      EquipmentType.cardio => AppColors.neonYellow,
    };
    final isSelected = selectedForMove.value?.id == equipment.id;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          selectedForPlacement.value = null;
          selectedForMove.value =
              isSelected ? null : equipment;
        },
        onLongPress: () => _onDotLongPress(context, ref, equipment),
        onPanStart: (_) {
          isDraggingDot.value = true;
          selectedForPlacement.value = null;
          selectedForMove.value = equipment;
          // Seed pending position from persisted value.
          pendingPositions.value = {
            ...pendingPositions.value,
            equipment.id: Offset(posX, posY),
          };
        },
        onPanUpdate: (details) {
          final scale = transformCtrl.value.getMaxScaleOnAxis();
          final dx = details.delta.dx / scale / canvasSize.width;
          final dy = details.delta.dy / scale / canvasSize.height;
          final current =
              pendingPositions.value[equipment.id] ?? Offset(posX, posY);
          final unsnapped = Offset(
            (current.dx + dx).clamp(0.0, 1.0).toDouble(),
            (current.dy + dy).clamp(0.0, 1.0).toDouble(),
          );
          final snapped = _snapToNearbyAxes(
            unsnapped,
            movingEquipmentId: equipment.id,
          );
          pendingPositions.value = {
            ...pendingPositions.value,
            equipment.id: snapped,
          };
        },
        onPanEnd: (_) {
          isDraggingDot.value = false;
          selectedForMove.value = null;
          final newPos = pendingPositions.value[equipment.id];
          if (newPos != null) {
            unawaited(
              _savePosition(context, ref, equipment, newPos),
            );
          }
        },
        child: SizedBox(
          width: hitDiameter,
          height: hitDiameter,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withAlpha(230),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.neonCyan : Colors.white,
                  width: isSelected ? 1.8 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? AppColors.neonCyan : color).withAlpha(
                      isSelected ? 130 : 90,
                    ),
                    blurRadius: isSelected ? 7 : 3,
                    spreadRadius: isSelected ? 1.4 : 0.5,
                  ),
                ],
              ),
              child: SizedBox(
                width: visualRadius * 2,
                height: visualRadius * 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _commitCanvasTap(
    BuildContext context,
    WidgetRef ref,
    Offset localPos,
    Size canvasSize,
  ) async {
    final eq = selectedForMove.value ?? selectedForPlacement.value;
    if (eq == null) return;

    final rawPos = Offset(
      (localPos.dx / canvasSize.width).clamp(0.0, 1.0).toDouble(),
      (localPos.dy / canvasSize.height).clamp(0.0, 1.0).toDouble(),
    );
    final snapped = _snapToNearbyAxes(rawPos, movingEquipmentId: eq.id);

    selectedForPlacement.value = null;
    selectedForMove.value = null;
    isBusy.value = true;
    try {
      await ref
          .read(floorPlanServiceProvider)
          .saveEquipmentPosition(gymId, eq.id, snapped.dx, snapped.dy);
    } catch (e, st) {
      AppLogger.e('[floor_plan] place equipment error', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position konnte nicht gespeichert werden'),
          ),
        );
      }
    } finally {
      isBusy.value = false;
    }
  }

  Offset _snapToNearbyAxes(
    Offset candidate, {
    required String movingEquipmentId,
  }) {
    double snappedX = candidate.dx;
    double snappedY = candidate.dy;
    var bestXDistance = _kSnapThreshold;
    var bestYDistance = _kSnapThreshold;

    for (final eq in equipment) {
      if (eq.id == movingEquipmentId) continue;

      final other = pendingPositions.value[eq.id];
      final otherX = other?.dx ?? eq.posX;
      final otherY = other?.dy ?? eq.posY;
      if (otherX == null || otherY == null) continue;

      final xDistance = (candidate.dx - otherX).abs();
      if (xDistance < bestXDistance) {
        snappedX = otherX;
        bestXDistance = xDistance;
      }

      final yDistance = (candidate.dy - otherY).abs();
      if (yDistance < bestYDistance) {
        snappedY = otherY;
        bestYDistance = yDistance;
      }
    }

    return Offset(snappedX, snappedY);
  }

  Future<void> _savePosition(
    BuildContext context,
    WidgetRef ref,
    GymEquipment equipment,
    Offset newPos,
  ) async {
    isBusy.value = true;
    try {
      await ref
          .read(floorPlanServiceProvider)
          .saveEquipmentPosition(gymId, equipment.id, newPos.dx, newPos.dy);
      // Remove from pending once persisted.
      pendingPositions.value = Map.of(pendingPositions.value)
        ..remove(equipment.id);
    } catch (e, st) {
      AppLogger.e('[floor_plan] save position error', e, st);
      // Revert to persisted position.
      pendingPositions.value = Map.of(pendingPositions.value)
        ..remove(equipment.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position konnte nicht gespeichert werden'),
          ),
        );
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> _onDotLongPress(
    BuildContext context,
    WidgetRef ref,
    GymEquipment equipment,
  ) async {
    final choice = await showModalBottomSheet<_DotAction>(
      context: context,
      backgroundColor: AppColors.surface800,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.open_with,
                color: AppColors.neonCyan,
              ),
              title: Text(
                'Verschieben',
                style: AppTextStyles.labelLg.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Dot auf der Karte ziehen',
                style: AppTextStyles.bodySm,
              ),
              onTap: () => Navigator.pop(ctx, _DotAction.move),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                'Position entfernen',
                style: AppTextStyles.labelLg.copyWith(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(ctx, _DotAction.delete),
            ),
          ],
        ),
      ),
    );

    if (choice == _DotAction.delete && context.mounted) {
      await AdminFloorPlanScreen._clearPosition(
        context,
        ref,
        gymId,
        equipment,
        isBusy,
      );
    }
    if (choice == _DotAction.move) {
      selectedForPlacement.value = null;
      selectedForMove.value = equipment;
    }
  }
}

class _FloorPlanImage extends StatelessWidget {
  const _FloorPlanImage({required this.url});

  final String url;

  bool get _isSvg => url.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      return ExcludeSemantics(
        child: SvgPicture.network(
          url,
          fit: BoxFit.fill,
          placeholderBuilder: (_) => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: Image.network(
        url,
        fit: BoxFit.fill,
        excludeFromSemantics: true,
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
      ),
    );
  }
}

enum _DotAction { move, delete }

// ─── Placement banner ─────────────────────────────────────────────────────────

class _MapActionBanner extends StatelessWidget {
  const _MapActionBanner({
    required this.equipment,
    required this.isMoveMode,
    required this.onCancel,
  });

  final GymEquipment equipment;
  final bool isMoveMode;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.neonCyan.withAlpha(20),
      child: Row(
        children: [
          Icon(
            isMoveMode ? Icons.open_with : Icons.touch_app,
            color: AppColors.neonCyan,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMoveMode
                  ? 'Tippe auf die Karte, um "${equipment.displayName}" neu zu platzieren. X- und Y-Achsen rasten automatisch an benachbarte Geräte an.'
                  : 'Tippe auf die Karte, um "${equipment.displayName}" zu platzieren. X- und Y-Achsen rasten automatisch an benachbarte Geräte an.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.neonCyan),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: const Icon(
              Icons.close,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom panel ─────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.tabController,
    required this.unpositioned,
    required this.positioned,
    required this.onSelectForPlacement,
    required this.onClearPosition,
    required this.panelHeight,
  });

  final TabController tabController;
  final List<GymEquipment> unpositioned;
  final List<GymEquipment> positioned;
  final void Function(GymEquipment) onSelectForPlacement;
  final void Function(GymEquipment) onClearPosition;
  final double panelHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: panelHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface800,
        border: Border(top: BorderSide(color: AppColors.surface500)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: tabController,
            indicatorColor: AppColors.neonCyan,
            labelColor: AppColors.neonCyan,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Ohne Position (${unpositioned.length})'),
              Tab(text: 'Platziert (${positioned.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _EquipmentList(
                  items: unpositioned,
                  onTap: onSelectForPlacement,
                  trailingIcon: Icons.add_location_outlined,
                  trailingColor: AppColors.neonCyan,
                ),
                _EquipmentList(
                  items: positioned,
                  onTap: onClearPosition,
                  trailingIcon: Icons.location_off_outlined,
                  trailingColor: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentList extends StatelessWidget {
  const _EquipmentList({
    required this.items,
    required this.onTap,
    required this.trailingIcon,
    required this.trailingColor,
  });

  final List<GymEquipment> items;
  final void Function(GymEquipment) onTap;
  final IconData trailingIcon;
  final Color trailingColor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Keine Geräte',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final eq = items[i];
        final typeColor = switch (eq.equipmentType) {
          EquipmentType.fixedMachine => AppColors.neonCyan,
          EquipmentType.openStation => AppColors.neonMagenta,
          EquipmentType.cardio => AppColors.neonYellow,
        };
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 8,
            backgroundColor: typeColor.withAlpha(180),
          ),
          title: Text(
            eq.displayName,
            style: AppTextStyles.labelLg.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: eq.manufacturer != null
              ? Text(eq.manufacturer!, style: AppTextStyles.bodySm)
              : null,
          trailing: Icon(trailingIcon, color: trailingColor, size: 18),
          onTap: () => onTap(eq),
        );
      },
    );
  }
}
