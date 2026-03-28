import 'package:equatable/equatable.dart';
import 'nutrition_enums.dart';

/// Compact per-day data stored in the annual nutrition summary.
class NutritionDaySummary extends Equatable {
  const NutritionDaySummary({
    required this.status,
    required this.totalKcal,
    required this.goalKcal,
  });

  final NutritionStatus status;
  final int totalKcal;
  final int goalKcal;

  Map<String, dynamic> toJson() => {
        'status': status.value,
        'total_kcal': totalKcal,
        'goal_kcal': goalKcal,
      };

  factory NutritionDaySummary.fromJson(Map<String, dynamic> j) =>
      NutritionDaySummary(
        status: NutritionStatus.fromValue(j['status'] as String? ?? 'under'),
        totalKcal: (j['total_kcal'] as num?)?.toInt() ?? 0,
        goalKcal: (j['goal_kcal'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [status, totalKcal, goalKcal];
}

/// Full-year compact summary. `days` maps dateKey (yyyyMMdd) to day data.
class NutritionYearSummary extends Equatable {
  const NutritionYearSummary({
    required this.year,
    required this.days,
  });

  final int year;

  /// Key = yyyyMMdd dateKey.
  final Map<String, NutritionDaySummary> days;

  NutritionDaySummary? dayFor(String dateKey) => days[dateKey];

  Map<String, dynamic> toJson() => {
        'year': year,
        'days': days.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory NutritionYearSummary.fromJson(Map<String, dynamic> j) {
    final rawDays = j['days'] as Map<String, dynamic>? ?? {};
    return NutritionYearSummary(
      year: (j['year'] as num).toInt(),
      days: rawDays.map(
        (k, v) => MapEntry(k, NutritionDaySummary.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }

  @override
  List<Object?> get props => [year];
}
