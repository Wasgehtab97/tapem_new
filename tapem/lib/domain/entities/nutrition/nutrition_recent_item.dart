import 'package:equatable/equatable.dart';

/// Snapshot of a recently-used product, stored in SharedPreferences.
class NutritionRecentItem extends Equatable {
  const NutritionRecentItem({
    required this.name,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    required this.lastUsedAtMs,
    required this.lastGrams,
    this.barcode,
  });

  final String name;
  final int kcalPer100;
  final int proteinPer100;
  final int carbsPer100;
  final int fatPer100;
  final int lastUsedAtMs;
  final double lastGrams;
  final String? barcode;

  /// Deduplication key: barcode first, then lowercased name.
  String get dedupeKey => barcode?.isNotEmpty == true
      ? barcode!
      : name.toLowerCase().trim();

  Map<String, dynamic> toJson() => {
        'name': name,
        'kcal_per100': kcalPer100,
        'protein_per100': proteinPer100,
        'carbs_per100': carbsPer100,
        'fat_per100': fatPer100,
        'last_used_at_ms': lastUsedAtMs,
        'last_grams': lastGrams,
        if (barcode != null) 'barcode': barcode,
      };

  factory NutritionRecentItem.fromJson(Map<String, dynamic> j) =>
      NutritionRecentItem(
        name: j['name'] as String,
        kcalPer100: (j['kcal_per100'] as num).toInt(),
        proteinPer100: (j['protein_per100'] as num).toInt(),
        carbsPer100: (j['carbs_per100'] as num).toInt(),
        fatPer100: (j['fat_per100'] as num).toInt(),
        lastUsedAtMs: (j['last_used_at_ms'] as num).toInt(),
        lastGrams: (j['last_grams'] as num).toDouble(),
        barcode: j['barcode'] as String?,
      );

  @override
  List<Object?> get props => [dedupeKey];
}
