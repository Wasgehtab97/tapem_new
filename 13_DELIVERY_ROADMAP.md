# 13 Delivery Roadmap

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


## Phase 1: Foundation
- Domainmodell, Scope und Acceptance-Kriterien finalisieren.
- Flutter-App-Foundation fuer iOS und Android (Projektstruktur, Build-Flavors, Basisnavigation) aufsetzen.
- Supabase-Projekt in EU/Frankfurt (sofern verfuegbar) aufsetzen.
- Schema, Migrationen, RLS-Baseline und Auth-Grundlagen produktionsreif machen.
- Username-Regeln, Theme-Presets und Privacy-Level final implementierbar spezifizieren.
- CI/CD, Security-Baseline, Secret-Management und Monitoring-Backbone etablieren.

Exit-Kriterien:
- Alle Foundation-Migrationen laufen reproduzierbar.
- RLS-Basisregeln fuer Kernentitaeten sind aktiv und getestet.
- Mindestens ein kompletter Build-und-Deploy-Pfad ist automatisiert.

## Phase 2: Core Workout Product
- Membership, Workout Core und Offline Core implementieren.
- Workout Start Hub mit NFC- und manuellem Start liefern.
- Edge Functions fuer privilegierte Kernwrites und Idempotenz liefern.
- XP-Engine V1 fuer alle drei XP-Achsen implementieren.
- Historie und Basis-Progress bereitstellen.

Exit-Kriterien:
- Kernflow Ende-zu-Ende funktionsfaehig.
- Offline-zu-Sync-Szenarien bestehen kritische Tests.
- Performance-Budgets fuer Kernaktionen sind in Staging nachgewiesen.

## Phase 3: Studio Engagement
- Gym-interne Rankings, Challenges und Community-Basis bereitstellen.
- Gym-interne Friends/Connections inkl. Requests und Activity-Ansichten liefern.
- Member-Eigenplaene: Trainingsplaene erstellen, bearbeiten, reordnen und als Workout-Vorlage starten.
- Coach-Plan-Zuweisung und Progress-Begleitung liefern.
- Notification-Grundfunktionen aktivieren.

Exit-Kriterien:
- Community- und Engagement-Flows laufen stabil unter Lasttestprofil.
- Privacy- und Fairnessregeln sind technisch nachweisbar.

## Phase 4: Launch Hardening
- Lasttests, Security Review und Compliance Check abschliessen.
- RLS-Audit, Restore-Drill, Incident Drills und Store-Release vorbereiten.
- Finales Go/No-Go gegen `14_ACCEPTANCE_CRITERIA.md`.

Exit-Kriterien:
- Alle Muss-Kriterien aus `14_ACCEPTANCE_CRITERIA.md` erfuellt.
- Keine offenen Blocker in den Launch Non-Negotiables.
- Incident-Kommunikation und Eskalationswege sind geprobt.
- Vollstaendiges Evidenzpaket pro `AC-*` Kriterium ist abgelegt.
- Kritische Oncall-Rollen und Vertretungen sind fuer Launch-Woche verbindlich geplant.

## Phase 5: Post-Launch Expansion (nicht V1)
- Partner-Deals und Revenue-Share.
- Gym-uebergreifende Features mit Consent- und Fairnessmodell.
- Erweiterte BI und optionale Integrationen.

## Lieferprinzip
Jede Phase endet nur mit messbaren und dokumentierten Abnahmekriterien.
Phasen ohne erfuellte Exit-Kriterien duerfen nicht uebersprungen werden.
