import 'package:equatable/equatable.dart';
import 'nutrition_entry.dart';
import 'nutrition_enums.dart';

/// All food entries for a single day, with pre-computed totals and status.
class NutritionLog extends Equatable {
  const NutritionLog({
    required this.dateKey,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.entries,
    required this.status,
    required this.updatedAt,
  });

  final String dateKey;
  final int totalKcal;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;

  /// Max 50 entries per day.
  final List<NutritionEntry> entries;
  final NutritionStatus status;
  final DateTime updatedAt;

  NutritionLog copyWith({
    String? dateKey,
    int? totalKcal,
    int? totalProtein,
    int? totalCarbs,
    int? totalFat,
    List<NutritionEntry>? entries,
    NutritionStatus? status,
    DateTime? updatedAt,
  }) =>
      NutritionLog(
        dateKey: dateKey ?? this.dateKey,
        totalKcal: totalKcal ?? this.totalKcal,
        totalProtein: totalProtein ?? this.totalProtein,
        totalCarbs: totalCarbs ?? this.totalCarbs,
        totalFat: totalFat ?? this.totalFat,
        entries: entries ?? this.entries,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'date_key': dateKey,
        'total_kcal': totalKcal,
        'total_protein': totalProtein,
        'total_carbs': totalCarbs,
        'total_fat': totalFat,
        'entries': entries.map((e) => e.toJson()).toList(),
        'status': status.value,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory NutritionLog.fromJson(Map<String, dynamic> j) {
    final rawEntries = j['entries'];
    final List<NutritionEntry> entries;
    if (rawEntries is List) {
      entries = rawEntries
          .map((e) => NutritionEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      entries = [];
    }
    return NutritionLog(
      dateKey: j['date_key'] as String,
      totalKcal: (j['total_kcal'] as num).toInt(),
      totalProtein: (j['total_protein'] as num).toInt(),
      totalCarbs: (j['total_carbs'] as num).toInt(),
      totalFat: (j['total_fat'] as num).toInt(),
      entries: entries,
      status: NutritionStatus.fromValue(j['status'] as String? ?? 'under'),
      updatedAt: DateTime.parse(j['updated_at'] as String).toLocal(),
    );
  }

  /// Recompute totals by folding all entries.
  static NutritionLog recompute({
    required String dateKey,
    required List<NutritionEntry> entries,
    required NutritionStatus status,
  }) {
    var kcal = 0, protein = 0, carbs = 0, fat = 0;
    for (final e in entries) {
      kcal += e.kcal;
      protein += e.protein;
      carbs += e.carbs;
      fat += e.fat;
    }
    return NutritionLog(
      dateKey: dateKey,
      totalKcal: kcal,
      totalProtein: protein,
      totalCarbs: carbs,
      totalFat: fat,
      entries: entries,
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [dateKey];
}
