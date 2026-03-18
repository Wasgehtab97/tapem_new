# 11 Security Privacy Compliance

## Security-Grundsaetze
- Zero Trust zwischen Client und Backend.
- Prinzip der minimalen Rechte.
- Sensitive Writes nur ueber serverseitig autorisierte Pfade.
- Jede kritische Aktion ist auditierbar.

## Supabase Security-Standards
- RLS ist fuer alle produktiven Fachtabellen aktiv.
- Zugriff aus Clients nur ueber `anon`/User-Context mit gueltigen Policies.
- Service-Role-Keys nur in Edge Functions oder geschuetzter Server-Infrastruktur.
- Kein Service-Role-Key in Mobile- oder Web-Clients.
- JWT-Claims, Rollen und Membership-Pruefungen sind konsistent mit Domainregeln.

## Produktkritische Security-Faelle
- Harte Tenant-Isolation in allen Lese- und Schreibpfaden.
- Schutz gegen manipulierte Ranking-Events durch serverseitige Plausibilisierung.
- Schutz gegen manipulierte XP/Level-Werte.
- Schutz gegen ungueltige NFC-Zuordnungen und Replay-Versuche.
- Idempotente APIs gegen doppelte Session-/Set-Events.
- Missbrauchsschutz fuer UserCustomExercises (Rate-Limits, Validierung, Duplikatregeln).
- Ranking-Eignung ist serverseitig gesteuert.
- Username-Impersonation verhindern (Eindeutigkeit, Reserveliste, Audit-Trail).
- Friend-Graph-Zugriffe strikt nach Friendship- und Privacy-Status.

## Operative Security-Kontrollen
- Secrets-Rotation mindestens quartalsweise oder sofort bei Vorfall.
- Security-Alerts fuer Auth-Anomalien, RLS-Verletzungsversuche und Error-Spikes.
- Jede Policy-Aenderung verlangt Vier-Augen-Review und automatisierte Policy-Tests.

## Datenschutz
- Privacy by default und Datensparsamkeit.
- Transparente Einwilligungen fuer optionale Tracking- und Community-Funktionen.
- Operative Prozesse fuer Auskunft, Export und Loeschung.
- Klare Controls fuer Trainingstags- und Aktivitaetssichtbarkeit.

## Privacy-Level fuer Freundesaktivitaet (V1)
- `private`: keine Aktivitaet sichtbar.
- `friends_training_days`: nur Trainingstage sichtbar.
- `friends_training_and_summary`: Trainingstage plus Session-Summary (keine Satzdetails).

Default ist `friends_training_days`.

## Mandantentrennung
- Harte Isolation nach `gymId` auf Daten- und Authorisierungsebene.
- Keine indirekten Querverknuepfungen zwischen Tenants.
- Gym-uebergreifende Auswertungen nur mit expliziter Produktfreigabe und Consent-Modell.

## Compliance-Mindestanforderungen
- DSGVO-konforme Dokumentation und Prozesse.
- Sicherheitsvorfall-Prozess mit klaren Verantwortlichkeiten.
- Nachweisbare technische und organisatorische Massnahmen.
- Region EU/Frankfurt fuer Deutschland-Start, sofern verfuegbar.
