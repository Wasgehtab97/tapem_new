# Prompt For Claude

Du bist die einzige umsetzende KI fuer dieses Greenfield-Projekt.

## Arbeitsauftrag
- Entwickle die komplette App von 0 bis Launch anhand der Markdown-Dokumente in diesem Repo.
- Nutze keinen Altcode und keine Annahmen aus frueheren Implementierungen.
- Triff technische Detailentscheidungen eigenstaendig, solange sie den definierten Produkt-, Sicherheits- und Qualitaetszielen entsprechen.

## Pflichtvorgehen
1. Lies alle Dokumente in der Reihenfolge aus `README.md`.
2. Leite daraus eine konkrete Modularchitektur und Lieferplanung ab.
3. Implementiere zuerst Foundation und Core-Workout-Flows, danach Engagement-Features.
4. Dokumentiere alle relevanten Architektur- und Trade-off-Entscheidungen im Decision Log.
5. Wenn Informationen kollidieren, halte dich an die Dokument-Prioritaet aus `00_READ_FIRST.md`.

## Harte Regeln
- Backend ist Supabase-first.
- Postgres ist Source of Truth.
- RLS ist fuer Fachdaten verpflichtend.
- Privilegierte Kernwrites laufen ueber serverseitige Pfade.
- XP/Level sind serverseitig und idempotent berechnet.
- Keine geschaeftskritische Logik im Client.
- Klare Tenant-Isolation und rollenbasierte Authorisierung.
- Testbarkeit, Observability und Betriebssicherheit sind Muss-Anforderungen.
- V1 priorisiert Einfachheit und Geschwindigkeit vor Feature-Masse.
- NFC- und manueller Workout-Start sind gleichwertig robust.
- Das 3-Typen-Geraetemodell ist verpflichtend:
  `fixed_machine`, `open_station`, `cardio`.
- Nach Registrierung ist ein eindeutiger Username verpflichtend.
- Gym-interne Friends/Connections mit privacy-gesteuerter Aktivitaetssicht sind V1-Bestandteil.
- App-Themes sind als vordefinierte, pro User waehlbare UI-Varianten umzusetzen.

## Ergebnisformat je Lieferinkrement
- Liefere implementierte Artefakte, Tests und aktualisierte technische Dokumentation.
- Vermerke offene Risiken mit konkretem Mitigationsvorschlag.
- Melde jeden Scope-Konflikt mit Verweis auf betroffenes Dokument und Entscheidungsbedarf.
