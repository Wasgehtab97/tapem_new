import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/domain/entities/nutrition/nutrition_enums.dart';
import 'package:tapem/domain/services/nutrition_weight_aggregation_service.dart';

void main() {
  group('NutritionWeightAggregationService', () {
    final reference = DateTime(2026, 3, 26); // A Wednesday

    test('returns empty list when no data', () {
      final buckets = NutritionWeightAggregationService.compute(
        weightByDate: {},
        range: WeightRange.month,
        referenceDate: reference,
      );
      expect(buckets, isEmpty);
    });

    test('includeEmptyBuckets=true includes all buckets', () {
      final buckets = NutritionWeightAggregationService.compute(
        weightByDate: {},
        range: WeightRange.month,
        referenceDate: reference,
        includeEmptyBuckets: true,
      );
      expect(buckets.length, 12); // default 12 months
    });

    test('computes correct average for a bucket', () {
      // March 2026: add 3 data points
      final data = {
        '20260301': 80.0,
        '20260315': 82.0,
        '20260326': 81.0,
      };
      final buckets = NutritionWeightAggregationService.compute(
        weightByDate: data,
        range: WeightRange.month,
        referenceDate: reference,
        includeEmptyBuckets: true,
      );
      final marchBucket = buckets.firstWhere(
        (b) => b.label == 'Mär',
        orElse: () => throw StateError('March bucket not found'),
      );
      expect(marchBucket.sampleCount, 3);
      expect(marchBucket.avgKg, closeTo(81.0, 0.1));
    });

    test('default week range has 12 buckets', () {
      final buckets = NutritionWeightAggregationService.compute(
        weightByDate: {'20260326': 80.0},
        range: WeightRange.week,
        referenceDate: reference,
        includeEmptyBuckets: true,
      );
      expect(buckets.length, 12);
    });

    test('year range has 5 buckets by default', () {
      final buckets = NutritionWeightAggregationService.compute(
        weightByDate: {'20260326': 80.0},
        range: WeightRange.year,
        referenceDate: reference,
        includeEmptyBuckets: true,
      );
      expect(buckets.length, 5);
    });

    test('requiredYears returns correct years for month range', () {
      final years = NutritionWeightAggregationService.requiredYears(
        range: WeightRange.month,
        referenceDate: DateTime(2026, 2, 15),
      );
      // 12 months back from Feb 2026 = Mar 2025 – Feb 2026 → years 2025, 2026
      expect(years, containsAll([2025, 2026]));
    });
  });
}
