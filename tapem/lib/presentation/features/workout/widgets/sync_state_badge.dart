import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Displays the current sync state to the user.
/// Spec: user sees local_saved / sync_pending / sync_confirmed / sync_failed.
class SyncStateBadge extends ConsumerWidget {
  const SyncStateBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncNotifierProvider);

    final (icon, label, color) = switch (sync.state) {
      SyncServiceState.idle when sync.pendingCount == 0 => (
        Icons.cloud_done_outlined,
        'SYNCED',
        AppColors.syncConfirmed,
      ),
      SyncServiceState.idle => (
        Icons.cloud_queue_outlined,
        '${sync.pendingCount} PENDING',
        AppColors.syncPending,
      ),
      SyncServiceState.syncing => (
        Icons.sync,
        'SYNCING...',
        AppColors.syncPending,
      ),
      SyncServiceState.error => (
        Icons.cloud_off_outlined,
        'SYNC FAILED',
        AppColors.syncFailed,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 10),
        ),
      ],
    );
  }
}
