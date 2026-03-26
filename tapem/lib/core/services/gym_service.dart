import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

import '../config/app_config.dart';
import '../../presentation/features/auth/providers/auth_provider.dart';

const _kActiveGymIdKey = 'active_gym_id';

/// SharedPreferences key written when a workout session becomes active and
/// removed when it is finished or discarded.
///
/// Used for two purposes:
///   1. Allows [WorkoutNotifier.resumeActiveSession] to restore the session
///      directly from SQLite even when [activeGymIdProvider] is temporarily
///      null (e.g. after a transient Supabase auth event).
///   2. Prevents [ActiveGymNotifier.clear] from wiping the gym ID from disk
///      while a workout is in progress — without the gym ID the recovery path
///      in [resumeActiveSession] cannot restore the session after re-auth.
// ignore: constant_identifier_names
const kActiveWorkoutSessionKey = 'tapem_active_session_id_v1';

// ─── SharedPreferences provider ───────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Override in ProviderScope with SharedPreferences.getInstance()',
  );
});

// ─── Active gym ───────────────────────────────────────────────────────────────

/// The gym the current user is actively working in.
/// Null until the user selects/joins a gym.
final activeGymIdProvider = StateNotifierProvider<ActiveGymNotifier, String?>(
  (ref) => ActiveGymNotifier(ref),
);

class ActiveGymNotifier extends StateNotifier<String?> {
  ActiveGymNotifier(this._ref) : super(null) {
    // Listen for auth *events*, not just session presence.
    //
    // Using authStateProvider (which exposes the raw AuthChangeEvent) instead
    // of authSessionProvider (Session? only) lets us distinguish an explicit
    // sign-out from a transient token-refresh failure.
    //
    // Supabase can emit AuthChangeEvent.signedOut transiently when the SDK
    // fails to refresh the JWT mid-session (e.g., brief network drop at the
    // ~60-minute token boundary).  Reacting to that by wiping the active gym
    // from SharedPreferences would kick the user to the gym-setup screen and
    // make their in-progress workout appear lost — even though the SQLite data
    // is still intact.
    //
    // We therefore only call clear() on an *explicit* AuthChangeEvent.signedOut,
    // which is emitted when the user deliberately signs out via AuthNotifier or
    // when the refresh token itself is expired/revoked (genuine session end).
    _authSub = _ref.listen(authStateProvider, (prev, next) {
      if (next.valueOrNull?.event == AuthChangeEvent.signedOut) {
        unawaited(clear());
      }
    });
    unawaited(_load());
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthState>> _authSub;

  @override
  void dispose() {
    _authSub.close();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final storedId = prefs.getString(_kActiveGymIdKey);
    if (storedId == null) return;

    // Only restore if a user session is currently active. On a cold start after
    // sign-out the SharedPreferences key may still hold the previous user's gym.
    final client = _ref.read(supabaseClientProvider);
    if (client.auth.currentSession == null) {
      await prefs.remove(_kActiveGymIdKey);
      return;
    }
    state = storedId;
  }

  Future<void> setActiveGym(String gymId) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(_kActiveGymIdKey, gymId);
    state = gymId;
  }

  Future<void> clear() async {
    final prefs = _ref.read(sharedPreferencesProvider);

    // Never wipe the gym ID from disk while a workout session is in progress.
    //
    // The session's gymId (stored in SQLite) is the recovery anchor: without
    // a matching activeGymIdProvider, resumeActiveSession cannot restore the
    // workout after re-authentication. We still null the in-memory state so
    // any auth-sensitive UI reacts correctly — the next _load() call (on
    // re-auth) will restore it from SharedPreferences automatically.
    if (!prefs.containsKey(kActiveWorkoutSessionKey)) {
      await prefs.remove(_kActiveGymIdKey);
    }
    state = null;
  }
}

// ─── Memberships for current user ─────────────────────────────────────────────

class GymMembership {
  const GymMembership({
    required this.gymId,
    required this.gymName,
    required this.role,
    required this.isActive,
  });

  final String gymId;
  final String gymName;
  final String role;
  final bool isActive;
}

final userMembershipsProvider = FutureProvider<List<GymMembership>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('memberships')
      .select('gym_id, role, is_active, tenant_gyms(name)')
      .eq('user_id', user.id)
      .eq('is_active', true);

  final typedRows = (rows as List)
      .whereType<Map<dynamic, dynamic>>()
      .map((row) => Map<String, Object?>.from(row))
      .toList(growable: false);

  return typedRows.map((r) {
    final gym = (r['tenant_gyms'] as Map<dynamic, dynamic>?)
        ?.cast<String, Object?>();
    return GymMembership(
      gymId: r['gym_id'] as String,
      gymName: gym?['name'] as String? ?? 'Unknown Gym',
      role: r['role'] as String,
      isActive: r['is_active'] as bool,
    );
  }).toList();
});

/// Resolved membership object for the active gym.
final activeMembershipProvider = FutureProvider<GymMembership?>((ref) async {
  final gymId = ref.watch(activeGymIdProvider);
  if (gymId == null) return null;
  final memberships = await ref.watch(userMembershipsProvider.future);
  try {
    return memberships.firstWhere((m) => m.gymId == gymId);
  } catch (_) {
    return null;
  }
});

/// True if the active user is admin/owner of their active gym.
final isGymAdminProvider = FutureProvider<bool>((ref) async {
  final m = await ref.watch(activeMembershipProvider.future);
  return m != null && (m.role == 'admin' || m.role == 'owner');
});

/// Performance budget: app start to interactive home < 2s.
/// This constant is used to assert timing in integration tests.
// ignore: unused_element
const _kAppStartBudgetMs = AppConfig.workoutStartBudgetMs;
