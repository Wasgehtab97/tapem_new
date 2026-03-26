import 'package:equatable/equatable.dart';

/// XP axis — drei Achsen in V1.
enum XpAxis {
  trainingDay('training_day'),
  exerciseEquipment('exercise_equipment'),
  muscleGroup('muscle_group');

  const XpAxis(this.value);
  final String value;

  static XpAxis fromValue(String v) =>
      XpAxis.values.firstWhere((e) => e.value == v);
}

/// Represents one XP event. Server is authoritative — this is the local
/// representation before/after sync.
class XpEvent extends Equatable {
  const XpEvent({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.axis,
    required this.xpAmount,
    required this.sourceType,
    required this.sourceId,
    required this.idempotencyKey,
    required this.occurredAt,
    this.exerciseKey,
    this.muscleGroup,
  });

  final String id;
  final String gymId;
  final String userId;
  final XpAxis axis;
  final int xpAmount;
  final String
  sourceType; // 'workout_session' | 'session_exercise' | 'set_entry'
  final String sourceId;

  /// Unique key preventing double-processing: `{axis}:{sourceType}:{sourceId}`
  final String idempotencyKey;
  final DateTime occurredAt;
  final String? exerciseKey;
  final String? muscleGroup;

  @override
  List<Object?> get props => [idempotencyKey];
}

class UserGymXp extends Equatable {
  const UserGymXp({
    required this.userId,
    required this.gymId,
    required this.totalXp,
    required this.currentLevel,
    required this.xpToNextLevel,
    required this.updatedAt,
  });

  final String userId;
  final String gymId;
  final int totalXp;
  final int currentLevel;
  final int xpToNextLevel;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [userId, gymId];
}
