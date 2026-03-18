# 05 Information Architecture

## Hauptbereiche der App
- Home
- Workout Start Hub (NFC + manuell)
- Active Workout
- Progress
- Gym Community
- Profile
- Admin (rollenbasiert)

## Navigationsprinzipien
- Flache Navigation fuer taegliche Kernjobs.
- Workout-Start in maximal 1 bis 2 Interaktionen erreichbar.
- NFC- und manueller Einstieg sind gleichrangig sichtbar.
- Manueller Start beginnt mit Geraetetyp-Auswahl:
  `fixed_machine`, `open_station`, `cardio`.
- Admin-Bereiche sind strikt von Member-Flows getrennt.

## Inhaltsprioritaet
1. Schnellstart Training (NFC oder manuell).
2. Aktueller Session-Status und naechste Kernaktion.
3. Relevanter Fortschritt (Leistung, XP, Level).
4. Relevante gym-interne Impulse (Challenge, Ranking, Freundesaktivitaet).
5. Sekundaere Konfiguration.

## Community-Informationslogik (V1)
- Username-Suche nur im eigenen Gym.
- Friend Requests, Freundesliste und Activity-Ansicht gemaess Privacy-Level.
- Keine gym-uebergreifende Friendship-Nutzung in V1.

## Profil-Informationslogik (V1)
- Username anzeigen und nach Regeln verwalten.
- Theme-Auswahl mit Sofortvorschau und persistenter Speicherung.
- Privacy-Level fuer Freundesaktivitaet explizit steuerbar.

## Workout-Start-Informationslogik
- `fixed_machine`: Geraet erkennen/waehlen, kanonische Uebung sofort starten.
- `open_station`: Station waehlen, bestehende Uebung waehlen oder neue anlegen.
- `cardio`: Geraet waehlen, Zeittracking direkt starten.
