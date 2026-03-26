import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class UsernameSetupScreen extends HookConsumerWidget {
  const UsernameSetupScreen({super.key});

  // Spec Decision 11: lowercase only, dots and underscores allowed, 3–20 chars.
  static final _usernameRegex = RegExp(r'^[a-z0-9_.]{3,20}$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameCtrl = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final availability = useState<bool?>(null);
    final suggestions = useState<List<String>>([]);
    final isChecking = useState(false);
    final profileState = ref.watch(profileNotifierProvider);
    final l10n = context.l10n;

    ref.listen<AsyncValue<void>>(profileNotifierProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    Future<void> checkAvailability(String username) async {
      if (!_usernameRegex.hasMatch(username)) return;
      isChecking.value = true;
      try {
        final notifier = ref.read(profileNotifierProvider.notifier);
        final available = await notifier.isUsernameAvailable(username);
        availability.value = available;
        if (!available) {
          suggestions.value = await notifier.suggestUsernames(username);
        } else {
          suggestions.value = [];
        }
      } catch (_) {
        availability.value = true;
        suggestions.value = [];
      } finally {
        isChecking.value = false;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.chooseYourUsername, style: AppTextStyles.h1),
                const SizedBox(height: 12),
                Text(
                  l10n.usernamePublicHint,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                TapemTextField(
                  controller: usernameCtrl,
                  label: l10n.usernameLabel,
                  hintText: 'e.g. iron_wolf',
                  textInputAction: TextInputAction.done,
                  onChanged: (v) {
                    // Auto-lowercase per spec — no uppercase usernames.
                    final lowered = v.toLowerCase();
                    if (lowered != v) {
                      usernameCtrl.value = TextEditingValue(
                        text: lowered,
                        selection: TextSelection.collapsed(
                          offset: lowered.length,
                        ),
                      );
                    }
                    availability.value = null;
                    if (lowered.length >= 3) {
                      unawaited(checkAvailability(lowered));
                    }
                  },
                  suffixIcon: _buildAvailabilityIcon(
                    isChecking.value,
                    availability.value,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.usernameRequired;
                    if (!_usernameRegex.hasMatch(v)) {
                      return l10n.usernameInvalid;
                    }
                    if (availability.value == false) return l10n.usernameTaken;
                    return null;
                  },
                ),
                if (suggestions.value.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.usernameSuggestions,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: suggestions.value
                        .map(
                          (s) => ActionChip(
                            label: Text(s, style: AppTextStyles.labelMd),
                            onPressed: () {
                              usernameCtrl.text = s;
                              availability.value = true;
                              suggestions.value = [];
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 40),
                TapemButton(
                  label: l10n.continueBtn,
                  isLoading: profileState is AsyncLoading,
                  isDisabled: availability.value != true,
                  onPressed: () => _submit(ref, formKey, usernameCtrl.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildAvailabilityIcon(bool isChecking, bool? available) {
    if (isChecking) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (available == null) return null;
    return Icon(
      available ? Icons.check_circle_outline : Icons.cancel_outlined,
      color: available ? AppColors.success : AppColors.error,
      size: 20,
    );
  }

  Future<void> _submit(
    WidgetRef ref,
    GlobalKey<FormState> formKey,
    String username,
  ) async {
    if (!formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await ref
        .read(profileNotifierProvider.notifier)
        .createProfile(
          userId: user.id,
          username: username.trim().toLowerCase(),
        );
  }
}
