import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/services/nfc_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../widgets/common/tapem_button.dart';
import '../providers/equipment_provider.dart';
import '../providers/workout_provider.dart';
import 'equipment_picker_screen.dart';

class WorkoutStartHubScreen extends HookConsumerWidget {
  const WorkoutStartHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    final workoutState = ref.watch(workoutProvider);
    final isScanning = useState(false);

    if (gymId == null) {
      return const Scaffold(
        body: Center(child: Text('No active gym. Join a gym first.')),
      );
    }

    // Resuming: DB check still running — show spinner, block interaction.
    if (workoutState is WorkoutResuming || workoutState is WorkoutStarting) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Active workout exists — pop modal and let ScaffoldWithNavBar switch tabs.
    if (workoutState is WorkoutActive) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('START WORKOUT'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _ResumeWorkoutCard(
            session: workoutState.session,
            onResume: () => Navigator.of(context).pop(),
            onDiscard: () => _discardActive(context, ref),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('START WORKOUT'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NfcStartCard(
              gymId: gymId,
              isScanning: isScanning.value,
              onScanStart: () => _doNfcScan(context, ref, gymId, isScanning),
              onScanCancel: () async {
                await ref.read(nfcServiceProvider).cancelScan();
                isScanning.value = false;
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR SELECT MANUALLY',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _EquipmentTypeSelector(gymId: gymId),
          ],
        ),
      ),
    );
  }

  Future<void> _discardActive(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DISCARD WORKOUT?'),
        content: const Text(
          'All sets from this session will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('KEEP'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'DISCARD',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(workoutProvider.notifier).discardSession();
    }
  }

  Future<void> _doNfcScan(
    BuildContext context,
    WidgetRef ref,
    String gymId,
    ValueNotifier<bool> isScanning,
  ) async {
    isScanning.value = true;
    final result = await ref.read(nfcServiceProvider).scanTagOnce();
    isScanning.value = false;

    if (!context.mounted) return;

    switch (result) {
      case NfcScanSuccess(:final uid, :final equipmentId):
        // Search active gym first, then all membership gyms (cross-gym support).
        GymEquipment? equipment;
        String? resolvedGymId;

        final memberships = await ref.read(userMembershipsProvider.future);
        final gymsToSearch = [
          gymId,
          ...memberships.map((m) => m.gymId).where((id) => id != gymId),
        ];

        for (final gid in gymsToSearch) {
          if (equipmentId != null) {
            final all = await ref.read(gymEquipmentProvider(gid).future);
            equipment = all.where((e) => e.id == equipmentId).firstOrNull;
          } else {
            equipment = await ref.read(
              nfcEquipmentProvider((gymId: gid, tagUid: uid)).future,
            );
          }
          if (equipment != null) {
            resolvedGymId = gid;
            break;
          }
        }

        if (!context.mounted) return;
        if (equipment == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unbekannter NFC-Tag — wähle das Gerät manuell'),
            ),
          );
          return;
        }

        // Auto-switch gym if tag belongs to a different one.
        if (resolvedGymId != null && resolvedGymId != gymId) {
          await ref
              .read(activeGymIdProvider.notifier)
              .setActiveGym(resolvedGymId);
          if (context.mounted) {
            final m = memberships
                .where((m) => m.gymId == resolvedGymId)
                .firstOrNull;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Studio gewechselt: ${m?.gymName ?? resolvedGymId}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }

        if (!context.mounted) return;
        await _startFromEquipment(context, ref, equipment);

      case NfcScanFailure(:final reason):
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NFC-Scan fehlgeschlagen: $reason'),
            action: SnackBarAction(label: 'MANUELL', onPressed: () {}),
          ),
        );

      case NfcScanCancelled():
        break;
    }
  }

  Future<void> _startFromEquipment(
    BuildContext context,
    WidgetRef ref,
    GymEquipment equipment,
  ) async {
    final notifier = ref.read(workoutProvider.notifier);

    switch (equipment.equipmentType) {
      case EquipmentType.fixedMachine:
        await notifier.startSession(
          equipmentId: equipment.id,
          equipmentName: equipment.displayName,
          canonicalExerciseKey: equipment.canonicalExerciseKey ?? '',
          canonicalExerciseName: equipment.displayName,
        );

      case EquipmentType.openStation:
        if (!context.mounted) return;
        final exercise = await Navigator.of(context)
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
                  equipmentName: equipment.displayName,
                ),
              ),
            );
        if (exercise == null) return;
        await notifier.startSession(
          equipmentId: equipment.id,
          equipmentName: equipment.displayName,
          canonicalExerciseKey: exercise.exerciseKey,
          canonicalExerciseName: exercise.displayName,
        );

      case EquipmentType.cardio:
        await notifier.startSession(
          equipmentId: equipment.id,
          equipmentName: equipment.displayName,
          canonicalExerciseKey: 'cardio:${equipment.id}',
          canonicalExerciseName: equipment.displayName,
        );
    }

    if (!context.mounted) return;
    final workoutState = ref.read(workoutProvider);
    if (workoutState is WorkoutActive) {
      // Pop this modal — ScaffoldWithNavBar will auto-switch to the Workout tab.
      Navigator.of(context).pop();
    }
  }
}

// ─── Resume workout card ──────────────────────────────────────────────────────

class _ResumeWorkoutCard extends StatelessWidget {
  const _ResumeWorkoutCard({
    required this.session,
    required this.onResume,
    required this.onDiscard,
  });

  final LocalWorkoutSession session;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(session.startedAt);
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final elapsedStr = elapsed.inHours > 0 ? '$h:$m:$s' : '$m:$s';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonCyan.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.fitness_center, color: AppColors.neonCyan, size: 24),
              SizedBox(width: 12),
              Text('WORKOUT IN PROGRESS', style: AppTextStyles.labelLg),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            elapsedStr,
            style: AppTextStyles.monoLg.copyWith(color: AppColors.neonCyan),
          ),
          const SizedBox(height: 4),
          Text(
            'Started at ${_fmtTime(session.startedAt)}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          TapemButton(
            label: 'RESUME WORKOUT',
            icon: Icons.play_arrow,
            onPressed: onResume,
          ),
          const SizedBox(height: 12),
          TapemButton(
            label: 'DISCARD',
            icon: Icons.delete_forever_outlined,
            variant: TapemButtonVariant.ghost,
            onPressed: onDiscard,
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── NFC Start Card ───────────────────────────────────────────────────────────

class _NfcStartCard extends ConsumerWidget {
  const _NfcStartCard({
    required this.gymId,
    required this.isScanning,
    required this.onScanStart,
    required this.onScanCancel,
  });

  final String gymId;
  final bool isScanning;
  final VoidCallback onScanStart;
  final VoidCallback onScanCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nfcAvailable = ref.watch(nfcAvailableProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isScanning
              ? AppColors.neonCyan
              : AppColors.neonCyan.withAlpha(80),
          width: isScanning ? 2 : 1,
        ),
        boxShadow: isScanning
            ? [
                const BoxShadow(
                  color: AppColors.neonCyanGlow,
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isScanning
                ? const SizedBox(
                    key: ValueKey('scanning'),
                    height: 56,
                    width: 56,
                    child: CircularProgressIndicator(
                      color: AppColors.neonCyan,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(
                    key: ValueKey('icon'),
                    Icons.nfc,
                    size: 56,
                    color: AppColors.neonCyan,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            isScanning ? 'HOLD NEAR MACHINE TAG' : 'NFC SCAN',
            style: AppTextStyles.h3.copyWith(color: AppColors.neonCyan),
          ),
          const SizedBox(height: 4),
          Text(
            isScanning
                ? 'Keep your phone steady...'
                : 'Tap your phone to the machine\'s NFC tag',
            style: AppTextStyles.bodySm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          nfcAvailable.when(
            data: (available) => available
                ? TapemButton(
                    label: isScanning ? 'CANCEL SCAN' : 'SCAN NFC TAG',
                    icon: isScanning ? Icons.close : Icons.sensors,
                    onPressed: isScanning ? onScanCancel : onScanStart,
                    variant: isScanning
                        ? TapemButtonVariant.outlined
                        : TapemButtonVariant.primary,
                  )
                : Text(
                    'NFC not available on this device',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textDisabled,
                    ),
                    textAlign: TextAlign.center,
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Equipment type selector ──────────────────────────────────────────────────

class _EquipmentTypeSelector extends StatelessWidget {
  const _EquipmentTypeSelector({required this.gymId});
  final String gymId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ALL equipment — search across everything
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AllEquipmentCard(gymId: gymId),
        ),
        // Type-specific
        ...EquipmentType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EquipmentTypeCard(gymId: gymId, type: type),
          ),
        ),
      ],
    );
  }
}

class _AllEquipmentCard extends StatelessWidget {
  const _AllEquipmentCard({required this.gymId});
  final String gymId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EquipmentPickerScreen(gymId: gymId)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withAlpha(40)),
              ),
              child: const Icon(
                Icons.grid_view_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ALL EQUIPMENT', style: AppTextStyles.labelLg),
                  Text(
                    'Browse & search all machines',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _EquipmentTypeCard extends StatelessWidget {
  const _EquipmentTypeCard({required this.gymId, required this.type});
  final String gymId;
  final EquipmentType type;

  @override
  Widget build(BuildContext context) {
    final (icon, label, description, color) = switch (type) {
      EquipmentType.fixedMachine => (
        Icons.fitness_center_outlined,
        'FIXED MACHINE',
        'One canonical exercise — quick start',
        AppColors.neonCyan,
      ),
      EquipmentType.openStation => (
        Icons.fitness_center_outlined,
        'OPEN STATION',
        'Free weights & multi-use — choose exercise',
        AppColors.neonMagenta,
      ),
      EquipmentType.cardio => (
        Icons.directions_run_outlined,
        'CARDIO',
        'Time-based session tracking',
        AppColors.neonYellow,
      ),
    };

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EquipmentPickerScreen(gymId: gymId, type: type),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelLg),
                  Text(description, style: AppTextStyles.bodySm),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
