import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../providers/admin_providers.dart';

class AdminGymSettingsScreen extends HookConsumerWidget {
  const AdminGymSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) return const _ErrorView('Kein aktives Gym.');

    final gymAsync = ref.watch(adminGymInfoProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('GYM EINSTELLUNGEN'),
        backgroundColor: AppColors.surface900,
      ),
      body: gymAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(e.toString()),
        data: (gym) => gym == null
            ? const _ErrorView('Gym nicht gefunden.')
            : _GymSettingsBody(gym: gym, gymId: gymId),
      ),
    );
  }
}

// ─── Main body ────────────────────────────────────────────────────────────────

class _GymSettingsBody extends HookConsumerWidget {
  const _GymSettingsBody({required this.gym, required this.gymId});

  final AdminGymInfo gym;
  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = useTextEditingController(text: gym.name);
    final descCtrl = useTextEditingController(text: gym.description ?? '');
    final requiresApproval = useState(gym.requiresApproval);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final notifier = ref.watch(gymSettingsNotifierProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Join Code Card ──────────────────────────────────────────────────
        _SectionCard(
          title: 'MITGLIEDER EINLADEN',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Teile diesen Code mit neuen Mitgliedern.',
                style: AppTextStyles.bodySm,
              ),
              const SizedBox(height: 16),
              _JoinCodeDisplay(gymCode: gym.joinCode, gymName: gym.name),
              const SizedBox(height: 16),
              _RequiresApprovalToggle(
                value: requiresApproval.value,
                onChanged: (v) => requiresApproval.value = v,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Profile Edit ───────────────────────────────────────────────────
        _SectionCard(
          title: 'GYM PROFIL',
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TapemTextField(
                  label: 'GYM NAME',
                  controller: nameCtrl,
                  hintText: 'z.B. Lifthouse Gym',
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.length < 3 || s.length > 60) {
                      return '3–60 Zeichen erforderlich';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TapemTextField(
                  label: 'BESCHREIBUNG (optional)',
                  controller: descCtrl,
                  hintText: 'Kurze Beschreibung deines Gyms',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                TapemButton(
                  label: 'SPEICHERN',
                  isLoading: notifier.isLoading,
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    await ref
                        .read(gymSettingsNotifierProvider.notifier)
                        .updateProfile(
                          gymId: gymId,
                          name: nameCtrl.text,
                          description: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          requiresApproval: requiresApproval.value,
                        );
                    if (context.mounted) {
                      final err = ref
                          .read(gymSettingsNotifierProvider)
                          .error;
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler: $err'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gym-Profil gespeichert.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Join code display ────────────────────────────────────────────────────────

class _JoinCodeDisplay extends StatelessWidget {
  const _JoinCodeDisplay({required this.gymCode, required this.gymName});

  final String gymCode;
  final String gymName;

  String get _shareText =>
      'Tritt $gymName auf Tap\'em bei! Lade die App herunter und gib den Code '
      'ein: $gymCode — Tracke dein Training und sieh, wie du abschneidest.';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonCyan.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            gymCode,
            style: AppTextStyles.displayMd.copyWith(
              color: AppColors.neonCyan,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    unawaited(Clipboard.setData(ClipboardData(text: gymCode)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code kopiert!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('CODE KOPIEREN'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonCyan,
                    side: const BorderSide(color: AppColors.neonCyan),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    unawaited(Clipboard.setData(ClipboardData(text: _shareText)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Einladungstext kopiert — jetzt teilen!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('EINLADEN'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surface500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Mitglieder geben diesen Code in der App beim Gym-Beitritt ein.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Approval toggle ──────────────────────────────────────────────────────────

class _RequiresApprovalToggle extends StatelessWidget {
  const _RequiresApprovalToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEITRITT MUSS GENEHMIGT WERDEN',
                  style: AppTextStyles.labelMd,
                ),
                SizedBox(height: 4),
                Text(
                  'Neue Mitglieder warten auf deine Freigabe, bevor sie Zugang erhalten.',
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.neonCyan,
          ),
        ],
      ),
    );
  }
}

// ─── Shared section card ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(title, style: AppTextStyles.labelMd),
          ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
