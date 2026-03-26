# 05 Information Architecture

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


## Hauptbereiche der App
- Home
- Workout Start Hub (NFC + manuell)
- Active Workout
- Progress
  - Trainingsplaene (Unterbereich, erreichbar ueber Progress-Screen-Tile)
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
- Kein Feature darf den workout-kritischen Flow ueberlagern oder verdecken.

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
- Standardansicht zeigt immer die kleinste datenschutzkonforme Informationsmenge.

## Profil-Informationslogik (V1)
- Username anzeigen und nach Regeln verwalten.
- Theme-Auswahl mit Sofortvorschau und persistenter Speicherung.
- Privacy-Level fuer Freundesaktivitaet explizit steuerbar.

## Trainingsplan-Informationslogik (V1)

### Einstieg
- "TRAININGSPLAENE"-Tile auf dem Progress-Screen navigiert zur Plaene-Listenansicht.
- Kein eigener Tab in der Bottom Navigation — Trainingsplaene sind Teil von Progress.

### Plaene-Listenansicht
- Zeigt alle aktiven Eigenplaene des Users im aktiven Gym.
- Leerzustand mit CTA zum Erstellen des ersten Plans.
- Jede Plan-Karte ist tappbar (→ Plan-Detail/Edit) und traegt einen "START"-Button.
- Neuen Plan erstellen: Schaltflaeche oben rechts navigiert zum Plan-Builder.

### Plan-Builder (Erstellen und Bearbeiten)
- Einheitlicher Screen fuer Create- und Edit-Modus (differenziert ueber planId-Parameter).
- Name-Eingabe: immer editierbar, kein Speichern ohne validen Namen (1–50 Zeichen).
- Uebungsliste: sortierbar per Drag-and-Drop, jederzeit erweiterbar und kuerzerueckbar.
- "+ UEBUNG HINZUFUEGEN" oeffnet Equipment-Browser als Bottom Sheet:
  - Alle aktiven Geraete des Gyms, gruppiert nach Zone.
  - `fixed_machine`: direktes Hinzufuegen mit kanonischer Uebung.
  - `cardio`: direktes Hinzufuegen.
  - `open_station`: Zwischenschritt — Auswahl aus bestehenden eigenen Uebungen fuer dieses Geraet ODER Inline-Neuanlage einer eigenen Uebung.
- Speichern: nur aktiv wenn Name nicht leer. Validierung vor Speichern.
- Loeschen: nur im Edit-Modus, mit Bestaetigung.

### Plan starten
- "START"-Button auf der Plan-Karte startet eine Freestyle-Session.
- Session-Uebungen werden aus den Plan-Items (in Reihenfolge) vorbelegt.
- Der weitere Workout-Flow ist identisch mit dem normalen Freestyle-Flow.
- Kein eigener "Plan-Session"-Typ — Plan dient als Vorlage, nicht als Constraint.

### Navigationsprinzip
- Plan-Builder darf den aktiven Workout-Flow nicht ueberlagern.
- Waehrend eines aktiven Workouts ist der Plan-Builder nicht erreichbar (Router-Guard).
- Plan-Item-Reihenfolge ist lokal-first — Aenderungen sind sofort sichtbar ohne Netzwerkabhaengigkeit.

## Workout-Start-Informationslogik
- `fixed_machine`: Geraet erkennen/waehlen, kanonische Uebung sofort starten.
- `open_station`: Station waehlen, bestehende Uebung waehlen oder neue anlegen.
- `cardio`: Geraet waehlen, Zeittracking direkt starten.
- Bei NFC-Fehler muss der manuelle Start auf derselben Ebene ohne Umweg erreichbar bleiben.

---

## Admin-Bereich — Informationsarchitektur (V1)

Erreichbar ueber eigenen Tab in der Bottom-Navigation.
Sichtbar ausschliesslich fuer Nutzer mit Rolle `admin` oder `owner` im aktiven Gym.
Admin-Bereiche sind strikt von Member-Flows getrennt — kein Admin-Screen darf ueber Member-Navigation erreichbar sein.

Einstiegspunkt: Kachel-Uebersicht aller Admin-Sektionen auf einem einzelnen Listenscreen.

---

### GYM SETTINGS
Zweck: Kerndaten des Gyms verwalten und den Gym-Code an neue Mitglieder verteilen.

- Gym-Code (`join_code`) anzeigen — gross und lesbar, zum Teilen per Screenshot, Copy oder QR-Code.
- Gym-Name und optionale Beschreibung bearbeiten (Owner only).
- Gym-Code regenerieren (Owner only) — mit Bestaetigung, da alter Code sofort unbrauchbar wird.
- Kein Insert neuer Gyms — Gyms werden ausschliesslich durch den Plattformbetreiber angelegt.

---

### EQUIPMENT — Geraeteverwaltung
Zweck: Den Geraetepark des Gyms vollstaendig und korrekt abbilden.

- Geraete-Bestandsliste: Name, Typ (`fixed_machine` / `open_station` / `cardio`), Zone, Hersteller, Modell, Aktiv-Status, NFC-Zuordnung (ja/nein).
- Geraet hinzufuegen: Name, Typ, Zone, Hersteller, Modell, `canonical_exercise_key` (fuer `fixed_machine`), `ranking_eligible`-Flag.
- Geraet bearbeiten: alle oben genannten Felder jederzeit aenderbar.
- Geraet deaktivieren (Soft-Delete): Geraet verschwindet aus Member-Ansichten, historische Daten bleiben erhalten.
- Geraet-Feedback-Inbox: eingehende Fehlermeldungen und Verbesserungsvorschlaege der Mitglieder einsehen (gelesen/ungelesen, Freitext, Timestamp, Username).
- (V1.1) Geraete-Grundriss: Position jedes Geraets auf einem Gym-Grundriss per Tap oder Drag-and-Drop setzen — sichtbar in der Gymgoer-Kartenansicht.

---

### NFC TAG ASSIGNMENT — NFC-Tag-Zuweisung
Zweck: Jedes physische NFC-Tag einem Geraet zuordnen, damit Mitglieder per Scan direkt starten.

- Uebersicht: alle Geraete, aufgeteilt in "hat NFC-Tag" und "ohne NFC-Tag".
- NFC-Tag zuweisen: Admin-App liest neuen Tag (Scan-Modus), Tag-UID wird dem gewaehlten Geraet serverseitig versioniert zugeordnet.
- NFC-Tag entfernen oder einem anderen Geraet neu zuweisen — alte Zuordnung wird im Audit-Log behalten.
- Jede Tag-Aenderung ist serverseitig versioniert und nachvollziehbar.

---

### EXERCISE TEMPLATES — Uebungsvorlagen
Zweck: Den gym-spezifischen Uebungskatalog pflegen, der als Grundlage fuer Tracking und Rankings dient.

- Uebungsvorlagen-Liste des Gyms: Name, primaere Muskelgruppe, `ranking_eligible`-Flag, Aktiv-Status.
- Uebungsvorlage hinzufuegen: Name, primaere Muskelgruppe, Muskelgruppen-Gewichtungen (Summe = 1.0), `ranking_eligible`, Verknuepfung mit Geraetetyp.
- Uebungsvorlage bearbeiten: alle Felder jederzeit aenderbar.
- `ranking_eligible` aktivieren: nur fuer Uebungen mit vollstaendigem Muskelgruppen-Mapping zulaessig.
- Uebungsvorlage deaktivieren (Soft-Delete): verschwindet aus Auswahlmenüs, historische Daten bleiben erhalten.

---

### MEMBERS — Mitgliederverwaltung
Zweck: Den Mitgliederbestand des Gyms ueberblicken und Rollen steuern.

- Mitgliederliste: Username, Rolle (`member` / `coach` / `admin`), Beitrittsdatum, letzte Aktivitaet, XP-Gesamtstand.
- Rolle aendern:
  - Admin kann Member auf `coach` hochsetzen und zuruecksetzen.
  - Owner kann Member auf `admin` hochsetzen und zuruecksetzen.
  - Owner kann eigene Owner-Rolle nicht selbst entfernen (Schutz gegen versehentliche Sperrung).
- Mitgliedschaft deaktivieren: Mitglied verliert Zugang zum Gym-Kontext; historische Daten bleiben erhalten.
- Kein Loeschen von Accounts — Account-Loeschung ist Sache des Plattformbetreibers.

---

### CHALLENGES
Zweck: Gym-interne Challenges erstellen, um Aktivitaet und Engagement zu steigern.

- Aktive und vergangene Challenges anzeigen mit Teilnehmerquote und Status.
- Neue Challenge erstellen: Titel, Beschreibung, Ziel-XP-Achse (`training_day` / `exercise_equipment` / `muscle_group`), Zeitraum (Start- und Enddatum), Zielwert.
- Challenge vorzeitig beenden (mit Bestaetigung).
- Teilnahme-Statistiken einsehen: Anzahl Teilnehmer, Fortschrittsverteilung.

---

### MODERATION
Zweck: Gym-interne Community-Inhalte im notwendigen Mindestumfang moderieren.

- Gemeldete Inhalte einsehen (gemeldeter Username, Inhalt-Typ, Zeitstempel).
- Entscheidung treffen: Inhalt entfernen oder Meldung ignorieren/schliessen.
- Jede Moderationsentscheidung wird mit Timestamp und Admin-ID geloggt.

---

### ANALYTICS — Aktivitaet und Engagement
Zweck: Messbaren Ueberblick ueber Aktivitaet, Bindung und Betriebsqualitaet des Gyms.

#### Aktivitaets-Dashboard
- Trainingstage pro Mitglied ueber die letzten 7 / 30 / 90 Tage.
- Aktive Mitglieder (DAU / WAU / MAU) als Trendkurve.
- Durchschnittliche Session-Dauer und Sets pro Session.

#### Equipment-Nutzung
- Nutzungsfrequenz pro Geraet (Anzahl Sessions die letzten 30 Tage).
- Identifikation von ungenutzten Geraeten (kein Scan und keine manuelle Auswahl in 30 Tagen).

#### Engagement-Metriken
- XP-Verteilung ueber alle Mitglieder (Histogramm).
- Challenge-Teilnahmequoten pro Challenge.
- Anteil Mitglieder mit aktivem Freundschaftsnetz im Gym.

---

### Floor Plan (V1.1 — nicht V1)
Zweck: Gymgoer koennen den interaktiven Gym-Grundriss oeffnen und ein Geraet durch Antippen direkt auswaehlen, ohne NFC oder Suche.

- Admin laedt ein Grundriss-Bild hoch (PNG/JPEG).
- Admin positioniert jedes Geraet per Tap oder Drag-and-Drop auf dem Bild.
- Position wird als normalisiertes Koordinatenpaar (x: 0.0–1.0, y: 0.0–1.0) in `gym_equipment.pos_x / pos_y` gespeichert.
- Gymgoer-Ansicht: `InteractiveViewer` mit Grundriss-Bild und Geraete-Dots; Tap auf Dot oeffnet Equipment-Detail-Sheet.
- Geraete ohne Positionsdaten erscheinen nicht in der Karte, sind aber weiterhin ueber Suche und NFC erreichbar.
- Voraussetzung fuer Aktivierung: mindestens 50 Prozent des aktiven Geraeteparks sind positioniert.
