import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/xp_rules.dart';
import '../../../../data/datasources/local/app_database.dart';
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

  final String muscleGroup;
  final int totalXp;
  final int currentLevel;
}

final userMuscleGroupXpProvider = FutureProvider<List<MuscleGroupXp>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('user_muscle_group_xp')
      .select()
      .eq('user_id', user.id)
      .eq('gym_id', gymId)
      .order('total_xp', ascending: false);

  final typedRows = (rows as List)
      .whereType<Map<dynamic, dynamic>>()
      .map((row) => Map<String, Object?>.from(row))
      .toList(growable: false);

  return typedRows
      .map(
        (r) => MuscleGroupXp(
          muscleGroup: r['muscle_group'] as String,
          totalXp: r['total_xp'] as int? ?? 0,
          currentLevel: r['current_level'] as int? ?? 1,
        ),
      )
      .toList();
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

  final client = ref.watch(supabaseClientProvider);
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

  return {for (final row in typedRows) row['session_day_anchor'] as String};
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
  final sessions = await db.getRecentSessions(gymId, user.id);

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
});

// ─── Session detail (exercises + sets + progress comparison) ──────────────────

class ExerciseWithSets {
  const ExerciseWithSets({
    required this.displayName,
    required this.sets,
    required this.previousSets,
  });

  final String displayName;
  final List<LocalSetEntry> sets;

  /// Sets from the most recent finished session for this exercise that
  /// pre-dates the session being viewed.  Empty on a user's first session
  /// for this exercise.
  final List<LocalSetEntry> previousSets;

  bool get isFirstTime => previousSets.isEmpty;
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
      final result = <ExerciseWithSets>[];
      for (final exercise in exercises) {
        final sets = await db.getSetsForExercise(exercise.id);
        final previousSets = await db.getLastCompletedSetsForExerciseKey(
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
          ),
        );
      }
      return result;
    });
