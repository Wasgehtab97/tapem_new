import 'package:equatable/equatable.dart';
import 'workout_session.dart';

class SessionExercise extends Equatable {
  const SessionExercise({
    required this.id,
    required this.sessionId,
    required this.gymId,
    required this.exerciseKey,
    required this.displayName,
    required this.sortOrder,
    required this.syncStatus,
    this.customExerciseId,
    this.notes,
  });

  final String id;
  final String sessionId;
  final String gymId;
  final String
  exerciseKey; // references exercise_templates or user_custom_exercises
  final String displayName;
  final int sortOrder;
  final SyncStatus syncStatus;
  final String? customExerciseId; // non-null if this is a UserCustomExercise
  final String? notes;

  bool get isCustomExercise => customExerciseId != null;

  @override
  List<Object?> get props => [id];
}
