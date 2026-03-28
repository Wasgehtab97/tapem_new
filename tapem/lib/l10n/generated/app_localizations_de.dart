// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navGym => 'Gym';

  @override
  String get navProgress => 'Progress';

  @override
  String get navCommunity => 'Community';

  @override
  String get navWorkout => 'Training';

  @override
  String get navAdmin => 'Admin';

  @override
  String get appTagline => 'TRACKE. ENTWICKLE DICH. KONKURRIERE.';

  @override
  String get emailLabel => 'E-MAIL';

  @override
  String get passwordLabel => 'PASSWORT';

  @override
  String get forgotPassword => 'PASSWORT VERGESSEN?';

  @override
  String get signIn => 'ANMELDEN';

  @override
  String get signUp => 'REGISTRIEREN';

  @override
  String get noAccount => 'Noch kein Konto? ';

  @override
  String get emailRequired => 'E-Mail erforderlich';

  @override
  String get invalidEmail => 'Ungültige E-Mail';

  @override
  String get passwordMinLength => 'Mind. 8 Zeichen';

  @override
  String get enterEmailFirst => 'Bitte zuerst E-Mail eingeben';

  @override
  String get passwordResetSent => 'Passwort-Reset wurde gesendet';

  @override
  String get createAccount => 'KONTO ERSTELLEN';

  @override
  String get joinGymTagline => 'Verbinde dich mit deinem Gym auf Tap\'em.';

  @override
  String get confirmPasswordLabel => 'PASSWORT BESTÄTIGEN';

  @override
  String get passwordsNoMatch => 'Passwörter stimmen nicht überein';

  @override
  String get alreadyHaveAccount => 'Bereits ein Konto? ';

  @override
  String get chooseYourUsername => 'WÄHLE DEINEN\nBENUTZERNAMEN';

  @override
  String get usernamePublicHint =>
      'Dein Benutzername ist im Gym öffentlich sichtbar. Du kannst ihn später ändern.';

  @override
  String get usernameLabel => 'BENUTZERNAME';

  @override
  String get usernameSuggestions => 'VORSCHLÄGE';

  @override
  String get usernameRequired => 'Benutzername erforderlich';

  @override
  String get usernameInvalid =>
      '3–20 Zeichen, Kleinbuchstaben, Zahlen, _ und . erlaubt';

  @override
  String get usernameTaken => 'Benutzername bereits vergeben';

  @override
  String get continueBtn => 'WEITER';

  @override
  String get joinYourGym => 'GYM BEITRETEN';

  @override
  String get gymCodeDescription =>
      'Gib den Gym-Code deines Gyms ein. Du kannst das Gym jederzeit in deinem Profil wechseln.';

  @override
  String get yourGyms => 'DEINE GYMS';

  @override
  String get joinAnotherGym => 'EINEM WEITEREN GYM BEITRETEN';

  @override
  String get noGymMembership => 'NOCH KEIN GYM-MITGLIED';

  @override
  String get askGymForCode =>
      'Frage dein Gym nach dem Gym-Code und gib ihn unten ein, um loszulegen.';

  @override
  String get gymCodeLabel => 'GYM-CODE';

  @override
  String get gymCodeEmpty => 'Bitte Gym-Code eingeben.';

  @override
  String get invalidGymCode =>
      'Ungültiger Gym-Code. Bitte überprüfen und erneut versuchen.';

  @override
  String get somethingWentWrong =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get joinGymBtn => 'GYM BEITRETEN';

  @override
  String failedToLoadGyms(String error) {
    return 'Gyms konnten nicht geladen werden: $error';
  }

  @override
  String get welcomeBack => 'WILLKOMMEN ZURÜCK';

  @override
  String welcomeBackUser(String username) {
    return 'WILLKOMMEN ZURÜCK, @$username';
  }

  @override
  String get errorLoadingProfile => 'Fehler beim Laden des Profils';

  @override
  String get noProfile => 'Kein Profil';

  @override
  String get checkingForSession => 'Aktive Session wird gesucht…';

  @override
  String get workoutInProgress => 'TRAINING LÄUFT';

  @override
  String startedAt(String time) {
    return 'Gestartet um $time';
  }

  @override
  String get continueWorkout => 'TRAINING FORTSETZEN';

  @override
  String get discard => 'VERWERFEN';

  @override
  String get discardWorkoutTitle => 'TRAINING VERWERFEN?';

  @override
  String get discardWorkoutContent =>
      'Alle Sätze dieser Session werden dauerhaft gelöscht.';

  @override
  String get keep => 'BEHALTEN';

  @override
  String get quickStart => 'SCHNELLSTART';

  @override
  String get startWorkout => 'TRAINING STARTEN';

  @override
  String get startWorkoutHint => 'Freestyle oder nach Plan trainieren';

  @override
  String get recentSessions => 'LETZTE SESSIONS';

  @override
  String get seeAll => 'ALLE ANZEIGEN';

  @override
  String get noSessionsYetShort =>
      'Noch keine Sessions.\nStarte dein erstes Training!';

  @override
  String get couldNotLoadSessions => 'Sessions konnten nicht geladen werden.';

  @override
  String get allSessions => 'ALLE SESSIONS';

  @override
  String get freestyleTitle => 'FREESTYLE';

  @override
  String get freestyleDescription =>
      'Sofort starten — Übungen\nhinzufügen über den Gym-Tab.';

  @override
  String get fromPlanTitle => 'NACH PLAN';

  @override
  String get fromPlanDescription => 'Folge einem deiner Trainingspläne.';

  @override
  String get choosePlan => 'PLAN WÄHLEN';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Übungen',
      one: '1 Übung',
    );
    return '$_temp0';
  }

  @override
  String setCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze',
      one: '1 Satz',
    );
    return '$_temp0';
  }

  @override
  String get noActiveGym => 'Kein aktives Gym.';

  @override
  String get searchEquipmentLabel => 'Suche';

  @override
  String get searchEquipmentHint => 'Geräte suchen...';

  @override
  String get tapMachineToAdd =>
      'Tippe auf ein Gerät, um es zum Training hinzuzufügen';

  @override
  String get noFavouritesYet =>
      'Noch keine Favoriten.\nTippe auf ★ bei einem Gerät.';

  @override
  String get noEquipmentFound =>
      'Keine Geräte gefunden.\nBitte den Gym-Admin, Geräte hinzuzufügen.';

  @override
  String get errorLoadingEquipment => 'Fehler beim Laden der Geräte';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterMachines => 'Maschinen';

  @override
  String get filterOpen => 'Multi';

  @override
  String get filterCardio => 'Cardio';

  @override
  String get filterFavs => '★ FAVS';

  @override
  String get machineTypeLabel => 'MASCHINE';

  @override
  String get openTypeLabel => 'OFFEN';

  @override
  String get cardioTypeLabel => 'CARDIO';

  @override
  String get discardWorkoutFullTitle => 'TRAINING VERWERFEN?';

  @override
  String get discardWorkoutFullContent =>
      'Alle Sätze und Fortschritte dieser Session werden dauerhaft gelöscht. Nichts wird gespeichert oder synchronisiert.';

  @override
  String get leaveWorkoutTitle => 'TRAINING VERLASSEN?';

  @override
  String get leaveWorkoutContent =>
      'Dein Training läuft noch. Nicht abgehakte Sätze gehen verloren — nur abgehakte Sätze werden beim Tippen auf FERTIG gespeichert.';

  @override
  String get finishWorkoutTitle => 'TRAINING BEENDEN?';

  @override
  String get finishWorkoutContent =>
      'Alle abgehakten Sätze werden gespeichert und synchronisiert.';

  @override
  String get stay => 'BLEIBEN';

  @override
  String get leave => 'VERLASSEN';

  @override
  String get finish => 'FERTIG';

  @override
  String get cancel => 'ABBRECHEN';

  @override
  String get addExercise => 'GERÄT HINZUFÜGEN';

  @override
  String get discardWorkoutMenu => 'Training verwerfen';

  @override
  String get workoutDiscardedSnack =>
      'Training verworfen. Nichts wurde gespeichert.';

  @override
  String get cancelTimer => 'Timer abbrechen';

  @override
  String get removeExerciseTitle => 'ÜBUNG ENTFERNEN?';

  @override
  String removeExerciseContent(String name) {
    return 'Alle Sätze für \"$name\" werden entfernt.';
  }

  @override
  String get remove => 'ENTFERNEN';

  @override
  String get sessionStarted => 'Session gestartet!';

  @override
  String get addExerciseHint =>
      'Tippe unten auf \"Gerät hinzufügen\" oder wähle im Gym-Tab.';

  @override
  String get addSet => 'SATZ HINZUFÜGEN';

  @override
  String get setColumnHeader => 'SATZ';

  @override
  String get prevColumnHeader => 'VORIG';

  @override
  String get kgColumnHeader => 'KG';

  @override
  String get repsColumnHeader => 'WDHL';

  @override
  String get startTimer => 'TIMER STARTEN';

  @override
  String get stopAndLog => 'STOPP & LOG';

  @override
  String get equipmentDetails => 'Gerätedetails';

  @override
  String get progressTitle => 'FORTSCHRITT';

  @override
  String get trainingCalendar => 'TRAININGSKALENDER';

  @override
  String get expand => 'VERGRÖßERN';

  @override
  String get failedToLoadCalendar => 'Kalender konnte nicht geladen werden';

  @override
  String trainingDaysThisYear(int count) {
    return '$count Trainingstage dieses Jahr';
  }

  @override
  String get failedToLoadXp => 'XP konnte nicht geladen werden';

  @override
  String get topEquipment => 'TOP-GERÄTE';

  @override
  String get noExerciseData => 'Noch keine Übungsdaten.';

  @override
  String get muscleGroups => 'MUSKELGRUPPEN';

  @override
  String get noMuscleGroupData => 'Noch keine Muskelgruppendaten.';

  @override
  String get trainingDayXp => 'TRAININGSTAG XP';

  @override
  String get noXpYet => 'Noch kein XP. Starte dein erstes Training!';

  @override
  String xpTotal(int xp) {
    return '$xp XP gesamt';
  }

  @override
  String xpToNextLevel(int xp) {
    return '$xp XP bis nächstes Level';
  }

  @override
  String get trainingPlansTile => 'TRAININGSPLÄNE';

  @override
  String get createManagePlans => 'Trainingspläne erstellen und verwalten';

  @override
  String get noSessionsYetLong =>
      'Noch keine Sessions. Starte dein erstes Training!';

  @override
  String get communityTitle => 'COMMUNITY';

  @override
  String get findFriendsTooltip => 'Freunde finden';

  @override
  String get friendsTab => 'FREUNDE';

  @override
  String get rankingsTab => 'RANGLISTE';

  @override
  String requestsSection(int count) {
    return 'ANFRAGEN ($count)';
  }

  @override
  String friendsSection(int count) {
    return 'FREUNDE ($count)';
  }

  @override
  String friendsSameGymSection(int count) {
    return 'DEIN GYM ($count)';
  }

  @override
  String friendsOtherGymsSection(int count) {
    return 'ANDERE GYMS ($count)';
  }

  @override
  String pendingSection(int count) {
    return 'AUSSTEHEND ($count)';
  }

  @override
  String get pendingBadge => 'AUSSTEHEND';

  @override
  String get friendStatusFriends => 'FREUND';

  @override
  String get noFriendsYet => 'NOCH KEINE FREUNDE';

  @override
  String get findGymMembers => 'Finde Gym-Mitglieder zum Verbinden.';

  @override
  String get findFriendsBtn => 'FREUNDE FINDEN';

  @override
  String get friendInYourGym => 'In deinem aktiven Gym';

  @override
  String friendFromOtherGyms(int count) {
    return 'Andere Gyms ($count gemeinsam)';
  }

  @override
  String searchMyGymSection(int count) {
    return 'MEIN GYM ($count)';
  }

  @override
  String searchOtherGymsSection(int count) {
    return 'ANDERE GYMS ($count)';
  }

  @override
  String lastTrained(String date) {
    return 'Zuletzt trainiert: $date';
  }

  @override
  String get noRankingData =>
      'Noch keine Rangliste.\nSchließe ein Training ab, um XP zu erhalten!';

  @override
  String get gymXpLeaderboard => 'GYM XP RANGLISTE';

  @override
  String get findFriendsSheetTitle => 'FREUNDE FINDEN';

  @override
  String get searchByUsername => 'Nach Benutzername suchen...';

  @override
  String noUsersFound(String query) {
    return 'Keine Nutzer gefunden für \"$query\"';
  }

  @override
  String get typeToSearch => 'Mindestens 2 Zeichen eingeben.';

  @override
  String get addFriendBtn => 'HINZUFÜGEN';

  @override
  String get acceptTooltip => 'Annehmen';

  @override
  String get declineTooltip => 'Ablehnen';

  @override
  String get profileTitle => 'PROFIL';

  @override
  String get profileNavLabel => 'Profil';

  @override
  String get usernameSection => 'BENUTZERNAME';

  @override
  String get themeSection => 'DESIGN';

  @override
  String get themeDefault => 'STANDARD';

  @override
  String get themeEnergy => 'ENERGIE';

  @override
  String get themeMinimal => 'MINIMAL';

  @override
  String get privacySection => 'AKTIVITÄTS-DATENSCHUTZ';

  @override
  String get privacyPrivate => 'PRIVAT';

  @override
  String get privacyPrivateDescription =>
      'Keine Aktivität für Freunde sichtbar';

  @override
  String get privacyTrainingDays => 'TRAININGSTAGE';

  @override
  String get privacyTrainingDaysDescription =>
      'Freunde sehen nur deine Trainingstage';

  @override
  String get privacySummary => 'ZUSAMMENFASSUNG';

  @override
  String get privacySummaryDescription =>
      'Freunde sehen Trainingstage und Session-Zusammenfassungen';

  @override
  String get signOut => 'ABMELDEN';

  @override
  String get languageSection => 'SPRACHE';

  @override
  String get trainingPlansTitle => 'TRAININGSPLÄNE';

  @override
  String get newPlanTooltip => 'Neuer Plan';

  @override
  String get noPlansYet => 'NOCH KEINE PLÄNE';

  @override
  String get noPlansDescription =>
      'Erstelle deinen ersten Trainingsplan\nfür strukturierte Workouts.';

  @override
  String get createFirstPlan => 'ERSTEN PLAN ERSTELLEN';

  @override
  String get createNewPlan => 'NEUEN PLAN ERSTELLEN';

  @override
  String get updatedToday => 'Heute aktualisiert';

  @override
  String get updatedYesterday => 'Gestern aktualisiert';

  @override
  String updatedDaysAgo(int count) {
    return 'Vor ${count}d aktualisiert';
  }

  @override
  String updatedDate(String date) {
    return 'Aktualisiert am $date';
  }

  @override
  String get editPlan => 'PLAN BEARBEITEN';

  @override
  String get newPlan => 'NEUER PLAN';

  @override
  String get deletePlanTooltip => 'Plan löschen';

  @override
  String get deletePlanTitle => 'PLAN LÖSCHEN?';

  @override
  String get deletePlanContent => 'Dieser Plan wird dauerhaft entfernt.';

  @override
  String get delete => 'LÖSCHEN';

  @override
  String get planNameLabel => 'PLANNAME';

  @override
  String get noExercisesYet => 'NOCH KEINE ÜBUNGEN';

  @override
  String get noExercisesHint =>
      'Füge Übungen aus deinen Gym-\nGeräten hinzu, um den Plan zu erstellen.';

  @override
  String get addFirstExercise => 'ERSTE ÜBUNG HINZUFÜGEN';

  @override
  String get addExerciseToPlan => '+ ÜBUNG HINZUFÜGEN';

  @override
  String get saveChanges => 'ÄNDERUNGEN SPEICHERN';

  @override
  String get savePlan => 'PLAN SPEICHERN';

  @override
  String get addExercisePicker => 'ÜBUNG HINZUFÜGEN';

  @override
  String get searchLabel => 'SUCHE';

  @override
  String get filterEquipment => 'Geräte filtern...';

  @override
  String get noEquipmentFoundShort => 'Keine Geräte gefunden.';

  @override
  String get fixedBadge => 'FIX';

  @override
  String get openBadge => 'OFFEN';

  @override
  String get cardioBadge => 'CARDIO';

  @override
  String get myExercises => 'MEINE ÜBUNGEN';

  @override
  String get noExercisesAtStation =>
      'Noch keine Übungen an dieser Station erstellt.';

  @override
  String get myHistory => 'MEINE HISTORIE';

  @override
  String historyFor(String name) {
    return 'HISTORIE — $name';
  }

  @override
  String get noSessionsOnEquipment => 'Noch keine Sessions an diesem Gerät.';

  @override
  String noSessionsWithExercise(String name) {
    return 'Noch keine Sessions mit $name.';
  }

  @override
  String get historyCouldNotLoad => 'Historie konnte nicht geladen werden.';

  @override
  String get myXpOnEquipment => 'MEIN XP AN DIESEM GERÄT';

  @override
  String get xpDataUnavailable => 'XP-Daten nicht verfügbar.';

  @override
  String xpEarnedOnEquipment(int level) {
    return 'Level $level · an diesem Gerät erarbeitet';
  }

  @override
  String get gymRanking => 'GYM RANGLISTE';

  @override
  String get noRankingYet =>
      'Noch keine Rangliste.\nRanglisten werden nach ausreichend Sessions freigeschaltet.';

  @override
  String get rankingUnavailable => 'Rangliste nicht verfügbar.';

  @override
  String get myNote => 'MEINE NOTIZ';

  @override
  String get noteHint => 'Persönliche Notiz zu diesem Gerät...';

  @override
  String get save => 'SPEICHERN';

  @override
  String get noteSaved => 'Notiz gespeichert.';

  @override
  String get feedbackToGym => 'FEEDBACK AN GYM';

  @override
  String get feedbackHint => 'Problem melden oder Verbesserung vorschlagen...';

  @override
  String get send => 'SENDEN';

  @override
  String get feedbackSent => 'Feedback an die Gym-Verwaltung gesendet.';

  @override
  String get failedToSendFeedback =>
      'Feedback konnte nicht gesendet werden. Bitte erneut versuchen.';

  @override
  String setsRepsLabel(int sets, int reps, String duration) {
    return '$sets Sätze · $reps Wdhl · $duration';
  }

  @override
  String get allExercisesChip => 'ALLE';

  @override
  String get filterFixed => 'Fix';

  @override
  String get failedToLoadSessionDetails =>
      'Session konnte nicht geladen werden.';

  @override
  String get noExercisesRecorded => 'Keine Übungen aufgezeichnet.';

  @override
  String get noSetsLogged => 'Keine Sätze geloggt.';

  @override
  String get rankingConsistency => 'KONSISTENZ';

  @override
  String get rankingEquipment => 'GERÄTE';

  @override
  String get rankingMuscleGroup => 'MUSKELN';

  @override
  String get rankingMuscleGroupLocked => 'DEMNÄCHST';

  @override
  String get rankingMuscleGroupLockedDesc =>
      'Muskelgruppen-Rankings werden freigeschaltet, sobald das Gym-Equipment mit Muskelgruppen-Daten konfiguriert wurde.';

  @override
  String get rankingBeyondTop3 => 'RANGLISTE';

  @override
  String get rankingEmptyConsistency =>
      'Noch hat niemand im Gym trainiert – sei der Erste!';

  @override
  String get rankingEmptyEquipment =>
      'Noch keine Geräte-XP im Gym – trainiere als Erster!';

  @override
  String get rankingPrivacyNote =>
      'Die Rangliste zeigt nur Mitglieder mit öffentlichem Profil.';

  @override
  String get removeFriend => 'Freundschaft entfernen';

  @override
  String get removeFriendTitle => 'FREUNDSCHAFT AUFHEBEN?';

  @override
  String removeFriendContent(String username) {
    return '@$username aus deinen Freunden entfernen?';
  }

  @override
  String get removeFriendBtn => 'ENTFERNEN';

  @override
  String get cancelRequestTitle => 'ANFRAGE ABBRECHEN?';

  @override
  String cancelRequestContent(String username) {
    return 'Deine Anfrage an @$username abbrechen?';
  }

  @override
  String get cancelRequestBtn => 'ANFRAGE ABBRECHEN';

  @override
  String get lastTrainedToday => 'Heute trainiert';

  @override
  String get lastTrainedYesterday => 'Gestern trainiert';

  @override
  String lastTrainedDaysAgo(int days) {
    return 'Vor $days Tagen trainiert';
  }

  @override
  String get friendProfileTitle => 'FREUNDESPROFIL';

  @override
  String get friendTagSameGym => 'GLEICHES GYM';

  @override
  String get friendTagOtherGym => 'ANDERES GYM';

  @override
  String sharedGymsCount(int count) {
    return '$count gemeinsame Gyms';
  }

  @override
  String get friendTrainingCalendar => 'TRAININGSKALENDER';

  @override
  String friendTrainingDaysCount(int count, int year) {
    return '$count Trainingstage · $year';
  }

  @override
  String get openCalendarBtn => 'ÖFFNEN';

  @override
  String get friendCalendarUnavailable =>
      'Trainingskalender ist nicht sichtbar.';

  @override
  String get friendLastSessionSummary => 'LETZTE SESSION-ZUSAMMENFASSUNG';

  @override
  String get friendSessionSummaryHidden =>
      'Session-Zusammenfassung ist durch Privatsphäre ausgeblendet.';

  @override
  String get friendSessionSummaryUnavailable =>
      'Session-Zusammenfassung konnte nicht geladen werden.';

  @override
  String friendSessionDay(String day) {
    return 'Session-Tag: $day';
  }

  @override
  String friendExerciseCount(int count) {
    return '$count Übungen';
  }

  @override
  String friendSetCount(int count) {
    return '$count Sätze';
  }

  @override
  String get xpOverviewTitle => 'XP ÜBERSICHT';

  @override
  String get consistencyAxisLabel => 'KONSISTENZ';

  @override
  String get equipmentAxisLabel => 'GERÄTE';

  @override
  String get muscleGroupAxisLabel => 'MUSKELGRUPPEN';

  @override
  String get equipmentXpTitle => 'ÜBUNGEN';

  @override
  String get muscleGroupEmptyState =>
      'Muskelgruppen-Tracking aktiviert sich, sobald das Equipment des Gyms konfiguriert wurde.';

  @override
  String get showAllBtn => 'ALLE ANZEIGEN';

  @override
  String get collapseBtn => 'WENIGER ANZEIGEN';

  @override
  String get createPlanFromSessionTooltip => 'Plan aus Session erstellen';

  @override
  String get createPlanFromSessionTitle => 'PLAN AUS SESSION ERSTELLEN';

  @override
  String get planNameHintCreateFromSession => 'Planname...';

  @override
  String get createPlanBtn => 'ERSTELLEN';

  @override
  String planCreatedFromSessionSuccess(String name) {
    return 'Plan \"$name\" erstellt.';
  }

  @override
  String get planCreatedFromSessionFailed =>
      'Plan konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get strengthProgressTitle => 'E1RM FORTSCHRITT';

  @override
  String get e1rmChartEmptyState =>
      'Absolviere mehr Sessions, um deinen E1RM-Fortschritt zu sehen.';

  @override
  String get navNutrition => 'Ernährung';

  @override
  String get muscleGroupTrained => 'TRAINIERT';

  @override
  String get muscleGroupNeglected => 'VERNACHLÄSSIGT';
}
