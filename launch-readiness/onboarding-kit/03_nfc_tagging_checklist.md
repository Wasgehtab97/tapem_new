# 03 - NFC Tagging Checklist

Stand: 2026-04-03
Zweck: NFC-Setup so sauber ausfuehren, dass Member ohne Erklaerung korrekt starten koennen.

## Vorbereitung

- [ ] NFC-Tags vorhanden (Menge + Reserve 15%)
- [ ] Tags vorcodiert oder UID-Leseprozess vorhanden
- [ ] Smartphone-Testgeraet mit aktueller App-Version
- [ ] Equipment Intake final (Artefakt 02)
- [ ] Zonen-Reihenfolge fuer Tagging-Lauf definiert

## Tagging-Standards

- [ ] Tag immer am gleichen Interaktionspunkt des Geraets
- [ ] Tag sichtbar, aber nicht stoerend platziert
- [ ] Tag-Position robust gegen Schweiss/Reinigung
- [ ] Tag-UID eindeutig einem `equipment_id` zugeordnet
- [ ] Jede Zuordnung direkt in Admin-NFC-View bestaetigt

## Durchfuehrung je Geraet

- [ ] Geraet identifiziert (`equipment_id`)
- [ ] NFC-Tag physisch angebracht
- [ ] UID gelesen
- [ ] UID im Admin zugeordnet
- [ ] Sofortiger Scan-Test erfolgreich
- [ ] Fallback-Test: manueller Start funktioniert weiterhin

## Qualitaetssicherung

- [ ] 100% aller getaggten Geraete funktional getestet
- [ ] 10% Zufalls-Retest durch zweite Person
- [ ] 0 falsche Zuordnung in Stichprobe
- [ ] NFC-Abdeckung je Zone dokumentiert

## KPI fuer Pilotstart

- Minimum-Abdeckung fixed machines: 60%
- Ziel-Abdeckung fixed machines nach 14 Tagen: 85%

## Tracking-Tabelle

| zone_name | equipment_id | display_name | nfc_tag_uid | tagging_done (yes/no) | scan_test (pass/fail) | notes |
|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |

## Sign-off

- Datum:
- Ausgefuehrt von:
- Gegengeprueft von:
