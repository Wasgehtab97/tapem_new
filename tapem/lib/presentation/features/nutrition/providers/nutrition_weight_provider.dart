import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/logger.dart';
import '../../../../../data/nutrition/nutrition_repository.dart';
import '../../../../../domain/entities/nutrition/nutrition_enums.dart';
import '../../../../../domain/entities/nutrition/nutrition_weight.dart';
import '../../../../../domain/services/nutrition_weight_aggregation_service.dart';
import '../../../../../domain/utils/nutrition_date_utils.dart';
import 'nutrition_providers.dart';

// ─── State ─────────────────────────────────────────────────────────────────────

class NutritionWeightState {
  const NutritionWeightState({
    this.meta,
    this.todayKg,
    this.selectedDateKey,
    this.selectedKg,
    this.chartBuckets = const [],
    this.range = WeightRange.month,
    this.isLoading = false,
    this.error,
  });

  final NutritionWeightMeta? meta;
  final double? todayKg;
  final String? selectedDateKey;
  final double? selectedKg;
  final List<NutritionWeightBucket> chartBuckets;
  final WeightRange range;
  final bool isLoading;
  final String? error;

  NutritionWeightState copyWith({
    NutritionWeightMeta? meta,
    double? todayKg,
    String? selectedDateKey,
    double? selectedKg,
    List<NutritionWeightBucket>? chartBuckets,
    WeightRange? range,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      NutritionWeightState(
        meta: meta ?? this.meta,
        todayKg: todayKg ?? this.todayKg,
        selectedDateKey: selectedDateKey ?? this.selectedDateKey,
        selectedKg: selectedKg ?? this.selectedKg,
        chartBuckets: chartBuckets ?? this.chartBuckets,
        range: range ?? this.range,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

// ─── Notifier ──────────────────────────────────────────────────────────────────

class NutritionWeightNotifier extends StateNotifier<NutritionWeightState> {
  NutritionWeightNotifier(this._repo) : super(const NutritionWeightState());

  final NutritionRepository _repo;
  String? _uid;

  /// Per-year cache: year → {dateKey → kg}
  final Map<int, Map<String, double>> _yearCache = {};

  Future<void> load(String uid) async {
    if (_uid == uid && state.meta != null) return;
    _uid = uid;
    _yearCache.clear();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final meta = await _repo.loadWeightMeta(uid);
      final today = NutritionDateUtils.today();
      await _ensureYearsLoaded(uid, state.range, DateTime.now());

      final merged = _mergedWeightMap();
      final todayKg = merged[today];
      final chartBuckets = NutritionWeightAggregationService.compute(
        weightByDate: merged,
        range: state.range,
        referenceDate: DateTime.now(),
      );

      state = state.copyWith(
        meta: meta,
        todayKg: todayKg ?? meta?.kg,
        selectedDateKey: today,
        selectedKg: todayKg ?? meta?.kg,
        chartBuckets: chartBuckets,
        isLoading: false,
      );
    } catch (e) {
      state = NutritionWeightState(
        isLoading: false,
        error: e.toString(),
      );
      AppLogger.e('NutritionWeightNotifier.load failed', e);
    }
  }

  Future<void> changeRange(String uid, WeightRange range) async {
    _uid = uid;
    state = state.copyWith(range: range, isLoading: true);
    await _ensureYearsLoaded(uid, range, DateTime.now());
    _recomputeBuckets();
  }

  Future<void> saveWeight(String uid, double kg, DateTime date) async {
    final clamped = kg.clamp(20.0, 400.0);
    final rounded = double.parse(clamped.toStringAsFixed(2));
    final dateKey = NutritionDateUtils.toDateKey(date);

    await _repo.saveWeight(uid: uid, dateKey: dateKey, kg: rounded);

    // Update local cache
    final year = NutritionDateUtils.yearFromKey(dateKey);
    _yearCache.putIfAbsent(year, () => {});
    _yearCache[year]![dateKey] = rounded;

    // Update meta if this is the most recent date
    final meta = state.meta;
    final newMeta = (meta == null || dateKey.compareTo(meta.dateKey) >= 0)
        ? NutritionWeightMeta(
            kg: rounded,
            dateKey: dateKey,
            updatedAt: DateTime.now(),
          )
        : meta;

    final today = NutritionDateUtils.today();
    final merged = _mergedWeightMap();
    final chartBuckets = NutritionWeightAggregationService.compute(
      weightByDate: merged,
      range: state.range,
      referenceDate: DateTime.now(),
    );

    state = state.copyWith(
      meta: newMeta,
      todayKg: merged[today] ?? newMeta.kg,
      selectedDateKey: dateKey,
      selectedKg: rounded,
      chartBuckets: chartBuckets,
    );
  }

  void selectDate(String dateKey) {
    final merged = _mergedWeightMap();
    state = state.copyWith(
      selectedDateKey: dateKey,
      selectedKg: merged[dateKey],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _ensureYearsLoaded(
    String uid,
    WeightRange range,
    DateTime reference,
  ) async {
    final needed = NutritionWeightAggregationService.requiredYears(
      range: range,
      referenceDate: reference,
    );
    for (final year in needed) {
      if (!_yearCache.containsKey(year)) {
        final data = await _repo.loadWeightYear(uid, year);
        _yearCache[year] = data;
      }
    }
  }

  Map<String, double> _mergedWeightMap() {
    final result = <String, double>{};
    for (final entry in _yearCache.entries) {
      result.addAll(entry.value);
    }
    return result;
  }

  void _recomputeBuckets() {
    final merged = _mergedWeightMap();
    final today = NutritionDateUtils.today();
    final chartBuckets = NutritionWeightAggregationService.compute(
      weightByDate: merged,
      range: state.range,
      referenceDate: DateTime.now(),
    );
    state = state.copyWith(
      todayKg: merged[today] ?? state.meta?.kg,
      chartBuckets: chartBuckets,
      isLoading: false,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final nutritionWeightNotifierProvider =
    StateNotifierProvider<NutritionWeightNotifier, NutritionWeightState>((ref) {
  return NutritionWeightNotifier(ref.watch(nutritionRepositoryProvider));
});
