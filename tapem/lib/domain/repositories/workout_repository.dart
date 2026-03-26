import '../entities/gym/gym_equipment.dart';
import '../entities/gym/exercise_template.dart';
import '../entities/workout/workout_session.dart';
import '../entities/workout/session_exercise.dart';
import '../entities/workout/set_entry.dart';

/// Workout data operations. Offline-first: writes always go to local DB first.
/// Sync to Supabase happens asynchronously via the SyncService.
abstract interface class WorkoutRepository {
  // ─── Equipment ────────────────────────────────────────────────────────────

  /// All active equipment for the gym, cached locally.
  Future<List<GymEquipment>> getEquipment({required String gymId});

  /// Resolve a scanned NFC tag UID to equipment. Returns null on unknown tag.
  Future<GymEquipment?> resolveNfcTag({
    required String gymId,
    required String tagUid,
  });

  // ─── Exercise templates ───────────────────────────────────────────────────

  Future<List<ExerciseTemplate>> getExerciseTemplates({required String gymId});

  Future<List<UserCustomExercise>> getUserCustomExercises({
    required String gymId,
    required String userId,
  });

  Future<UserCustomExercise> createUserCustomExercise({
    required String gymId,
    required String userId,
    required String name,
  });

  // ─── Sessions ─────────────────────────────────────────────────────────────

  /// Start a new session. Writes locally, enqueues sync.
  Future<WorkoutSession> startSession({
    required String gymId,
    required String userId,
    required String equipmentId,
    required String sessionDayAnchor,
    required String idempotencyKey,
  });

  /// Finish an in-progress session.
  Future<WorkoutSession> finishSession({required String sessionId});

  /// Watch the active session for a user (null when no session active).
  Stream<WorkoutSession?> watchActiveSession({
    required String gymId,
    required String userId,
  });

  /// Recent sessions for history display.
  Future<List<WorkoutSession>> getRecentSessions({
    required String gymId,
    required String userId,
    int limit = 20,
  });

  // ─── Session exercises ────────────────────────────────────────────────────

  Future<SessionExercise> addExerciseToSession({
    required String sessionId,
    required String gymId,
    required String exerciseKey,
    required String displayName,
    required int sortOrder,
    String? customExerciseId,
  });

  Future<List<SessionExercise>> getSessionExercises({
    required String sessionId,
  });

  // ─── Sets ─────────────────────────────────────────────────────────────────

  Future<SetEntry> logSet({
    required String sessionExerciseId,
    required String gymId,
    required int setNumber,
    required String idempotencyKey,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    String? notes,
  });

  Future<List<SetEntry>> getSets({required String sessionExerciseId});

  Stream<List<SetEntry>> watchSets({required String sessionExerciseId});

  // ─── Sync ─────────────────────────────────────────────────────────────────

  /// Returns all locally saved items awaiting sync.
  Future<List<WorkoutSession>> getPendingSessions();

  Future<void> markSessionSynced({
    required String sessionId,
    required String serverId,
  });
  Future<void> markSessionSyncFailed({required String sessionId});
}
