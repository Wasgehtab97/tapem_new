import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapem/core/services/gym_service.dart';
import 'package:tapem/core/services/sync_service.dart';
import 'package:tapem/core/utils/logger.dart';
import 'package:tapem/data/datasources/local/app_database.dart';
import 'package:tapem/presentation/features/auth/providers/auth_provider.dart';
import 'package:tapem/presentation/features/workout/providers/workout_provider.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class SyncSpyNotifier extends SyncNotifier {
  SyncSpyNotifier(super.ref);

  int syncCalls = 0;
  int heartbeatCalls = 0;

  @override
  void start() {}

  @override
  Future<void> sync() async {
    syncCalls++;
  }

  @override
  Future<void> heartbeatActiveSession() async {
    heartbeatCalls++;
  }
}

String _jwtWithExp(DateTime expiresAt) {
  String b64(Map<String, Object?> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final header = b64({'alg': 'HS256', 'typ': 'JWT'});
  final payload = b64({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000});
  return '$header.$payload.sig';
}

User _user(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-04-03T00:00:00Z',
  email: '$id@test.local',
);

Session _session(User user) => Session(
  accessToken: _jwtWithExp(DateTime.now().add(const Duration(hours: 1))),
  tokenType: 'bearer',
  refreshToken: 'refresh-token',
  user: user,
);

Future<void> _settle() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

Future<void> _seedActiveSession(
  AppDatabase db, {
  required String sessionId,
  required String gymId,
  required String userId,
}) async {
  final startedAt = DateTime.now().toUtc().subtract(
    const Duration(minutes: 30),
  );
  final dayAnchor =
      '${startedAt.year.toString().padLeft(4, '0')}-'
      '${startedAt.month.toString().padLeft(2, '0')}-'
      '${startedAt.day.toString().padLeft(2, '0')}';

  await db.insertSession(
    LocalWorkoutSessionsCompanion.insert(
      id: sessionId,
      gymId: gymId,
      userId: userId,
      equipmentId: 'eq-seeded',
      sessionDayAnchor: dayAnchor,
      startedAt: startedAt,
      syncStatus: const Value('local_saved'),
      idempotencyKey: 'ik-$sessionId',
    ),
  );

  await db.insertSessionExercise(
    LocalSessionExercisesCompanion.insert(
      id: 'seed-ex-1',
      sessionId: sessionId,
      gymId: gymId,
      exerciseKey: 'fixed:bench_press',
      displayName: 'Bench Press',
      sortOrder: const Value(0),
      equipmentId: const Value('eq-seeded'),
    ),
  );
}

void main() {
  group('WorkoutNotifier core flow', () {
    late AppDatabase db;
    late SharedPreferences prefs;
    late MockSupabaseClient mockSupabase;
    late MockGoTrueClient mockAuth;
    late User user;
    late Session session;

    setUpAll(AppLogger.init);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase.forTesting(NativeDatabase.memory());

      user = _user('user-1');
      session = _session(user);
      mockSupabase = MockSupabaseClient();
      mockAuth = MockGoTrueClient();

      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(session);
    });

    tearDown(() async {
      await db.close();
    });

    ProviderContainer containerForTest() {
      return ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          supabaseClientProvider.overrideWithValue(mockSupabase),
          currentUserProvider.overrideWith((_) => user),
          authStateProvider.overrideWith(
            (_) => const Stream<AuthState>.empty(),
          ),
          syncNotifierProvider.overrideWith((ref) => SyncSpyNotifier(ref)),
        ],
      );
    }

    test(
      'start -> log set -> finish marks sync_pending and clears anchor',
      () async {
        final container = containerForTest();
        addTearDown(container.dispose);
        await container
            .read(activeGymIdProvider.notifier)
            .setActiveGym('gym-1');

        final notifier = container.read(workoutProvider.notifier);
        await notifier.startSession(
          equipmentId: 'eq-1',
          equipmentName: 'Bench A',
          canonicalExerciseKey: 'fixed:bench_press',
          canonicalExerciseName: 'Bench Press',
        );

        final active = container.read(workoutProvider);
        expect(active, isA<WorkoutActive>());
        final workout = active as WorkoutActive;
        expect(workout.exercises, isNotEmpty);

        await notifier.logSet(
          sessionExerciseId: workout.exercises.first.exercise.id,
          reps: 8,
          weightKg: 80,
        );
        await notifier.finishSession();

        expect(container.read(workoutProvider), isA<WorkoutIdle>());

        final sessionRow = await db.getSessionById(workout.session.id);
        expect(sessionRow, isNotNull);
        expect(sessionRow!.finishedAt, isNotNull);
        expect(sessionRow.syncStatus, 'sync_pending');
        expect(prefs.getString(kActiveWorkoutSessionKey), isNull);

        final syncSpy =
            container.read(syncNotifierProvider.notifier) as SyncSpyNotifier;
        expect(syncSpy.heartbeatCalls, greaterThanOrEqualTo(1));
        expect(syncSpy.syncCalls, 1);
      },
    );

    test(
      'startSession resumes existing active session instead of creating another',
      () async {
        await _seedActiveSession(
          db,
          sessionId: 'existing-session',
          gymId: 'gym-1',
          userId: user.id,
        );

        final container = containerForTest();
        addTearDown(container.dispose);
        await container
            .read(activeGymIdProvider.notifier)
            .setActiveGym('gym-1');

        final notifier = container.read(workoutProvider.notifier);
        await notifier.startSession(
          equipmentId: 'eq-new',
          equipmentName: 'Any',
          canonicalExerciseKey: 'fixed:leg_press',
        );

        final state = container.read(workoutProvider);
        expect(state, isA<WorkoutActive>());
        final active = state as WorkoutActive;
        expect(active.session.id, 'existing-session');

        final all = await db.getAllActiveSessions('gym-1', user.id);
        expect(all, hasLength(1));
        expect(all.single.id, 'existing-session');
      },
    );

    test(
      'resumeActiveSession restores active gym from persisted session key after transient clear',
      () async {
        await _seedActiveSession(
          db,
          sessionId: 'resume-session',
          gymId: 'gym-restore',
          userId: user.id,
        );
        await prefs.setString('active_gym_id', 'gym-restore');
        await prefs.setString(kActiveWorkoutSessionKey, 'resume-session');

        final container = containerForTest();
        addTearDown(container.dispose);
        container.read(activeGymIdProvider);
        await _settle();
        expect(container.read(activeGymIdProvider), 'gym-restore');

        await container.read(activeGymIdProvider.notifier).clear();
        expect(container.read(activeGymIdProvider), isNull);
        expect(prefs.getString('active_gym_id'), 'gym-restore');

        final notifier = container.read(workoutProvider.notifier);
        await notifier.resumeActiveSession();
        await _settle();

        expect(container.read(activeGymIdProvider), 'gym-restore');
        final state = container.read(workoutProvider);
        expect(state, isA<WorkoutActive>());
        expect((state as WorkoutActive).session.id, 'resume-session');
      },
    );
  });
}
