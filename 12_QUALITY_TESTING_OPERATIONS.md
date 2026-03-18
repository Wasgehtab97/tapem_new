# 12 Quality Testing Operations

## Qualitaetsziele
- Funktionale Korrektheit in allen Kernjourneys.
- Security-Stabilitaet und Mandantentrennung.
- Hohe Betriebsstabilitaet unter Last und Stoerung.
- Wartbare Codebasis mit klaren Modulen.

## Teststrategie
- Unit-Tests fuer Domain-Regeln, XP/Level und Validierungen.
- Integrations-Tests fuer API, Datenhaltung, Tenant- und Rollenregeln.
- End-to-End-Tests fuer Kernjourneys (NFC-Start, manueller Start, Offline-Sync).
- End-to-End-Tests je Geraetetyp (`fixed_machine`, `open_station`, `cardio`).
- End-to-End-Tests fuer Username, Theme und Friends/Requests.
- Contract-Tests fuer Integrationen.
- Policy-Tests fuer RLS und Rollenmatrix.
- Migrations-Tests fuer clean setup und upgrade path.

## Launchkritische Qualitaetsgates
- Erfassungsgeschwindigkeit innerhalb definierter Budgets.
- Keine verlorenen Session-/Set-Daten bei Offline, Retry und Neustart.
- Kernflow ist in UX-Tests selbsterklaerend reproduzierbar.
- Keine unerlaubten Cross-Tenant-Zugriffe unter RLS.
- Keine doppelte oder fehlende XP-Vergabe in kritischen Sync-Szenarien.
- Rankings zeigen keine nicht vergleichbaren freien Uebungen.
- Username-Validierung und Konfliktverhalten sind stabil.
- Privacy-Regeln fuer Freundesaktivitaet sind technisch nachweisbar.
- Jede Freigabe referenziert explizit die Kriteriums-IDs aus `14_ACCEPTANCE_CRITERIA.md`.

## Betriebsfaehigkeit
- Zentrale Telemetrie: Logs, Metriken, Tracing.
- Alerting mit Schwellwerten und Oncall-Routinen.
- Definierter Rollback-Plan pro Release.
- Runbooks fuer Sync-Stoerungen, Queue-Lag, Auth-Ausfall, Dateninkonsistenz.
- Backup/Restore-Drill vor Launch mit dokumentierter Wiederherstellungszeit.

## Mindestabdeckung fuer Release
- Unit- und Integrations-Tests fuer kritische Module: >= 85 Prozent Statement-Coverage.
- End-to-End-Abdeckung fuer alle in `14_ACCEPTANCE_CRITERIA.md` genannten Muss-Flows.

## Definition of Done pro Release
- Alle Muss-Kriterien aus `14_ACCEPTANCE_CRITERIA.md` sind nachweisbar gruen.
- Es gibt keine offenen P0/P1-Defects in Kernjourneys.
- Monitoring, Alerting und Runbooks sind fuer neue Komponenten aktiv.
- Deployment, Rollback und Datenmigration sind in Staging erfolgreich geprobt.
- Go/No-Go-Protokoll enthaelt Evidenzlinks pro Kriterium.
