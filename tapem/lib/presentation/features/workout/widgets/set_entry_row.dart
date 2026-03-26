import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/datasources/local/app_database.dart';

/// Displays a single logged set in the active workout and history views.
class SetEntryRow extends StatelessWidget {
  const SetEntryRow({super.key, required this.set, this.isCardio = false});

  final LocalSetEntry set;
  final bool isCardio;

  @override
  Widget build(BuildContext context) {
    final isPending =
        set.syncStatus == 'sync_pending' || set.syncStatus == 'local_saved';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 32,
            child: Text(
              '${set.setNumber}',
              style: AppTextStyles.monoSm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),

          if (isCardio) ...[
            // Duration
            Text(
              _formatDuration(set.durationSeconds ?? 0),
              style: AppTextStyles.monoSm.copyWith(
                color: AppColors.neonYellow,
                fontSize: 15,
              ),
            ),
            if (set.distanceMeters != null) ...[
              const SizedBox(width: 8),
              Text(
                '${(set.distanceMeters! / 1000).toStringAsFixed(2)} km',
                style: AppTextStyles.monoSm,
              ),
            ],
          ] else ...[
            // Weight
            SizedBox(
              width: 72,
              child: Text(
                set.weightKg != null
                    ? set.weightKg!.toStringAsFixed(
                        set.weightKg! % 1 == 0 ? 0 : 1,
                      )
                    : '—',
                style: AppTextStyles.monoSm,
                textAlign: TextAlign.center,
              ),
            ),
            // Reps
            SizedBox(
              width: 72,
              child: Text(
                set.reps != null ? '${set.reps}' : '—',
                style: AppTextStyles.monoSm,
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Sync indicator
          SizedBox(
            width: 8,
            child: isPending
                ? Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.syncPending,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
