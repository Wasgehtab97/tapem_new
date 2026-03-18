# 10 Data Model And Integrations

## Datenklassen
- Identity-Daten (Supabase Auth)
- User-Profile (Username, Theme, Privacy)
- Membership und Rollen
- Gym-spezifischer Geraete- und Uebungskatalog
- Geraetetyp-Metadaten und UserCustomExercises
- Workout-, Progress-, XP- und Leveldaten
- Friends-/Connections-Daten und Friend-Activity-Read-Modelle
- Ranking-, Challenge- und Feed-Ereignisse
- Administrative Betriebsdaten

## Data Ownership
- Supabase Postgres ist Source of Truth fuer alle Kernentitaeten.
- Keine parallelen Wahrheiten zwischen Client und Server.
- Read Models sind explizit als abgeleitete Daten gekennzeichnet.
- NFC-Tag-Mapping wird serverseitig versioniert.
- XP und Level sind serverseitig berechnet.

## Supabase Datenstruktur
- Trennung von `auth`, `public` und optionalen internen Schemas.
- Alle Fachtabellen mit konsequentem `gymId`-Bezug.
- Migrationen versioniert und reproduzierbar.
- Indizes und Constraints sind Teil des Fachmodells.
- XP-Events nutzen eindeutige `idempotency_key` pro Quelle.
- `gym_equipment.equipment_type` ist verpflichtend:
  `fixed_machine`, `open_station`, `cardio`.
- `exercise_templates` enthalten `ranking_eligible` und Muskelgruppen-Mapping.
- `user_custom_exercises` sind pro `gymId` und `userId` isoliert.
- `user_profiles.username` ist app-weit eindeutig und case-insensitive indiziert.
- `user_profiles.theme_key` referenziert ein freigegebenes Theme-Preset.
- `friendships` sind in V1 gym-intern modelliert.

## Mindestschema fuer Gym-Equipment-Import (V1)
Pflichtfelder:
- `gym_external_id`
- `equipment_external_id`
- `equipment_name`
- `equipment_type` (`fixed_machine` | `open_station` | `cardio`)
- `zone_name`

Optionale Felder:
- `nfc_tag_uid`
- `canonical_exercise_key`
- `ranking_eligible_override`
- `manufacturer`
- `model`

Validierungsregeln:
- `equipment_external_id` muss pro Gym eindeutig sein.
- `nfc_tag_uid` darf pro Gym nur einmal zugewiesen sein.
- `ranking_eligible_override` ist nur fuer `fixed_machine` oder kuratierte Templates erlaubt.

## Integrationsprinzipien
- Externe Systeme nur ueber stabile, versionierte API-Vertraege anbinden.
- Integrationsfehler duerfen Kernflows nicht blockieren.
- Jeder Integrationscall ist beobachtbar, retry-faehig und idempotent.
- Integrationen MUESSEN klare Timeout-, Retry- und Dead-Letter-Regeln besitzen.
- Externe Payloads werden strikt validiert und in interne Canonical-Modelle transformiert.

## Primaere Integrationen in V1
- Supabase Auth
- Supabase Edge Functions
- Supabase Realtime (selektiv)
- Push-/Notification-Infrastruktur
- Optionaler Gym-Equipment-Import (CSV/API)

## XP-System V1 (fachlich)
- `training_day`:
  - 100 XP pro validem Trainingstag je User und Gym.
  - Maximal einmal pro Kalendertag im `session_day_anchor`.
- `exercise_equipment`:
  - Pro abgeschlossenem Set: `5 + floor(reps / 5)` XP.
  - Pro SessionExercise-Cap: 120 XP.
- `muscle_group`:
  - XP aus `exercise_equipment` wird nach Muskelgruppen-Gewichtung verteilt.
  - Gewichtungen je Uebung muessen in Summe 1.0 ergeben.

## Geraetetyp-spezifische Trackingregeln (V1)
- `fixed_machine`: kanonische Uebung als Default, schneller Start via NFC oder Auswahl.
- `open_station`: bestehende eigene Uebung waehlen oder neue anlegen.
- `cardio`: Zeittracking ist Pflichtmetrik.

## Rankingregeln (V1)
- Rankings zeigen nur `ranking_eligible` Uebungen.
- UserCustomExercises sind standardmaessig nicht ranking-eligible.
- Freie Uebungen duerfen erst normalisiert werden, wenn alle Bedingungen erfuellt sind:
  - mindestens 200 Abschluesse in 30 Tagen,
  - Name-Cluster-Konfidenz >= 0.92,
  - manuelle Freigabe durch Content-Ops.

## Datenlebenszyklus
- Klare Retention-Regeln je Datentyp.
- Prozesse fuer Auskunft, Export und Loeschung.
- Audit-Trail fuer sicherheitskritische Aktionen.
- Loeschanforderungen duerfen finanz- oder revisionsrelevante Auditdaten nicht kompromittieren.
