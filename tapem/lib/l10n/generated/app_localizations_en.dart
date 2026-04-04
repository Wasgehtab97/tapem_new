// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navGym => 'Gym';

  @override
  String get navProgress => 'Progress';

  @override
  String get navCommunity => 'Community';

  @override
  String get navWorkout => 'Workout';

  @override
  String get navAdmin => 'Admin';

  @override
  String get appTagline => 'TRACK. PROGRESS. COMPETE.';

  @override
  String get emailLabel => 'EMAIL';

  @override
  String get passwordLabel => 'PASSWORD';

  @override
  String get forgotPassword => 'FORGOT PASSWORD?';

  @override
  String get signIn => 'SIGN IN';

  @override
  String get signUp => 'SIGN UP';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get emailRequired => 'Email required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordMinLength => 'Min. 8 characters';

  @override
  String get enterEmailFirst => 'Enter your email first';

  @override
  String get passwordResetSent => 'Password reset email sent';

  @override
  String get createAccount => 'CREATE ACCOUNT';

  @override
  String get joinGymTagline => 'Join your gym on Tap\'em.';

  @override
  String get confirmPasswordLabel => 'CONFIRM PASSWORD';

  @override
  String get passwordsNoMatch => 'Passwords do not match';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get authLegalPrefix => 'By continuing you accept';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get termsOfServiceLabel => 'Terms';

  @override
  String get chooseYourUsername => 'CHOOSE YOUR\nUSERNAME';

  @override
  String get usernamePublicHint =>
      'Your username is public within your gym. You can change it later.';

  @override
  String get usernameLabel => 'USERNAME';

  @override
  String get usernameSuggestions => 'SUGGESTIONS';

  @override
  String get usernameRequired => 'Username required';

  @override
  String get usernameInvalid => '3–20 chars, lowercase, numbers, _ and . only';

  @override
  String get usernameTaken => 'Username already taken';

  @override
  String get continueBtn => 'CONTINUE';

  @override
  String get joinYourGym => 'JOIN YOUR GYM';

  @override
  String get gymCodeDescription =>
      'Enter the gym code provided by your gym. You can switch gyms anytime from your profile.';

  @override
  String get yourGyms => 'YOUR GYMS';

  @override
  String get joinAnotherGym => 'JOIN ANOTHER GYM';

  @override
  String get noGymMembership => 'NO GYM MEMBERSHIP YET';

  @override
  String get askGymForCode =>
      'Ask your gym for the gym code and enter it below to get started.';

  @override
  String get gymCodeLabel => 'GYM CODE';

  @override
  String get gymCodeEmpty => 'Please enter the gym code.';

  @override
  String get invalidGymCode => 'Invalid gym code. Please check and try again.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get joinGymBtn => 'JOIN GYM';

  @override
  String failedToLoadGyms(String error) {
    return 'Failed to load gyms: $error';
  }

  @override
  String get welcomeBack => 'WELCOME BACK';

  @override
  String welcomeBackUser(String username) {
    return 'WELCOME BACK, @$username';
  }

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get noProfile => 'No profile';

  @override
  String get checkingForSession => 'Checking for active session…';

  @override
  String get workoutInProgress => 'WORKOUT IN PROGRESS';

  @override
  String startedAt(String time) {
    return 'Started at $time';
  }

  @override
  String get continueWorkout => 'CONTINUE WORKOUT';

  @override
  String get discard => 'DISCARD';

  @override
  String get discardWorkoutTitle => 'DISCARD WORKOUT?';

  @override
  String get discardWorkoutContent =>
      'All sets from this session will be permanently deleted.';

  @override
  String get keep => 'KEEP';

  @override
  String get quickStart => 'QUICK START';

  @override
  String get startWorkout => 'START WORKOUT';

  @override
  String get startWorkoutHint => 'Choose freestyle or follow a plan';

  @override
  String get recentSessions => 'RECENT SESSIONS';

  @override
  String get seeAll => 'SEE ALL';

  @override
  String get noSessionsYetShort =>
      'No sessions yet.\nStart your first workout!';

  @override
  String get couldNotLoadSessions => 'Could not load sessions.';

  @override
  String get allSessions => 'ALL SESSIONS';

  @override
  String get freestyleTitle => 'FREESTYLE';

  @override
  String get freestyleDescription =>
      'Start immediately — add exercises\nas you go from the Gym tab.';

  @override
  String get fromPlanTitle => 'FROM PLAN';

  @override
  String get fromPlanDescription => 'Follow one of your workout plans.';

  @override
  String get choosePlan => 'CHOOSE PLAN';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get noActiveGym => 'No active gym.';

  @override
  String get searchEquipmentLabel => 'Search';

  @override
  String get searchEquipmentHint => 'Search equipment...';

  @override
  String get tapMachineToAdd => 'Tap any machine to add it to your workout';

  @override
  String get noFavouritesYet =>
      'No favourites yet.\nTap ★ on any machine to add it.';

  @override
  String get noEquipmentFound =>
      'No equipment found.\nAsk your gym admin to add machines.';

  @override
  String get errorLoadingEquipment => 'Error loading equipment';

  @override
  String get filterAll => 'All';

  @override
  String get filterMachines => 'Machines';

  @override
  String get filterOpen => 'Multi';

  @override
  String get filterCardio => 'Cardio';

  @override
  String get filterFavs => '★ FAVS';

  @override
  String get machineTypeLabel => 'MACHINE';

  @override
  String get openTypeLabel => 'OPEN';

  @override
  String get cardioTypeLabel => 'CARDIO';

  @override
  String get discardWorkoutFullTitle => 'DISCARD WORKOUT?';

  @override
  String get discardWorkoutFullContent =>
      'All sets and progress from this session will be permanently deleted. Nothing will be saved or synced.';

  @override
  String get leaveWorkoutTitle => 'LEAVE WORKOUT?';

  @override
  String get leaveWorkoutContent =>
      'Your workout is still running. Unchecked sets will be lost — only checked sets are saved when you tap FINISH.';

  @override
  String get finishWorkoutTitle => 'FINISH WORKOUT?';

  @override
  String get finishWorkoutContent =>
      'All checked sets will be saved and synced.';

  @override
  String get stay => 'STAY';

  @override
  String get leave => 'LEAVE';

  @override
  String get finish => 'FINISH';

  @override
  String get cancel => 'CANCEL';

  @override
  String get addExercise => 'ADD EXERCISE';

  @override
  String get discardWorkoutMenu => 'Discard workout';

  @override
  String get workoutDiscardedSnack => 'Workout discarded. Nothing was saved.';

  @override
  String get cancelTimer => 'Cancel timer';

  @override
  String get removeExerciseTitle => 'REMOVE EXERCISE?';

  @override
  String removeExerciseContent(String name) {
    return 'All sets for \"$name\" will be removed.';
  }

  @override
  String get remove => 'REMOVE';

  @override
  String get sessionStarted => 'Session started!';

  @override
  String get addExerciseHint =>
      'Tap \"Add Exercise\" below or browse the Gym tab.';

  @override
  String get addSet => 'ADD SET';

  @override
  String get setColumnHeader => 'SET';

  @override
  String get prevColumnHeader => 'PREV';

  @override
  String get kgColumnHeader => 'KG';

  @override
  String get repsColumnHeader => 'REPS';

  @override
  String get startTimer => 'START TIMER';

  @override
  String get stopAndLog => 'STOP & LOG';

  @override
  String get equipmentDetails => 'Equipment details';

  @override
  String get progressTitle => 'PROGRESS';

  @override
  String get trainingCalendar => 'TRAINING CALENDAR';

  @override
  String get expand => 'EXPAND';

  @override
  String get failedToLoadCalendar => 'Failed to load calendar';

  @override
  String trainingDaysThisYear(int count) {
    return '$count training days this year';
  }

  @override
  String get failedToLoadXp => 'Failed to load XP';

  @override
  String get topEquipment => 'TOP EQUIPMENT';

  @override
  String get noExerciseData => 'No exercise data yet.';

  @override
  String get muscleGroups => 'MUSCLE GROUPS';

  @override
  String get noMuscleGroupData => 'No muscle group data yet.';

  @override
  String get trainingDayXp => 'TRAINING DAY XP';

  @override
  String get noXpYet => 'No XP yet. Start your first workout!';

  @override
  String xpTotal(int xp) {
    return '$xp XP total';
  }

  @override
  String xpToNextLevel(int xp) {
    return '$xp XP to next level';
  }

  @override
  String get trainingPlansTile => 'TRAINING PLANS';

  @override
  String get createManagePlans => 'Create and manage your workout plans';

  @override
  String get noSessionsYetLong => 'No sessions yet. Start your first workout!';

  @override
  String get communityTitle => 'COMMUNITY';

  @override
  String get findFriendsTooltip => 'Find friends';

  @override
  String get friendsTab => 'FRIENDS';

  @override
  String get rankingsTab => 'RANKINGS';

  @override
  String get dealsTab => 'DEALS';

  @override
  String get dealsHeaderTitle => 'EXCLUSIVE DEALS';

  @override
  String get dealsHeaderSubtitle => 'Offers selected for your gym.';

  @override
  String get dealsCategorySupplements => 'SUPPLEMENTS';

  @override
  String get dealsCategoryClothing => 'CLOTHING';

  @override
  String get dealsCategoryFood => 'NUTRITION';

  @override
  String get dealsCategoryEquipment => 'EQUIPMENT';

  @override
  String get dealsCategoryWellness => 'WELLNESS';

  @override
  String get dealsShopNow => 'SHOP NOW';

  @override
  String get dealsCopied => 'Code copied!';

  @override
  String get dealsNoDeals => 'NO DEALS AVAILABLE';

  @override
  String get dealsNoDealsSubtitle => 'Deals for your gym are coming soon.';

  @override
  String get dealsInfoTitle => 'SNEAK PEEK';

  @override
  String get dealsInfoBody =>
      'The deals you see here are demo content — no real codes yet. But this is exactly what\'s coming: exclusive discounts, curated for your gym, right inside the app. Every partner that joins supports Tap\'em\'s development and your gym. Stay tuned.';

  @override
  String get dealsInfoGotIt => 'GOT IT';

  @override
  String requestsSection(int count) {
    return 'REQUESTS ($count)';
  }

  @override
  String friendsSection(int count) {
    return 'FRIENDS ($count)';
  }

  @override
  String friendsSameGymSection(int count) {
    return 'YOUR GYM ($count)';
  }

  @override
  String friendsOtherGymsSection(int count) {
    return 'OTHER GYMS ($count)';
  }

  @override
  String pendingSection(int count) {
    return 'PENDING ($count)';
  }

  @override
  String get pendingBadge => 'PENDING';

  @override
  String get friendStatusFriends => 'FRIEND';

  @override
  String get noFriendsYet => 'NO FRIENDS YET';

  @override
  String get findGymMembers => 'Find gym members to connect with.';

  @override
  String get findFriendsBtn => 'FIND FRIENDS';

  @override
  String get friendInYourGym => 'In your active gym';

  @override
  String friendFromOtherGyms(int count) {
    return 'Other gyms ($count shared)';
  }

  @override
  String searchMyGymSection(int count) {
    return 'MY GYM ($count)';
  }

  @override
  String searchOtherGymsSection(int count) {
    return 'OTHER GYMS ($count)';
  }

  @override
  String lastTrained(String date) {
    return 'Last trained: $date';
  }

  @override
  String get noRankingData =>
      'No ranking data yet.\nComplete a workout to earn XP!';

  @override
  String get gymXpLeaderboard => 'GYM XP LEADERBOARD';

  @override
  String get findFriendsSheetTitle => 'FIND FRIENDS';

  @override
  String get searchByUsername => 'Search by username...';

  @override
  String noUsersFound(String query) {
    return 'No users found for \"$query\"';
  }

  @override
  String get typeToSearch => 'Type at least 2 characters to search.';

  @override
  String get addFriendBtn => 'ADD';

  @override
  String get acceptTooltip => 'Accept';

  @override
  String get declineTooltip => 'Decline';

  @override
  String get profileTitle => 'PROFILE';

  @override
  String get profileNavLabel => 'Profile';

  @override
  String get usernameSection => 'USERNAME';

  @override
  String get themeSection => 'THEME';

  @override
  String get themeDefault => 'DEFAULT';

  @override
  String get themeEnergy => 'ENERGY';

  @override
  String get themeMinimal => 'MINIMAL';

  @override
  String get privacySection => 'ACTIVITY PRIVACY';

  @override
  String get privacyPrivate => 'PRIVATE';

  @override
  String get privacyPrivateDescription => 'No activity visible to friends';

  @override
  String get privacyTrainingDays => 'TRAINING DAYS';

  @override
  String get privacyTrainingDaysDescription =>
      'Friends see your training days only';

  @override
  String get privacySummary => 'SUMMARY';

  @override
  String get privacySummaryDescription =>
      'Friends see training days + session summaries';

  @override
  String get signOut => 'SIGN OUT';

  @override
  String get languageSection => 'LANGUAGE';

  @override
  String get legalDataSection => 'LEGAL & DATA';

  @override
  String get imprintLabel => 'Imprint';

  @override
  String get supportLabel => 'Support';

  @override
  String get exportMyDataLabel => 'Export my data';

  @override
  String get exportingDataLabel => 'Preparing data export…';

  @override
  String get deleteAccountLabel => 'Delete account';

  @override
  String get deletingAccountLabel => 'Deleting account…';

  @override
  String get deleteAccountConfirmTitle => 'DELETE ACCOUNT?';

  @override
  String get deleteAccountConfirmBody =>
      'This permanently deletes your account and all personal data linked to it.';

  @override
  String get typeDeletePrompt => 'Type DELETE to confirm';

  @override
  String get accountDeletedSuccess => 'Account deleted.';

  @override
  String accountDeleteFailed(String error) {
    return 'Account deletion failed: $error';
  }

  @override
  String get exportDataReadyTitle => 'Data export ready';

  @override
  String exportDataReadyBody(int estimatedRows, int minutes) {
    return 'Your export was generated ($estimatedRows records). The download link expires in about $minutes minutes.';
  }

  @override
  String get downloadExportLabel => 'Download export';

  @override
  String get closeLabel => 'CLOSE';

  @override
  String exportDataFailed(String error) {
    return 'Data export failed: $error';
  }

  @override
  String get trainingPlansTitle => 'TRAINING PLANS';

  @override
  String get newPlanTooltip => 'New Plan';

  @override
  String get noPlansYet => 'NO PLANS YET';

  @override
  String get noPlansDescription =>
      'Create your first training plan\nto start structured workouts.';

  @override
  String get createFirstPlan => 'CREATE FIRST PLAN';

  @override
  String get createNewPlan => 'CREATE NEW PLAN';

  @override
  String get updatedToday => 'Updated today';

  @override
  String get updatedYesterday => 'Updated yesterday';

  @override
  String updatedDaysAgo(int count) {
    return 'Updated ${count}d ago';
  }

  @override
  String updatedDate(String date) {
    return 'Updated $date';
  }

  @override
  String get editPlan => 'EDIT PLAN';

  @override
  String get newPlan => 'NEW PLAN';

  @override
  String get deletePlanTooltip => 'Delete plan';

  @override
  String get deletePlanTitle => 'DELETE PLAN?';

  @override
  String get deletePlanContent => 'This plan will be permanently removed.';

  @override
  String get delete => 'DELETE';

  @override
  String get planNameLabel => 'PLAN NAME';

  @override
  String get noExercisesYet => 'NO EXERCISES YET';

  @override
  String get noExercisesHint =>
      'Add exercises from your gym\nequipment to build the plan.';

  @override
  String get addFirstExercise => 'ADD FIRST EXERCISE';

  @override
  String get addExerciseToPlan => '+ ADD EXERCISE';

  @override
  String get saveChanges => 'SAVE CHANGES';

  @override
  String get savePlan => 'SAVE PLAN';

  @override
  String get addExercisePicker => 'ADD EXERCISE';

  @override
  String get searchLabel => 'SEARCH';

  @override
  String get filterEquipment => 'Filter equipment...';

  @override
  String get noEquipmentFoundShort => 'No equipment found.';

  @override
  String get fixedBadge => 'FIXED';

  @override
  String get openBadge => 'OPEN';

  @override
  String get cardioBadge => 'CARDIO';

  @override
  String get myExercises => 'MY EXERCISES';

  @override
  String get noExercisesAtStation =>
      'No exercises created at this station yet.';

  @override
  String get selectExerciseForHistory =>
      'Select an exercise to view its history.';

  @override
  String get myHistory => 'MY HISTORY';

  @override
  String historyFor(String name) {
    return 'HISTORY — $name';
  }

  @override
  String get noSessionsOnEquipment => 'No sessions on this equipment yet.';

  @override
  String noSessionsWithExercise(String name) {
    return 'No sessions with $name yet.';
  }

  @override
  String get historyCouldNotLoad => 'History could not be loaded.';

  @override
  String get myXpOnEquipment => 'MY XP ON THIS EQUIPMENT';

  @override
  String get xpDataUnavailable => 'XP data unavailable.';

  @override
  String xpEarnedOnEquipment(int level) {
    return 'Level $level · earned on this equipment';
  }

  @override
  String get gymRanking => 'GYM RANKING';

  @override
  String get noRankingYet =>
      'No ranking data yet.\nRankings unlock after enough sessions are recorded.';

  @override
  String get rankingUnavailable => 'Ranking unavailable.';

  @override
  String get myNote => 'MY NOTE';

  @override
  String get noteHint => 'Add a personal note for this equipment...';

  @override
  String get save => 'SAVE';

  @override
  String get noteSaved => 'Note saved.';

  @override
  String get feedbackToGym => 'FEEDBACK TO GYM';

  @override
  String get feedbackHint =>
      'Report an issue or suggest an improvement for the gym owner...';

  @override
  String get send => 'SEND';

  @override
  String get feedbackSent => 'Feedback sent to gym management.';

  @override
  String get failedToSendFeedback =>
      'Failed to send feedback. Please try again.';

  @override
  String setsRepsLabel(int sets, int reps, String duration) {
    return '$sets sets · $reps reps · $duration';
  }

  @override
  String get allExercisesChip => 'ALL';

  @override
  String get filterFixed => 'Fixed';

  @override
  String get failedToLoadSessionDetails => 'Failed to load session details.';

  @override
  String get noExercisesRecorded => 'No exercises recorded.';

  @override
  String get noSetsLogged => 'No sets logged.';

  @override
  String get rankingConsistency => 'KONSISTENZ';

  @override
  String get rankingEquipment => 'EQUIPMENT';

  @override
  String get rankingMuscleGroup => 'MUSCLE';

  @override
  String get rankingMuscleGroupLocked => 'COMING SOON';

  @override
  String get rankingMuscleGroupLockedDesc =>
      'Muscle group rankings unlock once your gym\'s equipment has muscle group data configured by the gym admin.';

  @override
  String get rankingBeyondTop3 => 'RANKINGS';

  @override
  String get rankingEmptyConsistency =>
      'No one in this gym has trained yet – be the first!';

  @override
  String get rankingEmptyEquipment =>
      'No Equipment XP in this gym yet – be the first!';

  @override
  String get rankingPrivacyNote =>
      'Rankings show members with public profiles only.';

  @override
  String get removeFriend => 'Remove Friend';

  @override
  String get removeFriendTitle => 'REMOVE FRIEND?';

  @override
  String removeFriendContent(String username) {
    return 'Remove @$username from your friends?';
  }

  @override
  String get removeFriendBtn => 'REMOVE';

  @override
  String get cancelRequestTitle => 'CANCEL REQUEST?';

  @override
  String cancelRequestContent(String username) {
    return 'Cancel your request to @$username?';
  }

  @override
  String get cancelRequestBtn => 'CANCEL REQUEST';

  @override
  String get lastTrainedToday => 'Trained today';

  @override
  String get lastTrainedYesterday => 'Trained yesterday';

  @override
  String lastTrainedDaysAgo(int days) {
    return 'Trained ${days}d ago';
  }

  @override
  String get friendProfileTitle => 'FRIEND PROFILE';

  @override
  String get friendTagSameGym => 'SAME GYM';

  @override
  String get friendTagOtherGym => 'OTHER GYM';

  @override
  String sharedGymsCount(int count) {
    return '$count shared gyms';
  }

  @override
  String get friendTrainingCalendar => 'TRAINING CALENDAR';

  @override
  String friendTrainingDaysCount(int count, int year) {
    return '$count training days · $year';
  }

  @override
  String get openCalendarBtn => 'OPEN';

  @override
  String get friendCalendarUnavailable => 'Training calendar is not visible.';

  @override
  String get friendLastSessionSummary => 'LAST SESSION SUMMARY';

  @override
  String get friendSessionSummaryHidden =>
      'Session summary is hidden by privacy settings.';

  @override
  String get friendSessionSummaryUnavailable =>
      'Could not load session summary.';

  @override
  String friendSessionDay(String day) {
    return 'Session day: $day';
  }

  @override
  String friendExerciseCount(int count) {
    return '$count exercises';
  }

  @override
  String friendSetCount(int count) {
    return '$count sets';
  }

  @override
  String get xpOverviewTitle => 'XP OVERVIEW';

  @override
  String get consistencyAxisLabel => 'KONSISTENZ';

  @override
  String get equipmentAxisLabel => 'EQUIPMENT';

  @override
  String get muscleGroupAxisLabel => 'MUSCLE GROUPS';

  @override
  String get equipmentXpTitle => 'EXERCISES';

  @override
  String get performanceTileTitle => 'PERFORMANCE';

  @override
  String get performanceTileSubtitle =>
      'Exercises ranked by your e1RM improvement trend';

  @override
  String get noPerformanceData => 'No performance data yet.';

  @override
  String get performanceLoadError => 'Performance data could not be loaded.';

  @override
  String performanceMoreCount(int count) {
    return '+ $count more';
  }

  @override
  String get performanceSortedByTrend =>
      'Sorted by performance increase over time.';

  @override
  String get performanceSearchHint => 'Search exercise…';

  @override
  String get performanceNoSearchResults => 'No exercises found.';

  @override
  String get performanceInsufficientData => 'Not enough trend data yet.';

  @override
  String get performanceInsufficientDataShort => 'No trend yet';

  @override
  String performanceTrendSummary(String kg, String percent) {
    return '$kg ($percent)';
  }

  @override
  String performanceDetailTitle(String name) {
    return 'PERFORMANCE — $name';
  }

  @override
  String get performanceLatestE1rm => 'LATEST E1RM';

  @override
  String get performanceBestE1rm => 'BEST E1RM';

  @override
  String get performanceTrackedSessions => 'TRACKED SESSIONS';

  @override
  String get performanceTrend => 'TREND';

  @override
  String get muscleGroupEmptyState =>
      'Muscle group tracking activates once your gym\'s equipment has muscle group data configured.';

  @override
  String get showAllBtn => 'SHOW ALL';

  @override
  String get collapseBtn => 'SHOW LESS';

  @override
  String get createPlanFromSessionTooltip => 'Create plan from session';

  @override
  String get createPlanFromSessionTitle => 'CREATE PLAN FROM SESSION';

  @override
  String get planNameHintCreateFromSession => 'Plan name...';

  @override
  String get createPlanBtn => 'CREATE';

  @override
  String planCreatedFromSessionSuccess(String name) {
    return 'Plan \"$name\" created.';
  }

  @override
  String get planCreatedFromSessionFailed =>
      'Failed to create plan. Please try again.';

  @override
  String get strengthProgressTitle => 'E1RM PROGRESS';

  @override
  String get e1rmChartEmptyState =>
      'Complete more sessions to see your E1RM progress.';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get muscleGroupTrained => 'TRAINED';

  @override
  String get muscleGroupNeglected => 'NEGLECTED';
}
