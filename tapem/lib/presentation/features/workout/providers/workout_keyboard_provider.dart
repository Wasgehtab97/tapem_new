import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/datasources/local/app_database.dart';
import 'workout_drafts_provider.dart';
import 'workout_provider.dart';

// ─── Field enum ───────────────────────────────────────────────────────────────

enum WorkoutKeyboardField { kg, reps }

// ─── Target model ─────────────────────────────────────────────────────────────

class WorkoutKeyboardTarget {
  const WorkoutKeyboardTarget({
    required this.exerciseId,
    required this.setIndex,
    required this.field,
  });

  final String exerciseId;
  final int setIndex;
  final WorkoutKeyboardField field;

  WorkoutKeyboardTarget copyWith({
    String? exerciseId,
    int? setIndex,
    WorkoutKeyboardField? field,
  }) => WorkoutKeyboardTarget(
    exerciseId: exerciseId ?? this.exerciseId,
    setIndex: setIndex ?? this.setIndex,
    field: field ?? this.field,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutKeyboardTarget &&
          exerciseId == other.exerciseId &&
          setIndex == other.setIndex &&
          field == other.field;

  @override
  int get hashCode => Object.hash(exerciseId, setIndex, field);
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class WorkoutKeyboardNotifier
    extends StateNotifier<WorkoutKeyboardTarget?> {
  WorkoutKeyboardNotifier() : super(null);

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, void Function(String)> _updateCallbacks = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, Future<void> Function()> _checkCallbacks = {};
  final Map<String, List<LocalSetEntry>> _prevSets = {};

  // ── Registration ────────────────────────────────────────────────────────────

  void registerField({
    required String exerciseId,
    required int setIndex,
    required WorkoutKeyboardField field,
    required TextEditingController controller,
    required void Function(String) onUpdate,
    required FocusNode focusNode,
  }) {
    final k = _fkey(exerciseId, setIndex, field);
    _controllers[k] = controller;
    _updateCallbacks[k] = onUpdate;
    _focusNodes[k] = focusNode;
  }

  void unregisterField({
    required String exerciseId,
    required int setIndex,
    required WorkoutKeyboardField field,
  }) {
    final k = _fkey(exerciseId, setIndex, field);
    _controllers.remove(k);
    _updateCallbacks.remove(k);
    _focusNodes.remove(k);
  }

  void registerCheck({
    required String exerciseId,
    required int setIndex,
    required Future<void> Function() callback,
  }) {
    _checkCallbacks['$exerciseId:$setIndex'] = callback;
  }

  void unregisterCheck({required String exerciseId, required int setIndex}) {
    _checkCallbacks.remove('$exerciseId:$setIndex');
  }

  /// Triggers the check/uncheck callback for a given set directly.
  /// Used by the check button widget to avoid duplicating toggle logic.
  Future<void> callCheck({
    required String exerciseId,
    required int setIndex,
  }) async {
    await _toggleCheck(exerciseId, setIndex);
  }

  void setPrevSets(String exerciseId, List<LocalSetEntry> sets) {
    _prevSets[exerciseId] = sets;
  }

  // ── Focus / open / close ────────────────────────────────────────────────────

  void focus(String exerciseId, int setIndex, WorkoutKeyboardField field) {
    state = WorkoutKeyboardTarget(
      exerciseId: exerciseId,
      setIndex: setIndex,
      field: field,
    );
    _focusNodes[_fkey(exerciseId, setIndex, field)]?.requestFocus();
  }

  void close() {
    final t = state;
    if (t == null) return;
    _focusNodes[_fkey(t.exerciseId, t.setIndex, t.field)]?.unfocus();
    state = null;
  }

  // ── Input actions ────────────────────────────────────────────────────────────

  void type(String char) {
    final t = state;
    if (t == null) return;
    // Comma only for kg field and only once
    if (char == ',') {
      if (t.field == WorkoutKeyboardField.reps) return;
      final ctrl = _ctrl(t);
      if (ctrl != null && ctrl.text.contains(',')) return;
    }
    final ctrl = _ctrl(t);
    if (ctrl == null) return;
    final text = ctrl.text;
    final sel = ctrl.selection;
    final pos = (sel.isValid ? sel.baseOffset : text.length).clamp(0, text.length);
    final newText = text.substring(0, pos) + char + text.substring(pos);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + char.length),
    );
    _updateCallbacks[_fkey(t.exerciseId, t.setIndex, t.field)]?.call(newText);
  }

  void delete() {
    final t = state;
    if (t == null) return;
    final ctrl = _ctrl(t);
    if (ctrl == null || ctrl.text.isEmpty) return;
    final text = ctrl.text;
    final sel = ctrl.selection;
    final pos = (sel.isValid ? sel.baseOffset : text.length).clamp(0, text.length);
    if (pos == 0) return;
    final newText = text.substring(0, pos - 1) + text.substring(pos);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos - 1),
    );
    _updateCallbacks[_fkey(t.exerciseId, t.setIndex, t.field)]?.call(newText);
  }

  void increment() {
    final t = state;
    if (t == null) return;
    final ctrl = _ctrl(t);
    if (ctrl == null) return;
    final newText = t.field == WorkoutKeyboardField.kg
        ? _stepKg(ctrl.text, 1.0)
        : _stepReps(ctrl.text, 1);
    _applyText(ctrl, t, newText);
  }

  void decrement() {
    final t = state;
    if (t == null) return;
    final ctrl = _ctrl(t);
    if (ctrl == null) return;
    final newText = t.field == WorkoutKeyboardField.kg
        ? _stepKg(ctrl.text, -1.0)
        : _stepReps(ctrl.text, -1);
    _applyText(ctrl, t, newText);
  }

  void copyFromPrevious(List<SetDraft> drafts) {
    final t = state;
    if (t == null) return;
    final ctrl = _ctrl(t);
    if (ctrl == null) return;

    String? value;

    if (t.setIndex > 0) {
      // Copy from the previous set draft
      final prev = drafts.elementAtOrNull(t.setIndex - 1);
      if (prev != null) {
        value = t.field == WorkoutKeyboardField.kg
            ? _fmtKg(prev.weightKg)
            : prev.reps?.toString();
      }
    } else {
      // Set 0: copy from previous session's first set
      final ps = _prevSets[t.exerciseId] ?? [];
      if (ps.isNotEmpty) {
        value = t.field == WorkoutKeyboardField.kg
            ? _fmtKg(ps.first.weightKg)
            : ps.first.reps?.toString();
      }
    }

    if (value != null) {
      _applyText(ctrl, t, value);
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  Future<void> navigateRight({
    required WorkoutActive workoutState,
    required Map<String, List<SetDraft>> allDrafts,
  }) async {
    final t = state;
    if (t == null) return;

    // kg → reps
    if (t.field == WorkoutKeyboardField.kg) {
      _moveTo(t.copyWith(field: WorkoutKeyboardField.reps));
      return;
    }

    // reps → check current set, then advance
    await _toggleCheck(t.exerciseId, t.setIndex);

    final exercises = workoutState.exercises;
    final eIdx = exercises.indexWhere((e) => e.exercise.id == t.exerciseId);
    if (eIdx == -1) return;

    final eDrafts = allDrafts[t.exerciseId] ?? [];
    if (t.setIndex + 1 < eDrafts.length) {
      _moveTo(WorkoutKeyboardTarget(
        exerciseId: t.exerciseId,
        setIndex: t.setIndex + 1,
        field: WorkoutKeyboardField.kg,
      ));
    } else if (eIdx + 1 < exercises.length) {
      _moveTo(WorkoutKeyboardTarget(
        exerciseId: exercises[eIdx + 1].exercise.id,
        setIndex: 0,
        field: WorkoutKeyboardField.kg,
      ));
    }
    // else: last set of last exercise — do nothing
  }

  Future<void> navigateLeft({
    required WorkoutActive workoutState,
    required Map<String, List<SetDraft>> allDrafts,
  }) async {
    final t = state;
    if (t == null) return;

    // reps → kg (same set)
    if (t.field == WorkoutKeyboardField.reps) {
      _moveTo(t.copyWith(field: WorkoutKeyboardField.kg));
      return;
    }

    // kg → previous set's reps (or previous exercise's last set's reps)
    final exercises = workoutState.exercises;
    final eIdx = exercises.indexWhere((e) => e.exercise.id == t.exerciseId);
    if (eIdx == -1) return;

    if (t.setIndex > 0) {
      final prevIdx = t.setIndex - 1;
      final prevDraft =
          (allDrafts[t.exerciseId] ?? []).elementAtOrNull(prevIdx);
      if (prevDraft?.isChecked == true) {
        await _toggleCheck(t.exerciseId, prevIdx);
      }
      _moveTo(WorkoutKeyboardTarget(
        exerciseId: t.exerciseId,
        setIndex: prevIdx,
        field: WorkoutKeyboardField.reps,
      ));
    } else if (eIdx > 0) {
      final prevExercise = exercises[eIdx - 1];
      final prevDrafts = allDrafts[prevExercise.exercise.id] ?? [];
      if (prevDrafts.isEmpty) return;
      final lastIdx = prevDrafts.length - 1;
      if (prevDrafts[lastIdx].isChecked) {
        await _toggleCheck(prevExercise.exercise.id, lastIdx);
      }
      _moveTo(WorkoutKeyboardTarget(
        exerciseId: prevExercise.exercise.id,
        setIndex: lastIdx,
        field: WorkoutKeyboardField.reps,
      ));
    }
    // else: first field of first exercise — do nothing
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  Future<void> _toggleCheck(String exerciseId, int setIndex) async {
    final cb = _checkCallbacks['$exerciseId:$setIndex'];
    if (cb != null) await cb();
  }

  void _moveTo(WorkoutKeyboardTarget target) {
    state = target;
    _focusNodes[_fkey(target.exerciseId, target.setIndex, target.field)]
        ?.requestFocus();
  }

  TextEditingController? _ctrl(WorkoutKeyboardTarget t) =>
      _controllers[_fkey(t.exerciseId, t.setIndex, t.field)];

  void _applyText(
    TextEditingController ctrl,
    WorkoutKeyboardTarget t,
    String newText,
  ) {
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _updateCallbacks[_fkey(t.exerciseId, t.setIndex, t.field)]?.call(newText);
  }

  static String _stepKg(String text, double delta) {
    final v =
        (double.tryParse(text.replaceAll(',', '.')) ?? 0.0) + delta;
    final c = v.clamp(0.0, 9999.0);
    return c % 1 == 0 ? '${c.toInt()}' : c.toStringAsFixed(1);
  }

  static String _stepReps(String text, int delta) {
    final v = ((int.tryParse(text) ?? 0) + delta).clamp(0, 9999);
    return '$v';
  }

  static String? _fmtKg(double? v) {
    if (v == null) return null;
    return v % 1 == 0 ? '${v.toInt()}' : v.toStringAsFixed(1);
  }

  static String _fkey(
          String exerciseId, int setIndex, WorkoutKeyboardField field) =>
      '$exerciseId:$setIndex:${field.name}';
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final workoutKeyboardProvider = StateNotifierProvider.autoDispose<
    WorkoutKeyboardNotifier, WorkoutKeyboardTarget?>(
  (ref) => WorkoutKeyboardNotifier(),
);
