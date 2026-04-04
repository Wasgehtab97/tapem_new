# 04 - Backup & Restore Drill

Stand: 2026-04-03
Status: [ ] Offen [ ] In Uebung [ ] Bestanden

## Ziel

Sicherstellen, dass du Daten im Notfall wiederherstellen kannst.

## Frequenz

- Backup: taeglich
- Restore-Drill: mindestens 1x pro Monat

## Mindestumfang Backup

- Public Schema aus Supabase Postgres
- Migrationsstand dokumentieren
- Build/Release Referenz dokumentieren

## Vorbereitung

- [ ] `SUPABASE_DB_PASSWORD` lokal gesetzt
- [ ] `supabase/.temp/project-ref` vorhanden
- [ ] Lokale Restore-DB verfuegbar (Postgres lokal oder Test-Instanz)
- [ ] Ordner `backups/` vorhanden

## Backup Befehl (Projekt-spezifisch)

Im Ordner `/Users/daniel/Projekte/tapem_new/tapem`:

```bash
mkdir -p backups
REF="$(cat supabase/.temp/project-ref)"
TS="$(date +%Y%m%d_%H%M%S)"
pg_dump \
  "postgresql://postgres.${REF}:${SUPABASE_DB_PASSWORD}@aws-1-eu-central-1.pooler.supabase.com:5432/postgres" \
  --schema=public \
  --format=custom \
  --file="backups/tapem_public_${TS}.dump"
```

## Restore Drill (lokale Test-DB)

```bash
createdb tapem_restore_drill
pg_restore \
  --clean \
  --if-exists \
  --no-owner \
  --dbname=tapem_restore_drill \
  backups/tapem_public_<TIMESTAMP>.dump
```

## Validierung nach Restore

- [ ] Tabellen vorhanden (`workout_sessions`, `session_exercises`, `set_entries`)
- [ ] Beispielabfrage funktioniert
- [ ] Datensatzmengen plausibel
- [ ] Keine kritischen Restore-Fehler

Beispielabfragen:

```sql
select count(*) from public.workout_sessions;
select count(*) from public.session_exercises;
select count(*) from public.set_entries;
```

## Drill-Ergebnis (Pflicht)

- Backup Datei:
- Startzeit:
- Endzeit:
- Dauer (min):
- Ergebnis: [ ] Pass [ ] Fail
- Blocker:
- Naechste Massnahme:

Ergebnis in `07_ops_evidence_log.md` eintragen.
