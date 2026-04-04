# 02 - Incident Runbook

Stand: 2026-04-03
Status: [ ] Offen [ ] Aktiv

## Ziel

Bei Stoerungen schnell, reproduzierbar und ruhig handeln.

## Prioritaeten

- P0: Kernfunktion down (Join/Auth/Workout/Sync) oder Datenverlust-Risiko
- P1: Stark gestoert, aber Workaround vorhanden
- P2: Kleinere Stoerung ohne akute Betriebsgefahr

## SLA fuer 1-10 Gyms

- P0: Reaktion <= 15 Minuten, erste Kommunikation <= 30 Minuten
- P1: Reaktion <= 4 Stunden
- P2: Reaktion <= 2 Werktage

## Incident Ablauf (immer gleich)

1. Erkennen
- Alert oder Meldung erfassen
- Incident-ID vergeben: `INC-YYYYMMDD-XX`

2. Einordnen
- Prioritaet (P0/P1/P2) setzen
- Betroffene Gyms + betroffene Flows notieren

3. Eindammen
- Schaeden begrenzen (z.B. Rollout stoppen, fehlerhafte Funktion deaktivieren)

4. Analysieren
- Logs aus Supabase/GitHub/App Stores pruefen
- Letzte Aenderungen (DB migration, function deploy, app release) pruefen

5. Beheben
- Hotfix oder Rollback gemaess Artefakt 03

6. Verifizieren
- Smoke-Test auf betroffenen Kernflows
- Monitoring fuer 60 Minuten eng beobachten

7. Kommunizieren
- Statusupdate an betroffene Studios
- Abschlussmeldung nach Stabilisierung

8. Nachbereitung
- Root Cause notieren
- Praevention festlegen
- Evidence Log aktualisieren

## Triage-Checkliste

- [ ] Auth funktioniert
- [ ] Gym Join funktioniert
- [ ] Workout Start (manuell) funktioniert
- [ ] Workout Start (NFC) funktioniert
- [ ] Set loggen + Finish funktioniert
- [ ] Sync erreicht `sync_confirmed`
- [ ] Owner/Admin Views laden

## Kommunikationsvorlagen

### P0 Erstmeldung

"Wir haben aktuell eine Stoerung im Bereich <FLOW>. Wir arbeiten bereits an der Behebung. Naechstes Update spaetestens in 30 Minuten."

### Zwischenupdate

"Update: Ursache ist identifiziert (<KURZ>). Workaround/Fix ist in Arbeit. Naechstes Update um <UHRZEIT>."

### Abschluss

"Stoerung behoben. Der Dienst ist wieder stabil. Ursache: <KURZ>. Praeventive Massnahme: <KURZ>."

## Mindestdaten pro Incident

- Incident-ID
- Startzeit / Endzeit
- Prioritaet
- Betroffene Gyms
- Betroffene Flows
- Ursache
- Fix/Recovery Schritt
- Folgeaktion

Alle Daten in `07_ops_evidence_log.md` erfassen.
