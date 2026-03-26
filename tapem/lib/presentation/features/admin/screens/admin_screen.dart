import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../router/route_names.dart';

/// Admin screen — accessible only to users with role admin/owner in the
/// active gym. Tab visibility is enforced in ScaffoldWithNavBar via
/// isGymAdminProvider. All sub-screens are Phase 2/3 stubs until implemented.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GYM ADMIN'),
        backgroundColor: AppColors.surface900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // ── Gym Settings ─────────────────────────────────────────────────
          _AdminSection(
            title: 'GYM SETTINGS',
            icon: Icons.settings_outlined,
            items: [
              _AdminItem(
                label: 'Gym Code & Info',
                subtitle: 'Gym-Code anzeigen und teilen, Name bearbeiten',
                route: '/admin/gym-settings',
              ),
            ],
          ),
          SizedBox(height: 12),

          // ── Equipment ─────────────────────────────────────────────────────
          _AdminSection(
            title: 'EQUIPMENT',
            icon: Icons.precision_manufacturing_outlined,
            items: [
              _AdminItem(
                label: 'Geräte verwalten',
                subtitle: 'Geräte hinzufügen, bearbeiten, deaktivieren',
                route: '/admin/equipment',
              ),
              _AdminItem(
                label: 'NFC Tag Zuweisung',
                subtitle: 'NFC-Tags Geräten zuordnen und verwalten',
                route: '/admin/nfc',
              ),
              _AdminItem(
                label: 'Geräte-Feedback',
                subtitle: 'Fehlermeldungen und Vorschläge der Mitglieder',
                route: '/admin/equipment-feedback',
              ),
              _AdminItem(
                label: 'Grundriss (V1.1)',
                subtitle: 'Geräte auf Gym-Grundriss positionieren',
                route: '/admin/floor-plan',
              ),
            ],
          ),
          SizedBox(height: 12),

          // ── Exercise Templates ────────────────────────────────────────────
          _AdminSection(
            title: 'ÜBUNGSVORLAGEN',
            icon: Icons.category_outlined,
            items: [
              _AdminItem(
                label: 'Übungsvorlagen',
                subtitle: 'Gym-eigene Übungen und Muskelgruppen-Mappings',
                route: '/admin/exercises',
              ),
            ],
          ),
          SizedBox(height: 12),

          // ── Members ───────────────────────────────────────────────────────
          _AdminSection(
            title: 'MITGLIEDER',
            icon: Icons.people_outline,
            items: [
              _AdminItem(
                label: 'Mitgliederliste',
                subtitle: 'Alle Mitglieder, Aktivität und XP im Überblick',
                route: '/admin/members',
              ),
              _AdminItem(
                label: 'Rollen & Rechte',
                subtitle: 'Member zu Coach oder Admin ernennen',
                route: '/admin/roles',
              ),
            ],
          ),
          SizedBox(height: 12),

          // ── Challenges ────────────────────────────────────────────────────
          _AdminSection(
            title: 'CHALLENGES',
            icon: Icons.emoji_events_outlined,
            items: [
              _AdminItem(
                label: 'Challenges verwalten',
                subtitle: 'Gym-Challenges erstellen, starten und beenden',
                route: '/admin/challenges',
              ),
            ],
          ),
          SizedBox(height: 12),

          // ── Moderation ────────────────────────────────────────────────────
          _AdminSection(
            title: 'MODERATION',
            icon: Icons.shield_outlined,
            items: [
              _AdminItem(
                label: 'Gemeldete Inhalte',
                subtitle: 'Community-Meldungen prüfen und entscheiden',
                route: '/admin/moderation',
              ),
            ],
          ),
          SizedBox(height: 12),

          // ── Analytics ─────────────────────────────────────────────────────
          _AdminSection(
            title: 'ANALYTICS',
            icon: Icons.analytics_outlined,
            items: [
              _AdminItem(
                label: 'Aktivitäts-Dashboard',
                subtitle: 'Trainingstage, aktive Mitglieder, DAU/WAU/MAU',
                route: '/admin/analytics',
              ),
              _AdminItem(
                label: 'Equipment-Nutzung',
                subtitle: 'Welche Geräte werden wie oft genutzt',
                route: '/admin/equipment-analytics',
              ),
              _AdminItem(
                label: 'Engagement-Metriken',
                subtitle: 'XP-Verteilung, Challenge-Beteiligung, Community',
                route: '/admin/engagement',
              ),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
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
      title: Text(item.label, style: AppTextStyles.bodyMd),
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
      onTap: () {
        if (item.route == RouteNames.adminNfc) {
          unawaited(context.push(RouteNames.adminNfc));
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.label} — noch nicht implementiert')),
        );
      },
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _AdminItem {
  const _AdminItem({required this.label, required this.route, this.subtitle});
  final String label;
  final String route;
  final String? subtitle;
}
