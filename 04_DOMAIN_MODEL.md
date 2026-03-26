# 04 Domain Model

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


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
- PlanItem
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

## TenantGym — Schluessel-Attribute
- `join_code`: kurzer, einzigartiger, case-insensitiver Alphanumeric-Code (6–8 Zeichen), den der Gym-Betreiber an Mitglieder verteilt.
- Gyms werden nur durch den Plattformbetreiber angelegt (Service-Role). Member-Apps haben kein INSERT-Recht auf `tenant_gyms`.
- Gym-Beitritt durch Member: `join_gym_with_code(code)` — eine serverseitige Funktion (SECURITY DEFINER), die Code prueft und Membership anlegt.

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
- Theme-Praeferenzen sind rein praesentationsbezogen und duerfen keine Fachlogik beeinflussen.

## Fachliche Invarianten
- Keine Datenanzeige ohne Berechtigung.
- Keine gym-uebergreifende Datenvermischung in V1.
- Ein SetEntry gehoert genau zu einer SessionExercise in genau einem Gym-Kontext.
- Ein XPEvent wird pro Quelle und XP-Dimension hoechstens einmal verarbeitet.
- Eine UserCustomExercise gehoert genau einem User in genau einem Gym.
- Eine Friendship ist nur gueltig, wenn beide User aktive Membership im selben Gym besitzen.

## WorkoutPlan — Detailspezifikation

### Attribute
- `id`: UUID, PK
- `gym_id`: UUID, FK → tenant_gyms (Mandantentrennung)
- `created_by`: UUID, FK → auth.users (Eigentuemer)
- `name`: TEXT, 1–50 Zeichen, NOT NULL
- `description`: TEXT, optional
- `is_public`: BOOLEAN, DEFAULT FALSE (reserviert fuer Coach-Plaene in V1)
- `is_active`: BOOLEAN, DEFAULT TRUE (Soft-Delete)
- `created_at`, `updated_at`: TIMESTAMPTZ

### Rollen
- Member: kann eigene Plaene erstellen, bearbeiten, deaktivieren (Soft-Delete), lesen.
- Coach: kann Plaene erstellen und anderen Membern zuweisen (via PlanAssignment).
- Admin/Owner: lesender Zugriff auf alle Plaene im Gym.

### Invarianten
- Ein WorkoutPlan gehoert exklusiv genau einem User (`created_by`) in genau einem Gym.
- Name ist Pflicht und nach Erstellung jederzeit aenderbar.
- Deaktivierte Plaene (`is_active = FALSE`) werden im Client nicht angezeigt, bleiben aber in der Datenbank erhalten.
- Max. 50 PlanItems pro WorkoutPlan.
- Ein WorkoutPlan ohne PlanItems ist zulaessig (Erstellungsstatus) aber nicht startbar.

---

## PlanItem — Detailspezifikation

### Attribute
- `id`: UUID, PK
- `plan_id`: UUID, FK → workout_plans ON DELETE CASCADE
- `gym_id`: UUID, FK → tenant_gyms (denormalisiert fuer RLS)
- `equipment_id`: UUID, FK → gym_equipment ON DELETE CASCADE
- `canonical_exercise_key`: TEXT, nullable — gesetzt fuer fixed_machine
- `custom_exercise_id`: UUID, nullable FK → user_custom_exercises ON DELETE SET NULL — gesetzt fuer open_station
- `display_name`: TEXT, NOT NULL — denormalisiert fuer joinfreie Anzeige
- `position`: SMALLINT, NOT NULL, >= 0 — Reihenfolge im Plan

### Invarianten
- `position` ist eindeutig pro `plan_id` (UNIQUE constraint).
- Genau ein Referenztyp pro PlanItem:
  - `fixed_machine`: `canonical_exercise_key` gesetzt, `custom_exercise_id` null.
  - `open_station`: `custom_exercise_id` gesetzt. `canonical_exercise_key` optional (wenn Station auch kanonische Uebung hat).
  - `cardio`: beide null — Zeittracking als Pflichtmetrik.
- `display_name` muss immer einen lesbaren Wert enthalten und wird beim Erstellen aus der Quellentitaet befuellt.
- Reihenfolge-Updates erfolgen als Batch-Transaktion — nie als Einzel-Updates.
- Ein PlanItem kann jederzeit entfernt oder hinzugefuegt werden ohne den restlichen Plan zu invalidieren.

### Rollen
- Read/Write: nur der Eigentuemer des zugehoerigen WorkoutPlans.
- Coach: Lesezugriff auf alle plan_items seiner Gym-Plaene.

---

## Modellierungsleitlinie
Alle neuen Entitaeten muessen vor Umsetzung mindestens diese Fragen beantworten:
- Welche Invarianten gelten fachlich?
- Welche Rollen duerfen lesen/schreiben?
- Welche Idempotenz- und Audit-Anforderungen gelten?
- Wie wird Mandantentrennung technisch erzwungen und getestet?
