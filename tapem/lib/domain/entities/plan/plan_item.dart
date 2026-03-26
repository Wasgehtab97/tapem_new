import '../../../data/datasources/local/app_database.dart';

enum PlanItemType { fixedMachine, openStation, cardio }

/// One exercise slot in a [WorkoutPlan], ordered by [position].
class PlanItem {
  const PlanItem({
    required this.id,
    required this.planId,
    required this.gymId,
    required this.equipmentId,
    this.canonicalExerciseKey,
    this.customExerciseId,
    required this.displayName,
    required this.position,
  });

  final String id;
  final String planId;
  final String gymId;
  final String equipmentId;
  final String? canonicalExerciseKey;
  final String? customExerciseId;
  final String displayName;
  final int position;

  PlanItemType get type {
    if (customExerciseId != null) return PlanItemType.openStation;
    if (canonicalExerciseKey != null) return PlanItemType.fixedMachine;
    return PlanItemType.cardio;
  }

  /// The exercise key used when adding this item as a session exercise.
  String get exerciseKey =>
      canonicalExerciseKey ??
      (customExerciseId != null
          ? 'custom:$customExerciseId'
          : 'cardio:$equipmentId');

  static PlanItem fromLocal(LocalPlanItem row) => PlanItem(
    id: row.id,
    planId: row.planId,
    gymId: row.gymId,
    equipmentId: row.equipmentId,
    canonicalExerciseKey: row.canonicalExerciseKey,
    customExerciseId: row.customExerciseId,
    displayName: row.displayName,
    position: row.position,
  );
}
