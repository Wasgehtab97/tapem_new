import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/sync_service.dart';
import '../../../../data/datasources/local/app_database.dart';
import '../../../../domain/entities/gym/exercise_template.dart';
import '../../../../domain/entities/gym/gym_equipment.dart';
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

double _readDouble(_JsonMap row, String key, {double fallback = 0}) {
  final value = row[key];
  if (value is num) return value.toDouble();
  return fallback;
}

// ─── Equipment ────────────────────────────────────────────────────────────────

final gymEquipmentProvider = FutureProvider.family<List<GymEquipment>, String>((
  ref,
  gymId,
) async {
  final db = ref.watch(appDatabaseProvider);
  final client = ref.watch(supabaseClientProvider);

  // Try local cache first
  final cached = await db.getEquipmentForGym(gymId);
  if (cached.isNotEmpty) {
    _refreshEquipmentCache(ref, gymId, db, client); // async refresh
    return cached.map(_localToEquipment).toList();
  }

  // Fetch from server
  return _fetchAndCacheEquipment(gymId, db, client);
});

Future<List<GymEquipment>> _fetchAndCacheEquipment(
  String gymId,
  AppDatabase db,
  SupabaseClient client,
) async {
  final rows = _asJsonRows(
    await client
        .from('gym_equipment')
        .select()
        .eq('gym_id', gymId)
        .eq('is_active', true)
        .order('name'),
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
          isActive: true,
          createdAt: DateTime.now(),
        ),
      )
      .toList();
}

void _refreshEquipmentCache(
  Ref ref,
  String gymId,
  AppDatabase db,
  SupabaseClient client,
) {
  unawaited(
    Future.microtask(() async {
      try {
        await _fetchAndCacheEquipment(gymId, db, client);
        ref.invalidate(gymEquipmentProvider(gymId));
      } catch (_) {}
    }),
  );
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

// ─── NFC tag resolution ───────────────────────────────────────────────────────

final nfcEquipmentProvider =
    FutureProvider.family<GymEquipment?, ({String gymId, String tagUid})>((
      ref,
      args,
    ) async {
      final db = ref.watch(appDatabaseProvider);
      final local = await db.getEquipmentByNfc(args.gymId, args.tagUid);
      if (local != null) return _localToEquipment(local);

      // Refresh cache and retry once
      final client = ref.watch(supabaseClientProvider);
      await _fetchAndCacheEquipment(args.gymId, db, client);
      final retry = await db.getEquipmentByNfc(args.gymId, args.tagUid);
      return retry != null ? _localToEquipment(retry) : null;
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
  final rows = _asJsonRows(
    await client
        .from('exercise_templates')
        .select('*, muscle_group_weights(*)')
        .eq('gym_id', gymId)
        .eq('is_active', true),
  );

  final companions = rows.map((r) {
    final weightRows = _asJsonRows(r['muscle_group_weights']);
    final weights = weightRows
        .map(
          (w) => {
            'g': _readString(w, 'muscle_group'),
            'w': _readDouble(w, 'weight'),
          },
        )
        .toList(growable: false);

    return LocalExerciseTemplatesCompanion.insert(
      key: _readString(r, 'key'),
      gymId: _readString(r, 'gym_id'),
      name: _readString(r, 'name'),
      isRankingEligible: Value(_readBool(r, 'is_ranking_eligible')),
      primaryMuscleGroup: Value(r['primary_muscle_group'] as String?),
      muscleGroupWeightsJson: Value(jsonEncode(weights)),
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
  unawaited(
    Future.microtask(() async {
      try {
        await _fetchAndCacheTemplates(gymId, db, client);
        ref.invalidate(exerciseTemplatesProvider(gymId));
      } catch (_) {}
    }),
  );
}

ExerciseTemplate _localToTemplate(LocalExerciseTemplate r) {
  final weights = (jsonDecode(r.muscleGroupWeightsJson) as List).map((w) {
    final weight = _asJsonMap(w);
    return MuscleGroupWeight(
      muscleGroup: _readString(weight, 'g'),
      weight: _readDouble(weight, 'w'),
    );
  }).toList();

  return ExerciseTemplate(
    key: r.key,
    gymId: r.gymId,
    name: r.name,
    isRankingEligible: r.isRankingEligible,
    muscleGroupWeights: weights,
    primaryMuscleGroup: r.primaryMuscleGroup,
    isActive: r.isActive,
    createdAt: r.cachedAt,
  );
}

ExerciseTemplate _rowToTemplate(_JsonMap r) {
  final weights = _asJsonRows(r['muscle_group_weights'])
      .map(
        (w) => MuscleGroupWeight(
          muscleGroup: _readString(w, 'muscle_group'),
          weight: _readDouble(w, 'weight'),
        ),
      )
      .toList();

  return ExerciseTemplate(
    key: _readString(r, 'key'),
    gymId: _readString(r, 'gym_id'),
    name: _readString(r, 'name'),
    isRankingEligible: _readBool(r, 'is_ranking_eligible'),
    muscleGroupWeights: weights,
    primaryMuscleGroup: r['primary_muscle_group'] as String?,
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
