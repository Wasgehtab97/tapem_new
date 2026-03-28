import 'dart:async' show unawaited;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../../domain/entities/gym/exercise_muscle_group.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../../domain/entities/gym/muscle_group.dart';
import '../../../../domain/entities/gym/muscle_group_role.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../router/route_names.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../providers/equipment_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/equipment_detail_sheet.dart';
import '../widgets/muscle_group_picker.dart';

const _uuid = Uuid();

// ─── Equipment picker (by type) ───────────────────────────────────────────────

class EquipmentPickerScreen extends ConsumerWidget {
  const EquipmentPickerScreen({
    super.key,
    required this.gymId,
    this.type, // null = show all equipment
    this.addToActiveWorkout = false,
  });

  final String gymId;
  final EquipmentType? type;

  /// When true, tapping equipment adds an exercise to the running session
  /// instead of starting a new session. The screen pops with a
  /// `({exerciseKey, displayName, customExerciseId})` result.
  final bool addToActiveWorkout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = type != null
        ? ref.watch(equipmentByTypeProvider((gymId: gymId, type: type!)))
        : ref.watch(gymEquipmentProvider(gymId));

    final title = addToActiveWorkout
        ? 'ADD EXERCISE'
        : type == null
        ? 'ALL EQUIPMENT'
        : switch (type!) {
            EquipmentType.fixedMachine => 'FIXED MACHINES',
            EquipmentType.openStation => 'OPEN STATIONS',
            EquipmentType.cardio => 'CARDIO MACHINES',
          };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // When adding to an active workout the screen is pushed via
        // Navigator.push(), not GoRouter. Provide an explicit close button so
        // the user can always dismiss without selecting anything.
        leading: addToActiveWorkout
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: equipmentAsync.when(
        data: (equipment) => equipment.isEmpty
            ? Center(
                child: Text(
                  'No equipment found.\nAsk your gym admin to add machines.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : _EquipmentList(
                equipment: equipment,
                gymId: gymId,
                type: type,
                addToActiveWorkout: addToActiveWorkout,
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _EquipmentList extends HookConsumerWidget {
  const _EquipmentList({
    required this.equipment,
    required this.gymId,
    required this.type,
    this.addToActiveWorkout = false,
  });

  final List<GymEquipment> equipment;
  final String gymId;
  final EquipmentType? type;
  final bool addToActiveWorkout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtrl = useTextEditingController();
    final query = useState('');

    final filtered = query.value.isEmpty
        ? equipment
        : equipment
              .where(
                (e) =>
                    e.name.toLowerCase().contains(query.value) ||
                    (e.manufacturer?.toLowerCase().contains(query.value) ??
                        false),
              )
              .toList();

    // Group by type label when showing ALL, otherwise by zone
    final groups = <String, List<GymEquipment>>{};
    if (type == null) {
      // ALL view — group by equipment type
      for (final e in filtered) {
        final label = switch (e.equipmentType) {
          EquipmentType.fixedMachine => 'Fixed Machines',
          EquipmentType.openStation => 'Open Stations',
          EquipmentType.cardio => 'Cardio',
        };
        groups.putIfAbsent(label, () => []).add(e);
      }
    } else {
      // Type-specific view — group by zone (null → single unlabelled group)
      for (final e in filtered) {
        groups.putIfAbsent(e.zoneName ?? '', () => []).add(e);
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: searchCtrl,
            onChanged: (v) => query.value = v.toLowerCase(),
            autocorrect: false,
            enableSuggestions: false,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: 'Search equipment...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: query.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        searchCtrl.clear();
                        query.value = '';
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No results for "${searchCtrl.text}"',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: groups.length,
                  itemBuilder: (context, groupIdx) {
                    final groupLabel = groups.keys.elementAt(groupIdx);
                    final items = groups[groupLabel]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (groupIdx > 0) const SizedBox(height: 16),
                        if (groupLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              groupLabel.toUpperCase(),
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ...items.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _EquipmentTile(
                              equipment: e,
                              gymId: gymId,
                              type: type ?? e.equipmentType,
                              showTypeBadge: type == null,
                              addToActiveWorkout: addToActiveWorkout,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EquipmentTile extends ConsumerWidget {
  const _EquipmentTile({
    required this.equipment,
    required this.gymId,
    required this.type,
    this.showTypeBadge = false,
    this.addToActiveWorkout = false,
  });

  final GymEquipment equipment;
  final String gymId;
  final EquipmentType type;
  final bool showTypeBadge;
  final bool addToActiveWorkout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (badgeLabel, badgeColor) = switch (equipment.equipmentType) {
      EquipmentType.fixedMachine => ('FIXED', AppColors.neonCyan),
      EquipmentType.openStation => ('OPEN', AppColors.neonMagenta),
      EquipmentType.cardio => ('CARDIO', AppColors.neonYellow),
    };

    return GestureDetector(
      onTap: () => _onSelect(context, ref),
      onLongPress: () => _onLongPress(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equipment.name, style: AppTextStyles.bodyLg),
                  if (equipment.manufacturer != null)
                    Text(equipment.manufacturer!, style: AppTextStyles.bodySm),
                  if (equipment.supportsNfc)
                    Row(
                      children: [
                        Icon(
                          Icons.nfc,
                          size: 12,
                          color: AppColors.neonCyan.withAlpha(180),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'NFC',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.neonCyan,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (showTypeBadge)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: badgeColor.withAlpha(80)),
                ),
                child: Text(
                  badgeLabel,
                  style: AppTextStyles.labelSm.copyWith(color: badgeColor),
                ),
              ),
            Icon(
              addToActiveWorkout
                  ? Icons.add_circle_outline
                  : Icons.play_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _onLongPress(BuildContext context, WidgetRef ref) {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(showEquipmentDetailSheet(context, equipment, gymId));
  }

  Future<void> _onSelect(BuildContext context, WidgetRef ref) async {
    if (addToActiveWorkout) {
      await _addExerciseToActiveWorkout(context);
      return;
    }
    await _startNewSession(context, ref);
  }

  /// Resolves the exercise for the selected equipment and pops with the result.
  /// The caller (`ActiveWorkoutScreen`) is responsible for calling `addExercise`.
  Future<void> _addExerciseToActiveWorkout(BuildContext context) async {
    ({
      String exerciseKey,
      String displayName,
      String? customExerciseId,
      String equipmentId,
    })?
    result;

    switch (equipment.equipmentType) {
      case EquipmentType.fixedMachine:
        result = (
          exerciseKey: equipment.canonicalExerciseKey ?? '',
          displayName: equipment.name,
          customExerciseId: null,
          equipmentId: equipment.id,
        );

      case EquipmentType.openStation:
        if (!context.mounted) return;
        final picked = await Navigator.of(context)
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
                  equipmentName: equipment.name,
                ),
              ),
            );
        if (picked == null) return;
        result = (
          exerciseKey: picked.exerciseKey,
          displayName: picked.displayName,
          customExerciseId: picked.customExerciseId,
          equipmentId: equipment.id,
        );

      case EquipmentType.cardio:
        result = (
          exerciseKey: 'cardio:${equipment.id}',
          displayName: equipment.name,
          customExerciseId: null,
          equipmentId: equipment.id,
        );
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(result);
  }

  Future<void> _startNewSession(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(workoutProvider.notifier);

    switch (type) {
      case EquipmentType.fixedMachine:
        await notifier.startSession(
          equipmentId: equipment.id,
          equipmentName: equipment.name,
          canonicalExerciseKey: equipment.canonicalExerciseKey ?? '',
          canonicalExerciseName: equipment.name,
        );

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
                  equipmentName: equipment.name,
                ),
              ),
            );
        if (exercise == null) return;
        await notifier.startSession(
          equipmentId: equipment.id,
          equipmentName: equipment.name,
          canonicalExerciseKey: exercise.exerciseKey,
          canonicalExerciseName: exercise.displayName,
        );

      case EquipmentType.cardio:
        await notifier.startSession(
          equipmentId: equipment.id,
          equipmentName: equipment.name,
          canonicalExerciseKey: 'cardio:${equipment.id}',
          canonicalExerciseName: equipment.name,
          isCardio: true,
        );
    }

    if (!context.mounted) return;
    final workoutState = ref.read(workoutProvider);
    if (workoutState is WorkoutActive) {
      context.go(RouteNames.activeWorkout);
    }
  }
}

// ─── Exercise picker / creator for open_station ───────────────────────────────

class ExercisePickerSheet extends HookConsumerWidget {
  const ExercisePickerSheet({
    super.key,
    required this.gymId,
    required this.equipmentId,
    required this.equipmentName,
  });

  final String gymId;
  final String equipmentId;
  final String equipmentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtrl = useTextEditingController();
    final query = useState('');
    final isCreating = useState(false);
    final newExerciseCtrl = useTextEditingController();

    final userId = ref.watch(currentUserProvider)?.id ?? '';
    final db = ref.watch(appDatabaseProvider);

    final exercisesAsync = useMemoized(
      () => db.getCustomExercisesForEquipment(gymId, userId, equipmentId),
      [gymId, userId, equipmentId],
    );
    final exercisesFuture = useFuture(exercisesAsync);

    final exercises = exercisesFuture.data ?? [];
    final filtered = query.value.isEmpty
        ? exercises
        : exercises
              .where((e) => e.name.toLowerCase().contains(query.value))
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CHOOSE EXERCISE\n$equipmentName',
          style: AppTextStyles.bodyMd,
        ),
      ),
      body: Column(
        children: [
          if (exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TapemTextField(
                controller: searchCtrl,
                label: 'SEARCH',
                hintText: 'Filter exercises...',
                onChanged: (v) => query.value = v.toLowerCase(),
                prefixIcon: const Icon(Icons.search),
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (exercises.isEmpty) ...[
                  const SizedBox(height: 32),
                  Center(
                    child: Icon(
                      Icons.fitness_center_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withAlpha(100),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'NO EXERCISES YET',
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Create your first exercise for\n$equipmentName.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                // Create new exercise
                if (!isCreating.value)
                  TapemButton(
                    label: '+ CREATE EXERCISE',
                    variant: TapemButtonVariant.outlined,
                    icon: Icons.add,
                    onPressed: () => isCreating.value = true,
                  )
                else
                  _CreateExerciseInline(
                    controller: newExerciseCtrl,
                    gymId: gymId,
                    equipmentId: equipmentId,
                    onCreated: (key, name, customId) {
                      isCreating.value = false;
                      Navigator.of(context).pop((
                        exerciseKey: key,
                        displayName: name,
                        customExerciseId: customId,
                      ));
                    },
                    onCancel: () => isCreating.value = false,
                  ),
                const SizedBox(height: 16),
                // User's exercises for this station
                if (filtered.isNotEmpty) ...[
                  Text(
                    'MY EXERCISES AT ${equipmentName.toUpperCase()}',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...filtered.map(
                    (c) => _ExerciseTileItem(
                      name: c.name,
                      onTap: () => Navigator.of(context).pop((
                        exerciseKey: 'custom:${c.id}',
                        displayName: c.name,
                        customExerciseId: c.id,
                      )),
                    ),
                  ),
                ],
                if (query.value.isNotEmpty && filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No exercises match "${searchCtrl.text}".',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

class _ExerciseTileItem extends StatelessWidget {
  const _ExerciseTileItem({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Row(
          children: [
            Expanded(child: Text(name, style: AppTextStyles.bodyLg)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Two-step inline widget for creating a custom exercise:
///   Step 1 — Enter exercise name
///   Step 2 — Assign primary + optional secondary muscle groups
class _CreateExerciseInline extends HookConsumerWidget {
  const _CreateExerciseInline({
    required this.controller,
    required this.gymId,
    required this.equipmentId,
    required this.onCreated,
    required this.onCancel,
  });

  final TextEditingController controller;
  final String gymId;
  final String equipmentId;
  final void Function(
    String exerciseKey,
    String displayName,
    String? customExerciseId,
  )
  onCreated;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final step = useState(0); // 0 = name, 1 = muscle groups
    final selectedPrimary = useState<MuscleGroup?>(null);
    final selectedSecondary = useState<List<MuscleGroup>>(const []);
    // Rebuild when the text field content changes so the WEITER button
    // enables/disables reactively as the user types.
    useListenable(controller);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('NEUE ÜBUNG', style: AppTextStyles.labelMd),
              const Spacer(),
              // Step indicator
              Text(
                'SCHRITT ${step.value + 1}/2',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (step.value == 0) ...[
            // ── Step 1: Name ─────────────────────────────────────────────────
            TapemTextField(
              controller: controller,
              label: 'ÜBUNGSNAME',
              hintText: 'z.B. Cable Fly',
              textInputAction: TextInputAction.next,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TapemButton(
                    label: 'ABBRECHEN',
                    variant: TapemButtonVariant.ghost,
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TapemButton(
                    label: 'WEITER',
                    onPressed: controller.text.trim().isEmpty
                        ? null
                        : () => step.value = 1,
                  ),
                ),
              ],
            ),
          ] else ...[
            // ── Step 2: Muscle groups ────────────────────────────────────────
            Text(
              '"${controller.text.trim()}"',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            MuscleGroupPicker(
              selectedPrimary: selectedPrimary.value,
              selectedSecondary: selectedSecondary.value,
              onPrimaryChanged: (g) => selectedPrimary.value = g,
              onSecondaryChanged: (list) => selectedSecondary.value = list,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TapemButton(
                    label: 'ZURÜCK',
                    variant: TapemButtonVariant.ghost,
                    onPressed: () => step.value = 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TapemButton(
                    label: 'ERSTELLEN',
                    isLoading: isLoading.value,
                    // Require at least a primary muscle group.
                    onPressed: selectedPrimary.value == null
                        ? null
                        : () => _create(
                              ref,
                              isLoading,
                              selectedPrimary.value,
                              selectedSecondary.value,
                            ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _create(
    WidgetRef ref,
    ValueNotifier<bool> isLoading,
    MuscleGroup? primary,
    List<MuscleGroup> secondary,
  ) async {
    final name = controller.text.trim();
    if (name.isEmpty || primary == null) return;

    isLoading.value = true;
    try {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      final db = ref.read(appDatabaseProvider);
      final id = _uuid.v4();

      await db.insertCustomExercise(
        LocalUserCustomExercisesCompanion.insert(
          id: id,
          gymId: gymId,
          userId: userId,
          name: name,
          equipmentId: Value(equipmentId),
        ),
      );

      // Persist muscle group assignments locally.
      final mgCompanions = [
        LocalUserCustomExerciseMuscleGroupsCompanion.insert(
          customExerciseId: id,
          muscleGroup: primary.value,
          role: MuscleGroupRole.primary.value,
        ),
        for (final sec in secondary)
          LocalUserCustomExerciseMuscleGroupsCompanion.insert(
            customExerciseId: id,
            muscleGroup: sec.value,
            role: MuscleGroupRole.secondary.value,
          ),
      ];
      await db.upsertCustomExerciseMuscleGroups(id, mgCompanions);

      onCreated('custom:$id', name, id);
    } finally {
      isLoading.value = false;
    }
  }
}
