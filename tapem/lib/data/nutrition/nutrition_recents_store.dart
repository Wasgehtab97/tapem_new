import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/nutrition/nutrition_recent_item.dart';

/// Persists recently used food items in SharedPreferences.
/// Limit 60, deduped by barcode (first) then lowercased name.
class NutritionRecentsStore {
  NutritionRecentsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'nutrition_recents_v1';
  static const _limit = 60;

  List<NutritionRecentItem> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => NutritionRecentItem.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.lastUsedAtMs.compareTo(a.lastUsedAtMs));
    } catch (_) {
      return [];
    }
  }

  Future<void> add(NutritionRecentItem item) async {
    final items = load();
    // Remove duplicates (same barcode or same name)
    items.removeWhere((r) => r.dedupeKey == item.dedupeKey);
    items.insert(0, item); // most recent first

    final trimmed = items.take(_limit).toList();
    await _prefs.setString(_key, jsonEncode(trimmed.map((i) => i.toJson()).toList()));
  }

  Future<void> clear() async => _prefs.remove(_key);
}
