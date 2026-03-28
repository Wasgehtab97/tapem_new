import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

/// Cached gym equipment — refreshed from server per gym.
class LocalGymEquipment extends Table {
  TextColumn get id => text()();
  TextColumn get gymId => text()();
  TextColumn get name => text()();
  TextColumn get equipmentType =>
      text()(); // 'fixed_machine'|'open_station'|'cardio'
  TextColumn get zoneName => text()();
  TextColumn get nfcTagUid => text().nullable()();
  TextColumn get canonicalExerciseKey => text().nullable()();
  BoolColumn get rankingEligibleOverride => boolean().nullable()();
  TextColumn get manufacturer => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached exercise templates — refreshed from server per gym.
class LocalExerciseTemplates extends Table {
  TextColumn get key => text()();
  TextColumn get gymId => text()();
  TextColumn get name => text()();
  BoolColumn get isRankingEligible =>
      boolean().withDefault(const Constant(false))();
  TextColumn get primaryMuscleGroup => text().nullable()();
  // Muscle group assignments serialized as JSON: [{"g":"chest","r":"primary"},...]
  // Legacy format [{"g":"chest","w":0.7},...] is accepted during migration.
  TextColumn get muscleGroupsJson =>
      text().withDefault(const Constant('[]'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key, gymId};
}

/// Muscle group assignments for user-created open-station exercises.
/// Stored locally, synced to [user_custom_exercise_muscle_groups] on the server.
class LocalUserCustomExerciseMuscleGroups extends Table {
  TextColumn get customExerciseId => text()(); // FK → LocalUserCustomExercises.id
  TextColumn get muscleGroup => text()();       // MuscleGroup.value
  TextColumn get role => text()();              // 'primary' | 'secondary'

  @override
  Set<Column> get primaryKey => {customExerciseId, muscleGroup};
}

/// User's custom exercises — stored locally, synced to server.
class LocalUserCustomExercises extends Table {
  TextColumn get id => text()();
  TextColumn get gymId => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get equipmentId => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('local_saved'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local workout sessions — primary write target during a workout.
class LocalWorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get gymId => text()();
  TextColumn get userId => text()();
  TextColumn get equipmentId => text()();
  TextColumn get sessionDayAnchor => text()(); // 'yyyy-MM-dd'
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('local_saved'))();
  TextColumn get idempotencyKey => text()();
  TextColumn get notes => text().nullable()();
  // server-assigned id after sync confirmation
  TextColumn get serverSyncedId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local session exercises.
class LocalSessionExercises extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get gymId => text()();
  TextColumn get exerciseKey => text()();
  TextColumn get displayName => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get customExerciseId => text().nullable()();

  /// The gym-equipment ID of the machine/station this exercise was performed
  /// on.  Set when adding the exercise from the gym screen (v3+).
  /// Null for data migrated from before v3 — XP code falls back to exerciseKey.
  TextColumn get equipmentId => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('local_saved'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Member-owned training plans — locally stored, synced to Supabase.
class LocalWorkoutPlans extends Table {
  TextColumn get id => text()();
  TextColumn get gymId => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('local_saved'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Individual exercises within a training plan, ordered by [position].
class LocalPlanItems extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  TextColumn get gymId => text()();
  TextColumn get equipmentId => text()();
  TextColumn get canonicalExerciseKey => text().nullable()();
  TextColumn get customExerciseId => text().nullable()();
  TextColumn get displayName => text()();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-user equipment favourites — stored locally, never synced.
class LocalEquipmentFavourites extends Table {
  TextColumn get userId => text()();
  TextColumn get gymId => text()();
  TextColumn get equipmentId => text()();

  @override
  Set<Column> get primaryKey => {userId, gymId, equipmentId};
}

/// Local set entries — fastest write path (< 150 ms target).
class LocalSetEntries extends Table {
  TextColumn get id => text()();
  TextColumn get sessionExerciseId => text()();
  TextColumn get gymId => text()();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get distanceMeters => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('local_saved'))();
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get idempotencyKey => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    LocalGymEquipment,
    LocalExerciseTemplates,
    LocalUserCustomExercises,
    LocalUserCustomExerciseMuscleGroups,
    LocalWorkoutSessions,
    LocalSessionExercises,
    LocalSetEntries,
    LocalEquipmentFavourites,
    LocalWorkoutPlans,
    LocalPlanItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          localGymEquipment,
          localGymEquipment.manufacturer,
        );
        await migrator.addColumn(
          localUserCustomExercises,
          localUserCustomExercises.equipmentId,
        );
      }
      if (from < 3) {
        // Nullable — existing rows get NULL, which the XP layer handles via
        // exerciseKey fallback for backward-compatibility.
        await migrator.addColumn(
          localSessionExercises,
          localSessionExercises.equipmentId,
        );
      }
      if (from < 4) {
        await migrator.createTable(localEquipmentFavourites);
      }
      if (from < 5) {
        await migrator.createTable(localWorkoutPlans);
        await migrator.createTable(localPlanItems);
      }
      if (from < 6) {
        // Rename muscleGroupWeightsJson → muscleGroupsJson.
        // The legacy format {"g":"…","w":…} is handled gracefully by
        // ExerciseMuscleGroup.fromJson, so no data conversion is needed.
        await migrator.renameColumn(
          localExerciseTemplates,
          'muscle_group_weights_json',
          localExerciseTemplates.muscleGroupsJson,
        );
        // New table for user-assigned muscle groups on custom exercises.
        await migrator.createTable(localUserCustomExerciseMuscleGroups);
      }
    },
  );

  // ─── Equipment ─────────────────────────────────────────────────────────────

  Future<List<LocalGymEquipmentData>> getEquipmentForGym(String gymId) =>
      (select(localGymEquipment)
            ..where((t) => t.gymId.equals(gymId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .get();

  Future<LocalGymEquipmentData?> getEquipmentByNfc(
    String gymId,
    String tagUid,
  ) =>
      (select(localGymEquipment)
            ..where(
              (t) =>
                  t.gymId.equals(gymId) &
                  t.nfcTagUid.equals(tagUid) &
                  t.isActive.equals(true),
            )
            ..limit(1))
          .getSingleOrNull();

  Future<void> upsertEquipment(List<LocalGymEquipmentCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localGymEquipment, rows));

  Future<void> updateNfcTagUid(String equipmentId, String? uid) async {
    await (update(localGymEquipment)..where((t) => t.id.equals(equipmentId)))
        .write(LocalGymEquipmentCompanion(nfcTagUid: Value(uid)));
  }

  // ─── Exercise templates ────────────────────────────────────────────────────

  Future<List<LocalExerciseTemplate>> getTemplatesForGym(String gymId) =>
      (select(
        localExerciseTemplates,
      )..where((t) => t.gymId.equals(gymId) & t.isActive.equals(true))).get();

  Future<void> upsertTemplates(List<LocalExerciseTemplatesCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localExerciseTemplates, rows));

  // ─── Custom exercises ──────────────────────────────────────────────────────

  Future<List<LocalUserCustomExercise>> getCustomExercises(
    String gymId,
    String userId,
  ) =>
      (select(localUserCustomExercises)
            ..where((t) => t.gymId.equals(gymId) & t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<List<LocalUserCustomExercise>> getCustomExercisesForEquipment(
    String gymId,
    String userId,
    String equipmentId,
  ) =>
      (select(localUserCustomExercises)
            ..where(
              (t) =>
                  t.gymId.equals(gymId) &
                  t.userId.equals(userId) &
                  t.equipmentId.equals(equipmentId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<void> insertCustomExercise(LocalUserCustomExercisesCompanion row) =>
      into(localUserCustomExercises).insertOnConflictUpdate(row);

  // ─── Custom exercise muscle groups ────────────────────────────────────────

  Future<List<LocalUserCustomExerciseMuscleGroup>> getCustomExerciseMuscleGroups(
    String customExerciseId,
  ) =>
      (select(localUserCustomExerciseMuscleGroups)
            ..where((t) => t.customExerciseId.equals(customExerciseId)))
          .get();

  /// Replaces all muscle group assignments for [customExerciseId] atomically.
  Future<void> upsertCustomExerciseMuscleGroups(
    String customExerciseId,
    List<LocalUserCustomExerciseMuscleGroupsCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(localUserCustomExerciseMuscleGroups)
            ..where((t) => t.customExerciseId.equals(customExerciseId)))
          .go();
      if (rows.isNotEmpty) {
        await batch((b) => b.insertAll(localUserCustomExerciseMuscleGroups, rows));
      }
    });
  }

  // ─── Sessions ──────────────────────────────────────────────────────────────

  Future<LocalWorkoutSession?> getActiveSession(String gymId, String userId) =>
      (select(localWorkoutSessions)
            ..where(
              (t) =>
                  t.gymId.equals(gymId) &
                  t.userId.equals(userId) &
                  t.finishedAt.isNull(),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Returns ALL unfinished sessions for a user, newest first.
  /// Used during resume to detect and clean up orphan sessions from
  /// previous app runs where multiple active sessions could accumulate.
  Future<List<LocalWorkoutSession>> getAllActiveSessions(
    String gymId,
    String userId,
  ) =>
      (select(localWorkoutSessions)
            ..where(
              (t) =>
                  t.gymId.equals(gymId) &
                  t.userId.equals(userId) &
                  t.finishedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

  /// Returns ALL unfinished sessions for a user across ALL gyms, newest first.
  ///
  /// Used during cold-start resume to sweep orphans left by previously-selected
  /// gyms. Without this, sessions from a gym the user is no longer at would
  /// linger in SQLite indefinitely without ever being synced or discarded.
  Future<List<LocalWorkoutSession>> getAllUnfinishedSessionsForUser(
    String userId,
  ) =>
      (select(localWorkoutSessions)
            ..where((t) => t.userId.equals(userId) & t.finishedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

  /// Deletes every unfinished session (and all their exercises/sets) for a
  /// user in one shot. Used for "discard" so orphan sessions cannot survive.
  Future<void> discardAllActiveSessions(String gymId, String userId) async {
    final sessions = await getAllActiveSessions(gymId, userId);
    for (final s in sessions) {
      await deleteSessionCascade(s.id);
    }
  }

  Stream<LocalWorkoutSession?> watchActiveSession(
    String gymId,
    String userId,
  ) =>
      (select(localWorkoutSessions)
            ..where(
              (t) =>
                  t.gymId.equals(gymId) &
                  t.userId.equals(userId) &
                  t.finishedAt.isNull(),
            )
            ..limit(1))
          .watchSingleOrNull();

  Future<LocalWorkoutSession?> getSessionById(String id) =>
      (select(localWorkoutSessions)
            ..where((t) => t.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<void> insertSession(LocalWorkoutSessionsCompanion row) =>
      into(localWorkoutSessions).insertOnConflictUpdate(row);

  /// Deletes a session and all its exercises + sets in a single transaction.
  /// Used for the "discard workout" flow — no data is kept.
  Future<void> deleteSessionCascade(String sessionId) async {
    await transaction(() async {
      final exercises = await getExercisesForSession(sessionId);
      for (final exercise in exercises) {
        await (delete(
          localSetEntries,
        )..where((t) => t.sessionExerciseId.equals(exercise.id))).go();
      }
      await (delete(
        localSessionExercises,
      )..where((t) => t.sessionId.equals(sessionId))).go();
      await (delete(
        localWorkoutSessions,
      )..where((t) => t.id.equals(sessionId))).go();
    });
  }

  Future<void> finishSession(String id, DateTime finishedAt) =>
      (update(localWorkoutSessions)..where((t) => t.id.equals(id))).write(
        LocalWorkoutSessionsCompanion(
          finishedAt: Value(finishedAt),
          syncStatus: const Value('sync_pending'),
        ),
      );

  Future<void> updateSessionSyncStatus(String id, String status) =>
      (update(localWorkoutSessions)..where((t) => t.id.equals(id))).write(
        LocalWorkoutSessionsCompanion(syncStatus: Value(status)),
      );

  Future<List<LocalWorkoutSession>> getPendingSessions({
    required String userId,
  }) =>
      (select(localWorkoutSessions)..where(
            (t) =>
                t.syncStatus.isIn(['sync_pending', 'sync_failed']) &
                t.finishedAt.isNotNull() &
                t.userId.equals(userId),
          ))
          .get();

  /// Returns all distinct session_day_anchor values for [userId] in [year]
  /// regardless of gym or sync status. Used to populate the calendar heatmap
  /// with locally-saved sessions so the dot appears immediately after finishing
  /// a workout, without waiting for a Supabase sync.
  Future<Set<String>> getLocalSessionDaysForYear(
    String userId,
    int year,
  ) async {
    final prefix = '$year-';
    final sessions = await (select(localWorkoutSessions)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.finishedAt.isNotNull() &
                t.sessionDayAnchor.like('$prefix%'),
          ))
        .get();
    return sessions.map((s) => s.sessionDayAnchor).toSet();
  }

  Future<List<LocalWorkoutSession>> getRecentSessions(
    String gymId,
    String userId, {
    int? limit,
  }) {
    final query = select(localWorkoutSessions)
      ..where(
        (t) =>
            t.gymId.equals(gymId) &
            t.userId.equals(userId) &
            t.finishedAt.isNotNull(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  /// Returns finished sessions in which [equipmentId] was used in any exercise.
  ///
  /// The session-level [LocalWorkoutSession.equipmentId] only stores the
  /// equipment that was tapped to *start* the session, so filtering by it
  /// misses sessions where the equipment was added mid-workout.  Instead we
  /// look at [LocalSessionExercise.equipmentId] which is set per exercise.
  Future<List<LocalWorkoutSession>> getSessionsForEquipment(
    String gymId,
    String userId,
    String equipmentId,
  ) async {
    // Step 1: find every session-exercise row that used this equipment.
    final exercises =
        await (select(localSessionExercises)..where(
              (t) => t.gymId.equals(gymId) & t.equipmentId.equals(equipmentId),
            ))
            .get();

    final sessionIds = exercises.map((e) => e.sessionId).toSet();
    if (sessionIds.isEmpty) return [];

    // Step 2: load all corresponding finished sessions.
    return (select(localWorkoutSessions)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.id.isIn(sessionIds) &
                t.finishedAt.isNotNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  // ─── Session exercises ─────────────────────────────────────────────────────

  /// All session-exercise entries for a specific exercise key in a gym,
  /// ordered newest first. Used to build per-exercise history.
  Future<List<LocalSessionExercise>> getSessionExercisesForKey(
    String gymId,
    String exerciseKey,
  ) =>
      (select(localSessionExercises)
            ..where(
              (t) => t.gymId.equals(gymId) & t.exerciseKey.equals(exerciseKey),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<LocalSessionExercise>> getExercisesForSession(String sessionId) =>
      (select(localSessionExercises)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<void> insertSessionExercise(LocalSessionExercisesCompanion row) =>
      into(localSessionExercises).insertOnConflictUpdate(row);

  /// Deletes a session exercise and all its sets in a single transaction.
  Future<void> deleteSessionExercise(String exerciseId) async {
    await transaction(() async {
      await (delete(
        localSetEntries,
      )..where((t) => t.sessionExerciseId.equals(exerciseId))).go();
      await (delete(
        localSessionExercises,
      )..where((t) => t.id.equals(exerciseId))).go();
    });
  }

  /// Batch-updates the sortOrder of multiple exercises in a single transaction.
  Future<void> updateExercisesSortOrders(
    List<({String id, int sortOrder})> updates,
  ) async {
    await batch((b) {
      for (final u in updates) {
        b.update(
          localSessionExercises,
          LocalSessionExercisesCompanion(sortOrder: Value(u.sortOrder)),
          where: (t) => t.id.equals(u.id),
        );
      }
    });
  }

  // ─── Set entries ───────────────────────────────────────────────────────────

  Stream<List<LocalSetEntry>> watchSetsForExercise(String sessionExerciseId) =>
      (select(localSetEntries)
            ..where((t) => t.sessionExerciseId.equals(sessionExerciseId))
            ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
          .watch();

  Future<List<LocalSetEntry>> getSetsForExercise(String sessionExerciseId) =>
      (select(localSetEntries)
            ..where((t) => t.sessionExerciseId.equals(sessionExerciseId))
            ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
          .get();

  Future<void> insertSetEntry(LocalSetEntriesCompanion row) =>
      into(localSetEntries).insertOnConflictUpdate(row);

  Future<void> deleteSetEntry(String id) =>
      (delete(localSetEntries)..where((t) => t.id.equals(id))).go();

  /// Returns the sets from the most recent *finished* session that contains
  /// [exerciseKey] for this user, excluding [excludeSessionId] (current session).
  Future<List<LocalSetEntry>> getLastCompletedSetsForExerciseKey(
    String gymId,
    String userId,
    String exerciseKey, {
    String? excludeSessionId,
  }) async {
    final exercises =
        await (select(localSessionExercises)
              ..where(
                (t) =>
                    t.gymId.equals(gymId) & t.exerciseKey.equals(exerciseKey),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();

    for (final ex in exercises) {
      if (ex.sessionId == excludeSessionId) continue;
      final session = await getSessionById(ex.sessionId);
      if (session == null ||
          session.userId != userId ||
          session.finishedAt == null) {
        continue;
      }
      return getSetsForExercise(ex.id);
    }
    return [];
  }

  /// Returns all sets from every *finished* session that contains [exerciseKey]
  /// for this user, excluding [excludeSessionId] (current session).
  /// Used to compute the all-time best e1RM for a given exercise.
  Future<List<LocalSetEntry>> getAllCompletedSetsForExerciseKey(
    String gymId,
    String userId,
    String exerciseKey, {
    String? excludeSessionId,
  }) async {
    final exercises =
        await (select(localSessionExercises)
              ..where(
                (t) =>
                    t.gymId.equals(gymId) & t.exerciseKey.equals(exerciseKey),
              ))
            .get();

    final allSets = <LocalSetEntry>[];
    for (final ex in exercises) {
      if (ex.sessionId == excludeSessionId) continue;
      final session = await getSessionById(ex.sessionId);
      if (session == null ||
          session.userId != userId ||
          session.finishedAt == null) {
        continue;
      }
      allSets.addAll(await getSetsForExercise(ex.id));
    }
    return allSets;
  }

  /// Returns the maximum total volume (reps × weight_kg) achieved in a single
  /// finished session for [exerciseKey], excluding [excludeSessionId].
  /// Returns null if there is no prior strength history for this exercise.
  Future<double?> getBestVolumeForExerciseKey(
    String gymId,
    String userId,
    String exerciseKey, {
    String? excludeSessionId,
  }) async {
    final exercises =
        await (select(localSessionExercises)
              ..where(
                (t) =>
                    t.gymId.equals(gymId) & t.exerciseKey.equals(exerciseKey),
              ))
            .get();

    double? bestVolume;
    for (final ex in exercises) {
      if (ex.sessionId == excludeSessionId) continue;
      final session = await getSessionById(ex.sessionId);
      if (session == null ||
          session.userId != userId ||
          session.finishedAt == null) {
        continue;
      }
      final sets = await getSetsForExercise(ex.id);
      final volume = sets.fold(0.0, (sum, s) {
        final r = s.reps;
        final w = s.weightKg;
        if (r == null || w == null) return sum;
        return sum + r * w;
      });
      if (volume > 0 && (bestVolume == null || volume > bestVolume)) {
        bestVolume = volume;
      }
    }
    return bestVolume;
  }

  Future<List<LocalSetEntry>> getPendingSets(String gymId) =>
      (select(localSetEntries)..where(
            (t) =>
                t.gymId.equals(gymId) &
                t.syncStatus.isIn(['sync_pending', 'sync_failed']),
          ))
          .get();

  // ─── Equipment favourites ──────────────────────────────────────────────────

  Future<Set<String>> getFavouriteEquipmentIds(
    String userId,
    String gymId,
  ) async {
    final rows = await (select(
      localEquipmentFavourites,
    )..where((t) => t.userId.equals(userId) & t.gymId.equals(gymId))).get();
    return {for (final r in rows) r.equipmentId};
  }

  Future<void> setFavourite(
    String userId,
    String gymId,
    String equipmentId,
    bool isFavourite,
  ) async {
    if (isFavourite) {
      await into(localEquipmentFavourites).insertOnConflictUpdate(
        LocalEquipmentFavouritesCompanion.insert(
          userId: userId,
          gymId: gymId,
          equipmentId: equipmentId,
        ),
      );
    } else {
      await (delete(localEquipmentFavourites)..where(
            (t) =>
                t.userId.equals(userId) &
                t.gymId.equals(gymId) &
                t.equipmentId.equals(equipmentId),
          ))
          .go();
    }
  }

  // ─── Workout plans ─────────────────────────────────────────────────────────

  /// Live stream of all active plans for a user in a gym, newest first.
  Stream<List<LocalWorkoutPlan>> watchPlansForUser(
    String gymId,
    String userId,
  ) =>
      (select(localWorkoutPlans)
            ..where(
              (t) =>
                  t.gymId.equals(gymId) &
                  t.userId.equals(userId) &
                  t.isActive.equals(true),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<LocalWorkoutPlan?> getPlanById(String id) =>
      (select(localWorkoutPlans)
            ..where((t) => t.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<void> upsertPlan(LocalWorkoutPlansCompanion row) =>
      into(localWorkoutPlans).insertOnConflictUpdate(row);

  Future<void> softDeletePlan(String planId) =>
      (update(localWorkoutPlans)..where((t) => t.id.equals(planId))).write(
        LocalWorkoutPlansCompanion(
          isActive: const Value(false),
          syncStatus: const Value('sync_pending'),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ─── Plan items ────────────────────────────────────────────────────────────

  Future<List<LocalPlanItem>> getItemsForPlan(String planId) =>
      (select(localPlanItems)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  Future<void> upsertPlanItem(LocalPlanItemsCompanion row) =>
      into(localPlanItems).insertOnConflictUpdate(row);

  Future<void> deleteAllPlanItems(String planId) =>
      (delete(localPlanItems)..where((t) => t.planId.equals(planId))).go();

  /// Atomically replaces all items for a plan with a new ordered list.
  /// Deletes existing items first, then batch-inserts the new set.
  /// Never partially visible — runs inside a single transaction.
  Future<void> replacePlanItems(
    String planId,
    List<LocalPlanItemsCompanion> items,
  ) async {
    await transaction(() async {
      await deleteAllPlanItems(planId);
      if (items.isNotEmpty) {
        await batch((b) => b.insertAll(localPlanItems, items));
      }
    });
  }
}

DatabaseConnection _openConnection() {
  return DatabaseConnection(driftDatabase(name: 'tapem_local_v1'));
}
