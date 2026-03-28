import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/nutrition/nutrition_product.dart';
import '../../core/utils/logger.dart';

/// HTTP client for the Open Food Facts API.
class OpenFoodFactsClient {
  static const _timeout = Duration(seconds: 8);
  static const _base = 'https://world.openfoodfacts.org';

  static const _headers = {
    'User-Agent': 'tapem/1.0 - Flutter - https://tapem.app',
  };

  /// Look up a single product by barcode. Returns null if not found or invalid.
  Future<NutritionProduct?> getByBarcode(String barcode) async {
    final url = Uri.parse(
      '$_base/api/v2/product/$barcode.json?'
      'fields=product_name,nutriments,code',
    );
    try {
      final resp = await http.get(url, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['status'] != 1) return null;
      final product = json['product'] as Map<String, dynamic>?;
      if (product == null) return null;
      return _parseProduct(barcode, product);
    } catch (e) {
      AppLogger.w('OpenFoodFacts barcode lookup failed', e);
      return null;
    }
  }

  /// Search for products by name. Returns a filtered list of valid products.
  Future<List<NutritionProduct>> search(
    String query, {
    String lc = 'de',
    String? cc,
  }) async {
    if (query.trim().length < 2) return [];
    final params = {
      'search_terms': query.trim(),
      'lc': lc,
      if (cc != null) 'cc': cc,
      'page_size': '20',
      'fields': 'product_name,nutriments,code',
    };
    final url = Uri.parse('$_base/api/v2/search').replace(
      queryParameters: params,
    );
    try {
      final resp = await http.get(url, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final products = json['products'] as List<dynamic>? ?? [];
      return products
          .map((p) => _parseProduct(
                (p as Map<String, dynamic>)['code'] as String? ?? '',
                p,
              ))
          .whereType<NutritionProduct>()
          .where((p) => p.isValid)
          .where((p) =>
              p.kcalPer100 + p.proteinPer100 + p.carbsPer100 + p.fatPer100 > 0)
          .toList();
    } catch (e) {
      AppLogger.w('OpenFoodFacts search failed', e);
      return [];
    }
  }

  NutritionProduct? _parseProduct(
    String barcode,
    Map<String, dynamic> product,
  ) {
    final name = (product['product_name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return null;

    final nutriments =
        product['nutriments'] as Map<String, dynamic>? ?? {};

    // Prefer energy-kcal, fallback to kJ / 4.184
    double kcal = _toDouble(nutriments['energy-kcal_100g']) ??
        _toDouble(nutriments['energy-kcal']) ??
        0;
    if (kcal == 0) {
      final kj = _toDouble(nutriments['energy-kj_100g']) ??
          _toDouble(nutriments['energy_100g']) ??
          0;
      kcal = kj / 4.184;
    }
    final protein = _toDouble(nutriments['proteins_100g']) ?? 0;
    final carbs = _toDouble(nutriments['carbohydrates_100g']) ?? 0;
    final fat = _toDouble(nutriments['fat_100g']) ?? 0;

    if (kcal < 0 || protein < 0 || carbs < 0 || fat < 0) return null;

    return NutritionProduct(
      name: name,
      kcalPer100: kcal.round(),
      proteinPer100: protein.round(),
      carbsPer100: carbs.round(),
      fatPer100: fat.round(),
      barcode: barcode.isNotEmpty ? barcode : null,
      updatedAt: DateTime.now(),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
