import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../../domain/entities/gym/exercise_muscle_group.dart';
import '../../../../domain/entities/gym/exercise_template.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
import '../../../../domain/entities/gym/muscle_group.dart';
import '../../../../domain/entities/gym/muscle_group_role.dart';
import '../../../features/auth/providers/auth_provider.dart';

typedef _JsonMap = Map<String, Object?>;

List<_JsonMap> _asJsonRows(Object? response) {
  if (response is! List) return const [];
  return response
      .whereType<Map<dynamic, dynamic>>()
      .map((row) => Map<String, Object?>.from(row))
      .toList(growable: false);
}

_JsonMap _asJsonMap(Object? value) {
  if (value is Map<dynamic, dynamic>) {
    return Map<String, Object?>.from(value);
  }
  return <String, Object?>{};
}

String _readString(_JsonMap row, String key, {String fallback = ''}) =>
    row[key] as String? ?? fallback;

bool _readBool(_JsonMap row, String key, {bool fallback = false}) =>
    row[key] as bool? ?? fallback;

const kEquipmentAliasMaxLength = 80;
const _aliasOverrideTableName = 'user_equipment_name_overrides';
const _aliasSyncBackoffWhenTableMissing = Duration(minutes: 3);
DateTime? _aliasSyncPausedUntil;
const _equipmentBackgroundRefreshInterval = Duration(minutes: 5);
const _templateBackgroundRefreshInterval = Duration(minutes: 5);
final _equipmentRefreshInFlight = <String>{};
final _templateRefreshInFlight = <String>{};
final _equipmentLastBackgroundRefreshAt = <String, DateTime>{};
final _templateLastBackgroundRefreshAt = <String, DateTime>{};

bool _isAliasSyncPaused() {
  final until = _aliasSyncPausedUntil;
  if (until == null) return false;
  return DateTime.now().isBefore(until);
}

bool _isAliasTableMissingError(Object error) {
  final serialized = error.toString().toLowerCase();
  if (serialized.contains('pgrst205') &&
      serialized.contains(_aliasOverrideTableName)) {
    return true;
  }

  if (error is! PostgrestException) return false;

  final code = (error.code ?? '').toString().toUpperCase();
  if (code == 'PGRST205') return true;

  final message = error.message.toLowerCase();
  final details = (error.details ?? '').toString().toLowerCase();
  final hint = (error.hint ?? '').toString().toLowerCase();
  final blob = '$message $details $hint';
  return blob.contains('could not find the table') &&
      blob.contains(_aliasOverrideTableName);
}

void _pauseAliasSyncForMissingTable(Object error, StackTrace? stackTrace) {
  final wasPaused = _isAliasSyncPaused();
  _aliasSyncPausedUntil = DateTime.now().add(_aliasSyncBackoffWhenTableMissing);
  if (!wasPaused) {
    AppLogger.w(
      '[equipment] alias table missing in Supabase; pausing alias sync for ${_aliasSyncBackoffWhenTableMissing.inMinutes}m. Apply migration 00070_user_equipment_name_overrides.sql.',
      error,
      stackTrace,
    );
  }
}

String _normalizeQuery(String query) => query.trim().toLowerCase();

bool equipmentMatchesSearchQuery(GymEquipment equipment, String query) {
  final q = _normalizeQuery(query);
  if (q.isEmpty) return true;
  return equipment.displayName.toLowerCase().contains(q) ||
      equipment.name.toLowerCase().contains(q) ||
      (equipment.manufacturer?.toLowerCase().contains(q) ?? false);
}

bool _beginBackgroundRefresh({
  required String key,
  required Set<String> inFlight,
  required Map<String, DateTime> lastRefreshAt,
  required Duration interval,
}) {
  if (inFlight.contains(key)) return false;
  final last = lastRefreshAt[key];
  if (last != null && DateTime.now().difference(last) < interval) return false;
  inFlight.add(key);
  return true;
}

void _finishBackgroundRefresh({
  required String key,
  required Set<String> inFlight,
  required Map<String, DateTime> lastRefreshAt,
}) {
  inFlight.remove(key);
  lastRefreshAt[key] = DateTime.now();
}

// ─── Equipment ────────────────────────────────────────────────────────────────

final gymEquipmentProvider = FutureProvider.family<List<GymEquipment>, String>((
  ref,
  gymId,
) async {
  final db = ref.watch(appDatabaseProvider);
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserProvider)?.id;

  final localOverrides = userId == null
      ? const <LocalEquipmentNameOverride>[]
      : await db.getEquipmentNameOverrides(userId, gymId);

  // Try local cache first.
  final cached = await db.getEquipmentForGym(gymId);
  if (cached.isNotEmpty) {
    _refreshEquipmentCache(
      ref: ref,
      gymId: gymId,
      userId: userId,
      db: db,
      client: client,
    ); // async refresh
    return applyEquipmentNameOverrides(
      cached.map(_localToEquipment).toList(),
      localOverrides,
    );
  }

  // Cache miss: fetch equipment first.
  final canonical = await _fetchAndCacheEquipment(gymId, db, client);
  if (userId == null) return canonical;

  // Best-effort alias refresh. Never block rendering on failures.
  try {
    await _refreshEquipmentNameOverridesCache(
      gymId: gymId,
      userId: userId,
      db: db,
      client: client,
    );
  } catch (e, st) {
    AppLogger.e('[equipment] alias refresh failed', e, st);
  }
  final refreshedOverrides = await db.getEquipmentNameOverrides(userId, gymId);
  return applyEquipmentNameOverrides(canonical, refreshedOverrides);
});

Future<List<GymEquipment>> _fetchAndCacheEquipment(
  String gymId,
  AppDatabase db,
  SupabaseClient client,
) async {
  final rows = _asJsonRows(
    await client
        .from('gym_equipment')
        .select(
          'id, gym_id, name, equipment_type, zone_name, nfc_tag_uid, '
          'canonical_exercise_key, ranking_eligible_override, manufacturer, '
          'pos_x, pos_y',
        )
        .eq('gym_id', gymId)
        .eq('is_active', true)
        .order('name', ascending: true),
  );

  final companions = rows
      .map(
        (r) => LocalGymEquipmentCompanion.insert(
          id: _readString(r, 'id'),
          gymId: _readString(r, 'gym_id'),
          name: _readString(r, 'name'),
          equipmentType: _readString(r, 'equipment_type'),
          zoneName: _readString(r, 'zone_name'),
          nfcTagUid: Value(r['nfc_tag_uid'] as String?),
          canonicalExerciseKey: Value(r['canonical_exercise_key'] as String?),
          rankingEligibleOverride: Value(
            r['ranking_eligible_override'] as bool?,
          ),
          manufacturer: Value(r['manufacturer'] as String?),
          posX: Value((r['pos_x'] as num?)?.toDouble()),
          posY: Value((r['pos_y'] as num?)?.toDouble()),
        ),
      )
      .toList();

  await db.upsertEquipment(companions);
  return companions
      .map(
        (c) => GymEquipment(
          id: c.id.value,
          gymId: c.gymId.value,
          name: c.name.value,
          equipmentType: EquipmentType.fromValue(c.equipmentType.value),
          zoneName: c.zoneName.value,
          nfcTagUid: c.nfcTagUid.value,
          canonicalExerciseKey: c.canonicalExerciseKey.value,
          rankingEligibleOverride: c.rankingEligibleOverride.value,
          manufacturer: c.manufacturer.value,
          posX: c.posX.value,
          posY: c.posY.value,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      )
      .toList();
}

void _refreshEquipmentCache({
  required Ref ref,
  required String gymId,
  required String? userId,
  required AppDatabase db,
  required SupabaseClient client,
}) {
  if (!_beginBackgroundRefresh(
    key: gymId,
    inFlight: _equipmentRefreshInFlight,
    lastRefreshAt: _equipmentLastBackgroundRefreshAt,
    interval: _equipmentBackgroundRefreshInterval,
  )) {
    return;
  }

  unawaited(
    Future.microtask(() async {
      try {
        await _fetchAndCacheEquipment(gymId, db, client);
        if (userId != null) {
          await _refreshEquipmentNameOverridesCache(
            gymId: gymId,
            userId: userId,
            db: db,
            client: client,
          );
        }
        ref.invalidateSelf();
      } catch (e, st) {
        AppLogger.e('[equipment] cache refresh failed', e, st);
      } finally {
        _finishBackgroundRefresh(
          key: gymId,
          inFlight: _equipmentRefreshInFlight,
          lastRefreshAt: _equipmentLastBackgroundRefreshAt,
        );
      }
    }),
  );
}

List<GymEquipment> applyEquipmentNameOverrides(
  List<GymEquipment> equipment,
  List<LocalEquipmentNameOverride> overrides,
) {
  if (equipment.isEmpty || overrides.isEmpty) return equipment;
  final aliasByEquipmentId = <String, String>{
    for (final row in overrides)
      if (!row.isDeleted) row.equipmentId: row.displayName,
  };
  return applyEquipmentAliasMap(equipment, aliasByEquipmentId);
}

List<GymEquipment> applyEquipmentAliasMap(
  List<GymEquipment> equipment,
  Map<String, String> aliasByEquipmentId,
) {
  if (equipment.isEmpty || aliasByEquipmentId.isEmpty) return equipment;
  return equipment
      .map((e) {
        final alias = aliasByEquipmentId[e.id];
        if (alias == null) return e;
        return GymEquipment(
          id: e.id,
          gymId: e.gymId,
          name: e.name,
          personalDisplayName: alias,
          hasPersonalNameOverride: true,
          equipmentType: e.equipmentType,
          zoneName: e.zoneName,
          nfcTagUid: e.nfcTagUid,
          canonicalExerciseKey: e.canonicalExerciseKey,
          rankingEligibleOverride: e.rankingEligibleOverride,
          manufacturer: e.manufacturer,
          model: e.model,
          catalogId: e.catalogId,
          equipmentExternalId: e.equipmentExternalId,
          posX: e.posX,
          posY: e.posY,
          isActive: e.isActive,
          createdAt: e.createdAt,
        );
      })
      .toList(growable: false);
}

Future<void> _refreshEquipmentNameOverridesCache({
  required String gymId,
  required String userId,
  required AppDatabase db,
  required SupabaseClient client,
}) async {
  if (_isAliasSyncPaused()) return;

  await _syncPendingEquipmentNameOverrides(
    gymId: gymId,
    userId: userId,
    db: db,
    client: client,
  );
  if (_isAliasSyncPaused()) return;

  late final List<_JsonMap> rows;
  try {
    rows = _asJsonRows(
      await client
          .from('user_equipment_name_overrides')
          .select(
            'user_id, gym_id, equipment_id, display_name, created_at, updated_at',
          )
          .eq('user_id', userId)
          .eq('gym_id', gymId),
    );
  } catch (e, st) {
    if (_isAliasTableMissingError(e)) {
      _pauseAliasSyncForMissingTable(e, st);
      return;
    }
    rethrow;
  }

  final remoteEquipmentIds = <String>{};
  for (final row in rows) {
    final equipmentId = _readString(row, 'equipment_id');
    if (equipmentId.isEmpty) continue;
    remoteEquipmentIds.add(equipmentId);

    final displayName = _readString(row, 'display_name');
    final remoteUpdatedAt = DateTime.tryParse(_readString(row, 'updated_at'));
    final remoteCreatedAt = DateTime.tryParse(_readString(row, 'created_at'));
    final local = await db.getEquipmentNameOverride(userId, equipmentId);

    // Keep newer local pending/sync_failed edits over stale remote snapshots.
    if (local != null &&
        local.syncStatus != 'sync_confirmed' &&
        remoteUpdatedAt != null &&
        local.updatedAt.isAfter(remoteUpdatedAt)) {
      continue;
    }

    await db.markEquipmentNameOverrideSynced(
      userId,
      equipmentId,
      displayName: displayName,
      createdAt: remoteCreatedAt ?? DateTime.now(),
      updatedAt: remoteUpdatedAt ?? DateTime.now(),
      gymId: gymId,
    );
  }

  await db.pruneSyncedEquipmentNameOverridesNotIn(
    userId,
    gymId,
    remoteEquipmentIds,
  );
}

Future<void> _syncPendingEquipmentNameOverrides({
  required String gymId,
  required String userId,
  required AppDatabase db,
  required SupabaseClient client,
}) async {
  if (_isAliasSyncPaused()) return;

  final pending = await db.getPendingEquipmentNameOverrides(userId, gymId);
  for (final local in pending) {
    try {
      if (local.isDeleted) {
        await client
            .from('user_equipment_name_overrides')
            .delete()
            .eq('user_id', userId)
            .eq('gym_id', gymId)
            .eq('equipment_id', local.equipmentId);
        await db.deleteEquipmentNameOverride(userId, local.equipmentId);
        continue;
      }

      final upserted = _asJsonMap(
        await client
            .from('user_equipment_name_overrides')
            .upsert({
              'user_id': userId,
              'gym_id': gymId,
              'equipment_id': local.equipmentId,
              'display_name': local.displayName,
              'updated_at': local.updatedAt.toUtc().toIso8601String(),
            }, onConflict: 'user_id,equipment_id')
            .select('created_at, updated_at')
            .maybeSingle(),
      );

      await db.markEquipmentNameOverrideSynced(
        userId,
        local.equipmentId,
        displayName: local.displayName,
        createdAt:
            DateTime.tryParse(_readString(upserted, 'created_at')) ??
            local.createdAt,
        updatedAt:
            DateTime.tryParse(_readString(upserted, 'updated_at')) ??
            local.updatedAt,
        gymId: gymId,
      );
    } catch (e, st) {
      if (_isAliasTableMissingError(e)) {
        _pauseAliasSyncForMissingTable(e, st);
        return;
      }
      AppLogger.e(
        '[equipment] alias sync failed for ${local.equipmentId}',
        e,
        st,
      );
      await db.markEquipmentNameOverrideSyncFailed(userId, local.equipmentId);
    }
  }
}

GymEquipment _localToEquipment(LocalGymEquipmentData r) => GymEquipment(
  id: r.id,
  gymId: r.gymId,
  name: r.name,
  equipmentType: EquipmentType.fromValue(r.equipmentType),
  zoneName: r.zoneName.isEmpty ? null : r.zoneName,
  nfcTagUid: r.nfcTagUid,
  canonicalExerciseKey: r.canonicalExerciseKey,
  rankingEligibleOverride: r.rankingEligibleOverride,
  manufacturer: r.manufacturer,
  posX: r.posX,
  posY: r.posY,
  isActive: r.isActive,
  createdAt: r.cachedAt,
);

// ─── Equipment filtered by type ───────────────────────────────────────────────

final equipmentByTypeProvider =
    FutureProvider.family<
      List<GymEquipment>,
      ({String gymId, EquipmentType type})
    >((ref, args) async {
      final all = await ref.watch(gymEquipmentProvider(args.gymId).future);
      return all.where((e) => e.equipmentType == args.type).toList()
        ..sort((a, b) => (a.zoneName ?? '').compareTo(b.zoneName ?? ''));
    });

class EquipmentNameOverrideService {
  EquipmentNameOverrideService(this._ref);

  final Ref _ref;

  Future<void> setPersonalName({
    required String gymId,
    required String equipmentId,
    required String displayName,
  }) async {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Display name cannot be empty.');
    }
    if (trimmed.length > kEquipmentAliasMaxLength) {
      throw ArgumentError(
        'Display name must be <= $kEquipmentAliasMaxLength characters.',
      );
    }

    final db = _ref.read(appDatabaseProvider);
    final client = _ref.read(supabaseClientProvider);
    final now = DateTime.now();

    await db.setEquipmentNameOverrideLocal(
      userId: userId,
      gymId: gymId,
      equipmentId: equipmentId,
      displayName: trimmed,
      updatedAt: now,
    );
    _ref.invalidate(gymEquipmentProvider(gymId));

    unawaited(
      Future<void>(() async {
        try {
          await _syncPendingEquipmentNameOverrides(
            gymId: gymId,
            userId: userId,
            db: db,
            client: client,
          );
          await _refreshEquipmentNameOverridesCache(
            gymId: gymId,
            userId: userId,
            db: db,
            client: client,
          );
        } catch (e, st) {
          AppLogger.e('[equipment] set alias sync failed', e, st);
        } finally {
          _ref.invalidate(gymEquipmentProvider(gymId));
        }
      }),
    );
  }

  Future<void> resetToCanonical({
    required String gymId,
    required String equipmentId,
  }) async {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final db = _ref.read(appDatabaseProvider);
    final client = _ref.read(supabaseClientProvider);
    final now = DateTime.now();

    await db.markEquipmentNameOverrideDeletedLocal(
      userId: userId,
      gymId: gymId,
      equipmentId: equipmentId,
      updatedAt: now,
    );
    _ref.invalidate(gymEquipmentProvider(gymId));

    unawaited(
      Future<void>(() async {
        try {
          await _syncPendingEquipmentNameOverrides(
            gymId: gymId,
            userId: userId,
            db: db,
            client: client,
          );
          await _refreshEquipmentNameOverridesCache(
            gymId: gymId,
            userId: userId,
            db: db,
            client: client,
          );
        } catch (e, st) {
          AppLogger.e('[equipment] reset alias sync failed', e, st);
        } finally {
          _ref.invalidate(gymEquipmentProvider(gymId));
        }
      }),
    );
  }
}

final equipmentNameOverrideServiceProvider =
    Provider<EquipmentNameOverrideService>(
      (ref) => EquipmentNameOverrideService(ref),
    );

// ─── NFC tag resolution ───────────────────────────────────────────────────────

final nfcEquipmentProvider =
    FutureProvider.family<GymEquipment?, ({String gymId, String tagUid})>((
      ref,
      args,
    ) async {
      final db = ref.watch(appDatabaseProvider);
      final userId = ref.watch(currentUserProvider)?.id;
      final local = await db.getEquipmentByNfc(args.gymId, args.tagUid);
      if (local != null) {
        final equipment = _localToEquipment(local);
        if (userId == null) return equipment;
        final overrides = await db.getEquipmentNameOverrides(
          userId,
          args.gymId,
        );
        return applyEquipmentNameOverrides([equipment], overrides).firstOrNull;
      }

      // Refresh cache and retry once
      final client = ref.watch(supabaseClientProvider);
      await _fetchAndCacheEquipment(args.gymId, db, client);
      final retry = await db.getEquipmentByNfc(args.gymId, args.tagUid);
      if (retry == null) return null;
      final equipment = _localToEquipment(retry);
      if (userId == null) return equipment;
      final overrides = await db.getEquipmentNameOverrides(userId, args.gymId);
      return applyEquipmentNameOverrides([equipment], overrides).firstOrNull;
    });

// ─── Exercise templates ───────────────────────────────────────────────────────

final exerciseTemplatesProvider =
    FutureProvider.family<List<ExerciseTemplate>, String>((ref, gymId) async {
      final db = ref.watch(appDatabaseProvider);
      final client = ref.watch(supabaseClientProvider);

      final cached = await db.getTemplatesForGym(gymId);
      if (cached.isNotEmpty) {
        _refreshTemplateCache(ref, gymId, db, client);
        return cached.map(_localToTemplate).toList();
      }

      return _fetchAndCacheTemplates(gymId, db, client);
    });

Future<List<ExerciseTemplate>> _fetchAndCacheTemplates(
  String gymId,
  AppDatabase db,
  SupabaseClient client,
) async {
  // Fetch exercise_templates joined with their muscle group assignments.
  // exercise_muscle_groups replaces the old muscle_group_weights table.
  final rows = _asJsonRows(
    await client
        .from('exercise_templates')
        .select(
          'key, gym_id, name, is_ranking_eligible, primary_muscle_group, '
          'is_active, created_at, '
          'exercise_muscle_groups(muscle_group, role)',
        )
        .eq('gym_id', gymId)
        .eq('is_active', true),
  );

  final companions = rows.map((r) {
    final mgRows = _asJsonRows(r['exercise_muscle_groups']);
    final groups = mgRows
        .map(
          (w) => {
            'g': _readString(w, 'muscle_group'),
            'r': _readString(w, 'role'),
          },
        )
        .toList(growable: false);

    return LocalExerciseTemplatesCompanion.insert(
      key: _readString(r, 'key'),
      gymId: _readString(r, 'gym_id'),
      name: _readString(r, 'name'),
      isRankingEligible: Value(_readBool(r, 'is_ranking_eligible')),
      primaryMuscleGroup: Value(r['primary_muscle_group'] as String?),
      muscleGroupsJson: Value(jsonEncode(groups)),
    );
  }).toList();

  await db.upsertTemplates(companions);
  return rows.map((r) => _rowToTemplate(r)).toList();
}

void _refreshTemplateCache(
  Ref ref,
  String gymId,
  AppDatabase db,
  SupabaseClient client,
) {
  if (!_beginBackgroundRefresh(
    key: gymId,
    inFlight: _templateRefreshInFlight,
    lastRefreshAt: _templateLastBackgroundRefreshAt,
    interval: _templateBackgroundRefreshInterval,
  )) {
    return;
  }

  unawaited(
    Future.microtask(() async {
      try {
        await _fetchAndCacheTemplates(gymId, db, client);
        ref.invalidate(exerciseTemplatesProvider(gymId));
      } catch (_) {
      } finally {
        _finishBackgroundRefresh(
          key: gymId,
          inFlight: _templateRefreshInFlight,
          lastRefreshAt: _templateLastBackgroundRefreshAt,
        );
      }
    }),
  );
}

ExerciseTemplate _localToTemplate(LocalExerciseTemplate r) {
  final groups = (jsonDecode(r.muscleGroupsJson) as List)
      .map((w) => ExerciseMuscleGroup.fromJson(_asJsonMap(w)))
      .where((mg) => MuscleGroup.tryFromValue(mg.muscleGroup.value) != null)
      .toList();

  return ExerciseTemplate(
    key: r.key,
    gymId: r.gymId,
    name: r.name,
    isRankingEligible: r.isRankingEligible,
    muscleGroups: groups,
    isActive: r.isActive,
    createdAt: r.cachedAt,
  );
}

ExerciseTemplate _rowToTemplate(_JsonMap r) {
  final groups = _asJsonRows(r['exercise_muscle_groups'])
      .map((w) {
        final group = MuscleGroup.tryFromValue(_readString(w, 'muscle_group'));
        if (group == null) return null;
        return ExerciseMuscleGroup(
          muscleGroup: group,
          role: MuscleGroupRole.fromValue(_readString(w, 'role')),
        );
      })
      .whereType<ExerciseMuscleGroup>()
      .toList();

  return ExerciseTemplate(
    key: _readString(r, 'key'),
    gymId: _readString(r, 'gym_id'),
    name: _readString(r, 'name'),
    isRankingEligible: _readBool(r, 'is_ranking_eligible'),
    muscleGroups: groups,
    isActive: _readBool(r, 'is_active', fallback: true),
    createdAt: DateTime.parse(_readString(r, 'created_at')),
  );
}

// ─── Equipment favourites ─────────────────────────────────────────────────────

final favouriteEquipmentIdsProvider =
    FutureProvider.family<Set<String>, ({String userId, String gymId})>((
      ref,
      args,
    ) async {
      final db = ref.watch(appDatabaseProvider);
      return db.getFavouriteEquipmentIds(args.userId, args.gymId);
    });

// ─── User custom exercises ────────────────────────────────────────────────────

final userCustomExercisesProvider =
    FutureProvider.family<
      List<LocalUserCustomExercise>,
      ({String gymId, String userId})
    >((ref, args) async {
      final db = ref.watch(appDatabaseProvider);
      return db.getCustomExercises(args.gymId, args.userId);
    });

// ─── Equipment lookup by ID ───────────────────────────────────────────────────

/// Resolves a single [GymEquipment] by its UUID, using the local cache.
/// Falls back to a server refresh if not found locally.
final equipmentByIdProvider =
    FutureProvider.family<GymEquipment?, ({String gymId, String equipmentId})>((
      ref,
      args,
    ) async {
      final all = await ref.watch(gymEquipmentProvider(args.gymId).future);
      final found = all.where((e) => e.id == args.equipmentId).firstOrNull;
      if (found != null) return found;

      // Not in cache — force a refresh and retry once.
      ref.invalidate(gymEquipmentProvider(args.gymId));
      final refreshed = await ref.read(gymEquipmentProvider(args.gymId).future);
      return refreshed.where((e) => e.id == args.equipmentId).firstOrNull;
    });
