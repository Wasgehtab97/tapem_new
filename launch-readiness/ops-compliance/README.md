# Ops & Compliance Kit (Launch-Ready)

Stand: 2026-04-03
Zweck: Tap'em fuer die ersten 1-10 Gyms betriebssicher und DSGVO-minimal belastbar machen.

## Fuer wen

- Du (Founder/Operator)
- Studio Owner/Manager (bei Incidents und DSGVO-Faellen)

## Enthaltene Artefakte

1. `01_monitoring_alerting_setup.md`
2. `02_incident_runbook.md`
3. `03_release_rollback_checklist.md`
4. `04_backup_restore_drill.md`
5. `05_dsgvo_minimum_process.md`
6. `06_raci_contacts.md`
7. `07_ops_evidence_log.md`

## Definition of Done (Ops/Compliance)

Ops/Compliance gilt als launch-ready, wenn alle Punkte erfuellt sind:

- Monitoring und Alerting sind aktiv und testweise ausgeloest.
- Incident-Runbook wurde einmal in einer Uebung durchgespielt.
- Release- und Rollback-Checklist wurde bei einem echten Release benutzt.
- Backup/Restore-Drill wurde erfolgreich dokumentiert.
- DSGVO-Testfall (mindestens Export oder Loeschung) wurde einmal sauber durchlaufen.
- Rollen, Eskalation und Kontaktwege sind im Team klar.

## Reihenfolge (verbindlich)

1. 06 ausfuellen (Rollen/Kontakte)
2. 01 einrichten (Monitoring/Alerting)
3. 02 finalisieren (Incident-Ablauf)
4. 03 als Standard fuer jeden Release nutzen
5. 04 als Drill einmal ausfuehren
6. 05 fuer echten DSGVO-Fall vorbereiten
7. Alles in 07 als Evidence dokumentieren

## Projekt-spezifische Referenzen

- Repo: `/Users/daniel/Projekte/tapem_new/tapem`
- CI: `.github/workflows/ci.yml`
- Android Release Workflow: `.github/workflows/android-release.yml`
- Release Commands: `make aab`, `make testflight`, `make deploy-functions`
