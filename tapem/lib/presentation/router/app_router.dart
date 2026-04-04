import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import '../features/admin/screens/admin_gym_settings_screen.dart';
import '../features/admin/screens/admin_equipment_screen.dart';
import '../features/admin/screens/admin_exercise_templates_screen.dart';
import '../features/admin/screens/admin_members_screen.dart';
import '../features/admin/screens/admin_roles_screen.dart';
import '../features/admin/screens/admin_challenges_screen.dart';
import '../features/admin/screens/admin_analytics_screen.dart';
import '../features/admin/screens/admin_equipment_analytics_screen.dart';
import '../features/admin/screens/admin_engagement_screen.dart';
import '../features/admin/screens/admin_moderation_screen.dart';
import '../features/admin/screens/admin_equipment_feedback_screen.dart';
import '../features/admin/screens/admin_owner_overview_screen.dart';
import '../features/floor_plan/screens/admin_floor_plan_screen.dart';
import '../features/plans/screens/plan_builder_screen.dart';
import '../features/plans/screens/plans_screen.dart';
import '../widgets/common/scaffold_with_nav_bar.dart';
import 'route_names.dart';
import '../features/nutrition/screens/nutrition_home_screen.dart';
import '../features/nutrition/screens/nutrition_day_screen.dart';
import '../features/nutrition/screens/nutrition_goals_screen.dart';
import '../features/nutrition/screens/nutrition_entry_screen.dart';
import '../features/nutrition/screens/nutrition_search_screen.dart';
import '../features/nutrition/screens/nutrition_scan_screen.dart';
import '../features/nutrition/screens/nutrition_recipes_screen.dart';
import '../features/nutrition/screens/nutrition_recipe_edit_screen.dart';
import '../features/nutrition/screens/nutrition_weight_screen.dart';
import '../features/nutrition/screens/nutrition_calendar_screen.dart';

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
          // Only protect an active workout when the SDK still has a user in
          // memory (mid-session token-refresh failure scenario). If there is
          // no user at all the key is a stale leftover — clear it immediately
          // so the redirect to login is never blocked again.
          final client = ref.read(supabaseClientProvider);
          if (client.auth.currentUser != null) {
            return null; // Workout in progress — do NOT interrupt.
          }
          unawaited(prefs.remove(kActiveWorkoutSessionKey));
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
        pageBuilder: (c, s) => _fadeScalePage(c, s, const LoginScreen()),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        pageBuilder: (c, s) => _slidePage(c, s, const RegisterScreen()),
      ),
      GoRoute(
        path: RouteNames.usernameSetup,
        name: 'username-setup',
        pageBuilder: (c, s) => _slidePage(c, s, const UsernameSetupScreen()),
      ),
      GoRoute(
        path: RouteNames.gymSetup,
        name: 'gym-setup',
        pageBuilder: (c, s) => _slidePage(c, s, const GymSetupScreen()),
      ),

      // ── Profile (full-screen overlay, not a tab) ─────────────────────────
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        pageBuilder: (c, s) => _fadeScalePage(c, s, const ProfileScreen()),
      ),

      // ── Nutrition (full-screen, not a tab) ──────────────────────────────
      GoRoute(
        path: RouteNames.nutrition,
        name: 'nutrition',
        pageBuilder: (c, s) => _slidePage(c, s, const NutritionHomeScreen()),
        routes: [
          GoRoute(
            path: 'day',
            name: 'nutrition-day',
            pageBuilder: (c, s) => _slidePage(c, s, const NutritionDayScreen()),
          ),
          GoRoute(
            path: 'goals',
            name: 'nutrition-goals',
            pageBuilder: (c, s) =>
                _slidePage(c, s, const NutritionGoalsScreen()),
          ),
          GoRoute(
            path: 'entry',
            name: 'nutrition-entry',
            pageBuilder: (c, s) =>
                _slidePage(c, s, const NutritionEntryScreen()),
          ),
          GoRoute(
            path: 'search',
            name: 'nutrition-search',
            pageBuilder: (c, s) => _slidePage(
              c,
              s,
              NutritionSearchScreen(
                extra: (s.extra as Map<String, dynamic>?) ?? {},
              ),
            ),
          ),
          GoRoute(
            path: 'scan',
            name: 'nutrition-scan',
            pageBuilder: (c, s) => _slidePage(
              c,
              s,
              NutritionScanScreen(
                extra: (s.extra as Map<String, dynamic>?) ?? {},
              ),
            ),
          ),
          GoRoute(
            path: 'recipes',
            name: 'nutrition-recipes',
            pageBuilder: (c, s) => _slidePage(
              c,
              s,
              NutritionRecipesScreen(
                extra: (s.extra as Map<String, dynamic>?) ?? {},
              ),
            ),
          ),
          GoRoute(
            path: 'recipe-edit',
            name: 'nutrition-recipe-edit',
            pageBuilder: (c, s) => _slidePage(
              c,
              s,
              NutritionRecipeEditScreen(
                extra: (s.extra as Map<String, dynamic>?) ?? {},
              ),
            ),
          ),
          GoRoute(
            path: 'weight',
            name: 'nutrition-weight',
            pageBuilder: (c, s) =>
                _slidePage(c, s, const NutritionWeightScreen()),
          ),
          GoRoute(
            path: 'calendar',
            name: 'nutrition-calendar',
            pageBuilder: (c, s) => _slidePage(
              c,
              s,
              NutritionCalendarScreen(
                extra: (s.extra as Map<String, dynamic>?) ?? {},
              ),
            ),
          ),
        ],
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
                    pageBuilder: (c, s) => _slidePage(c, s, const PlansScreen()),
                    routes: [
                      GoRoute(
                        path: 'new',
                        name: 'plan-new',
                        pageBuilder: (c, s) => _slidePage(
                          c,
                          s,
                          const PlanBuilderScreen(editPlanId: null),
                        ),
                      ),
                      GoRoute(
                        path: ':planId/edit',
                        name: 'plan-edit',
                        pageBuilder: (c, s) => _slidePage(
                          c,
                          s,
                          PlanBuilderScreen(
                            editPlanId: s.pathParameters['planId'],
                          ),
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
                redirect: (_, __) {
                  final isAdmin =
                      ref.read(isGymAdminProvider).valueOrNull ?? false;
                  return isAdmin ? null : RouteNames.home;
                },
                builder: (_, __) => const AdminScreen(),
                routes: _adminSubRoutes(ref),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ─── Admin sub-route builder ──────────────────────────────────────────────────
// All admin sub-routes share the same guard: caller must be gym admin/owner.
// Extracted to keep the main route tree readable.

List<GoRoute> _adminSubRoutes(Ref ref) {
  GoRouterRedirect adminGuard() => (_, __) {
        final isAdmin = ref.read(isGymAdminProvider).valueOrNull ?? false;
        return isAdmin ? null : RouteNames.home;
      };

  return [
    GoRoute(
      path: 'nfc',
      name: 'admin-nfc',
      redirect: adminGuard(),
      pageBuilder: (c, s) => _slidePage(c, s, const AdminNfcScreen()),
    ),
    GoRoute(
      path: 'gym-settings',
      name: 'admin-gym-settings',
      redirect: adminGuard(),
      pageBuilder: (c, s) => _slidePage(c, s, const AdminGymSettingsScreen()),
    ),
    GoRoute(
      path: 'equipment',
      name: 'admin-equipment',
      redirect: adminGuard(),
      pageBuilder: (c, s) => _slidePage(c, s, const AdminEquipmentScreen()),
    ),
    GoRoute(
      path: 'exercises',
      name: 'admin-exercises',
      redirect: adminGuard(),
      pageBuilder: (c, s) =>
          _slidePage(c, s, const AdminExerciseTemplatesScreen()),
    ),
    GoRoute(
      path: 'members',
      name: 'admin-members',
      redirect: adminGuard(),
      pageBuilder: (c, s) => _slidePage(c, s, const AdminMembersScreen()),
    ),
    GoRoute(
      path: 'roles',
      name: 'admin-roles',
      redirect: adminGuard(),
      pageBuilder: (c, s) => _slidePage(c, s, const AdminRolesScreen()),
    ),
    GoRoute(
      path: 'challenges',
      name: 'admin-challenges',
      redirect: adminGuard(),
      pageBuilder: (c, s) => _slidePage(c, s, const AdminChallengesScreen()),
    ),
    GoRoute(
      path: 'analytics',
      name: 'admin-analytics',
      redirect: adminGuard(),
      pageBuilder: (c, s) => _slidePage(c, s, const AdminAnalyticsScreen()),
    ),
    GoRoute(
      path: 'equipment-analytics',
      name: 'admin-equipment-analytics',
      redirect: adminGuard(),
      pageBuilder: (c, s) =>
          _slidePage(c, s, const AdminEquipmentAnalyticsScreen()),
    ),
    GoRoute(
      path: 'engagement',
      name: 'admin-engagement',
      redirect: adminGuard(),
      pageBuilder: (c, s) => _slidePage(c, s, const AdminEngagementScreen()),
    ),
    GoRoute(
      path: 'moderation',
      name: 'admin-moderation',
      redirect: adminGuard(),
      pageBuilder: (c, s) => _slidePage(c, s, const AdminModerationScreen()),
    ),
    GoRoute(
      path: 'equipment-feedback',
      name: 'admin-equipment-feedback',
      redirect: adminGuard(),
      pageBuilder: (c, s) =>
          _slidePage(c, s, const AdminEquipmentFeedbackScreen()),
    ),
    GoRoute(
      path: 'floor-plan',
      name: 'admin-floor-plan',
      redirect: adminGuard(),
      pageBuilder: (c, s) => _slidePage(c, s, const AdminFloorPlanScreen()),
    ),
    GoRoute(
      path: 'owner-overview',
      name: 'admin-owner-overview',
      redirect: adminGuard(),
      pageBuilder: (c, s) =>
          _slidePage(c, s, const AdminOwnerOverviewScreen()),
    ),
  ];
}

// ─── Transition helpers ───────────────────────────────────────────────────────

/// Slide from right (standard detail push).
CustomTransitionPage<void> _slidePage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curve),
        child: FadeTransition(opacity: curve, child: child),
      );
    },
  );
}

/// Fade + scale up (modal/overlay screens).
CustomTransitionPage<void> _fadeScalePage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
          child: child,
        ),
      );
    },
  );
}

/// [ChangeNotifier] that fires whenever auth state, active gym, or admin role
/// changes, triggering GoRouter to re-evaluate all redirect rules including
/// the admin route guard.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(Ref ref) {
    _authSub = ref.listen(
      authRouteStreamProvider,
      (_, __) => notifyListeners(),
    );
    _gymSub = ref.listen(activeGymIdProvider, (_, __) => notifyListeners());
    _adminSub = ref.listen(isGymAdminProvider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription<dynamic> _authSub;
  late final ProviderSubscription<dynamic> _gymSub;
  late final ProviderSubscription<dynamic> _adminSub;

  @override
  void dispose() {
    _authSub.close();
    _gymSub.close();
    _adminSub.close();
    super.dispose();
  }
}
