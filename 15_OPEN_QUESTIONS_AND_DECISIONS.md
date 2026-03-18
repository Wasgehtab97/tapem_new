# 15 Open Questions And Decisions

## Status V1
Es gibt aktuell keine offenen Blocker-Fragen fuer V1. Alle zuvor offenen Punkte sind entschieden und in den Spezifikationen verankert.

## Verbindliche Entscheidungen

### 1) Community-Features mit groesstem Retention-Hebel (erste 90 Tage)
Entscheidung:
- Fokus auf drei Features: gym-interne Friends/Connections, woechentliche gym-interne Challenges, sichtbare Trainingstage der Freunde.

Begruendung:
- Hohe soziale Relevanz bei niedriger Produktkomplexitaet.

### 2) Coach-Planungstiefe in V1
Entscheidung:
- Coach kann Plaene erstellen, zuweisen, aktiv/deaktivieren und pro Plan eine Revision pro Woche publizieren.
- Kein KI-Coaching, keine adaptive Echtzeit-Planautomatik in V1.

### 3) Mindest-Datenmodell fuer Gym-Equipment-Import
Entscheidung:
- Pflichtfelder und Validierungen gemaess `10_DATA_MODEL_AND_INTEGRATIONS.md` Abschnitt "Mindestschema".

### 4) Fairness-Regeln fuer spaetere gym-uebergreifende Vergleiche
Entscheidung:
- Nicht Teil von V1.
- Vorbedingung fuer spaetere Aktivierung:
  einheitliche Uebungsnormalisierung, Geraeteklassenabgleich, vergleichbare Messmetriken und ausdrueckliches Nutzer-Consent.

### 5) Revenue-Share fuer Partner-Deals
Entscheidung:
- Nicht Teil von V1.
- Spaeteres Zielmodell: revisionssicheres Ledger mit unveraenderlichen Buchungssaetzen und monatlicher Abrechnung je Gym und Partner.

### 6) Upgrade-Trigger Supabase Free zu Paid
Entscheidung:
- Upgrade, wenn mindestens eines gilt:
  - Datenbankgroesse >= 70 Prozent des Free-Limits fuer 7 Tage,
  - p95 API-Latenz > 400ms an 3 Folgetagen,
  - >= 3 zahlende Gyms oder SLA 99.5 Prozent vertraglich zugesagt.

### 7) XP-Formel je Achse
Entscheidung:
- `training_day`: 100 XP pro validem Trainingstag, einmal pro Kalendertag je Gym.
- `exercise_equipment`: pro Set `5 + floor(reps / 5)` XP, Cap 120 XP je SessionExercise.
- `muscle_group`: Verteilung der `exercise_equipment` XP nach Muskelgruppen-Gewichtung.

### 8) Gewichtung fuer Muskelgruppen-XP
Entscheidung:
- Jede Uebung hat eine feste Gewichtung ueber beteiligte Muskelgruppen.
- Summe aller Gewichte pro Uebung = 1.0.
- Ohne kuratiertes Mapping wird Standardgewichtung aus ExerciseTemplate genutzt.

### 9) Duplikat-Erkennung bei UserCustomExercises
Entscheidung:
- Duplikatwarnung, wenn normalisierter Name + `equipment_type` + primaere Muskelgruppe kollidieren.
- Normalisierung: lowercase, trim, Sonderzeichenreduktion, einfache Singular/Plural-Glattung.
- User darf trotzdem speichern, aber UI markiert moegliche Dublette.

### 10) Bedingungen fuer Ranking-Normalisierung freier Uebungen
Entscheidung:
- Freigabe nur bei:
  - >= 200 Abschluessen in 30 Tagen,
  - Name-Cluster-Konfidenz >= 0.92,
  - manueller Content-Ops-Freigabe.

### 11) Username-Regeln final
Entscheidung:
- Laenge 3 bis 20 Zeichen.
- Erlaubt: `a-z`, `0-9`, `_`, `.`
- Case-insensitive eindeutig.
- Reservierte Begriffe blockiert (z. B. `admin`, `support`, `tapem`, `system`).
- Umbenennung maximal 1x pro 30 Tage.

### 12) Freundes-Privacy-Level in V1
Entscheidung:
- `private`
- `friends_training_days` (Default)
- `friends_training_and_summary`

### 13) Theme-Presets und Governance in V1
Entscheidung:
- V1 liefert drei Presets: `default`, `energy`, `minimal`.
- Theme-Aenderungen nur ueber token-basiertes Design-System.
- Keine gym-spezifischen Sonderthemes in V1.

### 14) Zeitsemantik fuer `session_day_anchor`
Entscheidung:
- `session_day_anchor` wird im lokalen Zeitzonen-Kontext des Gyms bestimmt.
- Eine Session behaelt ihren Anchor auch bei Sync-Verzoegerung oder User-Reisen.

### 15) Definition valider Trainingstag
Entscheidung:
- Ein Trainingstag ist valide, wenn mindestens eine abgeschlossene Session eine gueltige Leistungserfassung enthaelt.
- Gueltige Leistungserfassung bedeutet mindestens ein Set-Eintrag oder eine Cardio-Zeiterfassung.

## Decision Log (Template)
- Datum:
- Thema:
- Optionen:
- Entscheidung:
- Begruendung:
- Risiken:
- Revisit-Datum:

## Bereits gesetzte Leitentscheidungen
- Greenfield-Entwicklung ohne Uebernahme technischer Altlasten.
- Supabase-first Architektur.
- Postgres + RLS + serverseitige privilegierte Write-Pfade.
- V1 bleibt ein schnelles, fokussiertes Trainingsprodukt.
