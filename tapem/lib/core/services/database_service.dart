import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/app_database.dart';

/// Canonical provider for the local Drift database.
///
/// Extracted into its own file so that [sync_service.dart] can import
/// [xp_provider.dart] (for post-sync invalidation) without creating a circular
/// dependency.  All other files that previously obtained [appDatabaseProvider]
/// via [sync_service.dart] continue to work because [sync_service.dart]
/// re-exports this symbol.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
