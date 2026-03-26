# 09 Backend Decision

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


## Entscheidung
V1 wird als `Supabase-first, server-authoritative` Backend aufgebaut.

## Kontext zum Client-Stack
- Der primaere Mobile-Client fuer V1 ist Flutter (Dart) mit gemeinsamem Codepfad fuer iOS und Android.

## Entscheidungsgruende
- Relationale Datenintegritaet fuer Sessions, Sets, Rankings und Memberships.
- Konsistente serverseitige XP-/Level-Berechnung in drei XP-Achsen.
- Strikte Mandantentrennung mit nachvollziehbarer Authorisierung.
- Schneller MVP-Start mit kontrolliertem Betriebsaufwand und klarem Wachstumspfad.

## Bewertete Optionen

### Option A: Firebase/Firestore als Kern behalten
Vorteile:
- Schneller Start mit starker mobiler Realtime-Erfahrung.

Nachteile:
- Relationale Auswertungen, Ranking-Fairness und Tenant-Logik werden komplexer.
- Fachlogik verteilt sich leichter in Client/Rules und wird schwerer testbar.

### Option B: Supabase-first (entschieden)
Vorteile:
- Postgres als belastbare Source of Truth.
- RLS fuer Zugriffskontrolle auf Datenebene.
- Auth, Realtime und Storage reduzieren MVP-Aufwand.
- Gute Basis fuer spaetere Erweiterungen.

Nachteile:
- Hoeherer initialer Aufwand fuer Datenmodell- und Policy-Design.

### Option C: PocketBase als Kernbackend
Vorteile:
- Schneller und guenstiger Einstieg fuer kleine Setups.

Nachteile:
- Hoeheres Eigenbetriebsrisiko fuer B2B-Multi-Tenant-Betrieb.
- Schwacher Fit fuer langfristige Produkttiefe.

## Zielarchitektur (Supabase-first)
- Supabase Postgres als Source of Truth.
- Supabase Auth fuer Identity/JWT-Basis.
- RLS als harte Zugriffsschicht (`deny by default`).
- Edge Functions fuer privilegierte Writes und Orchestrierung.
- Realtime fuer selektive Live-Updates.
- Storage fuer Assets.
- Async-Verarbeitung via Jobtabellen + Worker/Function-Layer.
- XP-Engine serverseitig, event-basiert, idempotent.

## Betriebsvorgaben
- Region: EU, bevorzugt Frankfurt (sofern verfuegbar).
- Keine geschaeftskritische Client-Logik.
- Service-Role-Zugriffe nur in geschuetzten serverseitigen Komponenten.
- Alle privilegierten Writes muessen auditierbare Request-IDs fuehren.
- Kritische Datenpfade muessen deterministisch replaybar sein (Debug- und Incident-Faelle).

## Kostenstrategie MVP
- Start auf Supabase Free Tier.
- Budgets fuer Storage, Realtime-Subscriptions und Egress definieren und monitoren.
- Upgrade-Trigger (verbindlich):
  - Datenbankgroesse >= 70 Prozent des Free-Tier-Limits fuer 7 Tage.
  - p95 API-Latenz > 400ms in 3 aufeinanderfolgenden Tagen.
  - >= 3 zahlende Gyms oder definierte SLA-Zusagen mit 99.5 Prozent Verfuegbarkeit.
- Upgrade-Entscheidung wird im Decision Log mit Metrik-Snapshot und Datum dokumentiert.

## Hauptrisiken und Gegenmassnahmen
- Risiko: fehlerhafte RLS-Policies.
  Gegenmassnahme: Policy-Tests, deny-by-default, verpflichtendes Review bei jeder Policy-Aenderung.
- Risiko: inkonsistente XP bei Retry/Offline.
  Gegenmassnahme: idempotency keys, serverseitige Event-Deduplizierung, Replay-Tests.
- Risiko: Latenzspitzen unter Last.
  Gegenmassnahme: p95-Monitoring, gezielte Indizes, asynchrone Entkopplung nichtkritischer Writes.

## Re-Evaluationskriterien
- Wenn in zwei aufeinanderfolgenden Quartalen SLA-Ziele trotz Optimierung verfehlt werden.
- Wenn regulatorische Vorgaben den Datenstandort oder Dienstumfang erzwingen.
- Wenn Produktumfang gym-uebergreifende Kernfunktionen in V1 erzwingt.
