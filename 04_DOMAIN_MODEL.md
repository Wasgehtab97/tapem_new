# 04 Domain Model

## Zentrale Entitaeten (V1)
- TenantGym
- User
- UserProfile
- UsernameReservation
- Membership
- GymEquipment
- EquipmentTag
- ExerciseTemplate
- UserCustomExercise
- WorkoutPlan
- PlanAssignment
- WorkoutSession
- SessionExercise
- SetEntry
- ProgressMetric
- XPEvent
- UserGymXP
- UserExerciseXP
- UserMuscleGroupXP
- LevelSnapshot
- Achievement
- Challenge
- RankingEvent
- RankingSnapshot
- FeedEvent
- Friendship
- FriendRequest
- FriendActivityView
- UserThemePreference
- Notification

## Nicht-V1 Entitaeten
- PartnerBrand
- GymDealCampaign
- DealRedemption
- CrossGymLeaderboard

## Kernregeln
- Jede fachliche Aktion traegt immer `gymId`.
- Schreibende Aktionen pruefen immer Rolle und Membership.
- XP, Level und Ranking werden ausschliesslich serverseitig berechnet.
- WorkoutSession hat einen unveraenderlichen Starttag-Anker (`session_day_anchor`).
- Idempotenz ist Pflicht fuer alle kritischen Write-Pfade.
- NFC-Tag-Zuordnungen werden serverseitig validiert und versioniert.
- `gym_equipment.equipment_type` ist verpflichtend:
  `fixed_machine`, `open_station`, `cardio`.
- `fixed_machine` hat genau eine kanonische Hauptuebung als Default.
- `open_station` erlaubt mehrere Uebungen, inklusive `user_custom_exercises`.
- `cardio` unterstuetzt mindestens Zeittracking.
- `user_profiles.username` ist app-weit eindeutig und case-insensitive.
- Friendships sind in V1 gym-intern.
- Sichtbarkeit von Trainingstagen und Aktivitaet folgt expliziten Privacy-Einstellungen.

## Fachliche Invarianten
- Keine Datenanzeige ohne Berechtigung.
- Keine gym-uebergreifende Datenvermischung in V1.
- Ein SetEntry gehoert genau zu einer SessionExercise in genau einem Gym-Kontext.
- Ein XPEvent wird pro Quelle und XP-Dimension hoechstens einmal verarbeitet.
- Eine UserCustomExercise gehoert genau einem User in genau einem Gym.
- Theme-Praeferenzen steuern nur die UI-Darstellung, nie Fachlogik.

## Modellierungsleitlinie
Alle neuen Entitaeten muessen vor Umsetzung mindestens diese Fragen beantworten:
- Welche Invarianten gelten fachlich?
- Welche Rollen duerfen lesen/schreiben?
- Welche Idempotenz- und Audit-Anforderungen gelten?
