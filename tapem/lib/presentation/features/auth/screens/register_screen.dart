import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../router/route_names.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final confirmPasswordCtrl = useTextEditingController();
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.createAccount, style: AppTextStyles.h1),
                const SizedBox(height: 8),
                Text(
                  l10n.joinGymTagline,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
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
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return l10n.passwordMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TapemTextField(
                  controller: confirmPasswordCtrl,
                  label: l10n.confirmPasswordLabel,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v != passwordCtrl.text) return l10n.passwordsNoMatch;
                    return null;
                  },
                  onFieldSubmitted: (_) =>
                      _submit(ref, formKey, emailCtrl, passwordCtrl),
                ),
                const SizedBox(height: 40),
                TapemButton(
                  label: l10n.createAccount,
                  isLoading: authState is AsyncLoading,
                  onPressed: () =>
                      _submit(ref, formKey, emailCtrl, passwordCtrl),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.alreadyHaveAccount, style: AppTextStyles.bodySm),
                    GestureDetector(
                      onTap: () => context.go(RouteNames.login),
                      child: Text(
                        l10n.signIn,
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
        .signUpWithEmail(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
        );
  }
}
