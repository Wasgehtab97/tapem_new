import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/streak_calculator.dart';
import '../../../../domain/entities/streak/streak_info.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/progress/providers/xp_provider.dart';

/// Server-authoritative streak provider.
///
/// Primary path: calls the `get_user_streak(p_user_id)` RPC on Supabase.
/// This is cross-year correct and covers all historically synced sessions.
///
/// Fallback path: if the user is offline or the RPC call fails, the streak
/// is computed client-side from [trainingDaysProvider] for the current year.
/// This is accurate for users whose streak does not span a year boundary.
final streakProvider = FutureProvider<StreakInfo>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return StreakInfo.empty;

  final client = ref.watch(supabaseClientProvider);

  try {
    // PostgREST RPC returns a List containing one row per RETURNS TABLE row.
    final result = await client.rpc(
      'get_user_streak',
      params: {'p_user_id': user.id},
    );

    final rows = result as List;
    if (rows.isEmpty) return StreakInfo.empty;

    final row = Map<String, Object?>.from(rows.first as Map);
    final lastDateStr = row['last_training_date'] as String?;

    return StreakInfo(
      currentStreak: (row['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (row['longest_streak'] as num?)?.toInt() ?? 0,
      graceDaysRemaining:
          (row['grace_days_remaining'] as num?)?.toInt() ?? 0,
      lastTrainingDate:
          lastDateStr != null ? DateTime.parse(lastDateStr) : null,
    );
  } catch (_) {
    // Offline / RPC unavailable — fall back to client-side computation.
    final currentYear = DateTime.now().year;
    final days =
        await ref.watch(trainingDaysProvider(currentYear).future);
    return StreakCalculator.compute(days);
  }
});
