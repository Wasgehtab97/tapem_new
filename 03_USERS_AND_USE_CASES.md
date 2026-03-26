# 03 Users And Use Cases

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


## Hauptzielgruppen
- Casual Member: will schnell und reibungsarm tracken.
- Ambitionierter Member: will Fortschritt detailliert analysieren.
- Coach: erstellt Plaene, begleitet Fortschritt und setzt Trainingsimpulse.
- Gym Admin/Owner: steuert Aktivitaet, Bindung und Betriebsqualitaet.

## Kern-Jobs-To-Be-Done
- "Ich will in Sekunden tracken und direkt weitertrainieren."
- "Ich will Fortschritt sehen, ohne manuelle Nacharbeit."
- "Ich will durch reales Training XP sammeln."
- "Ich will mein echtes Gym in der App wiederfinden."
- "Ich will bei offenen Stationen eigene Uebungen schnell wiederverwenden."
- "Ich will Cardio ohne Komplexitaet tracken, mindestens ueber Zeit."
- "Ich will als Coach Plaene auf Basis des realen Equipments erstellen."
- "Ich will als Studio messbar erkennen, was Bindung steigert."
- "Ich will mich im Gym vernetzen und Aktivitaet meiner Freunde sehen."

## Gym-Zuordnung (Onboarding-Modell)
- Tap'em ist ein B2B2C-Produkt: Das Studio schliesst einen Vertrag mit Tap'em.
- Gyms werden ausschliesslich durch den Tap'em-Plattformbetreiber im Backend angelegt (Supabase-Dashboard oder Admin-Skript). Mitglieder erstellen keine Gyms.
- Jedes Gym erhaelt einen eindeutigen, kurzen **Gym-Code** (`join_code`, z.B. `WOLF42`).
- Mitglieder geben diesen Code beim Onboarding ein, um einem Gym beizutreten.
- Ein Member kann Mitglied in mehreren Gyms sein; der aktive Gym-Kontext wird explizit gewaehlt.
- Der Gym-Code wird vom Gym-Admin an neue Mitglieder verteilt (Aushang, E-Mail, QR-Code).

## Top Journeys (V1)
1. Onboarding: Registrierung → Username → Gym-Code eingeben → Gym beitreten → Home.
2. Workout-Start per NFC-Scan.
3. Workout-Start per manueller Auswahl ohne NFC.
4. Eigene Uebung bei `open_station` anlegen und wiederverwenden.
5. Cardio-Session starten und Zeit erfassen.
6. Saetze/Zeiten erfassen, Session abschliessen, Historie direkt sehen.
7. XP-Update und Level-Fortschritt sehen.
8. Achievements und relevante Rankings einsehen.
9. Coach erstellt und weist Plan zu.
10. Member erstellt und nutzt eigenen Plan.
11. Member vernetzt sich gym-intern und sieht Freundesaktivitaet gemaess Privacy-Regeln.
12. Member waehlt Theme und sieht sofortige UI-Umstellung.
13. Admin analysiert Aktivitaet und Engagement-Kennzahlen.

## Kritische Edge Cases
- Komplette Session offline.
- NFC-Scan fehlschlaegig, nahtloser manueller Fallback.
- Doppelte Events durch Retry oder App-Neustart.
- XP darf nie doppelt oder fehlend verbucht werden.
- Session ueber Mitternacht.
- Username-Konflikte inkl. Gross-/Kleinschreibung.
- Privacy-Regeln fuer Freundesaktivitaet.
- Gym-Kontextwechsel.
- Nahezu gleiche UserCustomExercises mit Schreibvarianten.

## Erwartetes Systemverhalten in Edge Cases
- Bei Offline-Session bleibt der komplette workout-kritische Flow ohne Datenverlust nutzbar.
- Bei doppelten Events wird serverseitig idempotent dedupliziert.
- Bei Username-Konflikten liefert das System sofortige, nachvollziehbare Alternativvorschlaege.
- Bei Gym-Kontextwechsel sind offene lokale Writes dem korrekten `gymId` eindeutig zugeordnet.
- Bei Privacy-Aenderungen greifen neue Sichtbarkeitsregeln sofort fuer neue Activity-Reads.

## Erfolgskriterien aus Nutzersicht
- Kernaktion in jedem Flow in unter 2 Interaktionen erreichbar.
- Kein Datenverlust in workout-kritischen Situationen.
- Nutzer verstehen jederzeit, was lokal gespeichert und was synchronisiert ist.
- Jede Kernjourney liefert innerhalb weniger Sekunden eine sichtbare Erfolgs- oder Fehler-Rueckmeldung.
