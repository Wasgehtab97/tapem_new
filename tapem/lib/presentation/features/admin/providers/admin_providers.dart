import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/gym/exercise_muscle_group.dart';
import '../../../../domain/entities/gym/exercise_template.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../../domain/entities/gym/muscle_group.dart';
import '../../../../domain/entities/gym/muscle_group_role.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/workout/providers/equipment_provider.dart';

// ─── Type aliases ─────────────────────────────────────────────────────────────

typedef _Row = Map<String, Object?>;

List<_Row> _toRows(Object? v) {
  if (v is! List) return const [];
  return v
      .whereType<Map<dynamic, dynamic>>()
      .map((r) => Map<String, Object?>.from(r))
      .toList(growable: false);
}

_Row _toRow(Object? v) {
  if (v is Map<dynamic, dynamic>) return Map<String, Object?>.from(v);
  return const {};
}

T _read<T>(_Row row, String key, T fallback) {
  final v = row[key];
  if (v is T) return v;
  return fallback;
}

// =============================================================================
// Domain models — admin-scoped data transfer objects
// =============================================================================

/// Full gym info as seen by an admin (includes join_code).
class AdminGymInfo {
  const AdminGymInfo({
    required this.id,
    required this.name,
    this.description,
    required this.joinCode,
    required this.requiresApproval,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String? description;
  final String joinCode;
  final bool requiresApproval;
  final String? logoUrl;
}

/// A gym member as seen in the admin member list.
class AdminMember {
  const AdminMember({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.isActive,
    required this.joinedAt,
    this.totalXp,
    this.currentLevel,
    this.lastTrainingDate,
  });

  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String role;

  /// 'active' | 'pending' | 'inactive'
  final String status;
  final bool isActive;
  final DateTime joinedAt;
  final int? totalXp;
  final int? currentLevel;
  final DateTime? lastTrainingDate;

  bool get isPending => status == 'pending';
  bool get isOwner => role == 'owner';
}

/// A gym challenge.
class AdminChallenge {
  const AdminChallenge({
    required this.id,
    required this.gymId,
    required this.title,
    this.description,
    required this.challengeType,
    required this.targetMetric,
    required this.visibility,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String gymId;
  final String title;
  final String? description;

  /// 'training_days' | 'total_xp' | 'exercise_volume'
  final String challengeType;
  final double targetMetric;

  /// 'all_members' | 'opt_in'
  final String visibility;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;
  final DateTime createdAt;

  bool get isUpcoming => startsAt.isAfter(DateTime.now());
  bool get isCompleted => endsAt.isBefore(DateTime.now()) || !isActive;
  bool get isRunning => isActive && !isUpcoming && !isCompleted;
}

/// DAU/WAU/MAU stats returned from get_gym_activity_stats.
class GymActivityStats {
  const GymActivityStats({
    required this.dau,
    required this.wau,
    required this.mau,
    required this.totalMembers,
    required this.pendingApprovals,
    required this.newMembersThisMonth,
    required this.totalSessionsThisMonth,
    required this.dailyActivity,
  });

  final int dau;
  final int wau;
  final int mau;
  final int totalMembers;
  final int pendingApprovals;
  final int newMembersThisMonth;
  final int totalSessionsThisMonth;

  /// Sorted list of {date: String, active_users: int} for last 30 days.
  final List<DailyActivityPoint> dailyActivity;
}

class DailyActivityPoint {
  const DailyActivityPoint({required this.date, required this.activeUsers});
  final DateTime date;
  final int activeUsers;
}

/// Per-equipment usage statistics.
class EquipmentUsageStat {
  const EquipmentUsageStat({
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentType,
    required this.isActive,
    required this.hasNfcTag,
    required this.totalSetsAllTime,
    required this.totalSetsLast30d,
    required this.uniqueUsers,
    required this.feedbackOpenCount,
    required this.feedbackTotalCount,
    this.lastUsedDate,
    this.lastFeedbackDate,
  });

  final String equipmentId;
  final String equipmentName;
  final String equipmentType;
  final bool isActive;
  final bool hasNfcTag;
  final int totalSetsAllTime;
  final int totalSetsLast30d;
  final int uniqueUsers;
  final int feedbackOpenCount;
  final int feedbackTotalCount;
  final DateTime? lastUsedDate;
  final DateTime? lastFeedbackDate;
}

/// KPI aggregation for one challenge.
class ChallengeKpi {
  const ChallengeKpi({
    required this.challengeId,
    required this.challengeType,
    required this.visibility,
    required this.targetMetric,
    required this.eligibleMembers,
    required this.participantsStarted,
    required this.participantsCompleted,
    required this.participationRatePct,
    required this.completionRatePct,
    required this.avgProgressValue,
    required this.bestProgressValue,
  });

  final String challengeId;
  final String challengeType;
  final String visibility;
  final double targetMetric;
  final int eligibleMembers;
  final int participantsStarted;
  final int participantsCompleted;
  final double participationRatePct;
  final double completionRatePct;
  final double avgProgressValue;
  final double bestProgressValue;
}

/// Engagement stats returned from get_gym_engagement_stats.
class GymEngagementStats {
  const GymEngagementStats({
    required this.levelDistribution,
    required this.topMembers,
    required this.activeChallenges,
    required this.totalActiveMembers,
  });

  final List<LevelBucket> levelDistribution;
  final List<TopMemberEntry> topMembers;
  final int activeChallenges;
  final int totalActiveMembers;
}

class LevelBucket {
  const LevelBucket({required this.range, required this.count});
  final String range;
  final int count;
}

class TopMemberEntry {
  const TopMemberEntry({
    required this.username,
    this.avatarUrl,
    required this.totalXp,
    required this.level,
    required this.trainingDaysThisMonth,
  });

  final String username;
  final String? avatarUrl;
  final int totalXp;
  final int level;
  final int trainingDaysThisMonth;
}

/// An equipment feedback report as seen by an admin.
class EquipmentFeedbackItem {
  const EquipmentFeedbackItem({
    required this.id,
    required this.gymId,
    required this.equipmentId,
    required this.equipmentName,
    required this.feedbackType,
    this.message,
    required this.status,
    required this.createdAt,
    this.reporterUsername,
  });

  final String id;
  final String gymId;
  final String equipmentId;
  final String equipmentName;
  final String feedbackType;
  final String? message;
  final String status;
  final DateTime createdAt;
  final String? reporterUsername;
}

/// A content moderation report.
class ContentReport {
  const ContentReport({
    required this.id,
    required this.gymId,
    required this.reportType,
    this.description,
    required this.status,
    required this.createdAt,
    this.reporterUsername,
    this.targetUsername,
    this.adminNote,
    this.resolvedAt,
  });

  final String id;
  final String gymId;
  final String reportType;
  final String? description;
  final String status;
  final DateTime createdAt;
  final String? reporterUsername;
  final String? targetUsername;
  final String? adminNote;
  final DateTime? resolvedAt;

  bool get isPending => status == 'pending';
}

// =============================================================================
// Read providers
// =============================================================================

/// Full gym info including join code — admin-only read.
final adminGymInfoProvider = FutureProvider.family<AdminGymInfo?, String>((
  ref,
  gymId,
) async {
  final client = ref.watch(supabaseClientProvider);

  final row = _toRow(
    await client
        .from('tenant_gyms')
        .select('id, name, description, join_code, requires_approval, logo_url')
        .eq('id', gymId)
        .maybeSingle(),
  );

  if (row.isEmpty) return null;

  return AdminGymInfo(
    id: _read(row, 'id', ''),
    name: _read(row, 'name', ''),
    description: row['description'] as String?,
    joinCode: _read(row, 'join_code', ''),
    requiresApproval: _read(row, 'requires_approval', false),
    logoUrl: row['logo_url'] as String?,
  );
});

/// All members of the gym (active, pending, inactive).
final adminMembersProvider = FutureProvider.family<List<AdminMember>, String>((
  ref,
  gymId,
) async {
  final client = ref.watch(supabaseClientProvider);

  final rows = _toRows(
    await client
        .from('memberships')
        .select(
          'user_id, role, status, is_active, joined_at, '
          'user_profiles(username, display_name, avatar_url)',
        )
        .eq('gym_id', gymId)
        .order('joined_at', ascending: false)
        .limit(500), // hard ceiling — no gym at current scale exceeds this
  );

  // user_gym_xp has a composite PK (user_id, gym_id) with no FK to memberships,
  // so PostgREST cannot do an embedded join. Fetch separately and merge by user_id.
  final userIds = rows.map((r) => r['user_id'] as String).toList();
  final Map<String, _Row> xpByUserId = {};
  if (userIds.isNotEmpty) {
    final xpRows = _toRows(
      await client
          .from('user_gym_xp')
          .select('user_id, total_xp, current_level')
          .eq('gym_id', gymId)
          .inFilter('user_id', userIds),
    );
    for (final xr in xpRows) {
      final uid = xr['user_id'] as String?;
      if (uid != null) xpByUserId[uid] = xr;
    }
  }

  return rows.map((r) {
    final profile = _toRow(r['user_profiles']);
    final xp = xpByUserId[_read(r, 'user_id', '')] ?? const {};
    return AdminMember(
      userId: _read(r, 'user_id', ''),
      username: _read(profile, 'username', ''),
      displayName: profile['display_name'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      role: _read(r, 'role', 'member'),
      status: _read(r, 'status', 'active'),
      isActive: _read(r, 'is_active', false),
      joinedAt: DateTime.parse(
        _read(r, 'joined_at', DateTime.now().toIso8601String()),
      ),
      totalXp: (xp['total_xp'] as num?)?.toInt() ?? 0,
      currentLevel: (xp['current_level'] as num?)?.toInt() ?? 1,
    );
  }).toList();
});

/// Pending member count — used for badge on admin menu item.
final pendingMemberCountProvider = FutureProvider.family<int, String>((
  ref,
  gymId,
) async {
  final members = await ref.watch(adminMembersProvider(gymId).future);
  return members.where((m) => m.isPending).length;
});

/// All challenges for the gym.
final adminChallengesProvider =
    FutureProvider.family<List<AdminChallenge>, String>((ref, gymId) async {
      final client = ref.watch(supabaseClientProvider);

      final rows = _toRows(
        await client
            .from('challenges')
            .select(
              'id, gym_id, title, description, challenge_type, target_metric, '
              'visibility, starts_at, ends_at, is_active, created_at',
            )
            .eq('gym_id', gymId)
            .order('starts_at', ascending: false),
      );

      return rows.map((r) {
        return AdminChallenge(
          id: _read(r, 'id', ''),
          gymId: _read(r, 'gym_id', ''),
          title: _read(r, 'title', ''),
          description: r['description'] as String?,
          challengeType: _read(r, 'challenge_type', 'training_days'),
          targetMetric: (r['target_metric'] as num?)?.toDouble() ?? 0,
          visibility: _read(r, 'visibility', 'all_members'),
          startsAt: DateTime.parse(
            _read(r, 'starts_at', DateTime.now().toIso8601String()),
          ),
          endsAt: DateTime.parse(
            _read(r, 'ends_at', DateTime.now().toIso8601String()),
          ),
          isActive: _read(r, 'is_active', true),
          createdAt: DateTime.parse(
            _read(r, 'created_at', DateTime.now().toIso8601String()),
          ),
        );
      }).toList();
    });

/// KPI map keyed by challenge_id.
final challengeKpisProvider =
    FutureProvider.family<Map<String, ChallengeKpi>, String>((
      ref,
      gymId,
    ) async {
      final client = ref.watch(supabaseClientProvider);

      final rows = _toRows(
        await client.rpc('get_challenge_kpis', params: {'p_gym_id': gymId}),
      );

      final result = <String, ChallengeKpi>{};
      for (final r in rows) {
        final id = _read(r, 'challenge_id', '');
        if (id.isEmpty) continue;
        result[id] = ChallengeKpi(
          challengeId: id,
          challengeType: _read(r, 'challenge_type', 'training_days'),
          visibility: _read(r, 'visibility', 'all_members'),
          targetMetric: (r['target_metric'] as num?)?.toDouble() ?? 0,
          eligibleMembers: (r['eligible_members'] as num?)?.toInt() ?? 0,
          participantsStarted:
              (r['participants_started'] as num?)?.toInt() ?? 0,
          participantsCompleted:
              (r['participants_completed'] as num?)?.toInt() ?? 0,
          participationRatePct:
              (r['participation_rate_pct'] as num?)?.toDouble() ?? 0,
          completionRatePct:
              (r['completion_rate_pct'] as num?)?.toDouble() ?? 0,
          avgProgressValue: (r['avg_progress_value'] as num?)?.toDouble() ?? 0,
          bestProgressValue:
              (r['best_progress_value'] as num?)?.toDouble() ?? 0,
        );
      }
      return result;
    });

/// Activity stats — backed by SECURITY DEFINER RPC.
final gymActivityStatsProvider =
    FutureProvider.family<GymActivityStats, String>((ref, gymId) async {
      final client = ref.watch(supabaseClientProvider);

      final raw = _toRow(
        await client.rpc('get_gym_activity_stats', params: {'p_gym_id': gymId}),
      );

      final dailyRaw = raw['daily_activity'];
      final dailyPoints =
          (dailyRaw is List ? dailyRaw : <dynamic>[])
              .whereType<Map<dynamic, dynamic>>()
              .map((item) {
                final m = Map<String, Object?>.from(item);
                final dateStr = m['date'] as String?;
                final users = (m['active_users'] as num?)?.toInt() ?? 0;
                if (dateStr == null) return null;
                final date = DateTime.tryParse(dateStr);
                if (date == null) return null;
                return DailyActivityPoint(date: date, activeUsers: users);
              })
              .whereType<DailyActivityPoint>()
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

      return GymActivityStats(
        dau: (raw['dau'] as num?)?.toInt() ?? 0,
        wau: (raw['wau'] as num?)?.toInt() ?? 0,
        mau: (raw['mau'] as num?)?.toInt() ?? 0,
        totalMembers: (raw['total_members'] as num?)?.toInt() ?? 0,
        pendingApprovals: (raw['pending_approvals'] as num?)?.toInt() ?? 0,
        newMembersThisMonth:
            (raw['new_members_this_month'] as num?)?.toInt() ?? 0,
        totalSessionsThisMonth:
            (raw['total_sessions_this_month'] as num?)?.toInt() ?? 0,
        dailyActivity: dailyPoints,
      );
    });

/// Equipment usage stats — backed by SECURITY DEFINER RPC.
final equipmentUsageStatsProvider =
    FutureProvider.family<List<EquipmentUsageStat>, String>((ref, gymId) async {
      final client = ref.watch(supabaseClientProvider);

      final raw = await client.rpc(
        'get_equipment_usage_stats',
        params: {'p_gym_id': gymId},
      );
      final rows = _toRows(raw);

      return rows.map((r) {
        final lastUsedStr = r['last_used_date'] as String?;
        final lastFeedbackStr = r['last_feedback_date'] as String?;
        return EquipmentUsageStat(
          equipmentId: _read(r, 'equipment_id', ''),
          equipmentName: _read(r, 'equipment_name', ''),
          equipmentType: _read(r, 'equipment_type', 'fixed_machine'),
          isActive: _read(r, 'is_active', true),
          hasNfcTag: _read(r, 'has_nfc_tag', false),
          totalSetsAllTime: (r['total_sets_all_time'] as num?)?.toInt() ?? 0,
          totalSetsLast30d: (r['total_sets_last_30d'] as num?)?.toInt() ?? 0,
          uniqueUsers: (r['unique_users'] as num?)?.toInt() ?? 0,
          feedbackOpenCount: (r['feedback_open_count'] as num?)?.toInt() ?? 0,
          feedbackTotalCount: (r['feedback_total_count'] as num?)?.toInt() ?? 0,
          lastUsedDate: lastUsedStr != null
              ? DateTime.tryParse(lastUsedStr)
              : null,
          lastFeedbackDate: lastFeedbackStr != null
              ? DateTime.tryParse(lastFeedbackStr)
              : null,
        );
      }).toList();
    });

/// Engagement stats — backed by SECURITY DEFINER RPC.
final gymEngagementStatsProvider =
    FutureProvider.family<GymEngagementStats, String>((ref, gymId) async {
      final client = ref.watch(supabaseClientProvider);

      final raw = _toRow(
        await client.rpc(
          'get_gym_engagement_stats',
          params: {'p_gym_id': gymId},
        ),
      );

      final levelRaw = raw['level_distribution'];
      final levels = (levelRaw is List ? levelRaw : <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((item) {
            final m = Map<String, Object?>.from(item);
            return LevelBucket(
              range: m['level_range'] as String? ?? '',
              count: (m['member_count'] as num?)?.toInt() ?? 0,
            );
          })
          .toList();

      final topRaw = raw['top_members'];
      final top = (topRaw is List ? topRaw : <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((item) {
            final m = Map<String, Object?>.from(item);
            return TopMemberEntry(
              username: m['username'] as String? ?? '',
              avatarUrl: m['avatar_url'] as String?,
              totalXp: (m['total_xp'] as num?)?.toInt() ?? 0,
              level: (m['level'] as num?)?.toInt() ?? 1,
              trainingDaysThisMonth:
                  (m['training_days_this_month'] as num?)?.toInt() ?? 0,
            );
          })
          .toList();

      return GymEngagementStats(
        levelDistribution: levels,
        topMembers: top,
        activeChallenges: (raw['active_challenges'] as num?)?.toInt() ?? 0,
        totalActiveMembers: (raw['total_active_members'] as num?)?.toInt() ?? 0,
      );
    });

// =============================================================================
// Owner overview — single-call consolidated KPI endpoint
// =============================================================================

/// All KPIs for the owner overview screen, loaded in a single RPC call.
class OwnerOverviewStats {
  const OwnerOverviewStats({
    required this.funnelRegistered,
    required this.funnelJoined,
    required this.funnelFirstWorkout,
    required this.funnelActive7d,
    required this.funnelActive30d,
    required this.sessionsThisMonth,
    required this.workoutsPerActiveUser30d,
    required this.equipmentTotal,
    required this.equipmentWithNfc,
    required this.activeChallenges,
    required this.openJoinRequests,
    required this.openFeedbacks,
    required this.openReports,
  });

  final int funnelRegistered;
  final int funnelJoined;
  final int funnelFirstWorkout;
  final int funnelActive7d;
  final int funnelActive30d;
  final int sessionsThisMonth;
  final double workoutsPerActiveUser30d;
  final int equipmentTotal;
  final int equipmentWithNfc;
  final int activeChallenges;
  final int openJoinRequests;
  final int openFeedbacks;
  final int openReports;

  int get openTasksTotal => openJoinRequests + openFeedbacks + openReports;
  int get nfcCoveragePercent => equipmentTotal == 0
      ? 0
      : ((equipmentWithNfc / equipmentTotal) * 100).round();
}

/// Owner overview stats — backed by SECURITY DEFINER RPC.
final ownerOverviewProvider = FutureProvider.family<OwnerOverviewStats, String>(
  (ref, gymId) async {
    final client = ref.watch(supabaseClientProvider);

    final raw = _toRow(
      await client.rpc('get_owner_overview', params: {'p_gym_id': gymId}),
    );

    return OwnerOverviewStats(
      funnelRegistered: (raw['funnel_registered'] as num?)?.toInt() ?? 0,
      funnelJoined: (raw['funnel_joined'] as num?)?.toInt() ?? 0,
      funnelFirstWorkout: (raw['funnel_first_workout'] as num?)?.toInt() ?? 0,
      funnelActive7d: (raw['funnel_active_7d'] as num?)?.toInt() ?? 0,
      funnelActive30d: (raw['funnel_active_30d'] as num?)?.toInt() ?? 0,
      sessionsThisMonth: (raw['sessions_this_month'] as num?)?.toInt() ?? 0,
      workoutsPerActiveUser30d:
          (raw['workouts_per_active_user_30d'] as num?)?.toDouble() ?? 0,
      equipmentTotal: (raw['equipment_total'] as num?)?.toInt() ?? 0,
      equipmentWithNfc: (raw['equipment_with_nfc'] as num?)?.toInt() ?? 0,
      activeChallenges: (raw['active_challenges'] as num?)?.toInt() ?? 0,
      openJoinRequests: (raw['open_join_requests'] as num?)?.toInt() ?? 0,
      openFeedbacks: (raw['open_feedbacks'] as num?)?.toInt() ?? 0,
      openReports: (raw['open_reports'] as num?)?.toInt() ?? 0,
    );
  },
);

/// Equipment feedback for admin review.
final equipmentFeedbackAdminProvider =
    FutureProvider.family<List<EquipmentFeedbackItem>, String>((
      ref,
      gymId,
    ) async {
      final client = ref.watch(supabaseClientProvider);

      final rows = _toRows(
        await client
            .from('equipment_feedback')
            .select(
              'id, gym_id, equipment_id, equipment_name, feedback_type, message, '
              'status, created_at, '
              'user_profiles!equipment_feedback_user_id_fkey(username)',
            )
            .eq('gym_id', gymId)
            .order('created_at', ascending: false),
      );

      return rows.map((r) {
        final profile = _toRow(r['user_profiles']);
        return EquipmentFeedbackItem(
          id: _read(r, 'id', ''),
          gymId: _read(r, 'gym_id', ''),
          equipmentId: _read(r, 'equipment_id', ''),
          equipmentName: _read(r, 'equipment_name', ''),
          feedbackType: _read(r, 'feedback_type', 'broken'),
          message: r['message'] as String?,
          status: _read(r, 'status', 'open'),
          createdAt: DateTime.parse(
            _read(r, 'created_at', DateTime.now().toIso8601String()),
          ),
          reporterUsername: profile['username'] as String?,
        );
      }).toList();
    });

/// Content reports pending moderation.
final contentReportsProvider =
    FutureProvider.family<List<ContentReport>, String>((ref, gymId) async {
      final client = ref.watch(supabaseClientProvider);

      final rows = _toRows(
        await client
            .from('content_reports')
            .select(
              'id, gym_id, report_type, description, status, admin_note, '
              'resolved_at, created_at, '
              'reporter:reporter_id(username), '
              'target:target_user_id(username)',
            )
            .eq('gym_id', gymId)
            .order('created_at', ascending: false),
      );

      return rows.map((r) {
        final reporter = _toRow(r['reporter']);
        final target = _toRow(r['target']);
        final resolvedStr = r['resolved_at'] as String?;
        return ContentReport(
          id: _read(r, 'id', ''),
          gymId: _read(r, 'gym_id', ''),
          reportType: _read(r, 'report_type', 'other'),
          description: r['description'] as String?,
          status: _read(r, 'status', 'pending'),
          createdAt: DateTime.parse(
            _read(r, 'created_at', DateTime.now().toIso8601String()),
          ),
          reporterUsername: reporter['username'] as String?,
          targetUsername: target['username'] as String?,
          adminNote: r['admin_note'] as String?,
          resolvedAt: resolvedStr != null
              ? DateTime.tryParse(resolvedStr)
              : null,
        );
      }).toList();
    });

// =============================================================================
// Mutation notifiers
// =============================================================================

// ─── Gym settings ─────────────────────────────────────────────────────────────

class GymSettingsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateProfile({
    required String gymId,
    required String name,
    required String? description,
    bool? requiresApproval,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.rpc(
        'update_gym_profile',
        params: {
          'p_gym_id': gymId,
          'p_name': name,
          'p_description': description,
          if (requiresApproval != null) 'p_requires_approval': requiresApproval,
        },
      );
      ref.invalidate(adminGymInfoProvider(gymId));
    });
  }
}

final gymSettingsNotifierProvider =
    AsyncNotifierProvider<GymSettingsNotifier, void>(GymSettingsNotifier.new);

// ─── Member management ────────────────────────────────────────────────────────

class MemberManagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> approveRequest({
    required String gymId,
    required String userId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.rpc(
        'approve_member_request',
        params: {'p_gym_id': gymId, 'p_user_id': userId},
      );
      ref.invalidate(adminMembersProvider(gymId));
      ref.invalidate(pendingMemberCountProvider(gymId));
    });
  }

  Future<void> declineRequest({
    required String gymId,
    required String userId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.rpc(
        'decline_member_request',
        params: {'p_gym_id': gymId, 'p_user_id': userId},
      );
      ref.invalidate(adminMembersProvider(gymId));
      ref.invalidate(pendingMemberCountProvider(gymId));
    });
  }

  Future<void> deactivate({
    required String gymId,
    required String userId,
    String? reason,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.rpc(
        'deactivate_member',
        params: {
          'p_gym_id': gymId,
          'p_user_id': userId,
          if (reason != null) 'p_reason': reason,
        },
      );
      ref.invalidate(adminMembersProvider(gymId));
    });
  }
}

final memberManagementProvider =
    AsyncNotifierProvider<MemberManagementNotifier, void>(
      MemberManagementNotifier.new,
    );

// ─── Role management ──────────────────────────────────────────────────────────

class RoleManagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setRole({
    required String gymId,
    required String targetUserId,
    required String newRole,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.rpc(
        'set_member_role',
        params: {
          'p_gym_id': gymId,
          'p_target_id': targetUserId,
          'p_new_role': newRole,
        },
      );
      ref.invalidate(adminMembersProvider(gymId));
    });
  }
}

final roleManagementProvider =
    AsyncNotifierProvider<RoleManagementNotifier, void>(
      RoleManagementNotifier.new,
    );

// ─── Equipment admin ──────────────────────────────────────────────────────────

class EquipmentAdminNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addEquipment({
    required String gymId,
    required String name,
    required String equipmentType,
    required String zoneName,
    String? canonicalExerciseKey,
    String? manufacturer,
    String? model,
    String? description,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.from('gym_equipment').insert({
        'gym_id': gymId,
        'name': name.trim(),
        'equipment_type': equipmentType,
        'zone_name': zoneName.trim().isEmpty ? 'Main Floor' : zoneName.trim(),
        'canonical_exercise_key': canonicalExerciseKey,
        'manufacturer': manufacturer?.trim(),
        'model': model?.trim(),
        'is_active': true,
      });
      ref.invalidate(gymEquipmentProvider(gymId));
    });
  }

  Future<void> updateEquipment({
    required String gymId,
    required String equipmentId,
    required String name,
    required String equipmentType,
    required String zoneName,
    String? canonicalExerciseKey,
    String? manufacturer,
    String? model,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('gym_equipment')
          .update({
            'name': name.trim(),
            'equipment_type': equipmentType,
            'zone_name': zoneName.trim().isEmpty
                ? 'Main Floor'
                : zoneName.trim(),
            'canonical_exercise_key': canonicalExerciseKey,
            'manufacturer': manufacturer?.trim(),
            'model': model?.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', equipmentId)
          .eq('gym_id', gymId);
      ref.invalidate(gymEquipmentProvider(gymId));
    });
  }

  Future<void> setActive({
    required String gymId,
    required String equipmentId,
    required bool isActive,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('gym_equipment')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', equipmentId)
          .eq('gym_id', gymId);
      ref.invalidate(gymEquipmentProvider(gymId));
    });
  }
}

final equipmentAdminProvider =
    AsyncNotifierProvider<EquipmentAdminNotifier, void>(
      EquipmentAdminNotifier.new,
    );

// ─── Exercise template admin ──────────────────────────────────────────────────

class ExerciseTemplateAdminNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> upsertTemplate({
    required String gymId,
    required String key,
    required String name,
    String? description,
    required List<ExerciseMuscleGroup> muscleGroups,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);

      final primaryGroup = muscleGroups.where((m) => m.isPrimary).firstOrNull;

      // Upsert the exercise_template row
      await client.from('exercise_templates').upsert({
        'key': key,
        'gym_id': gymId,
        'name': name.trim(),
        'description': description?.trim(),
        'primary_muscle_group': primaryGroup?.muscleGroup.value,
        'is_active': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'key, gym_id');

      // Replace muscle group assignments: delete existing, insert new
      await client
          .from('exercise_muscle_groups')
          .delete()
          .eq('exercise_key', key)
          .eq('gym_id', gymId);

      if (muscleGroups.isNotEmpty) {
        await client
            .from('exercise_muscle_groups')
            .insert(
              muscleGroups
                  .map(
                    (mg) => {
                      'exercise_key': key,
                      'gym_id': gymId,
                      'muscle_group': mg.muscleGroup.value,
                      'role': mg.role.value,
                    },
                  )
                  .toList(),
            );
      }

      ref.invalidate(exerciseTemplatesProvider(gymId));
    });
  }

  Future<void> deactivateTemplate({
    required String gymId,
    required String key,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('exercise_templates')
          .update({'is_active': false})
          .eq('key', key)
          .eq('gym_id', gymId);
      ref.invalidate(exerciseTemplatesProvider(gymId));
    });
  }
}

final exerciseTemplateAdminProvider =
    AsyncNotifierProvider<ExerciseTemplateAdminNotifier, void>(
      ExerciseTemplateAdminNotifier.new,
    );

// ─── All templates including inactive (admin view) ────────────────────────────

final adminExerciseTemplatesProvider =
    FutureProvider.family<List<ExerciseTemplate>, String>((ref, gymId) async {
      final client = ref.watch(supabaseClientProvider);

      final rows = _toRows(
        await client
            .from('exercise_templates')
            .select(
              'key, gym_id, name, description, is_ranking_eligible, is_active, created_at, '
              'exercise_muscle_groups(muscle_group, role)',
            )
            .eq('gym_id', gymId)
            .order('name', ascending: true),
      );

      return rows.map((r) {
        final mgRows = _toRows(r['exercise_muscle_groups']);
        final groups = mgRows
            .map((w) {
              final group = MuscleGroup.tryFromValue(
                _read(w, 'muscle_group', ''),
              );
              if (group == null) return null;
              return ExerciseMuscleGroup(
                muscleGroup: group,
                role: MuscleGroupRole.fromValue(_read(w, 'role', 'secondary')),
              );
            })
            .whereType<ExerciseMuscleGroup>()
            .toList();

        return ExerciseTemplate(
          key: _read(r, 'key', ''),
          gymId: _read(r, 'gym_id', ''),
          name: _read(r, 'name', ''),
          isRankingEligible: _read(r, 'is_ranking_eligible', false),
          muscleGroups: groups,
          description: r['description'] as String?,
          isActive: _read(r, 'is_active', true),
          createdAt: DateTime.parse(
            _read(r, 'created_at', DateTime.now().toIso8601String()),
          ),
        );
      }).toList();
    });

// ─── Challenge management ─────────────────────────────────────────────────────

class ChallengeManagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createChallenge({
    required String gymId,
    required String title,
    String? description,
    required String challengeType,
    required double targetMetric,
    required DateTime startsAt,
    required DateTime endsAt,
    String visibility = 'all_members',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);
      await client.from('challenges').insert({
        'gym_id': gymId,
        'title': title.trim(),
        'description': description?.trim(),
        'challenge_type': challengeType,
        'target_metric': targetMetric,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'visibility': visibility,
        'is_active': true,
        'created_by': user?.id,
      });
      ref.invalidate(adminChallengesProvider(gymId));
    });
  }

  Future<void> deactivateChallenge({
    required String gymId,
    required String challengeId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('challenges')
          .update({'is_active': false})
          .eq('id', challengeId)
          .eq('gym_id', gymId);
      ref.invalidate(adminChallengesProvider(gymId));
    });
  }
}

final challengeManagementProvider =
    AsyncNotifierProvider<ChallengeManagementNotifier, void>(
      ChallengeManagementNotifier.new,
    );

// ─── Feedback management ──────────────────────────────────────────────────────

class FeedbackManagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateStatus({
    required String gymId,
    required String feedbackId,
    required String newStatus,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.rpc(
        'update_equipment_feedback_status',
        params: {'p_feedback_id': feedbackId, 'p_status': newStatus},
      );
      ref.invalidate(equipmentFeedbackAdminProvider(gymId));
    });
  }
}

final feedbackManagementProvider =
    AsyncNotifierProvider<FeedbackManagementNotifier, void>(
      FeedbackManagementNotifier.new,
    );

// ─── Moderation management ────────────────────────────────────────────────────

class ModerationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> resolveReport({
    required String gymId,
    required String reportId,
    required String action,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.rpc(
        'resolve_content_report',
        params: {
          'p_report_id': reportId,
          'p_action': action,
          if (note != null && note.isNotEmpty) 'p_note': note,
        },
      );
      ref.invalidate(contentReportsProvider(gymId));
    });
  }
}

final moderationNotifierProvider =
    AsyncNotifierProvider<ModerationNotifier, void>(ModerationNotifier.new);

// ─── Admin-side equipment list (all including inactive) ───────────────────────

final adminAllEquipmentProvider =
    FutureProvider.family<List<GymEquipment>, String>((ref, gymId) async {
      final client = ref.watch(supabaseClientProvider);

      final rows = _toRows(
        await client
            .from('gym_equipment')
            .select(
              'id, gym_id, name, equipment_type, zone_name, nfc_tag_uid, '
              'canonical_exercise_key, ranking_eligible_override, manufacturer, '
              'model, is_active, created_at',
            )
            .eq('gym_id', gymId)
            .order('name', ascending: true),
      );

      return rows.map((r) {
        return GymEquipment(
          id: _read(r, 'id', ''),
          gymId: _read(r, 'gym_id', ''),
          name: _read(r, 'name', ''),
          equipmentType: EquipmentType.fromValue(
            _read(r, 'equipment_type', 'fixed_machine'),
          ),
          zoneName: r['zone_name'] as String?,
          nfcTagUid: r['nfc_tag_uid'] as String?,
          canonicalExerciseKey: r['canonical_exercise_key'] as String?,
          rankingEligibleOverride: r['ranking_eligible_override'] as bool?,
          manufacturer: r['manufacturer'] as String?,
          model: r['model'] as String?,
          isActive: _read(r, 'is_active', true),
          createdAt: DateTime.parse(
            _read(r, 'created_at', DateTime.now().toIso8601String()),
          ),
        );
      }).toList();
    });
