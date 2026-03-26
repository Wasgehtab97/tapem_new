import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/xp_rules.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class EquipmentHistorySummary {
  const EquipmentHistorySummary({
    required this.sessionId,
    required this.sessionDayAnchor,
    required this.startedAt,
    this.finishedAt,
    required this.setCount,
    required this.totalReps,
    required this.totalVolumeKg,
    required this.totalXp,
  });

  final String sessionId;
  final String sessionDayAnchor;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int setCount;
  final int totalReps;
  final double totalVolumeKg;
  final int totalXp;

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

typedef _E1rmArgs = ({String gymId, String userId, String exerciseKey});

final e1rmChartProvider = FutureProvider.family<List<E1rmDataPoint>, _E1rmArgs>(
  (ref, args) async {
    if (args.exerciseKey.isEmpty) return [];
    if (args.exerciseKey.startsWith('cardio:')) return [];

    final db = ref.watch(appDatabaseProvider);
    final sessionExercises = await db.getSessionExercisesForKey(
      args.gymId,
      args.exerciseKey,
    );

    // Best E1RM per session day (Epley: w × (1 + r/30))
    final byDate = <String, double>{};
    final byDateMeta = <String, ({double weightKg, int reps})>{};

    for (final ex in sessionExercises) {
      final session = await db.getSessionById(ex.sessionId);
      if (session == null ||
          session.userId != args.userId ||
          session.finishedAt == null) {
        continue;
      }

      final sets = await db.getSetsForExercise(ex.id);
      for (final s in sets) {
        final w = s.weightKg;
        final r = s.reps;
        if (w == null || r == null || r <= 0 || w <= 0) continue;
        final e1rm = w * (1 + r / 30);
        final key = session.sessionDayAnchor;
        if (!byDate.containsKey(key) || e1rm > byDate[key]!) {
          byDate[key] = e1rm;
          byDateMeta[key] = (weightKg: w, reps: r);
        }
      }
    }

    final points =
        byDate.entries.map((e) {
            final meta = byDateMeta[e.key]!;
            return E1rmDataPoint(
              sessionDayAnchor: e.key,
              e1rm: e.value,
              weightKg: meta.weightKg,
              reps: meta.reps,
            );
          }).toList()
          ..sort((a, b) => a.sessionDayAnchor.compareTo(b.sessionDayAnchor));

    return points;
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
        var totalSets = 0;
        var totalReps = 0;
        var totalVolume = 0.0;
        var totalXp = 0;

        for (final exercise in exercises) {
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
      final seenSessions = <String>{};

      for (final ex in sessionExercises) {
        if (seenSessions.contains(ex.sessionId)) continue;

        final session = await db.getSessionById(ex.sessionId);
        if (session == null ||
            session.userId != args.userId ||
            session.finishedAt == null) {
          continue;
        }

        seenSessions.add(session.id);

        final sets = await db.getSetsForExercise(ex.id);
        var totalReps = 0;
        var totalVolume = 0.0;

        for (final s in sets) {
          final reps = s.reps ?? 0;
          totalReps += reps;
          if (s.weightKg != null && reps > 0) totalVolume += reps * s.weightKg!;
        }

        summaries.add(
          EquipmentHistorySummary(
            sessionId: session.id,
            sessionDayAnchor: session.sessionDayAnchor,
            startedAt: session.startedAt,
            finishedAt: session.finishedAt,
            setCount: sets.length,
            totalReps: totalReps,
            totalVolumeKg: totalVolume,
            // Flat XP per session-exercise — same rule as XP accounting.
            totalXp: sets.isNotEmpty ? XpRules.exerciseSessionBase : 0,
          ),
        );
      }

      summaries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return summaries.take(20).toList();
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
            .order('rank_position')
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
