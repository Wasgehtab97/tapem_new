import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../features/workout/providers/equipment_detail_provider.dart';

class E1rmProgressChart extends StatelessWidget {
  const E1rmProgressChart({
    super.key,
    required this.points,
    required this.emptyMessage,
  });

  final List<E1rmDataPoint> points;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        key: const Key('e1rm-progress-empty'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface700,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surface500),
        ),
        child: Text(
          emptyMessage,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final minY = points.fold(
      double.infinity,
      (m, p) => p.e1rm < m ? p.e1rm : m,
    );
    final maxY = points.fold(0.0, (m, p) => p.e1rm > m ? p.e1rm : m);
    final yPad = max((maxY - minY) * 0.15, 5.0);
    final yMin = (minY - yPad).clamp(0.0, double.infinity);
    final yMax = maxY + yPad;

    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.e1rm))
        .toList();
    final maxX = spots.length <= 1 ? 1.0 : (spots.length - 1).toDouble();

    final labelInterval = max(1.0, (spots.length / 4).floorToDouble());

    return Container(
      key: const Key('e1rm-progress-chart'),
      height: 190,
      padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.surface700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: yMin,
          maxY: yMax,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.surface500, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${v.toInt()}',
                    style: AppTextStyles.monoSm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: labelInterval,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final parts = points[idx].sessionDayAnchor.split('-');
                  return Text(
                    '${parts[2]}.${parts[1]}',
                    style: AppTextStyles.monoSm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface800,
              tooltipBorder: const BorderSide(
                color: AppColors.neonCyan,
                width: 0.5,
              ),
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                final p = points[s.spotIndex];
                final wStr = p.weightKg == p.weightKg.truncateToDouble()
                    ? p.weightKg.toInt().toString()
                    : p.weightKg.toStringAsFixed(1);
                return LineTooltipItem(
                  '${p.e1rm.toStringAsFixed(1)} kg\n${p.reps} × ${wStr}kg',
                  AppTextStyles.monoSm.copyWith(
                    color: AppColors.neonCyan,
                    fontSize: 11,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: spots.length > 1,
              curveSmoothness: 0.35,
              color: AppColors.neonCyan,
              barWidth: 2,
              dotData: FlDotData(
                show: spots.length <= 30,
                getDotPainter: (spot, pct, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.neonCyan,
                  strokeWidth: 1.5,
                  strokeColor: AppColors.surface800,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.neonCyan.withAlpha(50),
                    AppColors.neonCyan.withAlpha(0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
