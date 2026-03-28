import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../domain/entities/nutrition/nutrition_product.dart';
import '../../core/utils/logger.dart';

/// Client for the USDA FoodData Central API (https://fdc.nal.usda.gov/).
/// API key is injected at build time via --dart-define=USDA_API_KEY=...
/// (register free at https://fdc.nal.usda.gov/api-guide.html).
class UsdaFoodClient {
  static const _timeout = Duration(seconds: 10);
  static const _base = 'https://api.nal.usda.gov/fdc/v1';

  Future<List<NutritionProduct>> search(String query, {int pageSize = 20}) async {
    if (query.trim().length < 2) return [];
    final url = Uri.parse('$_base/foods/search').replace(queryParameters: {
      'query': query.trim(),
      'pageSize': pageSize.toString(),
      'api_key': AppConfig.usdaApiKey,
      'dataType': 'Branded,Foundation,SR Legacy',
      'fields': 'fdcId,description,brandName,gtinUpc,dataType,foodNutrients',
    });
    try {
      final resp = await http.get(url).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final foods = json['foods'] as List<dynamic>? ?? [];
      return foods
          .map((f) => _parseFood(f as Map<String, dynamic>))
          .whereType<NutritionProduct>()
          .toList();
    } catch (e) {
      AppLogger.w('USDA search failed', e);
      return [];
    }
  }

  NutritionProduct? _parseFood(Map<String, dynamic> food) {
    final description = (food['description'] as String?)?.trim() ?? '';
    if (description.isEmpty) return null;

    final brandName = (food['brandName'] as String?)?.trim() ?? '';
    final name = brandName.isNotEmpty ? '$description ($brandName)' : description;

    final nutrients = <String, double>{};
    for (final n in food['foodNutrients'] as List<dynamic>? ?? []) {
      final m = n as Map<String, dynamic>;
      final nutrientName = m['nutrientName'] as String? ?? '';
      final value = (m['value'] as num?)?.toDouble() ?? 0.0;
      nutrients[nutrientName] = value;
    }

    // Foundation items use "Energy (Atwater ...)" instead of "Energy"
    final kcal = nutrients['Energy'] ??
        nutrients['Energy (Atwater General Factors)'] ??
        nutrients['Energy (Atwater Specific Factors)'] ??
        0.0;
    final protein = nutrients['Protein'] ?? 0.0;
    final carbs = nutrients['Carbohydrate, by difference'] ?? 0.0;
    final fat = nutrients['Total lipid (fat)'] ?? 0.0;

    if (kcal <= 0 && protein <= 0 && carbs <= 0 && fat <= 0) return null;

    final barcode = (food['gtinUpc'] as String?)?.trim();

    return NutritionProduct(
      name: name,
      kcalPer100: kcal.round(),
      proteinPer100: protein.round(),
      carbsPer100: carbs.round(),
      fatPer100: fat.round(),
      barcode: (barcode != null && barcode.isNotEmpty) ? barcode : null,
      updatedAt: DateTime.now(),
    );
  }
}
