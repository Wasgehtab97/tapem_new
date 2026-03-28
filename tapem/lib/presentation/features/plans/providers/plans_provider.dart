import 'dart:async' show unawaited;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/gym_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../../domain/entities/plan/plan_item.dart';
import '../../../features/auth/providers/auth_provider.dart';

const _uuid = Uuid();

/// Maximum number of active plans a user can have at one time.
const kMaxPlansPerUser = 7;

// ─── Stream: all active plans for the current user/gym ───────────────────────

final plansProvider = StreamProvider<List<LocalWorkoutPlan>>((ref) {
  final gymId = ref.watch(activeGymIdProvider);
  final user = ref.watch(currentUserProvider);
  if (gymId == null || user == null) return const Stream.empty();
  return ref.watch(appDatabaseProvider).watchPlansForUser(gymId, user.id);
});

// ─── Restore plans from Supabase when local SQLite is empty ──────────────────
//
// Called on the PlansScreen and Plans-from-session flow. If the user has
// reinstalled the app (SQLite cleared), this fetches all their active plans
// from Supabase and writes them back into SQLite so the StreamProvider above
// can serve them normally. Idempotent: no-op when SQLite already has plans.

final restorePlansFromSupabaseProvider = FutureProvider<void>((ref) async {
  final gymId = ref.watch(activeGymIdProvider);
  final user = ref.watch(currentUserProvider);
  if (gymId == null || user == null) return;

  final db = ref.watch(appDatabaseProvider);

  // Fast path: SQLite has plans — nothing to restore.
  final localPlans = await db.watchPlansForUser(gymId, user.id).first;
  if (localPlans.isNotEmpty) return;

  try {
    final client = ref.watch(supabaseClientProvider);

    final planRows = await client
        .from('workout_plans')
        .select('id, name, created_at, updated_at')
        .eq('gym_id', gymId)
        .eq('is_active', true)
        .order('updated_at', ascending: false)
        .limit(kMaxPlansPerUser);

    for (final row in (planRows as List)) {
      final r = Map<String, Object?>.from(row as Map);
      final planId = r['id'] as String;

      await db.upsertPlan(
        LocalWorkoutPlansCompanion(
          id: Value(planId),
          gymId: Value(gymId),
          userId: Value(user.id),
          name: Value(r['name'] as String? ?? ''),
          isActive: const Value(true),
          syncStatus: const Value('sync_confirmed'),
          createdAt: Value(
            DateTime.tryParse(r['created_at'] as String? ?? '') ??
                DateTime.now(),
          ),
          updatedAt: Value(
            DateTime.tryParse(r['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        ),
      );

      final itemRows = await client
          .from('plan_items')
          .select(
            'id, equipment_id, canonical_exercise_key, '
            'custom_exercise_id, display_name, position',
          )
          .eq('plan_id', planId)
          .order('position', ascending: true);

      final companions =
          (itemRows as List).map((item) {
            final i = Map<String, Object?>.from(item as Map);
            return LocalPlanItemsCompanion(
              id: Value(i['id'] as String),
              planId: Value(planId),
              gymId: Value(gymId),
              equipmentId: Value(i['equipment_id'] as String? ?? ''),
              canonicalExerciseKey: Value(
                i['canonical_exercise_key'] as String?,
              ),
              customExerciseId: Value(i['custom_exercise_id'] as String?),
              displayName: Value(i['display_name'] as String? ?? ''),
              position: Value((i['position'] as num?)?.toInt() ?? 0),
              createdAt: Value(DateTime.now()),
            );
          }).toList();

      if (companions.isNotEmpty) {
        await db.replacePlanItems(planId, companions);
      }
    }
  } catch (e, st) {
    AppLogger.e('restorePlansFromSupabase: failed', e, st);
  }
});

// ─── Plan builder state ───────────────────────────────────────────────────────

/// An exercise item held in-memory while the user edits a plan.
/// Uses a stable [tempId] so [ReorderableListView] can track it.
class PlanBuilderItem {
  const PlanBuilderItem({
    required this.tempId,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentType, // 'fixed_machine' | 'open_station' | 'cardio'
    this.canonicalExerciseKey,
    this.customExerciseId,
    required this.displayName,
  });

  final String tempId;
  final String equipmentId;
  final String equipmentName;
  final String equipmentType;
  final String? canonicalExerciseKey;
  final String? customExerciseId;
  final String displayName;

  /// Converts to a [PlanItem] for persistence. Position assigned by caller.
  PlanItem toPlanItem({
    required String planId,
    required String gymId,
    required int position,
  }) => PlanItem(
    id: _uuid.v4(),
    planId: planId,
    gymId: gymId,
    equipmentId: equipmentId,
    canonicalExerciseKey: canonicalExerciseKey,
    customExerciseId: customExerciseId,
    displayName: displayName,
    position: position,
  );
}

class PlanBuilderState {
  const PlanBuilderState({
    this.isLoading = false,
    this.name = '',
    this.items = const [],
    this.isSaving = false,
    this.error,
    this.savedPlanId,
  });

  final bool isLoading;
  final String name;
  final List<PlanBuilderItem> items;
  final bool isSaving;
  final String? error;
  final String? savedPlanId; // non-null after successful save

  bool get canSave => name.trim().isNotEmpty;

  PlanBuilderState copyWith({
    bool? isLoading,
    String? name,
    List<PlanBuilderItem>? items,
    bool? isSaving,
    String? error,
    String? savedPlanId,
  }) => PlanBuilderState(
    isLoading: isLoading ?? this.isLoading,
    name: name ?? this.name,
    items: items ?? this.items,
    isSaving: isSaving ?? this.isSaving,
    error: error,
    savedPlanId: savedPlanId ?? this.savedPlanId,
  );
}

// ─── Plan builder notifier ────────────────────────────────────────────────────

class PlanBuilderNotifier extends StateNotifier<PlanBuilderState> {
  PlanBuilderNotifier(this._ref, this._editPlanId)
    : super(const PlanBuilderState()) {
    final editPlanId = _editPlanId;
    if (editPlanId != null) {
      unawaited(_loadExisting(editPlanId));
    }
  }

  final Ref _ref;
  final String? _editPlanId;

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  SupabaseClient get _supabase => _ref.read(supabaseClientProvider);

  bool get isEditMode => _editPlanId != null;

  // ── Load existing plan for edit ──────────────────────────────────────────

  Future<void> _loadExisting(String planId) async {
    state = state.copyWith(isLoading: true);
    try {
      final plan = await _db.getPlanById(planId);
      if (plan == null || !mounted) return;
      final dbItems = await _db.getItemsForPlan(planId);
      final items = dbItems
          .map(
            (row) => PlanBuilderItem(
              tempId: row.id,
              equipmentId: row.equipmentId,
              equipmentName: row.displayName,
              equipmentType: row.canonicalExerciseKey != null
                  ? 'fixed_machine'
                  : row.customExerciseId != null
                  ? 'open_station'
                  : 'cardio',
              canonicalExerciseKey: row.canonicalExerciseKey,
              customExerciseId: row.customExerciseId,
              displayName: row.displayName,
            ),
          )
          .toList();
      state = state.copyWith(isLoading: false, name: plan.name, items: items);
    } catch (e, st) {
      AppLogger.e('PlanBuilderNotifier: failed to load plan', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Mutations ────────────────────────────────────────────────────────────

  void setName(String value) =>
      state = state.copyWith(name: value, error: null);

  void addItem(PlanBuilderItem item) =>
      state = state.copyWith(items: [...state.items, item], error: null);

  void removeItem(String tempId) => state = state.copyWith(
    items: state.items.where((i) => i.tempId != tempId).toList(),
  );

  void reorder(int oldIndex, int newIndex) {
    // ReorderableListView passes newIndex as if the dragged item is removed
    if (newIndex > oldIndex) newIndex -= 1;
    final list = [...state.items];
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    state = state.copyWith(items: list);
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  /// Persists plan + items to local DB, then fire-and-forgets Supabase sync.
  /// Returns the plan ID on success, null on validation failure.
  Future<String?> save() async {
    if (!state.canSave) return null;

    final gymId = _ref.read(activeGymIdProvider);
    final user = _ref.read(currentUserProvider);
    if (gymId == null || user == null) return null;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final planId = _editPlanId ?? _uuid.v4();

      // Enforce max plan limit for new plans only (not edits).
      if (_editPlanId == null) {
        final existing = await _db.watchPlansForUser(gymId, user.id).first;
        if (existing.length >= kMaxPlansPerUser) {
          state = state.copyWith(
            isSaving: false,
            error:
                'Du hast bereits $kMaxPlansPerUser Pläne. '
                'Lösche einen Plan, bevor du einen neuen erstellst.',
          );
          return null;
        }
      }
      final now = DateTime.now();
      final trimmedName = state.name.trim();

      // 1. Persist plan header locally
      await _db.upsertPlan(
        LocalWorkoutPlansCompanion(
          id: Value(planId),
          gymId: Value(gymId),
          userId: Value(user.id),
          name: Value(trimmedName),
          isActive: const Value(true),
          syncStatus: const Value('sync_confirmed'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // 2. Persist items (atomic replace)
      final companions = state.items.asMap().entries.map((e) {
        final item = e.value;
        final pos = e.key;
        return LocalPlanItemsCompanion(
          id: Value(_uuid.v4()),
          planId: Value(planId),
          gymId: Value(gymId),
          equipmentId: Value(item.equipmentId),
          canonicalExerciseKey: Value(item.canonicalExerciseKey),
          customExerciseId: Value(item.customExerciseId),
          displayName: Value(item.displayName),
          position: Value(pos),
          createdAt: Value(now),
        );
      }).toList();
      await _db.replacePlanItems(planId, companions);

      unawaited(
        _syncToSupabase(
          planId: planId,
          gymId: gymId,
          userId: user.id,
          name: trimmedName,
          items: state.items,
          now: now,
        ),
      );

      state = state.copyWith(isSaving: false, savedPlanId: planId);
      return planId;
    } catch (e, st) {
      AppLogger.e('PlanBuilderNotifier: save failed', e, st);
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  Future<void> deletePlan() async {
    final planId = _editPlanId;
    if (planId == null) return;
    final gymId = _ref.read(activeGymIdProvider);
    if (gymId == null) return;

    try {
      await _db.softDeletePlan(planId);
      unawaited(() async {
        try {
          await _supabase
              .from('workout_plans')
              .update({'is_active': false})
              .eq('id', planId)
              .eq('gym_id', gymId);
        } catch (e) {
          AppLogger.e('PlanBuilderNotifier: remote delete failed', e, null);
        }
      }());
    } catch (e, st) {
      AppLogger.e('PlanBuilderNotifier: local delete failed', e, st);
    }
  }

  // ── Supabase sync (fire-and-forget) ──────────────────────────────────────

  Future<void> _syncToSupabase({
    required String planId,
    required String gymId,
    required String userId,
    required String name,
    required List<PlanBuilderItem> items,
    required DateTime now,
  }) async {
    try {
      // Upsert plan header
      await _supabase.from('workout_plans').upsert({
        'id': planId,
        'gym_id': gymId,
        'created_by': userId,
        'name': name,
        'is_active': true,
        'updated_at': now.toIso8601String(),
      });

      // Replace items: delete all then re-insert
      await _supabase.from('plan_items').delete().eq('plan_id', planId);
      if (items.isNotEmpty) {
        await _supabase
            .from('plan_items')
            .insert(
              items.asMap().entries.map((e) {
                final item = e.value;
                return {
                  'id': _uuid.v4(),
                  'plan_id': planId,
                  'gym_id': gymId,
                  'equipment_id': item.equipmentId,
                  'canonical_exercise_key': item.canonicalExerciseKey,
                  'custom_exercise_id': item.customExerciseId,
                  'display_name': item.displayName,
                  'position': e.key,
                };
              }).toList(),
            );
      }
    } catch (e, st) {
      AppLogger.e('PlanBuilderNotifier: Supabase sync failed', e, st);
      // Local data is already persisted — sync will retry on next save
    }
  }
}

final planBuilderProvider = StateNotifierProvider.autoDispose
    .family<PlanBuilderNotifier, PlanBuilderState, String?>(
      (ref, planId) => PlanBuilderNotifier(ref, planId),
    );

// ─── Plan-with-items for start-from-plan flow ─────────────────────────────────

final planItemsProvider = FutureProvider.autoDispose
    .family<List<LocalPlanItem>, String>(
      (ref, planId) => ref.watch(appDatabaseProvider).getItemsForPlan(planId),
    );

// ─── Create plan from a finished session ─────────────────────────────────────

/// Converts a finished workout session into a new [WorkoutPlan].
///
/// Maps each [LocalSessionExercise] row to a [LocalPlanItemsCompanion], in
/// their original [sortOrder]. Exercises without a resolvable [equipmentId]
/// (pre-v3 legacy data that is neither cardio nor has the field set) are
/// silently skipped.
///
/// Returns the new plan's ID on success, or `null` when no mappable exercises
/// were found (all legacy, or the session has no exercises at all).
Future<String?> createPlanFromSession({
  required AppDatabase db,
  required SupabaseClient supabase,
  required String gymId,
  required String userId,
  required String sessionId,
  required String planName,
}) async {
  // Enforce max plan limit.
  final activePlans = await db.watchPlansForUser(gymId, userId).first;
  if (activePlans.length >= kMaxPlansPerUser) return null;

  // Try local SQLite first (normal case).
  var exercises = await db.getExercisesForSession(sessionId);

  // Reinstall fallback: SQLite is empty — fetch exercises from Supabase.
  if (exercises.isEmpty) {
    try {
      final rows = await supabase
          .from('session_exercises')
          .select(
            'id, exercise_key, display_name, sort_order, '
            'equipment_id, custom_exercise_id',
          )
          .eq('session_id', sessionId)
          .order('sort_order', ascending: true);

      exercises =
          (rows as List).map((row) {
            final r = Map<String, Object?>.from(row as Map);
            return LocalSessionExercise(
              id: r['id'] as String? ?? '',
              sessionId: sessionId,
              gymId: gymId,
              exerciseKey: r['exercise_key'] as String? ?? '',
              displayName: r['display_name'] as String? ?? '',
              sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
              equipmentId: r['equipment_id'] as String?,
              customExerciseId: r['custom_exercise_id'] as String?,
              syncStatus: 'sync_confirmed',
              createdAt: DateTime.now(),
            );
          }).toList();
    } catch (e, st) {
      AppLogger.e('createPlanFromSession: Supabase exercises fallback failed', e, st);
    }
  }

  if (exercises.isEmpty) return null;

  final planId = _uuid.v4();
  final now = DateTime.now();
  final trimmedName = planName.trim();

  // Build companion list — resolve equipmentId for each exercise.
  final companions = <LocalPlanItemsCompanion>[];
  for (var i = 0; i < exercises.length; i++) {
    final ex = exercises[i];

    String? equipmentId = ex.equipmentId;
    if (equipmentId == null) {
      // Legacy cardio exercises encode the equipment ID in the exercise key.
      if (ex.exerciseKey.startsWith('cardio:')) {
        equipmentId = ex.exerciseKey.substring(7);
      } else {
        continue; // Pre-v3 fixed/open exercise — cannot map without equipmentId.
      }
    }

    // Canonical key applies to fixed-machine exercises only.
    final canonicalKey =
        (ex.customExerciseId == null && !ex.exerciseKey.startsWith('cardio:'))
        ? ex.exerciseKey
        : null;

    companions.add(
      LocalPlanItemsCompanion(
        id: Value(_uuid.v4()),
        planId: Value(planId),
        gymId: Value(gymId),
        equipmentId: Value(equipmentId),
        canonicalExerciseKey: Value(canonicalKey),
        customExerciseId: Value(ex.customExerciseId),
        displayName: Value(ex.displayName),
        position: Value(i),
        createdAt: Value(now),
      ),
    );
  }

  if (companions.isEmpty) return null;

  // Persist plan header locally.
  await db.upsertPlan(
    LocalWorkoutPlansCompanion(
      id: Value(planId),
      gymId: Value(gymId),
      userId: Value(userId),
      name: Value(trimmedName),
      isActive: const Value(true),
      syncStatus: const Value('sync_confirmed'),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );

  // Persist items atomically.
  await db.replacePlanItems(planId, companions);

  // Fire-and-forget remote sync — local data is authoritative.
  unawaited(
    _syncNewPlanToSupabase(
      supabase: supabase,
      planId: planId,
      gymId: gymId,
      userId: userId,
      name: trimmedName,
      companions: companions,
      now: now,
    ),
  );

  return planId;
}

Future<void> _syncNewPlanToSupabase({
  required SupabaseClient supabase,
  required String planId,
  required String gymId,
  required String userId,
  required String name,
  required List<LocalPlanItemsCompanion> companions,
  required DateTime now,
}) async {
  try {
    await supabase.from('workout_plans').upsert({
      'id': planId,
      'gym_id': gymId,
      'created_by': userId,
      'name': name,
      'is_active': true,
      'updated_at': now.toIso8601String(),
    });

    await supabase.from('plan_items').delete().eq('plan_id', planId);
    if (companions.isNotEmpty) {
      await supabase
          .from('plan_items')
          .insert(
            companions
                .map(
                  (c) => {
                    'id': c.id.value,
                    'plan_id': planId,
                    'gym_id': gymId,
                    'equipment_id': c.equipmentId.value,
                    'canonical_exercise_key': c.canonicalExerciseKey.value,
                    'custom_exercise_id': c.customExerciseId.value,
                    'display_name': c.displayName.value,
                    'position': c.position.value,
                  },
                )
                .toList(),
          );
    }
  } catch (e, st) {
    AppLogger.e('createPlanFromSession: Supabase sync failed', e, st);
  }
}
