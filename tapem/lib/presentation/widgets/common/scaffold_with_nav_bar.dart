import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/deep_link_service.dart';
import '../../../core/services/gym_service.dart';
import '../../../core/services/nfc_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../../domain/entities/gym/gym_equipment.dart';
import '../../features/workout/providers/equipment_provider.dart';
import '../../features/workout/providers/workout_provider.dart';
import '../../features/workout/screens/equipment_picker_screen.dart';

/// Bottom navigation shell — wraps the main tab destinations.
///
/// Responsibilities beyond navigation:
///   • Manages the foreground NFC session on Android (silent, continuous).
///   • Listens for deep links (`tapem://e/<id>`) from [deepLinkStreamProvider].
///   • Routes NFC / deep-link equipment to [_handleEquipment].
///   • Auto-switches to the Workout tab when a session starts.
class ScaffoldWithNavBar extends HookConsumerWidget {
  const ScaffoldWithNavBar({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static List<int> _visibleBranches({
    required bool isWorkoutActive,
    required bool isAdmin,
  }) {
    return [0, 1, if (isWorkoutActive) 2, 3, 4, if (isAdmin) 5];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider);
    final isWorkoutActive =
        workoutState is WorkoutActive || workoutState is WorkoutResuming;
    final isAdmin = ref.watch(isGymAdminProvider).valueOrNull ?? false;
    final gymId = ref.watch(activeGymIdProvider);

    final branches = _visibleBranches(
      isWorkoutActive: isWorkoutActive,
      isAdmin: isAdmin,
    );

    final currentBranch = shell.currentIndex;
    int selectedTabIndex = branches.indexOf(currentBranch);
    if (selectedTabIndex == -1) selectedTabIndex = 0;

    // ── Workout tab: auto-switch when session starts or ends ─────────────────
    ref.listen<WorkoutState>(workoutProvider, (prev, next) {
      if (next is WorkoutIdle && shell.currentIndex == 2) {
        shell.goBranch(0);
      }
      if (prev is! WorkoutActive && next is WorkoutActive) {
        shell.goBranch(2);
      }
    });

    // ── Deep link listener ───────────────────────────────────────────────────
    ref.listen(deepLinkStreamProvider, (_, next) {
      if (!next.hasValue) return;
      final equipmentId = equipmentIdFromLink(next.value!);
      if (equipmentId == null) return;
      unawaited(
        _resolveAndDispatch(
          context: context,
          ref: ref,
          equipmentId: equipmentId,
          uid: null,
          activeGymId: gymId,
        ),
      );
    });

    // ── Pending NFC / deep-link equipment handler ────────────────────────────
    ref.listen<GymEquipment?>(pendingNfcEquipmentProvider, (_, equipment) {
      if (equipment == null) return;
      ref.read(pendingNfcEquipmentProvider.notifier).state = null;
      _handleEquipment(context, ref, equipment);
    });

    // ── Android: continuous foreground NFC session ───────────────────────────
    useEffect(() {
      if (!Platform.isAndroid || gymId == null) return null;

      final nfc = ref.read(nfcServiceProvider);
      unawaited(
        nfc.startForegroundSession(
          onTag: (equipmentId, uid) => unawaited(
            _resolveAndDispatch(
              context: context,
              ref: ref,
              equipmentId: equipmentId,
              uid: uid,
              activeGymId: gymId,
            ),
          ),
        ),
      );
      return () => unawaited(nfc.stopForegroundSession());
    }, [gymId]);

    return Scaffold(
      body: shell,
      bottomNavigationBar: _CyberpunkNavBar(
        isWorkoutActive: isWorkoutActive,
        isAdmin: isAdmin,
        selectedIndex: selectedTabIndex,
        onDestinationSelected: (tabIndex) {
          shell.goBranch(
            branches[tabIndex],
            initialLocation: branches[tabIndex] == shell.currentIndex,
          );
        },
      ),
    );
  }

  /// Resolves an NFC tag (by NDEF equipment ID or raw UID) across ALL gyms the
  /// user is a member of. If found in a different gym than the active one:
  ///   • No active workout → auto-switch gym, then dispatch.
  ///   • Active workout running → show a snackbar; do NOT switch mid-workout.
  Future<void> _resolveAndDispatch({
    required BuildContext context,
    required WidgetRef ref,
    required String? equipmentId,
    required String? uid,
    required String? activeGymId,
  }) async {
    final memberships = await ref.read(userMembershipsProvider.future);
    if (memberships.isEmpty) return;

    GymEquipment? equipment;
    String? resolvedGymId;

    // ── Search active gym first (fastest — no network needed) ───────────────
    if (activeGymId != null) {
      if (equipmentId != null) {
        final all = await ref.read(gymEquipmentProvider(activeGymId).future);
        equipment = all.where((e) => e.id == equipmentId).firstOrNull;
      } else if (uid != null) {
        equipment = await ref.read(
          nfcEquipmentProvider((gymId: activeGymId, tagUid: uid)).future,
        );
      }
      if (equipment != null) resolvedGymId = activeGymId;
    }

    // ── If not found, search all other membership gyms ──────────────────────
    if (equipment == null) {
      for (final m in memberships) {
        if (m.gymId == activeGymId) continue;
        if (equipmentId != null) {
          final all = await ref.read(gymEquipmentProvider(m.gymId).future);
          equipment = all.where((e) => e.id == equipmentId).firstOrNull;
        } else if (uid != null) {
          equipment = await ref.read(
            nfcEquipmentProvider((gymId: m.gymId, tagUid: uid)).future,
          );
        }
        if (equipment != null) {
          resolvedGymId = m.gymId;
          break;
        }
      }
    }

    if (equipment == null || resolvedGymId == null) return;
    if (!context.mounted) return;

    // ── Tag belongs to a different gym ───────────────────────────────────────
    if (resolvedGymId != activeGymId) {
      final workoutState = ref.read(workoutProvider);
      if (workoutState is WorkoutActive) {
        // Cannot auto-switch during an active workout.
        final membership = memberships
            .where((m) => m.gymId == resolvedGymId)
            .firstOrNull;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dieser Tag gehört zu '
              '"${membership?.gymName ?? "einem anderen Studio"}". '
              'Beende zuerst dein Training.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Auto-switch to the gym that owns this tag.
      final membership = memberships
          .where((m) => m.gymId == resolvedGymId)
          .firstOrNull;
      await ref.read(activeGymIdProvider.notifier).setActiveGym(resolvedGymId);

      if (context.mounted && membership != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Studio gewechselt: ${membership.gymName}',
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    ref.read(pendingNfcEquipmentProvider.notifier).state = equipment;
  }

  void _handleEquipment(
    BuildContext context,
    WidgetRef ref,
    GymEquipment equipment,
  ) {
    final workoutState = ref.read(workoutProvider);
    final notifier = ref.read(workoutProvider.notifier);
    final isActive = workoutState is WorkoutActive;

    switch (equipment.equipmentType) {
      case EquipmentType.fixedMachine:
        if (isActive) {
          unawaited(
            notifier.addExercise(
              exerciseKey: equipment.canonicalExerciseKey ?? '',
              displayName: equipment.name,
              equipmentId: equipment.id,
            ),
          );
        } else {
          unawaited(
            notifier.startSession(
              equipmentId: equipment.id,
              equipmentName: equipment.name,
              canonicalExerciseKey: equipment.canonicalExerciseKey ?? '',
              canonicalExerciseName: equipment.name,
            ),
          );
        }

      case EquipmentType.openStation:
        unawaited(
          Navigator.of(context)
              .push<
                ({
                  String exerciseKey,
                  String displayName,
                  String? customExerciseId,
                })
              >(
                MaterialPageRoute(
                  builder: (_) => ExercisePickerSheet(
                    gymId: equipment.gymId,
                    equipmentId: equipment.id,
                    equipmentName: equipment.name,
                  ),
                ),
              )
              .then((exercise) {
                if (exercise == null) return;
                if (isActive) {
                  unawaited(
                    notifier.addExercise(
                      exerciseKey: exercise.exerciseKey,
                      displayName: exercise.displayName,
                      equipmentId: equipment.id,
                      customExerciseId: exercise.customExerciseId,
                    ),
                  );
                } else {
                  unawaited(
                    notifier.startSession(
                      equipmentId: equipment.id,
                      equipmentName: equipment.name,
                      canonicalExerciseKey: exercise.exerciseKey,
                      canonicalExerciseName: exercise.displayName,
                    ),
                  );
                }
              }),
        );

      case EquipmentType.cardio:
        if (isActive) {
          unawaited(
            notifier.addExercise(
              exerciseKey: 'cardio:${equipment.id}',
              displayName: equipment.name,
              equipmentId: equipment.id,
            ),
          );
        } else {
          unawaited(
            notifier.startSession(
              equipmentId: equipment.id,
              equipmentName: equipment.name,
              canonicalExerciseKey: 'cardio:${equipment.id}',
              canonicalExerciseName: equipment.name,
              isCardio: true,
            ),
          );
        }
    }
  }
}

// ─── Custom nav bar ───────────────────────────────────────────────────────────

class _CyberpunkNavBar extends StatelessWidget {
  const _CyberpunkNavBar({
    required this.isWorkoutActive,
    required this.isAdmin,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final bool isWorkoutActive;
  final bool isAdmin;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  List<NavigationDestination> _buildDestinations(BuildContext context) {
    final l10n = context.l10n;
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.navHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.fitness_center_outlined),
        selectedIcon: const Icon(Icons.fitness_center),
        label: l10n.navGym,
      ),
      if (isWorkoutActive)
        NavigationDestination(
          icon: const Icon(Icons.sports_gymnastics_outlined),
          selectedIcon: const Icon(Icons.sports_gymnastics),
          label: l10n.navWorkout,
        ),
      NavigationDestination(
        icon: const Icon(Icons.bar_chart_outlined),
        selectedIcon: const Icon(Icons.bar_chart),
        label: l10n.navProgress,
      ),
      NavigationDestination(
        icon: const Icon(Icons.people_outline),
        selectedIcon: const Icon(Icons.people),
        label: l10n.navCommunity,
      ),
      if (isAdmin)
        NavigationDestination(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: const Icon(Icons.admin_panel_settings),
          label: l10n.navAdmin,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isOnWorkoutTab = isWorkoutActive && selectedIndex == 2;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface800,
        border: Border(top: BorderSide(color: AppColors.surface500, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: _buildDestinations(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: isOnWorkoutTab
            ? AppColors.neonCyan.withAlpha(60)
            : accent.withAlpha(40),
      ),
    );
  }
}
