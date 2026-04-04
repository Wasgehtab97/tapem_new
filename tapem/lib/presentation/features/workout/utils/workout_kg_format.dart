import 'dart:math' as math;

/// Normalizes workout weight values to a fixed decimal precision to prevent
/// floating-point artifacts from leaking into UI formatting.
double normalizeWorkoutKg(double value, {int decimals = 2}) {
  final factor = math.pow(10, decimals).toDouble();
  return (value * factor).roundToDouble() / factor;
}

/// Formats workout weight with up to 2 decimals (no trailing zeros).
///
/// Examples:
/// - `73` -> `73`
/// - `73.5` -> `73,5` (or `73.5` when [useComma] is false)
/// - `73.75` -> `73,75` (or `73.75` when [useComma] is false)
String formatWorkoutKg(
  double value, {
  bool useComma = true,
  int maxDecimals = 2,
}) {
  final normalized = normalizeWorkoutKg(value, decimals: maxDecimals);
  final fixed = normalized.toStringAsFixed(maxDecimals);
  final trimmed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  return useComma ? trimmed.replaceAll('.', ',') : trimmed;
}

String? formatWorkoutKgNullable(
  double? value, {
  bool useComma = true,
  int maxDecimals = 2,
}) {
  if (value == null) return null;
  return formatWorkoutKg(value, useComma: useComma, maxDecimals: maxDecimals);
}
