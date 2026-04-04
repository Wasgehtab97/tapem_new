# 02 - Equipment Intake Template

Stand: 2026-04-03
Zweck: Vollstaendige und saubere Erfassung der Studioflaeche als Basis fuer Tracking, Rankings und NFC.

## Hinweise

- Eine Zeile pro physischem Geraet.
- `equipment_id` muss stabil bleiben (nie spaeter neu vergeben).
- Bei fixed machines muss `canonical_exercise_key` gesetzt sein.
- Bei open_station/cardio `canonical_exercise_key` leer lassen, falls nicht sinnvoll.

## Pflichtfelder je Geraet

| Feld | Pflicht | Beispiel | Hinweis |
|---|---|---|---|
| equipment_id | Ja | `lh_bench_press_01` | Eindeutiger technischer Key |
| display_name | Ja | `Chest Press 1` | Sichtbarer Name in der App |
| equipment_type | Ja | `fixed_machine` | `fixed_machine` / `open_station` / `cardio` |
| zone_name | Ja | `Upper Body Zone` | Fuer Orientierung + Analytics |
| manufacturer | Nein | `Technogym` | Optional |
| canonical_exercise_key | Bedingt | `fixed:bench_press` | Pflicht bei fixed machines |
| nfc_tag_uid | Nein | `04A224B19F5C80` | Kann spaeter befuellt werden |
| is_active | Ja | `true` | Inaktive Geraete nicht loeschen |

## Import-Tabelle (ausfuellen)

| equipment_id | display_name | equipment_type | zone_name | manufacturer | canonical_exercise_key | nfc_tag_uid | is_active |
|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  | true |
|  |  |  |  |  |  |  | true |
|  |  |  |  |  |  |  | true |
|  |  |  |  |  |  |  | true |
|  |  |  |  |  |  |  | true |
|  |  |  |  |  |  |  | true |
|  |  |  |  |  |  |  | true |
|  |  |  |  |  |  |  | true |
|  |  |  |  |  |  |  | true |
|  |  |  |  |  |  |  | true |

## Validierung vor Import

- [ ] Keine doppelten `equipment_id`
- [ ] Keine leeren Pflichtfelder
- [ ] `equipment_type` nur erlaubte Werte
- [ ] fixed machines haben `canonical_exercise_key`
- [ ] Zone-Namen sind konsistent geschrieben
- [ ] Import-Stichprobe (5 Geraete) in App geprueft

## Sign-off

- Datum:
- Verantwortlich Studio:
- Verantwortlich Tap'em:
