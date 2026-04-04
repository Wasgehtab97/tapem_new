import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get navGym;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get navWorkout;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'TRACK. PROGRESS. COMPETE.'**
  String get appTagline;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get passwordLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'FORGOT PASSWORD?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'SIGN UP'**
  String get signUp;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get passwordMinLength;

  /// No description provided for @enterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first'**
  String get enterEmailFirst;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get passwordResetSent;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get createAccount;

  /// No description provided for @joinGymTagline.
  ///
  /// In en, this message translates to:
  /// **'Join your gym on Tap\'em.'**
  String get joinGymTagline;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PASSWORD'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsNoMatch;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @authLegalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing you accept'**
  String get authLegalPrefix;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLabel;

  /// No description provided for @termsOfServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsOfServiceLabel;

  /// No description provided for @chooseYourUsername.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE YOUR\nUSERNAME'**
  String get chooseYourUsername;

  /// No description provided for @usernamePublicHint.
  ///
  /// In en, this message translates to:
  /// **'Your username is public within your gym. You can change it later.'**
  String get usernamePublicHint;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get usernameLabel;

  /// No description provided for @usernameSuggestions.
  ///
  /// In en, this message translates to:
  /// **'SUGGESTIONS'**
  String get usernameSuggestions;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username required'**
  String get usernameRequired;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'3–20 chars, lowercase, numbers, _ and . only'**
  String get usernameInvalid;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username already taken'**
  String get usernameTaken;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueBtn;

  /// No description provided for @joinYourGym.
  ///
  /// In en, this message translates to:
  /// **'JOIN YOUR GYM'**
  String get joinYourGym;

  /// No description provided for @gymCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the gym code provided by your gym. You can switch gyms anytime from your profile.'**
  String get gymCodeDescription;

  /// No description provided for @yourGyms.
  ///
  /// In en, this message translates to:
  /// **'YOUR GYMS'**
  String get yourGyms;

  /// No description provided for @joinAnotherGym.
  ///
  /// In en, this message translates to:
  /// **'JOIN ANOTHER GYM'**
  String get joinAnotherGym;

  /// No description provided for @noGymMembership.
  ///
  /// In en, this message translates to:
  /// **'NO GYM MEMBERSHIP YET'**
  String get noGymMembership;

  /// No description provided for @askGymForCode.
  ///
  /// In en, this message translates to:
  /// **'Ask your gym for the gym code and enter it below to get started.'**
  String get askGymForCode;

  /// No description provided for @gymCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'GYM CODE'**
  String get gymCodeLabel;

  /// No description provided for @gymCodeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter the gym code.'**
  String get gymCodeEmpty;

  /// No description provided for @invalidGymCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid gym code. Please check and try again.'**
  String get invalidGymCode;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @joinGymBtn.
  ///
  /// In en, this message translates to:
  /// **'JOIN GYM'**
  String get joinGymBtn;

  /// No description provided for @failedToLoadGyms.
  ///
  /// In en, this message translates to:
  /// **'Failed to load gyms: {error}'**
  String failedToLoadGyms(String error);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get welcomeBack;

  /// No description provided for @welcomeBackUser.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK, @{username}'**
  String welcomeBackUser(String username);

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @noProfile.
  ///
  /// In en, this message translates to:
  /// **'No profile'**
  String get noProfile;

  /// No description provided for @checkingForSession.
  ///
  /// In en, this message translates to:
  /// **'Checking for active session…'**
  String get checkingForSession;

  /// No description provided for @workoutInProgress.
  ///
  /// In en, this message translates to:
  /// **'WORKOUT IN PROGRESS'**
  String get workoutInProgress;

  /// No description provided for @startedAt.
  ///
  /// In en, this message translates to:
  /// **'Started at {time}'**
  String startedAt(String time);

  /// No description provided for @continueWorkout.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WORKOUT'**
  String get continueWorkout;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'DISCARD'**
  String get discard;

  /// No description provided for @discardWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'DISCARD WORKOUT?'**
  String get discardWorkoutTitle;

  /// No description provided for @discardWorkoutContent.
  ///
  /// In en, this message translates to:
  /// **'All sets from this session will be permanently deleted.'**
  String get discardWorkoutContent;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'KEEP'**
  String get keep;

  /// No description provided for @quickStart.
  ///
  /// In en, this message translates to:
  /// **'QUICK START'**
  String get quickStart;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'START WORKOUT'**
  String get startWorkout;

  /// No description provided for @startWorkoutHint.
  ///
  /// In en, this message translates to:
  /// **'Choose freestyle or follow a plan'**
  String get startWorkoutHint;

  /// No description provided for @recentSessions.
  ///
  /// In en, this message translates to:
  /// **'RECENT SESSIONS'**
  String get recentSessions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'SEE ALL'**
  String get seeAll;

  /// No description provided for @noSessionsYetShort.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet.\nStart your first workout!'**
  String get noSessionsYetShort;

  /// No description provided for @couldNotLoadSessions.
  ///
  /// In en, this message translates to:
  /// **'Could not load sessions.'**
  String get couldNotLoadSessions;

  /// No description provided for @allSessions.
  ///
  /// In en, this message translates to:
  /// **'ALL SESSIONS'**
  String get allSessions;

  /// No description provided for @freestyleTitle.
  ///
  /// In en, this message translates to:
  /// **'FREESTYLE'**
  String get freestyleTitle;

  /// No description provided for @freestyleDescription.
  ///
  /// In en, this message translates to:
  /// **'Start immediately — add exercises\nas you go from the Gym tab.'**
  String get freestyleDescription;

  /// No description provided for @fromPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'FROM PLAN'**
  String get fromPlanTitle;

  /// No description provided for @fromPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow one of your workout plans.'**
  String get fromPlanDescription;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE PLAN'**
  String get choosePlan;

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String exerciseCount(int count);

  /// No description provided for @setCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set} other{{count} sets}}'**
  String setCount(int count);

  /// No description provided for @noActiveGym.
  ///
  /// In en, this message translates to:
  /// **'No active gym.'**
  String get noActiveGym;

  /// No description provided for @searchEquipmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchEquipmentLabel;

  /// No description provided for @searchEquipmentHint.
  ///
  /// In en, this message translates to:
  /// **'Search equipment...'**
  String get searchEquipmentHint;

  /// No description provided for @tapMachineToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap any machine to add it to your workout'**
  String get tapMachineToAdd;

  /// No description provided for @noFavouritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet.\nTap ★ on any machine to add it.'**
  String get noFavouritesYet;

  /// No description provided for @noEquipmentFound.
  ///
  /// In en, this message translates to:
  /// **'No equipment found.\nAsk your gym admin to add machines.'**
  String get noEquipmentFound;

  /// No description provided for @errorLoadingEquipment.
  ///
  /// In en, this message translates to:
  /// **'Error loading equipment'**
  String get errorLoadingEquipment;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterMachines.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get filterMachines;

  /// No description provided for @filterOpen.
  ///
  /// In en, this message translates to:
  /// **'Multi'**
  String get filterOpen;

  /// No description provided for @filterCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get filterCardio;

  /// No description provided for @filterFavs.
  ///
  /// In en, this message translates to:
  /// **'★ FAVS'**
  String get filterFavs;

  /// No description provided for @machineTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'MACHINE'**
  String get machineTypeLabel;

  /// No description provided for @openTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get openTypeLabel;

  /// No description provided for @cardioTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'CARDIO'**
  String get cardioTypeLabel;

  /// No description provided for @discardWorkoutFullTitle.
  ///
  /// In en, this message translates to:
  /// **'DISCARD WORKOUT?'**
  String get discardWorkoutFullTitle;

  /// No description provided for @discardWorkoutFullContent.
  ///
  /// In en, this message translates to:
  /// **'All sets and progress from this session will be permanently deleted. Nothing will be saved or synced.'**
  String get discardWorkoutFullContent;

  /// No description provided for @leaveWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'LEAVE WORKOUT?'**
  String get leaveWorkoutTitle;

  /// No description provided for @leaveWorkoutContent.
  ///
  /// In en, this message translates to:
  /// **'Your workout is still running. Unchecked sets will be lost — only checked sets are saved when you tap FINISH.'**
  String get leaveWorkoutContent;

  /// No description provided for @finishWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'FINISH WORKOUT?'**
  String get finishWorkoutTitle;

  /// No description provided for @finishWorkoutContent.
  ///
  /// In en, this message translates to:
  /// **'All checked sets will be saved and synced.'**
  String get finishWorkoutContent;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'STAY'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'LEAVE'**
  String get leave;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get finish;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'ADD EXERCISE'**
  String get addExercise;

  /// No description provided for @discardWorkoutMenu.
  ///
  /// In en, this message translates to:
  /// **'Discard workout'**
  String get discardWorkoutMenu;

  /// No description provided for @workoutDiscardedSnack.
  ///
  /// In en, this message translates to:
  /// **'Workout discarded. Nothing was saved.'**
  String get workoutDiscardedSnack;

  /// No description provided for @cancelTimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel timer'**
  String get cancelTimer;

  /// No description provided for @removeExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'REMOVE EXERCISE?'**
  String get removeExerciseTitle;

  /// No description provided for @removeExerciseContent.
  ///
  /// In en, this message translates to:
  /// **'All sets for \"{name}\" will be removed.'**
  String removeExerciseContent(String name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get remove;

  /// No description provided for @sessionStarted.
  ///
  /// In en, this message translates to:
  /// **'Session started!'**
  String get sessionStarted;

  /// No description provided for @addExerciseHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Exercise\" below or browse the Gym tab.'**
  String get addExerciseHint;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'ADD SET'**
  String get addSet;

  /// No description provided for @setColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'SET'**
  String get setColumnHeader;

  /// No description provided for @prevColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'PREV'**
  String get prevColumnHeader;

  /// No description provided for @kgColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'KG'**
  String get kgColumnHeader;

  /// No description provided for @repsColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'REPS'**
  String get repsColumnHeader;

  /// No description provided for @startTimer.
  ///
  /// In en, this message translates to:
  /// **'START TIMER'**
  String get startTimer;

  /// No description provided for @stopAndLog.
  ///
  /// In en, this message translates to:
  /// **'STOP & LOG'**
  String get stopAndLog;

  /// No description provided for @equipmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Equipment details'**
  String get equipmentDetails;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get progressTitle;

  /// No description provided for @trainingCalendar.
  ///
  /// In en, this message translates to:
  /// **'TRAINING CALENDAR'**
  String get trainingCalendar;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'EXPAND'**
  String get expand;

  /// No description provided for @failedToLoadCalendar.
  ///
  /// In en, this message translates to:
  /// **'Failed to load calendar'**
  String get failedToLoadCalendar;

  /// No description provided for @trainingDaysThisYear.
  ///
  /// In en, this message translates to:
  /// **'{count} training days this year'**
  String trainingDaysThisYear(int count);

  /// No description provided for @failedToLoadXp.
  ///
  /// In en, this message translates to:
  /// **'Failed to load XP'**
  String get failedToLoadXp;

  /// No description provided for @topEquipment.
  ///
  /// In en, this message translates to:
  /// **'TOP EQUIPMENT'**
  String get topEquipment;

  /// No description provided for @noExerciseData.
  ///
  /// In en, this message translates to:
  /// **'No exercise data yet.'**
  String get noExerciseData;

  /// No description provided for @muscleGroups.
  ///
  /// In en, this message translates to:
  /// **'MUSCLE GROUPS'**
  String get muscleGroups;

  /// No description provided for @noMuscleGroupData.
  ///
  /// In en, this message translates to:
  /// **'No muscle group data yet.'**
  String get noMuscleGroupData;

  /// No description provided for @trainingDayXp.
  ///
  /// In en, this message translates to:
  /// **'TRAINING DAY XP'**
  String get trainingDayXp;

  /// No description provided for @noXpYet.
  ///
  /// In en, this message translates to:
  /// **'No XP yet. Start your first workout!'**
  String get noXpYet;

  /// No description provided for @xpTotal.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP total'**
  String xpTotal(int xp);

  /// No description provided for @xpToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to next level'**
  String xpToNextLevel(int xp);

  /// No description provided for @trainingPlansTile.
  ///
  /// In en, this message translates to:
  /// **'TRAINING PLANS'**
  String get trainingPlansTile;

  /// No description provided for @createManagePlans.
  ///
  /// In en, this message translates to:
  /// **'Create and manage your workout plans'**
  String get createManagePlans;

  /// No description provided for @noSessionsYetLong.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet. Start your first workout!'**
  String get noSessionsYetLong;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY'**
  String get communityTitle;

  /// No description provided for @findFriendsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Find friends'**
  String get findFriendsTooltip;

  /// No description provided for @friendsTab.
  ///
  /// In en, this message translates to:
  /// **'FRIENDS'**
  String get friendsTab;

  /// No description provided for @rankingsTab.
  ///
  /// In en, this message translates to:
  /// **'RANKINGS'**
  String get rankingsTab;

  /// No description provided for @dealsTab.
  ///
  /// In en, this message translates to:
  /// **'DEALS'**
  String get dealsTab;

  /// No description provided for @dealsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'EXCLUSIVE DEALS'**
  String get dealsHeaderTitle;

  /// No description provided for @dealsHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offers selected for your gym.'**
  String get dealsHeaderSubtitle;

  /// No description provided for @dealsCategorySupplements.
  ///
  /// In en, this message translates to:
  /// **'SUPPLEMENTS'**
  String get dealsCategorySupplements;

  /// No description provided for @dealsCategoryClothing.
  ///
  /// In en, this message translates to:
  /// **'CLOTHING'**
  String get dealsCategoryClothing;

  /// No description provided for @dealsCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'NUTRITION'**
  String get dealsCategoryFood;

  /// No description provided for @dealsCategoryEquipment.
  ///
  /// In en, this message translates to:
  /// **'EQUIPMENT'**
  String get dealsCategoryEquipment;

  /// No description provided for @dealsCategoryWellness.
  ///
  /// In en, this message translates to:
  /// **'WELLNESS'**
  String get dealsCategoryWellness;

  /// No description provided for @dealsShopNow.
  ///
  /// In en, this message translates to:
  /// **'SHOP NOW'**
  String get dealsShopNow;

  /// No description provided for @dealsCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get dealsCopied;

  /// No description provided for @dealsNoDeals.
  ///
  /// In en, this message translates to:
  /// **'NO DEALS AVAILABLE'**
  String get dealsNoDeals;

  /// No description provided for @dealsNoDealsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deals for your gym are coming soon.'**
  String get dealsNoDealsSubtitle;

  /// No description provided for @dealsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'SNEAK PEEK'**
  String get dealsInfoTitle;

  /// No description provided for @dealsInfoBody.
  ///
  /// In en, this message translates to:
  /// **'The deals you see here are demo content — no real codes yet. But this is exactly what\'s coming: exclusive discounts, curated for your gym, right inside the app. Every partner that joins supports Tap\'em\'s development and your gym. Stay tuned.'**
  String get dealsInfoBody;

  /// No description provided for @dealsInfoGotIt.
  ///
  /// In en, this message translates to:
  /// **'GOT IT'**
  String get dealsInfoGotIt;

  /// No description provided for @requestsSection.
  ///
  /// In en, this message translates to:
  /// **'REQUESTS ({count})'**
  String requestsSection(int count);

  /// No description provided for @friendsSection.
  ///
  /// In en, this message translates to:
  /// **'FRIENDS ({count})'**
  String friendsSection(int count);

  /// No description provided for @friendsSameGymSection.
  ///
  /// In en, this message translates to:
  /// **'YOUR GYM ({count})'**
  String friendsSameGymSection(int count);

  /// No description provided for @friendsOtherGymsSection.
  ///
  /// In en, this message translates to:
  /// **'OTHER GYMS ({count})'**
  String friendsOtherGymsSection(int count);

  /// No description provided for @pendingSection.
  ///
  /// In en, this message translates to:
  /// **'PENDING ({count})'**
  String pendingSection(int count);

  /// No description provided for @pendingBadge.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingBadge;

  /// No description provided for @friendStatusFriends.
  ///
  /// In en, this message translates to:
  /// **'FRIEND'**
  String get friendStatusFriends;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'NO FRIENDS YET'**
  String get noFriendsYet;

  /// No description provided for @findGymMembers.
  ///
  /// In en, this message translates to:
  /// **'Find gym members to connect with.'**
  String get findGymMembers;

  /// No description provided for @findFriendsBtn.
  ///
  /// In en, this message translates to:
  /// **'FIND FRIENDS'**
  String get findFriendsBtn;

  /// No description provided for @friendInYourGym.
  ///
  /// In en, this message translates to:
  /// **'In your active gym'**
  String get friendInYourGym;

  /// No description provided for @friendFromOtherGyms.
  ///
  /// In en, this message translates to:
  /// **'Other gyms ({count} shared)'**
  String friendFromOtherGyms(int count);

  /// No description provided for @searchMyGymSection.
  ///
  /// In en, this message translates to:
  /// **'MY GYM ({count})'**
  String searchMyGymSection(int count);

  /// No description provided for @searchOtherGymsSection.
  ///
  /// In en, this message translates to:
  /// **'OTHER GYMS ({count})'**
  String searchOtherGymsSection(int count);

  /// No description provided for @lastTrained.
  ///
  /// In en, this message translates to:
  /// **'Last trained: {date}'**
  String lastTrained(String date);

  /// No description provided for @noRankingData.
  ///
  /// In en, this message translates to:
  /// **'No ranking data yet.\nComplete a workout to earn XP!'**
  String get noRankingData;

  /// No description provided for @gymXpLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'GYM XP LEADERBOARD'**
  String get gymXpLeaderboard;

  /// No description provided for @findFriendsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'FIND FRIENDS'**
  String get findFriendsSheetTitle;

  /// No description provided for @searchByUsername.
  ///
  /// In en, this message translates to:
  /// **'Search by username...'**
  String get searchByUsername;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found for \"{query}\"'**
  String noUsersFound(String query);

  /// No description provided for @typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters to search.'**
  String get typeToSearch;

  /// No description provided for @addFriendBtn.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get addFriendBtn;

  /// No description provided for @acceptTooltip.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptTooltip;

  /// No description provided for @declineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineTooltip;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profileTitle;

  /// No description provided for @profileNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileNavLabel;

  /// No description provided for @usernameSection.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get usernameSection;

  /// No description provided for @themeSection.
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get themeSection;

  /// No description provided for @themeDefault.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get themeDefault;

  /// No description provided for @themeEnergy.
  ///
  /// In en, this message translates to:
  /// **'ENERGY'**
  String get themeEnergy;

  /// No description provided for @themeMinimal.
  ///
  /// In en, this message translates to:
  /// **'MINIMAL'**
  String get themeMinimal;

  /// No description provided for @privacySection.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY PRIVACY'**
  String get privacySection;

  /// No description provided for @privacyPrivate.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE'**
  String get privacyPrivate;

  /// No description provided for @privacyPrivateDescription.
  ///
  /// In en, this message translates to:
  /// **'No activity visible to friends'**
  String get privacyPrivateDescription;

  /// No description provided for @privacyTrainingDays.
  ///
  /// In en, this message translates to:
  /// **'TRAINING DAYS'**
  String get privacyTrainingDays;

  /// No description provided for @privacyTrainingDaysDescription.
  ///
  /// In en, this message translates to:
  /// **'Friends see your training days only'**
  String get privacyTrainingDaysDescription;

  /// No description provided for @privacySummary.
  ///
  /// In en, this message translates to:
  /// **'SUMMARY'**
  String get privacySummary;

  /// No description provided for @privacySummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Friends see training days + session summaries'**
  String get privacySummaryDescription;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'SIGN OUT'**
  String get signOut;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageSection;

  /// No description provided for @legalDataSection.
  ///
  /// In en, this message translates to:
  /// **'LEGAL & DATA'**
  String get legalDataSection;

  /// No description provided for @imprintLabel.
  ///
  /// In en, this message translates to:
  /// **'Imprint'**
  String get imprintLabel;

  /// No description provided for @supportLabel.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportLabel;

  /// No description provided for @exportMyDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportMyDataLabel;

  /// No description provided for @exportingDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparing data export…'**
  String get exportingDataLabel;

  /// No description provided for @deleteAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountLabel;

  /// No description provided for @deletingAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Deleting account…'**
  String get deletingAccountLabel;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all personal data linked to it.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @typeDeletePrompt.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeletePrompt;

  /// No description provided for @accountDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted.'**
  String get accountDeletedSuccess;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed: {error}'**
  String accountDeleteFailed(String error);

  /// No description provided for @exportDataReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Data export ready'**
  String get exportDataReadyTitle;

  /// No description provided for @exportDataReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your export was generated ({estimatedRows} records). The download link expires in about {minutes} minutes.'**
  String exportDataReadyBody(int estimatedRows, int minutes);

  /// No description provided for @downloadExportLabel.
  ///
  /// In en, this message translates to:
  /// **'Download export'**
  String get downloadExportLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get closeLabel;

  /// No description provided for @exportDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Data export failed: {error}'**
  String exportDataFailed(String error);

  /// No description provided for @trainingPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'TRAINING PLANS'**
  String get trainingPlansTitle;

  /// No description provided for @newPlanTooltip.
  ///
  /// In en, this message translates to:
  /// **'New Plan'**
  String get newPlanTooltip;

  /// No description provided for @noPlansYet.
  ///
  /// In en, this message translates to:
  /// **'NO PLANS YET'**
  String get noPlansYet;

  /// No description provided for @noPlansDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your first training plan\nto start structured workouts.'**
  String get noPlansDescription;

  /// No description provided for @createFirstPlan.
  ///
  /// In en, this message translates to:
  /// **'CREATE FIRST PLAN'**
  String get createFirstPlan;

  /// No description provided for @createNewPlan.
  ///
  /// In en, this message translates to:
  /// **'CREATE NEW PLAN'**
  String get createNewPlan;

  /// No description provided for @updatedToday.
  ///
  /// In en, this message translates to:
  /// **'Updated today'**
  String get updatedToday;

  /// No description provided for @updatedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Updated yesterday'**
  String get updatedYesterday;

  /// No description provided for @updatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {count}d ago'**
  String updatedDaysAgo(int count);

  /// No description provided for @updatedDate.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedDate(String date);

  /// No description provided for @editPlan.
  ///
  /// In en, this message translates to:
  /// **'EDIT PLAN'**
  String get editPlan;

  /// No description provided for @newPlan.
  ///
  /// In en, this message translates to:
  /// **'NEW PLAN'**
  String get newPlan;

  /// No description provided for @deletePlanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get deletePlanTooltip;

  /// No description provided for @deletePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE PLAN?'**
  String get deletePlanTitle;

  /// No description provided for @deletePlanContent.
  ///
  /// In en, this message translates to:
  /// **'This plan will be permanently removed.'**
  String get deletePlanContent;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// No description provided for @planNameLabel.
  ///
  /// In en, this message translates to:
  /// **'PLAN NAME'**
  String get planNameLabel;

  /// No description provided for @noExercisesYet.
  ///
  /// In en, this message translates to:
  /// **'NO EXERCISES YET'**
  String get noExercisesYet;

  /// No description provided for @noExercisesHint.
  ///
  /// In en, this message translates to:
  /// **'Add exercises from your gym\nequipment to build the plan.'**
  String get noExercisesHint;

  /// No description provided for @addFirstExercise.
  ///
  /// In en, this message translates to:
  /// **'ADD FIRST EXERCISE'**
  String get addFirstExercise;

  /// No description provided for @addExerciseToPlan.
  ///
  /// In en, this message translates to:
  /// **'+ ADD EXERCISE'**
  String get addExerciseToPlan;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get saveChanges;

  /// No description provided for @savePlan.
  ///
  /// In en, this message translates to:
  /// **'SAVE PLAN'**
  String get savePlan;

  /// No description provided for @addExercisePicker.
  ///
  /// In en, this message translates to:
  /// **'ADD EXERCISE'**
  String get addExercisePicker;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get searchLabel;

  /// No description provided for @filterEquipment.
  ///
  /// In en, this message translates to:
  /// **'Filter equipment...'**
  String get filterEquipment;

  /// No description provided for @noEquipmentFoundShort.
  ///
  /// In en, this message translates to:
  /// **'No equipment found.'**
  String get noEquipmentFoundShort;

  /// No description provided for @fixedBadge.
  ///
  /// In en, this message translates to:
  /// **'FIXED'**
  String get fixedBadge;

  /// No description provided for @openBadge.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get openBadge;

  /// No description provided for @cardioBadge.
  ///
  /// In en, this message translates to:
  /// **'CARDIO'**
  String get cardioBadge;

  /// No description provided for @myExercises.
  ///
  /// In en, this message translates to:
  /// **'MY EXERCISES'**
  String get myExercises;

  /// No description provided for @noExercisesAtStation.
  ///
  /// In en, this message translates to:
  /// **'No exercises created at this station yet.'**
  String get noExercisesAtStation;

  /// No description provided for @selectExerciseForHistory.
  ///
  /// In en, this message translates to:
  /// **'Select an exercise to view its history.'**
  String get selectExerciseForHistory;

  /// No description provided for @myHistory.
  ///
  /// In en, this message translates to:
  /// **'MY HISTORY'**
  String get myHistory;

  /// No description provided for @historyFor.
  ///
  /// In en, this message translates to:
  /// **'HISTORY — {name}'**
  String historyFor(String name);

  /// No description provided for @noSessionsOnEquipment.
  ///
  /// In en, this message translates to:
  /// **'No sessions on this equipment yet.'**
  String get noSessionsOnEquipment;

  /// No description provided for @noSessionsWithExercise.
  ///
  /// In en, this message translates to:
  /// **'No sessions with {name} yet.'**
  String noSessionsWithExercise(String name);

  /// No description provided for @historyCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'History could not be loaded.'**
  String get historyCouldNotLoad;

  /// No description provided for @myXpOnEquipment.
  ///
  /// In en, this message translates to:
  /// **'MY XP ON THIS EQUIPMENT'**
  String get myXpOnEquipment;

  /// No description provided for @xpDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'XP data unavailable.'**
  String get xpDataUnavailable;

  /// No description provided for @xpEarnedOnEquipment.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · earned on this equipment'**
  String xpEarnedOnEquipment(int level);

  /// No description provided for @gymRanking.
  ///
  /// In en, this message translates to:
  /// **'GYM RANKING'**
  String get gymRanking;

  /// No description provided for @noRankingYet.
  ///
  /// In en, this message translates to:
  /// **'No ranking data yet.\nRankings unlock after enough sessions are recorded.'**
  String get noRankingYet;

  /// No description provided for @rankingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ranking unavailable.'**
  String get rankingUnavailable;

  /// No description provided for @myNote.
  ///
  /// In en, this message translates to:
  /// **'MY NOTE'**
  String get myNote;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a personal note for this equipment...'**
  String get noteHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get save;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved.'**
  String get noteSaved;

  /// No description provided for @feedbackToGym.
  ///
  /// In en, this message translates to:
  /// **'FEEDBACK TO GYM'**
  String get feedbackToGym;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Report an issue or suggest an improvement for the gym owner...'**
  String get feedbackHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get send;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent to gym management.'**
  String get feedbackSent;

  /// No description provided for @failedToSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Failed to send feedback. Please try again.'**
  String get failedToSendFeedback;

  /// No description provided for @setsRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'{sets} sets · {reps} reps · {duration}'**
  String setsRepsLabel(int sets, int reps, String duration);

  /// No description provided for @allExercisesChip.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get allExercisesChip;

  /// No description provided for @filterFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get filterFixed;

  /// No description provided for @failedToLoadSessionDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load session details.'**
  String get failedToLoadSessionDetails;

  /// No description provided for @noExercisesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No exercises recorded.'**
  String get noExercisesRecorded;

  /// No description provided for @noSetsLogged.
  ///
  /// In en, this message translates to:
  /// **'No sets logged.'**
  String get noSetsLogged;

  /// No description provided for @rankingConsistency.
  ///
  /// In en, this message translates to:
  /// **'KONSISTENZ'**
  String get rankingConsistency;

  /// No description provided for @rankingEquipment.
  ///
  /// In en, this message translates to:
  /// **'EQUIPMENT'**
  String get rankingEquipment;

  /// No description provided for @rankingMuscleGroup.
  ///
  /// In en, this message translates to:
  /// **'MUSCLE'**
  String get rankingMuscleGroup;

  /// No description provided for @rankingMuscleGroupLocked.
  ///
  /// In en, this message translates to:
  /// **'COMING SOON'**
  String get rankingMuscleGroupLocked;

  /// No description provided for @rankingMuscleGroupLockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Muscle group rankings unlock once your gym\'s equipment has muscle group data configured by the gym admin.'**
  String get rankingMuscleGroupLockedDesc;

  /// No description provided for @rankingBeyondTop3.
  ///
  /// In en, this message translates to:
  /// **'RANKINGS'**
  String get rankingBeyondTop3;

  /// No description provided for @rankingEmptyConsistency.
  ///
  /// In en, this message translates to:
  /// **'No one in this gym has trained yet – be the first!'**
  String get rankingEmptyConsistency;

  /// No description provided for @rankingEmptyEquipment.
  ///
  /// In en, this message translates to:
  /// **'No Equipment XP in this gym yet – be the first!'**
  String get rankingEmptyEquipment;

  /// No description provided for @rankingPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Rankings show members with public profiles only.'**
  String get rankingPrivacyNote;

  /// No description provided for @removeFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove Friend'**
  String get removeFriend;

  /// No description provided for @removeFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'REMOVE FRIEND?'**
  String get removeFriendTitle;

  /// No description provided for @removeFriendContent.
  ///
  /// In en, this message translates to:
  /// **'Remove @{username} from your friends?'**
  String removeFriendContent(String username);

  /// No description provided for @removeFriendBtn.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get removeFriendBtn;

  /// No description provided for @cancelRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'CANCEL REQUEST?'**
  String get cancelRequestTitle;

  /// No description provided for @cancelRequestContent.
  ///
  /// In en, this message translates to:
  /// **'Cancel your request to @{username}?'**
  String cancelRequestContent(String username);

  /// No description provided for @cancelRequestBtn.
  ///
  /// In en, this message translates to:
  /// **'CANCEL REQUEST'**
  String get cancelRequestBtn;

  /// No description provided for @lastTrainedToday.
  ///
  /// In en, this message translates to:
  /// **'Trained today'**
  String get lastTrainedToday;

  /// No description provided for @lastTrainedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Trained yesterday'**
  String get lastTrainedYesterday;

  /// No description provided for @lastTrainedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Trained {days}d ago'**
  String lastTrainedDaysAgo(int days);

  /// No description provided for @friendProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'FRIEND PROFILE'**
  String get friendProfileTitle;

  /// No description provided for @friendTagSameGym.
  ///
  /// In en, this message translates to:
  /// **'SAME GYM'**
  String get friendTagSameGym;

  /// No description provided for @friendTagOtherGym.
  ///
  /// In en, this message translates to:
  /// **'OTHER GYM'**
  String get friendTagOtherGym;

  /// No description provided for @sharedGymsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} shared gyms'**
  String sharedGymsCount(int count);

  /// No description provided for @friendTrainingCalendar.
  ///
  /// In en, this message translates to:
  /// **'TRAINING CALENDAR'**
  String get friendTrainingCalendar;

  /// No description provided for @friendTrainingDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} training days · {year}'**
  String friendTrainingDaysCount(int count, int year);

  /// No description provided for @openCalendarBtn.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get openCalendarBtn;

  /// No description provided for @friendCalendarUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Training calendar is not visible.'**
  String get friendCalendarUnavailable;

  /// No description provided for @friendLastSessionSummary.
  ///
  /// In en, this message translates to:
  /// **'LAST SESSION SUMMARY'**
  String get friendLastSessionSummary;

  /// No description provided for @friendSessionSummaryHidden.
  ///
  /// In en, this message translates to:
  /// **'Session summary is hidden by privacy settings.'**
  String get friendSessionSummaryHidden;

  /// No description provided for @friendSessionSummaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load session summary.'**
  String get friendSessionSummaryUnavailable;

  /// No description provided for @friendSessionDay.
  ///
  /// In en, this message translates to:
  /// **'Session day: {day}'**
  String friendSessionDay(String day);

  /// No description provided for @friendExerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String friendExerciseCount(int count);

  /// No description provided for @friendSetCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String friendSetCount(int count);

  /// No description provided for @xpOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'XP OVERVIEW'**
  String get xpOverviewTitle;

  /// No description provided for @consistencyAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'KONSISTENZ'**
  String get consistencyAxisLabel;

  /// No description provided for @equipmentAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'EQUIPMENT'**
  String get equipmentAxisLabel;

  /// No description provided for @muscleGroupAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'MUSCLE GROUPS'**
  String get muscleGroupAxisLabel;

  /// No description provided for @equipmentXpTitle.
  ///
  /// In en, this message translates to:
  /// **'EXERCISES'**
  String get equipmentXpTitle;

  /// No description provided for @performanceTileTitle.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE'**
  String get performanceTileTitle;

  /// No description provided for @performanceTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exercises ranked by your e1RM improvement trend'**
  String get performanceTileSubtitle;

  /// No description provided for @noPerformanceData.
  ///
  /// In en, this message translates to:
  /// **'No performance data yet.'**
  String get noPerformanceData;

  /// No description provided for @performanceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Performance data could not be loaded.'**
  String get performanceLoadError;

  /// No description provided for @performanceMoreCount.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more'**
  String performanceMoreCount(int count);

  /// No description provided for @performanceSortedByTrend.
  ///
  /// In en, this message translates to:
  /// **'Sorted by performance increase over time.'**
  String get performanceSortedByTrend;

  /// No description provided for @performanceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search exercise…'**
  String get performanceSearchHint;

  /// No description provided for @performanceNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No exercises found.'**
  String get performanceNoSearchResults;

  /// No description provided for @performanceInsufficientData.
  ///
  /// In en, this message translates to:
  /// **'Not enough trend data yet.'**
  String get performanceInsufficientData;

  /// No description provided for @performanceInsufficientDataShort.
  ///
  /// In en, this message translates to:
  /// **'No trend yet'**
  String get performanceInsufficientDataShort;

  /// No description provided for @performanceTrendSummary.
  ///
  /// In en, this message translates to:
  /// **'{kg} ({percent})'**
  String performanceTrendSummary(String kg, String percent);

  /// No description provided for @performanceDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE — {name}'**
  String performanceDetailTitle(String name);

  /// No description provided for @performanceLatestE1rm.
  ///
  /// In en, this message translates to:
  /// **'LATEST E1RM'**
  String get performanceLatestE1rm;

  /// No description provided for @performanceBestE1rm.
  ///
  /// In en, this message translates to:
  /// **'BEST E1RM'**
  String get performanceBestE1rm;

  /// No description provided for @performanceTrackedSessions.
  ///
  /// In en, this message translates to:
  /// **'TRACKED SESSIONS'**
  String get performanceTrackedSessions;

  /// No description provided for @performanceTrend.
  ///
  /// In en, this message translates to:
  /// **'TREND'**
  String get performanceTrend;

  /// No description provided for @muscleGroupEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Muscle group tracking activates once your gym\'s equipment has muscle group data configured.'**
  String get muscleGroupEmptyState;

  /// No description provided for @showAllBtn.
  ///
  /// In en, this message translates to:
  /// **'SHOW ALL'**
  String get showAllBtn;

  /// No description provided for @collapseBtn.
  ///
  /// In en, this message translates to:
  /// **'SHOW LESS'**
  String get collapseBtn;

  /// No description provided for @createPlanFromSessionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create plan from session'**
  String get createPlanFromSessionTooltip;

  /// No description provided for @createPlanFromSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'CREATE PLAN FROM SESSION'**
  String get createPlanFromSessionTitle;

  /// No description provided for @planNameHintCreateFromSession.
  ///
  /// In en, this message translates to:
  /// **'Plan name...'**
  String get planNameHintCreateFromSession;

  /// No description provided for @createPlanBtn.
  ///
  /// In en, this message translates to:
  /// **'CREATE'**
  String get createPlanBtn;

  /// No description provided for @planCreatedFromSessionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plan \"{name}\" created.'**
  String planCreatedFromSessionSuccess(String name);

  /// No description provided for @planCreatedFromSessionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create plan. Please try again.'**
  String get planCreatedFromSessionFailed;

  /// No description provided for @strengthProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'E1RM PROGRESS'**
  String get strengthProgressTitle;

  /// No description provided for @e1rmChartEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Complete more sessions to see your E1RM progress.'**
  String get e1rmChartEmptyState;

  /// No description provided for @navNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get navNutrition;

  /// No description provided for @muscleGroupTrained.
  ///
  /// In en, this message translates to:
  /// **'TRAINED'**
  String get muscleGroupTrained;

  /// No description provided for @muscleGroupNeglected.
  ///
  /// In en, this message translates to:
  /// **'NEGLECTED'**
  String get muscleGroupNeglected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
