import 'package:equatable/equatable.dart';

/// Equipment type — verbindliche Taxonomie (V1).
/// Matches `gym_equipment.equipment_type` enum in Postgres.
enum EquipmentType {
  fixedMachine('fixed_machine'),
  openStation('open_station'),
  cardio('cardio');

  const EquipmentType(this.value);
  final String value;

  static EquipmentType fromValue(String v) =>
      EquipmentType.values.firstWhere((e) => e.value == v);
}

class GymEquipment extends Equatable {
  const GymEquipment({
    required this.id,
    required this.gymId,
    required this.name,
    this.personalDisplayName,
    this.hasPersonalNameOverride = false,
    required this.equipmentType,
    this.zoneName,
    this.nfcTagUid,
    this.canonicalExerciseKey,
    this.rankingEligibleOverride,
    this.manufacturer,
    this.model,
    this.catalogId,
    this.equipmentExternalId,
    this.posX,
    this.posY,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String gymId;

  /// Canonical admin-defined equipment name from `gym_equipment.name`.
  final String name;

  /// Optional per-user alias. Never persisted to `gym_equipment`.
  final String? personalDisplayName;
  final bool hasPersonalNameOverride;
  final EquipmentType equipmentType;
  final String? zoneName;
  final String? nfcTagUid;

  /// Only for `fixedMachine` — the one canonical exercise shown by default.
  final String? canonicalExerciseKey;

  /// Overrides system ranking eligibility. Only valid for `fixedMachine`
  /// or curated templates.
  final bool? rankingEligibleOverride;
  final String? manufacturer;
  final String? model;

  /// FK to `global_equipment_catalog.id` — set when this equipment has been
  /// matched to the platform's canonical equipment catalog.
  /// Enables future cross-gym leaderboards by specific model.
  final String? catalogId;

  final String? equipmentExternalId;

  /// Normalised floor-plan coordinates (0.0–1.0). Both null = not positioned.
  final double? posX;
  final double? posY;

  final bool isActive;
  final DateTime createdAt;

  bool get isPositioned => posX != null && posY != null;

  String get displayName {
    final alias = personalDisplayName?.trim();
    if (alias == null || alias.isEmpty) return name;
    return alias;
  }

  bool get supportsNfc => nfcTagUid != null;

  @override
  List<Object?> get props => [id];
}
