import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/gym/exercise_muscle_group.dart';
import '../../../../domain/entities/gym/exercise_template.dart';
import '../../../../domain/entities/gym/muscle_group.dart';
import '../../../../domain/entities/gym/muscle_group_role.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../providers/admin_providers.dart';


class AdminExerciseTemplatesScreen extends HookConsumerWidget {
  const AdminExerciseTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) return _errorScaffold('Kein aktives Gym.');

    final templatesAsync = ref.watch(adminExerciseTemplatesProvider(gymId));
    final searchCtrl = useTextEditingController();
    final searchQuery = useState('');

    useEffect(() {
      searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
      return null;
    }, []);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('ÜBUNGSVORLAGEN'),
        backgroundColor: AppColors.surface900,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateForm(context, ref, gymId, null),
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.surface900,
        icon: const Icon(Icons.add),
        label: const Text('ÜBUNG HINZUFÜGEN'),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
        ),
        data: (templates) {
          final q = searchQuery.value.trim().toLowerCase();
          final gym = templates
              .where((t) => t.gymId == gymId)
              .where((t) => q.isEmpty || t.name.toLowerCase().contains(q))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Übung suchen...',
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    if (gym.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'DEINE GYM ÜBUNGEN (${gym.length})',
                        color: AppColors.neonCyan,
                      ),
                      ...gym.map(
                        (t) => _TemplateTile(
                          template: t,
                          gymId: gymId,
                          isEditable: true,
                          onTap: () =>
                              _showTemplateForm(context, ref, gymId, t),
                        ),
                      ),
                    ],
                    if (gym.isEmpty && q.isEmpty)
                      _EmptyTemplatesView(
                        onAdd: () =>
                            _showTemplateForm(context, ref, gymId, null),
                      ),
                    if (gym.isEmpty && q.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'Keine Übung gefunden.',
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(color: color),
      ),
    );
  }
}

// ─── Template tile ────────────────────────────────────────────────────────────

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.gymId,
    required this.isEditable,
    required this.onTap,
  });

  final ExerciseTemplate template;
  final String gymId;
  final bool isEditable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = template.primaryGroup;
    final isActive = template.isActive;

    return GestureDetector(
      onTap: isEditable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.surface500 : AppColors.surface500.withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (primary != null)
                        _MuscleChip(
                          label: primary.displayNameDe,
                          isPrimary: true,
                        ),
                      ...template.secondaryMuscleGroups.take(2).map(
                            (mg) => _MuscleChip(
                              label: mg.muscleGroup.displayNameDe,
                              isPrimary: false,
                            ),
                          ),
                      if (!isActive)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: _Badge(
                            label: 'INAKTIV',
                            color: AppColors.textDisabled,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isEditable)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.label, required this.isPrimary});
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? AppColors.neonMagenta : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.bodySm.copyWith(color: color, fontSize: 9),
      ),
    );
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

class _EmptyTemplatesView extends StatelessWidget {
  const _EmptyTemplatesView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.category_outlined,
            size: 56,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine eigenen Übungen.',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle gym-spezifische Übungen mit Muskelgruppen-Zuordnung für das XP-System.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TapemButton(
            label: 'ERSTE ÜBUNG ERSTELLEN',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

// ─── Add / Edit form sheet ────────────────────────────────────────────────────

Future<void> _showTemplateForm(
  BuildContext context,
  WidgetRef ref,
  String gymId,
  ExerciseTemplate? existing,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface800,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) =>
        _TemplateFormSheet(gymId: gymId, existing: existing),
  );
}

class _TemplateFormSheet extends HookConsumerWidget {
  const _TemplateFormSheet({required this.gymId, this.existing});

  final String gymId;
  final ExerciseTemplate? existing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = useTextEditingController(text: existing?.name ?? '');
    final descCtrl = useTextEditingController(
      text: existing?.description ?? '',
    );
    final selectedPrimary = useState<MuscleGroup?>(existing?.primaryGroup);
    final selectedSecondary = useState<Set<MuscleGroup>>(
      existing?.secondaryMuscleGroups
          .map((m) => m.muscleGroup)
          .toSet() ?? {},
    );
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final notifier = ref.watch(exerciseTemplateAdminProvider);

    // Derive a key from the name (slug format)
    String keyFromName(String name) {
      return name
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Form(
        key: formKey,
        child: ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          children: [
            Text(
              existing == null ? 'ÜBUNG HINZUFÜGEN' : 'ÜBUNG BEARBEITEN',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 20),

            TapemTextField(
              label: 'NAME',
              controller: nameCtrl,
              hintText: 'z.B. Beinpresse',
              validator: (v) {
                if ((v?.trim() ?? '').length < 2) {
                  return 'Mindestens 2 Zeichen';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TapemTextField(
              label: 'BESCHREIBUNG (optional)',
              controller: descCtrl,
              maxLines: 2,
              hintText: 'Kurze Beschreibung der Übung',
            ),
            const SizedBox(height: 20),

            // Primary muscle group
            const Text('PRIMÄRE MUSKELGRUPPE', style: AppTextStyles.labelMd),
            const Text(
              'Die Hauptmuskelgruppe, die diese Übung beansprucht.',
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: 8),
            _MuscleGroupPicker(
              selected: selectedPrimary.value,
              excluded: const {},
              onSelect: (mg) {
                // If picking the primary that was in secondary, remove from secondary
                final newSecondary =
                    Set<MuscleGroup>.from(selectedSecondary.value)..remove(mg);
                selectedSecondary.value = newSecondary;
                selectedPrimary.value = mg;
              },
            ),
            const SizedBox(height: 20),

            // Secondary muscle groups
            const Text('SEKUNDÄRE MUSKELGRUPPEN (bis zu 3)', style: AppTextStyles.labelMd),
            const Text(
              'Unterstützend trainierte Muskelgruppen.',
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: 8),
            _SecondaryMuscleGroupPicker(
              selected: selectedSecondary.value,
              excluded: {
                if (selectedPrimary.value != null) selectedPrimary.value!,
              },
              onToggle: (mg) {
                final current = Set<MuscleGroup>.from(selectedSecondary.value);
                if (current.contains(mg)) {
                  current.remove(mg);
                } else if (current.length < 3) {
                  current.add(mg);
                }
                selectedSecondary.value = current;
              },
            ),
            const SizedBox(height: 24),

            TapemButton(
              label: existing == null ? 'HINZUFÜGEN' : 'SPEICHERN',
              isLoading: notifier.isLoading,
              isDisabled: selectedPrimary.value == null,
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                if (selectedPrimary.value == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Primäre Muskelgruppe wählen.'),
                    ),
                  );
                  return;
                }

                final key = existing?.key ?? keyFromName(nameCtrl.text);
                final muscleGroups = <ExerciseMuscleGroup>[
                  ExerciseMuscleGroup(
                    muscleGroup: selectedPrimary.value!,
                    role: MuscleGroupRole.primary,
                  ),
                  ...selectedSecondary.value.map(
                    (mg) => ExerciseMuscleGroup(
                      muscleGroup: mg,
                      role: MuscleGroupRole.secondary,
                    ),
                  ),
                ];

                await ref
                    .read(exerciseTemplateAdminProvider.notifier)
                    .upsertTemplate(
                      gymId: gymId,
                      key: key,
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      muscleGroups: muscleGroups,
                    );

                if (context.mounted) {
                  final err =
                      ref.read(exerciseTemplateAdminProvider).error;
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

            if (existing != null && existing!.isActive) ...[
              const SizedBox(height: 12),
              TapemButton(
                label: 'ÜBUNG DEAKTIVIEREN',
                variant: TapemButtonVariant.outlined,
                isLoading: notifier.isLoading,
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface800,
                      title: const Text('ÜBUNG DEAKTIVIEREN?'),
                      content: const Text(
                        'Die Übung wird für Mitglieder ausgeblendet.',
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
                        .read(exerciseTemplateAdminProvider.notifier)
                        .deactivateTemplate(gymId: gymId, key: existing!.key);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Muscle group pickers ─────────────────────────────────────────────────────

class _MuscleGroupPicker extends StatelessWidget {
  const _MuscleGroupPicker({
    required this.selected,
    required this.excluded,
    required this.onSelect,
  });

  final MuscleGroup? selected;
  final Set<MuscleGroup> excluded;
  final ValueChanged<MuscleGroup> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: MuscleGroup.sorted.map((mg) {
        final isSelected = selected == mg;
        final isExcluded = excluded.contains(mg);
        if (isExcluded) return const SizedBox.shrink();

        return ChoiceChip(
          label: Text(mg.displayNameDe, style: AppTextStyles.bodySm),
          selected: isSelected,
          onSelected: (_) => onSelect(mg),
          selectedColor: AppColors.neonMagenta.withAlpha(60),
          backgroundColor: AppColors.surface700,
          side: BorderSide(
            color: isSelected
                ? AppColors.neonMagenta
                : AppColors.surface500,
          ),
          labelStyle: AppTextStyles.bodySm.copyWith(
            color:
                isSelected ? AppColors.neonMagenta : AppColors.textSecondary,
          ),
        );
      }).toList(),
    );
  }
}

class _SecondaryMuscleGroupPicker extends StatelessWidget {
  const _SecondaryMuscleGroupPicker({
    required this.selected,
    required this.excluded,
    required this.onToggle,
  });

  final Set<MuscleGroup> selected;
  final Set<MuscleGroup> excluded;
  final ValueChanged<MuscleGroup> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: MuscleGroup.sorted.map((mg) {
        final isSelected = selected.contains(mg);
        final isExcluded = excluded.contains(mg);
        if (isExcluded) return const SizedBox.shrink();

        final atMax = selected.length >= 3 && !isSelected;

        return FilterChip(
          label: Text(mg.displayNameDe, style: AppTextStyles.bodySm),
          selected: isSelected,
          onSelected: atMax ? null : (_) => onToggle(mg),
          selectedColor: AppColors.surface600.withAlpha(120),
          backgroundColor: AppColors.surface700,
          side: BorderSide(
            color: isSelected
                ? AppColors.textSecondary
                : AppColors.surface500,
          ),
          labelStyle: AppTextStyles.bodySm.copyWith(
            color: isSelected
                ? AppColors.textPrimary
                : atMax
                    ? AppColors.textDisabled
                    : AppColors.textSecondary,
          ),
        );
      }).toList(),
    );
  }
}

Scaffold _errorScaffold(String message) => Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('ÜBUNGSVORLAGEN'),
        backgroundColor: AppColors.surface900,
      ),
      body: Center(
        child: Text(
          message,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
        ),
      ),
    );
