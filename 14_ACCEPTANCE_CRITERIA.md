# 14 Acceptance Criteria

## Produkt
- `AC-PROD-01`: Kernjourneys fuer Member, Coach und Gym Admin sind Ende-zu-Ende funktionsfaehig und in E2E-Tests abgedeckt.
- `AC-PROD-02`: Workout-Start funktioniert per NFC und manuell ohne funktionale Abstriche.
- `AC-PROD-03`: UX liefert klare Rueckmeldung bei Erfolg, Fehler, Offline und Sync.
- `AC-PROD-04`: Drei XP-Achsen sind sichtbar und korrekt berechnet:
  `training_day`, `exercise_equipment`, `muscle_group`.
- `AC-PROD-05`: Drei Geraetetypen sind voll funktionsfaehig:
  `fixed_machine`, `open_station`, `cardio`.
- `AC-PROD-06`: Username-Anlage nach Erstregistrierung ist verpflichtend und robust validiert.
- `AC-PROD-07`: Theme-Presets sind pro User persistent anwendbar.
- `AC-PROD-08`: Gym-interne Friends/Connections inklusive Activity-Sicht funktionieren gemaess Privacy-Leveln.

## Launch Non-Negotiables
- `AC-LAUNCH-01` Erfassungsgeschwindigkeit:
  - Workout-Start p95 < 10s unter realistischen Mobilbedingungen.
  - Set-Erfassung bis sichtbare Bestaetigung p95 < 150ms lokal.
- `AC-LAUNCH-02` Datenvertrauen:
  Session- und Set-Daten bleiben bei Offline, Retry und App-Neustart korrekt erhalten und synchronisieren konsistent.
- `AC-LAUNCH-03` Nutzerfuehrung:
  Der Trainingstags-Flow ist ohne Erklaerung nutzbar.

## Sicherheit
- `AC-SEC-01`: Keine unautorisierten kritischen Writes moeglich.
- `AC-SEC-02`: Rollen- und Tenant-Regeln sind automatisiert getestet.
- `AC-SEC-03`: Ranking-relevante Events sind serverseitig validiert und auditierbar.
- `AC-SEC-04`: RLS verhindert Cross-Tenant-Zugriffe nachweisbar.
- `AC-SEC-05`: Service-Role-Secrets sind nicht in Clients enthalten.
- `AC-SEC-06`: Username- und Friendship-Daten sind gegen unberechtigten Zugriff abgesichert.

## Qualitaet
- `AC-QUAL-01`: Kritische Test-Suiten sind stabil gruen.
- `AC-QUAL-02`: Definierte Performance-Budgets in Kernflows sind eingehalten.
- `AC-QUAL-03`: Keine bekannten Blocker in den Launch Non-Negotiables.
- `AC-QUAL-04`: Migrationen laufen reproduzierbar in clean und upgrade Szenarien.
- `AC-QUAL-05`: XP-/Level-Berechnung ist deterministisch und idempotent.
- `AC-QUAL-06`: Rankings zeigen nur freigegebene, fair vergleichbare Uebungen.

## Betrieb
- `AC-OPS-01`: Monitoring, Alerting und Incident-Prozesse sind aktiv.
- `AC-OPS-02`: Rollback ist reproduzierbar getestet.
- `AC-OPS-03`: Runbooks fuer kritische Stoerungen sind vorhanden.
- `AC-OPS-04`: Backup/Restore wurde vor Launch erfolgreich geuebt.

## Region und Datenschutz
- `AC-DAT-01`: Produktionsprojekt laeuft fuer Deutschland-Start in EU/Frankfurt, sofern verfuegbar.
- `AC-DAT-02`: DSGVO-Prozesse fuer Auskunft, Export und Loeschung sind operativ nachweisbar.

## Nachweisformat
- Jedes Kriterium muss im Go/No-Go-Protokoll mit Status, Evidenzlink und verantwortlicher Rolle dokumentiert sein.
- Fehlende Evidenz gilt als nicht erfuellt.

## Launch-Freigabe
Ein Release ist nur launch-ready, wenn alle Muss-Kriterien in diesem Dokument erfuellt sind.
