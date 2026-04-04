import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Compact year heatmap widget.
///
/// Preview mode (default): fills available width with no internal padding —
/// the caller is responsible for horizontal spacing. All 53 weeks are rendered
/// at whatever cell size fits.
///
/// Dialog mode (`isDialog: true`): 24 px cells, horizontally scrollable,
/// auto-scrolls to the current week on mount.
class TrainingHeatmap extends StatelessWidget {
  const TrainingHeatmap({
    super.key,
    required this.year,
    required this.trainingDays,
    this.isDialog = false,
    this.onCellTap,
    this.scrollController,
  });

  final int year;
  final Set<String> trainingDays; // 'yyyy-MM-dd'
  final bool isDialog;
  final void Function(DateTime)? onCellTap;
  final ScrollController? scrollController;

  // ─── Constants ────────────────────────────────────────────────────────────

  static const int _totalWeeks = 53;

  /// 1-char month initials for compact preview (ShareTechMono — unambiguous
  /// at tiny sizes because spatial position disambiguates repeated letters).
  static const _compactMonths = [
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];

  /// 3-char German abbreviations for the scrollable dialog.
  static const _dialogMonths = [
    'Jan',
    'Feb',
    'Mär',
    'Apr',
    'Mai',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Okt',
    'Nov',
    'Dez',
  ];

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final today = DateTime.now();

    final jan1 = DateTime(year, 1, 1);
    // 0 = Monday offset for the first column
    final startOffset = (jan1.weekday - 1) % 7;

    return Semantics(
      label: '${trainingDays.length} Trainingstage in $year',
      child: LayoutBuilder(
      builder: (context, constraints) {
        // Dialog uses fixed 24 px cells; preview fills available width.
        const dialogCellSize = 24.0;
        const dialogCellMargin = 2.0;
        const previewCellMargin = 1.0;

        final cellSize = isDialog
            ? dialogCellSize
            : ((constraints.maxWidth / _totalWeeks) - previewCellMargin * 2)
                  .clamp(1.0, 18.0);
        final cellMargin = isDialog ? dialogCellMargin : previewCellMargin;
        final weekWidth = cellSize + cellMargin * 2;

        // ── Grid ────────────────────────────────────────────────────────────

        final grid = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_totalWeeks, (weekIdx) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (dayOfWeek) {
                final dayOffset = weekIdx * 7 + dayOfWeek - startOffset;
                final date = jan1.add(Duration(days: dayOffset));

                // Cells outside the current year are invisible spacers.
                if (date.year != year) {
                  return SizedBox(width: weekWidth, height: weekWidth);
                }

                final key = _dateKey(date);
                final isTraining = trainingDays.contains(key);
                final isToday = _isSameDay(date, today);

                return GestureDetector(
                  onTap: onCellTap != null ? () => onCellTap!(date) : null,
                  child: Container(
                    margin: EdgeInsets.all(cellMargin),
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: isTraining
                          ? accent
                          : AppColors.surface600.withAlpha(80),
                      borderRadius: BorderRadius.circular(
                        cellSize <= 5 ? 1 : 2,
                      ),
                      border: isToday
                          ? Border.all(color: AppColors.neonCyan, width: 1.5)
                          : !isTraining
                          ? Border.all(
                              color: AppColors.surface500.withAlpha(40),
                              width: 0.5,
                            )
                          : null,
                      boxShadow: isTraining
                          ? [
                              BoxShadow(
                                color: accent.withAlpha(60),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isDialog && cellSize >= 16 && isTraining
                        ? Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: cellSize * 0.45,
                                color: AppColors.textOnAction,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              }),
            );
          }),
        );

        // ── Month label row ─────────────────────────────────────────────────

        final monthRow = _MonthLabelRow(
          year: year,
          startOffset: startOffset,
          weekWidth: weekWidth,
          totalWeeks: _totalWeeks,
          labels: isDialog ? _dialogMonths : _compactMonths,
          fontSize: isDialog ? 10.0 : 8.5,
          rowHeight: isDialog ? 18.0 : 13.0,
        );

        // ── Assemble ────────────────────────────────────────────────────────

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [monthRow, const SizedBox(height: 4), grid],
        );

        if (isDialog) {
          return SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: content,
          );
        }

        // Preview: no extra padding — the parent card handles all spacing.
        return content;
      },
      ), // LayoutBuilder
    ); // Semantics
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Month label row ──────────────────────────────────────────────────────────
//
// Uses Stack + Positioned to place each label at the exact pixel offset of its
// month's first column — the only correct approach for a variable-width grid.
// The previous Transform.translate-inside-SizedBox approach caused labels to
// render outside their layout boxes and appear clipped or overlapping.

class _MonthLabelRow extends StatelessWidget {
  const _MonthLabelRow({
    required this.year,
    required this.startOffset,
    required this.weekWidth,
    required this.totalWeeks,
    required this.labels,
    required this.fontSize,
    required this.rowHeight,
  });

  final int year;
  final int startOffset;
  final double weekWidth;
  final int totalWeeks;
  final List<String> labels;
  final double fontSize;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final totalWidth = totalWeeks * weekWidth;
    final jan1 = DateTime(year, 1, 1);

    final children = <Widget>[];
    for (var m = 1; m <= 12; m++) {
      final firstOfMonth = DateTime(year, m, 1);
      final dayOfYear = firstOfMonth.difference(jan1).inDays;
      final weekIdx = (dayOfYear + startOffset) ~/ 7;
      final left = weekIdx * weekWidth;

      if (left >= totalWidth) continue;

      children.add(
        Positioned(
          left: left,
          top: 0,
          bottom: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              labels[m - 1],
              style: AppTextStyles.monoSm.copyWith(
                fontSize: fontSize,
                color: AppColors.textSecondary,
                height: 1.0,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: totalWidth,
      height: rowHeight,
      child: Stack(children: children),
    );
  }
}

// ─── Dialog wrapper ───────────────────────────────────────────────────────────

/// Full-year scrollable heatmap dialog, auto-scrolled to the current week.
class TrainingHeatmapDialog extends StatefulWidget {
  const TrainingHeatmapDialog({
    super.key,
    required this.year,
    required this.trainingDays,
  });

  final int year;
  final Set<String> trainingDays;

  @override
  State<TrainingHeatmapDialog> createState() => _TrainingHeatmapDialogState();
}

class _TrainingHeatmapDialogState extends State<TrainingHeatmapDialog> {
  final _scrollController = ScrollController();

  // Must match TrainingHeatmap's dialog constants exactly.
  static const double _cellSize = 24.0;
  static const double _cellMargin = 2.0;
  static const double _weekWidth = _cellSize + _cellMargin * 2; // 28 px
  static const double _horizontalPadding = 16.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrentWeek());
  }

  void _jumpToCurrentWeek() {
    if (!_scrollController.hasClients) return;
    final today = DateTime.now();
    if (today.year != widget.year) return;

    final jan1 = DateTime(widget.year, 1, 1);
    final startOffset = (jan1.weekday - 1) % 7;
    final dayOfYear = today.difference(jan1).inDays;
    final weekIdx = (dayOfYear + startOffset) ~/ 7;

    final weekLeft = _horizontalPadding + weekIdx * _weekWidth;
    final viewport = _scrollController.position.viewportDimension;
    final target = (weekLeft - viewport / 2 + _weekWidth / 2).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.jumpTo(target);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'TRAININGSKALENDER ${widget.year}',
              style: AppTextStyles.labelMd,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        height: 220,
        width: double.maxFinite,
        child: TrainingHeatmap(
          year: widget.year,
          trainingDays: widget.trainingDays,
          isDialog: true,
          scrollController: _scrollController,
        ),
      ),
    );
  }
}
