import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../l10n/generated/app_localizations.dart';
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

    final entranceCtrl = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );
    useEffect(() {
      entranceCtrl.forward();
      return null;
    }, const []);

    Animation<double> stagger(double start) => CurvedAnimation(
      parent: entranceCtrl,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    final a0 = stagger(0.0);
    final a1 = stagger(0.15);
    final a2 = stagger(0.3);
    final a3 = stagger(0.45);

    Widget fadeSlide(Widget child, Animation<double> anim) =>
        FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );

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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fadeSlide(Text(l10n.createAccount, style: AppTextStyles.h1), a0),
                const SizedBox(height: 8),
                fadeSlide(
                  Text(
                    l10n.joinGymTagline,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  a0,
                ),
                const SizedBox(height: 40),
                fadeSlide(
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
                  a1,
                ),
                const SizedBox(height: 16),
                fadeSlide(
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
                  a2,
                ),
                const SizedBox(height: 16),
                fadeSlide(
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
                  a2,
                ),
                const SizedBox(height: 40),
                fadeSlide(
                  TapemButton(
                    label: l10n.createAccount,
                    isLoading: authState is AsyncLoading,
                    onPressed: () =>
                        _submit(ref, formKey, emailCtrl, passwordCtrl),
                  ),
                  a3,
                ),
                const SizedBox(height: 24),
                fadeSlide(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.alreadyHaveAccount, style: AppTextStyles.bodySm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        child: Semantics(
                          button: true,
                          label: l10n.signIn,
                          child: GestureDetector(
                            onTap: () => context.go(RouteNames.login),
                            child: Text(
                              l10n.signIn,
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.neonCyan,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  a3,
                ),
                const SizedBox(height: 20),
                fadeSlide(_AuthLegalLinks(l10n: l10n), a3),
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

class _AuthLegalLinks extends StatelessWidget {
  const _AuthLegalLinks({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        Text(
          l10n.authLegalPrefix,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => _open(AppConfig.privacyPolicyUrl),
          child: Text(l10n.privacyPolicyLabel),
        ),
        Text(
          '|',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => _open(AppConfig.termsOfServiceUrl),
          child: Text(l10n.termsOfServiceLabel),
        ),
      ],
    );
  }

  Future<void> _open(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
