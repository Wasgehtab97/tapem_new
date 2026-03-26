import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../domain/entities/auth/user_profile.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../../../widgets/common/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
      body: profile.when(
        data: (p) => p == null
            ? Center(child: Text(context.l10n.noProfile))
            : _ProfileBody(profile: p),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar
        Center(child: _AvatarSection(profile: profile)),
        const SizedBox(height: 24),

        // Username
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surface500),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.usernameSection, style: AppTextStyles.labelSm),
              const SizedBox(height: 4),
              Text(
                '@${profile.username}',
                style: AppTextStyles.h2.copyWith(color: AppColors.neonCyan),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Theme picker
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surface500),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.themeSection, style: AppTextStyles.labelMd),
              const SizedBox(height: 12),
              _ThemePicker(currentKey: profile.themeKey),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Privacy
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surface500),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.privacySection, style: AppTextStyles.labelMd),
              const SizedBox(height: 12),
              _PrivacySelector(current: profile.privacyLevel),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Language picker
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surface500),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.languageSection, style: AppTextStyles.labelMd),
              const SizedBox(height: 12),
              const _LanguagePicker(),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Studios
        const _GymSection(),
        const SizedBox(height: 32),

        TapemButton(
          label: l10n.signOut,
          variant: TapemButtonVariant.outlined,
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
        ),
      ],
    );
  }
}

// ─── Avatar section ───────────────────────────────────────────────────────────

class _AvatarSection extends HookConsumerWidget {
  const _AvatarSection({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUploading = useState(false);

    Future<void> pick(ImageSource source) async {
      Navigator.pop(context);

      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file == null || !context.mounted) return;

      final bytes = await file.readAsBytes();
      if (!context.mounted) return;

      isUploading.value = true;
      try {
        await ref.read(profileNotifierProvider.notifier).uploadAvatar(bytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profilbild aktualisiert ✓')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload fehlgeschlagen: $e')));
        }
      } finally {
        isUploading.value = false;
      }
    }

    void showPicker() {
      unawaited(
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.surface800,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface500,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text('PROFILBILD ÄNDERN', style: AppTextStyles.labelMd),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.neonCyan,
                  ),
                  title: const Text(
                    'Aus Bibliothek',
                    style: AppTextStyles.bodyLg,
                  ),
                  onTap: () => pick(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.neonCyan,
                  ),
                  title: const Text('Kamera', style: AppTextStyles.bodyLg),
                  onTap: () => pick(ImageSource.camera),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: showPicker,
          child: Stack(
            alignment: Alignment.center,
            children: [
              UserAvatar(
                username: profile.username,
                radius: 52,
                avatarUrl: profile.avatarUrl,
                borderColor: AppColors.neonCyan,
                borderWidth: 2,
              ),
              if (isUploading.value)
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withAlpha(120),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonCyan,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 15,
                      color: AppColors.surface900,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'TIPPEN ZUM ÄNDERN',
          style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─── Theme picker ─────────────────────────────────────────────────────────────

class _ThemePicker extends ConsumerWidget {
  const _ThemePicker({required this.currentKey});
  final String currentKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final presets = [
      ('default', l10n.themeDefault, AppColors.neonCyan),
      ('energy', l10n.themeEnergy, AppColors.neonMagenta),
      ('minimal', l10n.themeMinimal, AppColors.themeMinimal),
    ];

    return Row(
      children: presets.map((preset) {
        final (key, label, color) = preset;
        final isSelected = key == currentKey;
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                ref.read(profileNotifierProvider.notifier).updateTheme(key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(30) : AppColors.surface700,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? color : AppColors.surface500,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: AppTextStyles.labelSm.copyWith(
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Privacy selector ─────────────────────────────────────────────────────────

class _PrivacySelector extends ConsumerWidget {
  const _PrivacySelector({required this.current});
  final PrivacyLevel current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      children: PrivacyLevel.values.map((level) {
        final (label, description) = switch (level) {
          PrivacyLevel.private => (
            l10n.privacyPrivate,
            l10n.privacyPrivateDescription,
          ),
          PrivacyLevel.friendsTrainingDays => (
            l10n.privacyTrainingDays,
            l10n.privacyTrainingDaysDescription,
          ),
          PrivacyLevel.friendsTrainingAndSummary => (
            l10n.privacySummary,
            l10n.privacySummaryDescription,
          ),
        };

        final isSelected = level == current;
        return GestureDetector(
          onTap: () => ref
              .read(profileNotifierProvider.notifier)
              .updatePrivacyLevel(level),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.neonCyan.withAlpha(15)
                  : AppColors.surface700,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? AppColors.neonCyan : AppColors.surface500,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? AppColors.neonCyan
                      : AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelMd.copyWith(
                        color: isSelected
                            ? AppColors.neonCyan
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(description, style: AppTextStyles.bodySm),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Gym section ──────────────────────────────────────────────────────────────

class _GymSection extends HookConsumerWidget {
  const _GymSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(userMembershipsProvider);
    final activeGymId = ref.watch(activeGymIdProvider);
    final showJoinForm = useState(false);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MEINE STUDIOS', style: AppTextStyles.labelMd),
          const SizedBox(height: 12),
          membershipsAsync.when(
            data: (memberships) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Gym tiles ───────────────────────────────────────────────
                ...memberships.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _GymSwitchTile(
                      membership: m,
                      isActive: m.gymId == activeGymId,
                      onTap: () async {
                        if (m.gymId == activeGymId) return;
                        await ref
                            .read(activeGymIdProvider.notifier)
                            .setActiveGym(m.gymId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Studio gewechselt: ${m.gymName}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),

                // ── Add gym button / form ────────────────────────────────────
                if (!showJoinForm.value) ...[
                  if (memberships.isNotEmpty) const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => showJoinForm.value = true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface700,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withAlpha(60),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: accent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'WEITERES STUDIO HINZUFÜGEN',
                            style: AppTextStyles.labelSm.copyWith(
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  _InlineJoinForm(
                    onCancel: () => showJoinForm.value = false,
                    onJoined: (gymId) {
                      showJoinForm.value = false;
                      unawaited(
                        ref
                            .read(activeGymIdProvider.notifier)
                            .setActiveGym(gymId),
                      );
                    },
                  ),
                ],
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Text(
              'Fehler beim Laden der Studios',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymSwitchTile extends StatelessWidget {
  const _GymSwitchTile({
    required this.membership,
    required this.isActive,
    required this.onTap,
  });

  final GymMembership membership;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final color = isActive ? AppColors.neonCyan : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.neonCyan.withAlpha(12)
              : AppColors.surface700,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? AppColors.neonCyan : AppColors.surface500,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.fitness_center : Icons.fitness_center_outlined,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membership.gymName,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: isActive ? AppColors.neonCyan : null,
                    ),
                  ),
                  Text(
                    membership.role.toUpperCase(),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle,
                color: AppColors.neonCyan,
                size: 18,
              )
            else
              Icon(Icons.swap_horiz, color: accent.withAlpha(180), size: 18),
          ],
        ),
      ),
    );
  }
}

class _InlineJoinForm extends HookConsumerWidget {
  const _InlineJoinForm({required this.onCancel, required this.onJoined});

  final VoidCallback onCancel;
  final void Function(String gymId) onJoined;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeCtrl = useTextEditingController();
    final isLoading = useState(false);
    final error = useState<String?>(null);

    Future<void> join() async {
      final code = codeCtrl.text.trim().toUpperCase();
      if (code.isEmpty) {
        error.value = 'Bitte Gym-Code eingeben';
        return;
      }
      isLoading.value = true;
      error.value = null;
      try {
        final client = ref.read(supabaseClientProvider);
        final result = await client
            .rpc('join_gym_with_code', params: {'p_code': code})
            .single();
        final data = Map<String, dynamic>.from(result as Map);
        if (data['success'] == true) {
          final gymId = data['gym_id'] as String;
          ref.invalidate(userMembershipsProvider);
          if (context.mounted) {
            final gymName = data['gym_name'] as String? ?? code;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$gymName erfolgreich hinzugefügt!'),
                duration: const Duration(seconds: 3),
              ),
            );
            onJoined(gymId);
          }
        } else {
          error.value = data['message'] as String? ?? 'Ungültiger Gym-Code';
        }
      } catch (_) {
        error.value = 'Etwas ist schiefgelaufen. Bitte erneut versuchen.';
      } finally {
        isLoading.value = false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TapemTextField(
          controller: codeCtrl,
          label: 'GYM-CODE',
          hintText: 'z.B. TAPEM1',
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => join(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            _UpperCaseTextFormatter(),
          ],
        ),
        if (error.value != null) ...[
          const SizedBox(height: 6),
          Text(
            error.value!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TapemButton(
                label: 'ABBRECHEN',
                variant: TapemButtonVariant.ghost,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TapemButton(
                label: 'HINZUFÜGEN',
                icon: Icons.login_outlined,
                isLoading: isLoading.value,
                onPressed: join,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

// ─── Language picker ──────────────────────────────────────────────────────────

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeNotifierProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final options = [
      (const Locale('de'), 'DEUTSCH', '🇩🇪'),
      (const Locale('en'), 'ENGLISH', '🇬🇧'),
    ];

    return Row(
      children: options.map((option) {
        final (locale, label, flag) = option;
        final isSelected = currentLocale.languageCode == locale.languageCode;
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                ref.read(localeNotifierProvider.notifier).setLocale(locale),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? accent.withAlpha(30) : AppColors.surface700,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? accent : AppColors.surface500,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: AppTextStyles.labelSm.copyWith(
                      color: isSelected ? accent : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
