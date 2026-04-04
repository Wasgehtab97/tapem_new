import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapem/core/services/gym_service.dart';
import 'package:tapem/presentation/features/auth/providers/auth_provider.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

const _activeGymIdKey = 'active_gym_id';

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

void main() {
  group('ActiveGymNotifier core flow', () {
    late SharedPreferences prefs;
    late MockSupabaseClient mockSupabase;
    late MockGoTrueClient mockAuth;
    late StreamController<AuthState> authController;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockSupabase = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      authController = StreamController<AuthState>.broadcast();

      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(null);
    });

    tearDown(() async {
      await authController.close();
    });

    ProviderContainer containerForTest() {
      return ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          supabaseClientProvider.overrideWithValue(mockSupabase),
          authStateProvider.overrideWith((_) => authController.stream),
        ],
      );
    }

    test('loads stored gym when a session is active', () async {
      await prefs.setString(_activeGymIdKey, 'gym-1');
      when(() => mockAuth.currentSession).thenReturn(_session(_user('user-1')));

      final container = containerForTest();
      addTearDown(container.dispose);
      container.read(activeGymIdProvider);
      await _settle();

      expect(container.read(activeGymIdProvider), 'gym-1');
    });

    test(
      'clears stale gym and workout anchor when no session exists',
      () async {
        await prefs.setString(_activeGymIdKey, 'gym-stale');
        await prefs.setString(kActiveWorkoutSessionKey, 'session-stale');
        when(() => mockAuth.currentSession).thenReturn(null);

        final container = containerForTest();
        addTearDown(container.dispose);
        container.read(activeGymIdProvider);
        await _settle();

        expect(container.read(activeGymIdProvider), isNull);
        expect(prefs.getString(_activeGymIdKey), isNull);
        expect(prefs.getString(kActiveWorkoutSessionKey), isNull);
      },
    );

    test(
      'clear keeps persisted gym while an active workout key exists',
      () async {
        await prefs.setString(_activeGymIdKey, 'gym-1');
        await prefs.setString(kActiveWorkoutSessionKey, 'session-1');
        when(
          () => mockAuth.currentSession,
        ).thenReturn(_session(_user('user-1')));

        final container = containerForTest();
        addTearDown(container.dispose);
        container.read(activeGymIdProvider);
        await _settle();
        expect(container.read(activeGymIdProvider), 'gym-1');

        await container.read(activeGymIdProvider.notifier).clear();

        expect(container.read(activeGymIdProvider), isNull);
        expect(prefs.getString(_activeGymIdKey), 'gym-1');
      },
    );

    test(
      'signedOut event clears persisted gym when no active workout key',
      () async {
        await prefs.setString(_activeGymIdKey, 'gym-1');
        when(
          () => mockAuth.currentSession,
        ).thenReturn(_session(_user('user-1')));

        final container = containerForTest();
        addTearDown(container.dispose);
        container.read(activeGymIdProvider);
        await _settle();
        expect(container.read(activeGymIdProvider), 'gym-1');

        authController.add(const AuthState(AuthChangeEvent.signedOut, null));
        await _settle();

        expect(container.read(activeGymIdProvider), isNull);
        expect(prefs.getString(_activeGymIdKey), isNull);
      },
    );

    test(
      'signedOut event keeps persisted gym when workout key exists',
      () async {
        await prefs.setString(_activeGymIdKey, 'gym-1');
        await prefs.setString(kActiveWorkoutSessionKey, 'session-1');
        when(
          () => mockAuth.currentSession,
        ).thenReturn(_session(_user('user-1')));

        final container = containerForTest();
        addTearDown(container.dispose);
        container.read(activeGymIdProvider);
        await _settle();
        expect(container.read(activeGymIdProvider), 'gym-1');

        authController.add(const AuthState(AuthChangeEvent.signedOut, null));
        await _settle();

        expect(container.read(activeGymIdProvider), isNull);
        expect(prefs.getString(_activeGymIdKey), 'gym-1');
      },
    );
  });
}
