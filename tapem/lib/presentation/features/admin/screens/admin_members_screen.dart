import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_providers.dart';

class AdminMembersScreen extends HookConsumerWidget {
  const AdminMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(activeGymIdProvider);
    if (gymId == null) {
      return _errorScaffold('Kein aktives Gym.');
    }

    final membersAsync = ref.watch(adminMembersProvider(gymId));
    final searchCtrl = useTextEditingController();
    final searchQuery = useState('');
    useEffect(() {
      searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
      return null;
    }, []);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.surface900,
        appBar: AppBar(
          title: const Text('MITGLIEDER'),
          backgroundColor: AppColors.surface900,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ALLE'),
              Tab(text: 'AKTIV'),
              Tab(text: 'AUSSTEHEND'),
            ],
            indicatorColor: AppColors.neonCyan,
            labelColor: AppColors.neonCyan,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(e.toString(),
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
          ),
          data: (members) {
            final q = searchQuery.value.trim().toLowerCase();
            final filtered = q.isEmpty
                ? members
                : members.where(
                    (m) =>
                        m.username.toLowerCase().contains(q) ||
                        (m.displayName?.toLowerCase().contains(q) ?? false),
                  ).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Mitglied suchen...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: searchCtrl.clear,
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _MemberList(
                        members: filtered,
                        gymId: gymId,
                      ),
                      _MemberList(
                        members: filtered
                            .where(
                              (m) => m.status == 'active' && m.isActive,
                            )
                            .toList(),
                        gymId: gymId,
                      ),
                      _PendingMemberList(
                        members: filtered
                            .where((m) => m.isPending)
                            .toList(),
                        gymId: gymId,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Member list ──────────────────────────────────────────────────────────────

class _MemberList extends StatelessWidget {
  const _MemberList({required this.members, required this.gymId});
  final List<AdminMember> members;
  final String gymId;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Text(
          'Keine Mitglieder.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: members.length,
      itemBuilder: (_, i) => _MemberTile(member: members[i], gymId: gymId),
    );
  }
}

// ─── Pending list ─────────────────────────────────────────────────────────────

class _PendingMemberList extends ConsumerWidget {
  const _PendingMemberList({required this.members, required this.gymId});
  final List<AdminMember> members;
  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.success,
            ),
            const SizedBox(height: 12),
            Text(
              'Keine ausstehenden Anfragen.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: members.length,
      itemBuilder: (_, i) => _PendingMemberTile(
        member: members[i],
        gymId: gymId,
      ),
    );
  }
}

// ─── Pending tile ─────────────────────────────────────────────────────────────

class _PendingMemberTile extends ConsumerWidget {
  const _PendingMemberTile({required this.member, required this.gymId});
  final AdminMember member;
  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(memberManagementProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonYellow.withAlpha(60)),
      ),
      child: Row(
        children: [
          _Avatar(avatarUrl: member.avatarUrl, username: member.username),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${member.username}', style: AppTextStyles.bodyLg),
                Text(
                  'Anfrage: ${_formatDate(member.joinedAt)}',
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
          if (notifier.isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.error, size: 20),
              tooltip: 'Ablehnen',
              onPressed: () => ref
                  .read(memberManagementProvider.notifier)
                  .declineRequest(gymId: gymId, userId: member.userId),
            ),
            IconButton(
              icon: const Icon(
                Icons.check,
                color: AppColors.success,
                size: 20,
              ),
              tooltip: 'Genehmigen',
              onPressed: () => ref
                  .read(memberManagementProvider.notifier)
                  .approveRequest(gymId: gymId, userId: member.userId),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Member tile ──────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.gymId});
  final AdminMember member;
  final String gymId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMemberDetail(context, member, gymId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Row(
          children: [
            _Avatar(
              avatarUrl: member.avatarUrl,
              username: member.username,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${member.username}', style: AppTextStyles.bodyLg),
                  Row(
                    children: [
                      _RoleBadge(role: member.role),
                      if (!member.isActive) ...[
                        const SizedBox(width: 4),
                        _StatusBadge(status: member.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  member.currentLevel != null
                      ? 'LVL ${member.currentLevel}'
                      : '–',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.neonMagenta,
                  ),
                ),
                Text(
                  member.totalXp != null ? '${member.totalXp} XP' : '0 XP',
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Member detail sheet ──────────────────────────────────────────────────────

void _showMemberDetail(
  BuildContext context,
  AdminMember member,
  String gymId,
) {
  unawaited(showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface800,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _MemberDetailSheet(member: member, gymId: gymId),
  ));
}

class _MemberDetailSheet extends ConsumerWidget {
  const _MemberDetailSheet({required this.member, required this.gymId});
  final AdminMember member;
  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(memberManagementProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _Avatar(
                avatarUrl: member.avatarUrl,
                username: member.username,
                radius: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${member.username}', style: AppTextStyles.h3),
                    if (member.displayName != null)
                      Text(member.displayName!, style: AppTextStyles.bodySm),
                    Row(
                      children: [
                        _RoleBadge(role: member.role),
                        const SizedBox(width: 4),
                        if (member.status != 'active')
                          _StatusBadge(status: member.status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Stats
          Row(
            children: [
              _StatCell(
                label: 'XP',
                value: '${member.totalXp ?? 0}',
                color: AppColors.neonMagenta,
              ),
              _StatCell(
                label: 'LEVEL',
                value: '${member.currentLevel ?? 1}',
                color: AppColors.neonCyan,
              ),
              _StatCell(
                label: 'BEIGETRETEN',
                value: _formatDate(member.joinedAt),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actions
          if (!member.isOwner && member.status == 'active') ...[
            const Text('AKTIONEN', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            _DeactivateButton(
              isLoading: notifier.isLoading,
              onPressed: () => _confirmDeactivate(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface800,
        title: const Text('MITGLIEDSCHAFT DEAKTIVIEREN?'),
        content: Text(
          '@${member.username} verliert den Zugang zum Gym. '
          'Trainingsdaten bleiben erhalten.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('DEAKTIVIEREN'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(memberManagementProvider.notifier).deactivate(
            gymId: gymId,
            userId: member.userId,
          );
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _DeactivateButton extends StatelessWidget {
  const _DeactivateButton({required this.isLoading, required this.onPressed});
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.remove_circle_outline, size: 18),
      label: const Text('MITGLIEDSCHAFT DEAKTIVIEREN'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error.withAlpha(80)),
        minimumSize: const Size(double.infinity, 44),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.username,
    this.radius = 20,
  });
  final String? avatarUrl;
  final String username;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface600,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: AppTextStyles.labelMd.copyWith(color: AppColors.neonCyan),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  Color get _color => switch (role) {
        'owner' => AppColors.neonYellow,
        'admin' => AppColors.neonCyan,
        'coach' => AppColors.neonMagenta,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Text(
        role.toUpperCase(),
        style: AppTextStyles.bodySm.copyWith(color: _color, fontSize: 10),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'pending' ? AppColors.neonYellow : AppColors.error;
    final label = status == 'pending' ? 'AUSSTEHEND' : 'INAKTIV';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h3.copyWith(color: color)),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) {
  return DateFormat('dd.MM.yy', 'de_DE').format(d);
}

Scaffold _errorScaffold(String message) => Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        title: const Text('MITGLIEDER'),
        backgroundColor: AppColors.surface900,
      ),
      body: Center(
        child: Text(
          message,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
        ),
      ),
    );
