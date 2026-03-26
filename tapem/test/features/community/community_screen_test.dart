import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tapem/core/services/gym_service.dart';
import 'package:tapem/l10n/generated/app_localizations.dart';
import 'package:tapem/presentation/features/community/providers/community_provider.dart';
import 'package:tapem/presentation/features/community/screens/community_screen.dart';
import 'package:tapem/presentation/widgets/common/user_avatar.dart';

Widget _buildTestApp({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CommunityScreen(),
    ),
  );
}

Future<void> _pumpCommunityScreen(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(_buildTestApp(overrides: overrides));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('groups accepted friends into same gym and other gyms sections', (
    tester,
  ) async {
    final overrides = <Override>[
      activeMembershipProvider.overrideWith((ref) async => null),
      gymLeaderboardProvider.overrideWith((ref, axis) async => []),
      gymEquipmentOverviewProvider.overrideWith((ref) async => []),
      friendsProvider.overrideWith(
        (ref) async => const <FriendUser>[
          FriendUser(
            friendshipId: 'f-1',
            userId: 'u-1',
            username: 'alex',
            displayName: 'Alex',
            avatarUrl: null,
            status: 'accepted',
            lastTrainingDay: '2026-03-20',
            sharedGymCount: 1,
            sharesActiveGym: true,
          ),
          FriendUser(
            friendshipId: 'f-2',
            userId: 'u-2',
            username: 'bea',
            displayName: 'Bea',
            avatarUrl: null,
            status: 'accepted',
            lastTrainingDay: null,
            sharedGymCount: 2,
            sharesActiveGym: false,
          ),
        ],
      ),
    ];

    await _pumpCommunityScreen(tester, overrides: overrides);

    expect(find.text('YOUR GYM (1)'), findsOneWidget);
    expect(find.text('OTHER GYMS (1)'), findsOneWidget);
    expect(find.text('@alex'), findsOneWidget);
    expect(find.text('@bea'), findsOneWidget);
  });

  testWidgets('opens friend profile sheet with calendar, summary and avatar', (
    tester,
  ) async {
    final currentYear = DateTime.now().year;
    final overrides = <Override>[
      activeMembershipProvider.overrideWith((ref) async => null),
      gymLeaderboardProvider.overrideWith((ref, axis) async => []),
      gymEquipmentOverviewProvider.overrideWith((ref) async => []),
      friendTrainingDaysProvider.overrideWith(
        (ref, query) async => {'$currentYear-01-10', '$currentYear-01-21'},
      ),
      friendLastSessionSummaryProvider.overrideWith(
        (ref, query) async => const FriendSessionSummary(
          sessionId: 's-1',
          sessionDay: '2026-01-21',
          exerciseCount: 3,
          setCount: 12,
        ),
      ),
      friendsProvider.overrideWith(
        (ref) async => const <FriendUser>[
          FriendUser(
            friendshipId: 'f-1',
            userId: 'u-1',
            username: 'alex',
            displayName: 'Alex',
            avatarUrl: null,
            status: 'accepted',
            lastTrainingDay: '2026-03-20',
            sharedGymCount: 1,
            sharesActiveGym: true,
          ),
        ],
      ),
    ];

    await _pumpCommunityScreen(tester, overrides: overrides);

    await tester.tap(find.text('@alex'));
    await tester.pumpAndSettle();

    expect(find.text('FRIEND PROFILE'), findsOneWidget);
    expect(find.text('TRAINING CALENDAR'), findsOneWidget);
    expect(find.text('LAST SESSION SUMMARY'), findsOneWidget);
    expect(find.byType(UserAvatar), findsWidgets);
  });

  testWidgets('find-friends search shows my gym and other gyms result groups', (
    tester,
  ) async {
    final overrides = <Override>[
      activeMembershipProvider.overrideWith((ref) async => null),
      gymLeaderboardProvider.overrideWith((ref, axis) async => []),
      gymEquipmentOverviewProvider.overrideWith((ref) async => []),
      friendsProvider.overrideWith((ref) async => const <FriendUser>[]),
      userSearchProvider.overrideWith((ref, query) async {
        if (query.trim().toLowerCase() != 'al') return const <FriendUser>[];
        return const <FriendUser>[
          FriendUser(
            friendshipId: '',
            userId: 'u-1',
            username: 'alex',
            displayName: 'Alex',
            avatarUrl: null,
            status: 'none',
            lastTrainingDay: null,
            sharedGymCount: 1,
            sharesActiveGym: true,
          ),
          FriendUser(
            friendshipId: '',
            userId: 'u-2',
            username: 'alina',
            displayName: 'Alina',
            avatarUrl: null,
            status: 'none',
            lastTrainingDay: null,
            sharedGymCount: 3,
            sharesActiveGym: false,
          ),
        ];
      }),
    ];

    await _pumpCommunityScreen(tester, overrides: overrides);

    await tester.tap(find.byTooltip('Find friends'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'al');
    await tester.pumpAndSettle();

    expect(find.text('MY GYM (1)'), findsOneWidget);
    expect(find.text('OTHER GYMS (1)'), findsOneWidget);
    expect(find.text('@alex'), findsOneWidget);
    expect(find.text('@alina'), findsOneWidget);
  });
}
