import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Supabase client ──────────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// ─── Auth state stream (event + session) ─────────────────────────────────────
//
// Exposes the raw [AuthState] so consumers can inspect the [AuthChangeEvent]
// and distinguish an explicit sign-out from a transient token-refresh failure.

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

// ─── Auth session stream ──────────────────────────────────────────────────────

final authSessionProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((e) => e.session);
});

// ─── Current user ─────────────────────────────────────────────────────────────

final currentUserProvider = Provider<User?>((ref) {
  final streamUser = ref.watch(authSessionProvider).valueOrNull?.user;
  if (streamUser != null) return streamUser;
  // Fall back to the synchronous SDK value during stream startup or transient
  // token-refresh gaps — prevents data providers from seeing a spurious null
  // and clearing cached data (e.g. profile screen showing "Kein Profil").
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

// ─── Auth route state (for router guard) ──────────────────────────────────────

class AuthRouteState {
  const AuthRouteState({required this.hasProfile});
  final bool hasProfile;
}

final authRouteStreamProvider = StreamProvider<AuthRouteState?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);

  await for (final authState in client.auth.onAuthStateChange) {
    final user = authState.session?.user;

    if (user == null) {
      // Only yield null (→ redirect to login) on an *explicit* sign-out.
      // Transient events such as a failed token refresh at the ~60-minute
      // boundary must NOT redirect the user mid-session — the data is still
      // intact in SQLite and the SDK will retry the refresh automatically.
      //
      // Cold start without a stored session arrives as `initialSession` with
      // `session == null` and must also route to login.
      if (authState.event == AuthChangeEvent.signedOut ||
          authState.event == AuthChangeEvent.initialSession) {
        yield null;
      }
      continue;
    }

    try {
      final profile = await client
          .from('user_profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      yield AuthRouteState(hasProfile: profile != null);
    } catch (_) {
      // Profile check failed — treat as no profile so user reaches setup.
      yield const AuthRouteState(hasProfile: false);
    }
  }
});

// Must match kActiveWorkoutSessionKey in gym_service.dart — kept separate to
// avoid a circular import (gym_service.dart imports auth_provider.dart).
const _kActiveWorkoutSessionKey = 'tapem_active_session_id_v1';

// ─── Auth actions notifier ────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signInWithPassword(email: email, password: password);
    });
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signUp(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Clear the workout anchor key BEFORE signing out so the router's
      // active-workout guard cannot block the redirect to /auth/login.
      // This also covers the case where the server-side revocation fails
      // (expired token, offline) and we fall back to a local-only sign-out.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kActiveWorkoutSessionKey);

      try {
        await _client.auth.signOut();
      } catch (_) {
        // Server-side token revocation failed (e.g. expired token, no network).
        // Local-only sign-out always clears the stored session and emits the
        // signedOut event, ensuring the router redirects to login.
        await _client.auth.signOut(scope: SignOutScope.local);
      }
    });
  }

  Future<void> sendPasswordReset({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.resetPasswordForEmail(email);
    });
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);
