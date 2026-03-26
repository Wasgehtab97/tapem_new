# 00 Read First

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


## Zweck
Dieses Dokumentpaket ist die verbindliche Produkt-, Architektur-, Sicherheits- und Liefergrundlage fuer die Greenfield-Neuentwicklung von Tap'em.
Alle Build-, Review- und Release-Entscheidungen leiten sich aus diesen Spezifikationen ab.

## Normative Sprache
- `MUSS`: zwingende Anforderung.
- `SOLLTE`: starke Empfehlung; Abweichung nur mit begruendetem Decision-Log-Eintrag und benanntem Risiko.
- `KANN`: optionale Ausgestaltung ohne Scope-Verletzung.

## Verbindliche Begriffe
- `workout-kritischer Flow`: Starten, Tracken, Abschliessen, lokale Persistenz und spaeterer Sync einer Session.
- `session_day_anchor`: lokaler Kalendertag des Gyms zum Session-Startzeitpunkt.
- `valider Trainingstag`: mindestens eine abgeschlossene Session mit mindestens einer gueltigen Leistungserfassung (Set oder Cardio-Zeit).
- `privilegierter Write`: serverseitiger Schreibpfad mit erhoehten Rechten ausserhalb normaler User-RLS-Pfade.

## Dokument-Prioritaet bei Widerspruechen
1. `14_ACCEPTANCE_CRITERIA.md`
2. `02_SCOPE_AND_NON_GOALS.md`
3. `01_VISION.md`
4. `00_READ_FIRST.md`
5. Alle weiteren Dokumente in der Reihenfolge aus `README.md`

## Nicht verhandelbare Leitlinien
- Kein Rueckgriff auf Altcode, alte Datenmodelle oder historische Architekturentscheidungen.
- V1 bleibt fokussiert: schneller und robuster Trainingsnutzen vor Feature-Breite.
- Frontend ist Flutter-first (Dart) als einheitlicher Mobile-Stack fuer iOS und Android.
- Backend ist Supabase-first mit Postgres als Source of Truth.
- Geschaeftskritische Logik liegt serverseitig, nicht im Client.
- Privilegierte Writes erfolgen nur ueber kontrollierte serverseitige Pfade.
- Jede kritische Write-Operation MUSS idempotent sein.
- Security, Testbarkeit, Observability und Betriebsfaehigkeit sind Muss-Kriterien.

## Produktleitplanken
- Kernprodukt ist ein digitales Trainings-Notizbuch fuer den Studioalltag: schnell, klar, verlaesslich.
- Workout-Start MUSS in Sekunden moeglich sein: NFC-first, manueller Fallback jederzeit.
- V1-Gamification umfasst exakt drei XP-Achsen:
  `training_day`, `exercise_equipment`, `muscle_group`.
- Studio-Individualisierung ist Pflicht: Geraetepark und Uebungen jedes Gyms sind abbildbar.
- Geraete werden in V1 strikt in drei Typen gefuehrt:
  `fixed_machine`, `open_station`, `cardio`.
- Rankings sind nur dort prominent, wo Leistungen fair vergleichbar sind.
- Community-Kern in V1: gym-interne Friends/Connections mit privacy-gesteuerter Sichtbarkeit.
- Identitaet und Personalisierung sind V1-Pflicht: eindeutiger Username und waehlbares Theme.

## Technische Leitplanken
- Mobile-App-Implementierung erfolgt in Flutter (Dart) als gemeinsamer Codepfad fuer iOS und Android.
- Supabase Postgres + RLS + Edge Functions ist der Standardpfad.
- Datenregion fuer den initialen Betrieb: EU, bevorzugt Frankfurt (sofern verfuegbar).
- Fehlertoleranz fuer Offline, Retry, Teil-Ausfaelle und App-Neustarts ist Pflicht.
- Jede fachliche Aktion mit Datenwirkung ist einem `gymId` zugeordnet.
- Kritische Events muessen deduplizierbar und auditierbar gespeichert werden.

## Konsistenzregeln fuer alle Folge-Dokumente
- Launch-relevante Anforderungen MUESSEN als messbares Kriterium in `14_ACCEPTANCE_CRITERIA.md` stehen.
- Scope-Aenderungen MUESSEN in `02_SCOPE_AND_NON_GOALS.md` und `13_DELIVERY_ROADMAP.md` synchronisiert werden.
- Entscheidungs- oder Trade-off-Aenderungen MUESSEN in `15_OPEN_QUESTIONS_AND_DECISIONS.md` dokumentiert werden.
- Offene Fragen duerfen nur in `15_OPEN_QUESTIONS_AND_DECISIONS.md` stehen.

## Arbeitsweise
- Erst verstehen, dann strukturieren, dann implementieren.
- Annahmen, Risiken und Trade-offs explizit dokumentieren.
- Klare Grenzen zwischen Domain, Application, Infrastruktur und UI einhalten.
- Keine kurzfristigen Abkuerzungen auf Kosten langfristiger Wartbarkeit.
- Jede release-relevante Aussage muss auf ein messbares Abnahmekriterium aus `14_ACCEPTANCE_CRITERIA.md` verweisen.

## Definition von Enterprise-Niveau
- Sicher, testbar, beobachtbar und skalierbar.
- Vorhersagbares Verhalten unter Last und bei Stoerungen.
- Messbare Qualitaetskriterien fuer Launch und Betrieb.
