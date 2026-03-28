import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/nutrition/nutrition_enums.dart';
import '../../domain/entities/nutrition/nutrition_goal.dart';
import '../../domain/entities/nutrition/nutrition_log.dart';
import '../../domain/entities/nutrition/nutrition_recipe.dart';
import '../../domain/entities/nutrition/nutrition_weight.dart';
import '../../domain/entities/nutrition/nutrition_year_summary.dart';
import '../../core/utils/logger.dart';

/// Thin Supabase persistence layer for all nutrition data.
/// User-scoped: all operations require [uid].
class NutritionRepository {
  NutritionRepository(this._supabase);

  final SupabaseClient _supabase;

  // ── Goals ──────────────────────────────────────────────────────────────────

  Future<NutritionGoal?> loadGoalForDate(String uid, String dateKey) async {
    try {
      final row = await _supabase
          .from('nutrition_goals')
          .select()
          .eq('user_id', uid)
          .eq('date_key', dateKey)
          .maybeSingle();
      return row != null ? NutritionGoal.fromJson(row) : null;
    } catch (e) {
      AppLogger.w('loadGoalForDate failed', e);
      return null;
    }
  }

  Future<NutritionGoal?> loadDefaultGoal(String uid) async {
    try {
      final row = await _supabase
          .from('nutrition_goal_defaults')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return null;
      return NutritionGoal(
        dateKey: 'default',
        kcal: (row['kcal'] as num).toInt(),
        protein: (row['protein'] as num).toInt(),
        carbs: (row['carbs'] as num).toInt(),
        fat: (row['fat'] as num).toInt(),
        updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
      );
    } catch (e) {
      AppLogger.w('loadDefaultGoal failed', e);
      return null;
    }
  }

  Future<void> upsertGoal(String uid, NutritionGoal goal) async {
    await _supabase.from('nutrition_goals').upsert({
      'user_id': uid,
      ...goal.toJson(),
    });
  }

  Future<void> upsertDefaultGoal(String uid, NutritionGoal goal) async {
    await _supabase.from('nutrition_goal_defaults').upsert({
      'user_id': uid,
      'kcal': goal.kcal,
      'protein': goal.protein,
      'carbs': goal.carbs,
      'fat': goal.fat,
      'updated_at': goal.updatedAt.toUtc().toIso8601String(),
    });
  }

  // ── Logs ───────────────────────────────────────────────────────────────────

  Future<NutritionLog?> loadLog(String uid, String dateKey) async {
    try {
      final row = await _supabase
          .from('nutrition_logs')
          .select()
          .eq('user_id', uid)
          .eq('date_key', dateKey)
          .maybeSingle();
      return row != null ? NutritionLog.fromJson(row) : null;
    } catch (e) {
      AppLogger.w('loadLog failed', e);
      return null;
    }
  }

  Future<void> upsertLog(String uid, NutritionLog log) async {
    await _supabase.from('nutrition_logs').upsert({
      'user_id': uid,
      ...log.toJson(),
    });
  }

  // ── Year Summary ───────────────────────────────────────────────────────────

  Future<NutritionYearSummary?> loadYearSummary(String uid, int year) async {
    try {
      final row = await _supabase
          .from('nutrition_year_summaries')
          .select()
          .eq('user_id', uid)
          .eq('year', year)
          .maybeSingle();
      if (row == null) return null;
      // days is stored as JSONB
      final rawDays = row['days'] as Map<String, dynamic>? ?? {};
      return NutritionYearSummary.fromJson({
        'year': year,
        'days': rawDays,
      });
    } catch (e) {
      AppLogger.w('loadYearSummary failed', e);
      return null;
    }
  }

  Future<void> updateYearDay({
    required String uid,
    required String dateKey,
    required NutritionStatus status,
    required int totalKcal,
    required int goalKcal,
  }) async {
    final year = int.parse(dateKey.substring(0, 4));
    try {
      // Use Postgres jsonb_set to update a single day without overwriting others
      await _supabase.rpc('nutrition_upsert_year_day', params: {
        'p_user_id': uid,
        'p_year': year,
        'p_date_key': dateKey,
        'p_status': status.value,
        'p_total_kcal': totalKcal,
        'p_goal_kcal': goalKcal,
      });
    } catch (e) {
      AppLogger.w('updateYearDay failed', e);
    }
  }

  // ── Recipes ────────────────────────────────────────────────────────────────

  Future<List<NutritionRecipe>> loadRecipes(String uid) async {
    try {
      final rows = await _supabase
          .from('nutrition_recipes')
          .select()
          .eq('user_id', uid)
          .order('updated_at', ascending: false);
      return rows.map((r) => NutritionRecipe.fromJson(r)).toList();
    } catch (e) {
      AppLogger.w('loadRecipes failed', e);
      return [];
    }
  }

  Future<void> upsertRecipe(String uid, NutritionRecipe recipe) async {
    await _supabase.from('nutrition_recipes').upsert({
      'user_id': uid,
      ...recipe.toJson(),
    });
  }

  Future<void> deleteRecipe(String uid, String recipeId) async {
    await _supabase
        .from('nutrition_recipes')
        .delete()
        .eq('user_id', uid)
        .eq('id', recipeId);
  }

  // ── Weight ─────────────────────────────────────────────────────────────────

  Future<NutritionWeightMeta?> loadWeightMeta(String uid) async {
    try {
      final row = await _supabase
          .from('nutrition_weight_meta')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      return row != null ? NutritionWeightMeta.fromJson(row) : null;
    } catch (e) {
      AppLogger.w('loadWeightMeta failed', e);
      return null;
    }
  }

  Future<Map<String, double>> loadWeightYear(String uid, int year) async {
    try {
      final row = await _supabase
          .from('nutrition_weight_year_summaries')
          .select('days')
          .eq('user_id', uid)
          .eq('year', year)
          .maybeSingle();
      if (row == null) return {};
      final days = row['days'] as Map<String, dynamic>? ?? {};
      return days.map((k, v) {
        final map = v as Map<String, dynamic>;
        return MapEntry(k, (map['kg'] as num).toDouble());
      });
    } catch (e) {
      AppLogger.w('loadWeightYear failed', e);
      return {};
    }
  }

  Future<void> saveWeight({
    required String uid,
    required String dateKey,
    required double kg,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    // Write daily log
    await _supabase.from('nutrition_weight_logs').upsert({
      'user_id': uid,
      'date_key': dateKey,
      'kg': kg,
      'updated_at': now,
    });

    // Merge-update year summary via RPC
    final year = int.parse(dateKey.substring(0, 4));
    try {
      await _supabase.rpc('nutrition_upsert_weight_day', params: {
        'p_user_id': uid,
        'p_year': year,
        'p_date_key': dateKey,
        'p_kg': kg,
      });
    } catch (e) {
      AppLogger.w('nutrition_upsert_weight_day failed', e);
    }

    // Update meta if this date >= current meta date
    final meta = await loadWeightMeta(uid);
    if (meta == null || dateKey.compareTo(meta.dateKey) >= 0) {
      await _supabase.from('nutrition_weight_meta').upsert({
        'user_id': uid,
        'kg': kg,
        'date_key': dateKey,
        'updated_at': now,
      });
    }
  }
}
