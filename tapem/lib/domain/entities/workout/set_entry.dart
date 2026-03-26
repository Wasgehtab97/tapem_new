import 'package:equatable/equatable.dart';
import 'workout_session.dart';

/// A single set within a SessionExercise.
/// For cardio sessions, `durationSeconds` is the primary metric.
class SetEntry extends Equatable {
  const SetEntry({
    required this.id,
    required this.sessionExerciseId,
    required this.gymId,
    required this.setNumber,
    this.reps,
    this.weightKg,
    this.durationSeconds, // cardio primary metric
    this.distanceMeters,
    this.notes,
    required this.syncStatus,
    required this.loggedAt,
    this.idempotencyKey,
  });

  final String id;
  final String sessionExerciseId;
  final String gymId;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final String? notes;
  final SyncStatus syncStatus;
  final DateTime loggedAt;
  final String? idempotencyKey;

  bool get isCardio => durationSeconds != null && reps == null;

  /// XP earned for this set: 5 + floor(reps / 5), capped at SessionExercise level.
  int get rawXpContribution {
    if (isCardio) return 5; // flat for cardio sets
    final r = reps ?? 0;
    return 5 + (r ~/ 5);
  }

  @override
  List<Object?> get props => [id];
}
