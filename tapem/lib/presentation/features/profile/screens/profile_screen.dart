import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/build_info.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../domain/entities/auth/user_profile.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_skeleton.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../../../widgets/common/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/account_compliance_provider.dart';
import '../../auth/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: context.l10n.signOut,
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.neonCyan.withAlpha(120),
                  AppColors.neonMagenta.withAlpha(100),
                  AppColors.neonCyan.withAlpha(120),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: profile.when(
        data: (p) => p == null
            ? Center(child: Text(context.l10n.noProfile))
            : _ProfileBody(profile: p),
        loading: () => const _ProfileSkeleton(),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: TapemSkeleton.circle(size: 104)),
        const SizedBox(height: 24),
        TapemSkeleton.card(height: 72),
        const SizedBox(height: 16),
        TapemSkeleton.card(height: 88),
        const SizedBox(height: 16),
        TapemSkeleton.card(height: 72),
        const SizedBox(height: 16),
        TapemSkeleton.card(height: 72),
        const SizedBox(height: 16),
        TapemSkeleton.card(height: 120),
      ],
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
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withAlpha(18),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
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
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withAlpha(18),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
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
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withAlpha(18),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
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

        // Machine performance leaderboard visibility
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surface500),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withAlpha(18),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _MachinePerformanceLeaderboardSelector(profile: profile),
        ),
        const SizedBox(height: 16),

        // Language picker
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surface500),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withAlpha(18),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
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
        const SizedBox(height: 16),

        // Legal + privacy + account rights
        const _LegalAndDataSection(),
        const SizedBox(height: 32),

        TapemButton(
          label: l10n.signOut,
          variant: TapemButtonVariant.outlined,
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
        ),
        const SizedBox(height: 24),
        const _AppBuildInfo(),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _LegalAndDataSection extends HookConsumerWidget {
  const _LegalAndDataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isExporting = useState(false);
    final isDeleting = useState(false);
    final compliance = ref.read(accountComplianceServiceProvider);

    Future<void> openExternal(String url) async {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    Future<void> exportData() async {
      if (isExporting.value || isDeleting.value) return;
      isExporting.value = true;
      try {
        final result = await compliance.exportMyData();
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface800,
            title: Text(l10n.exportDataReadyTitle, style: AppTextStyles.h3),
            content: Text(
              l10n.exportDataReadyBody(
                result.estimatedRows,
                result.expiresInSeconds ~/ 60,
              ),
              style: AppTextStyles.bodyMd,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.closeLabel),
              ),
              TextButton(
                onPressed: () async {
                  await openExternal(result.downloadUrl);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(l10n.downloadExportLabel),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportDataFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        isExporting.value = false;
      }
    }

    Future<void> deleteAccount() async {
      if (isDeleting.value || isExporting.value) return;

      final confirmed = await _confirmDeleteDialog(context, l10n);
      if (!confirmed) return;

      isDeleting.value = true;
      try {
        await compliance.deleteMyAccount(confirmationText: 'DELETE');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountDeletedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountDeleteFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        isDeleting.value = false;
      }
    }

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
          Text(l10n.legalDataSection, style: AppTextStyles.labelMd),
          const SizedBox(height: 8),
          _SettingsLinkTile(
            icon: Icons.privacy_tip_outlined,
            label: l10n.privacyPolicyLabel,
            onTap: () => openExternal(AppConfig.privacyPolicyUrl),
          ),
          _SettingsLinkTile(
            icon: Icons.description_outlined,
            label: l10n.termsOfServiceLabel,
            onTap: () => openExternal(AppConfig.termsOfServiceUrl),
          ),
          _SettingsLinkTile(
            icon: Icons.business_outlined,
            label: l10n.imprintLabel,
            onTap: () => openExternal(AppConfig.imprintUrl),
          ),
          _SettingsLinkTile(
            icon: Icons.support_agent_outlined,
            label: l10n.supportLabel,
            onTap: () => openExternal(AppConfig.supportUrl),
          ),
          const Divider(height: 24),
          _SettingsLinkTile(
            icon: Icons.download_outlined,
            label: isExporting.value
                ? l10n.exportingDataLabel
                : l10n.exportMyDataLabel,
            onTap: exportData,
            trailing: isExporting.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          _SettingsLinkTile(
            icon: Icons.delete_forever_outlined,
            label: isDeleting.value
                ? l10n.deletingAccountLabel
                : l10n.deleteAccountLabel,
            onTap: deleteAccount,
            danger: true,
            trailing: isDeleting.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController();
    bool canDelete = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface800,
            title: Text(
              l10n.deleteAccountConfirmTitle,
              style: AppTextStyles.h3,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deleteAccountConfirmBody,
                  style: AppTextStyles.bodyMd,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    labelText: l10n.typeDeletePrompt,
                    labelStyle: AppTextStyles.bodySm,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.surface500),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.neonCyan),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onChanged: (value) {
                    final next = value.trim().toUpperCase() == 'DELETE';
                    if (next != canDelete) {
                      setState(() => canDelete = next);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: canDelete
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: Text(
                  l10n.deleteAccountLabel,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          );
        },
      ),
    );

    controller.dispose();
    return result == true;
  }
}

class _SettingsLinkTile extends StatelessWidget {
  const _SettingsLinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTextStyles.bodyMd.copyWith(color: color)),
      trailing:
          trailing ??
          const Icon(
            Icons.open_in_new,
            size: 18,
            color: AppColors.textSecondary,
          ),
      onTap: onTap,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(30) : AppColors.surface700,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? color : AppColors.surface500,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withAlpha(60), blurRadius: 8)]
                    : null,
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
                Expanded(
                  child: Column(
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
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MachinePerformanceLeaderboardSelector extends ConsumerWidget {
  const _MachinePerformanceLeaderboardSelector({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(profileNotifierProvider.notifier);
    final selectedSex = profile.machinePerformanceSex;
    final isOptedIn = profile.machinePerformanceOptIn;

    Future<void> save({
      required bool nextOptIn,
      required MachinePerformanceSex? nextSex,
    }) async {
      try {
        await notifier.updateMachinePerformanceVisibility(
          isOptedIn: nextOptIn,
          sex: nextSex,
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MACHINE PERFORMANCE LEADERBOARD',
          style: AppTextStyles.labelMd,
        ),
        const SizedBox(height: 8),
        Text(
          'Opt in to appear in sex-separated machine strength rankings (best-set e1RM).',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          value: isOptedIn,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.neonCyan,
          title: Text(
            isOptedIn ? 'Visible in leaderboard' : 'Not visible in leaderboard',
            style: AppTextStyles.bodyMd,
          ),
          subtitle: Text(
            'Requires sex selection',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          onChanged: (enabled) async {
            if (enabled && selectedSex == null) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Select sex before enabling opt-in.'),
                ),
              );
              return;
            }
            await save(nextOptIn: enabled, nextSex: selectedSex);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SexChoiceChip(
                label: 'Male',
                selected: selectedSex == MachinePerformanceSex.male,
                onTap: () => save(
                  nextOptIn: isOptedIn,
                  nextSex: MachinePerformanceSex.male,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SexChoiceChip(
                label: 'Female',
                selected: selectedSex == MachinePerformanceSex.female,
                onTap: () => save(
                  nextOptIn: isOptedIn,
                  nextSex: MachinePerformanceSex.female,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SexChoiceChip extends StatelessWidget {
  const _SexChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neonCyan.withAlpha(18)
              : AppColors.surface700,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.neonCyan : AppColors.surface500,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? AppColors.neonCyan : AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ),
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

// ─── App build info ───────────────────────────────────────────────────────────

class _AppBuildInfo extends HookConsumerWidget {
  const _AppBuildInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tapCount = useState(0);

    Future<void> handleTap() async {
      final nextCount = tapCount.value + 1;
      if (nextCount < 5) {
        tapCount.value = nextCount;
        return;
      }

      tapCount.value = 0;

      final gymId = ref.read(activeGymIdProvider);
      if (gymId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kein aktives Gym ausgewählt')),
          );
        }
        return;
      }

      try {
        await ref
            .read(supabaseClientProvider)
            .rpc(
              'claim_owner_membership_if_existing_owner',
              params: {'p_gym_id': gymId},
            );

        ref.invalidate(userMembershipsProvider);
        ref.invalidate(activeMembershipProvider);
        ref.invalidate(isGymAdminProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Owner-Rolle für das aktive Gym aktiviert'),
            ),
          );
        }
      } catch (e) {
        final message = e.toString();
        String uiMessage = 'Owner-Rolle konnte nicht aktiviert werden';
        if (message.contains('not_existing_owner')) {
          uiMessage = 'Nur bestehende Gym-Owner können diese Aktion nutzen';
        } else if (message.contains('membership_not_found')) {
          uiMessage = 'Keine aktive Membership im ausgewählten Gym gefunden';
        }

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(uiMessage)));
        }
      }
    }

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '–';
        final build = snapshot.data?.buildNumber ?? '–';
        const date = BuildInfo.buildDate;
        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: handleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Version $version ($build) · $date',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textSecondary.withAlpha(100),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
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
