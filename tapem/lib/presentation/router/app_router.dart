import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/gym_service.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/username_setup_screen.dart';
import '../features/gym/screens/gym_setup_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/gym/screens/gym_screen.dart';
import '../features/workout/screens/active_workout_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/community/screens/community_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/admin/screens/admin_screen.dart';
import '../features/admin/screens/admin_nfc_screen.dart';
import '../features/plans/screens/plan_builder_screen.dart';
import '../features/plans/screens/plans_screen.dart';
import '../widgets/common/scaffold_with_nav_bar.dart';
import 'route_names.dart';

/// Provides a fully-configured [GoRouter] instance.
/// Auth/gym changes are handled via [_AuthStateNotifier] as refreshListenable,
/// so the router is created once and re-evaluates redirect on state changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthStateNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: RouteNames.home,
    redirect: (context, state) {
      // Read current state at redirect time (not captured at creation time)
      final authState = ref.read(authRouteStreamProvider);
      final activeGymId = ref.read(activeGymIdProvider);

      // Don't redirect while auth is still resolving — prevents login screen flicker
      if (authState.isLoading) return null;

      final routeState = authState.valueOrNull;
      final isLoggedIn = routeState != null;
      final hasProfile = routeState?.hasProfile ?? false;
      final location = state.uri.path;
      final isAuthRoute = location.startsWith('/auth');

      // ── Active-workout protection ─────────────────────────────────────────
      // Never redirect a user to the login or auth screens while they have an
      // active workout session.  The session is durably persisted in SQLite
      // and the anchor key in SharedPreferences guarantees it can be restored
      // after re-authentication.  Sending the user to login mid-workout is
      // disorienting and unnecessary — the workout runs offline-first and does
      // not need a valid JWT until the user presses FINISH.
      if (!isLoggedIn && !isAuthRoute) {
        final prefs = ref.read(sharedPreferencesProvider);
        if (prefs.containsKey(kActiveWorkoutSessionKey)) {
          return null; // Stay on current screen — do NOT interrupt the workout.
        }
        return RouteNames.login;
      }
      if (isLoggedIn && !hasProfile && location != RouteNames.usernameSetup) {
        return RouteNames.usernameSetup;
      }
      if (isLoggedIn &&
          hasProfile &&
          activeGymId == null &&
          location != RouteNames.gymSetup) {
        return RouteNames.gymSetup;
      }
      if (isLoggedIn && hasProfile && activeGymId != null && isAuthRoute) {
        return RouteNames.home;
      }

      return null;
    },
    refreshListenable: notifier,
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.usernameSetup,
        name: 'username-setup',
        builder: (_, __) => const UsernameSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.gymSetup,
        name: 'gym-setup',
        builder: (_, __) => const GymSetupScreen(),
      ),

      // ── Profile (full-screen overlay, not a tab) ─────────────────────────
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),

      // ── Main shell ────────────────────────────────────────────────────────
      // 6 branches, always present. Nav bar shows 4–6 tabs depending on
      // whether a workout is active and whether the user is a gym admin.
      //   Branch 0: Home       /
      //   Branch 1: Gym        /gym
      //   Branch 2: Workout    /workout/active  (hidden in nav when inactive)
      //   Branch 3: Progress   /progress
      //   Branch 4: Community  /community
      //   Branch 5: Admin      /admin           (hidden in nav for non-admins)
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ScaffoldWithNavBar(shell: shell),
        branches: [
          // Branch 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                name: 'home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1 — Gym
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.gym,
                name: 'gym',
                builder: (_, __) => const GymScreen(),
              ),
            ],
          ),
          // Branch 2 — Active workout (hidden in nav when no session running)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.activeWorkout,
                name: 'active-workout',
                builder: (_, __) => const ActiveWorkoutScreen(),
              ),
            ],
          ),
          // Branch 3 — Progress
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.progress,
                name: 'progress',
                builder: (_, __) => const ProgressScreen(),
                routes: [
                  GoRoute(
                    path: 'plans',
                    name: 'plans',
                    builder: (_, __) => const PlansScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        name: 'plan-new',
                        builder: (_, __) =>
                            const PlanBuilderScreen(editPlanId: null),
                      ),
                      GoRoute(
                        path: ':planId/edit',
                        name: 'plan-edit',
                        builder: (_, state) => PlanBuilderScreen(
                          editPlanId: state.pathParameters['planId'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch 4 — Community
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.community,
                name: 'community',
                builder: (_, __) => const CommunityScreen(),
              ),
            ],
          ),
          // Branch 5 — Admin (only visible in nav for admin/owner role)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.admin,
                name: 'admin',
                builder: (_, __) => const AdminScreen(),
                routes: [
                  GoRoute(
                    path: 'nfc',
                    name: 'admin-nfc',
                    builder: (_, __) => const AdminNfcScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// [ChangeNotifier] that fires whenever auth state or active gym changes,
/// triggering GoRouter to re-evaluate redirect rules.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(Ref ref) {
    _authSub = ref.listen(
      authRouteStreamProvider,
      (_, __) => notifyListeners(),
    );
    _gymSub = ref.listen(activeGymIdProvider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription<dynamic> _authSub;
  late final ProviderSubscription<dynamic> _gymSub;

  @override
  void dispose() {
    _authSub.close();
    _gymSub.close();
    super.dispose();
  }
}
