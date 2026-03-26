import '../../../data/datasources/local/app_database.dart';

/// A member-owned training plan within a specific gym.
class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String gymId;
  final String userId;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  static WorkoutPlan fromLocal(LocalWorkoutPlan row) => WorkoutPlan(
    id: row.id,
    gymId: row.gymId,
    userId: row.userId,
    name: row.name,
    isActive: row.isActive,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
