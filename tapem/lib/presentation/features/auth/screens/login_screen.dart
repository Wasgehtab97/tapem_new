import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../router/route_names.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final authState = ref.watch(authNotifierProvider);
    final l10n = context.l10n;

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Text(
                  "TAP'EM",
                  style: AppTextStyles.displayLg.copyWith(
                    color: AppColors.neonCyan,
                    letterSpacing: 6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appTagline,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 56),
                TapemTextField(
                  controller: emailCtrl,
                  label: l10n.emailLabel,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.emailRequired;
                    if (!v.contains('@')) return l10n.invalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TapemTextField(
                  controller: passwordCtrl,
                  label: l10n.passwordLabel,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return l10n.passwordMinLength;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) =>
                      _submit(ref, formKey, emailCtrl, passwordCtrl),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        _forgotPassword(context, ref, emailCtrl.text, l10n),
                    child: Text(
                      l10n.forgotPassword,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.neonCyan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TapemButton(
                  label: l10n.signIn,
                  isLoading: authState is AsyncLoading,
                  onPressed: () =>
                      _submit(ref, formKey, emailCtrl, passwordCtrl),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.noAccount, style: AppTextStyles.bodySm),
                    GestureDetector(
                      onTap: () => context.go(RouteNames.register),
                      child: Text(
                        l10n.signUp,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(
    WidgetRef ref,
    GlobalKey<FormState> formKey,
    TextEditingController emailCtrl,
    TextEditingController passwordCtrl,
  ) async {
    if (!formKey.currentState!.validate()) return;
    await ref
        .read(authNotifierProvider.notifier)
        .signInWithEmail(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
        );
  }

  Future<void> _forgotPassword(
    BuildContext context,
    WidgetRef ref,
    String email,
    AppLocalizations l10n,
  ) async {
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterEmailFirst)));
      return;
    }
    await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordReset(email: email.trim());
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.passwordResetSent)));
    }
  }
}
