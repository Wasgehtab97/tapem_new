# tapem_new

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


Dieses Repository enthaelt die verbindlichen Source-of-Truth-Dokumente fuer die Greenfield-Neuentwicklung von Tap'em auf Enterprise-Niveau.

## Zweck dieses Repos
- Produkt-, Architektur-, Security- und Betriebsanforderungen fuer V1 eindeutig festlegen.
- Umsetzungsrisiken durch klare Scope-Grenzen und messbare Abnahmekriterien minimieren.
- Eine konsistente Grundlage schaffen, damit die Implementierung ohne Altcode von 0 bis Launch planbar ist.
- Diskussionen und Aenderungen strukturiert ueber Decision Log und AC-Mapping nachvollziehbar machen.

## Verbindlicher Produktkern (V1)
- Workout in Sekunden starten: NFC-first, manueller Fallback jederzeit gleichwertig.
- Drei verpflichtende Geraetetypen:
  `fixed_machine`, `open_station`, `cardio`.
- Drei verpflichtende XP-Achsen:
  `training_day`, `exercise_equipment`, `muscle_group`.
- Gym-interne Friends/Connections mit privacy-gesteuerter Aktivitaetssicht.
- Verpflichtender, app-weit eindeutiger Username nach Registrierung.
- Drei vordefinierte Theme-Presets pro User:
  `default`, `energy`, `minimal`.

## Technologischer Leitentscheid
Frontend ist Flutter-first (Dart) als gemeinsamer iOS- und Android-Codepfad.
Backend ist Supabase-first:
Postgres als Source of Truth, RLS fuer Mandantentrennung, Edge Functions fuer privilegierte Kernwrites.

## Dokumenthierarchie bei Konflikten
1. `14_ACCEPTANCE_CRITERIA.md`
2. `02_SCOPE_AND_NON_GOALS.md`
3. `01_VISION.md`
4. `00_READ_FIRST.md`
5. Alle weiteren Dokumente in der unten definierten Reihenfolge

## Lesereihenfolge
1. `00_READ_FIRST.md`
2. `01_VISION.md`
3. `02_SCOPE_AND_NON_GOALS.md`
4. `03_USERS_AND_USE_CASES.md`
5. `04_DOMAIN_MODEL.md`
6. `05_INFORMATION_ARCHITECTURE.md`
7. `06_DESIGN_PRINCIPLES.md`
8. `07_DESIGN_SYSTEM.md`
9. `08_FRONTEND_EXPERIENCE.md`
10. `09_BACKEND_DECISION.md`
11. `10_DATA_MODEL_AND_INTEGRATIONS.md`
12. `11_SECURITY_PRIVACY_COMPLIANCE.md`
13. `12_QUALITY_TESTING_OPERATIONS.md`
14. `13_DELIVERY_ROADMAP.md`
15. `14_ACCEPTANCE_CRITERIA.md`
16. `15_OPEN_QUESTIONS_AND_DECISIONS.md`
17. `PROMPT_FOR_CLAUDE.md`

## Arbeitsregel fuer Teams und KI
- Dokumente sind normativ; Abweichungen brauchen einen nachvollziehbaren Decision-Log-Eintrag.
- Ungeklaerte Fragen duerfen nur in `15_OPEN_QUESTIONS_AND_DECISIONS.md` existieren.
- Launch-Freigaben erfolgen ausschliesslich gegen `14_ACCEPTANCE_CRITERIA.md`.
- Ohne Evidenz zu einem `AC-*` Kriterium gilt eine Funktion nicht als releasebereit.

## Dokumentenstatus
- Alle Markdown-Dokumente tragen einen einheitlichen Status- und Stand-Header.
- Der Header gilt als Schnellindikator fuer die aktuell gueltige Baseline.

## Erwartetes Ergebnis
Eine implementierbare, widerspruchsarme und testbare Spezifikationsbasis, mit der das Team die App planbar, sicher und skalierbar ausliefern kann.
