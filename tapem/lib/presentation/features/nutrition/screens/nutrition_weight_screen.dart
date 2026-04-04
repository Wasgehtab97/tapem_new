import 'dart:async' show unawaited;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/nutrition/nutrition_enums.dart';
import '../../../../domain/entities/nutrition/nutrition_weight.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/nutrition_weight_provider.dart';
import '../../../widgets/common/tapem_skeleton.dart';

class NutritionWeightScreen extends HookConsumerWidget {
  const NutritionWeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.id ?? '';

    useEffect(() {
      if (uid.isNotEmpty) {
        unawaited(
          Future.microtask(
            () => ref.read(nutritionWeightNotifierProvider.notifier).load(uid),
          ),
        );
      }
      return null;
    }, [uid]);

    final state = ref.watch(nutritionWeightNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface900,
      appBar: AppBar(
        backgroundColor: AppColors.surface900,
        surfaceTintColor: Colors.transparent,
        title: Text('GEWICHT', style: AppTextStyles.h3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.neonCyan,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.textOnAction,
        icon: const Icon(Icons.add),
        label: Text(
          'GEWICHT EINTRAGEN',
          style: AppTextStyles.buttonMd.copyWith(color: AppColors.textOnAction),
        ),
        onPressed: () => _showAddWeightSheet(context, ref, uid),
      ),
      body: state.isLoading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TapemSkeleton.card(height: 200),
                const SizedBox(height: 16),
                TapemSkeleton.listTiles(count: 4),
              ],
            )
          : state.error != null
          ? _ErrorState(
              error: state.error!,
              onRetry: () =>
                  ref.read(nutritionWeightNotifierProvider.notifier).load(uid),
            )
          : _WeightBody(state: state, uid: uid),
    );
  }

  void _showAddWeightSheet(BuildContext context, WidgetRef ref, String uid) {
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface800,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _AddWeightSheet(
          currentKg: ref.read(nutritionWeightNotifierProvider).todayKg,
          onSave: (kg) async {
            Navigator.of(context).pop();
            await ref
                .read(nutritionWeightNotifierProvider.notifier)
                .saveWeight(uid, kg, DateTime.now());
          },
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _WeightBody extends HookConsumerWidget {
  const _WeightBody({required this.state, required this.uid});

  final NutritionWeightState state;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasData = state.chartBuckets.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Current weight display ───────────────────────────────────
        _CurrentWeightCard(state: state),
        const Gap(20),

        // ── Range tabs ───────────────────────────────────────────────
        _RangeTabs(
          current: state.range,
          onChanged: (r) {
            unawaited(
              ref
                  .read(nutritionWeightNotifierProvider.notifier)
                  .changeRange(uid, r),
            );
          },
        ),
        const Gap(16),

        // ── Chart ────────────────────────────────────────────────────
        if (!hasData)
          _EmptyChart()
        else
          _WeightChart(buckets: state.chartBuckets),
        const Gap(24),

        // ── History hint ─────────────────────────────────────────────
        if (hasData)
          const Center(
            child: Text(
              'Tippe auf einen Punkt für Details.',
              style: AppTextStyles.bodySm,
            ),
          ),
      ],
    );
  }
}

// ─── Current weight card ──────────────────────────────────────────────────────

class _CurrentWeightCard extends StatelessWidget {
  const _CurrentWeightCard({required this.state});

  final NutritionWeightState state;

  @override
  Widget build(BuildContext context) {
    final kg = state.todayKg ?? state.meta?.kg;
    final dateKey = state.meta?.dateKey ?? '';
    final dateStr = dateKey.length == 8
        ? '${dateKey.substring(6, 8)}.${dateKey.substring(4, 6)}.${dateKey.substring(0, 4)}'
        : '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.neonCyanGlow.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AKTUELLES GEWICHT',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Gap(8),
              kg != null
                  ? Text(
                      '${kg.toStringAsFixed(1)} kg',
                      style: AppTextStyles.displayMd.copyWith(
                        color: AppColors.neonCyan,
                      ),
                    )
                  : Text(
                      '— kg',
                      style: AppTextStyles.displayMd.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
              const Gap(4),
              Text(
                kg != null ? 'Stand: $dateStr' : 'Noch kein Eintrag',
                style: AppTextStyles.bodySm,
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.neonCyanGlow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monitor_weight_outlined,
              color: AppColors.neonCyan,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Range tabs ───────────────────────────────────────────────────────────────

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.current, required this.onChanged});

  final WeightRange current;
  final void Function(WeightRange) onChanged;

  static const _labels = {
    WeightRange.week: 'Woche',
    WeightRange.month: 'Monat',
    WeightRange.quarter: 'Quartal',
    WeightRange.year: 'Jahr',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface500),
      ),
      child: Row(
        children: WeightRange.values.map((r) {
          final isSelected = r == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neonCyan : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[r]!,
                  style: AppTextStyles.labelMd.copyWith(
                    color: isSelected
                        ? AppColors.textOnAction
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Weight chart ─────────────────────────────────────────────────────────────

class _WeightChart extends HookWidget {
  const _WeightChart({required this.buckets});

  final List<NutritionWeightBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final touchedIndex = useState<int>(-1);

    if (buckets.isEmpty) return _EmptyChart();

    final spots = buckets.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.avgKg);
    }).toList();

    final allKg = buckets.map((b) => b.avgKg).toList();
    final minY = (allKg.reduce((a, b) => a < b ? a : b) - 2)
        .floorToDouble()
        .clamp(0.0, double.infinity);
    final maxY = (allKg.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface500),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.surface500, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toStringAsFixed(0)} kg',
                  style: AppTextStyles.labelSm,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _labelInterval(buckets.length),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      buckets[i].label,
                      style: AppTextStyles.labelSm,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchCallback: (event, response) {
              if (response?.lineBarSpots != null &&
                  response!.lineBarSpots!.isNotEmpty) {
                touchedIndex.value = response.lineBarSpots!.first.spotIndex;
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface700,
              getTooltipItems: (spots) => spots.map((s) {
                final b = buckets[s.spotIndex];
                return LineTooltipItem(
                  '${b.avgKg.toStringAsFixed(1)} kg\n${b.label}',
                  AppTextStyles.labelMd.copyWith(color: AppColors.neonCyan),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.neonCyan,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, index) => FlDotCirclePainter(
                  radius: index == touchedIndex.value ? 5 : 3,
                  color: AppColors.neonCyan,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.neonCyan.withValues(alpha: 0.2),
                    AppColors.neonCyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _labelInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    return (count / 6).ceilToDouble();
  }
}

// ─── Empty chart ──────────────────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface500),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, color: AppColors.textDisabled, size: 40),
            Gap(10),
            Text('Noch keine Gewichtsdaten.', style: AppTextStyles.bodySm),
            Gap(4),
            Text(
              'Füge dein erstes Gewicht hinzu.',
              style: AppTextStyles.bodySm,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add weight bottom sheet ──────────────────────────────────────────────────

class _AddWeightSheet extends HookWidget {
  const _AddWeightSheet({this.currentKg, required this.onSave});

  final double? currentKg;
  final void Function(double) onSave;

  @override
  Widget build(BuildContext context) {
    final kgCtrl = useTextEditingController(
      text: currentKg != null ? currentKg!.toStringAsFixed(1) : '',
    );
    final errorMsg = useState<String?>(null);
    final isSaving = useState(false);

    void handleSave() {
      errorMsg.value = null;
      final raw = kgCtrl.text.trim().replaceAll(',', '.');
      final kg = double.tryParse(raw);
      if (kg == null) {
        errorMsg.value = 'Bitte eine gültige Zahl eingeben.';
        return;
      }
      if (kg < 20 || kg > 400) {
        errorMsg.value = 'Gewicht muss zwischen 20 und 400 kg liegen.';
        return;
      }
      isSaving.value = true;
      onSave(kg);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(16),
          Text('GEWICHT EINTRAGEN', style: AppTextStyles.h3),
          const Gap(4),
          const Text('Heutiges Gewicht in kg', style: AppTextStyles.bodySm),
          const Gap(16),
          TextField(
            controller: kgCtrl,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: AppTextStyles.displayMd.copyWith(color: AppColors.neonCyan),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '70.0',
              hintStyle: AppTextStyles.displayMd.copyWith(
                color: AppColors.textDisabled,
              ),
              suffixText: 'kg',
              suffixStyle: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
              errorText: errorMsg.value,
              filled: true,
              fillColor: AppColors.surface700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.surface500),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.surface500),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.neonCyan),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
            onSubmitted: (_) => handleSave(),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving.value ? null : handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: AppColors.textOnAction,
                disabledBackgroundColor: AppColors.neonCyanDim,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSaving.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnAction,
                      ),
                    )
                  : const Text('SPEICHERN', style: AppTextStyles.buttonLg),
            ),
          ),
          const Gap(8),
        ],
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const Gap(12),
            Text(
              'Fehler beim Laden.',
              style: AppTextStyles.h3.copyWith(color: AppColors.error),
            ),
            const Gap(8),
            Text(
              error,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'ERNEUT VERSUCHEN',
                style: AppTextStyles.buttonMd.copyWith(
                  color: AppColors.neonCyan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
