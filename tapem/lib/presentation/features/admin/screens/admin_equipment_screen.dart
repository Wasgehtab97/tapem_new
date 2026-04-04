import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../router/route_names.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../providers/admin_providers.dart';

class AdminEquipmentScreen extends HookConsumerWidget {
  const AdminEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) return const _AdminEquipmentError('Kein aktives Gym.');

    final equipAsync = ref.watch(adminAllEquipmentProvider(gymId));
    final searchCtrl = useTextEditingController();
    final searchQuery = useState('');

    useEffect(() {
      searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
      return null;
    }, []);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('GERÄTE VERWALTEN'),
        backgroundColor: AppColors.surface900,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEquipmentForm(context, ref, gymId, null),
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.surface900,
        icon: const Icon(Icons.add),
        label: const Text('GERÄT HINZUFÜGEN'),
      ),
      body: equipAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _AdminEquipmentError(e.toString()),
        data: (all) {
          final q = searchQuery.value.trim().toLowerCase();
          final filtered = q.isEmpty
              ? all
              : all
                  .where(
                    (e) =>
                        e.name.toLowerCase().contains(q) ||
                        (e.manufacturer?.toLowerCase().contains(q) ?? false),
                  )
                  .toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Gerät suchen...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: searchCtrl.clear,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Summary stats
              _EquipmentStats(all: all),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyEquipmentView(
                        hasSearch: q.isNotEmpty,
                        onAdd: () =>
                            _showEquipmentForm(context, ref, gymId, null),
                      )
                    : _EquipmentList(
                        items: filtered,
                        gymId: gymId,
                        ref: ref,
                        onEdit: (eq) =>
                            _showEquipmentForm(context, ref, gymId, eq),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Stats bar ────────────────────────────────────────────────────────────────

class _EquipmentStats extends StatelessWidget {
  const _EquipmentStats({required this.all});
  final List<GymEquipment> all;

  @override
  Widget build(BuildContext context) {
    final active = all.where((e) => e.isActive).length;
    final withNfc = all.where((e) => e.nfcTagUid != null).length;
    final inactive = all.where((e) => !e.isActive).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatChip(label: '$active AKTIV', color: AppColors.success),
          const SizedBox(width: 8),
          _StatChip(
            label: '$withNfc MIT NFC',
            color: AppColors.neonCyan,
          ),
          if (inactive > 0) ...[
            const SizedBox(width: 8),
            _StatChip(
              label: '$inactive INAKTIV',
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}

// ─── Equipment list ───────────────────────────────────────────────────────────

class _EquipmentList extends StatelessWidget {
  const _EquipmentList({
    required this.items,
    required this.gymId,
    required this.ref,
    required this.onEdit,
  });

  final List<GymEquipment> items;
  final String gymId;
  final WidgetRef ref;
  final void Function(GymEquipment) onEdit;

  @override
  Widget build(BuildContext context) {
    // Group by type for visual clarity
    final groups = {
      EquipmentType.fixedMachine: <GymEquipment>[],
      EquipmentType.openStation: <GymEquipment>[],
      EquipmentType.cardio: <GymEquipment>[],
    };
    for (final e in items) {
      groups[e.equipmentType]?.add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        for (final type in EquipmentType.values)
          if (groups[type]!.isNotEmpty) ...[
            _TypeHeader(type: type),
            ...groups[type]!.map(
              (eq) => _EquipmentTile(
                equipment: eq,
                gymId: gymId,
                ref: ref,
                onEdit: () => onEdit(eq),
              ),
            ),
          ],
      ],
    );
  }
}

class _TypeHeader extends StatelessWidget {
  const _TypeHeader({required this.type});
  final EquipmentType type;

  String get label => switch (type) {
        EquipmentType.fixedMachine => 'MASCHINEN',
        EquipmentType.openStation => 'OPEN STATIONS',
        EquipmentType.cardio => 'CARDIO',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  const _EquipmentTile({
    required this.equipment,
    required this.gymId,
    required this.ref,
    required this.onEdit,
  });

  final GymEquipment equipment;
  final String gymId;
  final WidgetRef ref;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasNfc = equipment.nfcTagUid != null;
    final isActive = equipment.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surface800 : AppColors.surface700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? AppColors.surface500 : AppColors.surface500.withAlpha(80),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          _typeIcon(equipment.equipmentType),
          color: isActive ? AppColors.neonCyan : AppColors.textDisabled,
          size: 22,
        ),
        title: Text(
          equipment.name,
          style: AppTextStyles.bodyLg.copyWith(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        subtitle: Row(
          children: [
            if (!isActive)
              const _Badge(label: 'INAKTIV', color: AppColors.textDisabled),
            if (isActive)
              _Badge(
                label: hasNfc ? 'NFC' : 'KEIN NFC',
                color: hasNfc ? AppColors.success : AppColors.textDisabled,
              ),
            if (equipment.manufacturer != null) ...[
              const SizedBox(width: 6),
              Text(
                equipment.manufacturer!,
                style: AppTextStyles.bodySm,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.textSecondary,
          ),
          onSelected: (action) => _handleAction(context, action),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Bearbeiten'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'nfc',
              child: ListTile(
                leading: const Icon(Icons.nfc),
                title: const Text('NFC-Tag zuweisen'),
                contentPadding: EdgeInsets.zero,
                enabled: isActive,
              ),
            ),
            PopupMenuItem(
              value: isActive ? 'deactivate' : 'activate',
              child: ListTile(
                leading: Icon(
                  isActive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: isActive ? AppColors.error : AppColors.success,
                ),
                title: Text(
                  isActive ? 'Deaktivieren' : 'Aktivieren',
                  style: TextStyle(
                    color: isActive ? AppColors.error : AppColors.success,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(EquipmentType type) => switch (type) {
        EquipmentType.fixedMachine => Icons.precision_manufacturing_outlined,
        EquipmentType.openStation => Icons.fitness_center,
        EquipmentType.cardio => Icons.directions_run,
      };

  Future<void> _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'edit':
        onEdit();
      case 'nfc':
        unawaited(context.push(RouteNames.adminNfc));
      case 'deactivate':
        await _confirmAndDeactivate(context);
      case 'activate':
        await ref
            .read(equipmentAdminProvider.notifier)
            .setActive(
              gymId: gymId,
              equipmentId: equipment.id,
              isActive: true,
            );
    }
  }

  Future<void> _confirmAndDeactivate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface800,
        title: const Text('GERÄT DEAKTIVIEREN?'),
        content: Text(
          '"${equipment.name}" wird für Mitglieder ausgeblendet. '
          'Historische Trainingsdaten bleiben erhalten.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('DEAKTIVIEREN'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(equipmentAdminProvider.notifier)
          .setActive(
            gymId: gymId,
            equipmentId: equipment.id,
            isActive: false,
          );
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _EmptyEquipmentView extends StatelessWidget {
  const _EmptyEquipmentView({required this.hasSearch, required this.onAdd});
  final bool hasSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.precision_manufacturing_outlined,
              size: 56,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'Kein Gerät gefunden.' : 'Noch keine Geräte.',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 8),
              Text(
                'Füge dein erstes Gerät hinzu, damit Mitglieder ihr Training tracken können.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TapemButton(
                label: 'ERSTES GERÄT HINZUFÜGEN',
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Add / Edit form ──────────────────────────────────────────────────────────

Future<void> _showEquipmentForm(
  BuildContext context,
  WidgetRef ref,
  String gymId,
  GymEquipment? existing,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface800,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _EquipmentFormSheet(
      gymId: gymId,
      existing: existing,
    ),
  );
}

class _EquipmentFormSheet extends HookConsumerWidget {
  const _EquipmentFormSheet({required this.gymId, this.existing});

  final String gymId;
  final GymEquipment? existing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = useTextEditingController(text: existing?.name ?? '');
    final mfrCtrl = useTextEditingController(
      text: existing?.manufacturer ?? '',
    );
    final modelCtrl = useTextEditingController(text: existing?.model ?? '');
    final canonicalCtrl = useTextEditingController(
      text: existing?.canonicalExerciseKey ?? '',
    );
    final selectedType = useState(existing?.equipmentType ?? EquipmentType.fixedMachine);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final notifier = ref.watch(equipmentAdminProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null ? 'GERÄT HINZUFÜGEN' : 'GERÄT BEARBEITEN',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 20),

            // Type selector
            const Text('GERÄTETYP', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            Row(
              children: EquipmentType.values.map((type) {
                final isSelected = selectedType.value == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => selectedType.value = type,
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.neonCyan.withAlpha(30)
                            : AppColors.surface700,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.neonCyan
                              : AppColors.surface500,
                        ),
                      ),
                      child: Text(
                        _typeLabel(type),
                        style: AppTextStyles.labelMd.copyWith(
                          color: isSelected
                              ? AppColors.neonCyan
                              : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TapemTextField(
              label: 'NAME',
              controller: nameCtrl,
              hintText: 'z.B. Beinpresse',
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.length < 3 || s.length > 60) {
                  return '3–60 Zeichen';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            if (selectedType.value == EquipmentType.fixedMachine) ...[
              TapemTextField(
                label: 'ÜBUNGS-KEY (für Maschinen)',
                controller: canonicalCtrl,
                hintText: 'z.B. leg_press',
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (selectedType.value == EquipmentType.fixedMachine &&
                      s.isEmpty) {
                    return 'Übungs-Key erforderlich für Maschinen';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: TapemTextField(
                    label: 'HERSTELLER',
                    controller: mfrCtrl,
                    hintText: 'z.B. Technogym',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TapemTextField(
                    label: 'MODELL',
                    controller: modelCtrl,
                    hintText: 'optional',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TapemButton(
              label: existing == null ? 'HINZUFÜGEN' : 'SPEICHERN',
              isLoading: notifier.isLoading,
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;

                final type = selectedType.value;
                final n = ref.read(equipmentAdminProvider.notifier);

                if (existing == null) {
                  await n.addEquipment(
                    gymId: gymId,
                    name: nameCtrl.text,
                    equipmentType: type.value,
                    zoneName: 'Main Floor',
                    canonicalExerciseKey:
                        type == EquipmentType.fixedMachine &&
                                canonicalCtrl.text.trim().isNotEmpty
                            ? canonicalCtrl.text.trim()
                            : null,
                    manufacturer: mfrCtrl.text.trim().isEmpty
                        ? null
                        : mfrCtrl.text.trim(),
                    model: modelCtrl.text.trim().isEmpty
                        ? null
                        : modelCtrl.text.trim(),
                  );
                } else {
                  await n.updateEquipment(
                    gymId: gymId,
                    equipmentId: existing!.id,
                    name: nameCtrl.text,
                    equipmentType: type.value,
                    zoneName: existing!.zoneName ?? 'Main Floor',
                    canonicalExerciseKey:
                        type == EquipmentType.fixedMachine &&
                                canonicalCtrl.text.trim().isNotEmpty
                            ? canonicalCtrl.text.trim()
                            : null,
                    manufacturer: mfrCtrl.text.trim().isEmpty
                        ? null
                        : mfrCtrl.text.trim(),
                    model: modelCtrl.text.trim().isEmpty
                        ? null
                        : modelCtrl.text.trim(),
                  );
                }

                if (context.mounted) {
                  final err = ref.read(equipmentAdminProvider).error;
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fehler: $err'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(EquipmentType type) => switch (type) {
        EquipmentType.fixedMachine => 'MASCHINE',
        EquipmentType.openStation => 'OPEN',
        EquipmentType.cardio => 'CARDIO',
      };
}

class _AdminEquipmentError extends StatelessWidget {
  const _AdminEquipmentError(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('GERÄTE VERWALTEN'),
        backgroundColor: AppColors.surface900,
      ),
      body: Center(
        child: Text(
          message,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}
