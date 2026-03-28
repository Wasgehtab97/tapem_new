import 'package:equatable/equatable.dart';

/// A user's body weight logged on a specific date.
class NutritionWeightLog extends Equatable {
  const NutritionWeightLog({
    required this.dateKey,
    required this.kg,
    required this.updatedAt,
    this.source,
  });

  final String dateKey;

  /// Clamped to 20–400 kg.
  final double kg;
  final DateTime updatedAt;
  final String? source;

  Map<String, dynamic> toJson() => {
        'date_key': dateKey,
        'kg': kg,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        if (source != null) 'source': source,
      };

  factory NutritionWeightLog.fromJson(Map<String, dynamic> j) =>
      NutritionWeightLog(
        dateKey: j['date_key'] as String,
        kg: (j['kg'] as num).toDouble(),
        updatedAt: DateTime.parse(j['updated_at'] as String).toLocal(),
        source: j['source'] as String?,
      );

  @override
  List<Object?> get props => [dateKey];
}

/// Pointer to the most recent weight entry (updated only forward in time).
class NutritionWeightMeta extends Equatable {
  const NutritionWeightMeta({
    required this.kg,
    required this.dateKey,
    required this.updatedAt,
  });

  final double kg;
  final String dateKey;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'kg': kg,
        'date_key': dateKey,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory NutritionWeightMeta.fromJson(Map<String, dynamic> j) =>
      NutritionWeightMeta(
        kg: (j['kg'] as num).toDouble(),
        dateKey: j['date_key'] as String,
        updatedAt: DateTime.parse(j['updated_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [dateKey];
}

/// One aggregated bucket for a weight chart (average over a time period).
class NutritionWeightBucket extends Equatable {
  const NutritionWeightBucket({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    required this.avgKg,
    required this.sampleCount,
  });

  final String id;
  final String label;
  final DateTime start;
  final DateTime end;
  final double avgKg;
  final int sampleCount;

  @override
  List<Object?> get props => [id];
}

/// Compact per-day weight snapshot stored in the year summary map.
class NutritionWeightDayEntry extends Equatable {
  const NutritionWeightDayEntry({
    required this.kg,
    required this.updatedAt,
  });

  final double kg;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'kg': kg,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory NutritionWeightDayEntry.fromJson(Map<String, dynamic> j) =>
      NutritionWeightDayEntry(
        kg: (j['kg'] as num).toDouble(),
        updatedAt: DateTime.parse(j['updated_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [kg, updatedAt];
}
