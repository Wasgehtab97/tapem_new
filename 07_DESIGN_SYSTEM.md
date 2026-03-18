# 07 Design System

## Design Tokens
- Farbrollen: `surface`, `text`, `action`, `success`, `warning`, `error`.
- Typografie-Skala mit klaren Einsatzbereichen.
- Spacing- und Radius-System in festen Schritten.
- Motion-Regeln mit wenigen wiederverwendbaren Mustern.
- Theme-Presets als token-basierte Varianten:
  `default`, `energy`, `minimal`.

## Kernkomponenten fuer V1
- WorkoutStartCard
- EquipmentTypeSelector
- EquipmentPicker
- UserExerciseQuickCreate
- CardioTimerLogger
- ActiveSetLogger
- SyncStateBadge
- ProgressCard
- XPProgressCard
- LevelBadge
- XPGainToast
- AchievementToast
- RankingList
- ChallengeCard
- UsernameInput
- UserSearchList
- FriendRequestCard
- FriendListItem
- FriendTrainingDayCard
- ThemePickerCard
- Basisbausteine: Inputs, Buttons, Cards, Lists, Empty States, Dialoge, Toasts, Charts

## Zustandsmodell
Jeder Baustein hat Varianten fuer:
- `default`
- `focus`
- `active`
- `disabled`
- `loading`
- `error`
- `offline_pending`

## Komponentenvertrag
- Jede Kernkomponente definiert Props, States, Analytics-Events und Accessibility-Verhalten.
- Jede Kernkomponente hat mindestens einen visuell dokumentierten Fehlerzustand.
- Jede Kernkomponente muss in Storybook oder aequivalenter Doku reproduzierbar sein.

## Responsivitaet
- Mobile first.
- Tablet erhoeht Informationsdichte statt nur Abstand.
- Kein funktionskritischer Unterschied zwischen Smartphone- und Tablet-Flow.

## Nicht erlaubt
- Feature-spezifische Sonderkomponenten ohne Systembegruendung.
- Unterschiedliche Begriffe fuer denselben Workout-Status.
- Inkompatible Komponentenversionen fuer gleiche Kernmuster.
