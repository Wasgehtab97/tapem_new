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
import 'package:tapem/data/datasources/local/app_database.dart';
import 'package:tapem/presentation/features/auth/providers/auth_provider.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class ManualSyncNotifier extends SyncNotifier {
  ManualSyncNotifier(super.ref);

  @override
  void start() {}
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

Future<void> _seedFinishedPendingSession(
  AppDatabase db, {
  required String sessionId,
  required String gymId,
  required String userId,
}) async {
  await db.insertSession(
    LocalWorkoutSessionsCompanion.insert(
      id: sessionId,
      gymId: gymId,
      userId: userId,
      equipmentId: 'eq-1',
      sessionDayAnchor: '2026-04-03',
      startedAt: DateTime.utc(2026, 4, 3, 8),
      finishedAt: Value(DateTime.utc(2026, 4, 3, 9)),
      syncStatus: const Value('sync_pending'),
      idempotencyKey: 'ik-$sessionId',
    ),
  );

  const exId = 'ex-1';
  await db.insertSessionExercise(
    LocalSessionExercisesCompanion.insert(
      id: exId,
      sessionId: sessionId,
      gymId: gymId,
      exerciseKey: 'fixed:bench_press',
      displayName: 'Bench Press',
      sortOrder: const Value(0),
      equipmentId: const Value('eq-1'),
    ),
  );

  await db.insertSetEntry(
    LocalSetEntriesCompanion.insert(
      id: 'set-1',
      sessionExerciseId: exId,
      gymId: gymId,
      setNumber: 1,
      reps: const Value(8),
      weightKg: const Value(80),
      syncStatus: const Value('local_saved'),
      loggedAt: Value(DateTime.utc(2026, 4, 3, 8, 30)),
      idempotencyKey: 'set-ik-1',
    ),
  );
}

void main() {
  group('SyncNotifier core flow', () {
    late AppDatabase db;
    late SharedPreferences prefs;
    late MockSupabaseClient mockSupabase;
    late MockGoTrueClient mockAuth;
    late MockFunctionsClient mockFunctions;
    late User user;
    late Session session;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase.forTesting(NativeDatabase.memory());

      user = _user('user-1');
      session = _session(user);
      mockSupabase = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockFunctions = MockFunctionsClient();

      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockSupabase.functions).thenReturn(mockFunctions);
      when(() => mockAuth.currentSession).thenReturn(session);
      when(
        () => mockAuth.refreshSession(),
      ).thenAnswer((_) async => AuthResponse(session: session));
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
          syncNotifierProvider.overrideWith((ref) => ManualSyncNotifier(ref)),
        ],
      );
    }

    test(
      'sync with no pending sessions ends idle with pendingCount=0',
      () async {
        final container = containerForTest();
        addTearDown(container.dispose);
        await container
            .read(activeGymIdProvider.notifier)
            .setActiveGym('gym-1');

        final notifier = container.read(syncNotifierProvider.notifier);
        await notifier.sync();

        final status = container.read(syncNotifierProvider);
        expect(status.state, SyncServiceState.idle);
        expect(status.pendingCount, 0);
        expect(status.lastSyncedAt, isNotNull);
        verifyNever(
          () => mockFunctions.invoke(
            'sync-workout',
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        );
      },
    );

    test('sync uploads pending session and marks it sync_confirmed', () async {
      await _seedFinishedPendingSession(
        db,
        sessionId: 'session-1',
        gymId: 'gym-1',
        userId: user.id,
      );
      when(
        () => mockFunctions.invoke(
          'sync-workout',
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(data: {'ok': true}, status: 200),
      );

      final container = containerForTest();
      addTearDown(container.dispose);
      await container.read(activeGymIdProvider.notifier).setActiveGym('gym-1');

      final notifier = container.read(syncNotifierProvider.notifier);
      await notifier.sync();

      final updated = await db.getSessionById('session-1');
      expect(updated, isNotNull);
      expect(updated!.syncStatus, 'sync_confirmed');

      final status = container.read(syncNotifierProvider);
      expect(status.state, SyncServiceState.idle);
      expect(status.pendingCount, 0);
      verify(
        () => mockFunctions.invoke(
          'sync-workout',
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('sync keeps session pending on 401 and records lastError', () async {
      await _seedFinishedPendingSession(
        db,
        sessionId: 'session-401',
        gymId: 'gym-1',
        userId: user.id,
      );
      when(
        () => mockFunctions.invoke(
          'sync-workout',
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(
        const FunctionException(status: 401, details: 'unauthorized'),
      );

      final container = containerForTest();
      addTearDown(container.dispose);
      await container.read(activeGymIdProvider.notifier).setActiveGym('gym-1');

      final notifier = container.read(syncNotifierProvider.notifier);
      await notifier.sync();

      final updated = await db.getSessionById('session-401');
      expect(updated, isNotNull);
      expect(updated!.syncStatus, 'sync_pending');

      final status = container.read(syncNotifierProvider);
      expect(status.state, SyncServiceState.idle);
      expect(status.lastError, contains('401'));
      verify(() => mockAuth.refreshSession()).called(greaterThanOrEqualTo(1));
    });
  });
}
