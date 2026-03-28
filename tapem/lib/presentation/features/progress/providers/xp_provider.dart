import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/services/database_service.dart';
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

/// Computes both XP axes from local SQLite in one pass.
///
/// Training-Days axis: unique calendar days × [XpRules.trainingDayBase].
/// Exercise axis: per-equipment-id, one flat award of
/// [XpRules.exerciseSessionBase] per (session, exercise) pair.
///
/// For exercises recorded before schema v3 (equipmentId == null), the
/// exerciseKey itself is used as the grouping key so no history is lost.
///
/// Public so it can be invalidated by [invalidateLocalXpProviders] from
/// outside this file (e.g. [SyncNotifier] after a successful upload).
final localXpBaseProvider = FutureProvider<_LocalXpBase>((ref) async {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) {
    return (trainingDayXp: 0, equipmentXpMap: <String, _EquipmentEntry>{});
  }

  final db = ref.watch(appDatabaseProvider);

  // Build equipment-id → display-name map from local cache (no network call).
  final cachedEquipment = await db.getEquipmentForGym(gymId);
  final equipNameMap = <String, String>{
    for (final e in cachedEquipment) e.id: e.name,
  };

  final sessions = await db.getRecentSessions(gymId, user.id, limit: 1000);

  // ── Training-Days XP ──────────────────────────────────────────────────────
  final uniqueDays = {for (final s in sessions) s.sessionDayAnchor};
  final trainingDayXp = uniqueDays.length * XpRules.trainingDayBase;

  // ── Per-Equipment XP ──────────────────────────────────────────────────────
  final equipmentXpMap = <String, _EquipmentEntry>{};

  for (final session in sessions) {
    final exercises = await db.getExercisesForSession(session.id);

    for (final exercise in exercises) {
      // Resolve the grouping key and a human-readable name.
      final String key;
      final String name;

      if (exercise.equipmentId != null) {
        // v3+ data: authoritative equipment ID stored on the exercise row.
        key = exercise.equipmentId!;
        name = equipNameMap[key] ?? exercise.displayName;
      } else if (exercise.exerciseKey.startsWith('cardio:')) {
        // Legacy cardio: key encoded in exerciseKey as "cardio:{equipmentId}".
        key = exercise.exerciseKey.substring(7);
        name = equipNameMap[key] ?? exercise.displayName;
      } else {
        // Legacy fixed-machine or open-station: group by exerciseKey and use
        // the stored display name as label.
        key = exercise.exerciseKey;
        name = exercise.displayName;
      }

      final prev = equipmentXpMap[key];
      equipmentXpMap[key] = (
        // Keep the first name we resolved — avoids display flicker if the same
        // key appears with slightly different display names across sessions.
        name: prev?.name ?? name,
        xp: (prev?.xp ?? 0) + XpRules.exerciseSessionBase,
      );
    }
  }

  return (trainingDayXp: trainingDayXp, equipmentXpMap: equipmentXpMap);
});

// ─── Training-Days XP (global gym-level) ──────────────────────────────────────

final userGymXpProvider = FutureProvider<UserGymXp?>((ref) async {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) return null;

  final base = await ref.watch(localXpBaseProvider.future);
  if (base.trainingDayXp > 0) {
    // Local SQLite has data — fast path, works offline + immediate post-workout.
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
  }

  // Local empty (fresh install / reinstall) — fall back to Supabase.
  try {
    final client = ref.watch(supabaseClientProvider);
    final row = await client
        .from('user_gym_xp')
        .select('total_xp, current_level, xp_to_next_level, updated_at')
        .eq('user_id', user.id)
        .eq('gym_id', gymId)
        .maybeSingle();
    if (row == null) return null;
    final totalXp = (row['total_xp'] as num?)?.toInt() ?? 0;
    if (totalXp == 0) return null;
    return UserGymXp(
      userId: user.id,
      gymId: gymId,
      totalXp: totalXp,
      currentLevel: XpRules.levelFromXp(totalXp, XpRules.trainingDayXpPerLevel),
      xpToNextLevel: XpRules.xpToNextLevel(totalXp, XpRules.trainingDayXpPerLevel),
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  } catch (_) {
    return null;
  }
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

  if (base.equipmentXpMap.isNotEmpty) {
    // Local SQLite has data — fast path.
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
  }

  // Local empty — fall back to Supabase user_exercise_xp.
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) return [];

  try {
    final client = ref.watch(supabaseClientProvider);

    // Fetch XP rows and custom-exercise names in parallel.
    final results = await Future.wait([
      client
          .from('user_exercise_xp')
          .select('exercise_key, total_xp, current_level')
          .eq('user_id', user.id)
          .eq('gym_id', gymId)
          .order('total_xp', ascending: false),
      client
          .from('user_custom_exercises')
          .select('id, display_name')
          .eq('user_id', user.id),
    ]);

    final rows = results[0] as List;
    final customRows = results[1] as List;

    // custom_exercise_id → display_name (user-created exercise names).
    final customNameMap = <String, String>{
      for (final row in customRows)
        '${row['id']}': '${row['display_name'] ?? ''}',
    };

    // Best-effort name resolution from local equipment cache.
    final db = ref.watch(appDatabaseProvider);
    final cachedEquipment = await db.getEquipmentForGym(gymId);
    final equipNameMap = {for (final e in cachedEquipment) e.id: e.name};

    return rows
        .map((row) {
          final r = Map<String, Object?>.from(row as Map);
          final key = r['exercise_key'] as String? ?? '';
          final xp = (r['total_xp'] as num?)?.toInt() ?? 0;
          if (xp == 0) return null;
          return ExerciseXp(
            label: _resolveExerciseLabel(key, equipNameMap, customNameMap),
            equipmentKey: key,
            totalXp: xp,
            currentLevel: (r['current_level'] as num?)?.toInt() ?? 1,
          );
        })
        .whereType<ExerciseXp>()
        .toList();
  } catch (_) {
    return [];
  }
});

/// Resolves a human-readable label for an [exerciseKey].
///
/// Priority (for custom:UUID keys): user_custom_exercises name →
///   local equipment cache → raw key.
/// Priority (for regular keys): local equipment cache → snake_case humanisation.
String _resolveExerciseLabel(
  String key,
  Map<String, String> equipNameMap, [
  Map<String, String> customNameMap = const {},
]) {
  if (key.startsWith('custom:')) {
    final id = key.substring(7);
    return customNameMap[id] ?? equipNameMap[id] ?? key;
  }
  if (equipNameMap.containsKey(key)) return equipNameMap[key]!;
  // snake_case → Title Case fallback (e.g. "bench_press" → "Bench Press").
  return key
      .split('_')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

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

/// Invalidates all locally-computed XP providers so they re-read from SQLite.
///
/// Call this immediately after a workout session is finished (data already in
/// SQLite → instant refresh) AND after a successful server sync (picks up any
/// server-side corrections).
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
// Reads from Supabase rather than local SQLite so that:
//   • seeded / historical sessions are visible even on a fresh install
//   • the calendar works correctly across devices
//   • navigating to past years (via year picker in _CalendarCard) always works
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
  final sessions = await db.getRecentSessions(gymId, user.id, limit: 20);

  if (sessions.isNotEmpty) {
    // Local SQLite has data — read full detail (exercises + sets).
    final summaries = <SessionSummary>[];
    for (final session in sessions) {
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
    return summaries;
  }

  // Local empty (reinstall / fresh install) — fall back to Supabase.
  // session_exercises.display_name is synced by sync-workout, so names are available.
  try {
    final client = ref.watch(supabaseClientProvider);
    final rows = await client
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

    return (rows as List).map((row) {
      final r = Map<String, Object?>.from(row as Map);
      final exercises =
          ((r['session_exercises'] as List?) ?? [])
              .cast<Map<dynamic, dynamic>>()
              .map((e) => Map<String, Object?>.from(e))
              .toList()
            ..sort(
              (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
                (b['sort_order'] as num?) ?? 0,
              ),
            );
      final exerciseNames = exercises
          .map((e) => e['display_name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      var totalSets = 0;
      for (final ex in exercises) {
        totalSets += ((ex['set_entries'] as List?) ?? []).length;
      }
      return SessionSummary(
        id: r['id'] as String,
        sessionDayAnchor: r['session_day_anchor'] as String? ?? '',
        startedAt: DateTime.parse(r['started_at'] as String),
        finishedAt: r['finished_at'] != null
            ? DateTime.parse(r['finished_at'] as String)
            : null,
        exerciseNames: exerciseNames,
        totalSets: totalSets,
      );
    }).toList();
  } catch (_) {
    return [];
  }
});

/// Loads **all** finished sessions for the current user without any limit.
/// Used by the "all sessions" sheet. [recentSessionsProvider] keeps its own
/// small limit (20) for the progress-screen card preview.
final allSessionsProvider = FutureProvider<List<SessionSummary>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) return [];

  final db = ref.watch(appDatabaseProvider);
  final sessions = await db.getRecentSessions(gymId, user.id); // no limit

  if (sessions.isNotEmpty) {
    final summaries = <SessionSummary>[];
    for (final session in sessions) {
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
    return summaries;
  }

  // Supabase fallback — no limit so the full history is returned.
  try {
    final client = ref.watch(supabaseClientProvider);
    final rows = await client
        .from('workout_sessions')
        .select(
          'id, started_at, finished_at, session_day_anchor, '
          'session_exercises(display_name, sort_order, set_entries(id))',
        )
        .eq('user_id', user.id)
        .eq('gym_id', gymId)
        .not('finished_at', 'is', null)
        .order('finished_at', ascending: false);

    return (rows as List).map((row) {
      final r = Map<String, Object?>.from(row as Map);
      final exercises =
          ((r['session_exercises'] as List?) ?? [])
              .cast<Map<dynamic, dynamic>>()
              .map((e) => Map<String, Object?>.from(e))
              .toList()
            ..sort(
              (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
                (b['sort_order'] as num?) ?? 0,
              ),
            );
      final exerciseNames = exercises
          .map((e) => e['display_name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      var totalSets = 0;
      for (final ex in exercises) {
        totalSets += ((ex['set_entries'] as List?) ?? []).length;
      }
      return SessionSummary(
        id: r['id'] as String,
        sessionDayAnchor: r['session_day_anchor'] as String? ?? '',
        startedAt: DateTime.parse(r['started_at'] as String),
        finishedAt: r['finished_at'] != null
            ? DateTime.parse(r['finished_at'] as String)
            : null,
        exerciseNames: exerciseNames,
        totalSets: totalSets,
      );
    }).toList();
  } catch (_) {
    return [];
  }
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
