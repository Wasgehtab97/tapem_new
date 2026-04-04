# 01 - Gym Setup Checklist

Stand: 2026-04-03
Status: [ ] Offen [ ] In Arbeit [ ] Fertig

## A) Studio-Stammdaten

- [ ] Studio-Name final
- [ ] Standort/Adresse final
- [ ] Ansprechpartner (Owner)
- [ ] Ansprechpartner (Operativ/Admin)
- [ ] Rechnungs-E-Mail + Vertrag hinterlegt
- [ ] Pilotzeitraum (Start/Ende) fixiert

Felder:
- Gym ID:
- Owner Name:
- Owner Mail:
- Operative Kontaktperson:
- Startdatum Pilot:
- Enddatum Pilot:

## B) Technische Grundkonfiguration

- [ ] Gym in Supabase korrekt angelegt
- [ ] Join-Code/Invite-Flow geprueft
- [ ] Rollenmodell geprueft (owner/admin/member)
- [ ] Erstes Owner-Konto erfolgreich eingeloggt
- [ ] Mindestens ein Admin-Konto vorhanden
- [ ] Feature-Flags fuer Pilot korrekt gesetzt

## C) Security/Access Minimum

- [ ] Keine geteilten Logins
- [ ] Admins nur benoetigte Rechte
- [ ] Zugriff ehemaliger Testnutzer geprueft und bereinigt
- [ ] Recovery-Owner definiert (2. Owner/Admin)

## D) Produkt-Basisdaten

- [ ] Equipment-Liste importiert (siehe Artefakt 02)
- [ ] Canonical Exercise Mapping fuer fixed machines plausibel
- [ ] Open-Station Bereiche sinnvoll benannt
- [ ] Cardio-Geraete korrekt kategorisiert
- [ ] Inaktive Geraete markiert

## E) Launch Smoke Test (Pflicht)

- [ ] Member kann Joinen
- [ ] Member kann Workout manuell starten
- [ ] NFC-Scan startet korrektes Geraet (wenn vorhanden)
- [ ] Set loggen + Session beenden funktioniert
- [ ] Sync auf `sync_confirmed` wird erreicht
- [ ] Owner sieht Daten im Overview/Admin

## F) Abnahme

- [ ] Studio-Owner Abnahme erfolgt
- [ ] Tap'em technische Abnahme erfolgt
- [ ] Blocker-Liste ist leer (P0/P1)

Abnahme:
- Datum:
- Studio Owner (Name/Unterschrift):
- Tap'em Owner (Name/Unterschrift):
