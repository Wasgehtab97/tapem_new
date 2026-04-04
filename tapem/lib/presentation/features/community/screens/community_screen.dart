import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../domain/entities/auth/user_profile.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../progress/widgets/training_heatmap.dart';
import '../../../widgets/common/user_avatar.dart';
import '../providers/community_provider.dart';
import 'deals_tab.dart';

// ─── Root screen ──────────────────────────────────────────────────────────────

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedTab = 0;

  void _showFindFriends() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface800,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const _FindFriendsSheet(),
      ),
    );
  }

  void _showDealsInfo(AppLocalizations l10n) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DealsInfoSheet(l10n: l10n),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.communityTitle),
        actions: [
          if (_selectedTab == 0)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: _showFindFriends,
              tooltip: l10n.findFriendsTooltip,
            ),
          if (_selectedTab == 2)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: l10n.dealsInfoTitle,
              onPressed: () => _showDealsInfo(l10n),
            ),
        ],
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
      body: Column(
        children: [
          _CommunityTabBar(
            selectedIndex: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
            tabs: [l10n.friendsTab, l10n.rankingsTab, l10n.dealsTab],
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: const [_FriendsTab(), _RankingsTab(), DealsTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Deals info bottom sheet ──────────────────────────────────────────────────

class _DealsInfoSheet extends StatelessWidget {
  const _DealsInfoSheet({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with glow
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.neonCyan.withAlpha(80),
                      width: 1,
                    ),
                    boxShadow: [
                      const BoxShadow(
                        color: AppColors.neonCyanGlow,
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: AppColors.neonCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.dealsInfoTitle,
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.neonCyan,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.dealsInfoBody,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.neonCyan.withAlpha(20),
                      foregroundColor: AppColors.neonCyan,
                      side: BorderSide(
                        color: AppColors.neonCyan.withAlpha(80),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: AppTextStyles.buttonMd,
                    ),
                    child: Text(l10n.dealsInfoGotIt),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom tab bar (no PageView/swipe conflict) ──────────────────────────────

class _CommunityTabBar extends StatelessWidget {
  const _CommunityTabBar({
    required this.selectedIndex,
    required this.onTabChanged,
    required this.tabs,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (i) {
        final active = i == selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: AppTextStyles.labelMd.copyWith(
                      color: active
                          ? AppColors.neonCyan
                          : AppColors.textSecondary,
                    ),
                    child: Text(tabs[i]),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  color: active ? AppColors.neonCyan : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Friends tab ──────────────────────────────────────────────────────────────

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(friendsProvider),
      child: friendsAsync.when(
        data: (friends) {
          if (friends.isEmpty) {
            return _EmptyFriends(
              onFindFriends: () => _showFindFriendsSheet(context),
            );
          }

          final pending = friends
              .where((f) => f.status == 'pending_received')
              .toList();
          final accepted = friends
              .where((f) => f.status == 'accepted')
              .toList();
          final acceptedSameGym = accepted
              .where((f) => f.sharesActiveGym)
              .toList();
          final acceptedOtherGyms = accepted
              .where((f) => !f.sharesActiveGym)
              .toList();
          final sent = friends
              .where((f) => f.status == 'pending_sent')
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionLabel(
                  l10n.requestsSection(pending.length),
                  color: AppColors.neonYellow,
                ),
                const SizedBox(height: 8),
                ...pending.map((f) => _FriendRequestTile(friend: f)),
                const SizedBox(height: 16),
              ],
              if (acceptedSameGym.isNotEmpty) ...[
                _SectionLabel(
                  l10n.friendsSameGymSection(acceptedSameGym.length),
                ),
                const SizedBox(height: 8),
                ...acceptedSameGym.map((f) => _FriendTile(friend: f)),
                const SizedBox(height: 16),
              ],
              if (acceptedOtherGyms.isNotEmpty) ...[
                _SectionLabel(
                  l10n.friendsOtherGymsSection(acceptedOtherGyms.length),
                ),
                const SizedBox(height: 8),
                ...acceptedOtherGyms.map((f) => _FriendTile(friend: f)),
                const SizedBox(height: 16),
              ],
              if (sent.isNotEmpty) ...[
                _SectionLabel(l10n.pendingSection(sent.length)),
                const SizedBox(height: 8),
                ...sent.map(
                  (f) => _FriendTile(friend: f, showPendingBadge: true),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  void _showFindFriendsSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface800,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const _FindFriendsSheet(),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelSm.copyWith(
        color: color ?? AppColors.textSecondary,
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends({required this.onFindFriends});
  final VoidCallback onFindFriends;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 56,
            color: AppColors.textSecondary.withAlpha(100),
          ),
          const SizedBox(height: 20),
          Text(l10n.noFriendsYet, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            l10n.findGymMembers,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onFindFriends,
            icon: const Icon(Icons.person_add_outlined),
            label: Text(l10n.findFriendsBtn),
          ),
        ],
      ),
    );
  }
}

// ─── Friend request tile (incoming) ───────────────────────────────────────────

class _FriendRequestTile extends ConsumerWidget {
  const _FriendRequestTile({required this.friend});
  final FriendUser friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonYellow.withAlpha(80)),
        boxShadow: [
          BoxShadow(color: AppColors.neonYellow.withAlpha(20), blurRadius: 20),
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Avatar(username: friend.username, avatarUrl: friend.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${friend.username}', style: AppTextStyles.labelLg),
                  if (friend.displayName != null)
                    Text(
                      friend.displayName!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonYellow.withAlpha(15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.neonYellow.withAlpha(50),
                      ),
                    ),
                    child: Text(
                      'ANFRAGE',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.neonYellow,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => ref
                  .read(friendActionsProvider.notifier)
                  .acceptRequest(friend.friendshipId),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success.withAlpha(80)),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              tooltip: l10n.acceptTooltip,
            ),
            IconButton(
              onPressed: () => ref
                  .read(friendActionsProvider.notifier)
                  .declineRequest(friend.friendshipId),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface700,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface500),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary.withAlpha(180),
                  size: 18,
                ),
              ),
              tooltip: l10n.declineTooltip,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Friend tile (accepted / pending_sent) ────────────────────────────────────

class _FriendTile extends ConsumerWidget {
  const _FriendTile({required this.friend, this.showPendingBadge = false});
  final FriendUser friend;
  final bool showPendingBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: friend.status == 'accepted'
          ? () => _openProfileSheet(context)
          : null,
      onLongPress: friend.status == 'accepted'
          ? () => _showRemoveDialog(context, ref, l10n)
          : friend.status == 'pending_sent'
          ? () => _showCancelDialog(context, ref, l10n)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: friend.sharesActiveGym
                ? AppColors.neonCyan.withAlpha(60)
                : AppColors.surface500.withAlpha(140),
          ),
          boxShadow: [
            if (friend.sharesActiveGym)
              BoxShadow(
                color: AppColors.neonCyan.withAlpha(18),
                blurRadius: 16,
              ),
            BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _Avatar(username: friend.username, avatarUrl: friend.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${friend.username}',
                      style: AppTextStyles.labelLg.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (friend.sharesActiveGym) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.neonCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          friend.sharesActiveGym
                              ? l10n.friendInYourGym
                              : l10n.friendFromOtherGyms(friend.sharedGymCount),
                          style: AppTextStyles.bodySm.copyWith(
                            color: friend.sharesActiveGym
                                ? AppColors.neonCyan.withAlpha(200)
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (friend.lastTrainingDay != null)
                      Text(
                        _formatLastTraining(friend.lastTrainingDay!, l10n),
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.neonCyan.withAlpha(160),
                          fontSize: 10,
                        ),
                      )
                    else if (friend.status == 'accepted')
                      Text(
                        l10n.privacyPrivate,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              if (showPendingBadge)
                _Badge(label: l10n.pendingBadge)
              else if (friend.status == 'accepted')
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDisabled,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastTraining(String dateStr, AppLocalizations l10n) {
    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.now();
      final diff = DateTime(
        today.year,
        today.month,
        today.day,
      ).difference(DateTime(date.year, date.month, date.day)).inDays;
      if (diff == 0) return l10n.lastTrainedToday;
      if (diff == 1) return l10n.lastTrainedYesterday;
      return l10n.lastTrainedDaysAgo(diff);
    } catch (_) {
      return dateStr;
    }
  }

  void _openProfileSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface800,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _FriendProfileSheet(friend: friend),
      ),
    );
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface800,
        title: Text(l10n.cancelRequestTitle, style: AppTextStyles.h3),
        content: Text(
          l10n.cancelRequestContent(friend.username),
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.cancelRequestBtn,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await ref
        .read(friendActionsProvider.notifier)
        .removeFriend(friend.friendshipId);
  }

  Future<void> _showRemoveDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface800,
        title: Text(l10n.removeFriendTitle, style: AppTextStyles.h3),
        content: Text(
          l10n.removeFriendContent(friend.username),
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.removeFriendBtn,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await ref
        .read(friendActionsProvider.notifier)
        .removeFriend(friend.friendshipId);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface600,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _FriendProfileSheet extends ConsumerStatefulWidget {
  const _FriendProfileSheet({required this.friend});
  final FriendUser friend;

  @override
  ConsumerState<_FriendProfileSheet> createState() =>
      _FriendProfileSheetState();
}

class _FriendProfileSheetState extends ConsumerState<_FriendProfileSheet> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  void _prevYear() => setState(() => _year--);

  void _nextYear() {
    if (_year < DateTime.now().year) {
      setState(() => _year++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final friend = widget.friend;
    final daysAsync = ref.watch(
      friendTrainingDaysProvider(
        FriendCalendarQuery(friendUserId: friend.userId, year: _year),
      ),
    );
    final summaryAsync = ref.watch(
      friendLastSessionSummaryProvider(
        FriendSessionSummaryQuery(friendUserId: friend.userId),
      ),
    );

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.friendProfileTitle,
                      style: AppTextStyles.h3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: UserAvatar(
                          username: friend.username,
                          radius: 38,
                          avatarUrl: friend.avatarUrl,
                          borderColor: friend.sharesActiveGym
                              ? AppColors.neonCyan
                              : AppColors.neonYellow,
                          borderWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          '@${friend.username}',
                          style: AppTextStyles.h3,
                        ),
                      ),
                      if (friend.displayName != null) ...[
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            friend.displayName!,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(
                            label: friend.sharesActiveGym
                                ? l10n.friendTagSameGym
                                : l10n.friendTagOtherGym,
                          ),
                          _Badge(
                            label: l10n.sharedGymsCount(friend.sharedGymCount),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface700,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surface500),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.friendTrainingCalendar,
                                    style: AppTextStyles.labelMd,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _prevYear,
                                  icon: const Icon(Icons.chevron_left_rounded),
                                ),
                                Text('$_year', style: AppTextStyles.monoSm),
                                IconButton(
                                  onPressed: _year < DateTime.now().year
                                      ? _nextYear
                                      : null,
                                  icon: const Icon(Icons.chevron_right_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            daysAsync.when(
                              data: (days) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TrainingHeatmap(
                                    year: _year,
                                    trainingDays: days,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        l10n.friendTrainingDaysCount(
                                          days.length,
                                          _year,
                                        ),
                                        style: AppTextStyles.bodySm.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: days.isEmpty
                                            ? null
                                            : () => _openHeatmapDialog(
                                                context,
                                                days,
                                              ),
                                        child: Text(l10n.openCalendarBtn),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: LinearProgressIndicator(
                                  color: AppColors.neonCyan,
                                  backgroundColor: AppColors.surface600,
                                ),
                              ),
                              error: (_, __) => Text(
                                l10n.friendCalendarUnavailable,
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface700,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surface500),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.friendLastSessionSummary,
                              style: AppTextStyles.labelMd,
                            ),
                            const SizedBox(height: 8),
                            summaryAsync.when(
                              data: (summary) {
                                if (summary == null) {
                                  return Text(
                                    l10n.friendSessionSummaryHidden,
                                    style: AppTextStyles.bodySm.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.friendSessionDay(summary.sessionDay),
                                      style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l10n.friendExerciseCount(
                                              summary.exerciseCount,
                                            ),
                                            style: AppTextStyles.bodyMd,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            l10n.friendSetCount(
                                              summary.setCount,
                                            ),
                                            style: AppTextStyles.bodyMd,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(
                                  color: AppColors.neonYellow,
                                  backgroundColor: AppColors.surface600,
                                ),
                              ),
                              error: (_, __) => Text(
                                l10n.friendSessionSummaryUnavailable,
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (friend.status == 'accepted') ...[
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => _removeFriend(context, friend),
                          icon: const Icon(Icons.person_remove_alt_1_rounded),
                          label: Text(l10n.removeFriendBtn),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHeatmapDialog(BuildContext context, Set<String> days) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => TrainingHeatmapDialog(year: _year, trainingDays: days),
      ),
    );
  }

  Future<void> _removeFriend(BuildContext context, FriendUser friend) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface800,
        title: Text(l10n.removeFriendTitle, style: AppTextStyles.h3),
        content: Text(
          l10n.removeFriendContent(friend.username),
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.removeFriendBtn,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(friendActionsProvider.notifier)
        .removeFriend(friend.friendshipId);
    if (!mounted) return;
    Navigator.of(this.context).pop();
  }
}

// ─── Rankings tab (LoL-inspired leaderboard) ──────────────────────────────────

class _RankingsTab extends ConsumerStatefulWidget {
  const _RankingsTab();

  @override
  ConsumerState<_RankingsTab> createState() => _RankingsTabState();
}

class _RankingsTabState extends ConsumerState<_RankingsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gymName = ref
        .watch(activeMembershipProvider)
        .maybeWhen(data: (m) => m?.gymName, orElse: () => null);

    return Column(
      children: [
        _LeaderboardSeasonHeader(gymName: gymName),
        _LeaderboardAxisTabBar(controller: _tabController),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _LeaderboardView(axis: kAxisTrainingDay),
              _EquipmentOverviewView(),
              _MachinePerformanceView(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Season header banner ─────────────────────────────────────────────────────

class _LeaderboardSeasonHeader extends StatelessWidget {
  const _LeaderboardSeasonHeader({this.gymName});
  final String? gymName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.surface800,
            AppColors.neonCyan.withAlpha(14),
            AppColors.surface800,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.neonCyan.withAlpha(50)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppColors.neonCyan,
                    AppColors.neonCyan.withAlpha(180),
                  ],
                ).createShader(bounds),
                child: Text(
                  'GYM LEADERBOARD',
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                    letterSpacing: 2.0,
                    height: 1.1,
                  ),
                ),
              ),
              if (gymName != null) ...[
                const SizedBox(height: 2),
                Text(
                  gymName!.toUpperCase(),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.neonCyan.withAlpha(28),
                  AppColors.neonCyan.withAlpha(10),
                ],
              ),
              border: Border.all(color: AppColors.neonCyan.withAlpha(110)),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCyan.withAlpha(30),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              'SEASON 1',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.neonCyan,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Axis tab bar ─────────────────────────────────────────────────────────────

class _LeaderboardAxisTabBar extends StatelessWidget {
  const _LeaderboardAxisTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface900,
        border: Border(
          bottom: BorderSide(color: AppColors.surface500.withAlpha(120)),
        ),
      ),
      child: TabBar(
        controller: controller,
        indicatorColor: AppColors.neonCyan,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.neonCyan,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelSm.copyWith(
          letterSpacing: 1.5,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.labelSm.copyWith(
          letterSpacing: 1.5,
          fontSize: 11,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'KONSISTENZ'),
          Tab(text: 'EQUIPMENT XP'),
          Tab(text: 'PERFORMANCE'),
        ],
      ),
    );
  }
}

// ─── Machine performance tab (best-set e1RM) ──────────────────────────────────

class _PerfPagerIntent extends Intent {
  const _PerfPagerIntent(this.delta);
  final int delta;
}

abstract final class _PerfSwipeTokens {
  static const bgTop = AppColors.surface900;
  static const bgBottom = AppColors.surface900;
  static const card = AppColors.surface800;
  static const cardAlt = AppColors.surface700;
  static const border = AppColors.surface500;
  static const divider = AppColors.surface500;
  static const cyan = AppColors.neonCyan;
  static const gold = AppColors.neonYellowDim;
  static const text = AppColors.textPrimary;
  static const muted = AppColors.textSecondary;
  static const selected = AppColors.neonCyanGlow;

  static const radiusXl = 16.0;
  static const radiusLg = 12.0;
  static const radiusMd = 8.0;
  static const radiusSm = 4.0;
}

abstract final class _PerfSwipeText {
  static TextStyle get title => AppTextStyles.h3.copyWith(
    color: _PerfSwipeTokens.text,
    letterSpacing: 1.2,
  );

  static TextStyle get section => AppTextStyles.labelSm.copyWith(
    color: _PerfSwipeTokens.muted,
    letterSpacing: 1.2,
    fontSize: 10,
  );

  static TextStyle get body => AppTextStyles.bodySm.copyWith(
    color: _PerfSwipeTokens.muted,
    fontSize: 12,
    height: 1.4,
  );

  static TextStyle get strong => AppTextStyles.bodyMd.copyWith(
    color: _PerfSwipeTokens.text,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle get metric => AppTextStyles.monoSm.copyWith(
    color: _PerfSwipeTokens.gold,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    letterSpacing: 0.4,
  );

  static TextStyle get headerCell => AppTextStyles.labelSm.copyWith(
    color: _PerfSwipeTokens.muted,
    fontSize: 10,
    letterSpacing: 1.1,
    fontWeight: FontWeight.w700,
  );
}

class _MachinePerformanceView extends ConsumerStatefulWidget {
  const _MachinePerformanceView();

  @override
  ConsumerState<_MachinePerformanceView> createState() =>
      _MachinePerformanceViewState();
}

class _MachinePerformanceViewState
    extends ConsumerState<_MachinePerformanceView> {
  static const _pageCount = 3;

  final PageController _pageController = PageController();

  MachinePerformanceSex _selectedSex = MachinePerformanceSex.male;
  String? _selectedEquipmentId;
  String _searchQuery = '';
  bool _showOnlyRanked = false;
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatYmd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatWeight(double kg) {
    final rounded = kg.roundToDouble();
    if ((kg - rounded).abs() < 0.05) return rounded.toInt().toString();
    return kg.toStringAsFixed(1);
  }

  Future<void> _refresh() async {
    ref.invalidate(machinePerformanceBoardsProvider(_selectedSex));
    final selectedEquipmentId = _selectedEquipmentId;
    if (selectedEquipmentId != null) {
      ref.invalidate(
        machinePerformanceLeaderboardProvider((
          equipmentId: selectedEquipmentId,
          sex: _selectedSex,
        )),
      );
    }
  }

  Future<void> _goToPage(int index) async {
    final target = index.clamp(0, _pageCount - 1);
    await _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goByDelta(int delta) async {
    await _goToPage(_pageIndex + delta);
  }

  List<MachinePerformanceBoardEntry> _filterBoards(
    List<MachinePerformanceBoardEntry> boards,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = boards.where((board) {
      if (_showOnlyRanked && board.participantCount <= 0) return false;
      if (query.isEmpty) return true;
      final haystack = [
        board.exerciseName,
        board.equipmentName,
        board.manufacturer ?? '',
        board.exerciseKey,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final exerciseCmp = a.exerciseName.toLowerCase().compareTo(
        b.exerciseName.toLowerCase(),
      );
      if (exerciseCmp != 0) return exerciseCmp;
      if (a.participantCount != b.participantCount) {
        return b.participantCount.compareTo(a.participantCount);
      }
      return a.equipmentName.toLowerCase().compareTo(
        b.equipmentName.toLowerCase(),
      );
    });
    return filtered;
  }

  Future<void> _openBoardPicker(
    List<MachinePerformanceBoardEntry> boards,
  ) async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MachineBoardPickerSheet(
        boards: boards,
        selectedEquipmentId: _selectedEquipmentId,
        initialQuery: _searchQuery,
        initialOnlyRanked: _showOnlyRanked,
        formatWeight: _formatWeight,
      ),
    );
    if (!mounted || selectedId == null) return;
    setState(() => _selectedEquipmentId = selectedId);
    await _goToPage(1);
  }

  Future<void> _selectBoard(String equipmentId) async {
    setState(() => _selectedEquipmentId = equipmentId);
    await _goToPage(1);
  }

  @override
  Widget build(BuildContext context) {
    final boardsAsync = ref.watch(
      machinePerformanceBoardsProvider(_selectedSex),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_PerfSwipeTokens.bgTop, _PerfSwipeTokens.bgBottom],
        ),
      ),
      child: Column(
        children: [
          _MachinePerformanceTopBar(
            selectedSex: _selectedSex,
            selectedBoardLabel: _selectedEquipmentId == null
                ? 'No board selected'
                : 'Board selected',
            pageIndex: _pageIndex,
            onSexChanged: (sex) {
              setState(() {
                _selectedSex = sex;
                _selectedEquipmentId = null;
              });
            },
            onPreviousCard: () => _goByDelta(-1),
            onNextCard: () => _goByDelta(1),
          ),
          Expanded(
            child: RefreshIndicator(
              color: _PerfSwipeTokens.cyan,
              backgroundColor: _PerfSwipeTokens.card,
              onRefresh: _refresh,
              child: boardsAsync.when(
                loading: () => _MachinePerformancePagerShell(
                  controller: _pageController,
                  pageIndex: _pageIndex,
                  onPageChanged: (value) => setState(() => _pageIndex = value),
                  onDeltaNavigate: _goByDelta,
                  cards: const [
                    _MachinePerfLoadingCard(
                      key: Key('machine-perf-card-board-picker'),
                      title: 'BOARD PICKER',
                    ),
                    _MachinePerfLoadingCard(
                      key: Key('machine-perf-card-ladder'),
                      title: 'RANKED LADDER',
                    ),
                    _MachinePerfLoadingCard(
                      key: Key('machine-perf-card-summary'),
                      title: 'SUMMARY',
                    ),
                  ],
                ),
                error: (error, _) => _MachinePerformancePagerShell(
                  controller: _pageController,
                  pageIndex: _pageIndex,
                  onPageChanged: (value) => setState(() => _pageIndex = value),
                  onDeltaNavigate: _goByDelta,
                  cards: [
                    _MachinePerformanceStateCard(
                      key: const Key('machine-perf-card-board-picker'),
                      title: 'Boards unavailable',
                      body:
                          'Could not load machine boards. Pull to refresh or retry.',
                      icon: Icons.sync_problem_rounded,
                      actionLabel: 'Retry',
                      onAction: () => ref.invalidate(
                        machinePerformanceBoardsProvider(_selectedSex),
                      ),
                    ),
                    const _MachinePerformanceStateCard(
                      key: Key('machine-perf-card-ladder'),
                      title: 'Ladder unavailable',
                      body:
                          'Board data is required before ladder can be shown.',
                      icon: Icons.format_list_numbered_rounded,
                    ),
                    const _MachinePerformanceStateCard(
                      key: Key('machine-perf-card-summary'),
                      title: 'Summary unavailable',
                      body:
                          'Board data is required before summary can be shown.',
                      icon: Icons.auto_graph_rounded,
                    ),
                  ],
                ),
                data: (boards) {
                  final filteredBoards = _filterBoards(boards);
                  final selectedBoard = _selectedEquipmentId == null
                      ? null
                      : boards
                            .where((b) => b.equipmentId == _selectedEquipmentId)
                            .firstOrNull;

                  final leaderboardAsync = selectedBoard == null
                      ? const AsyncValue.data(
                          <MachinePerformanceLeaderboardEntry>[],
                        )
                      : ref.watch(
                          machinePerformanceLeaderboardProvider((
                            equipmentId: selectedBoard.equipmentId,
                            sex: _selectedSex,
                          )),
                        );

                  return _MachinePerformancePagerShell(
                    controller: _pageController,
                    pageIndex: _pageIndex,
                    onPageChanged: (value) =>
                        setState(() => _pageIndex = value),
                    onDeltaNavigate: _goByDelta,
                    cards: [
                      _MachinePerformanceBoardCard(
                        key: const Key('machine-perf-card-board-picker'),
                        boards: boards,
                        filteredBoards: filteredBoards,
                        selectedBoard: selectedBoard,
                        searchQuery: _searchQuery,
                        showOnlyRanked: _showOnlyRanked,
                        formatWeight: _formatWeight,
                        onSearchChanged: (value) =>
                            setState(() => _searchQuery = value),
                        onToggleOnlyRanked: (value) =>
                            setState(() => _showOnlyRanked = value),
                        onOpenPicker: () => _openBoardPicker(boards),
                        onSelectBoard: _selectBoard,
                        onClearSelection: selectedBoard == null
                            ? null
                            : () => setState(() => _selectedEquipmentId = null),
                      ),
                      _MachinePerformanceLadderCard(
                        key: const Key('machine-perf-card-ladder'),
                        selectedBoard: selectedBoard,
                        leaderboardAsync: leaderboardAsync,
                        formatWeight: _formatWeight,
                        dateFormatter: _formatYmd,
                        onOpenPicker: () => _openBoardPicker(boards),
                      ),
                      _MachinePerformanceSummaryCard(
                        key: const Key('machine-perf-card-summary'),
                        selectedBoard: selectedBoard,
                        leaderboardAsync: leaderboardAsync,
                        formatWeight: _formatWeight,
                        onOpenPicker: () => _openBoardPicker(boards),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          _MachinePerformancePageDots(current: _pageIndex, count: _pageCount),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _MachinePerformanceTopBar extends StatelessWidget {
  const _MachinePerformanceTopBar({
    required this.selectedSex,
    required this.selectedBoardLabel,
    required this.pageIndex,
    required this.onSexChanged,
    required this.onPreviousCard,
    required this.onNextCard,
  });

  final MachinePerformanceSex selectedSex;
  final String selectedBoardLabel;
  final int pageIndex;
  final ValueChanged<MachinePerformanceSex> onSexChanged;
  final VoidCallback onPreviousCard;
  final VoidCallback onNextCard;

  @override
  Widget build(BuildContext context) {
    const pageLabels = ['Board', 'Ladder', 'Summary'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _PerfSwipeTokens.card,
        borderRadius: BorderRadius.circular(_PerfSwipeTokens.radiusLg),
        border: Border.all(color: _PerfSwipeTokens.border),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PERFORMANCE', style: _PerfSwipeText.section),
                    const SizedBox(height: 2),
                    Text('Swipe Cards', style: _PerfSwipeText.title),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _PerfSwipeTokens.cardAlt,
                  borderRadius: BorderRadius.circular(
                    _PerfSwipeTokens.radiusSm,
                  ),
                  border: Border.all(color: _PerfSwipeTokens.border),
                ),
                child: Text(
                  pageLabels[pageIndex],
                  style: _PerfSwipeText.strong.copyWith(
                    fontSize: 12,
                    color: _PerfSwipeTokens.cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedBoardLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _PerfSwipeText.body,
                ),
              ),
              const SizedBox(width: 8),
              _SexToggle(selectedSex: selectedSex, onChanged: onSexChanged),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPreviousCard,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _PerfSwipeTokens.muted,
                  side: const BorderSide(color: _PerfSwipeTokens.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _PerfSwipeTokens.radiusSm,
                    ),
                  ),
                ),
                label: Text(
                  'Prev',
                  style: _PerfSwipeText.strong.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onNextCard,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _PerfSwipeTokens.cyan,
                  side: const BorderSide(color: _PerfSwipeTokens.cyan),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _PerfSwipeTokens.radiusSm,
                    ),
                  ),
                ),
                label: Text(
                  'Next',
                  style: _PerfSwipeText.strong.copyWith(
                    fontSize: 12,
                    color: _PerfSwipeTokens.cyan,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SexToggle extends StatelessWidget {
  const _SexToggle({required this.selectedSex, required this.onChanged});

  final MachinePerformanceSex selectedSex;
  final ValueChanged<MachinePerformanceSex> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget button(MachinePerformanceSex sex, String label, IconData icon) {
      final selected = sex == selectedSex;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(_PerfSwipeTokens.radiusSm),
          onTap: () => onChanged(sex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? _PerfSwipeTokens.cyan.withAlpha(28)
                  : _PerfSwipeTokens.cardAlt,
              borderRadius: BorderRadius.circular(_PerfSwipeTokens.radiusSm),
              border: Border.all(
                color: selected
                    ? _PerfSwipeTokens.cyan
                    : _PerfSwipeTokens.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? _PerfSwipeTokens.cyan
                      : _PerfSwipeTokens.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: _PerfSwipeText.strong.copyWith(
                    fontSize: 11,
                    color: selected
                        ? _PerfSwipeTokens.cyan
                        : _PerfSwipeTokens.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 220,
      child: Row(
        children: [
          button(MachinePerformanceSex.male, 'MALE', Icons.male_rounded),
          const SizedBox(width: 6),
          button(MachinePerformanceSex.female, 'FEMALE', Icons.female_rounded),
        ],
      ),
    );
  }
}

class _MachinePerformancePagerShell extends StatelessWidget {
  const _MachinePerformancePagerShell({
    required this.controller,
    required this.pageIndex,
    required this.onPageChanged,
    required this.onDeltaNavigate,
    required this.cards,
  });

  final PageController controller;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onDeltaNavigate;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PerfPagerIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _PerfPagerIntent(1),
      },
      child: Actions(
        actions: {
          _PerfPagerIntent: CallbackAction<_PerfPagerIntent>(
            onInvoke: (intent) {
              onDeltaNavigate(intent.delta);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PageView.builder(
              key: const Key('machine-perf-pageview'),
              controller: controller,
              physics: const BouncingScrollPhysics(),
              onPageChanged: onPageChanged,
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: cards[index],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MachinePerformanceBoardCard extends StatelessWidget {
  const _MachinePerformanceBoardCard({
    required this.boards,
    required this.filteredBoards,
    required this.selectedBoard,
    required this.searchQuery,
    required this.showOnlyRanked,
    required this.formatWeight,
    required this.onSearchChanged,
    required this.onToggleOnlyRanked,
    required this.onOpenPicker,
    required this.onSelectBoard,
    required this.onClearSelection,
    super.key,
  });

  final List<MachinePerformanceBoardEntry> boards;
  final List<MachinePerformanceBoardEntry> filteredBoards;
  final MachinePerformanceBoardEntry? selectedBoard;
  final String searchQuery;
  final bool showOnlyRanked;
  final String Function(double) formatWeight;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onToggleOnlyRanked;
  final VoidCallback onOpenPicker;
  final ValueChanged<String> onSelectBoard;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    final previewBoards = filteredBoards.take(8).toList(growable: false);
    return _PerfCardShell(
      title: 'BOARD PICKER',
      subtitle:
          'Pick one fixed-machine board. One board = one machine variant leaderboard.',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (selectedBoard != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _PerfSwipeTokens.selected,
                borderRadius: BorderRadius.circular(_PerfSwipeTokens.radiusSm),
                border: Border.all(color: _PerfSwipeTokens.cyan.withAlpha(170)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    color: _PerfSwipeTokens.cyan,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${selectedBoard!.equipmentName} · ${selectedBoard!.exerciseName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _PerfSwipeText.strong.copyWith(
                        color: _PerfSwipeTokens.cyan,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (onClearSelection != null)
                    TextButton(
                      onPressed: onClearSelection,
                      child: Text(
                        'Clear',
                        style: _PerfSwipeText.body.copyWith(
                          color: _PerfSwipeTokens.text,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('machine-board-selector-search'),
                  onChanged: onSearchChanged,
                  style: _PerfSwipeText.strong.copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search board',
                    hintStyle: _PerfSwipeText.body,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: _PerfSwipeTokens.muted,
                    ),
                    suffixIcon: searchQuery.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => onSearchChanged(''),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            color: _PerfSwipeTokens.muted,
                          ),
                    filled: true,
                    fillColor: _PerfSwipeTokens.cardAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _PerfSwipeTokens.radiusSm,
                      ),
                      borderSide: const BorderSide(
                        color: _PerfSwipeTokens.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _PerfSwipeTokens.radiusSm,
                      ),
                      borderSide: const BorderSide(
                        color: _PerfSwipeTokens.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _PerfSwipeTokens.radiusSm,
                      ),
                      borderSide: const BorderSide(
                        color: _PerfSwipeTokens.cyan,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  key: const Key('machine-board-selector-open'),
                  onPressed: onOpenPicker,
                  icon: const Icon(Icons.view_list_rounded, size: 16),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _PerfSwipeTokens.cyan,
                    side: const BorderSide(color: _PerfSwipeTokens.cyan),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        _PerfSwipeTokens.radiusSm,
                      ),
                    ),
                  ),
                  label: Text(
                    'Browse',
                    style: _PerfSwipeText.strong.copyWith(
                      color: _PerfSwipeTokens.cyan,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                selected: showOnlyRanked,
                onSelected: onToggleOnlyRanked,
                backgroundColor: _PerfSwipeTokens.cardAlt,
                selectedColor: _PerfSwipeTokens.cyan.withAlpha(24),
                side: BorderSide(
                  color: showOnlyRanked
                      ? _PerfSwipeTokens.cyan
                      : _PerfSwipeTokens.border,
                ),
                label: Text(
                  'Only ranked boards',
                  style: _PerfSwipeText.body.copyWith(
                    fontSize: 11,
                    color: showOnlyRanked
                        ? _PerfSwipeTokens.cyan
                        : _PerfSwipeTokens.muted,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${filteredBoards.length}/${boards.length}',
                style: _PerfSwipeText.body.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (filteredBoards.isEmpty)
            const _MachinePerformanceStateCard(
              title: 'No boards match this filter',
              body: 'Adjust search or filters, or open full board directory.',
              icon: Icons.filter_alt_off_rounded,
            )
          else
            ...List.generate(previewBoards.length, (index) {
              final board = previewBoards[index];
              final selected = selectedBoard?.equipmentId == board.equipmentId;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == previewBoards.length - 1 ? 0 : 8,
                ),
                child: InkWell(
                  onTap: () => onSelectBoard(board.equipmentId),
                  borderRadius: BorderRadius.circular(
                    _PerfSwipeTokens.radiusSm,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? _PerfSwipeTokens.selected
                          : _PerfSwipeTokens.cardAlt,
                      borderRadius: BorderRadius.circular(
                        _PerfSwipeTokens.radiusSm,
                      ),
                      border: Border.all(
                        color: selected
                            ? _PerfSwipeTokens.cyan
                            : _PerfSwipeTokens.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                board.equipmentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _PerfSwipeText.strong.copyWith(
                                  fontSize: 12,
                                  color: selected
                                      ? _PerfSwipeTokens.cyan
                                      : _PerfSwipeTokens.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${board.exerciseName} · ${board.manufacturer ?? 'Unknown manufacturer'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _PerfSwipeText.body.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              board.participantCount == 0
                                  ? 'No rank yet'
                                  : '${board.participantCount} ranked',
                              style: _PerfSwipeText.body.copyWith(fontSize: 10),
                            ),
                            if (board.topE1rmKg != null)
                              Text(
                                '${board.topE1rmKg!.toStringAsFixed(1)} kg · ${formatWeight(board.topWeightKg ?? 0)} x ${board.topReps ?? 0}',
                                style: _PerfSwipeText.body.copyWith(
                                  color: _PerfSwipeTokens.gold,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MachineBoardPickerSheet extends StatefulWidget {
  const _MachineBoardPickerSheet({
    required this.boards,
    required this.selectedEquipmentId,
    required this.initialQuery,
    required this.initialOnlyRanked,
    required this.formatWeight,
  });

  final List<MachinePerformanceBoardEntry> boards;
  final String? selectedEquipmentId;
  final String initialQuery;
  final bool initialOnlyRanked;
  final String Function(double) formatWeight;

  @override
  State<_MachineBoardPickerSheet> createState() =>
      _MachineBoardPickerSheetState();
}

class _MachineBoardPickerSheetState extends State<_MachineBoardPickerSheet> {
  late final TextEditingController _controller;
  late bool _onlyRanked;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _onlyRanked = widget.initialOnlyRanked;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MachinePerformanceBoardEntry> _filtered() {
    final q = _controller.text.trim().toLowerCase();
    final filtered = widget.boards.where((board) {
      if (_onlyRanked && board.participantCount <= 0) return false;
      if (q.isEmpty) return true;
      final haystack = [
        board.exerciseName,
        board.equipmentName,
        board.manufacturer ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();

    filtered.sort((a, b) {
      final exerciseCmp = a.exerciseName.toLowerCase().compareTo(
        b.exerciseName.toLowerCase(),
      );
      if (exerciseCmp != 0) return exerciseCmp;
      return a.equipmentName.toLowerCase().compareTo(
        b.equipmentName.toLowerCase(),
      );
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) {
          final filtered = _filtered();
          final grouped = <String, List<MachinePerformanceBoardEntry>>{};
          for (final board in filtered) {
            grouped.putIfAbsent(board.exerciseName, () => []).add(board);
          }
          final exercises = grouped.keys.toList()
            ..sort((a, b) => a.compareTo(b));

          return DecoratedBox(
            decoration: BoxDecoration(
              color: _PerfSwipeTokens.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_PerfSwipeTokens.radiusXl),
              ),
              border: Border.all(color: _PerfSwipeTokens.border),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _PerfSwipeTokens.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BOARD DIRECTORY', style: _PerfSwipeText.section),
                      const SizedBox(height: 4),
                      Text('Exercise + Machine', style: _PerfSwipeText.title),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('machine-board-picker-search'),
                        controller: _controller,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: _PerfSwipeText.strong.copyWith(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search exercises or machines',
                          hintStyle: _PerfSwipeText.body,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 17,
                            color: _PerfSwipeTokens.muted,
                          ),
                          filled: true,
                          fillColor: _PerfSwipeTokens.cardAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              _PerfSwipeTokens.radiusSm,
                            ),
                            borderSide: const BorderSide(
                              color: _PerfSwipeTokens.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              _PerfSwipeTokens.radiusSm,
                            ),
                            borderSide: const BorderSide(
                              color: _PerfSwipeTokens.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              _PerfSwipeTokens.radiusSm,
                            ),
                            borderSide: const BorderSide(
                              color: _PerfSwipeTokens.cyan,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilterChip(
                            selected: _onlyRanked,
                            onSelected: (value) =>
                                setState(() => _onlyRanked = value),
                            label: const Text('Only ranked'),
                            backgroundColor: _PerfSwipeTokens.cardAlt,
                            selectedColor: _PerfSwipeTokens.cyan.withAlpha(24),
                            side: BorderSide(
                              color: _onlyRanked
                                  ? _PerfSwipeTokens.cyan
                                  : _PerfSwipeTokens.border,
                            ),
                            labelStyle: _PerfSwipeText.body.copyWith(
                              fontSize: 11,
                              color: _onlyRanked
                                  ? _PerfSwipeTokens.cyan
                                  : _PerfSwipeTokens.muted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${filtered.length} boards',
                            style: _PerfSwipeText.body.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _PerfSwipeTokens.divider),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No machine boards match this filter.',
                            style: _PerfSwipeText.body,
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: exercises.length,
                          itemBuilder: (context, exerciseIndex) {
                            final exerciseName = exercises[exerciseIndex];
                            final boards = grouped[exerciseName] ?? const [];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                              child: _MachineBoardExerciseGroup(
                                exerciseName: exerciseName,
                                boards: boards,
                                selectedEquipmentId: widget.selectedEquipmentId,
                                formatWeight: widget.formatWeight,
                                onSelect: (equipmentId) =>
                                    Navigator.of(context).pop(equipmentId),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MachineBoardExerciseGroup extends StatelessWidget {
  const _MachineBoardExerciseGroup({
    required this.exerciseName,
    required this.boards,
    required this.selectedEquipmentId,
    required this.formatWeight,
    required this.onSelect,
  });

  final String exerciseName;
  final List<MachinePerformanceBoardEntry> boards;
  final String? selectedEquipmentId;
  final String Function(double) formatWeight;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _PerfSwipeTokens.cardAlt,
        borderRadius: BorderRadius.circular(_PerfSwipeTokens.radiusMd),
        border: Border.all(color: _PerfSwipeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    exerciseName,
                    style: _PerfSwipeText.strong.copyWith(fontSize: 13),
                  ),
                ),
                Text(
                  '${boards.length} variants',
                  style: _PerfSwipeText.body.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _PerfSwipeTokens.divider),
          ...boards.map((board) {
            final selected = selectedEquipmentId == board.equipmentId;
            return InkWell(
              key: Key('machine-board-option-${board.equipmentId}'),
              onTap: () => onSelect(board.equipmentId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: selected
                      ? _PerfSwipeTokens.selected
                      : Colors.transparent,
                  border: const Border(
                    bottom: BorderSide(color: _PerfSwipeTokens.divider),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            board.equipmentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _PerfSwipeText.strong.copyWith(
                              fontSize: 12,
                              color: selected
                                  ? _PerfSwipeTokens.cyan
                                  : _PerfSwipeTokens.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            board.manufacturer ?? 'Unknown manufacturer',
                            style: _PerfSwipeText.body.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      board.topE1rmKg == null
                          ? 'No rank yet'
                          : '${board.topE1rmKg!.toStringAsFixed(1)} kg · ${formatWeight(board.topWeightKg ?? 0)} x ${board.topReps ?? 0}',
                      style: _PerfSwipeText.body.copyWith(
                        fontSize: 10,
                        color: board.topE1rmKg == null
                            ? _PerfSwipeTokens.muted
                            : _PerfSwipeTokens.gold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MachinePerformanceLadderCard extends StatelessWidget {
  const _MachinePerformanceLadderCard({
    required this.selectedBoard,
    required this.leaderboardAsync,
    required this.formatWeight,
    required this.dateFormatter,
    required this.onOpenPicker,
    super.key,
  });

  final MachinePerformanceBoardEntry? selectedBoard;
  final AsyncValue<List<MachinePerformanceLeaderboardEntry>> leaderboardAsync;
  final String Function(double) formatWeight;
  final String Function(DateTime) dateFormatter;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    return _PerfCardShell(
      title: 'RANKED LADDER',
      subtitle: selectedBoard == null
          ? 'Select a board first to open leaderboard.'
          : '${selectedBoard!.equipmentName} · ${selectedBoard!.exerciseName}',
      action: selectedBoard == null
          ? OutlinedButton.icon(
              onPressed: onOpenPicker,
              icon: const Icon(Icons.flag_rounded, size: 16),
              style: OutlinedButton.styleFrom(
                foregroundColor: _PerfSwipeTokens.cyan,
                side: const BorderSide(color: _PerfSwipeTokens.cyan),
              ),
              label: Text(
                'Select board',
                style: _PerfSwipeText.strong.copyWith(
                  fontSize: 12,
                  color: _PerfSwipeTokens.cyan,
                ),
              ),
            )
          : null,
      child: selectedBoard == null
          ? const _MachinePerformanceStateCard(
              title: 'No board selected',
              body:
                  'Choose one board in card 1. Then swipe back here to see ranking.',
              icon: Icons.flag_rounded,
            )
          : leaderboardAsync.when(
              loading: () => const _MachinePerfTableSkeleton(),
              error: (error, _) => _MachinePerformanceStateCard(
                title: 'Could not load ladder',
                body: 'Please retry. ${error.toString()}',
                icon: Icons.wifi_tethering_error_rounded,
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return const _MachinePerformanceStateCard(
                    title: 'No eligible ranked result yet for this selection',
                    body:
                        'No opted-in athlete with matching sex has a qualifying fixed-machine result on this board.',
                    icon: Icons.hourglass_empty_rounded,
                  );
                }

                final estimated = rows.length * 56.0 + 56;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best set format: weight x reps',
                      style: _PerfSwipeText.body.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          _PerfSwipeTokens.radiusSm,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _PerfSwipeTokens.cardAlt,
                            border: Border.all(color: _PerfSwipeTokens.border),
                          ),
                          child: CustomScrollView(
                            cacheExtent: 1200,
                            slivers: [
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _LadderHeaderDelegate(),
                              ),
                              if (rows.length <= 200)
                                SliverList(
                                  delegate: SliverChildListDelegate.fixed(
                                    rows
                                        .map(
                                          (row) => _MachineLadderRow(
                                            row: row,
                                            bestSet:
                                                '${formatWeight(row.bestWeightKg)} x ${row.bestReps}',
                                            dateLabel: dateFormatter(
                                              row.achievedAt,
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                )
                              else
                                SliverList.builder(
                                  itemCount: rows.length,
                                  itemBuilder: (context, index) {
                                    final row = rows[index];
                                    return _MachineLadderRow(
                                      row: row,
                                      bestSet:
                                          '${formatWeight(row.bestWeightKg)} x ${row.bestReps}',
                                      dateLabel: dateFormatter(row.achievedAt),
                                    );
                                  },
                                ),
                              if (estimated < 320)
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 8),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _LadderHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 42;

  @override
  double get maxExtent => 42;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      key: const Key('machine-ladder-header'),
      decoration: const BoxDecoration(
        color: _PerfSwipeTokens.card,
        border: Border(bottom: BorderSide(color: _PerfSwipeTokens.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text('#', style: _PerfSwipeText.headerCell),
          ),
          Expanded(child: Text('ATHLETE', style: _PerfSwipeText.headerCell)),
          SizedBox(
            width: 102,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('BEST SET', style: _PerfSwipeText.headerCell),
            ),
          ),
          SizedBox(
            width: 86,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('E1RM', style: _PerfSwipeText.headerCell),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _MachineLadderRow extends StatelessWidget {
  const _MachineLadderRow({
    required this.row,
    required this.bestSet,
    required this.dateLabel,
  });

  final MachinePerformanceLeaderboardEntry row;
  final String bestSet;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = row.isCurrentUser;

    return Container(
      key: isCurrentUser
          ? const Key('machine-ladder-row-current-user')
          : Key('machine-ladder-row-${row.rank}'),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? _PerfSwipeTokens.selected
            : (row.rank <= 3
                  ? _PerfSwipeTokens.gold.withAlpha(14)
                  : Colors.transparent),
        border: Border(
          left: BorderSide(
            color: isCurrentUser ? _PerfSwipeTokens.cyan : Colors.transparent,
            width: 2.5,
          ),
          bottom: const BorderSide(color: _PerfSwipeTokens.divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                '#${row.rank}',
                style: _PerfSwipeText.strong.copyWith(
                  fontSize: 12,
                  color: row.rank <= 3
                      ? _PerfSwipeTokens.gold
                      : _PerfSwipeTokens.muted,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${row.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _PerfSwipeText.strong.copyWith(
                      fontSize: 12,
                      color: isCurrentUser
                          ? _PerfSwipeTokens.cyan
                          : _PerfSwipeTokens.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: _PerfSwipeText.body.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 102,
              child: Text(
                bestSet,
                style: _PerfSwipeText.strong.copyWith(fontSize: 12),
              ),
            ),
            SizedBox(
              width: 86,
              child: Text(
                '${row.bestE1rmKg.toStringAsFixed(1)} kg',
                textAlign: TextAlign.right,
                style: _PerfSwipeText.metric,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MachinePerformanceSummaryCard extends StatelessWidget {
  const _MachinePerformanceSummaryCard({
    required this.selectedBoard,
    required this.leaderboardAsync,
    required this.formatWeight,
    required this.onOpenPicker,
    super.key,
  });

  final MachinePerformanceBoardEntry? selectedBoard;
  final AsyncValue<List<MachinePerformanceLeaderboardEntry>> leaderboardAsync;
  final String Function(double) formatWeight;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    return _PerfCardShell(
      title: 'SUMMARY',
      subtitle: 'Board highlights and your personal standing.',
      child: selectedBoard == null
          ? _MachinePerformanceStateCard(
              title: 'No board selected',
              body: 'Select a board first to unlock board summary insights.',
              icon: Icons.insights_rounded,
              actionLabel: 'Choose board',
              onAction: onOpenPicker,
            )
          : leaderboardAsync.when(
              loading: () => const _MachinePerfLoadingCard(title: 'SUMMARY'),
              error: (error, _) => const _MachinePerformanceStateCard(
                title: 'Summary unavailable',
                body: 'Could not load summary for this board.',
                icon: Icons.sync_problem_rounded,
              ),
              data: (rows) {
                final top = rows.firstOrNull;
                final me = rows.where((r) => r.isCurrentUser).firstOrNull;
                final boardBestE1rm =
                    top?.bestE1rmKg ?? selectedBoard!.topE1rmKg;
                final boardBestSet = top == null
                    ? (selectedBoard!.topWeightKg != null &&
                              selectedBoard!.topReps != null
                          ? '${formatWeight(selectedBoard!.topWeightKg!)} x ${selectedBoard!.topReps}'
                          : 'No best set yet')
                    : '${formatWeight(top.bestWeightKg)} x ${top.bestReps}';

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _PerfSwipeTokens.cardAlt,
                        borderRadius: BorderRadius.circular(
                          _PerfSwipeTokens.radiusSm,
                        ),
                        border: Border.all(color: _PerfSwipeTokens.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedBoard!.equipmentName,
                            style: _PerfSwipeText.strong.copyWith(
                              color: _PerfSwipeTokens.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${selectedBoard!.exerciseName} · ${selectedBoard!.manufacturer ?? 'Unknown manufacturer'}',
                            style: _PerfSwipeText.body.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SummaryMetric(
                      label: 'Board Best e1RM',
                      value: boardBestE1rm == null
                          ? 'No ranked score yet'
                          : '${boardBestE1rm.toStringAsFixed(1)} kg',
                    ),
                    _SummaryMetric(
                      label: 'Board Best Set',
                      value: boardBestSet,
                    ),
                    _SummaryMetric(
                      label: 'Record Holder',
                      value: top == null
                          ? 'No record holder yet'
                          : '@${top.username}',
                    ),
                    _SummaryMetric(
                      label: 'Athletes Ranked',
                      value: '${selectedBoard!.participantCount}',
                    ),
                    if (me != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _PerfSwipeTokens.selected,
                          borderRadius: BorderRadius.circular(
                            _PerfSwipeTokens.radiusSm,
                          ),
                          border: Border.all(
                            color: _PerfSwipeTokens.cyan.withAlpha(150),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR POSITION',
                              style: _PerfSwipeText.section.copyWith(
                                color: _PerfSwipeTokens.cyan,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#${me.rank} · ${me.bestE1rmKg.toStringAsFixed(1)} kg',
                              style: _PerfSwipeText.metric,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Best set ${formatWeight(me.bestWeightKg)} x ${me.bestReps}',
                              style: _PerfSwipeText.body.copyWith(
                                color: _PerfSwipeTokens.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _PerfSwipeText.section),
          const SizedBox(height: 2),
          Text(value, style: _PerfSwipeText.strong),
        ],
      ),
    );
  }
}

class _PerfCardShell extends StatelessWidget {
  const _PerfCardShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _PerfSwipeTokens.card,
        borderRadius: BorderRadius.circular(_PerfSwipeTokens.radiusXl),
        border: Border.all(color: _PerfSwipeTokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _PerfSwipeText.title),
                      const SizedBox(height: 3),
                      Text(subtitle, style: _PerfSwipeText.body),
                    ],
                  ),
                ),
                if (action != null) ...[const SizedBox(width: 8), action!],
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _MachinePerformanceStateCard extends StatelessWidget {
  const _MachinePerformanceStateCard({
    required this.title,
    required this.body,
    required this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _PerfSwipeTokens.cardAlt,
        borderRadius: BorderRadius.circular(_PerfSwipeTokens.radiusSm),
        border: Border.all(color: _PerfSwipeTokens.border),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _PerfSwipeTokens.gold),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: _PerfSwipeText.strong)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: _PerfSwipeText.body),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              style: OutlinedButton.styleFrom(
                foregroundColor: _PerfSwipeTokens.cyan,
                side: const BorderSide(color: _PerfSwipeTokens.cyan),
              ),
              label: Text(
                actionLabel!,
                style: _PerfSwipeText.strong.copyWith(
                  color: _PerfSwipeTokens.cyan,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MachinePerfLoadingCard extends StatelessWidget {
  const _MachinePerfLoadingCard({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return _PerfCardShell(
      title: title,
      subtitle: 'Loading card content',
      child: Shimmer.fromColors(
        baseColor: AppColors.surface700,
        highlightColor: AppColors.surface600,
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            _SkeletonLine(width: double.infinity, height: 40),
            SizedBox(height: 8),
            _SkeletonLine(width: double.infinity, height: 40),
            SizedBox(height: 8),
            _SkeletonLine(width: double.infinity, height: 160),
            SizedBox(height: 8),
            _SkeletonLine(width: double.infinity, height: 160),
          ],
        ),
      ),
    );
  }
}

class _MachinePerfTableSkeleton extends StatelessWidget {
  const _MachinePerfTableSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface700,
      highlightColor: AppColors.surface600,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _SkeletonLine(width: double.infinity, height: 40),
          const SizedBox(height: 8),
          ...List.generate(
            6,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _SkeletonLine(width: double.infinity, height: 46),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _MachinePerformancePageDots extends StatelessWidget {
  const _MachinePerformancePageDots({
    required this.current,
    required this.count,
  });

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = current == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected
                ? _PerfSwipeTokens.cyan
                : _PerfSwipeTokens.border.withAlpha(180),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
// ─── Equipment overview tab (per-exercise top user) ───────────────────────────

class _EquipmentOverviewView extends ConsumerWidget {
  const _EquipmentOverviewView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gymEquipmentOverviewProvider);

    return Column(
      children: [
        _EquipmentColumnHeader(),
        Expanded(
          child: async.when(
            skipLoadingOnReload: true,
            loading: () => _EquipmentOverviewLoading(),
            error: (e, _) => _LeaderboardError(message: e.toString()),
            data: (entries) {
              if (entries.isEmpty) {
                // Gym has no active equipment configured yet.
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Noch keine Geräte im Gym konfiguriert.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(gymEquipmentOverviewProvider),
                color: AppColors.neonCyan,
                backgroundColor: AppColors.surface800,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: entries.length + 1, // +1 for privacy note
                  itemBuilder: (_, i) {
                    if (i == entries.length) return const _PrivacyFootnote();
                    return _EquipmentOverviewRow(entry: entries[i]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Loading state: ghost rows matching the equipment row layout ────────────────

class _EquipmentOverviewLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 8,
          itemBuilder: (_, i) => _EquipmentGhostRow(index: i),
        ),
        const Center(
          child: CircularProgressIndicator(
            color: AppColors.neonCyan,
            strokeWidth: 2,
          ),
        ),
      ],
    );
  }
}

class _EquipmentGhostRow extends StatelessWidget {
  const _EquipmentGhostRow({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final opacity = (0.38 - index * 0.032).clamp(0.05, 0.38);
    // Vary placeholder widths so ghost rows look natural
    final nameWidth = 80.0 + (index % 4) * 28.0;
    final userWidth = 60.0 + (index % 3) * 20.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surface500)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Exercise name + user placeholder
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: nameWidth,
                    decoration: BoxDecoration(
                      color: AppColors.surface600,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    width: userWidth,
                    decoration: BoxDecoration(
                      color: AppColors.surface600,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 58,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.surface600,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 54,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.surface600,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentColumnHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.surface900,
        border: Border(bottom: BorderSide(color: AppColors.surface500)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'GERÄT',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            'TOP-ATHLET',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.textDisabled,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 28), // space for chevron
        ],
      ),
    );
  }
}

class _EquipmentOverviewRow extends ConsumerWidget {
  const _EquipmentOverviewRow({required this.entry});
  final EquipmentExerciseEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasData = entry.hasData;
    final hasMyData = entry.hasMyData;
    final isCurrent = entry.isCurrentUser; // I am the top athlete

    return InkWell(
      onTap: () => _openLeaderboardSheet(context, ref),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: hasMyData
                  ? AppColors.neonCyan.withAlpha(100)
                  : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(color: AppColors.surface500.withAlpha(70)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left: machine name + my XP ───────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.equipmentName,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (hasMyData)
                    Text(
                      'Du: ${entry.myXp} XP · LVL ${entry.myLevel}',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.neonCyan.withAlpha(200),
                        fontSize: 10,
                      ),
                    )
                  else
                    Text(
                      'Noch nicht trainiert',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── Right: top athlete ────────────────────────────────────────
            if (hasData) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        size: 11,
                        color: Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '@${entry.topUsername}',
                        style: AppTextStyles.bodySm.copyWith(
                          color: isCurrent
                              ? AppColors.neonCyan
                              : AppColors.neonMagenta,
                          fontSize: 11,
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.topXp} XP · LVL ${entry.topLevel}',
                    style: AppTextStyles.monoSm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                'Niemand',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }

  void _openLeaderboardSheet(BuildContext context, WidgetRef ref) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface800,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => UncontrolledProviderScope(
          container: ProviderScope.containerOf(context),
          child: _EquipmentLeaderboardSheet(entry: entry),
        ),
      ),
    );
  }
}

// ─── Equipment leaderboard sheet ──────────────────────────────────────────────
// Bottom sheet showing ALL gym members ranked by XP on one specific machine.

class _EquipmentLeaderboardSheet extends ConsumerWidget {
  const _EquipmentLeaderboardSheet({required this.entry});
  final EquipmentExerciseEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(
      equipmentLeaderboardProvider(entry.equipmentId),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // ── Sheet header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.surface500)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 18,
                    color: AppColors.neonCyan,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.equipmentName.toUpperCase(),
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.neonCyan,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'LEADERBOARD',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 2,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // ── Column header ───────────────────────────────────────────────
            Container(
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.surface900,
                border: Border(bottom: BorderSide(color: AppColors.surface500)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '#',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textDisabled,
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'ATHLET',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textDisabled,
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      'LEVEL',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textDisabled,
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      'XP',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textDisabled,
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: leaderboardAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.neonCyan,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Fehler: $e',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fitness_center_outlined,
                              size: 40,
                              color: AppColors.textDisabled.withAlpha(120),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Noch niemand hat auf diesem Gerät trainiert.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 48),
                    itemCount: entries.length,
                    itemBuilder: (_, i) =>
                        _EquipmentLeaderboardRow(entry: entries[i]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EquipmentLeaderboardRow extends StatelessWidget {
  const _EquipmentLeaderboardRow({required this.entry});
  final EquipmentLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final rank = entry.rank;
    final isCurrent = entry.isCurrentUser;
    final isTop3 = rank <= 3;

    final Color? medalColor = switch (rank) {
      1 when !isCurrent => const Color(0xFFFFD700),
      2 when !isCurrent => const Color(0xFFC0C0C0),
      3 when !isCurrent => const Color(0xFFCD7F32),
      _ => null,
    };

    final accentColor = isCurrent
        ? AppColors.neonCyan
        : (medalColor ?? AppColors.textSecondary);

    final bgColor = isCurrent
        ? AppColors.neonCyan.withAlpha(18)
        : (medalColor != null ? medalColor.withAlpha(10) : Colors.transparent);

    final leftBorderColor = isCurrent
        ? AppColors.neonCyan
        : (isTop3 ? (medalColor ?? Colors.transparent) : Colors.transparent);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(color: leftBorderColor, width: 3),
          bottom: BorderSide(color: AppColors.surface500.withAlpha(70)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '#$rank',
                    style: AppTextStyles.monoSm.copyWith(
                      color: accentColor,
                      fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w400,
                      fontSize: isTop3 ? 13 : 12,
                    ),
                  ),
                ),
                _LeaderboardAvatar(
                  username: entry.username,
                  accentColor: accentColor,
                  size: 28,
                  avatarUrl: entry.avatarUrl,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '@${entry.username}',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: isCurrent
                          ? AppColors.neonCyan
                          : AppColors.textPrimary,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _LevelBadge(level: entry.currentLevel, color: accentColor),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${entry.totalXp} XP',
                    style: AppTextStyles.monoSm.copyWith(
                      color: accentColor,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: _progressFraction(entry.totalXp, entry.xpToNextLevel),
            backgroundColor: AppColors.surface500.withAlpha(50),
            valueColor: AlwaysStoppedAnimation<Color>(
              accentColor.withAlpha(130),
            ),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  double _progressFraction(int totalXp, int xpToNextLevel) {
    final denominator = totalXp + xpToNextLevel;
    if (denominator <= 0) return 0;
    return (totalXp / denominator).clamp(0.0, 1.0);
  }
}

// ─── Column header row ────────────────────────────────────────────────────────

class _TableColumnHeader extends StatelessWidget {
  const _TableColumnHeader({required this.axis});
  final String axis;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.surface900,
        border: Border(bottom: BorderSide(color: AppColors.surface500)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '#',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'ATHLET',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              'LEVEL',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              'XP',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Leaderboard view (orchestrates states) ───────────────────────────────────

class _LeaderboardView extends ConsumerWidget {
  const _LeaderboardView({required this.axis});
  final String axis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gymLeaderboardProvider(axis));

    return async.when(
      skipLoadingOnReload: true,
      loading: () => Column(
        children: [
          _TableColumnHeader(axis: axis),
          Expanded(child: _LeaderboardLoading(axis: axis)),
        ],
      ),
      error: (e, _) => _LeaderboardError(message: e.toString()),
      data: (entries) => _LeaderboardLoaded(
        entries: entries,
        axis: axis,
        onRefresh: () async => ref.refresh(gymLeaderboardProvider(axis)),
      ),
    );
  }
}

// ─── Loading state ────────────────────────────────────────────────────────────

class _LeaderboardLoading extends StatelessWidget {
  const _LeaderboardLoading({required this.axis});
  final String axis;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 10,
          itemBuilder: (_, i) => _GhostRow(rank: i + 1),
        ),
        const Center(
          child: CircularProgressIndicator(
            color: AppColors.neonCyan,
            strokeWidth: 2,
          ),
        ),
      ],
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _LeaderboardError extends StatelessWidget {
  const _LeaderboardError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: AppTextStyles.h3.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loaded state (data + empty) ──────────────────────────────────────────────

class _LeaderboardLoaded extends StatelessWidget {
  const _LeaderboardLoaded({
    required this.entries,
    required this.axis,
    required this.onRefresh,
  });

  final List<LeaderboardEntry> entries;
  final String axis;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Column(
        children: [
          _TableColumnHeader(axis: axis),
          Expanded(child: _EmptyLeaderboardBody(axis: axis)),
        ],
      );
    }

    final currentUserEntry = entries.where((e) => e.isCurrentUser).firstOrNull;
    final showPodium = entries.length >= 3 && entries[0].totalXp > 0;
    final listEntries = showPodium ? entries.skip(3).toList() : entries;
    // items: [podium?] + [column header] + [N data rows] + [privacy]
    final extraItems = showPodium ? 3 : 2;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.neonCyan,
          backgroundColor: AppColors.surface800,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: listEntries.length + extraItems,
            itemBuilder: (_, i) {
              int idx = i;
              if (showPodium) {
                if (idx == 0) {
                  return _PodiumSection(top3: entries.take(3).toList());
                }
                idx--;
              }
              if (idx == 0) return _TableColumnHeader(axis: axis);
              idx--;
              if (idx == listEntries.length) return const _PrivacyFootnote();
              return _LeaderboardDataRow(entry: listEntries[idx]);
            },
          ),
        ),
        if (currentUserEntry != null)
          _StickyCurrentUserBar(entry: currentUserEntry),
      ],
    );
  }
}

// ─── Podium section (top 3) ───────────────────────────────────────────────────

class _PodiumSection extends StatelessWidget {
  const _PodiumSection({required this.top3});
  final List<LeaderboardEntry> top3;

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface800, AppColors.surface900],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PodiumSlot(
            entry: top3[1],
            rank: 2,
            medalColor: _silver,
            avatarRadius: 20,
            pedestalHeight: 58,
          ),
          _PodiumSlot(
            entry: top3[0],
            rank: 1,
            medalColor: _gold,
            avatarRadius: 26,
            pedestalHeight: 82,
          ),
          _PodiumSlot(
            entry: top3[2],
            rank: 3,
            medalColor: _bronze,
            avatarRadius: 20,
            pedestalHeight: 44,
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.rank,
    required this.medalColor,
    required this.avatarRadius,
    required this.pedestalHeight,
  });

  final LeaderboardEntry entry;
  final int rank;
  final Color medalColor;
  final double avatarRadius;
  final double pedestalHeight;

  @override
  Widget build(BuildContext context) {
    final isCurrent = entry.isCurrentUser;
    final color = isCurrent ? AppColors.neonCyan : medalColor;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (rank == 1)
            Icon(Icons.workspace_premium_rounded, color: color, size: 18)
          else
            const SizedBox(height: 18),
          const SizedBox(height: 4),
          _LeaderboardAvatar(
            username: entry.username,
            accentColor: color,
            size: avatarRadius * 2,
            avatarUrl: entry.avatarUrl,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '@${entry.username}',
              style: AppTextStyles.labelSm.copyWith(
                color: isCurrent ? AppColors.neonCyan : AppColors.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${entry.totalXp} XP',
            style: AppTextStyles.monoSm.copyWith(
              color: color.withAlpha(200),
              fontSize: 8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            height: pedestalHeight,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withAlpha(70), color.withAlpha(18)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border(
                top: BorderSide(color: color.withAlpha(150), width: 1.5),
                left: BorderSide(color: color.withAlpha(60)),
                right: BorderSide(color: color.withAlpha(60)),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(rank == 1 ? 45 : 20),
                  blurRadius: rank == 1 ? 22 : 12,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTextStyles.monoSm.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: rank == 1 ? 20 : 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty leaderboard: ghost rows + call-to-action overlay ──────────────────

class _EmptyLeaderboardBody extends StatelessWidget {
  const _EmptyLeaderboardBody({required this.axis});
  final String axis;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ghost rows as structural backdrop — convey leaderboard shape
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 10,
          itemBuilder: (_, i) => _GhostRow(rank: i + 1),
        ),
        // Frosted CTA card centred over the ghost rows
        Center(child: _EmptyCallToAction(axis: axis)),
      ],
    );
  }
}

class _EmptyCallToAction extends StatelessWidget {
  const _EmptyCallToAction({required this.axis});
  final String axis;

  @override
  Widget build(BuildContext context) {
    final isConsistency = axis == kAxisTrainingDay;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface800.withAlpha(242),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonCyan.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withAlpha(25),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonCyan.withAlpha(20),
              border: Border.all(color: AppColors.neonCyan.withAlpha(80)),
            ),
            child: Icon(
              isConsistency
                  ? Icons.emoji_events_outlined
                  : Icons.fitness_center_outlined,
              color: AppColors.neonCyan,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NOCH KEINE DATEN',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.neonCyan,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            isConsistency
                ? 'Trainiere und claim deinen ersten Platz auf dem Leaderboard!'
                : 'Benutze Geräte im Gym und steige in der Equipment-Rangliste auf!',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Actual data row ──────────────────────────────────────────────────────────

class _LeaderboardDataRow extends StatelessWidget {
  const _LeaderboardDataRow({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final rank = entry.rank;
    final isCurrent = entry.isCurrentUser;
    final hasXp = entry.totalXp > 0;
    final isTop3 = rank <= 3 && hasXp;

    // Rank-based medal colour — only for ranked (xp > 0) non-current rows
    final Color? medalColor = switch (rank) {
      1 when !isCurrent && hasXp => const Color(0xFFFFD700),
      2 when !isCurrent && hasXp => const Color(0xFFC0C0C0),
      3 when !isCurrent && hasXp => const Color(0xFFCD7F32),
      _ => null,
    };

    // Users with 0 XP (haven't synced yet) render dimly — they're on the
    // board, but clearly haven't earned a rank yet.
    final accentColor = isCurrent
        ? AppColors.neonCyan
        : hasXp
        ? (medalColor ?? AppColors.textSecondary)
        : AppColors.textDisabled;

    final bgColor = isCurrent
        ? AppColors.neonCyan.withAlpha(18)
        : (medalColor != null ? medalColor.withAlpha(10) : Colors.transparent);

    final leftBorderColor = isCurrent
        ? AppColors.neonCyan
        : (isTop3 ? (medalColor ?? Colors.transparent) : Colors.transparent);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(color: leftBorderColor, width: 3),
          bottom: BorderSide(color: AppColors.surface500.withAlpha(70)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                // ── Rank ─────────────────────────────────────────────────────
                SizedBox(
                  width: 44,
                  child: Text(
                    '#$rank',
                    style: AppTextStyles.monoSm.copyWith(
                      color: accentColor,
                      fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w400,
                      fontSize: isTop3 ? 14 : 13,
                    ),
                  ),
                ),
                // ── Avatar ────────────────────────────────────────────────────
                _LeaderboardAvatar(
                  username: entry.username,
                  accentColor: accentColor,
                  size: 32,
                  avatarUrl: entry.avatarUrl,
                ),
                const SizedBox(width: 10),
                // ── Username + optional "Noch kein Training" label ────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '@${entry.username}',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: isCurrent
                              ? AppColors.neonCyan
                              : hasXp
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!hasXp && !isCurrent)
                        Text(
                          'Noch kein Training',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textDisabled,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ── Level badge ───────────────────────────────────────────────
                _LevelBadge(level: entry.currentLevel, color: accentColor),
                const SizedBox(width: 8),
                // ── XP ────────────────────────────────────────────────────────
                SizedBox(
                  width: 72,
                  child: Text(
                    hasXp ? '${entry.totalXp} XP' : '—',
                    style: AppTextStyles.monoSm.copyWith(
                      color: accentColor,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // ── XP progress bar — hidden for 0-XP users ───────────────────────
          if (hasXp)
            LinearProgressIndicator(
              value: entry.xpProgressFraction,
              backgroundColor: AppColors.surface500.withAlpha(50),
              valueColor: AlwaysStoppedAnimation<Color>(
                accentColor.withAlpha(130),
              ),
              minHeight: 2,
            )
          else
            const SizedBox(height: 2),
        ],
      ),
    );
  }
}

// ─── Level badge ──────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.color});
  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        border: Border.all(color: color.withAlpha(90)),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        'LVL $level',
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Ghost row (empty-state placeholder) ──────────────────────────────────────

class _GhostRow extends StatelessWidget {
  const _GhostRow({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    // Rows fade out as rank increases to convey depth
    final opacity = (0.38 - (rank - 1) * 0.032).clamp(0.05, 0.38);

    return Opacity(
      opacity: opacity,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surface500)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 44,
              child: Text(
                '#$rank',
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ),
            // Avatar placeholder
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface600,
              ),
            ),
            const SizedBox(width: 10),
            // Username placeholder bar
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 11,
                    width: 100 + (rank % 3) * 20.0,
                    decoration: BoxDecoration(
                      color: AppColors.surface600,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Level badge placeholder
            Container(
              width: 58,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.surface600,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            // XP placeholder
            Container(
              width: 54,
              height: 11,
              decoration: BoxDecoration(
                color: AppColors.surface600,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Leaderboard avatar ───────────────────────────────────────────────────────

class _LeaderboardAvatar extends StatelessWidget {
  const _LeaderboardAvatar({
    required this.username,
    required this.accentColor,
    required this.size,
    this.avatarUrl,
  });

  final String username;
  final Color accentColor;
  final double size;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      username: username,
      radius: size / 2,
      avatarUrl: avatarUrl,
      borderColor: accentColor,
    );
  }
}

// ─── Sticky current-user bar ──────────────────────────────────────────────────

class _StickyCurrentUserBar extends StatelessWidget {
  const _StickyCurrentUserBar({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.surface900.withAlpha(240),
          border: Border(
            top: BorderSide(color: AppColors.neonCyan.withAlpha(100)),
            left: const BorderSide(color: AppColors.neonCyan, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              'DU  ',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.neonCyan,
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
            Text(
              '#${entry.rank}',
              style: AppTextStyles.monoSm.copyWith(
                color: AppColors.neonCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            _LeaderboardAvatar(
              username: entry.username,
              accentColor: AppColors.neonCyan,
              size: 28,
              avatarUrl: entry.avatarUrl,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '@${entry.username}',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.neonCyan),
              ),
            ),
            _LevelBadge(level: entry.currentLevel, color: AppColors.neonCyan),
            const SizedBox(width: 8),
            Text(
              '${entry.totalXp} XP',
              style: AppTextStyles.monoSm.copyWith(
                color: AppColors.neonCyan,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Privacy footnote ─────────────────────────────────────────────────────────

class _PrivacyFootnote extends StatelessWidget {
  const _PrivacyFootnote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 12,
            color: AppColors.textDisabled,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.l10n.rankingPrivacyNote,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textDisabled,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Find friends bottom sheet ────────────────────────────────────────────────

class _FindFriendsSheet extends ConsumerStatefulWidget {
  const _FindFriendsSheet();

  @override
  ConsumerState<_FindFriendsSheet> createState() => _FindFriendsSheetState();
}

class _FindFriendsSheetState extends ConsumerState<_FindFriendsSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(userSearchProvider(_query));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.findFriendsSheetTitle,
                  style: AppTextStyles.h3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: l10n.searchByUsername,
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surface700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.surface500),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.surface500),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: 16),
          if (_query.length >= 2)
            searchAsync.when(
              data: (users) => users.isEmpty
                  ? Text(
                      l10n.noUsersFound(_query),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : _SearchResults(users: users),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString()),
            )
          else
            Text(
              l10n.typeToSearch,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.users});
  final List<FriendUser> users;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sameGym = users.where((u) => u.sharesActiveGym).toList();
    final otherGyms = users.where((u) => !u.sharesActiveGym).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sameGym.isNotEmpty) ...[
          _SectionLabel(l10n.searchMyGymSection(sameGym.length)),
          const SizedBox(height: 8),
          ...sameGym.map((u) => _SearchResultTile(user: u)),
          const SizedBox(height: 10),
        ],
        if (otherGyms.isNotEmpty) ...[
          _SectionLabel(l10n.searchOtherGymsSection(otherGyms.length)),
          const SizedBox(height: 8),
          ...otherGyms.map((u) => _SearchResultTile(user: u)),
        ],
      ],
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  const _SearchResultTile({required this.user});
  final FriendUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(friendActionsProvider);
    final isLoading = actionsState.isLoading;
    final l10n = context.l10n;

    Widget trailing;
    switch (user.status) {
      case 'accepted':
        trailing = _Badge(label: l10n.friendStatusFriends);
        break;
      case 'pending_sent':
        trailing = _Badge(label: l10n.pendingBadge);
        break;
      case 'pending_received':
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: isLoading || user.friendshipId.isEmpty
                  ? null
                  : () => ref
                        .read(friendActionsProvider.notifier)
                        .declineRequest(user.friendshipId),
              icon: Icon(
                Icons.cancel_outlined,
                color: AppColors.textSecondary.withAlpha(190),
                size: 20,
              ),
              tooltip: l10n.declineTooltip,
            ),
            TextButton(
              onPressed: isLoading || user.friendshipId.isEmpty
                  ? null
                  : () => ref
                        .read(friendActionsProvider.notifier)
                        .acceptRequest(user.friendshipId),
              child: Text(
                l10n.acceptTooltip.toUpperCase(),
                style: AppTextStyles.labelMd.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
        break;
      default:
        trailing = TextButton(
          onPressed: isLoading
              ? null
              : () => ref
                    .read(friendActionsProvider.notifier)
                    .sendRequest(user.userId),
          child: Text(
            l10n.addFriendBtn,
            style: AppTextStyles.labelMd.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Row(
        children: [
          _Avatar(username: user.username, avatarUrl: user.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${user.username}', style: AppTextStyles.bodyMd),
                if (user.displayName != null)
                  Text(
                    user.displayName!,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                Text(
                  user.sharesActiveGym
                      ? l10n.friendInYourGym
                      : l10n.friendFromOtherGyms(user.sharedGymCount),
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ─── Shared avatar widget ─────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.username, this.avatarUrl});
  final String username;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return UserAvatar(username: username, radius: 20, avatarUrl: avatarUrl);
  }
}
