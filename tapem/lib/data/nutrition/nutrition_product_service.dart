import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/nutrition/nutrition_product.dart';
import '../../domain/entities/nutrition/nutrition_recent_item.dart';
import '../../core/utils/logger.dart';
import 'open_food_facts_client.dart';
import 'usda_food_client.dart';
import 'nutrition_product_cache_store.dart';
import 'nutrition_recents_store.dart';

/// Lazy-initialized provider for [NutritionProductService].
final nutritionProductServiceProvider = Provider<NutritionProductService>((
  ref,
) {
  throw UnimplementedError(
    'Override in ProviderScope overrides or initialize after main()',
  );
});

/// Regex for barcodes that qualify for global persistence (8/12/13/14 digits).
final _validBarcodeRegex = RegExp(r'^\d{8}$|^\d{12}$|^\d{13}$|^\d{14}$');

bool _isBarcodePersistable(String? barcode) =>
    barcode != null && _validBarcodeRegex.hasMatch(barcode);

/// Orchestrates product lookup: local cache → Supabase → Open Food Facts → USDA.
class NutritionProductService {
  NutritionProductService({
    required SupabaseClient supabase,
    required NutritionProductCacheStore cache,
    required NutritionRecentsStore recents,
    required OpenFoodFactsClient offClient,
    required UsdaFoodClient usdaClient,
  }) : _supabase = supabase,
       _cache = cache,
       _recents = recents,
       _off = offClient,
       _usda = usdaClient;

  final SupabaseClient _supabase;
  final NutritionProductCacheStore _cache;
  final NutritionRecentsStore _recents;
  final OpenFoodFactsClient _off;
  final UsdaFoodClient _usda;

  // ── Barcode lookup ────────────────────────────────────────────────────────

  Future<NutritionProduct?> getByBarcode(String barcode) async {
    // 1. Local cache
    final cached = _cache.get(barcode);
    if (cached != null) return cached;

    // 2. Supabase global products
    try {
      final row = await _supabase
          .from('nutrition_products')
          .select(
            'barcode, name, kcal_per100, protein_per100, carbs_per100, '
            'fat_per100, updated_at',
          )
          .eq('barcode', barcode)
          .maybeSingle();
      if (row != null) {
        final product = NutritionProduct.fromJson(row);
        await _cache.put(product);
        return product;
      }
    } catch (e) {
      AppLogger.w('Supabase product lookup failed', e);
    }

    // 3. Open Food Facts
    final offProduct = await _off.getByBarcode(barcode);
    if (offProduct != null && offProduct.isValid) {
      // Best-effort global persist
      if (_isBarcodePersistable(barcode)) {
        _persistGlobally(offProduct).ignore();
      }
      await _cache.put(offProduct);
      return offProduct;
    }

    return null;
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<List<NutritionProduct>> search(String query) async {
    final results = <NutritionProduct>[];

    // 1. Supabase ILIKE search (already persisted products)
    try {
      final rows = await _supabase
          .from('nutrition_products')
          .select(
            'barcode, name, kcal_per100, protein_per100, carbs_per100, '
            'fat_per100, updated_at',
          )
          .ilike('name', '%$query%')
          .limit(20);
      for (final row in rows) {
        results.add(NutritionProduct.fromJson(row));
      }
    } catch (e) {
      AppLogger.w('Supabase search failed', e);
    }

    // 2. Open Food Facts v2 search + USDA in parallel
    final futures = await Future.wait([
      _off.search(query),
      _usda.search(query),
    ]);
    final offResults = futures[0];
    final usdaResults = futures[1];

    // 3. Merge: dedup by barcode first, then by lowercased name
    final seenBarcodes = <String>{};
    final seenNames = <String>{};
    final merged = <NutritionProduct>[];
    for (final p in [...results, ...offResults, ...usdaResults]) {
      if (p.barcode != null && p.barcode!.isNotEmpty) {
        if (!seenBarcodes.add(p.barcode!)) continue;
      } else {
        if (!seenNames.add(p.name.toLowerCase())) continue;
      }
      merged.add(p);
    }
    return merged;
  }

  // ── Recents ───────────────────────────────────────────────────────────────

  List<NutritionRecentItem> getRecents() => _recents.load();

  Future<void> addToRecents({
    required NutritionProduct product,
    required double grams,
  }) async {
    await _recents.add(
      NutritionRecentItem(
        name: product.name,
        kcalPer100: product.kcalPer100,
        proteinPer100: product.proteinPer100,
        carbsPer100: product.carbsPer100,
        fatPer100: product.fatPer100,
        lastUsedAtMs: DateTime.now().millisecondsSinceEpoch,
        lastGrams: grams,
        barcode: product.barcode,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _persistGlobally(NutritionProduct product) async {
    try {
      await _supabase.from('nutrition_products').upsert({
        'barcode': product.barcode,
        'name': product.name,
        'kcal_per100': product.kcalPer100,
        'protein_per100': product.proteinPer100,
        'carbs_per100': product.carbsPer100,
        'fat_per100': product.fatPer100,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      AppLogger.w('Failed to persist product globally', e);
    }
  }
}
