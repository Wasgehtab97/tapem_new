import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../../data/datasources/local/app_database.dart';
import '../../presentation/features/auth/providers/auth_provider.dart';
import '../../presentation/features/community/providers/community_provider.dart';
import '../../presentation/features/progress/providers/xp_provider.dart';
import 'database_service.dart';
import 'gym_service.dart';

// Re-export so that files importing sync_service.dart for appDatabaseProvider
// continue to work without any import-site changes.
export 'database_service.dart' show appDatabaseProvider;

// ─── Sync status ──────────────────────────────────────────────────────────────

enum SyncServiceState { idle, syncing, error }

class SyncStatus {
  const SyncStatus({
    required this.state,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  final SyncServiceState state;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  SyncStatus copyWith({
    SyncServiceState? state,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? lastError,
  }) => SyncStatus(
    state: state ?? this.state,
    pendingCount: pendingCount ?? this.pendingCount,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    lastError: lastError,
  );
}

// ─── Sync notifier ────────────────────────────────────────────────────────────

class SyncNotifier extends StateNotifier<SyncStatus> {
  SyncNotifier(this._ref)
    : super(const SyncStatus(state: SyncServiceState.idle));

  final Ref _ref;
  Timer? _periodicTimer;
  Timer? _heartbeatTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Guards against concurrent heartbeat uploads.
  bool _heartbeatInFlight = false;

  /// Minimum time between consecutive heartbeat calls triggered by set
  /// check/uncheck events. Prevents bursts when a user checks several sets
  /// in quick succession — in that case the first heartbeat uploads all sets
  /// and subsequent calls within the window are safely skipped.
  static const _kHeartbeatMinInterval = Duration(seconds: 30);

  /// Interval for the periodic heartbeat fallback timer.
  static const _kHeartbeatPeriod = Duration(minutes: 5);

  /// After a 401 we back off for this long before retrying sync_failed sessions.
  /// 60 seconds is enough to prevent log spam while keeping recovery fast.
  static const _kAuthFailureCooldown = Duration(seconds: 60);

  DateTime? _lastHeartbeatAt;

  /// Set when sync is aborted due to a 401. Cleared on successful sync or
  /// when the Supabase auth state changes (new login).
  DateTime? _lastAuthFailureAt;

  void start() {
    _periodicTimer?.cancel();

    // 30-second fallback timer — only relevant for retrying sync_failed sessions
    // or sessions that missed their event-driven sync (e.g. app was offline).
    // Primary triggers: WorkoutNotifier.finishSession() (event-driven) and the
    // connectivity listener below (coming-online trigger).
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(sync()),
    );

    // 5-minute heartbeat fallback: uploads the current in-progress session as
    // a draft to Supabase even if the user never presses FINISH. This ensures
    // that checked sets reach the server periodically, so a lost/stolen device
    // loses at most 5 minutes of confirmed workout data.
    // Primary trigger: WorkoutNotifier.logSet / deleteSet (event-driven).
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _kHeartbeatPeriod,
      (_) => unawaited(heartbeatActiveSession()),
    );

    // Trigger sync immediately whenever the device comes back online.
    // This is the most reliable catch for "finished workout while offline" cases.
    unawaited(_connectivitySub?.cancel());
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        debugPrint('[SYNC] connectivity restored — triggering sync');
        unawaited(sync());
        // Also heartbeat on reconnect: picks up sets logged while offline.
        unawaited(heartbeatActiveSession());
      }
    });

    // Reset the auth-failure cooldown whenever the user signs in, so that
    // sync_failed sessions are retried immediately after a fresh login.
    final client = _ref.read(supabaseClientProvider);
    client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _lastAuthFailureAt = null;
        unawaited(sync());
      }
    });

    // Immediate sync on startup.
    unawaited(sync());
  }

  void stop() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    unawaited(_connectivitySub?.cancel());
    _connectivitySub = null;
  }

  /// Returns a valid Supabase access token.
  ///
  /// Uses the current session token when it has more than 5 minutes of
  /// validity remaining — no network call needed, no auth state events fired.
  /// Only calls [refreshSession] when the token is near expiry, preventing
  /// unnecessary [AuthChangeEvent.tokenRefreshed] emissions that would cause
  /// every [currentUserProvider] dependent to rebuild with a loading spinner.
  Future<String?> _getAccessToken(SupabaseClient client) async {
    final current = client.auth.currentSession;
    if (current == null) {
      debugPrint('[SYNC] no usable token — skipping sync');
      return null;
    }

    final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresAt = current.expiresAt ?? 0;

    // Token valid for more than 5 min — use it directly, no refresh needed.
    if (expiresAt - nowSecs > 300) {
      return current.accessToken;
    }

    // Token near expiry — refresh it.
    try {
      final refreshed = await client.auth.refreshSession();
      if (refreshed.session?.accessToken != null) {
        return refreshed.session!.accessToken;
      }
    } catch (e) {
      debugPrint('[SYNC] refreshSession failed: $e — trying current session');
    }

    // Fallback: use current token if still technically valid.
    if (expiresAt > nowSecs) {
      debugPrint('[SYNC] using current session token as fallback');
      return current.accessToken;
    }

    debugPrint('[SYNC] no usable token — skipping sync');
    return null;
  }

  /// Syncs all locally-finished, not-yet-confirmed sessions to Supabase.
  ///
  /// Re-entrant guard: if a sync is already in progress, this is a no-op.
  ///
  /// Provider invalidation: only triggered when at least one session was
  /// actually uploaded. Idle timer ticks (nothing pending) produce zero reads.
  Future<void> sync() async {
    if (state.state == SyncServiceState.syncing) return;

    // Back off after a 401 — avoids log spam when the refresh token is also
    // expired. Cleared on successful sync or when the user signs in again.
    final authFailure = _lastAuthFailureAt;
    if (authFailure != null &&
        DateTime.now().difference(authFailure) < _kAuthFailureCooldown) {
      return;
    }

    final user = _ref.read(currentUserProvider);
    final gymId = _ref.read(activeGymIdProvider);
    if (user == null || gymId == null) {
      debugPrint('[SYNC] skipped — user=${user?.id} gymId=$gymId');
      return;
    }

    final client = _ref.read(supabaseClientProvider);
    final accessToken = await _getAccessToken(client);
    if (accessToken == null) {
      debugPrint('[SYNC] skipped — could not obtain access token');
      return;
    }

    final db = _ref.read(appDatabaseProvider);
    final pending = await db.getPendingSessions(userId: user.id);

    if (pending.isEmpty) {
      state = state.copyWith(
        state: SyncServiceState.idle,
        pendingCount: 0,
        lastSyncedAt: DateTime.now(),
      );
      return;
    }

    debugPrint('[SYNC] ${pending.length} session(s) pending — syncing...');
    state = state.copyWith(
      state: SyncServiceState.syncing,
      pendingCount: pending.length,
    );

    int syncedCount = 0;
    String? lastErr;
    for (final session in pending) {
      try {
        debugPrint(
          '[SYNC] syncing session ${session.id} (${session.syncStatus})',
        );
        await _syncSession(session, db, client, accessToken);
        syncedCount++;
        _lastAuthFailureAt = null;
        debugPrint('[SYNC] ✓ session ${session.id} confirmed');
      } catch (e, st) {
        final msg = e.toString();
        // 401 means our JWT is invalid — force a refresh and abort this sync
        // cycle without touching session status. The 30-second timer will retry
        // once the token is valid again.
        if (e is FunctionException && e.status == 401) {
          debugPrint('[SYNC] 401 — backing off for ${_kAuthFailureCooldown.inMinutes}m');
          _lastAuthFailureAt = DateTime.now();
          unawaited(client.auth.refreshSession().catchError((_) {}));
          lastErr = msg;
          break;
        }
        debugPrint('[SYNC] ✗ session ${session.id} failed: $msg');
        AppLogger.e('Sync failed for session ${session.id}', e, st);
        await db.updateSessionSyncStatus(session.id, 'sync_failed');
        lastErr = msg;
      }
    }

    final remaining = await db.getPendingSessions(userId: user.id);
    state = state.copyWith(
      state: SyncServiceState.idle,
      pendingCount: remaining.length,
      lastSyncedAt: DateTime.now(),
      lastError: lastErr,
    );

    // Only invalidate caches when data actually changed on the server.
    // An idle timer tick with no pending sessions never reaches this point
    // (early return above). A tick with pending sessions that all failed
    // also skips this block — no point refreshing data that didn't change.
    if (syncedCount > 0) {
      // Local SQLite providers (training-day XP, equipment XP, heatmap,
      // recent sessions) — server may have corrected or de-duped entries.
      // localXpBaseProvider cascades to userGymXpProvider + userExerciseXpProvider.
      invalidateLocalXpProviders(_ref);
      // Server-side providers — now contain the newly-uploaded session.
      _ref.invalidate(userMuscleGroupXpProvider);
      _ref.invalidate(gymLeaderboardProvider);
      _ref.invalidate(gymEquipmentOverviewProvider);
      _ref.invalidate(gymTrainingDayRankingProvider);
      _ref.invalidate(gymEquipmentRankingProvider);
    }
  }

  /// Uploads the current in-progress session to Supabase as a draft snapshot.
  ///
  /// Fired after every set check/uncheck in [WorkoutNotifier] and by the
  /// 5-minute periodic fallback timer. Ensures that SQLite-confirmed sets
  /// reach the server even when the user never presses FINISH (e.g. device
  /// lost or stolen).
  ///
  /// **Silent failure**: any network or server error is logged and swallowed —
  /// the data is already durable in SQLite and will be re-uploaded on the next
  /// trigger or when the session is eventually finished.
  ///
  /// **Debounce**: calls within [_kHeartbeatMinInterval] of the previous
  /// successful (or attempted) upload are skipped. The snapshot is always
  /// complete, so the first call in a burst captures all sets.
  ///
  /// **No sync-status mutation**: the SQLite session row keeps its
  /// `local_saved` status. The full sync (triggered on FINISH) is responsible
  /// for setting `sync_confirmed` and processing XP.
  Future<void> heartbeatActiveSession() async {
    // Don't compete with an in-flight full sync or another heartbeat.
    if (state.state == SyncServiceState.syncing) return;
    if (_heartbeatInFlight) return;

    // Debounce: skip if a heartbeat ran recently (burst protection).
    final now = DateTime.now();
    if (_lastHeartbeatAt != null &&
        now.difference(_lastHeartbeatAt!) < _kHeartbeatMinInterval) {
      return;
    }

    final user = _ref.read(currentUserProvider);
    final gymId = _ref.read(activeGymIdProvider);
    if (user == null || gymId == null) return;

    final db = _ref.read(appDatabaseProvider);
    final session = await db.getActiveSession(gymId, user.id);
    if (session == null) return; // no active session

    // Only upload when there is at least one persisted set — no point
    // heartbeating an empty session that has nothing new on the server.
    final exercises = await db.getExercisesForSession(session.id);
    if (exercises.isEmpty) return;

    var hasSets = false;
    for (final ex in exercises) {
      final sets = await db.getSetsForExercise(ex.id);
      if (sets.isNotEmpty) {
        hasSets = true;
        break;
      }
    }
    if (!hasSets) return;

    final client = _ref.read(supabaseClientProvider);
    final accessToken = await _getAccessToken(client);
    if (accessToken == null) return; // offline or not logged in

    _heartbeatInFlight = true;
    _lastHeartbeatAt = DateTime.now();
    try {
      await _syncSession(session, db, client, accessToken, isDraft: true);
      debugPrint('[HEARTBEAT] ✓ session ${session.id} draft synced to Supabase');
    } catch (e) {
      // Silent: data is safe in SQLite; next heartbeat or FINISH will retry.
      debugPrint('[HEARTBEAT] ✗ session ${session.id}: $e');
    } finally {
      _heartbeatInFlight = false;
    }
  }

  /// Uploads a single session (exercises + sets) to [sync-workout].
  ///
  /// Passes [accessToken] explicitly in the Authorization header — never relies
  /// on the FunctionsClient's internal auth state, which may lag behind the
  /// actual session after app startup or user change.
  ///
  /// The Edge Function is idempotent: re-uploading an already-persisted session
  /// is always safe. On a non-200 response an exception is thrown so the caller
  /// can handle it appropriately.
  ///
  /// When [isDraft] is true the session is in-progress (`finished_at` is null):
  /// the edge function upserts the data but skips XP processing, and this
  /// method does NOT update the local [syncStatus] (the session is still open).
  Future<void> _syncSession(
    LocalWorkoutSession session,
    AppDatabase db,
    SupabaseClient client,
    String accessToken, {
    bool isDraft = false,
  }) async {
    final exercises = await db.getExercisesForSession(session.id);
    debugPrint(
      '[SYNC] session ${session.id}: gymId=${session.gymId} userId=${session.userId} ${exercises.length} exercises, finishedAt=${session.finishedAt}',
    );
    final exercisePayload = <Map<String, dynamic>>[];

    for (final exercise in exercises) {
      final sets = await db.getSetsForExercise(exercise.id);

      // Include muscle group assignments for custom exercises so the edge
      // function can compute muscle-group XP without an extra DB lookup.
      List<Map<String, String>>? customMuscleGroups;
      if (exercise.customExerciseId != null) {
        final mgRows =
            await db.getCustomExerciseMuscleGroups(exercise.customExerciseId!);
        if (mgRows.isNotEmpty) {
          customMuscleGroups = mgRows
              .map((mg) => {'muscle_group': mg.muscleGroup, 'role': mg.role})
              .toList();
        }
      }

      exercisePayload.add({
        'session_exercise_id': exercise.id,
        'exercise_key': exercise.exerciseKey,
        'display_name': exercise.displayName,
        'sort_order': exercise.sortOrder,
        'custom_exercise_id': exercise.customExerciseId,
        'equipment_id': exercise.equipmentId,
        if (customMuscleGroups != null)
          'custom_muscle_groups': customMuscleGroups,
        'sets': sets
            .map(
              (s) => {
                'set_entry_id': s.id,
                'set_number': s.setNumber,
                'reps': s.reps,
                'weight_kg': s.weightKg,
                'duration_seconds': s.durationSeconds,
                'distance_meters': s.distanceMeters,
                'idempotency_key': s.idempotencyKey,
              },
            )
            .toList(),
      });
    }

    final response = await client.functions.invoke(
      'sync-workout',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {
        'request_id': session.idempotencyKey,
        'session': {
          'id': session.id,
          'gym_id': session.gymId,
          'user_id': session.userId,
          'equipment_id': session.equipmentId,
          'session_day_anchor': session.sessionDayAnchor,
          'started_at': session.startedAt.toIso8601String(),
          'finished_at': session.finishedAt?.toIso8601String(),
          'idempotency_key': session.idempotencyKey,
          'notes': session.notes,
        },
        'exercises': exercisePayload,
      },
    );

    debugPrint('[SYNC] edge fn response: HTTP ${response.status}');
    if (response.status == 200) {
      // For draft heartbeats the session is still open — do NOT mark it
      // sync_confirmed. That status transition belongs to the full sync
      // triggered on FINISH, which also processes XP.
      if (!isDraft) {
        await db.updateSessionSyncStatus(session.id, 'sync_confirmed');
      }
    } else {
      final detail = response.data is String
          ? response.data as String
          : jsonEncode(response.data);
      debugPrint('[SYNC] edge fn error body: $detail');
      throw Exception('sync-workout HTTP ${response.status}: $detail');
    }
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _heartbeatTimer?.cancel();
    unawaited(_connectivitySub?.cancel());
    super.dispose();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncStatus>((
  ref,
) {
  final notifier = SyncNotifier(ref);
  notifier.start();
  return notifier;
});
