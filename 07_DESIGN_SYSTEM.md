# 07 Design System

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


## Design Tokens
- Farbrollen: `surface`, `text`, `action`, `success`, `warning`, `error`.
- Typografie-Skala mit klaren Einsatzbereichen.
- Spacing- und Radius-System in festen Schritten.
- Motion-Regeln mit wenigen wiederverwendbaren Mustern.
- Theme-Presets als token-basierte Varianten:
  `default`, `energy`, `minimal`.

## Visuelle Baseline fuer MVP
- Der gesamte V1-MVP wird in einem einheitlichen `cyberpunk`-Stil umgesetzt.
- Die visuelle Sprache ist komponenten- und layoutbasiert verbindlich; konkrete Farbtokens koennen spaeter unter Design-Governance angepasst werden.
- `default`, `energy`, `minimal` bleiben als Theme-Presets bestehen, muessen aber dieselbe Cyberpunk-Formensprache und dieselben Interaktionsmuster verwenden.
- Trainingstag- und Friend-Activity-Visualisierungen folgen derselben Cyberpunk-Baseline.

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
- TrainingDayCalendar
- TrainingDayCalendarDialog
- TrainingDayHeatmapGrid
- TrainingDayHeatmapCell
- ThemePickerCard
- Basisbausteine: Inputs, Buttons, Cards, Lists, Empty States, Dialoge, Toasts, Charts

## Trainingstag-Kalender UI-Spezifikation (V1)
- Darstellung als Jahres-Heatmap mit Wochen als Spalten und 7 Tagen als Zeilen.
- Monatsleiste ueber dem Grid mit 12 Monatslabels in kurzer Form (2 Zeichen), gleichmaessig ueber die Gesamtbreite verteilt.
- Optionaler Jahreskopf mit Navigation (links/rechts) fuer Jahreswechsel.
- Preview-Variante (Card): statisch eingebettet, ohne horizontales Scrollen.
- Detail-Variante (Dialog): horizontal scrollbar, zentrierter Initialfokus auf der relevanten Woche.

## Trainingstag-Kalender Layout und Spacing (V1)
- Grid-Innenabstand horizontal: `16px` je Seite.
- Grid-Cell-Abstand (Preview): `margin 1px` rundum.
- Grid-Cell-Abstand (Dialog): `margin 2px` rundum.
- Grid-Cell-Groesse (Preview): responsiv aus verfuegbarer Breite berechnet.
- Grid-Cell-Groesse (Dialog): feste Basis von `24px` je Zelle.
- Abstand Monatsleiste zu Grid: `4px`.
- Monatsleistenhoehe: `20px`.
- Dialog-Innenabstand: `24px`.
- Dialogbereich fuer Kalender: fixe Hoehe `300px`.

## Trainingstag-Kalender Zelllogik (V1)
- `training day`: gefuellte Zelle.
- `non-training day`: ungefuellte Zelle mit subtiler Outline.
- `today`: visuell hervorgehobene Outline mit staerkerer Border-Breite.
- Optionale Plan- oder Sondermarkierung ueber Border-Variation, ohne das Grundraster zu brechen.
- Optionale Tageszahlen nur in der Detail-Variante.

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
- Jede Kernkomponente ist als wiederverwendbares Flutter-Widget spezifiziert.
- Jede Kernkomponente muss in Storybook oder aequivalenter Doku reproduzierbar sein.
- Jede Kernkomponente besitzt stabile Test-IDs fuer kritische E2E-Szenarien.

## Responsivitaet
- Mobile first.
- Tablet erhoeht Informationsdichte statt nur Abstand.
- Kein funktionskritischer Unterschied zwischen Smartphone- und Tablet-Flow.
- Landscape- und Portrait-Layouts behalten identische Kernaktionen in gleicher Reihenfolge.

## Nicht erlaubt
- Feature-spezifische Sonderkomponenten ohne Systembegruendung.
- Unterschiedliche Begriffe fuer denselben Workout-Status.
- Inkompatible Komponentenversionen fuer gleiche Kernmuster.
