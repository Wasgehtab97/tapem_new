import '../entities/nutrition/nutrition_enums.dart';
import '../entities/nutrition/nutrition_weight.dart';

/// Aggregates raw daily weight data into chart buckets.
abstract final class NutritionWeightAggregationService {
  static const Map<WeightRange, int> _defaultBuckets = {
    WeightRange.week: 12,
    WeightRange.month: 12,
    WeightRange.quarter: 8,
    WeightRange.year: 5,
  };

  /// Compute aggregated buckets from [weightByDate].
  /// [weightByDate] maps yyyyMMdd dateKey → kg value.
  /// [referenceDate] is typically today.
  static List<NutritionWeightBucket> compute({
    required Map<String, double> weightByDate,
    required WeightRange range,
    required DateTime referenceDate,
    bool includeEmptyBuckets = false,
    int? bucketCount,
  }) {
    final count = bucketCount ?? _defaultBuckets[range]!;
    final buckets = _buildBucketFrames(range, referenceDate, count);
    final result = <NutritionWeightBucket>[];

    for (final frame in buckets) {
      final samples = <double>[];
      for (final entry in weightByDate.entries) {
        final d = _parseDate(entry.key);
        if (d == null) continue;
        if (!d.isBefore(frame.start) && !d.isAfter(frame.end)) {
          samples.add(entry.value);
        }
      }
      if (samples.isEmpty && !includeEmptyBuckets) continue;

      final avg = samples.isEmpty
          ? 0.0
          : double.parse(
              (samples.reduce((a, b) => a + b) / samples.length)
                  .toStringAsFixed(2),
            );
      result.add(
        NutritionWeightBucket(
          id: frame.id,
          label: frame.label,
          start: frame.start,
          end: frame.end,
          avgKg: avg,
          sampleCount: samples.length,
        ),
      );
    }
    return result;
  }

  /// Which calendar years must be loaded to cover [count] buckets of [range].
  static List<int> requiredYears({
    required WeightRange range,
    required DateTime referenceDate,
    int? bucketCount,
  }) {
    final count = bucketCount ?? _defaultBuckets[range]!;
    final frames = _buildBucketFrames(range, referenceDate, count);
    return frames
        .map((f) => f.start.year)
        .followedBy(frames.map((f) => f.end.year))
        .toSet()
        .toList();
  }

  static List<_BucketFrame> _buildBucketFrames(
    WeightRange range,
    DateTime ref,
    int count,
  ) {
    switch (range) {
      case WeightRange.week:
        return _isoWeekFrames(ref, count);
      case WeightRange.month:
        return _monthFrames(ref, count);
      case WeightRange.quarter:
        return _quarterFrames(ref, count);
      case WeightRange.year:
        return _yearFrames(ref, count);
    }
  }

  static List<_BucketFrame> _isoWeekFrames(DateTime ref, int count) {
    final frames = <_BucketFrame>[];
    var current = _isoWeekMonday(ref);
    for (var i = 0; i < count; i++) {
      final end = current.add(const Duration(days: 6));
      final weekNum = _isoWeekNumber(current);
      frames.add(_BucketFrame(
        id: 'week-${current.year}-$weekNum',
        label: 'KW$weekNum',
        start: current,
        end: end,
      ));
      current = current.subtract(const Duration(days: 7));
    }
    return frames.reversed.toList();
  }

  static List<_BucketFrame> _monthFrames(DateTime ref, int count) {
    final frames = <_BucketFrame>[];
    var y = ref.year;
    var m = ref.month;
    for (var i = 0; i < count; i++) {
      final start = DateTime(y, m, 1);
      final end = DateTime(y, m + 1, 0);
      frames.add(_BucketFrame(
        id: 'month-$y-$m',
        label: _shortMonth(m),
        start: start,
        end: end,
      ));
      m--;
      if (m == 0) {
        m = 12;
        y--;
      }
    }
    return frames.reversed.toList();
  }

  static List<_BucketFrame> _quarterFrames(DateTime ref, int count) {
    final frames = <_BucketFrame>[];
    var y = ref.year;
    var q = ((ref.month - 1) ~/ 3) + 1;
    for (var i = 0; i < count; i++) {
      final startMonth = (q - 1) * 3 + 1;
      final endMonth = startMonth + 2;
      final start = DateTime(y, startMonth, 1);
      final end = DateTime(y, endMonth + 1, 0);
      frames.add(_BucketFrame(
        id: 'q-$y-$q',
        label: 'Q$q/$y',
        start: start,
        end: end,
      ));
      q--;
      if (q == 0) {
        q = 4;
        y--;
      }
    }
    return frames.reversed.toList();
  }

  static List<_BucketFrame> _yearFrames(DateTime ref, int count) {
    final frames = <_BucketFrame>[];
    var y = ref.year;
    for (var i = 0; i < count; i++) {
      frames.add(_BucketFrame(
        id: 'year-$y',
        label: '$y',
        start: DateTime(y, 1, 1),
        end: DateTime(y, 12, 31),
      ));
      y--;
    }
    return frames.reversed.toList();
  }

  static DateTime _isoWeekMonday(DateTime d) {
    final weekday = d.weekday;
    return DateTime(d.year, d.month, d.day - (weekday - 1));
  }

  static int _isoWeekNumber(DateTime d) {
    final dayOfYear = int.parse(
      '${d.difference(DateTime(d.year, 1, 1)).inDays + 1}',
    );
    final wday = d.weekday;
    return ((dayOfYear - wday + 10) ~/ 7);
  }

  static String _shortMonth(int m) => const [
        '',
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
        'Dez'
      ][m];

  static DateTime? _parseDate(String dateKey) {
    if (dateKey.length != 8) return null;
    final y = int.tryParse(dateKey.substring(0, 4));
    final m = int.tryParse(dateKey.substring(4, 6));
    final d = int.tryParse(dateKey.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}

class _BucketFrame {
  const _BucketFrame({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
  });

  final String id;
  final String label;
  final DateTime start;
  final DateTime end;
}
