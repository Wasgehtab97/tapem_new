# 03 - Release & Rollback Checklist

Stand: 2026-04-03
Status: [ ] Offen [ ] Aktiv

## Ziel

Jeden Release planbar und im Notfall schnell ruecksteuerbar machen.

## Release Scope

- Mobile App (Android AAB, iOS TestFlight/App Store)
- Supabase DB Migrationen
- Supabase Edge Functions

## Pre-Release (Pflicht)

- [ ] Branch ist sauber, Scope klar
- [ ] `flutter analyze` ist gruen
- [ ] `flutter test test/` ist gruen
- [ ] CI (`.github/workflows/ci.yml`) ist gruen
- [ ] Migrations-Impact geprueft
- [ ] Rollback-Plan notiert (wer macht was in welcher Reihenfolge)

## Release Reihenfolge (empfohlen)

1. DB Migrationen
2. Edge Functions
3. Mobile App Release

## Projekt-Commands

Im Ordner `/Users/daniel/Projekte/tapem_new/tapem`:

```bash
# 1) DB aenderungen deployen
supabase db push --db-url "$(cat supabase/.temp/pooler-url)" --include-all --yes

# 2) Edge Functions deployen
make deploy-functions

# 3a) Android Release Artifact
make aab

# 3b) iOS TestFlight Upload
make testflight
```

## Post-Release Smoke (Pflicht)

- [ ] Login
- [ ] Gym Join / Gym laden
- [ ] Workout Start (manual + NFC)
- [ ] Set loggen
- [ ] Session finish
- [ ] Sync auf `sync_confirmed`
- [ ] Owner/Admin Overview laedt

## Rollback Strategie pro Layer

### A) Edge Function Rollback (schnell)

1. Letzten funktionierenden Commit finden.
2. Function Code auf diesen Stand setzen.
3. `make deploy-functions`
4. Smoke-Test wiederholen.

### B) DB Rollback (vorsichtig)

Wichtig: Bei Supabase ist klassisches "Down Migration" oft riskant.
Standard ist: Forward-Fix Migration.

1. Schadhafte Migration analysieren.
2. Korrigierende neue Migration erstellen.
3. `supabase db push ...`
4. Falls Datenintegritaet gefaehrdet: Restore-Plan gemaess Artefakt 04.

### C) Mobile Rollback

- Android: Rollout im Play Console stoppen, auf stabilen Releasekanal zurueck.
- iOS: Release stoppen/phased release pausieren, Hotfix Build pushen.

## Release Freigabe

- Release-ID:
- Datum/Uhrzeit:
- Verantwortlich:
- Ergebnis Smoke-Test: [ ] Pass [ ] Fail
- Rollback noetig: [ ] Nein [ ] Ja
