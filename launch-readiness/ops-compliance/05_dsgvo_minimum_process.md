# 05 - DSGVO Minimum Process (Auskunft / Export / Loeschung)

Stand: 2026-04-03
Status: [ ] Offen [ ] Aktiv
Hinweis: Dies ist ein operativer Mindestprozess, keine Rechtsberatung.

## Ziel

DSGVO-Anfragen fuer die ersten 1-10 Gyms fristgerecht und nachvollziehbar bearbeiten.

## Fristen (Mindeststandard)

- Eingang bestaetigen: innerhalb 72 Stunden
- Vollstaendige Bearbeitung: innerhalb 30 Tagen

## Rollen

- Data Request Owner: koordiniert den Fall
- Technical Executor: fuehrt Export/Loeschung aus
- Reviewer: prueft Vollstaendigkeit

## Prozessschritte (immer gleich)

1. Request aufnehmen
- Ticket-ID vergeben: `DSR-YYYYMMDD-XX`
- Art der Anfrage markieren: Auskunft / Export / Loeschung

2. Identitaet verifizieren
- Nur auf verifizierte Identitaet bearbeiten
- Verifikation dokumentieren

3. Scope bestimmen
- Betroffene User-ID(s)
- Betroffene Gym(s)
- Betroffener Zeitraum

4. Daten ermitteln
- SQL/Exports durchfuehren
- Ergebnis intern gegenpruefen

5. Antwort liefern
- Im vereinbarten sicheren Kanal
- Versandzeitpunkt dokumentieren

6. Abschluss dokumentieren
- Was wurde geliefert/geloescht
- Wer hat freigegeben
- Ticket schliessen

## Tabellen mit typischen personenbezogenen Daten (Tap'em)

- `public.user_profiles`
- `public.memberships`
- `public.workout_sessions`
- `public.session_exercises`
- `public.set_entries`
- `public.xp_events`
- `public.user_gym_xp`
- `public.user_exercise_xp`
- `public.user_muscle_group_xp`

## Export-Beispiel (SQL, user_id einsetzen)

```sql
-- 1) Profil
select * from public.user_profiles where id = '<USER_ID>';

-- 2) Mitgliedschaften
select * from public.memberships where user_id = '<USER_ID>';

-- 3) Sessions
select * from public.workout_sessions where user_id = '<USER_ID>';

-- 4) Session Exercises
select se.*
from public.session_exercises se
join public.workout_sessions ws on ws.id = se.session_id
where ws.user_id = '<USER_ID>';

-- 5) Sets
select st.*
from public.set_entries st
join public.session_exercises se on se.id = st.session_exercise_id
join public.workout_sessions ws on ws.id = se.session_id
where ws.user_id = '<USER_ID>';
```

## Loeschung (operativer Standard)

Empfohlener Weg:
1. User in Supabase Auth loeschen (falls Account-Loeschung angefragt)
2. Verifizieren, dass abhaengige Datensaetze entfernt wurden
3. Falls Reste vorhanden: gezielte Nachbereinigung in Public Tabellen

## Nachweis (Pflicht)

- [ ] Request-ID
- [ ] Verifikation dokumentiert
- [ ] Export/Loeschung ausgefuehrt
- [ ] Antwortzeit dokumentiert
- [ ] Abschlussfreigabe dokumentiert

Alles in `07_ops_evidence_log.md` protokollieren.
