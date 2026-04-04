import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_providers.dart';

class AdminRolesScreen extends HookConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) {
      return _errorScaffold('Kein aktives Gym.');
    }

    final membersAsync = ref.watch(adminMembersProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('ROLLEN & RECHTE'),
        backgroundColor: AppColors.surface900,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Rollenübersicht',
            onPressed: () => _showRolesInfo(context),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
        ),
        data: (members) {
          final active = members.where((m) => m.status == 'active').toList();
          final byRole = <String, List<AdminMember>>{
            'owner': active.where((m) => m.role == 'owner').toList(),
            'admin': active.where((m) => m.role == 'admin').toList(),
            'coach': active.where((m) => m.role == 'coach').toList(),
            'member': active.where((m) => m.role == 'member').toList(),
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RoleGroup(
                role: 'owner',
                label: 'OWNER',
                members: byRole['owner']!,
                gymId: gymId,
                showActions: false,
              ),
              const SizedBox(height: 12),
              _RoleGroup(
                role: 'admin',
                label: 'ADMINS (${byRole['admin']!.length})',
                members: byRole['admin']!,
                gymId: gymId,
                showActions: true,
              ),
              const SizedBox(height: 12),
              _RoleGroup(
                role: 'coach',
                label: 'COACHES (${byRole['coach']!.length})',
                members: byRole['coach']!,
                gymId: gymId,
                showActions: true,
              ),
              const SizedBox(height: 12),
              _RoleGroup(
                role: 'member',
                label: 'MITGLIEDER (${byRole['member']!.length})',
                members: byRole['member']!,
                gymId: gymId,
                showActions: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Role group ───────────────────────────────────────────────────────────────

class _RoleGroup extends StatelessWidget {
  const _RoleGroup({
    required this.role,
    required this.label,
    required this.members,
    required this.gymId,
    required this.showActions,
  });

  final String role;
  final String label;
  final List<AdminMember> members;
  final String gymId;
  final bool showActions;

  Color get _accentColor => switch (role) {
        'owner' => AppColors.neonYellow,
        'admin' => AppColors.neonCyan,
        'coach' => AppColors.neonMagenta,
        _ => AppColors.textSecondary,
      };

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.labelMd),
              ],
            ),
          ),
          const Divider(height: 1),
          if (members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Keine Mitglieder in dieser Rolle.',
                style: AppTextStyles.bodySm,
              ),
            )
          else
            ...members.map(
              (m) => _RoleMemberTile(
                member: m,
                gymId: gymId,
                showActions: showActions && !m.isOwner,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Role member tile ─────────────────────────────────────────────────────────

class _RoleMemberTile extends ConsumerWidget {
  const _RoleMemberTile({
    required this.member,
    required this.gymId,
    required this.showActions,
  });

  final AdminMember member;
  final String gymId;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(roleManagementProvider);

    return ListTile(
      leading: _Avatar(
        avatarUrl: member.avatarUrl,
        username: member.username,
      ),
      title: Text('@${member.username}', style: AppTextStyles.bodyMd),
      subtitle: member.displayName != null
          ? Text(member.displayName!, style: AppTextStyles.bodySm)
          : null,
      trailing: showActions
          ? notifier.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _RoleActionMenu(
                  member: member,
                  gymId: gymId,
                  onChanged: (newRole) async {
                    await ref
                        .read(roleManagementProvider.notifier)
                        .setRole(
                          gymId: gymId,
                          targetUserId: member.userId,
                          newRole: newRole,
                        );
                    if (context.mounted) {
                      final err = ref.read(roleManagementProvider).error;
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_friendlyError(err.toString())),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                )
          : null,
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('cannot_change_owner')) return 'Owner-Rolle kann nicht geändert werden.';
    if (raw.contains('cannot_change_own_role')) return 'Eigene Rolle kann nicht geändert werden.';
    if (raw.contains('only_owner_can_promote_admin')) {
      return 'Nur der Owner kann Admins ernennen.';
    }
    return 'Fehler: $raw';
  }
}

// ─── Role action menu ─────────────────────────────────────────────────────────

class _RoleActionMenu extends StatelessWidget {
  const _RoleActionMenu({
    required this.member,
    required this.gymId,
    required this.onChanged,
  });

  final AdminMember member;
  final String gymId;
  final Future<void> Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <PopupMenuEntry<String>>[];

    if (member.role != 'admin' && member.role != 'owner') {
      items.add(const PopupMenuItem(
        value: 'admin',
        child: Text('Zum Admin ernennen'),
      ));
    }
    if (member.role != 'coach' && member.role != 'owner') {
      items.add(const PopupMenuItem(
        value: 'coach',
        child: Text('Zum Coach ernennen'),
      ));
    }
    if (member.role != 'member') {
      items.add(const PopupMenuItem(
        value: 'member',
        child: Text('Zum Mitglied degradieren'),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      onSelected: (role) => unawaited(onChanged(role)),
      itemBuilder: (_) => items,
    );
  }
}

// ─── Roles info dialog ────────────────────────────────────────────────────────

void _showRolesInfo(BuildContext context) {
  unawaited(showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface800,
      title: Text('ROLLEN ERKLÄRT', style: AppTextStyles.h3),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoleInfoRow(
            role: 'OWNER',
            color: AppColors.neonYellow,
            description: 'Voller Zugriff. Kann alle Rollen vergeben und den Account übertragen.',
          ),
          SizedBox(height: 12),
          _RoleInfoRow(
            role: 'ADMIN',
            color: AppColors.neonCyan,
            description: 'Kann Geräte, Übungen, Challenges und Mitglieder verwalten.',
          ),
          SizedBox(height: 12),
          _RoleInfoRow(
            role: 'COACH',
            color: AppColors.neonMagenta,
            description: 'Kann Pläne erstellen und Mitgliederfortschritt einsehen.',
          ),
          SizedBox(height: 12),
          _RoleInfoRow(
            role: 'MITGLIED',
            color: AppColors.textSecondary,
            description: 'Standard-Zugang: tracken, Community, eigener Fortschritt.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  ));
}

class _RoleInfoRow extends StatelessWidget {
  const _RoleInfoRow({
    required this.role,
    required this.color,
    required this.description,
  });
  final String role;
  final Color color;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Text(
            role,
            style: AppTextStyles.bodySm.copyWith(color: color, fontSize: 10),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(description, style: AppTextStyles.bodySm),
        ),
      ],
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.username});
  final String? avatarUrl;
  final String username;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.surface600,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: AppTextStyles.labelMd.copyWith(color: AppColors.neonCyan),
      ),
    );
  }
}

Scaffold _errorScaffold(String message) => Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('ROLLEN & RECHTE'),
        backgroundColor: AppColors.surface900,
      ),
      body: Center(
        child: Text(
          message,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
        ),
      ),
    );
