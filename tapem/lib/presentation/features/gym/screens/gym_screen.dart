import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../router/route_names.dart';
import '../../../widgets/common/tapem_empty_state.dart';
import '../../../widgets/common/tapem_skeleton.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../workout/providers/equipment_provider.dart';
import '../../workout/providers/workout_provider.dart';
import '../../workout/screens/equipment_picker_screen.dart';
import '../../workout/widgets/equipment_detail_sheet.dart';
import '../widgets/gym_map_view.dart';

class GymScreen extends HookConsumerWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    final l10n = context.l10n;

    if (gymId == null) {
      return Scaffold(body: Center(child: Text(l10n.noActiveGym)));
    }

    final gymName = ref
        .watch(activeMembershipProvider)
        .maybeWhen(data: (m) => m?.gymName, orElse: () => null);

    final workoutState = ref.watch(workoutProvider);
    final isActive = workoutState is WorkoutActive;

    final user = ref.watch(currentUserProvider);

    final favArgs = user != null ? (userId: user.id, gymId: gymId) : null;
    final favouriteIds = favArgs != null
        ? ref.watch(favouriteEquipmentIdsProvider(favArgs)).valueOrNull ??
              const <String>{}
        : const <String>{};

    final searchCtrl = useTextEditingController();
    final searchQuery = useState('');
    final selectedType = useState<EquipmentType?>(null);
    final showFavouritesOnly = useState(false);
    final showMap = useState(false);

    useEffect(() {
      void listener() => searchQuery.value = searchCtrl.text;
      searchCtrl.addListener(listener);
      return () => searchCtrl.removeListener(listener);
    }, const []);

    final equipmentAsync = ref.watch(gymEquipmentProvider(gymId));

    return Scaffold(
      appBar: AppBar(
        title: Text(gymName ?? l10n.navGym.toUpperCase()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(45),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Theme.of(context).colorScheme.primary,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              _TypeFilterBar(
                selected: selectedType.value,
                onSelected: (t) {
                  selectedType.value = t;
                  showMap.value = false;
                },
                showFavourites: showFavouritesOnly.value,
                onToggleFavourites: () {
                  showFavouritesOnly.value = !showFavouritesOnly.value;
                  showMap.value = false;
                },
                showMap: showMap.value,
                onToggleMap: () => showMap.value = !showMap.value,
              ),
            ],
          ),
        ),
      ),
      body: equipmentAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [TapemSkeleton.listTiles(count: 6)],
        ),
        error: (_, __) => Center(
          child: Text(
            l10n.errorLoadingEquipment,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        data: (equipment) {
          // ── Map view ───────────────────────────────────────────────────
          if (showMap.value) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: GymMapView(
                key: const ValueKey('map'),
                gymId: gymId,
                equipment: equipment,
              ),
            );
          }

          // ── List view ──────────────────────────────────────────────────
          final filtered = equipment.where((e) {
            if (showFavouritesOnly.value && !favouriteIds.contains(e.id)) {
              return false;
            }
            if (selectedType.value != null &&
                e.equipmentType != selectedType.value) {
              return false;
            }
            if (searchQuery.value.isNotEmpty) {
              return equipmentMatchesSearchQuery(e, searchQuery.value);
            }
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TapemTextField(
                  label: l10n.searchEquipmentLabel,
                  controller: searchCtrl,
                  hintText: l10n.searchEquipmentHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.neonCyan.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.neonCyan,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.tapMachineToAdd,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? TapemEmptyState(
                        icon: showFavouritesOnly.value
                            ? Icons.favorite_outline
                            : Icons.fitness_center_outlined,
                        title: showFavouritesOnly.value
                            ? l10n.noFavouritesYet
                            : l10n.noEquipmentFound,
                        iconColor: Theme.of(context).colorScheme.primary,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final eq = filtered[i];
                          return _GymEquipmentTile(
                            equipment: eq,
                            gymId: gymId,
                            isActive: isActive,
                            isFavourite: favouriteIds.contains(eq.id),
                            onFavouriteToggle: () => _toggleFavourite(
                              ref,
                              user?.id,
                              gymId,
                              eq.id,
                              favouriteIds,
                            ),
                            onTap: () => unawaited(
                              _handleTap(context, ref, eq, gymId, isActive),
                            ),
                            onLongPress: () =>
                                showEquipmentDetailSheet(context, eq, gymId),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleFavourite(
    WidgetRef ref,
    String? userId,
    String gymId,
    String equipmentId,
    Set<String> currentFavs,
  ) async {
    if (userId == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.setFavourite(
      userId,
      gymId,
      equipmentId,
      !currentFavs.contains(equipmentId),
    );
    ref.invalidate(
      favouriteEquipmentIdsProvider((userId: userId, gymId: gymId)),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    GymEquipment equipment,
    String gymId,
    bool isActive,
  ) async {
    if (!isActive) {
      unawaited(showEquipmentDetailSheet(context, equipment, gymId));
      return;
    }
    await _addToWorkout(context, ref, equipment, gymId);
  }

  Future<void> _addToWorkout(
    BuildContext context,
    WidgetRef ref,
    GymEquipment equipment,
    String gymId,
  ) async {
    final notifier = ref.read(workoutProvider.notifier);

    switch (equipment.equipmentType) {
      case EquipmentType.fixedMachine:
        final key = equipment.canonicalExerciseKey ?? equipment.id;
        if (_focusIfAlreadyAdded(context, ref, key, equipment.id)) return;
        await notifier.addExercise(
          exerciseKey: key,
          displayName: equipment.displayName,
          equipmentId: equipment.id,
        );
        if (context.mounted) {
          _focusExerciseByEquipmentId(ref, equipment.id);
          context.go(RouteNames.activeWorkout);
        }

      case EquipmentType.openStation:
        if (!context.mounted) return;
        final exercise = await Navigator.of(context)
            .push<
              ({
                String exerciseKey,
                String displayName,
                String? customExerciseId,
              })
            >(
              MaterialPageRoute(
                builder: (_) => ExercisePickerSheet(
                  gymId: gymId,
                  equipmentId: equipment.id,
                  equipmentName: equipment.displayName,
                ),
              ),
            );
        if (exercise == null) return;
        if (!context.mounted) return;
        if (_focusIfAlreadyAdded(
          context,
          ref,
          exercise.exerciseKey,
          equipment.id,
        )) {
          return;
        }
        await notifier.addExercise(
          exerciseKey: exercise.exerciseKey,
          displayName: exercise.displayName,
          equipmentId: equipment.id,
          customExerciseId: exercise.customExerciseId,
        );
        if (context.mounted) {
          _focusExerciseByEquipmentAndKey(
            ref,
            equipment.id,
            exercise.exerciseKey,
          );
          context.go(RouteNames.activeWorkout);
        }

      case EquipmentType.cardio:
        final key = 'cardio:${equipment.id}';
        if (_focusIfAlreadyAdded(context, ref, key, equipment.id)) return;
        await notifier.addExercise(
          exerciseKey: key,
          displayName: equipment.displayName,
          equipmentId: equipment.id,
        );
        if (context.mounted) {
          _focusExerciseByEquipmentId(ref, equipment.id);
          context.go(RouteNames.activeWorkout);
        }
    }
  }

  /// Returns true (and focuses) only when this exact machine is already in the
  /// workout.  Two different machines that share a canonical exercise key are
  /// treated as distinct entries, so both can be added.
  bool _focusIfAlreadyAdded(
    BuildContext context,
    WidgetRef ref,
    String exerciseKey,
    String equipmentId,
  ) {
    final workout = ref.read(workoutProvider);
    if (workout is! WorkoutActive) return false;

    final existing = workout.exercises
        .where(
          (e) =>
              e.exercise.exerciseKey == exerciseKey &&
              e.exercise.equipmentId == equipmentId,
        )
        .firstOrNull;
    if (existing == null) return false;

    ref.read(focusedExerciseIdProvider.notifier).state = existing.exercise.id;
    context.go(RouteNames.activeWorkout);
    return true;
  }

  /// Focus the exercise on a specific machine (fixed machine / cardio).
  void _focusExerciseByEquipmentId(WidgetRef ref, String equipmentId) {
    final workout = ref.read(workoutProvider);
    if (workout is! WorkoutActive) return;
    final added = workout.exercises
        .where((e) => e.exercise.equipmentId == equipmentId)
        .lastOrNull;
    if (added != null) {
      ref.read(focusedExerciseIdProvider.notifier).state = added.exercise.id;
    }
  }

  /// Focus a specific exercise on an open station (key + equipmentId).
  void _focusExerciseByEquipmentAndKey(
    WidgetRef ref,
    String equipmentId,
    String exerciseKey,
  ) {
    final workout = ref.read(workoutProvider);
    if (workout is! WorkoutActive) return;
    final added = workout.exercises
        .where(
          (e) =>
              e.exercise.equipmentId == equipmentId &&
              e.exercise.exerciseKey == exerciseKey,
        )
        .lastOrNull;
    if (added != null) {
      ref.read(focusedExerciseIdProvider.notifier).state = added.exercise.id;
    }
  }
}

// ─── Type filter chips ────────────────────────────────────────────────────────

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({
    required this.selected,
    required this.onSelected,
    required this.showFavourites,
    required this.onToggleFavourites,
    required this.showMap,
    required this.onToggleMap,
  });

  final EquipmentType? selected;
  final void Function(EquipmentType?) onSelected;
  final bool showFavourites;
  final VoidCallback onToggleFavourites;
  final bool showMap;
  final VoidCallback onToggleMap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _FilterChip(
            label: l10n.filterFavs,
            selected: showFavourites && !showMap,
            onTap: onToggleFavourites,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.filterAll,
            selected: selected == null && !showMap,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.filterMachines,
            selected: selected == EquipmentType.fixedMachine && !showMap,
            onTap: () => onSelected(
              selected == EquipmentType.fixedMachine
                  ? null
                  : EquipmentType.fixedMachine,
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.filterOpen,
            selected: selected == EquipmentType.openStation && !showMap,
            onTap: () => onSelected(
              selected == EquipmentType.openStation
                  ? null
                  : EquipmentType.openStation,
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.filterCardio,
            selected: selected == EquipmentType.cardio && !showMap,
            onTap: () => onSelected(
              selected == EquipmentType.cardio ? null : EquipmentType.cardio,
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Karte',
            selected: showMap,
            onTap: onToggleMap,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? accent.withAlpha(40) : AppColors.surface800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? accent : AppColors.surface500),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Equipment tile ───────────────────────────────────────────────────────────

class _GymEquipmentTile extends StatelessWidget {
  const _GymEquipmentTile({
    required this.equipment,
    required this.gymId,
    required this.isActive,
    required this.isFavourite,
    required this.onFavouriteToggle,
    required this.onTap,
    required this.onLongPress,
  });

  final GymEquipment equipment;
  final String gymId;
  final bool isActive;
  final bool isFavourite;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (typeColor, typeIcon, typeLabel) = switch (equipment.equipmentType) {
      EquipmentType.fixedMachine => (
        AppColors.neonCyan,
        Icons.fitness_center_outlined,
        l10n.machineTypeLabel,
      ),
      EquipmentType.openStation => (
        AppColors.neonMagenta,
        Icons.fitness_center_outlined,
        l10n.openTypeLabel,
      ),
      EquipmentType.cardio => (
        AppColors.neonYellow,
        Icons.directions_run_outlined,
        l10n.cardioTypeLabel,
      ),
    };

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? typeColor.withAlpha(60) : AppColors.surface500,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: typeColor.withAlpha(80)),
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equipment.displayName, style: AppTextStyles.labelMd),
                  if (equipment.manufacturer != null &&
                      equipment.manufacturer!.isNotEmpty)
                    Text(
                      equipment.manufacturer!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    Text(
                      typeLabel,
                      style: AppTextStyles.bodySm.copyWith(
                        color: typeColor.withAlpha(180),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onFavouriteToggle,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isFavourite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFavourite
                      ? AppColors.neonYellow
                      : AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 2),
            if (isActive)
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.neonCyan,
                size: 20,
              )
            else
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
