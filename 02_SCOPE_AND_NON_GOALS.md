# 02 Scope And Non Goals

## V1 MUSS-Umfang

### Identitaet, Rollen, Tenanting
- Authentifizierung, Rollenmodell und Multi-Tenant-Gym-Kontext.
- Username-Pflicht direkt nach Erstregistrierung.
- Gym-interne Friends/Connections mit privacy-gesteuerter Aktivitaetssicht.
- Theme-Auswahl pro User aus freigegebenen Theme-Presets.

### Workout-Kern
- Studio-individualisierter Geraete- und Uebungskatalog pro Gym.
- Geraete-Taxonomie mit genau drei Typen:
  `fixed_machine`, `open_station`, `cardio`.
- Workout-Start ueber NFC plus gleichwertiger manueller Start.
- Workout-Tracking (Saetze, Wiederholungen, Gewicht, Notiz) mit schneller Session-Fuehrung.
- Fuer `open_station`: eigene Uebungen erstellen, finden und wiederverwenden.
- Fuer `cardio`: Zeittracking als Pflichtmetrik.
- Offline-Faehigkeit fuer workout-kritische Flows inklusive spaeterem Sync.

### Motivation, Progress, Engagement
- Drei XP-Achsen mit separaten Leveln:
  `training_day`, `exercise_equipment`, `muscle_group`.
- Achievements und gym-interne Rankings auf validierten XP-/Leveldaten.
- Rankings nur fuer fair vergleichbare und explizit freigegebene Uebungen.
- Trainingstag, Historie, Basis-Progress und Fortschrittsansicht.

### Coaching und Administration
- Trainingsplaene: selbst erstellt (Member) und zugewiesen (Coach).
- Studio-Admin-Bereich fuer operative Kernaufgaben.

## V1 Nicht-Ziele
- KI-Coaching als Kernprodukt.
- Vollstaendiges Social Network mit komplexen Content-Threads.
- Theme-Builder mit freier Token-Konfiguration.
- Gym-uebergreifende globale Rankings.
- Partner-Deals als operativer Kernbestandteil.
- Komplexe Economy-/Battle-Pass-Mechaniken.
- White-Label-Sonderlogik pro Gym im Kernsystem.

## V1.1 oder spaeter
- Fortgeschrittene KI-Coaching-Features.
- Partner-Deals inkl. Revenue-Share-Abwicklung.
- Gym-uebergreifende Rankings und Community-Features mit Consent- und Fairnessmodell.
- Erweiterte BI-Self-Service-Funktionen.
- Komplexe Integrationen (Wearables, ERP, Billing), ausser explizit priorisierte.

## Scope-Governance
- Jede Scope-Erweiterung braucht eine gleich grosse Komplexitaetsreduktion an anderer Stelle.
- Jede neue Funktion braucht mindestens ein Abnahmekriterium in `14_ACCEPTANCE_CRITERIA.md`.
- Scope-Aenderungen ohne messbaren Nutzen fuer Member, Coach oder Gym Admin sind nicht zulaessig.
