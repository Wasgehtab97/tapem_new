import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../domain/entities/auth/user_profile.dart';
import '../../../../presentation/features/auth/providers/auth_provider.dart';

typedef _JsonMap = Map<String, Object?>;

List<_JsonMap> _asJsonRows(Object? response) {
  if (response is! List) return const [];
  return response
      .whereType<Map<dynamic, dynamic>>()
      .map((row) => Map<String, Object?>.from(row))
      .toList(growable: false);
}

String? _readStringOrNull(_JsonMap row, String key) => row[key] as String?;

String _readString(_JsonMap row, String key, {String fallback = ''}) =>
    _readStringOrNull(row, key) ?? fallback;

int _readInt(_JsonMap row, String key, {int fallback = 0}) {
  final value = row[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

bool _readBool(_JsonMap row, String key, {bool fallback = false}) =>
    row[key] as bool? ?? fallback;

double _readDouble(_JsonMap row, String key, {double fallback = 0}) {
  final value = row[key];
  if (value is num) return value.toDouble();
  return fallback;
}

// ─── Models ───────────────────────────────────────────────────────────────────

class FriendUser {
  const FriendUser({
    required this.friendshipId,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.status,
    required this.lastTrainingDay,
    required this.sharedGymCount,
    required this.sharesActiveGym,
  });

  final String friendshipId;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String
  status; // 'accepted' | 'pending_sent' | 'pending_received' | 'none'
  final String? lastTrainingDay; // 'yyyy-MM-dd' — only if privacy allows
  final int sharedGymCount;
  final bool sharesActiveGym;
}

class TrainingDayRankingEntry {
  const TrainingDayRankingEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.totalXp,
    required this.currentLevel,
    required this.trainingDays,
    this.isCurrentUser = false,
  });

  final int rank;
  final String userId;
  final String username;
  final int totalXp;
  final int currentLevel;
  final int trainingDays;
  final bool isCurrentUser;
}

class EquipmentRankingEntry {
  const EquipmentRankingEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.totalXp,
    required this.currentLevel,
    required this.equipmentCount,
    this.isCurrentUser = false,
  });

  final int rank;
  final String userId;
  final String username;
  final int totalXp;
  final int currentLevel;
  final int equipmentCount;
  final bool isCurrentUser;
}

// ─── Friends list ─────────────────────────────────────────────────────────────

final friendsProvider = FutureProvider<List<FriendUser>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);

  final rows = _asJsonRows(
    await client.rpc(
      'get_my_friendships_overview',
      params: {'p_active_gym_id': gymId},
    ),
  );

  final friends = rows
      .map(
        (r) => FriendUser(
          friendshipId: _readString(r, 'friendship_id'),
          userId: _readString(r, 'friend_user_id'),
          username: _readString(r, 'username', fallback: '?'),
          displayName: _readStringOrNull(r, 'display_name'),
          avatarUrl: _readStringOrNull(r, 'avatar_url'),
          status: _readString(r, 'status', fallback: 'none'),
          lastTrainingDay: null, // enriched below for accepted friends
          sharedGymCount: _readInt(r, 'shared_gym_count'),
          sharesActiveGym: _readBool(r, 'shares_active_gym'),
        ),
      )
      .toList();

  // Enrich accepted friends with lastTrainingDay via privacy-aware RPC.
  final acceptedFriendIds = friends
      .where((f) => f.status == 'accepted')
      .map((f) => f.userId)
      .where((id) => id.isNotEmpty)
      .toList();

  if (acceptedFriendIds.isEmpty) return friends;

  Map<String, String?> trainingDayMap;
  try {
    final trainingDayRows = _asJsonRows(
      await client.rpc(
        'get_friends_last_training_day',
        params: {
          // Null => all gyms. This enables cross-gym friendships.
          'p_gym_id': null,
          'p_friend_ids': acceptedFriendIds,
        },
      ),
    );

    trainingDayMap = {
      for (final r in trainingDayRows)
        _readString(r, 'user_id'): _readStringOrNull(r, 'last_training_day'),
    };
  } catch (_) {
    // Non-fatal: RPC may not be deployed yet; fall back to no training days.
    trainingDayMap = {};
  }

  return friends.map((f) {
    if (f.status != 'accepted') return f;
    return FriendUser(
      friendshipId: f.friendshipId,
      userId: f.userId,
      username: f.username,
      displayName: f.displayName,
      avatarUrl: f.avatarUrl,
      status: f.status,
      lastTrainingDay: trainingDayMap[f.userId],
      sharedGymCount: f.sharedGymCount,
      sharesActiveGym: f.sharesActiveGym,
    );
  }).toList();
});

// ─── User search (my gym + other gyms) ────────────────────────────────────────

final userSearchProvider = FutureProvider.family<List<FriendUser>, String>((
  ref,
  query,
) async {
  if (query.trim().length < 2) return [];

  final user = ref.watch(currentUserProvider);
  final gymId = ref.watch(activeGymIdProvider);
  if (user == null || gymId == null) return [];

  final client = ref.watch(supabaseClientProvider);

  final rows = _asJsonRows(
    await client.rpc(
      'search_users_for_friendship',
      params: {
        'p_query': query.trim(),
        'p_limit': 20,
        'p_active_gym_id': gymId,
      },
    ),
  );

  return rows
      .map(
        (r) => FriendUser(
          friendshipId: _readString(r, 'friendship_id'),
          userId: _readString(r, 'user_id'),
          username: _readString(r, 'username', fallback: '?'),
          displayName: _readStringOrNull(r, 'display_name'),
          avatarUrl: _readStringOrNull(r, 'avatar_url'),
          status: _readString(r, 'relationship_status', fallback: 'none'),
          lastTrainingDay: null,
          sharedGymCount: _readInt(r, 'shared_gym_count'),
          sharesActiveGym: _readBool(r, 'shares_active_gym'),
        ),
      )
      .toList();
});

// ─── Friend training calendar ─────────────────────────────────────────────────

class FriendCalendarQuery {
  const FriendCalendarQuery({
    required this.friendUserId,
    required this.year,
    this.gymId,
  });

  final String friendUserId;
  final int year;
  final String? gymId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendCalendarQuery &&
          runtimeType == other.runtimeType &&
          friendUserId == other.friendUserId &&
          year == other.year &&
          gymId == other.gymId;

  @override
  int get hashCode => Object.hash(friendUserId, year, gymId);
}

final friendTrainingDaysProvider =
    FutureProvider.family<Set<String>, FriendCalendarQuery>((ref, query) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) return {};

      final client = ref.watch(supabaseClientProvider);
      final rows = _asJsonRows(
        await client.rpc(
          'get_friend_training_calendar_days',
          params: {
            'p_friend_id': query.friendUserId,
            'p_year': query.year,
            'p_gym_id': query.gymId,
          },
        ),
      );

      return {for (final row in rows) _readString(row, 'session_day')};
    });

// ─── Friend last-session summary ──────────────────────────────────────────────

class FriendSessionSummaryQuery {
  const FriendSessionSummaryQuery({required this.friendUserId, this.gymId});

  final String friendUserId;
  final String? gymId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendSessionSummaryQuery &&
          runtimeType == other.runtimeType &&
          friendUserId == other.friendUserId &&
          gymId == other.gymId;

  @override
  int get hashCode => Object.hash(friendUserId, gymId);
}

class FriendSessionSummary {
  const FriendSessionSummary({
    required this.sessionId,
    required this.sessionDay,
    required this.exerciseCount,
    required this.setCount,
  });

  final String sessionId;
  final String sessionDay;
  final int exerciseCount;
  final int setCount;
}

final friendLastSessionSummaryProvider =
    FutureProvider.family<FriendSessionSummary?, FriendSessionSummaryQuery>((
      ref,
      query,
    ) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) return null;

      final client = ref.watch(supabaseClientProvider);
      final rows = _asJsonRows(
        await client.rpc(
          'get_friend_last_session_summary',
          params: {'p_friend_id': query.friendUserId, 'p_gym_id': query.gymId},
        ),
      );

      if (rows.isEmpty) return null;
      final row = rows.first;
      return FriendSessionSummary(
        sessionId: _readString(row, 'session_id'),
        sessionDay: _readString(row, 'session_day'),
        exerciseCount: _readInt(row, 'exercise_count'),
        setCount: _readInt(row, 'set_count'),
      );
    });

// ─── Training Day Ranking ─────────────────────────────────────────────────────

final gymTrainingDayRankingProvider =
    FutureProvider<List<TrainingDayRankingEntry>>((ref) async {
      final user = ref.watch(currentUserProvider);
      final gymId = ref.watch(activeGymIdProvider);
      if (user == null || gymId == null) return [];

      final client = ref.watch(supabaseClientProvider);
      try {
        final rows = _asJsonRows(
          await client.rpc(
            'get_gym_training_day_ranking',
            params: {'p_gym_id': gymId},
          ),
        );

        return rows.map((r) {
          return TrainingDayRankingEntry(
            rank: _readInt(r, 'rank'),
            userId: _readString(r, 'user_id'),
            username: _readString(r, 'username', fallback: '?'),
            totalXp: _readInt(r, 'total_xp'),
            currentLevel: _readInt(r, 'current_level', fallback: 1),
            trainingDays: _readInt(r, 'training_days'),
            isCurrentUser: _readString(r, 'user_id') == user.id,
          );
        }).toList();
      } catch (e) {
        throw Exception('Training day ranking failed: $e');
      }
    });

// ─── Equipment XP Ranking ─────────────────────────────────────────────────────

final gymEquipmentRankingProvider = FutureProvider<List<EquipmentRankingEntry>>(
  (ref) async {
    final user = ref.watch(currentUserProvider);
    final gymId = ref.watch(activeGymIdProvider);
    if (user == null || gymId == null) return [];

    final client = ref.watch(supabaseClientProvider);
    try {
      final rows = _asJsonRows(
        await client.rpc(
          'get_gym_equipment_ranking',
          params: {'p_gym_id': gymId},
        ),
      );

      return rows.map((r) {
        return EquipmentRankingEntry(
          rank: _readInt(r, 'rank'),
          userId: _readString(r, 'user_id'),
          username: _readString(r, 'username', fallback: '?'),
          totalXp: _readInt(r, 'total_xp'),
          currentLevel: _readInt(r, 'current_level', fallback: 1),
          equipmentCount: _readInt(r, 'equipment_count'),
          isCurrentUser: _readString(r, 'user_id') == user.id,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  },
);

// ─── Unified Leaderboard Entry ────────────────────────────────────────────────

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.totalXp,
    required this.currentLevel,
    required this.trainingDays,
    required this.xpToNextLevel,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  final int rank;
  final String userId;
  final String username;
  final int totalXp;
  final int currentLevel;
  final int trainingDays;
  final int xpToNextLevel;
  final String? avatarUrl;
  final bool isCurrentUser;

  /// Progress fraction (0.0–1.0) within the current level for XP bar display.
  double get xpProgressFraction {
    final denominator = totalXp + xpToNextLevel;
    if (denominator <= 0) return 0;
    return (totalXp / denominator).clamp(0.0, 1.0);
  }
}

// ─── Unified Leaderboard Provider ─────────────────────────────────────────────
// Calls the get_gym_leaderboard() RPC which supports both axes and includes
// a session-based fallback for users whose XP aggregation hasn't run yet.

const kAxisTrainingDay = 'training_day';
const kAxisEquipment = 'exercise_equipment';

final gymLeaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, axis) async {
      final user = ref.watch(currentUserProvider);
      final gymId = ref.watch(activeGymIdProvider);
      if (user == null || gymId == null) return [];

      final client = ref.watch(supabaseClientProvider);
      try {
        // avatar_url is now included in get_gym_leaderboard (migration 00086),
        // eliminating the secondary user_profiles fetch (~15 KB per call).
        final rows = _asJsonRows(
          await client.rpc(
            'get_gym_leaderboard',
            params: {'p_gym_id': gymId, 'p_axis': axis},
          ),
        );

        return rows.map((r) {
          final userId = _readString(r, 'user_id');
          return LeaderboardEntry(
            rank: _readInt(r, 'rank'),
            userId: userId,
            username: _readString(r, 'username', fallback: '?'),
            totalXp: _readInt(r, 'total_xp'),
            currentLevel: _readInt(r, 'current_level', fallback: 1),
            trainingDays: _readInt(r, 'training_days'),
            xpToNextLevel: _readInt(r, 'xp_to_next_level', fallback: 500),
            avatarUrl: _readStringOrNull(r, 'avatar_url'),
            isCurrentUser: userId == user.id,
          );
        }).toList();
      } catch (e) {
        throw Exception('Leaderboard ($axis) failed: $e');
      }
    });

// ─── Equipment Exercise Overview ─────────────────────────────────────────────
// Per-exercise top-user data for the EQUIPMENT XP tab.

/// One row per active gym machine.
/// [topUserId] is null when no athlete has trained on this machine yet.
/// [myXp] / [myLevel] reflect the currently-logged-in user's own stats on this machine.
class EquipmentExerciseEntry {
  const EquipmentExerciseEntry({
    required this.equipmentId,
    required this.equipmentName,
    this.topUserId,
    this.topUsername,
    this.topXp = 0,
    this.topLevel = 1,
    this.distinctUsers = 0,
    this.myXp = 0,
    this.myLevel = 1,
    this.isCurrentUser = false,
  });

  final String equipmentId;
  final String equipmentName;
  final String? topUserId;
  final String? topUsername;
  final int topXp;
  final int topLevel;
  final int distinctUsers;
  final int myXp;
  final int myLevel;
  final bool isCurrentUser;

  // topUsername is guaranteed non-null by the SQL RPC when topUserId is set,
  // but we guard here too so a stale client never renders "@null".
  bool get hasData => topUserId != null && topUsername != null;
  bool get hasMyData => myXp > 0;
}

final gymEquipmentOverviewProvider =
    FutureProvider<List<EquipmentExerciseEntry>>((ref) async {
      final user = ref.watch(currentUserProvider);
      final gymId = ref.watch(activeGymIdProvider);
      if (user == null || gymId == null) return [];

      final client = ref.watch(supabaseClientProvider);
      try {
        final rows = _asJsonRows(
          await client.rpc(
            'get_gym_equipment_overview',
            params: {'p_gym_id': gymId, 'p_user_id': user.id},
          ),
        );

        return rows.map((r) {
          final topUserId = _readStringOrNull(r, 'top_user_id');
          return EquipmentExerciseEntry(
            equipmentId: _readString(r, 'equipment_id'),
            equipmentName: _readString(r, 'equipment_name', fallback: '?'),
            topUserId: topUserId,
            topUsername: _readStringOrNull(r, 'top_username'),
            topXp: _readInt(r, 'top_xp'),
            topLevel: _readInt(r, 'top_level', fallback: 1),
            distinctUsers: _readInt(r, 'distinct_users'),
            myXp: _readInt(r, 'my_xp'),
            myLevel: _readInt(r, 'my_level', fallback: 1),
            isCurrentUser: topUserId != null && topUserId == user.id,
          );
        }).toList();
      } catch (_) {
        return [];
      }
    });

// ─── Equipment Leaderboard ────────────────────────────────────────────────────
// Full ranked list of all athletes on one specific machine.

class EquipmentLeaderboardEntry {
  const EquipmentLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.totalXp,
    required this.currentLevel,
    required this.xpToNextLevel,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  final int rank;
  final String userId;
  final String username;
  final int totalXp;
  final int currentLevel;
  final int xpToNextLevel;
  final String? avatarUrl;
  final bool isCurrentUser;
}

final equipmentLeaderboardProvider =
    FutureProvider.family<List<EquipmentLeaderboardEntry>, String>((
      ref,
      equipmentId,
    ) async {
      final user = ref.watch(currentUserProvider);
      final gymId = ref.watch(activeGymIdProvider);
      if (user == null || gymId == null) return [];

      final client = ref.watch(supabaseClientProvider);
      try {
        final rows = _asJsonRows(
          await client.rpc(
            'get_equipment_leaderboard',
            params: {'p_gym_id': gymId, 'p_equipment_id': equipmentId},
          ),
        );

        // Batch-fetch avatar_url for all ranked users.
        final userIds = rows.map((r) => _readString(r, 'user_id')).toList();
        final Map<String, String?> avatarMap;
        if (userIds.isNotEmpty) {
          final profiles = _asJsonRows(
            await client
                .from('user_profiles')
                .select('id, avatar_url')
                .inFilter('id', userIds),
          );
          avatarMap = {
            for (final p in profiles)
              _readString(p, 'id'): _readStringOrNull(p, 'avatar_url'),
          };
        } else {
          avatarMap = {};
        }

        return rows.map((r) {
          final userId = _readString(r, 'user_id');
          return EquipmentLeaderboardEntry(
            rank: _readInt(r, 'rank'),
            userId: userId,
            username: _readString(r, 'username', fallback: '?'),
            totalXp: _readInt(r, 'total_xp'),
            currentLevel: _readInt(r, 'current_level', fallback: 1),
            xpToNextLevel: _readInt(r, 'xp_to_next_level', fallback: 500),
            avatarUrl: avatarMap[userId],
            isCurrentUser: userId == user.id,
          );
        }).toList();
      } catch (_) {
        return [];
      }
    });

// ─── Machine Performance Leaderboard ──────────────────────────────────────────

class MachinePerformanceBoardEntry {
  const MachinePerformanceBoardEntry({
    required this.equipmentId,
    required this.equipmentName,
    this.manufacturer,
    required this.exerciseKey,
    required this.exerciseName,
    required this.participantCount,
    this.topE1rmKg,
    this.topWeightKg,
    this.topReps,
    this.topUserId,
    this.topUsername,
    this.topAchievedAt,
  });

  final String equipmentId;
  final String equipmentName;
  final String? manufacturer;
  final String exerciseKey;
  final String exerciseName;
  final int participantCount;
  final double? topE1rmKg;
  final double? topWeightKg;
  final int? topReps;
  final String? topUserId;
  final String? topUsername;
  final DateTime? topAchievedAt;

  bool get hasLeaderboardData => topE1rmKg != null && topUserId != null;
}

class MachinePerformanceLeaderboardEntry {
  const MachinePerformanceLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.bestE1rmKg,
    required this.bestWeightKg,
    required this.bestReps,
    required this.achievedAt,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  final int rank;
  final String userId;
  final String username;
  final double bestE1rmKg;
  final double bestWeightKg;
  final int bestReps;
  final DateTime achievedAt;
  final String? avatarUrl;
  final bool isCurrentUser;
}

class MachinePerformanceDashboardStats {
  const MachinePerformanceDashboardStats({
    required this.fixedMachineCount,
    required this.activeBoardsCount,
    required this.rankedAthletesCount,
    this.bestE1rmKg,
    this.bestEquipmentId,
    this.bestEquipmentName,
    this.bestUsername,
  });

  final int fixedMachineCount;
  final int activeBoardsCount;
  final int rankedAthletesCount;
  final double? bestE1rmKg;
  final String? bestEquipmentId;
  final String? bestEquipmentName;
  final String? bestUsername;
}

class MachinePerformanceRecordEvent {
  const MachinePerformanceRecordEvent({
    required this.equipmentId,
    required this.equipmentName,
    this.manufacturer,
    required this.exerciseName,
    required this.userId,
    required this.username,
    required this.bestE1rmKg,
    required this.bestWeightKg,
    required this.bestReps,
    required this.achievedAt,
  });

  final String equipmentId;
  final String equipmentName;
  final String? manufacturer;
  final String exerciseName;
  final String userId;
  final String username;
  final double bestE1rmKg;
  final double bestWeightKg;
  final int bestReps;
  final DateTime achievedAt;
}

final machinePerformanceBoardsProvider =
    FutureProvider.family<
      List<MachinePerformanceBoardEntry>,
      MachinePerformanceSex
    >((ref, sex) async {
      final gymId = ref.watch(activeGymIdProvider);
      final user = ref.watch(currentUserProvider);
      if (gymId == null || user == null) return [];

      final client = ref.watch(supabaseClientProvider);
      try {
        final rows = _asJsonRows(
          await client.rpc(
            'get_machine_performance_equipment_boards',
            params: {'p_gym_id': gymId, 'p_sex': sex.value, 'p_query': null},
          ),
        );

        return rows
            .map(
              (r) => MachinePerformanceBoardEntry(
                equipmentId: _readString(r, 'equipment_id'),
                equipmentName: _readString(r, 'equipment_name', fallback: '?'),
                manufacturer: _readStringOrNull(r, 'manufacturer'),
                exerciseKey: _readString(r, 'exercise_key', fallback: '?'),
                exerciseName: _readString(r, 'exercise_name', fallback: '?'),
                participantCount: _readInt(r, 'participant_count'),
                topE1rmKg: r['top_e1rm_kg'] == null
                    ? null
                    : _readDouble(r, 'top_e1rm_kg'),
                topWeightKg: r['top_weight_kg'] == null
                    ? null
                    : _readDouble(r, 'top_weight_kg'),
                topReps: r['top_reps'] == null ? null : _readInt(r, 'top_reps'),
                topUserId: _readStringOrNull(r, 'top_user_id'),
                topUsername: _readStringOrNull(r, 'top_username'),
                topAchievedAt: r['top_achieved_at'] == null
                    ? null
                    : DateTime.tryParse(_readString(r, 'top_achieved_at')),
              ),
            )
            .toList();
      } catch (_) {
        return [];
      }
    });

typedef _MachineLeaderboardArgs = ({
  String equipmentId,
  MachinePerformanceSex sex,
});

final machinePerformanceLeaderboardProvider =
    FutureProvider.family<
      List<MachinePerformanceLeaderboardEntry>,
      _MachineLeaderboardArgs
    >((ref, args) async {
      final user = ref.watch(currentUserProvider);
      final gymId = ref.watch(activeGymIdProvider);
      if (user == null || gymId == null || args.equipmentId.isEmpty) return [];

      final client = ref.watch(supabaseClientProvider);
      try {
        final rows = _asJsonRows(
          await client.rpc(
            'get_machine_performance_equipment_leaderboard',
            params: {
              'p_gym_id': gymId,
              'p_equipment_id': args.equipmentId,
              'p_sex': args.sex.value,
              'p_limit': 100,
              'p_offset': 0,
            },
          ),
        );

        return rows.map((r) {
          final userId = _readString(r, 'user_id');
          final achievedAtRaw = _readString(r, 'achieved_at');
          return MachinePerformanceLeaderboardEntry(
            rank: _readInt(r, 'rank'),
            userId: userId,
            username: _readString(r, 'username', fallback: '?'),
            bestE1rmKg: _readDouble(r, 'best_e1rm_kg'),
            bestWeightKg: _readDouble(r, 'best_weight_kg'),
            bestReps: _readInt(r, 'best_reps'),
            achievedAt: DateTime.tryParse(achievedAtRaw) ?? DateTime(1970),
            avatarUrl: _readStringOrNull(r, 'avatar_url'),
            isCurrentUser: userId == user.id,
          );
        }).toList();
      } catch (_) {
        return [];
      }
    });

final machinePerformanceDashboardProvider =
    FutureProvider.family<
      MachinePerformanceDashboardStats,
      MachinePerformanceSex
    >((ref, sex) async {
      final gymId = ref.watch(activeGymIdProvider);
      final user = ref.watch(currentUserProvider);
      if (gymId == null || user == null) {
        return const MachinePerformanceDashboardStats(
          fixedMachineCount: 0,
          activeBoardsCount: 0,
          rankedAthletesCount: 0,
        );
      }

      final client = ref.watch(supabaseClientProvider);
      try {
        final rows = _asJsonRows(
          await client.rpc(
            'get_machine_performance_dashboard_stats',
            params: {'p_gym_id': gymId, 'p_sex': sex.value},
          ),
        );
        if (rows.isEmpty) {
          return const MachinePerformanceDashboardStats(
            fixedMachineCount: 0,
            activeBoardsCount: 0,
            rankedAthletesCount: 0,
          );
        }
        final row = rows.first;
        return MachinePerformanceDashboardStats(
          fixedMachineCount: _readInt(row, 'fixed_machine_count'),
          activeBoardsCount: _readInt(row, 'active_boards_count'),
          rankedAthletesCount: _readInt(row, 'ranked_athletes_count'),
          bestE1rmKg: row['best_e1rm_kg'] == null
              ? null
              : _readDouble(row, 'best_e1rm_kg'),
          bestEquipmentId: _readStringOrNull(row, 'best_equipment_id'),
          bestEquipmentName: _readStringOrNull(row, 'best_equipment_name'),
          bestUsername: _readStringOrNull(row, 'best_username'),
        );
      } catch (_) {
        return const MachinePerformanceDashboardStats(
          fixedMachineCount: 0,
          activeBoardsCount: 0,
          rankedAthletesCount: 0,
        );
      }
    });

final machinePerformanceRecentRecordsProvider =
    FutureProvider.family<
      List<MachinePerformanceRecordEvent>,
      MachinePerformanceSex
    >((ref, sex) async {
      final gymId = ref.watch(activeGymIdProvider);
      final user = ref.watch(currentUserProvider);
      if (gymId == null || user == null) return [];

      final client = ref.watch(supabaseClientProvider);
      try {
        final rows = _asJsonRows(
          await client.rpc(
            'get_machine_performance_recent_records',
            params: {'p_gym_id': gymId, 'p_sex': sex.value, 'p_limit': 12},
          ),
        );
        return rows.map((r) {
          return MachinePerformanceRecordEvent(
            equipmentId: _readString(r, 'equipment_id'),
            equipmentName: _readString(r, 'equipment_name', fallback: '?'),
            manufacturer: _readStringOrNull(r, 'manufacturer'),
            exerciseName: _readString(r, 'exercise_name', fallback: '?'),
            userId: _readString(r, 'user_id'),
            username: _readString(r, 'username', fallback: '?'),
            bestE1rmKg: _readDouble(r, 'best_e1rm_kg'),
            bestWeightKg: _readDouble(r, 'best_weight_kg'),
            bestReps: _readInt(r, 'best_reps'),
            achievedAt:
                DateTime.tryParse(_readString(r, 'achieved_at')) ??
                DateTime(1970),
          );
        }).toList();
      } catch (_) {
        return [];
      }
    });

// ─── Friend request actions ───────────────────────────────────────────────────

class FriendActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendRequest(String addresseeId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      final gymId = ref.read(activeGymIdProvider);
      if (user == null || gymId == null) throw Exception('Not authenticated');
      final client = ref.read(supabaseClientProvider);
      try {
        await client.from('friendships').insert({
          'requester_id': user.id,
          'addressee_id': addresseeId,
          'gym_id': gymId, // required by schema + RLS policy
          'status': 'pending',
        });
      } on PostgrestException catch (e) {
        // Duplicate pair can happen under races (both users tap "Add" quickly).
        // Treat unique-violation as success and let providers refresh.
        if (e.code != '23505') rethrow;
      }
      ref.invalidate(friendsProvider);
      ref.invalidate(userSearchProvider);
    });
  }

  Future<void> acceptRequest(String friendshipId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('friendships')
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId);
      ref.invalidate(friendsProvider);
      ref.invalidate(userSearchProvider);
    });
  }

  Future<void> declineRequest(String friendshipId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.from('friendships').delete().eq('id', friendshipId);
      ref.invalidate(friendsProvider);
      ref.invalidate(userSearchProvider);
    });
  }

  Future<void> removeFriend(String friendshipId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.from('friendships').delete().eq('id', friendshipId);
      ref.invalidate(friendsProvider);
      ref.invalidate(userSearchProvider);
      ref.invalidate(gymTrainingDayRankingProvider);
    });
  }
}

final friendActionsProvider =
    AsyncNotifierProvider<FriendActionsNotifier, void>(
      FriendActionsNotifier.new,
    );

// ─── Deals ────────────────────────────────────────────────────────────────────

class GymDeal {
  const GymDeal({
    required this.id,
    required this.gymId,
    required this.brandName,
    required this.tagline,
    required this.description,
    this.logoUrl,
    required this.bannerGradientStart,
    required this.bannerGradientEnd,
    required this.affiliateUrl,
    this.discountCode,
    this.discountLabel,
    required this.category,
    required this.sortOrder,
  });

  final String id;
  final String gymId;
  final String brandName;
  final String tagline;
  final String description;
  final String? logoUrl;
  final String bannerGradientStart;
  final String bannerGradientEnd;
  final String affiliateUrl;
  final String? discountCode;
  final String? discountLabel;
  final String
  category; // 'supplements'|'clothing'|'food'|'equipment'|'wellness'
  final int sortOrder;
}

/// Fetches active deals for the user's current gym, ordered by [sortOrder].
/// Automatically re-fetches when [activeGymIdProvider] changes (gym switch).
final gymDealsProvider = FutureProvider<List<GymDeal>>((ref) async {
  final gymId = ref.watch(activeGymIdProvider);
  if (gymId == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final rows = _asJsonRows(
    await client
        .from('gym_deals')
        .select(
          'id, gym_id, brand_name, tagline, description, logo_url, '
          'banner_gradient_start, banner_gradient_end, affiliate_url, '
          'discount_code, discount_label, category, sort_order',
        )
        .eq('gym_id', gymId)
        .eq('is_active', true)
        .order('sort_order'),
  );

  return rows
      .map(
        (r) => GymDeal(
          id: _readString(r, 'id'),
          gymId: _readString(r, 'gym_id'),
          brandName: _readString(r, 'brand_name'),
          tagline: _readString(r, 'tagline'),
          description: _readString(r, 'description'),
          logoUrl: _readStringOrNull(r, 'logo_url'),
          bannerGradientStart: _readString(
            r,
            'banner_gradient_start',
            fallback: '#12121A',
          ),
          bannerGradientEnd: _readString(
            r,
            'banner_gradient_end',
            fallback: '#0A0A0F',
          ),
          affiliateUrl: _readString(r, 'affiliate_url'),
          discountCode: _readStringOrNull(r, 'discount_code'),
          discountLabel: _readStringOrNull(r, 'discount_label'),
          category: _readString(r, 'category', fallback: 'supplements'),
          sortOrder: _readInt(r, 'sort_order'),
        ),
      )
      .toList();
});
