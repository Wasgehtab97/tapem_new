import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../../workout/providers/equipment_provider.dart';
import '../../workout/screens/equipment_picker_screen.dart';
import '../providers/plans_provider.dart';

const _uuid = Uuid();

// ─── Plan builder screen ──────────────────────────────────────────────────────

class PlanBuilderScreen extends HookConsumerWidget {
  const PlanBuilderScreen({super.key, this.editPlanId});

  final String? editPlanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planBuilderProvider(editPlanId));
    final notifier = ref.read(planBuilderProvider(editPlanId).notifier);
    final l10n = context.l10n;

    final nameCtrl = useTextEditingController();

    final didSyncName = useRef(false);
    useEffect(() {
      if (!didSyncName.value && state.name.isNotEmpty && !state.isLoading) {
        nameCtrl.text = state.name;
        nameCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: state.name.length),
        );
        didSyncName.value = true;
      }
      return null;
    }, [state.name, state.isLoading]);

    return Scaffold(
      appBar: AppBar(
        title: Text(editPlanId != null ? l10n.editPlan : l10n.newPlan),
        actions: [
          if (editPlanId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              tooltip: l10n.deletePlanTooltip,
              onPressed: () => _confirmDelete(context, notifier),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _PlanBuilderBody(
              state: state,
              notifier: notifier,
              nameCtrl: nameCtrl,
              editPlanId: editPlanId,
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PlanBuilderNotifier notifier,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePlanTitle),
        content: Text(l10n.deletePlanContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await notifier.deletePlan();
    if (!context.mounted) return;
    context.pop();
  }
}

// ─── Builder body ─────────────────────────────────────────────────────────────

class _PlanBuilderBody extends ConsumerWidget {
  const _PlanBuilderBody({
    required this.state,
    required this.notifier,
    required this.nameCtrl,
    required this.editPlanId,
  });

  final PlanBuilderState state;
  final PlanBuilderNotifier notifier;
  final TextEditingController nameCtrl;
  final String? editPlanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TapemTextField(
            controller: nameCtrl,
            label: l10n.planNameLabel,
            hintText: 'e.g. Push Day A',
            onChanged: notifier.setName,
            textInputAction: TextInputAction.done,
          ),
        ),

        if (state.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              state.error!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ),

        const SizedBox(height: 8),

        Expanded(
          child: state.items.isEmpty
              ? _EmptyItemsHint(
                  onAdd: gymId != null
                      ? () => _showEquipmentPicker(context, gymId, notifier)
                      : null,
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: state.items.length,
                  onReorder: notifier.reorder,
                  itemBuilder: (_, index) {
                    final item = state.items[index];
                    return _PlanItemTile(
                      key: ValueKey(item.tempId),
                      item: item,
                      position: index + 1,
                      onRemove: () => notifier.removeItem(item.tempId),
                    );
                  },
                ),
        ),

        if (state.items.isNotEmpty && gymId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TapemButton(
              label: l10n.addExerciseToPlan,
              icon: Icons.add,
              variant: TapemButtonVariant.outlined,
              onPressed: () => _showEquipmentPicker(context, gymId, notifier),
            ),
          ),

        const SizedBox(height: 8),

        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: TapemButton(
            label: editPlanId != null ? l10n.saveChanges : l10n.savePlan,
            icon: Icons.check,
            isLoading: state.isSaving,
            onPressed: state.canSave ? () => _save(context, notifier) : null,
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, PlanBuilderNotifier notifier) async {
    final planId = await notifier.save();
    if (!context.mounted) return;
    if (planId != null) context.pop();
  }

  void _showEquipmentPicker(
    BuildContext context,
    String gymId,
    PlanBuilderNotifier notifier,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetCtx) => _EquipmentPickerSheet(
          gymId: gymId,
          onItemAdded: notifier.addItem,
          parentContext: context,
          sheetContext: sheetCtx,
        ),
      ),
    );
  }
}

// ─── Empty items hint ─────────────────────────────────────────────────────────

class _EmptyItemsHint extends StatelessWidget {
  const _EmptyItemsHint({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 56,
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 20),
            Text(l10n.noExercisesYet, style: AppTextStyles.h3),
            const SizedBox(height: 10),
            Text(
              l10n.noExercisesHint,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 28),
              TapemButton(
                label: l10n.addFirstExercise,
                icon: Icons.add,
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Plan item tile ───────────────────────────────────────────────────────────

class _PlanItemTile extends StatelessWidget {
  const _PlanItemTile({
    super.key,
    required this.item,
    required this.position,
    required this.onRemove,
  });

  final PlanBuilderItem item;
  final int position;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (badgeLabel, badgeColor) = switch (item.equipmentType) {
      'fixed_machine' => (l10n.fixedBadge, AppColors.neonCyan),
      'open_station' => (l10n.openBadge, AppColors.neonMagenta),
      _ => (l10n.cardioBadge, AppColors.neonYellow),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface900,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: position - 1,
            child: const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(
                Icons.drag_handle,
                color: AppColors.textDisabled,
                size: 20,
              ),
            ),
          ),

          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$position',
              style: AppTextStyles.monoSm.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayName, style: AppTextStyles.bodyMd),
                const SizedBox(height: 2),
                Text(
                  item.equipmentName,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: badgeColor.withAlpha(70)),
            ),
            child: Text(
              badgeLabel,
              style: AppTextStyles.labelSm.copyWith(
                color: badgeColor,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 6),

          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.remove_circle_outline,
                color: AppColors.textDisabled,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Equipment picker sheet ───────────────────────────────────────────────────

class _EquipmentPickerSheet extends ConsumerWidget {
  const _EquipmentPickerSheet({
    required this.gymId,
    required this.onItemAdded,
    required this.parentContext,
    required this.sheetContext,
  });

  final String gymId;
  final void Function(PlanBuilderItem) onItemAdded;
  final BuildContext parentContext;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: _EquipmentPickerContent(
          gymId: gymId,
          scrollController: scrollCtrl,
          onItemAdded: onItemAdded,
          parentContext: parentContext,
          sheetContext: sheetContext,
        ),
      ),
    );
  }
}

class _EquipmentPickerContent extends HookConsumerWidget {
  const _EquipmentPickerContent({
    required this.gymId,
    required this.scrollController,
    required this.onItemAdded,
    required this.parentContext,
    required this.sheetContext,
  });

  final String gymId;
  final ScrollController scrollController;
  final void Function(PlanBuilderItem) onItemAdded;
  final BuildContext parentContext;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(gymEquipmentProvider(gymId));
    final selectedType = useState<EquipmentType?>(null);
    final searchCtrl = useTextEditingController();
    final query = useState('');
    final l10n = context.l10n;

    return Column(
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
              Text(l10n.addExercisePicker, style: AppTextStyles.labelLg),
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
        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _TypeChip(
                label: l10n.filterAll,
                selected: selectedType.value == null,
                color: AppColors.neonCyan,
                onTap: () => selectedType.value = null,
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: l10n.filterFixed,
                selected: selectedType.value == EquipmentType.fixedMachine,
                color: AppColors.neonCyan,
                onTap: () => selectedType.value = EquipmentType.fixedMachine,
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: l10n.filterOpen,
                selected: selectedType.value == EquipmentType.openStation,
                color: AppColors.neonMagenta,
                onTap: () => selectedType.value = EquipmentType.openStation,
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: l10n.filterCardio,
                selected: selectedType.value == EquipmentType.cardio,
                color: AppColors.neonYellow,
                onTap: () => selectedType.value = EquipmentType.cardio,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TapemTextField(
            controller: searchCtrl,
            label: l10n.searchLabel,
            hintText: l10n.filterEquipment,
            prefixIcon: const Icon(Icons.search, size: 20),
            onChanged: (v) => query.value = v.toLowerCase(),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: equipmentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (equipment) {
              final filtered = equipment.where((e) {
                final matchesType =
                    selectedType.value == null ||
                    e.equipmentType == selectedType.value;
                final matchesQuery =
                    query.value.isEmpty ||
                    e.name.toLowerCase().contains(query.value) ||
                    (e.manufacturer?.toLowerCase().contains(query.value) ??
                        false);
                return matchesType && matchesQuery;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noEquipmentFoundShort,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: filtered.length,
                itemBuilder: (_, index) => _EquipmentRow(
                  equipment: filtered[index],
                  gymId: gymId,
                  onItemAdded: onItemAdded,
                  parentContext: parentContext,
                  sheetContext: sheetContext,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Type filter chip ─────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : AppColors.surface700,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withAlpha(150) : AppColors.surface500,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Equipment row inside picker ──────────────────────────────────────────────

class _EquipmentRow extends StatelessWidget {
  const _EquipmentRow({
    required this.equipment,
    required this.gymId,
    required this.onItemAdded,
    required this.parentContext,
    required this.sheetContext,
  });

  final GymEquipment equipment;
  final String gymId;
  final void Function(PlanBuilderItem) onItemAdded;
  final BuildContext parentContext;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (badgeLabel, badgeColor) = switch (equipment.equipmentType) {
      EquipmentType.fixedMachine => (l10n.fixedBadge, AppColors.neonCyan),
      EquipmentType.openStation => (l10n.openBadge, AppColors.neonMagenta),
      EquipmentType.cardio => (l10n.cardioBadge, AppColors.neonYellow),
    };

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface900,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equipment.name, style: AppTextStyles.bodyMd),
                  if (equipment.manufacturer != null)
                    Text(
                      equipment.manufacturer!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(20),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: badgeColor.withAlpha(70)),
              ),
              child: Text(
                badgeLabel,
                style: AppTextStyles.labelSm.copyWith(
                  color: badgeColor,
                  fontSize: 10,
                ),
              ),
            ),
            const Icon(
              Icons.add_circle_outline,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    switch (equipment.equipmentType) {
      case EquipmentType.fixedMachine:
        onItemAdded(
          PlanBuilderItem(
            tempId: _uuid.v4(),
            equipmentId: equipment.id,
            equipmentName: equipment.name,
            equipmentType: 'fixed_machine',
            canonicalExerciseKey: equipment.canonicalExerciseKey,
            displayName: equipment.name,
          ),
        );
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();

      case EquipmentType.cardio:
        onItemAdded(
          PlanBuilderItem(
            tempId: _uuid.v4(),
            equipmentId: equipment.id,
            equipmentName: equipment.name,
            equipmentType: 'cardio',
            canonicalExerciseKey: 'cardio:${equipment.id}',
            displayName: equipment.name,
          ),
        );
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();

      case EquipmentType.openStation:
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        if (!parentContext.mounted) return;
        final exercise = await Navigator.of(parentContext)
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
        onItemAdded(
          PlanBuilderItem(
            tempId: _uuid.v4(),
            equipmentId: equipment.id,
            equipmentName: equipment.name,
            equipmentType: 'open_station',
            customExerciseId: exercise.customExerciseId,
            displayName: exercise.displayName,
          ),
        );
    }
  }
}
