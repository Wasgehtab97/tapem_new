import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tapem/core/services/gym_service.dart';
import 'package:tapem/l10n/generated/app_localizations.dart';
import 'package:tapem/presentation/features/community/providers/community_provider.dart';
import 'package:tapem/presentation/features/community/screens/community_screen.dart';
import 'package:tapem/presentation/widgets/common/user_avatar.dart';

Widget _buildTestApp({required List<Override> overrides}) {
  final mergedOverrides = <Override>[
    gymDealsProvider.overrideWith((ref) async => const <GymDeal>[]),
    ...overrides,
  ];
  return ProviderScope(
    overrides: mergedOverrides,
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

Future<void> _openPerformanceLeaderboard(WidgetTester tester) async {
  await tester.tap(
    find
        .ancestor(
          of: find.text('RANKINGS'),
          matching: find.byType(GestureDetector),
        )
        .first,
  );
  await tester.pumpAndSettle();
  expect(find.byTooltip('Find friends'), findsNothing);
  expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
  expect(find.text('KONSISTENZ').hitTestable(), findsOneWidget);
  await tester.tap(find.widgetWithText(Tab, 'PERFORMANCE').hitTestable());
  await tester.pumpAndSettle();
  final selectorFinder = find.byKey(
    const Key('machine-board-selector-open'),
    skipOffstage: false,
  );
  for (var i = 0; i < 20; i++) {
    if (selectorFinder.evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(selectorFinder, findsOneWidget);
}

MachinePerformanceBoardEntry _board({
  required String equipmentId,
  required String equipmentName,
  required String exerciseName,
  required int participantCount,
  String? manufacturer,
}) {
  return MachinePerformanceBoardEntry(
    equipmentId: equipmentId,
    equipmentName: equipmentName,
    manufacturer: manufacturer,
    exerciseKey: exerciseName.toLowerCase().replaceAll(' ', '_'),
    exerciseName: exerciseName,
    participantCount: participantCount,
    topE1rmKg: null,
    topWeightKg: null,
    topReps: null,
    topUserId: null,
    topUsername: null,
    topAchievedAt: null,
  );
}

MachinePerformanceLeaderboardEntry _leaderboardRow({
  required int rank,
  required String userId,
  required String username,
  required double e1rmKg,
  required double weightKg,
  required int reps,
  required bool isCurrentUser,
}) {
  return MachinePerformanceLeaderboardEntry(
    rank: rank,
    userId: userId,
    username: username,
    bestE1rmKg: e1rmKg,
    bestWeightKg: weightKg,
    bestReps: reps,
    achievedAt: DateTime(2026, 3, 10),
    avatarUrl: null,
    isCurrentUser: isCurrentUser,
  );
}

List<Override> _performanceOverrides({
  required List<MachinePerformanceBoardEntry> boards,
  required Map<String, List<MachinePerformanceLeaderboardEntry>>
  leaderboardByBoard,
}) {
  return <Override>[
    activeMembershipProvider.overrideWith((ref) async => null),
    gymLeaderboardProvider.overrideWith((ref, axis) async => []),
    gymEquipmentOverviewProvider.overrideWith((ref) async => []),
    friendsProvider.overrideWith((ref) async => const <FriendUser>[]),
    machinePerformanceBoardsProvider.overrideWith((ref, sex) async => boards),
    machinePerformanceDashboardProvider.overrideWith(
      (ref, sex) async => const MachinePerformanceDashboardStats(
        fixedMachineCount: 3,
        activeBoardsCount: 2,
        rankedAthletesCount: 5,
      ),
    ),
    machinePerformanceRecentRecordsProvider.overrideWith(
      (ref, sex) async => const <MachinePerformanceRecordEvent>[],
    ),
    machinePerformanceLeaderboardProvider.overrideWith((ref, args) async {
      return leaderboardByBoard[args.equipmentId] ?? const [];
    }),
  ];
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

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

    final findFriendsInput = find.byWidgetPredicate(
      (w) => w is TextField && w.autofocus,
    );
    await tester.enterText(findFriendsInput, 'al');
    await tester.pumpAndSettle();

    expect(find.text('MY GYM (1)'), findsOneWidget);
    expect(find.text('OTHER GYMS (1)'), findsOneWidget);
    expect(find.text('@alex'), findsOneWidget);
    expect(find.text('@alina'), findsOneWidget);
  });

  testWidgets(
    'performance exercise selection flow opens selected board ladder',
    (tester) async {
      final boardA = _board(
        equipmentId: 'eq-bench-a',
        equipmentName: 'Alpha Bench Press',
        exerciseName: 'Bench Press',
        manufacturer: 'Prime',
        participantCount: 0,
      );
      final boardB = _board(
        equipmentId: 'eq-bench-b',
        equipmentName: 'Vector Bench Press',
        exerciseName: 'Bench Press',
        manufacturer: 'Atlantis',
        participantCount: 2,
      );

      final overrides = _performanceOverrides(
        boards: [boardA, boardB],
        leaderboardByBoard: {
          boardB.equipmentId: [
            _leaderboardRow(
              rank: 1,
              userId: 'u-7',
              username: 'champ',
              e1rmKg: 128.4,
              weightKg: 110,
              reps: 5,
              isCurrentUser: false,
            ),
          ],
        },
      );

      await _pumpCommunityScreen(tester, overrides: overrides);
      await _openPerformanceLeaderboard(tester);

      final openSelector = find.byKey(
        const Key('machine-board-selector-open'),
        skipOffstage: false,
      );
      await tester.ensureVisible(openSelector);
      await tester.pumpAndSettle();
      await tester.tap(openSelector);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .byKey(Key('machine-board-option-${boardB.equipmentId}'))
            .hitTestable(),
      );
      await tester.pumpAndSettle();

      expect(find.text('RANKED LADDER'), findsOneWidget);
      expect(find.text('@champ'), findsWidgets);
    },
  );

  testWidgets('performance ladder renders required column headers', (
    tester,
  ) async {
    final board = _board(
      equipmentId: 'eq-incline',
      equipmentName: 'Incline Press X1',
      exerciseName: 'Incline Press',
      manufacturer: 'Technogym',
      participantCount: 1,
    );

    final overrides = _performanceOverrides(
      boards: [board],
      leaderboardByBoard: {
        board.equipmentId: [
          _leaderboardRow(
            rank: 1,
            userId: 'u-1',
            username: 'athlete',
            e1rmKg: 102.0,
            weightKg: 90,
            reps: 4,
            isCurrentUser: false,
          ),
        ],
      },
    );

    await _pumpCommunityScreen(tester, overrides: overrides);
    await _openPerformanceLeaderboard(tester);
    final openSelector = find.byKey(
      const Key('machine-board-selector-open'),
      skipOffstage: false,
    );
    await tester.ensureVisible(openSelector);
    await tester.pumpAndSettle();
    await tester.tap(openSelector);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .byKey(Key('machine-board-option-${board.equipmentId}'))
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    final header = find.byKey(const Key('machine-ladder-header'));
    expect(header, findsOneWidget);
    expect(
      find.descendant(of: header, matching: find.text('#')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: header, matching: find.text('ATHLETE')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: header, matching: find.text('BEST SET')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: header, matching: find.text('E1RM')),
      findsOneWidget,
    );
  });

  testWidgets('performance empty ladder state explains eligibility rules', (
    tester,
  ) async {
    final board = _board(
      equipmentId: 'eq-leg-press',
      equipmentName: 'Leg Press 3000',
      exerciseName: 'Leg Press',
      participantCount: 0,
    );
    final overrides = _performanceOverrides(
      boards: [board],
      leaderboardByBoard: const {},
    );

    await _pumpCommunityScreen(tester, overrides: overrides);
    await _openPerformanceLeaderboard(tester);
    final openSelector = find.byKey(
      const Key('machine-board-selector-open'),
      skipOffstage: false,
    );
    await tester.ensureVisible(openSelector);
    await tester.pumpAndSettle();
    await tester.tap(openSelector);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .byKey(Key('machine-board-option-${board.equipmentId}'))
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No eligible ranked result yet for this selection'),
      findsOneWidget,
    );
  });

  testWidgets('performance ladder highlights current user row', (tester) async {
    final board = _board(
      equipmentId: 'eq-row',
      equipmentName: 'Seated Row',
      exerciseName: 'Seated Row',
      participantCount: 2,
    );
    final overrides = _performanceOverrides(
      boards: [board],
      leaderboardByBoard: {
        board.equipmentId: [
          _leaderboardRow(
            rank: 1,
            userId: 'u-other',
            username: 'other',
            e1rmKg: 96.0,
            weightKg: 80,
            reps: 6,
            isCurrentUser: false,
          ),
          _leaderboardRow(
            rank: 2,
            userId: 'u-me',
            username: 'me',
            e1rmKg: 90.0,
            weightKg: 75,
            reps: 6,
            isCurrentUser: true,
          ),
        ],
      },
    );

    await _pumpCommunityScreen(tester, overrides: overrides);
    await _openPerformanceLeaderboard(tester);
    final openSelector = find.byKey(
      const Key('machine-board-selector-open'),
      skipOffstage: false,
    );
    await tester.ensureVisible(openSelector);
    await tester.pumpAndSettle();
    await tester.tap(openSelector);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .byKey(Key('machine-board-option-${board.equipmentId}'))
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    final currentUserRow = find.byKey(
      const Key('machine-ladder-row-current-user'),
      skipOffstage: false,
    );
    if (currentUserRow.evaluate().isEmpty) {
      final ladderScroll = find.descendant(
        of: find.byKey(
          const Key('machine-perf-card-ladder'),
          skipOffstage: false,
        ),
        matching: find.byType(CustomScrollView),
        skipOffstage: false,
      );
      if (ladderScroll.evaluate().isNotEmpty) {
        await tester.drag(ladderScroll.first, const Offset(0, -220));
        await tester.pumpAndSettle();
      }
    }

    expect(currentUserRow, findsOneWidget);
  });

  testWidgets('performance supports horizontal swipe card navigation', (
    tester,
  ) async {
    final board = _board(
      equipmentId: 'eq-swipe-bench',
      equipmentName: 'Swipe Bench Press',
      exerciseName: 'Bench Press',
      participantCount: 1,
    );

    final overrides = _performanceOverrides(
      boards: [board],
      leaderboardByBoard: {
        board.equipmentId: [
          _leaderboardRow(
            rank: 1,
            userId: 'u-1',
            username: 'athlete',
            e1rmKg: 110.0,
            weightKg: 95,
            reps: 4,
            isCurrentUser: false,
          ),
        ],
      },
    );

    await _pumpCommunityScreen(tester, overrides: overrides);
    await _openPerformanceLeaderboard(tester);

    final pageView = find.byKey(const Key('machine-perf-pageview'));
    expect(pageView, findsOneWidget);
    expect(
      find.byKey(const Key('machine-perf-card-board-picker')).hitTestable(),
      findsOneWidget,
    );

    await tester.fling(pageView, const Offset(-700, 0), 1400);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('machine-perf-card-ladder')).hitTestable(),
      findsOneWidget,
    );

    await tester.fling(pageView, const Offset(-700, 0), 1400);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('machine-perf-card-summary')).hitTestable(),
      findsOneWidget,
    );

    await tester.fling(pageView, const Offset(700, 0), 1400);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('machine-perf-card-ladder')).hitTestable(),
      findsOneWidget,
    );
  });
}
