import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/services/nfc_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/gym_service.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../features/workout/providers/equipment_provider.dart';
import '../../../../core/services/database_service.dart';

/// Admin screen for assigning and writing NFC tags to gym equipment.
///
/// Workflow:
///   1. Select equipment from the list.
///   2. Tap a tag to read its UID and write the Tap'em NDEF URL.
///   3. The tag UID is saved to the equipment record in the local DB
///      (server sync happens automatically via the sync service).
class AdminNfcScreen extends HookConsumerWidget {
  const AdminNfcScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    final equipmentAsync = gymId != null
        ? ref.watch(gymEquipmentProvider(gymId))
        : const AsyncValue<List<GymEquipment>>.loading();

    final selectedEquipment = useState<GymEquipment?>(null);
    final scanState = useState<_ScanState>(_ScanState.idle);
    final lastResult = useState<String?>(null);
    final errorMessage = useState<String?>(null);

    Future<void> assignAndWrite(GymEquipment equipment) async {
      if (gymId == null) return;
      scanState.value = _ScanState.scanning;
      errorMessage.value = null;
      lastResult.value = null;

      final nfc = ref.read(nfcServiceProvider);
      final db = ref.read(appDatabaseProvider);

      final result = await nfc.scanForWrite(
        onTagReady: (tag, uid) async {
          // 1. Write NDEF URL to the physical tag.
          final writeResult = await nfc.writeEquipmentTag(tag, equipment.id);
          if (writeResult is NfcWriteFailure) {
            throw Exception(writeResult.reason);
          }
          // 2. Persist the UID in the local DB (triggers server sync).
          await db.updateNfcTagUid(equipment.id, uid);
          // 3. Invalidate cache so the UI reflects the new UID.
          ref.invalidate(gymEquipmentProvider(gymId));
        },
      );

      switch (result) {
        case NfcScanSuccess(:final uid):
          scanState.value = _ScanState.success;
          lastResult.value = uid;
          selectedEquipment.value = null;
        case NfcScanFailure(:final reason):
          scanState.value = _ScanState.error;
          errorMessage.value = reason;
        case NfcScanCancelled():
          scanState.value = _ScanState.idle;
      }
    }

    Future<void> clearTag(GymEquipment equipment) async {
      if (gymId == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('NFC-TAG ENTFERNEN?'),
          content: Text(
            'Der NFC-Tag von "${equipment.name}" wird entfernt. '
            'Das physische Tag wird dabei nicht gelöscht.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ABBRECHEN'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'ENTFERNEN',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final db = ref.read(appDatabaseProvider);
      await db.updateNfcTagUid(equipment.id, null);
      ref.invalidate(gymEquipmentProvider(gymId));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC TAG ZUWEISUNG'),
        backgroundColor: AppColors.surface900,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Scan panel ─────────────────────────────────────────────────────
          _ScanPanel(
            equipment: selectedEquipment.value,
            scanState: scanState.value,
            lastUid: lastResult.value,
            errorMessage: errorMessage.value,
            onScan: selectedEquipment.value != null
                ? () => assignAndWrite(selectedEquipment.value!)
                : null,
            onReset: () {
              scanState.value = _ScanState.idle;
              errorMessage.value = null;
              lastResult.value = null;
            },
          ),

          const Divider(height: 1),

          // ── Equipment list ─────────────────────────────────────────────────
          Expanded(
            child: equipmentAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('Keine Geräte gefunden.'));
                }
                // Sort: without NFC tag first (need assignment), then with tag.
                final sorted = [...list]
                  ..sort((a, b) {
                    final aHas = a.nfcTagUid != null ? 1 : 0;
                    final bHas = b.nfcTagUid != null ? 1 : 0;
                    if (aHas != bHas) return aHas - bHas;
                    return a.name.compareTo(b.name);
                  });
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final eq = sorted[i];
                    final isSelected = selectedEquipment.value?.id == eq.id;
                    return _EquipmentTile(
                      equipment: eq,
                      isSelected: isSelected,
                      onTap: () {
                        selectedEquipment.value = isSelected ? null : eq;
                        scanState.value = _ScanState.idle;
                        errorMessage.value = null;
                        lastResult.value = null;
                      },
                      onClearTag: eq.nfcTagUid != null
                          ? () => clearTag(eq)
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan state ───────────────────────────────────────────────────────────────

enum _ScanState { idle, scanning, success, error }

// ─── Scan panel ───────────────────────────────────────────────────────────────

class _ScanPanel extends StatelessWidget {
  const _ScanPanel({
    required this.equipment,
    required this.scanState,
    required this.lastUid,
    required this.errorMessage,
    required this.onScan,
    required this.onReset,
  });

  final GymEquipment? equipment;
  final _ScanState scanState;
  final String? lastUid;
  final String? errorMessage;
  final VoidCallback? onScan;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (equipment == null)
            Text(
              'Gerät aus der Liste auswählen',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.nfc, color: AppColors.neonCyan, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    equipment!.name,
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.neonCyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              equipment!.nfcTagUid != null
                  ? 'Aktueller Tag: ${equipment!.nfcTagUid}'
                  : 'Kein Tag zugewiesen',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildStatusWidget(context),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context) {
    switch (scanState) {
      case _ScanState.idle:
        return ElevatedButton.icon(
          onPressed: onScan,
          icon: const Icon(Icons.nfc),
          label: Text(
            equipment != null ? 'TAG SCANNEN & BESCHREIBEN' : 'GERÄT WÄHLEN',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: equipment != null
                ? AppColors.neonCyan
                : AppColors.surface500,
            foregroundColor: AppColors.surface900,
          ),
        );

      case _ScanState.scanning:
        return Column(
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.neonCyan,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Halte das Handy an den NFC-Tag...',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _ScanState.success:
        return Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 36),
            const SizedBox(height: 8),
            Text(
              'Tag erfolgreich beschrieben!',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
            if (lastUid != null) ...[
              const SizedBox(height: 4),
              Text(
                'UID: $lastUid',
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: onReset,
              child: const Text('WEITERES GERÄT ZUWEISEN'),
            ),
          ],
        );

      case _ScanState.error:
        return Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 36),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unbekannter Fehler',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onReset,
              child: const Text('ERNEUT VERSUCHEN'),
            ),
          ],
        );
    }
  }
}

// ─── Equipment tile ───────────────────────────────────────────────────────────

class _EquipmentTile extends StatelessWidget {
  const _EquipmentTile({
    required this.equipment,
    required this.isSelected,
    required this.onTap,
    required this.onClearTag,
  });

  final GymEquipment equipment;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onClearTag;

  @override
  Widget build(BuildContext context) {
    final hasTag = equipment.nfcTagUid != null;
    final borderColor = isSelected
        ? AppColors.neonCyan
        : hasTag
        ? AppColors.success.withAlpha(80)
        : AppColors.surface500;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonCyan.withAlpha(15)
              : AppColors.surface800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(
              hasTag ? Icons.nfc : Icons.nfc_outlined,
              size: 20,
              color: hasTag ? AppColors.success : AppColors.textDisabled,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equipment.name, style: AppTextStyles.bodyLg),
                  if (hasTag)
                    Text(
                      equipment.nfcTagUid!,
                      style: AppTextStyles.monoSm.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    )
                  else
                    Text(
                      'Kein Tag',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.chevron_right, color: AppColors.neonCyan),
            if (!isSelected && hasTag && onClearTag != null)
              IconButton(
                icon: const Icon(Icons.link_off, size: 18),
                color: AppColors.textSecondary,
                tooltip: 'Tag-Zuweisung entfernen',
                onPressed: onClearTag,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }
}
