import 'package:equatable/equatable.dart';

import 'exercise_muscle_group.dart';
import 'muscle_group.dart';

/// An exercise template for a fixed machine or open station, scoped to a gym.
///
/// Muscle group assignments use the primary/secondary role model — see
/// [ExerciseMuscleGroup] for the XP rules.
class ExerciseTemplate extends Equatable {
  const ExerciseTemplate({
    required this.key,
    required this.gymId,
    required this.name,
    required this.isRankingEligible,
    required this.muscleGroups,
    this.description,
    required this.isActive,
    required this.createdAt,
  });

  final String key;
  final String gymId;
  final String name;
  final bool isRankingEligible;

  /// All muscle group assignments for this exercise (primary + secondary).
  final List<ExerciseMuscleGroup> muscleGroups;

  final String? description;
  final bool isActive;
  final DateTime createdAt;

  // ─── Convenience accessors ──────────────────────────────────────────────────

  /// The primary muscle group assignment, or null if none has been configured.
  ExerciseMuscleGroup? get primaryMuscleGroup =>
      muscleGroups.where((m) => m.isPrimary).firstOrNull;

  /// All secondary muscle group assignments.
  List<ExerciseMuscleGroup> get secondaryMuscleGroups =>
      muscleGroups.where((m) => m.isSecondary).toList();

  /// Returns the [MuscleGroup] enum value of the primary group, or null.
  MuscleGroup? get primaryGroup => primaryMuscleGroup?.muscleGroup;

  /// True when at least one muscle group is assigned.
  bool get hasMuscleGroups => muscleGroups.isNotEmpty;

  @override
  List<Object?> get props => [key, gymId];
}

/// A user-created exercise for an open_station. Gym- and user-scoped.
///
/// Users assign muscle groups when creating the exercise; the app persists
/// them locally and syncs them to [user_custom_exercise_muscle_groups] on
/// the server.
class UserCustomExercise extends Equatable {
  const UserCustomExercise({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.name,
    required this.isRankingEligible,
    required this.createdAt,
    this.muscleGroups = const [],
  });

  final String id;
  final String gymId;
  final String userId;
  final String name;

  /// Always false by default. Content-Ops must explicitly promote.
  final bool isRankingEligible;
  final DateTime createdAt;

  /// Muscle group assignments set by the user during exercise creation.
  final List<ExerciseMuscleGroup> muscleGroups;

  // ─── Convenience accessors ──────────────────────────────────────────────────

  ExerciseMuscleGroup? get primaryMuscleGroup =>
      muscleGroups.where((m) => m.isPrimary).firstOrNull;

  List<ExerciseMuscleGroup> get secondaryMuscleGroups =>
      muscleGroups.where((m) => m.isSecondary).toList();

  MuscleGroup? get primaryGroup => primaryMuscleGroup?.muscleGroup;

  @override
  List<Object?> get props => [id];
}
