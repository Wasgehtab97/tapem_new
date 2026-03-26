import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../router/route_names.dart';
import '../../../widgets/common/tapem_button.dart';
import '../../../widgets/common/tapem_text_field.dart';

/// Gym setup screen — shown when the user has no active gym.
class GymSetupScreen extends ConsumerWidget {
  const GymSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(userMembershipsProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                "TAP'EM",
                style: AppTextStyles.displayLg.copyWith(
                  color: AppColors.neonCyan,
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.joinYourGym, style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                l10n.gymCodeDescription,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: membershipsAsync.when(
                  data: (memberships) => memberships.isEmpty
                      ? const _JoinGymView()
                      : _MembershipList(memberships: memberships),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      l10n.failedToLoadGyms(e.toString()),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipList extends ConsumerWidget {
  const _MembershipList({required this.memberships});
  final List<GymMembership> memberships;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourGyms,
          style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...memberships.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GymTile(membership: m),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.surface500),
        const SizedBox(height: 16),
        Text(
          l10n.joinAnotherGym,
          style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        const _JoinGymForm(),
      ],
    );
  }
}

class _GymTile extends ConsumerWidget {
  const _GymTile({required this.membership});
  final GymMembership membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => _select(context, ref),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: accent.withAlpha(60)),
              ),
              child: Icon(Icons.fitness_center, color: accent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(membership.gymName, style: AppTextStyles.bodyLg),
                  Text(
                    membership.role.toUpperCase(),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: accent, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, WidgetRef ref) async {
    await ref.read(activeGymIdProvider.notifier).setActiveGym(membership.gymId);
    if (context.mounted) context.go(RouteNames.home);
  }
}

class _JoinGymView extends StatelessWidget {
  const _JoinGymView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: AppColors.textSecondary.withAlpha(100),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              l10n.noGymMembership,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.askGymForCode,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          const _JoinGymForm(),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

class _JoinGymForm extends HookConsumerWidget {
  const _JoinGymForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeCtrl = useTextEditingController();
    final isLoading = useState(false);
    final error = useState<String?>(null);
    final l10n = context.l10n;

    Future<void> join() async {
      final code = codeCtrl.text.trim().toUpperCase();
      if (code.isEmpty) {
        error.value = l10n.gymCodeEmpty;
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
          await ref.read(activeGymIdProvider.notifier).setActiveGym(gymId);
          if (context.mounted) context.go(RouteNames.home);
        } else {
          error.value = data['message'] as String? ?? l10n.invalidGymCode;
        }
      } catch (e) {
        error.value = l10n.somethingWentWrong;
      } finally {
        isLoading.value = false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TapemTextField(
          controller: codeCtrl,
          label: l10n.gymCodeLabel,
          hintText: 'e.g. TAPEM1',
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => join(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            _UpperCaseFormatter(),
          ],
        ),
        if (error.value != null) ...[
          const SizedBox(height: 8),
          Text(
            error.value!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 24),
        TapemButton(
          label: l10n.joinGymBtn,
          icon: Icons.login_outlined,
          isLoading: isLoading.value,
          onPressed: join,
        ),
      ],
    );
  }
}
