import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/xp_rules.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class EquipmentHistorySummary {
  const EquipmentHistorySummary({
    required this.sessionId,
    this.sessionExerciseId,
    this.exerciseName,
    required this.sessionDayAnchor,
    required this.startedAt,
    this.finishedAt,
    required this.setCount,
    required this.totalReps,
    required this.totalVolumeKg,
    required this.totalXp,
  });

  final String sessionId;
  final String? sessionExerciseId;
  final String? exerciseName;
  final String sessionDayAnchor;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int setCount;
  final int totalReps;
  final double totalVolumeKg;
  final int totalXp;

  Duration? get duration => finishedAt?.difference(startedAt);
}

class EquipmentHistoryDetail {
  const EquipmentHistoryDetail({
    required this.sessionId,
    required this.sessionDayAnchor,
    required this.startedAt,
    this.finishedAt,
    required this.exerciseName,
    required this.sets,
    required this.totalReps,
    required this.totalVolumeKg,
    required this.totalXp,
  });

  final String sessionId;
  final String sessionDayAnchor;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String exerciseName;
  final List<LocalSetEntry> sets;
  final int totalReps;
  final double totalVolumeKg;
  final int totalXp;

  int get setCount => sets.length;
  Duration? get duration => finishedAt?.difference(startedAt);
}

/// A custom exercise created by the user at an open station.
class CustomExerciseSummary {
  const CustomExerciseSummary({required this.exerciseKey, required this.name});

  final String exerciseKey; // 'custom:{id}'
  final String name;
}

class EquipmentRankingEntry {
  const EquipmentRankingEntry({
    required this.rank,
    required this.username,
    required this.score,
    required this.isCurrentUser,
  });

  final int rank;
  final String username;
  final double score;
  final bool isCurrentUser;
}

enum PerformanceScopeKind { fixedEquipment, exerciseOnStation }

/// Explicit identity used for performance/history queries.
///
/// Root-cause note:
/// Prior implementations keyed chart/history only by `exerciseKey`, which
/// merged multiple physical fixed machines sharing one canonical key
/// (e.g. several bench-press variants). This scope enforces machine isolation.
@immutable
class PerformanceScope {
  const PerformanceScope._({
    required this.kind,
    required this.exerciseKey,
    required this.equipmentId,
  });

  const PerformanceScope.fixedEquipment({
    required String exerciseKey,
    required String equipmentId,
  }) : this._(
         kind: PerformanceScopeKind.fixedEquipment,
         exerciseKey: exerciseKey,
         equipmentId: equipmentId,
       );

  const PerformanceScope.exerciseOnStation({
    required String exerciseKey,
    required String equipmentId,
  }) : this._(
         kind: PerformanceScopeKind.exerciseOnStation,
         exerciseKey: exerciseKey,
         equipmentId: equipmentId,
       );

  final PerformanceScopeKind kind;
  final String exerciseKey;
  final String equipmentId;

  bool get isFixedEquipment => kind == PerformanceScopeKind.fixedEquipment;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerformanceScope &&
        other.kind == kind &&
        other.exerciseKey == exerciseKey &&
        other.equipmentId == equipmentId;
  }

  @override
  int get hashCode => Object.hash(kind, exerciseKey, equipmentId);
}

// ─── E1RM data point ─────────────────────────────────────────────────────────

class E1rmDataPoint {
  const E1rmDataPoint({
    required this.sessionDayAnchor,
    required this.e1rm,
    required this.weightKg,
    required this.reps,
  });

  final String sessionDayAnchor; // 'yyyy-MM-dd'
  final double e1rm;
  final double weightKg;
  final int reps;
}

@visibleForTesting
class ScopedSetSample {
  const ScopedSetSample({
    required this.exerciseKey,
    required this.equipmentId,
    required this.sessionDayAnchor,
    required this.reps,
    required this.weightKg,
  });

  final String exerciseKey;
  final String? equipmentId;
  final String sessionDayAnchor;
  final int? reps;
  final double? weightKg;
}

@visibleForTesting
bool includeLegacyFixedRows({required int fixedVariantCount}) {
  // Legacy rows without equipmentId can only be attributed safely when one
  // fixed machine exists for this canonical key in the gym.
  return fixedVariantCount <= 1;
}

@visibleForTesting
List<E1rmDataPoint> aggregateScopedE1rmPoints({
  required Iterable<ScopedSetSample> samples,
  required PerformanceScope scope,
  required bool includeLegacyEquipmentlessRows,
}) {
  final byDate = <String, double>{};
  final byDateMeta = <String, ({double weightKg, int reps})>{};

  bool matchesScope(ScopedSetSample s) {
    if (s.exerciseKey != scope.exerciseKey) return false;
    if (s.equipmentId == scope.equipmentId) return true;
    if (scope.isFixedEquipment &&
        includeLegacyEquipmentlessRows &&
        s.equipmentId == null) {
      return true;
    }
    return false;
  }

  for (final s in samples) {
    if (!matchesScope(s)) continue;
    final w = s.weightKg;
    final r = s.reps;
    if (w == null || r == null || r <= 0 || w <= 0) continue;
    final e1rm = w * (1 + r / 30);
    final key = s.sessionDayAnchor;
    if (!byDate.containsKey(key) || e1rm > byDate[key]!) {
      byDate[key] = e1rm;
      byDateMeta[key] = (weightKg: w, reps: r);
    }
  }

  return byDate.entries.map((e) {
    final meta = byDateMeta[e.key]!;
    return E1rmDataPoint(
      sessionDayAnchor: e.key,
      e1rm: e.value,
      weightKg: meta.weightKg,
      reps: meta.reps,
    );
  }).toList()..sort((a, b) => a.sessionDayAnchor.compareTo(b.sessionDayAnchor));
}

typedef _E1rmArgs = ({String gymId, String userId, PerformanceScope scope});

final e1rmChartProvider = FutureProvider.family<List<E1rmDataPoint>, _E1rmArgs>(
  (ref, args) async {
    if (args.scope.exerciseKey.isEmpty) return [];
    if (args.scope.exerciseKey.startsWith('cardio:')) return [];

    final db = ref.watch(appDatabaseProvider);
    final sessionExercises = await db.getSessionExercisesForKey(
      args.gymId,
      args.scope.exerciseKey,
    );

    var includeLegacy = false;
    if (args.scope.isFixedEquipment) {
      final fixedVariantCount = await db
          .countActiveFixedEquipmentForExerciseKey(
            args.gymId,
            args.scope.exerciseKey,
          );
      includeLegacy = includeLegacyFixedRows(
        fixedVariantCount: fixedVariantCount,
      );
    }

    final samples = <ScopedSetSample>[];

    for (final ex in sessionExercises) {
      final session = await db.getSessionById(ex.sessionId);
      if (session == null ||
          session.userId != args.userId ||
          session.finishedAt == null) {
        continue;
      }

      final sets = await db.getSetsForExercise(ex.id);
      for (final s in sets) {
        samples.add(
          ScopedSetSample(
            exerciseKey: ex.exerciseKey,
            equipmentId: ex.equipmentId,
            sessionDayAnchor: session.sessionDayAnchor,
            reps: s.reps,
            weightKg: s.weightKg,
          ),
        );
      }
    }

    return aggregateScopedE1rmPoints(
      samples: samples,
      scope: args.scope,
      includeLegacyEquipmentlessRows: includeLegacy,
    );
  },
);

// ─── Equipment history ────────────────────────────────────────────────────────

typedef _HistoryArgs = ({String gymId, String userId, String equipmentId});

final equipmentHistoryProvider =
    FutureProvider.family<List<EquipmentHistorySummary>, _HistoryArgs>((
      ref,
      args,
    ) async {
      final db = ref.watch(appDatabaseProvider);
      final sessions = await db.getSessionsForEquipment(
        args.gymId,
        args.userId,
        args.equipmentId,
      );

      final summaries = <EquipmentHistorySummary>[];
      for (final session in sessions) {
        final exercises = await db.getExercisesForSession(session.id);
        final scopedExercises = exercises
            .where((exercise) => exercise.equipmentId == args.equipmentId)
            .toList();
        if (scopedExercises.isEmpty) continue;

        var totalSets = 0;
        var totalReps = 0;
        var totalVolume = 0.0;
        var totalXp = 0;

        for (final exercise in scopedExercises) {
          final sets = await db.getSetsForExercise(exercise.id);
          for (final s in sets) {
            totalSets++;
            final reps = s.reps ?? 0;
            totalReps += reps;
            if (s.weightKg != null && reps > 0) {
              totalVolume += reps * s.weightKg!;
            }
          }
          // Flat XP per exercise per session — same rule as XP accounting.
          if (sets.isNotEmpty) totalXp += XpRules.exerciseSessionBase;
        }

        summaries.add(
          EquipmentHistorySummary(
            sessionId: session.id,
            sessionExerciseId: null,
            exerciseName: null,
            sessionDayAnchor: session.sessionDayAnchor,
            startedAt: session.startedAt,
            finishedAt: session.finishedAt,
            setCount: totalSets,
            totalReps: totalReps,
            totalVolumeKg: totalVolume,
            totalXp: totalXp,
          ),
        );
      }
      return summaries;
    });

// ─── Custom exercises at open station ────────────────────────────────────────

typedef _CustomExercisesArgs = ({
  String gymId,
  String userId,
  String equipmentId,
});

final customExercisesForEquipmentProvider =
    FutureProvider.family<List<CustomExerciseSummary>, _CustomExercisesArgs>((
      ref,
      args,
    ) async {
      final db = ref.watch(appDatabaseProvider);
      final rows = await db.getCustomExercisesForEquipment(
        args.gymId,
        args.userId,
        args.equipmentId,
      );
      return rows
          .map(
            (r) => CustomExerciseSummary(
              exerciseKey: 'custom:${r.id}',
              name: r.name,
            ),
          )
          .toList();
    });

// ─── Per-exercise history (for open-station custom exercises) ─────────────────

typedef _ExerciseKeyHistoryArgs = ({
  String gymId,
  String userId,
  String exerciseKey,
  String equipmentId,
});

final exerciseKeyHistoryProvider =
    FutureProvider.family<
      List<EquipmentHistorySummary>,
      _ExerciseKeyHistoryArgs
    >((ref, args) async {
      if (args.exerciseKey.isEmpty) return [];

      final db = ref.watch(appDatabaseProvider);
      final sessionExercises = await db.getSessionExercisesForKey(
        args.gymId,
        args.exerciseKey,
      );

      final summaries = <EquipmentHistorySummary>[];
      final bySessionId = <String, EquipmentHistorySummary>{};

      for (final ex in sessionExercises) {
        if (ex.equipmentId != args.equipmentId) continue;

        final session = await db.getSessionById(ex.sessionId);
        if (session == null ||
            session.userId != args.userId ||
            session.finishedAt == null) {
          continue;
        }

        final sets = await db.getSetsForExercise(ex.id);
        if (sets.isEmpty) continue;

        var totalReps = 0;
        var totalVolume = 0.0;

        for (final s in sets) {
          final reps = s.reps ?? 0;
          totalReps += reps;
          if (s.weightKg != null && reps > 0) totalVolume += reps * s.weightKg!;
        }

        final previous = bySessionId[session.id];
        if (previous == null) {
          bySessionId[session.id] = EquipmentHistorySummary(
            sessionId: session.id,
            sessionExerciseId: ex.id,
            exerciseName: ex.displayName,
            sessionDayAnchor: session.sessionDayAnchor,
            startedAt: session.startedAt,
            finishedAt: session.finishedAt,
            setCount: sets.length,
            totalReps: totalReps,
            totalVolumeKg: totalVolume,
            // Flat XP per session-exercise — same rule as XP accounting.
            totalXp: XpRules.exerciseSessionBase,
          );
          continue;
        }

        bySessionId[session.id] = EquipmentHistorySummary(
          sessionId: previous.sessionId,
          sessionExerciseId: previous.sessionExerciseId,
          exerciseName: previous.exerciseName,
          sessionDayAnchor: previous.sessionDayAnchor,
          startedAt: previous.startedAt,
          finishedAt: previous.finishedAt,
          setCount: previous.setCount + sets.length,
          totalReps: previous.totalReps + totalReps,
          totalVolumeKg: previous.totalVolumeKg + totalVolume,
          totalXp: previous.totalXp + XpRules.exerciseSessionBase,
        );
      }

      summaries.addAll(bySessionId.values);
      summaries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return summaries.take(20).toList();
    });

typedef _HistoryDetailArgs = ({
  String gymId,
  String userId,
  String sessionId,
  String equipmentId,
  String exerciseKey,
});

final equipmentHistoryDetailProvider =
    FutureProvider.family<EquipmentHistoryDetail?, _HistoryDetailArgs>((
      ref,
      args,
    ) async {
      final db = ref.watch(appDatabaseProvider);
      final session = await db.getSessionById(args.sessionId);
      if (session == null ||
          session.userId != args.userId ||
          session.gymId != args.gymId ||
          session.finishedAt == null) {
        return null;
      }

      final exercises = await db.getExercisesForSession(session.id);
      final scopedExercises = exercises
          .where(
            (exercise) =>
                exercise.exerciseKey == args.exerciseKey &&
                exercise.equipmentId == args.equipmentId,
          )
          .toList();
      if (scopedExercises.isEmpty) return null;

      final sets = <LocalSetEntry>[];
      var totalReps = 0;
      var totalVolume = 0.0;
      var totalXp = 0;

      for (final exercise in scopedExercises) {
        final exerciseSets = await db.getSetsForExercise(exercise.id);
        if (exerciseSets.isEmpty) continue;
        sets.addAll(exerciseSets);

        for (final s in exerciseSets) {
          final reps = s.reps ?? 0;
          totalReps += reps;
          if (s.weightKg != null && reps > 0) {
            totalVolume += reps * s.weightKg!;
          }
        }
        totalXp += XpRules.exerciseSessionBase;
      }
      if (sets.isEmpty) return null;

      sets.sort((a, b) {
        final byLoggedAt = a.loggedAt.compareTo(b.loggedAt);
        if (byLoggedAt != 0) return byLoggedAt;
        return a.setNumber.compareTo(b.setNumber);
      });

      final primaryName = scopedExercises.first.displayName;
      return EquipmentHistoryDetail(
        sessionId: session.id,
        sessionDayAnchor: session.sessionDayAnchor,
        startedAt: session.startedAt,
        finishedAt: session.finishedAt,
        exerciseName: primaryName,
        sets: sets,
        totalReps: totalReps,
        totalVolumeKg: totalVolume,
        totalXp: totalXp,
      );
    });

// ─── Exercise XP (server-confirmed) ──────────────────────────────────────────

typedef _XpArgs = ({String gymId, String userId, String exerciseKey});

final equipmentExerciseXpProvider = FutureProvider.family<int, _XpArgs>((
  ref,
  args,
) async {
  if (args.exerciseKey.isEmpty) return 0;

  final client = ref.watch(supabaseClientProvider);
  try {
    final row = await client
        .from('user_exercise_xp')
        .select('total_xp')
        .eq('user_id', args.userId)
        .eq('gym_id', args.gymId)
        .eq('exercise_key', args.exerciseKey)
        .maybeSingle();

    if (row == null) return 0;
    return row['total_xp'] as int? ?? 0;
  } catch (_) {
    return 0;
  }
});

// ─── Gym ranking for exercise ──────────────────────────────────────────────────

typedef _RankingArgs = ({String gymId, String userId, String exerciseKey});

final equipmentRankingProvider =
    FutureProvider.family<List<EquipmentRankingEntry>, _RankingArgs>((
      ref,
      args,
    ) async {
      if (args.exerciseKey.isEmpty) return [];

      final client = ref.watch(supabaseClientProvider);
      try {
        final rows = await client
            .from('ranking_snapshots')
            .select('user_id, rank_position, score, user_profiles(username)')
            .eq('gym_id', args.gymId)
            .eq('exercise_key', args.exerciseKey)
            .eq('period', 'weekly')
            .order('rank_position', ascending: true)
            .limit(10);

        final typedRows = (rows as List)
            .whereType<Map<dynamic, dynamic>>()
            .map((row) => Map<String, Object?>.from(row))
            .toList(growable: false);

        return typedRows.map((r) {
          final profile = (r['user_profiles'] as Map<dynamic, dynamic>?)
              ?.cast<String, Object?>();
          return EquipmentRankingEntry(
            rank: r['rank_position'] as int? ?? 0,
            username: profile?['username'] as String? ?? 'Unknown',
            score: (r['score'] as num?)?.toDouble() ?? 0,
            isCurrentUser: (r['user_id'] as String?) == args.userId,
          );
        }).toList();
      } catch (_) {
        return [];
      }
    });

// ─── Exercise muscle groups ───────────────────────────────────────────────────

class ExerciseMuscleGroupEntry {
  const ExerciseMuscleGroupEntry({
    required this.muscleGroup,
    required this.role,
  });

  final String muscleGroup; // e.g. 'chest'
  final String role; // 'primary' | 'secondary'
}

typedef _MgArgs = ({String gymId, String exerciseKey});

final exerciseMuscleGroupsProvider =
    FutureProvider.family<List<ExerciseMuscleGroupEntry>, _MgArgs>((
      ref,
      args,
    ) async {
      if (args.exerciseKey.isEmpty) return [];
      if (args.exerciseKey.startsWith('cardio:')) return [];

      final client = ref.watch(supabaseClientProvider);
      try {
        final rows = await client
            .from('exercise_muscle_groups')
            .select('muscle_group, role')
            .eq('exercise_key', args.exerciseKey)
            .eq('gym_id', args.gymId);

        return (rows as List).map((r) {
          final m = Map<String, Object?>.from(r as Map);
          return ExerciseMuscleGroupEntry(
            muscleGroup: m['muscle_group'] as String? ?? '',
            role: m['role'] as String? ?? '',
          );
        }).toList();
      } catch (_) {
        return [];
      }
    });

// ─── Favourites ───────────────────────────────────────────────────────────────

const _kFavPrefsKey = 'tapem_fav_equipment_v1';

class FavouritesNotifier extends StateNotifier<Set<String>> {
  FavouritesNotifier(this._ref) : super({}) {
    _load();
  }

  final Ref _ref;

  SharedPreferences get _prefs => _ref.read(sharedPreferencesProvider);

  void _load() {
    final saved = _prefs.getStringList(_kFavPrefsKey) ?? [];
    state = saved.toSet();
  }

  bool isFavourite(String gymId, String equipmentId) =>
      state.contains('$gymId:$equipmentId');

  Future<void> toggle(String gymId, String equipmentId) async {
    final key = '$gymId:$equipmentId';
    final next = Set<String>.from(state);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    state = next;
    await _prefs.setStringList(_kFavPrefsKey, next.toList());
  }
}

final favouritesProvider =
    StateNotifierProvider<FavouritesNotifier, Set<String>>(
      (ref) => FavouritesNotifier(ref),
    );

// ─── Equipment note ───────────────────────────────────────────────────────────

String _noteKey(String gymId, String userId, String equipmentId) =>
    'tapem_eq_note_v1_${gymId}_${userId}_$equipmentId';

typedef _NoteArgs = ({String gymId, String userId, String equipmentId});

class EquipmentNoteNotifier extends StateNotifier<String> {
  EquipmentNoteNotifier(this._ref, this._gymId, this._userId, this._equipmentId)
    : super('') {
    _load();
  }

  final Ref _ref;
  final String _gymId;
  final String _userId;
  final String _equipmentId;

  SharedPreferences get _prefs => _ref.read(sharedPreferencesProvider);

  void _load() {
    state = _prefs.getString(_noteKey(_gymId, _userId, _equipmentId)) ?? '';
  }

  Future<void> save(String note) async {
    await _prefs.setString(_noteKey(_gymId, _userId, _equipmentId), note);
    state = note;
  }
}

final equipmentNoteNotifierProvider =
    StateNotifierProvider.family<EquipmentNoteNotifier, String, _NoteArgs>(
      (ref, args) =>
          EquipmentNoteNotifier(ref, args.gymId, args.userId, args.equipmentId),
    );
