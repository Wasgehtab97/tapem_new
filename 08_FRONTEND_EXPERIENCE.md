# 08 Frontend Experience

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


## Erlebnisziele
- Tracking fuehlt sich sofort, leicht und robust an.
- Rankings wirken belastbar und fair.
- Community wirkt lebendig, ohne den Trainingsflow zu stoeren.
- XP-/Level-Fortschritt wirkt motivierend und nachvollziehbar.

## Technologischer Rahmen (verbindlich)
- Frontend wird mit Flutter (Dart) als gemeinsamer iOS- und Android-Codepfad umgesetzt.
- Supabase ist der Standard-Backendpfad fuer Auth, Datenzugriff und Sync.

## Pflichtverhalten
- Offline: workout-kritische Funktionen bleiben nutzbar.
- Sync: User sieht jederzeit lokalen und serverseitigen Zustand.
- Fehler: keine stillen Fehler, immer klare Rueckmeldung.
- NFC-Fallback: bei Scan-Fehler sofort manuellen Start anbieten.
- XP bei Offline-Training lokal vormerken, serverseitig konsistent verbuchen.
- `open_station`: eigene Uebung in wenigen Taps anlegen und wiederfinden.
- `cardio`: Zeittracking muss ohne Zusatzmetriken voll nutzbar sein.
- Ranking-UI blendet nicht vergleichbare freie Uebungen standardmaessig aus.
- Username-Flow zeigt Verfuegbarkeit und validiert nachvollziehbar.
- Friend-Interaktionen liefern unmittelbares UI-Feedback.
- Theme-Wechsel wirkt sofort app-weit und wird persistiert.

## Sync-State-Modell
- `local_saved`: Eingabe lokal sicher gespeichert.
- `sync_pending`: Event ist in Queue und wartet auf Uebertragung.
- `sync_confirmed`: Server hat Event akzeptiert.
- `sync_failed`: serverseitiger Fehler, Benutzer kann gezielt erneut senden.
- Statuswechsel sind fuer den Nutzer klar unterscheidbar und ohne Log-Interpretation verstaendlich.

## Performance-Budgets (V1)
- App-Start bis interaktive Home-Ansicht: p95 < 2.0s.
- Wechsel in Workout Start Hub: p95 < 700ms.
- Set-Logging bis sichtbare Bestaetigung: p95 < 150ms lokal.
- Kritische Screens duerfen bei schlechtem Netz nicht blockieren.

## UX-Qualitaet am Trainingstag
- Kernflow (Starten, Tracken, Abschliessen, Verlauf) ohne Umwege.
- Fokus auf einhaendige Nutzung am Geraet.
- Historie ist nach Session-Ende sofort sichtbar, auch bei ausstehendem Sync.
- XP-Gewinne und Level-Aufstiege sind nach Session-Ende sofort sichtbar.
- Freundesaktivitaet ist schnell einsehbar, ohne Trainingsfluss zu unterbrechen.

## Frontend-Umsetzungsregeln
- Optimistische UI nur dort, wo serverseitige Konflikte sauber aufloesbar sind.
- Lokale Queue-Eintraege fuer kritische Writes sind idempotent und reihenfolge-stabil.
- Jeder Fehlerzustand bietet eine eindeutige Wiederholungsaktion.
- Konfliktfaelle zwischen lokalem und serverseitigem Zustand werden nachvollziehbar angezeigt.
- Keine blockierenden Dialoge ohne direkte Handlungsoption fuer den Nutzer.
