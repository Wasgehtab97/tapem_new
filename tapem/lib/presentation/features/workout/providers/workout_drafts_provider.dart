import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'workout_provider.dart';

const _uuid = Uuid();

// ─── Draft model ──────────────────────────────────────────────────────────────

/// In-memory representation of one editable set row.
///
/// A draft starts life as an empty, unchecked proposal.  When the user taps
/// the checkmark the set is immediately written to SQLite (via [logSet] in
/// [WorkoutNotifier]) and [persistedSetId] is set to the resulting row ID.
/// Unchecking calls [deleteSet] and clears [persistedSetId].
///
/// **Invariant**: [persistedSetId] is non-null iff [isChecked] is true AND the
/// row has been persisted to the local database.  Drafts that were restored
/// from SQLite on cold-start also carry a non-null [persistedSetId].
class SetDraft {
  SetDraft({
    this.weightKg,
    this.reps,
    this.isChecked = false,
    String? id,
    this.persistedSetId,
  }) : id = id ?? _uuid.v4();

  /// Stable UUID — used as [ValueKey] for widgets so that hook state
  /// (TextEditingControllers) is preserved across list mutations.
  final String id;
  final double? weightKg;
  final int? reps;
  final bool isChecked;

  /// The SQLite [local_set_entries.id] this draft maps to, or null when the
  /// draft has not yet been persisted (i.e. the user has not tapped the
  /// checkmark yet, or the set was explicitly unchecked).
  final String? persistedSetId;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// Manages per-exercise draft lists for the active workout session.
/// Key: sessionExerciseId  →  Value: ordered [SetDraft] list.
class WorkoutDraftsNotifier extends StateNotifier<Map<String, List<SetDraft>>> {
  WorkoutDraftsNotifier() : super(const {});

  /// Initialise the draft list for [exerciseId].
  /// No-op if already initialised (prevents double-init on hot-rebuild).
  void initExercise(String exerciseId, List<SetDraft> initial) {
    if (state.containsKey(exerciseId)) return;
    state = {...state, exerciseId: List.unmodifiable(initial)};
  }

  void addSet(String exerciseId) {
    final next = [...(state[exerciseId] ?? const []), SetDraft()];
    state = {...state, exerciseId: List.unmodifiable(next)};
  }

  void removeSet(String exerciseId, int index) {
    final list = state[exerciseId];
    if (list == null || index < 0 || index >= list.length) return;
    final next = [...list]..removeAt(index);
    state = {...state, exerciseId: List.unmodifiable(next)};
  }

  void updateWeight(String exerciseId, int index, double? kg) => _mutate(
    exerciseId,
    index,
    (d) => SetDraft(
      id: d.id,
      weightKg: kg,
      reps: d.reps,
      isChecked: d.isChecked,
      persistedSetId: d.persistedSetId,
    ),
  );

  void updateReps(String exerciseId, int index, int? reps) => _mutate(
    exerciseId,
    index,
    (d) => SetDraft(
      id: d.id,
      weightKg: d.weightKg,
      reps: reps,
      isChecked: d.isChecked,
      persistedSetId: d.persistedSetId,
    ),
  );

  /// Marks the draft as checked and records the SQLite row ID it was
  /// persisted to.  Must be called after [WorkoutNotifier.logSet] succeeds.
  void checkSet(String exerciseId, int index, String persistedSetId) => _mutate(
    exerciseId,
    index,
    (d) => SetDraft(
      id: d.id,
      weightKg: d.weightKg,
      reps: d.reps,
      isChecked: true,
      persistedSetId: persistedSetId,
    ),
  );

  /// Removes the checked state and clears the persisted set ID.
  /// Must be called after [WorkoutNotifier.deleteSet] succeeds (or is fired).
  void uncheckSet(String exerciseId, int index) => _mutate(
    exerciseId,
    index,
    (d) => SetDraft(
      id: d.id,
      weightKg: d.weightKg,
      reps: d.reps,
      isChecked: false,
      persistedSetId: null,
    ),
  );

  void _mutate(String exerciseId, int index, SetDraft Function(SetDraft) fn) {
    final list = state[exerciseId];
    if (list == null || index < 0 || index >= list.length) return;
    final next = [...list]..[index] = fn(list[index]);
    state = {...state, exerciseId: List.unmodifiable(next)};
  }

  void clear() => state = const {};
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final workoutDraftsProvider =
    StateNotifierProvider<WorkoutDraftsNotifier, Map<String, List<SetDraft>>>((
      ref,
    ) {
      final notifier = WorkoutDraftsNotifier();
      // Auto-clear when the workout ends (finish OR discard from any screen).
      ref.listen<WorkoutState>(workoutProvider, (_, next) {
        if (next is WorkoutIdle) notifier.clear();
      });
      return notifier;
    });
