import 'package:equatable/equatable.dart';

/// Sync state for offline-first writes.
enum SyncStatus {
  localSaved('local_saved'),
  syncPending('sync_pending'),
  syncConfirmed('sync_confirmed'),
  syncFailed('sync_failed');

  const SyncStatus(this.value);
  final String value;

  static SyncStatus fromValue(String v) => SyncStatus.values.firstWhere(
    (e) => e.value == v,
    orElse: () => SyncStatus.localSaved,
  );

  bool get isTerminal => this == syncConfirmed || this == syncFailed;
  bool get needsSync => this == localSaved || this == syncPending;
}

/// A single training session.
/// `sessionDayAnchor` is the local calendar date at the gym at session start —
/// immutable once set. Used for training_day XP deduplication.
class WorkoutSession extends Equatable {
  const WorkoutSession({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.equipmentId,
    required this.sessionDayAnchor,
    required this.startedAt,
    this.finishedAt,
    required this.syncStatus,
    this.idempotencyKey,
    this.notes,
  });

  final String id;
  final String gymId;
  final String userId;
  final String equipmentId;

  /// Immutable local calendar day (yyyy-MM-dd) of session start.
  final String sessionDayAnchor;

  final DateTime startedAt;
  final DateTime? finishedAt;
  final SyncStatus syncStatus;

  /// Client-generated UUID for idempotent server writes.
  final String? idempotencyKey;
  final String? notes;

  bool get isFinished => finishedAt != null;
  Duration? get duration => finishedAt?.difference(startedAt);

  @override
  List<Object?> get props => [id];
}
