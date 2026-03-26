import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/features/workout/providers/workout_provider.dart';
import '../../core/utils/logger.dart';
import 'sync_service.dart';

// ─── Workout lifecycle observer ───────────────────────────────────────────────

/// Observes [AppLifecycleState] changes and hooks them into the workout system.
///
/// **Why this exists**: Users forget to press FINISH after a workout. They
/// close the app, the OS suspends or kills the process, and the session stays
/// unfinished in SQLite forever — never synced to the server.
///
/// **Strategy**: Do NOT auto-finish when the app moves to the background
/// (`paused`). Users background the app constantly during a workout (lock
/// phone between sets, check messages). Finishing at that moment would
/// terminate an active session prematurely.
///
/// Instead, only check for staleness when the app **returns to the foreground**
/// (`resumed`). If the most recent set was logged >2 hours ago the workout is
/// considered abandoned and is auto-finished. The actual auto-finish logic and
/// thresholds live in [WorkoutNotifier.checkAndAutoFinishStaleSession].
///
/// Cold-start (app killed + reopened): handled separately in
/// [WorkoutNotifier.resumeActiveSession], which calls
/// [WorkoutNotifier.checkAndAutoFinishStaleSession] after reloading state.
class WorkoutLifecycleService with WidgetsBindingObserver {
  WorkoutLifecycleService(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    AppLogger.d('[LIFECYCLE] WorkoutLifecycleService registered');
  }

  final Ref _ref;

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLogger.d('[LIFECYCLE] WorkoutLifecycleService unregistered');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.d('[LIFECYCLE] state → $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App returned to foreground. Check if the in-memory workout has gone
        // stale while we were away and auto-finish it if so.
        unawaited(
          _ref.read(workoutProvider.notifier).checkAndAutoFinishStaleSession(),
        );
        // Trigger sync for any sessions that were queued while offline.
        unawaited(_ref.read(syncNotifierProvider.notifier).sync());
        // Upload the in-progress session draft — picks up any sets that were
        // checked while the device was offline during this background period.
        unawaited(
          _ref.read(syncNotifierProvider.notifier).heartbeatActiveSession(),
        );

      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // No action — data is already safe in SQLite. Staleness detection
        // happens on the next resume or cold start.
        break;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Keeps [WorkoutLifecycleService] alive for the entire app lifetime.
///
/// Must be watched from [TapemApp.build] alongside [syncNotifierProvider] so
/// that the [WidgetsBindingObserver] is registered immediately at app start
/// and never garbage-collected while the app is running.
final workoutLifecycleProvider = Provider<WorkoutLifecycleService>((ref) {
  final service = WorkoutLifecycleService(ref);
  ref.onDispose(service.dispose);
  return service;
});
