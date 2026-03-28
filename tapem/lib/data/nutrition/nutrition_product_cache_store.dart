import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/nutrition/nutrition_product.dart';

/// LRU product cache backed by SharedPreferences.
/// Max 200 entries, keyed by barcode.
class NutritionProductCacheStore {
  NutritionProductCacheStore(this._prefs);

  final SharedPreferences _prefs;

  static const _indexKey = 'nutrition_product_cache_index';
  static const _itemPrefix = 'nutrition_product_cache/';
  static const _maxEntries = 200;

  List<String> _readIndex() {
    final raw = _prefs.getString(_indexKey);
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeIndex(List<String> index) async {
    await _prefs.setString(_indexKey, jsonEncode(index));
  }

  /// Read a cached product for [barcode]. Returns null if not found.
  NutritionProduct? get(String barcode) {
    final raw = _prefs.getString('$_itemPrefix$barcode');
    if (raw == null) return null;
    try {
      return NutritionProduct.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Store [product] in cache. Evicts oldest entry when over limit.
  Future<void> put(NutritionProduct product) async {
    final barcode = product.barcode;
    if (barcode == null || barcode.isEmpty) return;

    await _prefs.setString(
      '$_itemPrefix$barcode',
      jsonEncode(product.toJson()),
    );

    var index = _readIndex();
    index.remove(barcode);
    index.add(barcode); // move to end (most recent)

    // Evict oldest if over limit
    while (index.length > _maxEntries) {
      final evicted = index.removeAt(0);
      await _prefs.remove('$_itemPrefix$evicted');
    }

    await _writeIndex(index);
  }

  /// Remove a product from cache.
  Future<void> remove(String barcode) async {
    await _prefs.remove('$_itemPrefix$barcode');
    final index = _readIndex();
    index.remove(barcode);
    await _writeIndex(index);
  }
}
