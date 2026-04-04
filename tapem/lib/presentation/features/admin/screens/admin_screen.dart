import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../router/route_names.dart';
import '../providers/admin_providers.dart';

/// Admin hub screen — links to all admin sub-sections.
/// Accessible only to users with role admin/owner in the active gym.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    final pendingCount = gymId != null
        ? ref.watch(pendingMemberCountProvider(gymId)).valueOrNull ?? 0
        : 0;
    final ownerOverviewAsync = gymId != null
        ? ref.watch(ownerOverviewProvider(gymId))
        : null;
    final ownerStats = ownerOverviewAsync?.valueOrNull;
    final openJoinRequests = ownerStats?.openJoinRequests ?? pendingCount;
    final openFeedbacks = ownerStats?.openFeedbacks ?? 0;
    final openReports = ownerStats?.openReports ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('GYM ADMIN'),
        backgroundColor: AppColors.surface900,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.neonMagenta.withAlpha(120),
                  AppColors.neonCyan.withAlpha(160),
                  AppColors.neonMagenta.withAlpha(120),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (gymId != null) ...[
            _AdminOpsPriorityCard(
              joinRequests: openJoinRequests,
              feedbacks: openFeedbacks,
              reports: openReports,
              loading: ownerOverviewAsync?.isLoading ?? false,
            ),
            const SizedBox(height: 12),
          ],

          // ── Owner overview ─────────────────────────────────────────────────
          const _AdminSection(
            title: 'OWNER OVERVIEW',
            icon: Icons.dashboard_outlined,
            items: [
              _AdminItem(
                label: 'Alle KPIs auf einen Blick',
                subtitle: 'Funnel, Nutzung, NFC-Abdeckung, offene Aufgaben',
                route: RouteNames.adminOwnerOverview,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Gym Settings ───────────────────────────────────────────────────
          const _AdminSection(
            title: 'GYM SETTINGS',
            icon: Icons.settings_outlined,
            items: [
              _AdminItem(
                label: 'Gym Code & Info',
                subtitle: 'Gym-Code anzeigen und teilen, Name bearbeiten',
                route: RouteNames.adminGymSettings,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Equipment ──────────────────────────────────────────────────────
          const _AdminSection(
            title: 'EQUIPMENT',
            icon: Icons.precision_manufacturing_outlined,
            items: [
              _AdminItem(
                label: 'Geräte verwalten',
                subtitle: 'Geräte hinzufügen, bearbeiten, deaktivieren',
                route: RouteNames.adminEquipment,
              ),
              _AdminItem(
                label: 'NFC Tag Zuweisung',
                subtitle: 'NFC-Tags Geräten zuordnen und verwalten',
                route: RouteNames.adminNfc,
              ),
              _AdminItem(
                label: 'Grundriss / Floor Plan',
                subtitle:
                    'Hallenplan hochladen und Geräte auf der Karte positionieren',
                route: RouteNames.adminFloorPlan,
              ),
              _AdminItem(
                label: 'Geräte-Feedback',
                subtitle: 'Fehlermeldungen und Vorschläge der Mitglieder',
                route: RouteNames.adminEquipmentFeedback,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Exercise Templates ─────────────────────────────────────────────
          const _AdminSection(
            title: 'ÜBUNGSVORLAGEN',
            icon: Icons.category_outlined,
            items: [
              _AdminItem(
                label: 'Übungsvorlagen',
                subtitle: 'Gym-eigene Übungen und Muskelgruppen-Mappings',
                route: RouteNames.adminExercises,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Members ────────────────────────────────────────────────────────
          _AdminSection(
            title: 'MITGLIEDER',
            icon: Icons.people_outline,
            items: [
              _AdminItem(
                label: 'Mitgliederliste',
                subtitle: 'Alle Mitglieder, Aktivität und XP im Überblick',
                route: RouteNames.adminMembers,
                badge: pendingCount > 0 ? pendingCount : null,
              ),
              const _AdminItem(
                label: 'Rollen & Rechte',
                subtitle: 'Member zu Coach oder Admin ernennen',
                route: RouteNames.adminRoles,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Challenges ─────────────────────────────────────────────────────
          const _AdminSection(
            title: 'CHALLENGES',
            icon: Icons.emoji_events_outlined,
            items: [
              _AdminItem(
                label: 'Challenges verwalten',
                subtitle: 'Gym-Challenges erstellen, starten und beenden',
                route: RouteNames.adminChallenges,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Moderation ─────────────────────────────────────────────────────
          const _AdminSection(
            title: 'MODERATION',
            icon: Icons.shield_outlined,
            items: [
              _AdminItem(
                label: 'Gemeldete Inhalte',
                subtitle: 'Community-Meldungen prüfen und entscheiden',
                route: RouteNames.adminModeration,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Analytics ──────────────────────────────────────────────────────
          const _AdminSection(
            title: 'ANALYTICS',
            icon: Icons.analytics_outlined,
            items: [
              _AdminItem(
                label: 'Aktivitäts-Dashboard',
                subtitle: 'Trainingstage, aktive Mitglieder, DAU/WAU/MAU',
                route: RouteNames.adminAnalytics,
              ),
              _AdminItem(
                label: 'Equipment-Nutzung',
                subtitle: 'Welche Geräte werden wie oft genutzt',
                route: RouteNames.adminEquipmentAnalytics,
              ),
              _AdminItem(
                label: 'Engagement-Metriken',
                subtitle: 'XP-Verteilung, Challenge-Beteiligung, Community',
                route: RouteNames.adminEngagement,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AdminOpsPriorityCard extends StatelessWidget {
  const _AdminOpsPriorityCard({
    required this.joinRequests,
    required this.feedbacks,
    required this.reports,
    required this.loading,
  });

  final int joinRequests;
  final int feedbacks;
  final int reports;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final total = joinRequests + feedbacks + reports;
    final color = total == 0 ? AppColors.success : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(130)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    total == 0
                        ? 'OPS PRIORITY: Keine offenen Aufgaben'
                        : 'OPS PRIORITY: $total offene Aufgaben',
                    style: AppTextStyles.labelMd.copyWith(color: color),
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          _OpsActionTile(
            label: 'Beitrittsanfragen',
            subtitle: 'Mitgliederfreigaben prüfen',
            count: joinRequests,
            route: RouteNames.adminMembers,
          ),
          _OpsActionTile(
            label: 'Geräte-Feedback',
            subtitle: 'Offene Defekte & Meldungen',
            count: feedbacks,
            route: RouteNames.adminEquipmentFeedback,
          ),
          _OpsActionTile(
            label: 'Moderationsfälle',
            subtitle: 'Gemeldete Inhalte entscheiden',
            count: reports,
            route: RouteNames.adminModeration,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _OpsActionTile extends StatelessWidget {
  const _OpsActionTile({
    required this.label,
    required this.subtitle,
    required this.count,
    required this.route,
    this.isLast = false,
  });

  final String label;
  final String subtitle;
  final int count;
  final String route;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: AppTextStyles.bodySm.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
          onTap: () => unawaited(context.push(route)),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

// ─── Section widget ───────────────────────────────────────────────────────────

class _AdminSection extends StatelessWidget {
  const _AdminSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_AdminItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.labelMd),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => _AdminItemTile(item: item)),
        ],
      ),
    );
  }
}

// ─── Item tile ────────────────────────────────────────────────────────────────

class _AdminItemTile extends StatelessWidget {
  const _AdminItemTile({required this.item});
  final _AdminItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(item.label, style: AppTextStyles.bodyMd)),
          if (item.badge != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${item.badge}',
                style: AppTextStyles.bodySm.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => unawaited(context.push(item.route)),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _AdminItem {
  const _AdminItem({
    required this.label,
    required this.route,
    this.subtitle,
    this.badge,
  });

  final String label;
  final String route;
  final String? subtitle;
  final int? badge;
}
