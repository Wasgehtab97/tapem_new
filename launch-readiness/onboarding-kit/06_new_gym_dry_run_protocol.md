# 06 - New Gym Dry-Run Protocol

Stand: 2026-04-03
Zweck: Vor echtem Pilot beweisen, dass der gesamte Rollout reproduzierbar funktioniert.

## Scope

Dry-Run umfasst den kompletten End-to-End Ablauf:

1. Gym Setup
2. Equipment Import
3. NFC Mapping
4. Admin Onboarding
5. Member Join + Workout + Sync
6. Owner KPI Sicht

## Voraussetzungen

- Alle Artefakte 01-05 sind vorbereitet.
- Testdaten oder Demo-Gym vorhanden.
- Mindestens 2 Testaccounts (Admin + Member).

## Testfaelle (Pflicht)

### TC-01 Gym Setup

- Ziel: Gym + Rollen korrekt konfiguriert.
- Erwartung: Owner/Admin koennen einloggen und sehen korrekte Menues.

### TC-02 Equipment Import

- Ziel: Mindestens 20 Geraete importiert.
- Erwartung: Geraete in Zonen korrekt sichtbar.

### TC-03 NFC Mapping

- Ziel: Mindestens 10 fixed machines getaggt.
- Erwartung: Scan startet das richtige Geraet ohne Fehlrouting.

### TC-04 Member Activation

- Ziel: Member joint selbststaendig.
- Erwartung: Join in < 2 Minuten erfolgreich.

### TC-05 Workout Core

- Ziel: Manuell + NFC Session komplett durchspielen.
- Erwartung: Set loggen, Session finish, `sync_confirmed` erreicht.

### TC-06 Owner Insight

- Ziel: Daten erscheinen in Owner/Admin Views.
- Erwartung: Aktivierung, NFC-Abdeckung und Basisnutzung sichtbar.

## Abnahmekriterien Dry-Run

- 100% Pflicht-Testfaelle bestanden.
- Kein offener P0, maximal 2 offene P1 mit klarer ETA.
- Gesamtzeit fuer Setup bis funktionsfaehigem Betrieb <= 2 Arbeitstage.

## Timeboxing

- Tag 1: Setup + Import + NFC
- Tag 2: Admin Enablement + Member Flows + KPI Check + Abnahme

## Ergebnis

- Evidence muss in Artefakt 07 dokumentiert werden.
- Ohne dokumentiertes Evidence kein Start mit echtem Gym.
