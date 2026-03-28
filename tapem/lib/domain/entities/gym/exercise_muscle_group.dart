import 'package:equatable/equatable.dart';

import 'muscle_group.dart';
import 'muscle_group_role.dart';

/// Associates a [MuscleGroup] and its training [role] with an exercise.
///
/// Replaces the old weight-based model (`MuscleGroupWeight`) which distributed
/// XP proportionally via fractional weights summing to 1.0. The new model uses
/// a binary primary/secondary classification with flat XP awards per role:
///   • primary   → [XpRules.muscleGroupPrimaryXp]   (10.0 XP)
///   • secondary → [XpRules.muscleGroupSecondaryXp]  (2.5 XP)
class ExerciseMuscleGroup extends Equatable {
  const ExerciseMuscleGroup({
    required this.muscleGroup,
    required this.role,
  });

  final MuscleGroup muscleGroup;
  final MuscleGroupRole role;

  bool get isPrimary => role == MuscleGroupRole.primary;
  bool get isSecondary => role == MuscleGroupRole.secondary;

  // ─── JSON serialization (Drift local cache format) ──────────────────────────

  /// Deserializes from the Drift local cache format: `{"g":"chest","r":"primary"}`.
  ///
  /// Also accepts the legacy weight format `{"g":"chest","w":0.7}` and infers
  /// the role from the weight (> 0.5 → primary, else secondary) so that existing
  /// cached templates upgrade gracefully without a forced server refresh.
  factory ExerciseMuscleGroup.fromJson(Map<String, Object?> json) {
    final group = MuscleGroup.fromValue(json['g'] as String);

    if (json.containsKey('r')) {
      return ExerciseMuscleGroup(
        muscleGroup: group,
        role: MuscleGroupRole.fromValue(json['r'] as String),
      );
    }

    // Legacy weight-based format — infer role from weight value.
    final weight = (json['w'] as num?)?.toDouble() ?? 0.0;
    return ExerciseMuscleGroup(
      muscleGroup: group,
      role: weight > 0.5 ? MuscleGroupRole.primary : MuscleGroupRole.secondary,
    );
  }

  /// Serializes to the Drift local cache format.
  Map<String, Object?> toJson() => {
        'g': muscleGroup.value,
        'r': role.value,
      };

  @override
  List<Object?> get props => [muscleGroup, role];
}
