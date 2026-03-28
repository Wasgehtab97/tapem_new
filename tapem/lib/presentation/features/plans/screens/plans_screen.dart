import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../router/route_names.dart';
import '../../../widgets/common/tapem_button.dart';
import '../providers/plans_provider.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Restore plans from Supabase if SQLite is empty (reinstall case).
    ref.watch(restorePlansFromSupabaseProvider);
    final plans = ref.watch(plansProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainingPlansTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.newPlanTooltip,
            onPressed: () => context.push(RouteNames.planNew),
          ),
        ],
      ),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
        data: (list) =>
            list.isEmpty ? const _EmptyState() : _PlanList(plans: list),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 64,
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 24),
            Text(l10n.noPlansYet, style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Text(
              l10n.noPlansDescription,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TapemButton(
              label: l10n.createFirstPlan,
              icon: Icons.add,
              onPressed: () => context.push(RouteNames.planNew),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plan list ────────────────────────────────────────────────────────────────

class _PlanList extends StatelessWidget {
  const _PlanList({required this.plans});

  final List<LocalWorkoutPlan> plans;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length + 1,
      itemBuilder: (context, index) {
        if (index == plans.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TapemButton(
              label: l10n.createNewPlan,
              icon: Icons.add,
              variant: TapemButtonVariant.outlined,
              onPressed: () => context.push(RouteNames.planNew),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PlanTile(plan: plans[index]),
        );
      },
    );
  }
}

// ─── Plan tile ────────────────────────────────────────────────────────────────

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan});

  final LocalWorkoutPlan plan;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: AppColors.surface800,
        child: InkWell(
          onTap: () => context.push('/progress/plans/${plan.id}/edit'),
          splashColor: AppColors.neonMagenta.withAlpha(15),
          highlightColor: AppColors.neonMagenta.withAlpha(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surface500),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.neonMagenta.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.neonMagenta.withAlpha(60),
                    ),
                  ),
                  child: const Icon(
                    Icons.list_alt_outlined,
                    color: AppColors.neonMagenta,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: AppTextStyles.bodyLg),
                      const SizedBox(height: 3),
                      Text(
                        _formatPlanDate(context, plan.updatedAt),
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPlanDate(BuildContext context, DateTime dt) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return l10n.updatedToday;
    if (diff.inDays == 1) return l10n.updatedYesterday;
    if (diff.inDays < 7) return l10n.updatedDaysAgo(diff.inDays);
    final date =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    return l10n.updatedDate(date);
  }
}
