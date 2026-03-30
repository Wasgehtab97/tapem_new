import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/xp_rules.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../../domain/entities/gym/muscle_group.dart';
import '../../../../domain/entities/xp/xp_event.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../home/providers/streak_provider.dart';

// ─── Internal computation record ──────────────────────────────────────────────

typedef _EquipmentEntry = ({String name, int xp});

typedef _LocalXpBase = ({
  int trainingDayXp,
  Map<String, _EquipmentEntry> equipmentXpMap,
});

/// Computes both XP axes by merging local SQLite data with the Supabase
/// server state.  This ensures cross-device correctness: sessions tracked on
/// a previous device (or before a reinstall) that exist only on the server are
/// always included, as long as a network connection is available.
///
/// Training-days axis:
///   Authoritative value = user_gym_xp.total_xp (server — only aggregates real
///   xp_events, never inflated by calendar-only seed sessions).
///   Plus: locally-pending sessions whose day has not yet been confirmed by the
///   server (i.e. syncStatus != 'sync_confirmed' AND no confirmed session exists
///   for that same day already).
///   Offline fallback: unique local calendar days × XpRules.trainingDayBase.
///
/// Exercise/equipment axis:
///   Start from local SQLite exercises (instant, works offline).
///   Augment with server sessions whose IDs are absent from local SQLite —
///   seeded sessions (no exercises) contribute nothing.
///   Offline fallback: local-only map.
///
/// Public so it can be invalidated by [invalidateLocalXpProviders].
final localXpBaseProvider = FutureProvider<_LocalXpBase>((ref) async {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) {
    return (trainingDayXp: 0, equipmentXpMap: <String, _EquipmentEntry>{});
  }

  final db = ref.watch(appDatabaseProvider);
  final client = ref.watch(supabaseClientProvider);

  // Equipment name resolution from local cache (no network call).
  final cachedEquipment = await db.getEquipmentForGym(gymId);
  final equipNameMap = <String, String>{
    for (final e in cachedEquipment) e.id: e.name,
  };

  final localSessions = await db.getRecentSessions(gymId, user.id, limit: 1000);
  final localSessionIds = {for (final s in localSessions) s.id};

  // Split local sessions by sync status to identify which days are
  // already confirmed on the server vs. pending upload.
  final confirmedDays = <String>{};
  final pendingDays = <String>{};
  for (final s in localSessions) {
    if (s.syncStatus == 'sync_confirmed') {
      confirmedDays.add(s.sessionDayAnchor);
    } else {
      pendingDays.add(s.sessionDayAnchor);
    }
  }
  // Days that are ONLY in pending (no confirmed session for the same day).
  // These are not yet counted in user_gym_xp.total_xp on the server.
  final newPendingDays = pendingDays.difference(confirmedDays);

  // ── Equipment XP: local pass ──────────────────────────────────────────────
  final equipmentXpMap = <String, _EquipmentEntry>{};

  for (final session in localSessions) {
    final exercises = await db.getExercisesForSession(session.id);

    for (final exercise in exercises) {
      final String key;
      final String name;

      if (exercise.equipmentId != null) {
        key = exercise.equipmentId!;
        name = equipNameMap[key] ?? exercise.displayName;
      } else if (exercise.exerciseKey.startsWith('cardio:')) {
        key = exercise.exerciseKey.substring(7);
        name = equipNameMap[key] ?? exercise.displayName;
      } else {
        key = exercise.exerciseKey;
        name = exercise.displayName;
      }

      final prev = equipmentXpMap[key];
      equipmentXpMap[key] = (
        name: prev?.name ?? name,
        xp: (prev?.xp ?? 0) + XpRules.exerciseSessionBase,
      );
    }
  }

  // ── Augment from Supabase ─────────────────────────────────────────────────
  // Handles reinstall / device-switch: sessions confirmed on the server that
  // no longer exist in local SQLite are fetched and merged in.
  //
  // Two independent Supabase calls so that a failure in one does not block
  // the other.  Both are wrapped in try/catch for offline resilience.

  // 1. Training-day XP — server aggregate is the single source of truth.
  int? serverTrainingDayXp; // null = fetch failed (offline / error)
  try {
    final row = await client
        .from('user_gym_xp')
        .select('total_xp')
        .eq('user_id', user.id)
        .eq('gym_id', gymId)
        .maybeSingle();
    serverTrainingDayXp = (row?['total_xp'] as num?)?.toInt() ?? 0;
  } catch (_) {
    // Offline or auth error — will fall back to local count below.
  }

  // 2. Equipment XP — augment with server sessions absent from local SQLite.
  try {
    final remoteRows = await client
        .from('workout_sessions')
        .select(
          'id, session_exercises(exercise_key, display_name, equipment_id)',
        )
        .eq('user_id', user.id)
        .eq('gym_id', gymId)
        .not('finished_at', 'is', null);

    for (final row in (remoteRows as List)) {
      final r = Map<String, Object?>.from(row as Map);
      final sessionId = r['id'] as String;
      if (localSessionIds.contains(sessionId)) continue; // already counted above

      final exercises = ((r['session_exercises'] as List?) ?? [])
          .cast<Map<dynamic, dynamic>>()
          .map((e) => Map<String, Object?>.from(e))
          .toList();

      // Seeded / calendar-only sessions have no exercises — skip them so they
      // do not inflate the equipment XP map.
      if (exercises.isEmpty) continue;

      for (final ex in exercises) {
        final equipmentId = ex['equipment_id'] as String?;
        final exerciseKey = ex['exercise_key'] as String? ?? '';
        final displayName = ex['display_name'] as String? ?? '';

        final String key;
        final String name;
        if (equipmentId != null) {
          key = equipmentId;
          name = equipNameMap[key] ?? displayName;
        } else if (exerciseKey.startsWith('cardio:')) {
          key = exerciseKey.substring(7);
          name = equipNameMap[key] ?? displayName;
        } else {
          key = exerciseKey;
          name = displayName;
        }
        if (key.isEmpty) continue;

        final prev = equipmentXpMap[key];
        equipmentXpMap[key] = (
          name: prev?.name ?? name,
          xp: (prev?.xp ?? 0) + XpRules.exerciseSessionBase,
        );
      }
    }
  } catch (e, st) {
    AppLogger.e('[localXpBaseProvider] equipment augment from server failed', e, st);
  }

  // ── Final training-day XP ─────────────────────────────────────────────────
  final int trainingDayXp;
  if (serverTrainingDayXp != null) {
    // Online path: server-confirmed XP (cross-device, seeded-session-safe)
    // plus any locally-pending days not yet uploaded.
    trainingDayXp = serverTrainingDayXp +
        (newPendingDays.length * XpRules.trainingDayBase);
  } else {
    // Offline path: count unique days from local SQLite only.
    final allLocalDays = {
      ...confirmedDays,
      ...pendingDays,
    };
    trainingDayXp = allLocalDays.length * XpRules.trainingDayBase;
  }

  return (trainingDayXp: trainingDayXp, equipmentXpMap: equipmentXpMap);
});

// ─── Training-Days XP (global gym-level) ──────────────────────────────────────

final userGymXpProvider = FutureProvider<UserGymXp?>((ref) async {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) return null;

  final base = await ref.watch(localXpBaseProvider.future);
  if (base.trainingDayXp == 0) return null;

  return UserGymXp(
    userId: user.id,
    gymId: gymId,
    totalXp: base.trainingDayXp,
    currentLevel: XpRules.levelFromXp(
      base.trainingDayXp,
      XpRules.trainingDayXpPerLevel,
    ),
    xpToNextLevel: XpRules.xpToNextLevel(
      base.trainingDayXp,
      XpRules.trainingDayXpPerLevel,
    ),
    updatedAt: DateTime.now(),
  );
});

// ─── Per-equipment Exercise XP ────────────────────────────────────────────────

class ExerciseXp {
  const ExerciseXp({
    required this.label,
    required this.equipmentKey,
    required this.totalXp,
    required this.currentLevel,
  });

  /// Human-readable equipment name shown in the UI.
  final String label;

  /// The key used for grouping (equipmentId or exerciseKey fallback).
  final String equipmentKey;

  final int totalXp;
  final int currentLevel;
}

final userExerciseXpProvider = FutureProvider<List<ExerciseXp>>((ref) async {
  final base = await ref.watch(localXpBaseProvider.future);

  if (base.equipmentXpMap.isEmpty) return [];

  final sorted = base.equipmentXpMap.entries.toList()
    ..sort((a, b) => b.value.xp.compareTo(a.value.xp));
  return sorted.map((entry) {
    return ExerciseXp(
      label: entry.value.name,
      equipmentKey: entry.key,
      totalXp: entry.value.xp,
      currentLevel: XpRules.levelFromXp(
        entry.value.xp,
        XpRules.exerciseXpPerLevel,
      ),
    );
  }).toList();
});

// ─── Per-muscle-group XP (populated after server sync) ────────────────────────

class MuscleGroupXp {
  const MuscleGroupXp({
    required this.muscleGroup,
    required this.totalXp,
    required this.currentLevel,
  });

  /// DB key value (e.g. "chest", "upper_back").
  final String muscleGroup;

  /// Fractional total XP — NUMERIC(8,1) from Postgres (10.0 per primary, 2.5 per secondary).
  final double totalXp;

  /// 1-based level computed locally from [totalXp].
  final int currentLevel;

  /// Resolved [MuscleGroup] enum, or null for unrecognised legacy values.
  MuscleGroup? get muscleGroupEnum => MuscleGroup.tryFromValue(muscleGroup);
}

/// Returns XP for all 15 canonical muscle groups — always a complete list.
///
/// Muscle groups without any XP on the server are included with totalXp = 0.0
/// so the UI can show untrained groups (body map, "neglected" section) without
/// extra queries.
///
/// The list is sorted by [MuscleGroup.sortOrder] (anatomical top-to-bottom
/// ordering), NOT by XP descending, to keep the body map and bar chart stable.
final userMuscleGroupXpProvider = FutureProvider<List<MuscleGroupXp>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('user_muscle_group_xp')
      .select('muscle_group, total_xp')
      .eq('user_id', user.id)
      .eq('gym_id', gymId);

  // Build key → xp lookup from server rows (total_xp is NUMERIC → num in Dart).
  final serverXp = <String, double>{};
  for (final row in (rows as List)) {
    final r = Map<String, Object?>.from(row as Map);
    final mg = r['muscle_group'] as String?;
    if (mg != null) {
      serverXp[mg] = (r['total_xp'] as num?)?.toDouble() ?? 0.0;
    }
  }

  // Return all 15 canonical groups in sort order, filling in 0.0 for untrained.
  return MuscleGroup.sorted.map((mg) {
    final xp = serverXp[mg.value] ?? 0.0;
    return MuscleGroupXp(
      muscleGroup: mg.value,
      totalXp: xp,
      currentLevel: XpRules.levelFromXpDouble(xp, XpRules.muscleGroupXpPerLevel),
    );
  }).toList();
});

// ─── Invalidation helper ──────────────────────────────────────────────────────

/// Invalidates all locally-computed XP providers so they re-read from SQLite
/// and re-fetch from the server.
///
/// Call this immediately after a workout session is finished (data already in
/// SQLite → instant refresh) AND after a successful server sync (picks up any
/// server-side corrections or cross-device sessions).
///
/// [localXpBaseProvider] is watched by [userGymXpProvider] and
/// [userExerciseXpProvider] via `ref.watch`, so invalidating the base
/// automatically cascades to both dependents — no need to list them explicitly.
void invalidateLocalXpProviders(Ref ref) {
  ref.invalidate(localXpBaseProvider);
  ref.invalidate(trainingDaysProvider);
  ref.invalidate(recentSessionsProvider);
  ref.invalidate(streakProvider);
}

// ─── Training days (for calendar heatmap) ─────────────────────────────────────
//
// Reads from both local SQLite and Supabase so that:
//   • seeded / historical sessions are visible even on a fresh install
//   • the calendar works correctly across devices
//   • navigating to past years (via year picker in _CalendarCard) always works
//   • locally-saved sessions appear immediately without waiting for sync
//
// The query is scoped to a single calendar year via date-range filters and
// guarded by the existing RLS policy (user_id = auth.uid() AND membership).

final trainingDaysProvider = FutureProvider.family<Set<String>, int>((
  ref,
  year,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};

  // ── Local sessions (always available, even offline or before sync) ──────────
  // Includes sync_pending and sync_failed sessions so the calendar dot appears
  // immediately after finishing a workout without waiting for Supabase sync.
  final db = ref.watch(appDatabaseProvider);
  final localDays = await db.getLocalSessionDaysForYear(user.id, year);

  // ── Remote sessions (cross-device history) ──────────────────────────────────
  final client = ref.watch(supabaseClientProvider);
  try {
    final rows = await client
        .from('workout_sessions')
        .select('session_day_anchor')
        .eq('user_id', user.id)
        .gte('session_day_anchor', '$year-01-01')
        .lte('session_day_anchor', '$year-12-31');

    // PostgREST returns DATE columns as 'yyyy-MM-dd' strings — exactly the
    // format TrainingHeatmap and streak computation expect.
    final typedRows = (rows as List)
        .whereType<Map<dynamic, dynamic>>()
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
    final remoteDays = {
      for (final row in typedRows) row['session_day_anchor'] as String,
    };
    return {...localDays, ...remoteDays};
  } catch (_) {
    // Supabase unavailable (offline / auth failure) — local data is enough.
    return localDays;
  }
});

// ─── Recent sessions ──────────────────────────────────────────────────────────

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.sessionDayAnchor,
    required this.startedAt,
    required this.finishedAt,
    required this.exerciseNames,
    required this.totalSets,
  });

  final String id;
  final String sessionDayAnchor;
  final DateTime startedAt;
  final DateTime? finishedAt;

  /// Ordered list of exercise display names in this session.
  final List<String> exerciseNames;

  /// Total number of logged sets across all exercises in this session.
  final int totalSets;

  int get exerciseCount => exerciseNames.length;

  Duration? get duration => finishedAt?.difference(startedAt);
}

final recentSessionsProvider = FutureProvider<List<SessionSummary>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) return [];

  final db = ref.watch(appDatabaseProvider);
  final localSessions = await db.getRecentSessions(gymId, user.id, limit: 20);
  final localSessionIds = {for (final s in localSessions) s.id};

  // Build summaries from local SQLite — always the fast path.
  final summaries = <SessionSummary>[];
  for (final session in localSessions) {
    final exercises = await db.getExercisesForSession(session.id);
    var totalSets = 0;
    for (final exercise in exercises) {
      final sets = await db.getSetsForExercise(exercise.id);
      totalSets += sets.length;
    }
    summaries.add(
      SessionSummary(
        id: session.id,
        sessionDayAnchor: session.sessionDayAnchor,
        startedAt: session.startedAt,
        finishedAt: session.finishedAt,
        exerciseNames: exercises.map((e) => e.displayName).toList(),
        totalSets: totalSets,
      ),
    );
  }

  // Augment with server sessions not in local SQLite.
  // This surfaces sessions from other devices or before a reinstall.
  // Seeded / calendar-only sessions (no exercises) are silently skipped.
  try {
    final client = ref.watch(supabaseClientProvider);
    final remoteRows = await client
        .from('workout_sessions')
        .select(
          'id, started_at, finished_at, session_day_anchor, '
          'session_exercises(display_name, sort_order, set_entries(id))',
        )
        .eq('user_id', user.id)
        .eq('gym_id', gymId)
        .not('finished_at', 'is', null)
        .order('finished_at', ascending: false)
        .limit(20);

    for (final row in (remoteRows as List)) {
      final r = Map<String, Object?>.from(row as Map);
      final sessionId = r['id'] as String;
      if (localSessionIds.contains(sessionId)) continue;

      final exercises = ((r['session_exercises'] as List?) ?? [])
          .cast<Map<dynamic, dynamic>>()
          .map((e) => Map<String, Object?>.from(e))
          .toList()
        ..sort(
          (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
            (b['sort_order'] as num?) ?? 0,
          ),
        );

      // Skip seeded / placeholder sessions that have no exercises.
      if (exercises.isEmpty) continue;

      final exerciseNames = exercises
          .map((e) => e['display_name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      var totalSets = 0;
      for (final ex in exercises) {
        totalSets += ((ex['set_entries'] as List?) ?? []).length;
      }

      summaries.add(
        SessionSummary(
          id: sessionId,
          sessionDayAnchor: r['session_day_anchor'] as String? ?? '',
          startedAt: DateTime.parse(r['started_at'] as String),
          finishedAt: r['finished_at'] != null
              ? DateTime.parse(r['finished_at'] as String)
              : null,
          exerciseNames: exerciseNames,
          totalSets: totalSets,
        ),
      );
    }
  } catch (_) {
    // Network unavailable — local data is sufficient.
  }

  summaries.sort((a, b) {
    final cmp = b.startedAt.compareTo(a.startedAt);
    return cmp;
  });
  return summaries.take(20).toList();
});

/// Loads **all** finished sessions for the current user without any limit.
/// Used by the "all sessions" sheet. [recentSessionsProvider] keeps its own
/// small limit (20) for the progress-screen card preview.
final allSessionsProvider = FutureProvider<List<SessionSummary>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) return [];

  final db = ref.watch(appDatabaseProvider);
  final localSessions = await db.getRecentSessions(gymId, user.id); // no limit
  final localSessionIds = {for (final s in localSessions) s.id};

  final summaries = <SessionSummary>[];
  for (final session in localSessions) {
    final exercises = await db.getExercisesForSession(session.id);
    var totalSets = 0;
    for (final exercise in exercises) {
      final sets = await db.getSetsForExercise(exercise.id);
      totalSets += sets.length;
    }
    summaries.add(
      SessionSummary(
        id: session.id,
        sessionDayAnchor: session.sessionDayAnchor,
        startedAt: session.startedAt,
        finishedAt: session.finishedAt,
        exerciseNames: exercises.map((e) => e.displayName).toList(),
        totalSets: totalSets,
      ),
    );
  }

  // Augment with all server sessions not present in local SQLite.
  try {
    final client = ref.watch(supabaseClientProvider);
    final remoteRows = await client
        .from('workout_sessions')
        .select(
          'id, started_at, finished_at, session_day_anchor, '
          'session_exercises(display_name, sort_order, set_entries(id))',
        )
        .eq('user_id', user.id)
        .eq('gym_id', gymId)
        .not('finished_at', 'is', null)
        .order('finished_at', ascending: false);

    for (final row in (remoteRows as List)) {
      final r = Map<String, Object?>.from(row as Map);
      final sessionId = r['id'] as String;
      if (localSessionIds.contains(sessionId)) continue;

      final exercises = ((r['session_exercises'] as List?) ?? [])
          .cast<Map<dynamic, dynamic>>()
          .map((e) => Map<String, Object?>.from(e))
          .toList()
        ..sort(
          (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
            (b['sort_order'] as num?) ?? 0,
          ),
        );

      if (exercises.isEmpty) continue;

      final exerciseNames = exercises
          .map((e) => e['display_name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      var totalSets = 0;
      for (final ex in exercises) {
        totalSets += ((ex['set_entries'] as List?) ?? []).length;
      }

      summaries.add(
        SessionSummary(
          id: sessionId,
          sessionDayAnchor: r['session_day_anchor'] as String? ?? '',
          startedAt: DateTime.parse(r['started_at'] as String),
          finishedAt: r['finished_at'] != null
              ? DateTime.parse(r['finished_at'] as String)
              : null,
          exerciseNames: exerciseNames,
          totalSets: totalSets,
        ),
      );
    }
  } catch (_) {
    // Network unavailable — local data is sufficient.
  }

  summaries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  return summaries;
});

// ─── Session detail (exercises + sets + progress comparison) ──────────────────

class ExerciseWithSets {
  const ExerciseWithSets({
    required this.displayName,
    required this.sets,
    required this.previousSets,
    this.previousBestE1rm,
    this.previousBestVolume,
  });

  final String displayName;
  final List<LocalSetEntry> sets;

  /// Sets from the most recent finished session for this exercise that
  /// pre-dates the session being viewed.  Empty on a user's first session
  /// for this exercise.
  final List<LocalSetEntry> previousSets;

  /// All-time best e1RM (Epley) across every previous finished session.
  /// Null when there is no prior history or no strength sets in history.
  final double? previousBestE1rm;

  /// All-time best single-session volume (reps × weight_kg) across every
  /// previous finished session.  Null when there is no prior strength history.
  final double? previousBestVolume;

  bool get isFirstTime => previousSets.isEmpty;
}

/// Computes the best Epley e1RM across [sets]. Returns null if no strength
/// sets (with both reps and weight) are present.
double? _computeBestE1rm(List<LocalSetEntry> sets) {
  double? best;
  for (final s in sets) {
    final reps = s.reps;
    final weight = s.weightKg;
    if (reps == null || weight == null || reps <= 0 || weight <= 0) continue;
    final e1rm = weight * (1 + reps / 30.0);
    if (best == null || e1rm > best) best = e1rm;
  }
  return best;
}

/// Args for [sessionDetailProvider].  Named record so equality/hashCode work
/// correctly inside FutureProvider.family.
typedef SessionDetailArgs = ({String sessionId, String gymId, String userId});

final sessionDetailProvider =
    FutureProvider.family<List<ExerciseWithSets>, SessionDetailArgs>((
      ref,
      args,
    ) async {
      final db = ref.watch(appDatabaseProvider);
      final exercises = await db.getExercisesForSession(args.sessionId);

      if (exercises.isNotEmpty) {
        // Local SQLite path — full detail including previous-session comparison.
        final result = <ExerciseWithSets>[];
        for (final exercise in exercises) {
          final sets = await db.getSetsForExercise(exercise.id);
          final previousSets = await db.getLastCompletedSetsForExerciseKey(
            args.gymId,
            args.userId,
            exercise.exerciseKey,
            excludeSessionId: args.sessionId,
          );
          final allPreviousSets = await db.getAllCompletedSetsForExerciseKey(
            args.gymId,
            args.userId,
            exercise.exerciseKey,
            excludeSessionId: args.sessionId,
          );
          final previousBestVolume = await db.getBestVolumeForExerciseKey(
            args.gymId,
            args.userId,
            exercise.exerciseKey,
            excludeSessionId: args.sessionId,
          );
          result.add(
            ExerciseWithSets(
              displayName: exercise.displayName,
              sets: sets,
              previousSets: previousSets,
              previousBestE1rm: _computeBestE1rm(allPreviousSets),
              previousBestVolume: previousBestVolume,
            ),
          );
        }
        return result;
      }

      // Local empty (reinstall / fresh install) — fall back to Supabase.
      // previous-session comparison is skipped (no local history available).
      try {
        final client = ref.watch(supabaseClientProvider);
        final rows = await client
            .from('session_exercises')
            .select(
              'id, display_name, sort_order, gym_id, '
              'set_entries(id, set_number, reps, weight_kg, duration_seconds, '
              'distance_meters, notes, sync_status, logged_at, idempotency_key)',
            )
            .eq('session_id', args.sessionId)
            .order('sort_order', ascending: true);

        return (rows as List).map((row) {
          final r = Map<String, Object?>.from(row as Map);
          final exerciseId = r['id'] as String? ?? '';
          final gymId = r['gym_id'] as String? ?? args.gymId;
          final displayName = r['display_name'] as String? ?? '';

          final setsRaw =
              ((r['set_entries'] as List?) ?? [])
                  .cast<Map<dynamic, dynamic>>()
                  .map((s) => Map<String, Object?>.from(s))
                  .toList()
                ..sort(
                  (a, b) => ((a['set_number'] as num?) ?? 0).compareTo(
                    (b['set_number'] as num?) ?? 0,
                  ),
                );

          final localSets = setsRaw.map((s) {
            return LocalSetEntry(
              id: s['id'] as String? ?? '',
              sessionExerciseId: exerciseId,
              gymId: gymId,
              setNumber: (s['set_number'] as num?)?.toInt() ?? 0,
              reps: (s['reps'] as num?)?.toInt(),
              weightKg: (s['weight_kg'] as num?)?.toDouble(),
              durationSeconds: (s['duration_seconds'] as num?)?.toInt(),
              distanceMeters: (s['distance_meters'] as num?)?.toDouble(),
              notes: s['notes'] as String?,
              syncStatus: s['sync_status'] as String? ?? 'sync_confirmed',
              loggedAt:
                  DateTime.tryParse(s['logged_at'] as String? ?? '') ??
                  DateTime.now(),
              idempotencyKey: s['idempotency_key'] as String? ?? '',
            );
          }).toList();

          return ExerciseWithSets(
            displayName: displayName,
            sets: localSets,
            previousSets: const [],
            previousBestE1rm: null,
            previousBestVolume: null,
          );
        }).where((e) => e.displayName.isNotEmpty).toList();
      } catch (_) {
        return [];
      }
    });
