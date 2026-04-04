# 01 - Monitoring & Alerting Setup

Stand: 2026-04-03
Status: [ ] Offen [ ] In Arbeit [ ] Live

## Ziel

Kritische Probleme in Workout/Auth/Sync innerhalb von Minuten erkennen, nicht erst durch Zufall.

## Monitoring Scope (Minimum)

1. Build/Release Gesundheit
- CI (`.github/workflows/ci.yml`) muss gruen sein.
- Android Signed AAB Workflow muss erfolgreich laufen.

2. Backend Gesundheit (Supabase)
- Edge Function Fehlerquote
- Auth Fehler / Login-Probleme
- DB Fehler bei Kernflows (Workout Sync)

3. Produkt-KPIs als Fruehwarnung
- Sync-Quote finished sessions -> `sync_confirmed`
- Aktivierungen (Join -> erstes Workout)
- NFC-Abdeckung fixed machines

## Alert Kanaele (fuer 1-10 Gyms)

- Primaer: E-Mail an Founder
- Sekundaer: WhatsApp/Telegram an Founder + Backup Kontakt
- Incident Ticket: Eintrag in `07_ops_evidence_log.md`

## Schwellwerte (Startwerte)

- P0 Alert:
  - Workout Sync-Quote < 90% in 60 Minuten bei aktivem Betrieb
  - Auth/Login komplett gestoert > 10 Minuten
  - Edge Function Error Burst > 10 Fehler in 15 Minuten

- P1 Alert:
  - Sync-Quote 90-97% fuer > 2 Stunden
  - CI oder Release Pipeline rot
  - Wiederkehrende Member-Beschwerden zum selben Flow

## Einrichtungs-Checkliste

### A) CI / Release Monitoring

- [ ] GitHub Notifications fuer CI-Failures aktiviert
- [ ] Owner sieht `ci.yml` und `android-release.yml` Runs
- [ ] Fehler gehen auf primaeren Alert-Kanal

### B) Supabase Monitoring

- [ ] Supabase Project Zugang fuer Incident-Owner vorhanden
- [ ] Edge Function Logs sind abrufbar
- [ ] DB Logs sind abrufbar
- [ ] Auth Logs sind abrufbar

### C) KPI Monitoring (taeglich)

- [ ] SQL Check fuer Sync-Quote hinterlegt
- [ ] SQL Check fuer NFC-Abdeckung hinterlegt
- [ ] SQL Check fuer Aktivierungen hinterlegt

## SQL Checks (copy/paste in Supabase SQL Editor)

### 1) Sync-Quote letzte 24h

```sql
select
  gym_id,
  count(*) filter (where finished_at is not null) as finished_sessions,
  count(*) filter (where finished_at is not null and sync_status = 'sync_confirmed') as synced_sessions,
  round(
    100.0 * count(*) filter (where finished_at is not null and sync_status = 'sync_confirmed')
    / nullif(count(*) filter (where finished_at is not null), 0),
    2
  ) as sync_rate_percent
from public.workout_sessions
where created_at >= now() - interval '24 hours'
group by gym_id
order by sync_rate_percent asc nulls last;
```

### 2) NFC-Abdeckung je Gym (fixed machines)

```sql
select
  gym_id,
  count(*) filter (where equipment_type = 'fixed_machine') as fixed_total,
  count(*) filter (where equipment_type = 'fixed_machine' and nfc_tag_uid is not null) as fixed_tagged,
  round(
    100.0 * count(*) filter (where equipment_type = 'fixed_machine' and nfc_tag_uid is not null)
    / nullif(count(*) filter (where equipment_type = 'fixed_machine'), 0),
    2
  ) as nfc_coverage_percent
from public.gym_equipment
where is_active = true
group by gym_id
order by nfc_coverage_percent asc nulls last;
```

### 3) Aktivierung letzte 7 Tage (Join -> erstes Workout)

```sql
with joins as (
  select user_id, gym_id, min(created_at) as joined_at
  from public.memberships
  where is_active = true
  group by user_id, gym_id
), first_workout as (
  select user_id, gym_id, min(started_at) as first_workout_at
  from public.workout_sessions
  group by user_id, gym_id
)
select
  j.gym_id,
  count(*) as joined_users,
  count(*) filter (
    where fw.first_workout_at is not null
      and fw.first_workout_at <= j.joined_at + interval '7 days'
  ) as activated_users,
  round(
    100.0 * count(*) filter (
      where fw.first_workout_at is not null
        and fw.first_workout_at <= j.joined_at + interval '7 days'
    ) / nullif(count(*), 0),
    2
  ) as activation_rate_percent
from joins j
left join first_workout fw
  on fw.user_id = j.user_id and fw.gym_id = j.gym_id
group by j.gym_id
order by activation_rate_percent asc nulls last;
```

## Nachweis (Pflicht)

- [ ] Ein Test-Alert wurde absichtlich ausgeloest und angekommen
- [ ] Ergebnis in `07_ops_evidence_log.md` dokumentiert
- Datum:
- Verantwortlich:
