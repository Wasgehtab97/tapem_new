/// Utility functions for nutrition date keys.
/// DateKey format: yyyyMMdd (lexicographically sortable, timezone-safe).
abstract final class NutritionDateUtils {
  /// Convert a local [DateTime] to a yyyyMMdd dateKey.
  static String toDateKey(DateTime d) {
    final local = d.toLocal();
    return '${local.year.toString().padLeft(4, '0')}'
        '${local.month.toString().padLeft(2, '0')}'
        '${local.day.toString().padLeft(2, '0')}';
  }

  /// Today's dateKey in local time.
  static String today() => toDateKey(DateTime.now());

  /// Normalise to start of local day.
  static DateTime startOfDay(DateTime d) {
    final local = d.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Parse a yyyyMMdd dateKey to a local DateTime (midnight).
  static DateTime? fromDateKey(String key) {
    if (key.length != 8) return null;
    final y = int.tryParse(key.substring(0, 4));
    final m = int.tryParse(key.substring(4, 6));
    final d = int.tryParse(key.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Extract year from dateKey.
  static int yearFromKey(String key) =>
      int.parse(key.substring(0, 4));
}
