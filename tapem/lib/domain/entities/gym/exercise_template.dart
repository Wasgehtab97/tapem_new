import 'package:equatable/equatable.dart';

/// Muscle group weighting for XP distribution.
/// Weights must sum to 1.0.
class MuscleGroupWeight extends Equatable {
  const MuscleGroupWeight({required this.muscleGroup, required this.weight});

  final String muscleGroup;
  final double weight; // 0.0–1.0

  @override
  List<Object?> get props => [muscleGroup, weight];
}

class ExerciseTemplate extends Equatable {
  const ExerciseTemplate({
    required this.key,
    required this.gymId,
    required this.name,
    required this.isRankingEligible,
    required this.muscleGroupWeights,
    this.description,
    this.primaryMuscleGroup,
    required this.isActive,
    required this.createdAt,
  });

  final String key;
  final String gymId;
  final String name;
  final bool isRankingEligible;
  final List<MuscleGroupWeight> muscleGroupWeights;
  final String? description;
  final String? primaryMuscleGroup;
  final bool isActive;
  final DateTime createdAt;

  /// Validates that muscle group weights sum to 1.0 (within floating point tolerance).
  bool get hasValidWeights {
    if (muscleGroupWeights.isEmpty) return true;
    final sum = muscleGroupWeights.fold(0.0, (s, w) => s + w.weight);
    return (sum - 1.0).abs() < 0.001;
  }

  @override
  List<Object?> get props => [key, gymId];
}

/// User-created exercise for open_station. Gym- and user-scoped.
class UserCustomExercise extends Equatable {
  const UserCustomExercise({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.name,
    required this.isRankingEligible,
    required this.createdAt,
  });

  final String id;
  final String gymId;
  final String userId;
  final String name;

  /// Always false by default. Content-Ops must explicitly promote.
  final bool isRankingEligible;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id];
}
