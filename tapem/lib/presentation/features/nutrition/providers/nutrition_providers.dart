import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/services/gym_service.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../data/nutrition/nutrition_product_cache_store.dart';
import '../../../../../data/nutrition/nutrition_product_service.dart';
import '../../../../../data/nutrition/nutrition_recents_store.dart';
import '../../../../../data/nutrition/nutrition_repository.dart';
import '../../../../../data/nutrition/open_food_facts_client.dart';
import '../../../../../data/nutrition/usda_food_client.dart';
import '../../../../../domain/entities/nutrition/nutrition_entry.dart';
import '../../../../../domain/entities/nutrition/nutrition_enums.dart';
import '../../../../../domain/entities/nutrition/nutrition_goal.dart';
import '../../../../../domain/entities/nutrition/nutrition_log.dart';
import '../../../../../domain/entities/nutrition/nutrition_product.dart';
import '../../../../../domain/entities/nutrition/nutrition_recipe.dart';
import '../../../../../domain/entities/nutrition/nutrition_recent_item.dart';
import '../../../../../domain/entities/nutrition/nutrition_year_summary.dart';
import '../../../../../domain/services/nutrition_recipe_math.dart';
import '../../../../../domain/services/nutrition_status_service.dart';
import '../../../../../domain/utils/nutrition_date_utils.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Infrastructure providers ──────────────────────────────────────────────────

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(supabaseClientProvider));
});

final nutritionProductCacheStoreProvider =
    Provider<NutritionProductCacheStore>((ref) {
  return NutritionProductCacheStore(ref.watch(sharedPreferencesProvider));
});

final nutritionRecentsStoreProvider = Provider<NutritionRecentsStore>((ref) {
  return NutritionRecentsStore(ref.watch(sharedPreferencesProvider));
});

final openFoodFactsClientProvider = Provider<OpenFoodFactsClient>(
  (_) => OpenFoodFactsClient(),
);

final usdaFoodClientProvider = Provider<UsdaFoodClient>(
  (_) => UsdaFoodClient(),
);

final nutritionProductServiceProvider =
    Provider<NutritionProductService>((ref) {
  return NutritionProductService(
    supabase: ref.watch(supabaseClientProvider),
    cache: ref.watch(nutritionProductCacheStoreProvider),
    recents: ref.watch(nutritionRecentsStoreProvider),
    offClient: ref.watch(openFoodFactsClientProvider),
    usdaClient: ref.watch(usdaFoodClientProvider),
  );
});

// ─── Day state ─────────────────────────────────────────────────────────────────

class NutritionDayState {
  const NutritionDayState({
    this.log,
    this.goal,
    this.isLoading = false,
    this.error,
  });

  final NutritionLog? log;
  final NutritionGoal? goal;
  final bool isLoading;
  final String? error;

  NutritionDayState copyWith({
    NutritionLog? log,
    NutritionGoal? goal,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearLog = false,
    bool clearGoal = false,
  }) =>
      NutritionDayState(
        log: clearLog ? null : log ?? this.log,
        goal: clearGoal ? null : goal ?? this.goal,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

// ─── Main nutrition notifier ───────────────────────────────────────────────────

class NutritionNotifier extends StateNotifier<NutritionDayState> {
  NutritionNotifier(this._repo, this._productService)
      : super(const NutritionDayState());

  final NutritionRepository _repo;
  final NutritionProductService _productService;

  String? _uid;
  String _dateKey = NutritionDateUtils.today();

  static const _uuid = Uuid();

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load(String uid, {String? dateKey}) async {
    _uid = uid;
    _dateKey = dateKey ?? NutritionDateUtils.today();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final log = await _repo.loadLog(uid, _dateKey);
      final goal = await _resolveGoal(uid, _dateKey);
      state = NutritionDayState(log: log, goal: goal);
    } catch (e) {
      state = NutritionDayState(error: e.toString());
      AppLogger.e('NutritionNotifier.load failed', e);
    }
  }

  // ── Add entries ───────────────────────────────────────────────────────────

  Future<void> addEntries(List<NutritionEntry> newEntries) async {
    final uid = _uid;
    if (uid == null) return;

    final prevLog = state.log;
    final prevGoal = state.goal;

    final existing = prevLog?.entries ?? [];
    if (existing.length + newEntries.length > 50) {
      state = state.copyWith(
        error: 'Maximal 50 Einträge pro Tag erlaubt.',
      );
      return;
    }

    final entries = [...existing, ...newEntries];
    final goal = await _resolveGoal(uid, _dateKey);
    final status = NutritionStatusService.statusFor(
      entries.fold(0, (s, e) => s + e.kcal),
      goal.kcal,
    );
    final newLog = NutritionLog.recompute(
      dateKey: _dateKey,
      entries: entries,
      status: status,
    );

    // Optimistic update
    state = NutritionDayState(log: newLog, goal: goal);

    try {
      await _repo.upsertLog(uid, newLog);
      await _repo.updateYearDay(
        uid: uid,
        dateKey: _dateKey,
        status: status,
        totalKcal: newLog.totalKcal,
        goalKcal: goal.kcal,
      );
      // Add to recents
      for (final e in newEntries) {
        if (e.barcode != null || e.name.isNotEmpty) {
          await _productService.addToRecents(
            product: NutritionProduct(
              name: e.name,
              kcalPer100: e.qty != null && e.qty! > 0
                  ? (e.kcal / e.qty! * 100).round()
                  : e.kcal,
              proteinPer100: e.qty != null && e.qty! > 0
                  ? (e.protein / e.qty! * 100).round()
                  : e.protein,
              carbsPer100: e.qty != null && e.qty! > 0
                  ? (e.carbs / e.qty! * 100).round()
                  : e.carbs,
              fatPer100: e.qty != null && e.qty! > 0
                  ? (e.fat / e.qty! * 100).round()
                  : e.fat,
              barcode: e.barcode,
              updatedAt: DateTime.now(),
            ),
            grams: e.qty ?? 100,
          );
        }
      }
    } catch (e) {
      // Rollback
      state = NutritionDayState(
          log: prevLog, goal: prevGoal, error: e.toString());
      rethrow;
    }
  }

  // ── Remove entry ──────────────────────────────────────────────────────────

  Future<void> removeEntry(String entryId) async {
    final uid = _uid;
    if (uid == null) return;

    final prevLog = state.log;
    final prevGoal = state.goal;

    final entries =
        (prevLog?.entries ?? []).where((e) => e.id != entryId).toList();
    final goal = await _resolveGoal(uid, _dateKey);
    final status = NutritionStatusService.statusFor(
      entries.fold(0, (s, e) => s + e.kcal),
      goal.kcal,
    );
    final newLog = NutritionLog.recompute(
      dateKey: _dateKey,
      entries: entries,
      status: status,
    );

    state = NutritionDayState(log: newLog, goal: goal);

    try {
      await _repo.upsertLog(uid, newLog);
      await _repo.updateYearDay(
        uid: uid,
        dateKey: _dateKey,
        status: status,
        totalKcal: newLog.totalKcal,
        goalKcal: goal.kcal,
      );
    } catch (e) {
      state =
          NutritionDayState(log: prevLog, goal: prevGoal, error: e.toString());
      rethrow;
    }
  }

  // ── Update entry ──────────────────────────────────────────────────────────

  Future<void> updateEntry(NutritionEntry updated) async {
    final uid = _uid;
    if (uid == null) return;

    final prevLog = state.log;
    final prevGoal = state.goal;

    final entries = (prevLog?.entries ?? [])
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    final goal = await _resolveGoal(uid, _dateKey);
    final status = NutritionStatusService.statusFor(
      entries.fold(0, (s, e) => s + e.kcal),
      goal.kcal,
    );
    final newLog = NutritionLog.recompute(
      dateKey: _dateKey,
      entries: entries,
      status: status,
    );

    state = NutritionDayState(log: newLog, goal: goal);

    try {
      await _repo.upsertLog(uid, newLog);
      await _repo.updateYearDay(
        uid: uid,
        dateKey: _dateKey,
        status: status,
        totalKcal: newLog.totalKcal,
        goalKcal: goal.kcal,
      );
    } catch (e) {
      state =
          NutritionDayState(log: prevLog, goal: prevGoal, error: e.toString());
      rethrow;
    }
  }

  // ── Save goal ─────────────────────────────────────────────────────────────

  Future<void> saveGoal(NutritionGoal goal) async {
    final uid = _uid;
    if (uid == null) return;

    final prevGoal = state.goal;
    state = state.copyWith(goal: goal);

    try {
      await _repo.upsertGoal(uid, goal);
      await _repo.upsertDefaultGoal(uid, goal);

      // Recompute status with new goal
      final log = state.log;
      if (log != null) {
        final status =
            NutritionStatusService.statusFor(log.totalKcal, goal.kcal);
        final updatedLog = log.copyWith(status: status);
        state = NutritionDayState(log: updatedLog, goal: goal);
        await _repo.upsertLog(uid, updatedLog);
        await _repo.updateYearDay(
          uid: uid,
          dateKey: _dateKey,
          status: status,
          totalKcal: log.totalKcal,
          goalKcal: goal.kcal,
        );
      }
    } catch (e) {
      state = state.copyWith(goal: prevGoal, error: e.toString());
      rethrow;
    }
  }

  // ── Add recipe to meal ────────────────────────────────────────────────────

  Future<void> addRecipeToMeal({
    required NutritionRecipe recipe,
    required MealType meal,
    required double factor,
  }) async {
    final entries = NutritionRecipeMath.buildIngredientEntries(
      recipe: recipe,
      meal: meal,
      factor: factor,
      idGen: () => _uuid.v4(),
    );
    await addEntries(entries);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<NutritionGoal> _resolveGoal(String uid, String dateKey) async {
    // Try date-specific goal
    final specific = await _repo.loadGoalForDate(uid, dateKey);
    if (specific != null && specific.dateKey == dateKey) return specific;

    // Try default goal
    final def = await _repo.loadDefaultGoal(uid);
    if (def != null) return def.copyWith(dateKey: dateKey);

    // Fallback to built-in default
    return NutritionGoal.defaultGoal(dateKey);
  }

  String generateId() => _uuid.v4();
}

// ─── Providers ────────────────────────────────────────────────────────────────

final nutritionNotifierProvider =
    StateNotifierProvider<NutritionNotifier, NutritionDayState>((ref) {
  return NutritionNotifier(
    ref.watch(nutritionRepositoryProvider),
    ref.watch(nutritionProductServiceProvider),
  );
});

// ── Year summary provider (family by year) ────────────────────────────────────

final nutritionYearSummaryProvider =
    FutureProvider.family<NutritionYearSummary?, ({String uid, int year})>(
  (ref, args) async {
    final repo = ref.watch(nutritionRepositoryProvider);
    return repo.loadYearSummary(args.uid, args.year);
  },
);

// ── Recipes provider ──────────────────────────────────────────────────────────

class RecipesNotifier
    extends StateNotifier<AsyncValue<List<NutritionRecipe>>> {
  RecipesNotifier(this._repo) : super(const AsyncValue.loading());

  final NutritionRepository _repo;
  String? _uid;

  Future<void> load(String uid) async {
    _uid = uid;
    state = const AsyncValue.loading();
    try {
      final recipes = await _repo.loadRecipes(uid);
      state = AsyncValue.data(recipes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(NutritionRecipe recipe) async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.upsertRecipe(uid, recipe);
    await load(uid);
  }

  Future<void> delete(String recipeId) async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.deleteRecipe(uid, recipeId);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
        current.where((r) => r.id != recipeId).toList());
  }
}

final recipesNotifierProvider =
    StateNotifierProvider<RecipesNotifier, AsyncValue<List<NutritionRecipe>>>(
  (ref) => RecipesNotifier(ref.watch(nutritionRepositoryProvider)),
);

// ── Recents provider (synchronous, from SharedPreferences) ───────────────────

final nutritionRecentsProvider = Provider<List<NutritionRecentItem>>((ref) {
  final store = ref.watch(nutritionRecentsStoreProvider);
  return store.load();
});

// ── Product search provider ────────────────────────────────────────────────────

final nutritionProductSearchProvider =
    FutureProvider.family<List<NutritionProduct>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  final service = ref.watch(nutritionProductServiceProvider);
  return service.search(query);
});
