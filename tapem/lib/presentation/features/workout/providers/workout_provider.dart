import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../features/progress/providers/xp_provider.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:drift/drift.dart';

const _uuid = Uuid();

// ─── Active session stream ────────────────────────────────────────────────────

final activeSessionProvider = StreamProvider<LocalWorkoutSession?>((ref) {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) return Stream.value(null);

  final db = ref.watch(appDatabaseProvider);
  return db.watchActiveSession(gymId, user.id);
});

// ─── Workout state ────────────────────────────────────────────────────────────

sealed class WorkoutState {
  const WorkoutState();
}

final class WorkoutIdle extends WorkoutState {
  const WorkoutIdle();
}

final class WorkoutStarting extends WorkoutState {
  const WorkoutStarting();
}

/// Transitional state while [WorkoutNotifier.resumeActiveSession] is running.
/// The hub shows a spinner during this state so the user cannot start a new
/// session before the DB check completes (prevents duplicate active sessions).
final class WorkoutResuming extends WorkoutState {
  const WorkoutResuming();
}

final class WorkoutActive extends WorkoutState {
  const WorkoutActive({required this.session, required this.exercises});

  final LocalWorkoutSession session;
  final List<SessionExerciseState> exercises;

  WorkoutActive copyWith({
    LocalWorkoutSession? session,
    List<SessionExerciseState>? exercises,
  }) => WorkoutActive(
    session: session ?? this.session,
    exercises: exercises ?? this.exercises,
  );
}

final class WorkoutFinishing extends WorkoutState {
  const WorkoutFinishing(this.session);
  final LocalWorkoutSession session;
}

final class WorkoutError extends WorkoutState {
  const WorkoutError(this.message);
  final String message;
}

class SessionExerciseState {
  const SessionExerciseState({required this.exercise, required this.sets});

  final LocalSessionExercise exercise;
  final List<LocalSetEntry> sets;

  int get xpEarned {
    var total = 0;
    for (final s in sets) {
      final reps = s.reps ?? 0;
      final raw = s.durationSeconds != null ? 5 : 5 + (reps ~/ 5);
      total += raw;
    }
    return total.clamp(0, 120);
  }
}

// ─── Workout notifier ─────────────────────────────────────────────────────────

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  WorkoutNotifier(this._ref) : super(const WorkoutIdle());

  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  Future<void> startSession({
    required String equipmentId,
    required String equipmentName,
    required String canonicalExerciseKey,
    String? canonicalExerciseName,
    bool isCardio = false,
  }) async {
    final user = _ref.read(currentUserProvider);
    final gymId = _ref.read(activeGymIdProvider);
    if (user == null || gymId == null) {
      state = const WorkoutError('No active gym or user');
      return;
    }

    state = const WorkoutStarting();
    try {
      // Safety guard: never create a second active session. If one already
      // exists (e.g. race condition on first launch), resume it instead.
      final existing = await _db.getActiveSession(gymId, user.id);
      if (existing != null) {
        await _reloadActiveState(existing.id);
        return;
      }

      final sessionId = _uuid.v4();
      final sessionIk = _uuid.v4();
      final now = DateTime.now();
      final dayAnchor =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _db.insertSession(
        LocalWorkoutSessionsCompanion.insert(
          id: sessionId,
          gymId: gymId,
          userId: user.id,
          equipmentId: equipmentId,
          sessionDayAnchor: dayAnchor,
          startedAt: now,
          syncStatus: const Value('local_saved'),
          idempotencyKey: sessionIk,
        ),
      );

      // Auto-add canonical exercise for fixed_machine and cardio
      if (canonicalExerciseKey.isNotEmpty) {
        final exerciseId = _uuid.v4();
        await _db.insertSessionExercise(
          LocalSessionExercisesCompanion.insert(
            id: exerciseId,
            sessionId: sessionId,
            gymId: gymId,
            exerciseKey: canonicalExerciseKey,
            displayName: canonicalExerciseName ?? canonicalExerciseKey,
            sortOrder: const Value(0),
          ),
        );
      }

      // Load initial state
      await _reloadActiveState(sessionId);
    } catch (e, st) {
      AppLogger.e('Failed to start session', e, st);
      state = WorkoutError(e.toString());
    }
  }

  Future<void> addExercise({
    required String exerciseKey,
    required String displayName,
    String? equipmentId,
    String? customExerciseId,
  }) async {
    final active = state;
    if (active is! WorkoutActive) return;

    final exerciseId = _uuid.v4();
    await _db.insertSessionExercise(
      LocalSessionExercisesCompanion.insert(
        id: exerciseId,
        sessionId: active.session.id,
        gymId: active.session.gymId,
        exerciseKey: exerciseKey,
        displayName: displayName,
        sortOrder: Value(active.exercises.length),
        equipmentId: Value(equipmentId),
        customExerciseId: Value(customExerciseId),
      ),
    );
    await _reloadActiveState(active.session.id);
  }

  Future<String> logSet({
    required String sessionExerciseId,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    String? notes,
  }) async {
    final active = state;
    if (active is! WorkoutActive) throw StateError('No active workout');

    final gymId = active.session.gymId;
    final exerciseState = active.exercises.firstWhere(
      (e) => e.exercise.id == sessionExerciseId,
    );
    final setNumber = exerciseState.sets.length + 1;
    final setId = _uuid.v4();
    final ik = _uuid.v4();

    await _db.insertSetEntry(
      LocalSetEntriesCompanion.insert(
        id: setId,
        sessionExerciseId: sessionExerciseId,
        gymId: gymId,
        setNumber: setNumber,
        // Treat 0 as "not entered" — matches the server-side CHECK (> 0) constraint.
        reps: Value(reps != null && reps > 0 ? reps : null),
        weightKg: Value(weightKg),
        durationSeconds: Value(
          durationSeconds != null && durationSeconds > 0
              ? durationSeconds
              : null,
        ),
        distanceMeters: Value(
          distanceMeters != null && distanceMeters > 0 ? distanceMeters : null,
        ),
        notes: Value(notes),
        syncStatus: const Value('local_saved'),
        loggedAt: Value(DateTime.now()),
        idempotencyKey: ik,
      ),
    );

    // Heartbeat: upload in-progress session to Supabase immediately so the
    // set is durably backed up even before the user presses FINISH.
    // Fire-and-forget — data is already safe in SQLite regardless of outcome.
    unawaited(_ref.read(syncNotifierProvider.notifier).heartbeatActiveSession());

    // Update in-place for immediate UI feedback (< 150ms target)
    final newSets = [...exerciseState.sets];
    final newEntry = LocalSetEntry(
      id: setId,
      sessionExerciseId: sessionExerciseId,
      gymId: gymId,
      setNumber: setNumber,
      reps: reps != null && reps > 0 ? reps : null,
      weightKg: weightKg,
      durationSeconds: durationSeconds != null && durationSeconds > 0
          ? durationSeconds
          : null,
      distanceMeters: distanceMeters != null && distanceMeters > 0
          ? distanceMeters
          : null,
      notes: notes,
      syncStatus: 'local_saved',
      loggedAt: DateTime.now(),
      idempotencyKey: ik,
    );
    newSets.add(newEntry);

    final updatedExercises = active.exercises.map((e) {
      if (e.exercise.id == sessionExerciseId) {
        return SessionExerciseState(exercise: e.exercise, sets: newSets);
      }
      return e;
    }).toList();

    state = active.copyWith(exercises: updatedExercises);
    return setId;
  }

  Future<void> finishSession() async {
    final active = state;
    if (active is! WorkoutActive) return;

    state = WorkoutFinishing(active.session);
    try {
      final now = DateTime.now();
      await _db.finishSession(active.session.id, now);

      // Instantly refresh all local XP providers — the finished session is
      // already in SQLite so this is a zero-latency update.  Progress screen
      // XP Übersicht, heatmap, and recent sessions all update immediately
      // without waiting for the server sync.
      invalidateLocalXpProviders(_ref);

      // Kick off server sync in the background.  SyncNotifier will run a
      // second full invalidation (including server-side providers) once the
      // upload confirms — no restart or pull-to-refresh needed.
      unawaited(_ref.read(syncNotifierProvider.notifier).sync());

      // Workout is complete — clear the active-session anchor.
      await _ref
          .read(sharedPreferencesProvider)
          .remove(kActiveWorkoutSessionKey);
      state = const WorkoutIdle();
    } catch (e, st) {
      AppLogger.e('Failed to finish session', e, st);
      // Best-effort anchor cleanup even on error; the session is finished in
      // SQLite so keeping the key would cause a spurious resume on next start.
      unawaited(
        _ref.read(sharedPreferencesProvider).remove(kActiveWorkoutSessionKey),
      );
      state = const WorkoutIdle();
    }
  }

  /// Removes a single set from the active session.
  /// Applies an optimistic in-state update before persisting to DB.
  Future<void> deleteSet(String setId, String sessionExerciseId) async {
    final active = state;
    if (active is! WorkoutActive) return;

    final exerciseIdx = active.exercises.indexWhere(
      (e) => e.exercise.id == sessionExerciseId,
    );
    if (exerciseIdx == -1) return;

    final exerciseState = active.exercises[exerciseIdx];
    final newSets = exerciseState.sets.where((s) => s.id != setId).toList();
    final updated = List<SessionExerciseState>.from(active.exercises)
      ..[exerciseIdx] = SessionExerciseState(
        exercise: exerciseState.exercise,
        sets: newSets,
      );
    state = active.copyWith(exercises: updated);

    await _db.deleteSetEntry(setId);

    // Heartbeat after uncheck so the server snapshot reflects the deletion.
    unawaited(_ref.read(syncNotifierProvider.notifier).heartbeatActiveSession());
  }

  /// Removes an exercise and all its sets from the active session.
  Future<void> deleteExercise(String exerciseId) async {
    final active = state;
    if (active is! WorkoutActive) return;

    final newExercises = active.exercises
        .where((e) => e.exercise.id != exerciseId)
        .toList();
    state = active.copyWith(exercises: newExercises);

    await _db.deleteSessionExercise(exerciseId);

    // Heartbeat so the server snapshot stays in sync with local state.
    unawaited(_ref.read(syncNotifierProvider.notifier).heartbeatActiveSession());
  }

  /// Reorders exercises and persists the new sort order.
  Future<void> reorderExercises(int oldIndex, int newIndex) async {
    final active = state;
    if (active is! WorkoutActive) return;

    // ReorderableListView passes newIndex as if the item is already removed
    if (newIndex > oldIndex) newIndex -= 1;

    final exercises = List<SessionExerciseState>.from(active.exercises);
    final moved = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, moved);
    state = active.copyWith(exercises: exercises);

    await _db.updateExercisesSortOrders(
      exercises
          .asMap()
          .entries
          .map((e) => (id: e.value.exercise.id, sortOrder: e.key))
          .toList(),
    );
  }

  /// Permanently deletes ALL unfinished sessions for the current user/gym.
  /// Nothing is synced — data is gone without a trace.
  /// Deletes ALL active sessions (not just the one in state) so that orphan
  /// sessions from previous app runs are also cleaned up.
  Future<void> discardSession() async {
    final user = _ref.read(currentUserProvider);
    final gymId = _ref.read(activeGymIdProvider);
    if (user == null || gymId == null) return;

    try {
      await _db.discardAllActiveSessions(gymId, user.id);
    } catch (e, st) {
      AppLogger.e('Failed to discard session', e, st);
      return;
    }

    await _ref.read(sharedPreferencesProvider).remove(kActiveWorkoutSessionKey);
    state = const WorkoutIdle();
  }

  /// Creates a new session pre-populated with all exercises from [items].
  /// Uses 'freestyle' as the session equipment sentinel (multi-equipment session).
  Future<void> startPlanSession(List<LocalPlanItem> items) async {
    final user = _ref.read(currentUserProvider);
    final gymId = _ref.read(activeGymIdProvider);
    if (user == null || gymId == null) {
      state = const WorkoutError('No active gym or user');
      return;
    }

    state = const WorkoutStarting();
    try {
      final existing = await _db.getActiveSession(gymId, user.id);
      if (existing != null) {
        await _reloadActiveState(existing.id);
        return;
      }

      final sessionId = _uuid.v4();
      final sessionIk = _uuid.v4();
      final now = DateTime.now();
      final dayAnchor =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _db.insertSession(
        LocalWorkoutSessionsCompanion.insert(
          id: sessionId,
          gymId: gymId,
          userId: user.id,
          equipmentId: 'freestyle',
          sessionDayAnchor: dayAnchor,
          startedAt: now,
          syncStatus: const Value('local_saved'),
          idempotencyKey: sessionIk,
        ),
      );

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final exerciseKey =
            item.canonicalExerciseKey ??
            (item.customExerciseId != null
                ? 'custom:${item.customExerciseId}'
                : 'cardio:${item.equipmentId}');
        await _db.insertSessionExercise(
          LocalSessionExercisesCompanion.insert(
            id: _uuid.v4(),
            sessionId: sessionId,
            gymId: gymId,
            exerciseKey: exerciseKey,
            displayName: item.displayName,
            sortOrder: Value(i),
            equipmentId: Value(item.equipmentId),
            customExerciseId: Value(item.customExerciseId),
          ),
        );
      }

      await _reloadActiveState(sessionId);
    } catch (e, st) {
      AppLogger.e('Failed to start plan session', e, st);
      state = WorkoutError(e.toString());
    }
  }

  Future<void> resumeActiveSession() async {
    // Guard: don't re-enter if already resuming or if a workout is already active.
    if (state is WorkoutResuming || state is WorkoutActive) return;

    state = const WorkoutResuming();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      // Auth not yet resolved — caller is responsible for retrying.
      state = const WorkoutIdle();
      return;
    }

    // ── Priority 1: restore via the persisted session anchor ─────────────────
    //
    // This path works even when activeGymIdProvider is temporarily null —
    // e.g. after a transient Supabase signedOut event wiped the gym from
    // memory.  The session row in SQLite carries its gymId, so we can
    // restore both the session AND the active gym without any other context.
    //
    // This is the primary guard against mid-workout data loss.
    final prefs = _ref.read(sharedPreferencesProvider);
    final persistedId = prefs.getString(kActiveWorkoutSessionKey);
    if (persistedId != null) {
      final session = await _db.getSessionById(persistedId);
      if (session != null &&
          session.userId == user.id &&
          session.finishedAt == null) {
        // Restore the gym from the session row if it was wiped from memory.
        if (_ref.read(activeGymIdProvider) == null) {
          AppLogger.d(
            '[WORKOUT] gym was null — restoring from persisted session '
            '(gymId=${session.gymId})',
          );
          await _ref
              .read(activeGymIdProvider.notifier)
              .setActiveGym(session.gymId);
        }
        await _reloadActiveState(persistedId);
        await checkAndAutoFinishStaleSession();
        return;
      }
      // Stale anchor — session is finished or has been deleted.
      AppLogger.d('[WORKOUT] stale anchor $persistedId — removing');
      await prefs.remove(kActiveWorkoutSessionKey);
    }

    // ── Priority 2: gym-scoped orphan scan (normal cold-start path) ──────────

    final gymId = _ref.read(activeGymIdProvider);
    if (gymId == null) {
      // Gym not yet resolved — caller will retry when activeGymIdProvider
      // emits a non-null value (listener in workoutProvider definition).
      state = const WorkoutIdle();
      return;
    }

    // Fetch ALL unfinished sessions (can accumulate from crashes or bugs).
    final allOrphans = await _db.getAllUnfinishedSessionsForUser(user.id);
    if (allOrphans.isEmpty) {
      state = const WorkoutIdle();
      return;
    }

    // Partition: sessions for the current gym vs other gyms.
    final currentGymSessions = allOrphans
        .where((s) => s.gymId == gymId)
        .toList();
    final otherGymSessions = allOrphans.where((s) => s.gymId != gymId).toList();

    // Discard OTHER-gym orphans only when they are EMPTY (no exercises).
    // Sessions that have exercise data are never deleted automatically —
    // data loss is always worse than a lingering orphan row.
    for (final s in otherGymSessions) {
      final exercises = await _db.getExercisesForSession(s.id);
      if (exercises.isEmpty) {
        await _db.deleteSessionCascade(s.id);
      } else {
        AppLogger.w(
          '[WORKOUT] Skipping deletion of non-empty other-gym orphan '
          '${s.id} (${exercises.length} exercises)',
        );
      }
    }

    if (currentGymSessions.isEmpty) {
      state = const WorkoutIdle();
      return;
    }

    // Keep the most recent session for the current gym.
    // Delete duplicates only if they are empty — same data-safety rule.
    for (int i = 1; i < currentGymSessions.length; i++) {
      final exercises = await _db.getExercisesForSession(
        currentGymSessions[i].id,
      );
      if (exercises.isEmpty) {
        await _db.deleteSessionCascade(currentGymSessions[i].id);
      }
    }

    await _reloadActiveState(currentGymSessions.first.id);

    // Run stale-session detection on cold start.
    await checkAndAutoFinishStaleSession();
  }

  // ─── Auto-save (stale-session detection) ──────────────────────────────────

  /// Checks whether the active workout session has gone stale and auto-finishes
  /// it if so. Called on two occasions:
  ///
  /// 1. **Foreground return** (`AppLifecycleState.resumed`) — via
  ///    [WorkoutLifecycleService]. Handles the "user forgets to press FINISH
  ///    then comes back later" case.
  ///
  /// 2. **Cold start** — at the end of [resumeActiveSession]. Handles the
  ///    "app was killed by the OS" case.
  ///
  /// **Staleness thresholds** (both configurable via the constants below):
  /// - Session has logged sets and the most recent set was >[_kStaleThreshold]
  ///   ago → auto-finish with `finishedAt = latestSetAt` (semantically correct:
  ///   the workout ended when the user last did something).
  /// - Session has NO logged sets and started >[_kEmptyAbandonThreshold] ago
  ///   → discard silently (user scanned equipment but logged nothing).
  ///
  /// Safe to call when no workout is active — the [WorkoutActive] guard makes
  /// it a guaranteed no-op in that case.
  Future<void> checkAndAutoFinishStaleSession() async {
    final active = state;
    if (active is! WorkoutActive) return;

    final now = DateTime.now();
    final totalSets = active.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.length,
    );

    if (totalSets == 0) {
      // No committed sets. If the session has been open for more than the
      // abandon threshold, the user clearly walked away without doing anything.
      final sessionAge = now.difference(active.session.startedAt);
      if (sessionAge > _kEmptyAbandonThreshold) {
        AppLogger.d(
          '[WORKOUT] stale empty session '
          '(${sessionAge.inMinutes}min old) → discarding',
        );
        await discardSession();
      }
      return;
    }

    // Session has data. Check how long ago the last set was logged.
    final latestSetAt = _getLatestSetTimestamp(active);
    if (latestSetAt == null) return; // Should not happen if totalSets > 0.

    final idleTime = now.difference(latestSetAt);
    if (idleTime <= _kStaleThreshold) {
      // User is still within an acceptable rest window — do nothing.
      AppLogger.d(
        '[WORKOUT] session not stale: last set ${idleTime.inMinutes}min ago '
        '(threshold: ${_kStaleThreshold.inHours}h)',
      );
      return;
    }

    AppLogger.d(
      '[WORKOUT] stale session: $totalSets sets, '
      'last activity ${idleTime.inMinutes}min ago → auto-finishing',
    );
    await _autoFinish(active, latestSetAt);
  }

  /// Returns the [loggedAt] timestamp of the most recently committed set
  /// across all exercises in [active], or null if no sets exist.
  ///
  /// Pure in-memory scan — no DB call needed because [_reloadActiveState]
  /// already populates [WorkoutActive.exercises] with all sets.
  DateTime? _getLatestSetTimestamp(WorkoutActive active) {
    DateTime? latest;
    for (final ex in active.exercises) {
      for (final s in ex.sets) {
        if (latest == null || s.loggedAt.isAfter(latest)) {
          latest = s.loggedAt;
        }
      }
    }
    return latest;
  }

  /// Finishes [session] with the given [finishedAt] timestamp and queues it
  /// for server sync. Transitions to [WorkoutIdle], which also clears the
  /// in-memory drafts via the [workoutDraftsProvider] listener.
  ///
  /// The [sessionDayAnchor] is immutable (set at session creation) so
  /// [finishedAt] can safely be after midnight without misattributing XP.
  Future<void> _autoFinish(WorkoutActive active, DateTime finishedAt) async {
    state = WorkoutFinishing(active.session);
    try {
      await _db.finishSession(active.session.id, finishedAt);

      // Refresh local XP providers immediately — the finished session is
      // already in SQLite so the progress screen updates without waiting
      // for the server sync to complete.
      invalidateLocalXpProviders(_ref);

      // Kick off server sync in the background.
      unawaited(_ref.read(syncNotifierProvider.notifier).sync());

      await _ref
          .read(sharedPreferencesProvider)
          .remove(kActiveWorkoutSessionKey);
      state = const WorkoutIdle();
      AppLogger.d(
        '[WORKOUT] auto-finish complete for session ${active.session.id}',
      );
    } catch (e, st) {
      AppLogger.e('Failed to auto-finish session', e, st);
      unawaited(
        _ref.read(sharedPreferencesProvider).remove(kActiveWorkoutSessionKey),
      );
      state = const WorkoutIdle();
    }
  }

  /// Sessions with logged sets idle for longer than this are considered
  /// abandoned and are auto-finished on the next foreground return or cold
  /// start. 2 hours covers the longest realistic rest between sets (including
  /// powerlifting protocols) while still catching "forgot to finish" cases.
  static const _kStaleThreshold = Duration(hours: 2);

  /// Empty sessions (no sets logged) started longer than this ago are
  /// discarded silently. 1 hour is generous — if the user scanned a machine
  /// but logged nothing for an hour, they clearly did not use it.
  static const _kEmptyAbandonThreshold = Duration(hours: 1);

  Future<void> _reloadActiveState(String sessionId) async {
    final db = _db;
    final session = await (db.select(
      db.localWorkoutSessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (session == null) {
      // Session no longer in SQLite — remove the stale anchor key so recovery
      // does not loop on a non-existent session on the next app start.
      unawaited(
        _ref.read(sharedPreferencesProvider).remove(kActiveWorkoutSessionKey),
      );
      state = const WorkoutIdle();
      return;
    }

    final exercises = await db.getExercisesForSession(sessionId);
    final exerciseStates = <SessionExerciseState>[];

    for (final exercise in exercises) {
      final sets = await db.getSetsForExercise(exercise.id);
      exerciseStates.add(SessionExerciseState(exercise: exercise, sets: sets));
    }

    // Persist the active session ID to SharedPreferences.  This anchor
    // survives auth blips, app kills, and Riverpod provider rebuilds.
    // ActiveGymNotifier.clear() reads this key to protect the gym ID on disk.
    await _ref
        .read(sharedPreferencesProvider)
        .setString(kActiveWorkoutSessionKey, sessionId);

    state = WorkoutActive(session: session, exercises: exerciseStates);
  }
}

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((
  ref,
) {
  final notifier = WorkoutNotifier(ref);

  // Attempt an immediate resume (may be a no-op if auth hasn't resolved yet).
  unawaited(notifier.resumeActiveSession());

  // Re-attempt resume whenever auth or the active gym first becomes available.
  // This handles hot-restart and cold-start races where currentUserProvider /
  // activeGymIdProvider return null on first read (stream not yet emitted).
  ref.listen(currentUserProvider, (prev, next) {
    if (prev == null && next != null) {
      unawaited(notifier.resumeActiveSession());
    }
  });

  ref.listen(activeGymIdProvider, (prev, next) {
    if (prev == null && next != null) {
      unawaited(notifier.resumeActiveSession());
    }
  });

  return notifier;
});

// ─── Focused exercise (scroll-to on duplicate tap) ───────────────────────────

/// Holds the sessionExerciseId that the active-workout screen should scroll
/// to and briefly highlight. Set when the user taps an exercise that is already
/// in the session. Cleared by [ActiveWorkoutScreen] after the animation.
final focusedExerciseIdProvider = StateProvider<String?>((ref) => null);

// ─── Previous-session sets (reference column) ─────────────────────────────────

typedef _PrevSetsArgs = ({
  String gymId,
  String userId,
  String exerciseKey,
  String currentSessionId,
});

/// Loads the sets from the most recent *finished* session that contains
/// [exerciseKey] for this user. Used to populate the PREV column.
final previousSetsProvider =
    FutureProvider.family<List<LocalSetEntry>, _PrevSetsArgs>(
      (ref, args) => ref
          .watch(appDatabaseProvider)
          .getLastCompletedSetsForExerciseKey(
            args.gymId,
            args.userId,
            args.exerciseKey,
            excludeSessionId: args.currentSessionId,
          ),
    );

// ─── Set stream for live updates in the active set logger ─────────────────────

final setsStreamProvider = StreamProvider.family<List<LocalSetEntry>, String>((
  ref,
  sessionExerciseId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSetsForExercise(sessionExerciseId);
});
