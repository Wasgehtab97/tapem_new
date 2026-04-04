# Tap'em Final Launch-Ready Roadmap (1-10 Gyms)

> Status: Final working roadmap
> Stand: 2026-04-03
> Zweck: Die App store-ready machen (App Store + Google Play) und parallel sales-ready fuer die ersten 1-10 Gyms.

---

## 1) Launch-Ready Definition (verbindlich)

Tap'em gilt als launch-ready fuer die ersten 1-10 Gyms erst dann, wenn alle 5 Gates erfuellt sind:

1. Product Gate
- Workout-Kern ist robust im realen Studioalltag.
- Owner/Admin Kernfunktionen sind stabil nutzbar.
- Community/Challenges sind nutzbar ohne Bastelaufwand.

2. Quality Gate
- CI laeuft stabil.
- Kernflow-Tests sind vorhanden (nicht nur UI-Featuretests).
- Keine offenen kritischen Bugs in Workout, Auth, Gym-Join, Sync.

3. Operations Gate
- Monitoring/Alerting Minimum ist aktiv.
- Incident-Runbook, Release-/Rollback-Checkliste vorhanden.
- Backup/Restore-Drill dokumentiert erfolgreich.

4. Compliance Gate
- DSGVO-Mindestprozess fuer Auskunft/Export/Loeschung operationalisiert.
- Security-Baselines dokumentiert und pruefbar.

5. Distribution & Sales Gate
- App Store und Google Play Release-Pipeline verifiziert.
- Demo-Gym, Pilotangebot, Owner-One-Pager, Rollout-Material fertig.

---

## 2) Verifizierter Ist-Stand (2026-04-03)

## 2.1 Bereits verifiziert als stark

- CI testet reale Tests (`flutter test test/`).
- `make test` vorhanden.
- Lokal: `flutter analyze` gruen, `flutter test test/` gruen.
- Workout-Kern implementiert: NFC + manuell, Offline/Resume/Sync, Sync-Badge.
- Owner Overview implementiert (Funnel, Nutzung, NFC-Abdeckung, offene Aufgaben).
- Breiter Admin-Bereich implementiert (Gym Settings, Members, Roles, Equipment, NFC, Feedback, Moderation, Analytics, Owner Overview).
- Community/Friends/Rankings implementiert.
- Admin-Challenge-CRUD implementiert.
- Edge Functions enthalten zentrale Sicherheits- und Validierungslogik.

## 2.2 Verifiziert als noch nicht launch-fertig

- Self-Service Compliance-Flows waren bisher unvollstaendig (Account-Loeschung, Datenexport, Legal-Links in App).
- Operativer Gym-Onboarding-Standardprozess ist dokumentiert, Dry-Run-Nachweis fuer echtes Gym fehlt noch.
- Launch-Ops Artefakte sind erstellt, operative Durchfuehrung/Nachweise fehlen.
- DSGVO-Prozess ist dokumentiert, operativer Testlauf/Nachweis fehlt.
- Sales-Readiness-Artefakte fehlen.

---

## 3) Prioritaeten (P0/P1/P2)

## P0 - Muss vor Store-Launch und aktiver Akquise

1. Kernflow-Tests `✅ erledigt (2026-04-03)`
- WorkoutNotifier
- SyncNotifier
- Auth/Gym-Onboarding Kernpfad

2. Gym-Onboarding-Operationalisierung `✅ Artefakte erstellt (2026-04-03), Dry-Run-Ausfuehrung offen`
- Gym Setup Checklist
- Equipment Intake Template
- NFC Tagging Checklist
- Admin Onboarding Sheet
- Pilot Rollout Day Checklist

3. Launch-Ops Minimum
- Monitoring/Alerting
- Incident-Runbook
- Release-/Rollback-Checklist
- Backup/Restore-Drill

4. DSGVO-Mindestprozess
- Auskunft
- Export
- Loeschung
- dokumentierter Verantwortungsprozess

5. Store-Submission Readiness
- Android Signed AAB Release-Pfad durchgetestet
- iOS/TestFlight->App Store Submission-Pfad durchgetestet
- Privacy/Metadata/Versioning konsistent

6. Sales-Readiness Minimum
- Demo-Gym
- Pilot-Angebot
- Owner-One-Pager
- 5-Minuten-Demo-Skript
- Rollout-Material (Admin + Member)

## P1 - Direkt nach P0

1. Challenge-Templates (4 startfertige Typen)
- Trainingstage/Woche
- Trainingstage/Monat
- XP-Ziel
- Volumen-Ziel

2. Challenge-Tracking
- Teilnahmequote
- Completion Rate
- Admin-Sicht auf laufende Challenge-Leistung

3. Equipment-Analytics Ausbau
- NFC-Aufschluesselung
- Feedback-Korrelation

4. Admin-Ops-Zentralisierung
- offene Aufgaben noch schneller sichtbar (Hub/Overview Entscheidung finalisieren)

## P2 - Nach erstem stabilen Launch

1. Owner Reporting/Export (monatlich)
2. Deals Add-on Pilot (mit sauberer Attribution)
3. Skalierung auf 4-10 Gyms mit standardisiertem Supportprozess

---

## 4) Umsetzung in 6 Phasen

## Phase A - Stabilitaet und Testnachweis (1-2 Wochen)

Ziel:
- Kernlogik durch Tests absichern, Smoke-Tests finalisieren.

Lieferobjekte:
- Tests fuer WorkoutNotifier
- Tests fuer SyncNotifier
- Tests fuer Auth/Gym-Join Kernpfad
- Kritische Launch-Flow Smoke-Test Liste

Exit:
- Kernflow-Tests vorhanden und gruen.
- Kritischer Workflow ist reproduzierbar testbar.

## Phase B - Gym-Onboarding als System (1 Woche)

Ziel:
- Neues Gym reproduzierbar ohne Trial-and-Error live setzen.

Lieferobjekte:
- 5 Onboarding-Artefakte (Checklisten/Templates)
- Einmal kompletter "new gym from scratch" Dry-Run mit Dokumentation

Exit:
- Ein neues Gym kann standardisiert ausgerollt werden.

## Phase C - Productization Challenges + Owner Insights (1 Woche)

Ziel:
- Challenges und Owner-Insights von "vorhanden" auf "verkaufsfaehig" bringen.

Lieferobjekte:
- 4 Challenge-Templates
- Challenge-Teilnahme-/Completion-KPIs
- Equipment Analytics: NFC + Feedback Views

Exit:
- Owner sieht echte Steuerungsdaten, Challenges sind low-friction startbar.

## Phase D - Operations & Compliance (1-2 Wochen)

Ziel:
- Betriebs- und Compliance-Reife auf Mindest-Enterprise-Niveau.

Lieferobjekte:
- Monitoring/Alerting Minimum
- Incident-Runbook
- Release-/Rollback-Checklist
- Backup/Restore-Drill Evidence
- DSGVO-Auskunft/Export/Loeschung Prozessdoku

Exit:
- Ops/Compliance Gate erfuellt.

## Phase E - Store Readiness (parallel zu D)

Ziel:
- Technisch und prozessual bereit fuer App Store + Google Play.

Lieferobjekte:
- Android: signierter AAB Build-Prozess verifiziert
- iOS: TestFlight Build/Upload Prozess verifiziert
- App Metadata/Versioning/Privacy Angaben final
- Final Release Candidate Smoke-Test auf echten Geraeten

Exit:
- Distribution Gate erfuellt.

## Phase F - Sales Activation (parallel zu E)

Ziel:
- Direkt nach Store-Freigabe in Akquise/Pilot gehen koennen.

Lieferobjekte:
- Demo-Gym final
- Pilotpaket (Preis, Laufzeit, Leistungen)
- Owner-One-Pager
- 5-Minuten-Demo-Skript
- Rollout-Material fuer Mitglieder und Admins
- KPI-Zielrahmen fuer Pilot

Exit:
- Kundenakquise kann ohne improvisierte Story starten.

---

## 5) Store Release Checklist (verbindlich)

## Google Play

- Signed AAB Build reproduzierbar
- Signing-Secrets/Keystore sauber dokumentiert
- Release Artifact + Versioning geprueft
- Store Listing + Datenschutzhinweise + Supportkontakt final
- Internal/Test Track Smoke-Test erfolgreich

## App Store

- iOS Release Build/TestFlight Upload reproduzierbar
- Version/Build/Metadata final
- Privacy Angaben und App Review Notes final
- TestFlight Smoke-Test auf realem Geraet erfolgreich

## Cross-Store

- Backend ENV/URLs korrekt fuer Production
- Crash-/Error-Triage Prozess definiert
- Final RC Smoke-Test dokumentiert

---

## 6) Aktueller Schnellstatus

- Product Core: `✅` weit fortgeschritten
- Testtiefe Kernlogik: `✅` Kernflow-Tests fuer Workout/Sync/ActiveGym vorhanden und gruen
- Owner Value: `✅` Equipment-Insights inkl. NFC-/Feedback-Aufschluesselung umgesetzt (Migration `00084` deployed)
- Challenge Productization: `✅` Templates + KPI-Auswertung umgesetzt (Migration `00084` deployed)
- Admin-Ops Sichtbarkeit: `✅` Ops-Priority-Karte im Admin-Hub umgesetzt
- Compliance Self-Service: `✅` Account-Loeschung + Datenexport + Legal-Links implementiert und deployed (Migration `00085`, Functions `dsr-export-account-data` + `dsr-delete-account`)
- Ops/Compliance: `🔄` Dokumentation final, operative Nachweise offen
- Store Submission Readiness: `🔄` technisch vorbereitet, End-to-End Release-Nachweis offen
- Sales Activation: `🔄` Sales-Kit-Dokumente erstellt, Vertriebsausfuehrung noch offen

---

## 7) Reihenfolge ab heute (kurz)

1. P0 Dry-Run fuer neues Gym inkl. Evidence + Sign-off
2. P0 Ops/Compliance
3. P0 Store Release End-to-End
4. P0 Sales Activation (Material ist da, jetzt Akquise-Ausfuehrung)
5. P0 Monitoring der neuen Owner-/Challenge-KPIs im ersten Pilot

---

## 8) Launch-Readiness Matrix (final)

### Bereits launch-ready

- Workout-Core inkl. NFC/manuell, Offline/Resume/Sync und Sync-Badge
- Owner Overview Basis (Funnel, Nutzung, NFC-Abdeckung, offene Aufgaben)
- Admin-Hub Basis inkl. Member/Roles/Equipment/NFC/Moderation
- Community/Friends/Rankings Kernfunktionen
- CI/Build-Qualitaet Basis (`flutter analyze`, `flutter test test/`, CI-Tests)

### Optimierungen umgesetzt (2026-04-03)

- Owner Analytics Tiefe: Equipment-Insights mit NFC-/Feedback-Aufschluesselung
- Challenge Productization: 4 Templates + KPI-Auswertung (Teilnahme/Completion)
- Admin-Ops Sichtbarkeit: zentrale Ops-Priority-Karte mit Direktlinks
- Sales-Artefakte: einheitliches Sales-Kit im Ordner `launch-readiness/sales-kit`
- Kernflow-Testtiefe: Notifier-/Service-Tests fuer Workout, Sync und ActiveGym (inkl. Auth-signedOut Pfad)
- Onboarding-System: vollstaendiges `onboarding-kit` mit 5 Pflicht-Artefakten, Dry-Run-Protokoll und Evidence-Template
- Ops/Compliance-System: vollstaendiges `ops-compliance` Kit mit Monitoring, Incident, Release/Rollback, Backup/Restore, DSGVO und Evidence-Log

### Fehlt noch fuer echten Launch (Go-Live-Ausfuehrung, keine Produkt-Hard-Blocker)

- Dry-Run Nachweis an realem Gym inkl. Sign-off (Prozess ist dokumentiert)
- Ops-Minimum ausfuehren und nachweisen: Monitoring/Alerting-Test, Incident-Uebung, Release mit Checklist
- Backup/Restore-Drill real durchfuehren und dokumentieren
- DSGVO-Prozess real durchlaufen (mind. 1 Testfall) und dokumentieren
- Vollstaendiger Store-Release-Nachweis (Google Play + App Store End-to-End)
