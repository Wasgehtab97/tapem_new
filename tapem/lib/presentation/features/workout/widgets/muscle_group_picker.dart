import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/gym/exercise_muscle_group.dart';
import '../../../../domain/entities/gym/muscle_group.dart';
import '../../../../domain/entities/gym/muscle_group_role.dart';

/// A compact inline widget for selecting primary and secondary muscle groups
/// when creating a custom exercise at an open station.
///
/// Primary muscle group is required (single-select).
/// Secondary muscle groups are optional (multi-select, max 3, primary excluded).
class MuscleGroupPicker extends StatelessWidget {
  const MuscleGroupPicker({
    super.key,
    required this.selectedPrimary,
    required this.selectedSecondary,
    required this.onPrimaryChanged,
    required this.onSecondaryChanged,
  });

  final MuscleGroup? selectedPrimary;
  final List<MuscleGroup> selectedSecondary;
  final ValueChanged<MuscleGroup?> onPrimaryChanged;
  final ValueChanged<List<MuscleGroup>> onSecondaryChanged;

  static const int _maxSecondary = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Primary (required) ─────────────────────────────────────────────────
        Row(
          children: [
            const Text('PRIMÄRE MUSKELGRUPPE', style: AppTextStyles.labelSm),
            const SizedBox(width: 6),
            Text(
              '(Pflichtfeld)',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.neonCyan,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MuscleGroupChipRow(
          groups: MuscleGroup.sorted,
          selectedGroups: selectedPrimary != null ? [selectedPrimary!] : [],
          isSingleSelect: true,
          onToggle: (group, selected) {
            onPrimaryChanged(selected ? group : null);
            // If the new primary was a secondary, remove it from secondaries.
            if (selected && selectedSecondary.contains(group)) {
              onSecondaryChanged(
                selectedSecondary.where((g) => g != group).toList(),
              );
            }
          },
        ),

        const SizedBox(height: 16),

        // ── Secondary (optional) ───────────────────────────────────────────────
        Row(
          children: [
            const Text('SEKUNDÄRE MUSKELGRUPPEN', style: AppTextStyles.labelSm),
            const SizedBox(width: 6),
            Text(
              '(Optional, max. $_maxSecondary)',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MuscleGroupChipRow(
          // Exclude the selected primary from the secondary options.
          groups: MuscleGroup.sorted
              .where((g) => g != selectedPrimary)
              .toList(),
          selectedGroups: selectedSecondary,
          isSingleSelect: false,
          onToggle: (group, selected) {
            final current = List<MuscleGroup>.from(selectedSecondary);
            if (selected) {
              if (current.length < _maxSecondary) {
                current.add(group);
              }
            } else {
              current.remove(group);
            }
            onSecondaryChanged(current);
          },
        ),
      ],
    );
  }

  /// Converts the current picker state to [ExerciseMuscleGroup] entities.
  /// Returns an empty list if no primary is selected.
  List<ExerciseMuscleGroup> toMuscleGroups() {
    if (selectedPrimary == null) return const [];
    return [
      ExerciseMuscleGroup(
        muscleGroup: selectedPrimary!,
        role: MuscleGroupRole.primary,
      ),
      for (final sec in selectedSecondary)
        ExerciseMuscleGroup(
          muscleGroup: sec,
          role: MuscleGroupRole.secondary,
        ),
    ];
  }
}

// ─── Internal chip row ────────────────────────────────────────────────────────

class _MuscleGroupChipRow extends StatelessWidget {
  const _MuscleGroupChipRow({
    required this.groups,
    required this.selectedGroups,
    required this.isSingleSelect,
    required this.onToggle,
  });

  final List<MuscleGroup> groups;
  final List<MuscleGroup> selectedGroups;
  final bool isSingleSelect;
  final void Function(MuscleGroup group, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: groups.map((group) {
        final isSelected = selectedGroups.contains(group);
        return _MuscleGroupChip(
          label: group.displayNameDe,
          isSelected: isSelected,
          onTap: () => onToggle(group, !isSelected),
        );
      }).toList(),
    );
  }
}

class _MuscleGroupChip extends StatelessWidget {
  const _MuscleGroupChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonCyan.withAlpha(25)
              : AppColors.surface600,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppColors.neonCyan.withAlpha(200)
                : AppColors.surface500,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isSelected ? AppColors.neonCyan : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
