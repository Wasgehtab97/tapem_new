// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalGymEquipmentTable extends LocalGymEquipment
    with TableInfo<$LocalGymEquipmentTable, LocalGymEquipmentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalGymEquipmentTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gymIdMeta = const VerificationMeta('gymId');
  @override
  late final GeneratedColumn<String> gymId = GeneratedColumn<String>(
    'gym_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentTypeMeta = const VerificationMeta(
    'equipmentType',
  );
  @override
  late final GeneratedColumn<String> equipmentType = GeneratedColumn<String>(
    'equipment_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoneNameMeta = const VerificationMeta(
    'zoneName',
  );
  @override
  late final GeneratedColumn<String> zoneName = GeneratedColumn<String>(
    'zone_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nfcTagUidMeta = const VerificationMeta(
    'nfcTagUid',
  );
  @override
  late final GeneratedColumn<String> nfcTagUid = GeneratedColumn<String>(
    'nfc_tag_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _canonicalExerciseKeyMeta =
      const VerificationMeta('canonicalExerciseKey');
  @override
  late final GeneratedColumn<String> canonicalExerciseKey =
      GeneratedColumn<String>(
        'canonical_exercise_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rankingEligibleOverrideMeta =
      const VerificationMeta('rankingEligibleOverride');
  @override
  late final GeneratedColumn<bool> rankingEligibleOverride =
      GeneratedColumn<bool>(
        'ranking_eligible_override',
        aliasedName,
        true,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("ranking_eligible_override" IN (0, 1))',
        ),
      );
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gymId,
    name,
    equipmentType,
    zoneName,
    nfcTagUid,
    canonicalExerciseKey,
    rankingEligibleOverride,
    manufacturer,
    isActive,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_gym_equipment';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalGymEquipmentData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('gym_id')) {
      context.handle(
        _gymIdMeta,
        gymId.isAcceptableOrUnknown(data['gym_id']!, _gymIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gymIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('equipment_type')) {
      context.handle(
        _equipmentTypeMeta,
        equipmentType.isAcceptableOrUnknown(
          data['equipment_type']!,
          _equipmentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_equipmentTypeMeta);
    }
    if (data.containsKey('zone_name')) {
      context.handle(
        _zoneNameMeta,
        zoneName.isAcceptableOrUnknown(data['zone_name']!, _zoneNameMeta),
      );
    } else if (isInserting) {
      context.missing(_zoneNameMeta);
    }
    if (data.containsKey('nfc_tag_uid')) {
      context.handle(
        _nfcTagUidMeta,
        nfcTagUid.isAcceptableOrUnknown(data['nfc_tag_uid']!, _nfcTagUidMeta),
      );
    }
    if (data.containsKey('canonical_exercise_key')) {
      context.handle(
        _canonicalExerciseKeyMeta,
        canonicalExerciseKey.isAcceptableOrUnknown(
          data['canonical_exercise_key']!,
          _canonicalExerciseKeyMeta,
        ),
      );
    }
    if (data.containsKey('ranking_eligible_override')) {
      context.handle(
        _rankingEligibleOverrideMeta,
        rankingEligibleOverride.isAcceptableOrUnknown(
          data['ranking_eligible_override']!,
          _rankingEligibleOverrideMeta,
        ),
      );
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalGymEquipmentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalGymEquipmentData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gymId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gym_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      equipmentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_type'],
      )!,
      zoneName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_name'],
      )!,
      nfcTagUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nfc_tag_uid'],
      ),
      canonicalExerciseKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_exercise_key'],
      ),
      rankingEligibleOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ranking_eligible_override'],
      ),
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $LocalGymEquipmentTable createAlias(String alias) {
    return $LocalGymEquipmentTable(attachedDatabase, alias);
  }
}

class LocalGymEquipmentData extends DataClass
    implements Insertable<LocalGymEquipmentData> {
  final String id;
  final String gymId;
  final String name;
  final String equipmentType;
  final String zoneName;
  final String? nfcTagUid;
  final String? canonicalExerciseKey;
  final bool? rankingEligibleOverride;
  final String? manufacturer;
  final bool isActive;
  final DateTime cachedAt;
  const LocalGymEquipmentData({
    required this.id,
    required this.gymId,
    required this.name,
    required this.equipmentType,
    required this.zoneName,
    this.nfcTagUid,
    this.canonicalExerciseKey,
    this.rankingEligibleOverride,
    this.manufacturer,
    required this.isActive,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['gym_id'] = Variable<String>(gymId);
    map['name'] = Variable<String>(name);
    map['equipment_type'] = Variable<String>(equipmentType);
    map['zone_name'] = Variable<String>(zoneName);
    if (!nullToAbsent || nfcTagUid != null) {
      map['nfc_tag_uid'] = Variable<String>(nfcTagUid);
    }
    if (!nullToAbsent || canonicalExerciseKey != null) {
      map['canonical_exercise_key'] = Variable<String>(canonicalExerciseKey);
    }
    if (!nullToAbsent || rankingEligibleOverride != null) {
      map['ranking_eligible_override'] = Variable<bool>(
        rankingEligibleOverride,
      );
    }
    if (!nullToAbsent || manufacturer != null) {
      map['manufacturer'] = Variable<String>(manufacturer);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  LocalGymEquipmentCompanion toCompanion(bool nullToAbsent) {
    return LocalGymEquipmentCompanion(
      id: Value(id),
      gymId: Value(gymId),
      name: Value(name),
      equipmentType: Value(equipmentType),
      zoneName: Value(zoneName),
      nfcTagUid: nfcTagUid == null && nullToAbsent
          ? const Value.absent()
          : Value(nfcTagUid),
      canonicalExerciseKey: canonicalExerciseKey == null && nullToAbsent
          ? const Value.absent()
          : Value(canonicalExerciseKey),
      rankingEligibleOverride: rankingEligibleOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(rankingEligibleOverride),
      manufacturer: manufacturer == null && nullToAbsent
          ? const Value.absent()
          : Value(manufacturer),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
    );
  }

  factory LocalGymEquipmentData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalGymEquipmentData(
      id: serializer.fromJson<String>(json['id']),
      gymId: serializer.fromJson<String>(json['gymId']),
      name: serializer.fromJson<String>(json['name']),
      equipmentType: serializer.fromJson<String>(json['equipmentType']),
      zoneName: serializer.fromJson<String>(json['zoneName']),
      nfcTagUid: serializer.fromJson<String?>(json['nfcTagUid']),
      canonicalExerciseKey: serializer.fromJson<String?>(
        json['canonicalExerciseKey'],
      ),
      rankingEligibleOverride: serializer.fromJson<bool?>(
        json['rankingEligibleOverride'],
      ),
      manufacturer: serializer.fromJson<String?>(json['manufacturer']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'gymId': serializer.toJson<String>(gymId),
      'name': serializer.toJson<String>(name),
      'equipmentType': serializer.toJson<String>(equipmentType),
      'zoneName': serializer.toJson<String>(zoneName),
      'nfcTagUid': serializer.toJson<String?>(nfcTagUid),
      'canonicalExerciseKey': serializer.toJson<String?>(canonicalExerciseKey),
      'rankingEligibleOverride': serializer.toJson<bool?>(
        rankingEligibleOverride,
      ),
      'manufacturer': serializer.toJson<String?>(manufacturer),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  LocalGymEquipmentData copyWith({
    String? id,
    String? gymId,
    String? name,
    String? equipmentType,
    String? zoneName,
    Value<String?> nfcTagUid = const Value.absent(),
    Value<String?> canonicalExerciseKey = const Value.absent(),
    Value<bool?> rankingEligibleOverride = const Value.absent(),
    Value<String?> manufacturer = const Value.absent(),
    bool? isActive,
    DateTime? cachedAt,
  }) => LocalGymEquipmentData(
    id: id ?? this.id,
    gymId: gymId ?? this.gymId,
    name: name ?? this.name,
    equipmentType: equipmentType ?? this.equipmentType,
    zoneName: zoneName ?? this.zoneName,
    nfcTagUid: nfcTagUid.present ? nfcTagUid.value : this.nfcTagUid,
    canonicalExerciseKey: canonicalExerciseKey.present
        ? canonicalExerciseKey.value
        : this.canonicalExerciseKey,
    rankingEligibleOverride: rankingEligibleOverride.present
        ? rankingEligibleOverride.value
        : this.rankingEligibleOverride,
    manufacturer: manufacturer.present ? manufacturer.value : this.manufacturer,
    isActive: isActive ?? this.isActive,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  LocalGymEquipmentData copyWithCompanion(LocalGymEquipmentCompanion data) {
    return LocalGymEquipmentData(
      id: data.id.present ? data.id.value : this.id,
      gymId: data.gymId.present ? data.gymId.value : this.gymId,
      name: data.name.present ? data.name.value : this.name,
      equipmentType: data.equipmentType.present
          ? data.equipmentType.value
          : this.equipmentType,
      zoneName: data.zoneName.present ? data.zoneName.value : this.zoneName,
      nfcTagUid: data.nfcTagUid.present ? data.nfcTagUid.value : this.nfcTagUid,
      canonicalExerciseKey: data.canonicalExerciseKey.present
          ? data.canonicalExerciseKey.value
          : this.canonicalExerciseKey,
      rankingEligibleOverride: data.rankingEligibleOverride.present
          ? data.rankingEligibleOverride.value
          : this.rankingEligibleOverride,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalGymEquipmentData(')
          ..write('id: $id, ')
          ..write('gymId: $gymId, ')
          ..write('name: $name, ')
          ..write('equipmentType: $equipmentType, ')
          ..write('zoneName: $zoneName, ')
          ..write('nfcTagUid: $nfcTagUid, ')
          ..write('canonicalExerciseKey: $canonicalExerciseKey, ')
          ..write('rankingEligibleOverride: $rankingEligibleOverride, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gymId,
    name,
    equipmentType,
    zoneName,
    nfcTagUid,
    canonicalExerciseKey,
    rankingEligibleOverride,
    manufacturer,
    isActive,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalGymEquipmentData &&
          other.id == this.id &&
          other.gymId == this.gymId &&
          other.name == this.name &&
          other.equipmentType == this.equipmentType &&
          other.zoneName == this.zoneName &&
          other.nfcTagUid == this.nfcTagUid &&
          other.canonicalExerciseKey == this.canonicalExerciseKey &&
          other.rankingEligibleOverride == this.rankingEligibleOverride &&
          other.manufacturer == this.manufacturer &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt);
}

class LocalGymEquipmentCompanion
    extends UpdateCompanion<LocalGymEquipmentData> {
  final Value<String> id;
  final Value<String> gymId;
  final Value<String> name;
  final Value<String> equipmentType;
  final Value<String> zoneName;
  final Value<String?> nfcTagUid;
  final Value<String?> canonicalExerciseKey;
  final Value<bool?> rankingEligibleOverride;
  final Value<String?> manufacturer;
  final Value<bool> isActive;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const LocalGymEquipmentCompanion({
    this.id = const Value.absent(),
    this.gymId = const Value.absent(),
    this.name = const Value.absent(),
    this.equipmentType = const Value.absent(),
    this.zoneName = const Value.absent(),
    this.nfcTagUid = const Value.absent(),
    this.canonicalExerciseKey = const Value.absent(),
    this.rankingEligibleOverride = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalGymEquipmentCompanion.insert({
    required String id,
    required String gymId,
    required String name,
    required String equipmentType,
    required String zoneName,
    this.nfcTagUid = const Value.absent(),
    this.canonicalExerciseKey = const Value.absent(),
    this.rankingEligibleOverride = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       gymId = Value(gymId),
       name = Value(name),
       equipmentType = Value(equipmentType),
       zoneName = Value(zoneName);
  static Insertable<LocalGymEquipmentData> custom({
    Expression<String>? id,
    Expression<String>? gymId,
    Expression<String>? name,
    Expression<String>? equipmentType,
    Expression<String>? zoneName,
    Expression<String>? nfcTagUid,
    Expression<String>? canonicalExerciseKey,
    Expression<bool>? rankingEligibleOverride,
    Expression<String>? manufacturer,
    Expression<bool>? isActive,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gymId != null) 'gym_id': gymId,
      if (name != null) 'name': name,
      if (equipmentType != null) 'equipment_type': equipmentType,
      if (zoneName != null) 'zone_name': zoneName,
      if (nfcTagUid != null) 'nfc_tag_uid': nfcTagUid,
      if (canonicalExerciseKey != null)
        'canonical_exercise_key': canonicalExerciseKey,
      if (rankingEligibleOverride != null)
        'ranking_eligible_override': rankingEligibleOverride,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalGymEquipmentCompanion copyWith({
    Value<String>? id,
    Value<String>? gymId,
    Value<String>? name,
    Value<String>? equipmentType,
    Value<String>? zoneName,
    Value<String?>? nfcTagUid,
    Value<String?>? canonicalExerciseKey,
    Value<bool?>? rankingEligibleOverride,
    Value<String?>? manufacturer,
    Value<bool>? isActive,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return LocalGymEquipmentCompanion(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      name: name ?? this.name,
      equipmentType: equipmentType ?? this.equipmentType,
      zoneName: zoneName ?? this.zoneName,
      nfcTagUid: nfcTagUid ?? this.nfcTagUid,
      canonicalExerciseKey: canonicalExerciseKey ?? this.canonicalExerciseKey,
      rankingEligibleOverride:
          rankingEligibleOverride ?? this.rankingEligibleOverride,
      manufacturer: manufacturer ?? this.manufacturer,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gymId.present) {
      map['gym_id'] = Variable<String>(gymId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (equipmentType.present) {
      map['equipment_type'] = Variable<String>(equipmentType.value);
    }
    if (zoneName.present) {
      map['zone_name'] = Variable<String>(zoneName.value);
    }
    if (nfcTagUid.present) {
      map['nfc_tag_uid'] = Variable<String>(nfcTagUid.value);
    }
    if (canonicalExerciseKey.present) {
      map['canonical_exercise_key'] = Variable<String>(
        canonicalExerciseKey.value,
      );
    }
    if (rankingEligibleOverride.present) {
      map['ranking_eligible_override'] = Variable<bool>(
        rankingEligibleOverride.value,
      );
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalGymEquipmentCompanion(')
          ..write('id: $id, ')
          ..write('gymId: $gymId, ')
          ..write('name: $name, ')
          ..write('equipmentType: $equipmentType, ')
          ..write('zoneName: $zoneName, ')
          ..write('nfcTagUid: $nfcTagUid, ')
          ..write('canonicalExerciseKey: $canonicalExerciseKey, ')
          ..write('rankingEligibleOverride: $rankingEligibleOverride, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExerciseTemplatesTable extends LocalExerciseTemplates
    with TableInfo<$LocalExerciseTemplatesTable, LocalExerciseTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExerciseTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gymIdMeta = const VerificationMeta('gymId');
  @override
  late final GeneratedColumn<String> gymId = GeneratedColumn<String>(
    'gym_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRankingEligibleMeta = const VerificationMeta(
    'isRankingEligible',
  );
  @override
  late final GeneratedColumn<bool> isRankingEligible = GeneratedColumn<bool>(
    'is_ranking_eligible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_ranking_eligible" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _primaryMuscleGroupMeta =
      const VerificationMeta('primaryMuscleGroup');
  @override
  late final GeneratedColumn<String> primaryMuscleGroup =
      GeneratedColumn<String>(
        'primary_muscle_group',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _muscleGroupWeightsJsonMeta =
      const VerificationMeta('muscleGroupWeightsJson');
  @override
  late final GeneratedColumn<String> muscleGroupWeightsJson =
      GeneratedColumn<String>(
        'muscle_group_weights_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    gymId,
    name,
    isRankingEligible,
    primaryMuscleGroup,
    muscleGroupWeightsJson,
    isActive,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_exercise_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalExerciseTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('gym_id')) {
      context.handle(
        _gymIdMeta,
        gymId.isAcceptableOrUnknown(data['gym_id']!, _gymIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gymIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_ranking_eligible')) {
      context.handle(
        _isRankingEligibleMeta,
        isRankingEligible.isAcceptableOrUnknown(
          data['is_ranking_eligible']!,
          _isRankingEligibleMeta,
        ),
      );
    }
    if (data.containsKey('primary_muscle_group')) {
      context.handle(
        _primaryMuscleGroupMeta,
        primaryMuscleGroup.isAcceptableOrUnknown(
          data['primary_muscle_group']!,
          _primaryMuscleGroupMeta,
        ),
      );
    }
    if (data.containsKey('muscle_group_weights_json')) {
      context.handle(
        _muscleGroupWeightsJsonMeta,
        muscleGroupWeightsJson.isAcceptableOrUnknown(
          data['muscle_group_weights_json']!,
          _muscleGroupWeightsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key, gymId};
  @override
  LocalExerciseTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalExerciseTemplate(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      gymId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gym_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isRankingEligible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ranking_eligible'],
      )!,
      primaryMuscleGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_muscle_group'],
      ),
      muscleGroupWeightsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muscle_group_weights_json'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $LocalExerciseTemplatesTable createAlias(String alias) {
    return $LocalExerciseTemplatesTable(attachedDatabase, alias);
  }
}

class LocalExerciseTemplate extends DataClass
    implements Insertable<LocalExerciseTemplate> {
  final String key;
  final String gymId;
  final String name;
  final bool isRankingEligible;
  final String? primaryMuscleGroup;
  final String muscleGroupWeightsJson;
  final bool isActive;
  final DateTime cachedAt;
  const LocalExerciseTemplate({
    required this.key,
    required this.gymId,
    required this.name,
    required this.isRankingEligible,
    this.primaryMuscleGroup,
    required this.muscleGroupWeightsJson,
    required this.isActive,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['gym_id'] = Variable<String>(gymId);
    map['name'] = Variable<String>(name);
    map['is_ranking_eligible'] = Variable<bool>(isRankingEligible);
    if (!nullToAbsent || primaryMuscleGroup != null) {
      map['primary_muscle_group'] = Variable<String>(primaryMuscleGroup);
    }
    map['muscle_group_weights_json'] = Variable<String>(muscleGroupWeightsJson);
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  LocalExerciseTemplatesCompanion toCompanion(bool nullToAbsent) {
    return LocalExerciseTemplatesCompanion(
      key: Value(key),
      gymId: Value(gymId),
      name: Value(name),
      isRankingEligible: Value(isRankingEligible),
      primaryMuscleGroup: primaryMuscleGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryMuscleGroup),
      muscleGroupWeightsJson: Value(muscleGroupWeightsJson),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
    );
  }

  factory LocalExerciseTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalExerciseTemplate(
      key: serializer.fromJson<String>(json['key']),
      gymId: serializer.fromJson<String>(json['gymId']),
      name: serializer.fromJson<String>(json['name']),
      isRankingEligible: serializer.fromJson<bool>(json['isRankingEligible']),
      primaryMuscleGroup: serializer.fromJson<String?>(
        json['primaryMuscleGroup'],
      ),
      muscleGroupWeightsJson: serializer.fromJson<String>(
        json['muscleGroupWeightsJson'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'gymId': serializer.toJson<String>(gymId),
      'name': serializer.toJson<String>(name),
      'isRankingEligible': serializer.toJson<bool>(isRankingEligible),
      'primaryMuscleGroup': serializer.toJson<String?>(primaryMuscleGroup),
      'muscleGroupWeightsJson': serializer.toJson<String>(
        muscleGroupWeightsJson,
      ),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  LocalExerciseTemplate copyWith({
    String? key,
    String? gymId,
    String? name,
    bool? isRankingEligible,
    Value<String?> primaryMuscleGroup = const Value.absent(),
    String? muscleGroupWeightsJson,
    bool? isActive,
    DateTime? cachedAt,
  }) => LocalExerciseTemplate(
    key: key ?? this.key,
    gymId: gymId ?? this.gymId,
    name: name ?? this.name,
    isRankingEligible: isRankingEligible ?? this.isRankingEligible,
    primaryMuscleGroup: primaryMuscleGroup.present
        ? primaryMuscleGroup.value
        : this.primaryMuscleGroup,
    muscleGroupWeightsJson:
        muscleGroupWeightsJson ?? this.muscleGroupWeightsJson,
    isActive: isActive ?? this.isActive,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  LocalExerciseTemplate copyWithCompanion(
    LocalExerciseTemplatesCompanion data,
  ) {
    return LocalExerciseTemplate(
      key: data.key.present ? data.key.value : this.key,
      gymId: data.gymId.present ? data.gymId.value : this.gymId,
      name: data.name.present ? data.name.value : this.name,
      isRankingEligible: data.isRankingEligible.present
          ? data.isRankingEligible.value
          : this.isRankingEligible,
      primaryMuscleGroup: data.primaryMuscleGroup.present
          ? data.primaryMuscleGroup.value
          : this.primaryMuscleGroup,
      muscleGroupWeightsJson: data.muscleGroupWeightsJson.present
          ? data.muscleGroupWeightsJson.value
          : this.muscleGroupWeightsJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalExerciseTemplate(')
          ..write('key: $key, ')
          ..write('gymId: $gymId, ')
          ..write('name: $name, ')
          ..write('isRankingEligible: $isRankingEligible, ')
          ..write('primaryMuscleGroup: $primaryMuscleGroup, ')
          ..write('muscleGroupWeightsJson: $muscleGroupWeightsJson, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    key,
    gymId,
    name,
    isRankingEligible,
    primaryMuscleGroup,
    muscleGroupWeightsJson,
    isActive,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalExerciseTemplate &&
          other.key == this.key &&
          other.gymId == this.gymId &&
          other.name == this.name &&
          other.isRankingEligible == this.isRankingEligible &&
          other.primaryMuscleGroup == this.primaryMuscleGroup &&
          other.muscleGroupWeightsJson == this.muscleGroupWeightsJson &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt);
}

class LocalExerciseTemplatesCompanion
    extends UpdateCompanion<LocalExerciseTemplate> {
  final Value<String> key;
  final Value<String> gymId;
  final Value<String> name;
  final Value<bool> isRankingEligible;
  final Value<String?> primaryMuscleGroup;
  final Value<String> muscleGroupWeightsJson;
  final Value<bool> isActive;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const LocalExerciseTemplatesCompanion({
    this.key = const Value.absent(),
    this.gymId = const Value.absent(),
    this.name = const Value.absent(),
    this.isRankingEligible = const Value.absent(),
    this.primaryMuscleGroup = const Value.absent(),
    this.muscleGroupWeightsJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExerciseTemplatesCompanion.insert({
    required String key,
    required String gymId,
    required String name,
    this.isRankingEligible = const Value.absent(),
    this.primaryMuscleGroup = const Value.absent(),
    this.muscleGroupWeightsJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       gymId = Value(gymId),
       name = Value(name);
  static Insertable<LocalExerciseTemplate> custom({
    Expression<String>? key,
    Expression<String>? gymId,
    Expression<String>? name,
    Expression<bool>? isRankingEligible,
    Expression<String>? primaryMuscleGroup,
    Expression<String>? muscleGroupWeightsJson,
    Expression<bool>? isActive,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (gymId != null) 'gym_id': gymId,
      if (name != null) 'name': name,
      if (isRankingEligible != null) 'is_ranking_eligible': isRankingEligible,
      if (primaryMuscleGroup != null)
        'primary_muscle_group': primaryMuscleGroup,
      if (muscleGroupWeightsJson != null)
        'muscle_group_weights_json': muscleGroupWeightsJson,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExerciseTemplatesCompanion copyWith({
    Value<String>? key,
    Value<String>? gymId,
    Value<String>? name,
    Value<bool>? isRankingEligible,
    Value<String?>? primaryMuscleGroup,
    Value<String>? muscleGroupWeightsJson,
    Value<bool>? isActive,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return LocalExerciseTemplatesCompanion(
      key: key ?? this.key,
      gymId: gymId ?? this.gymId,
      name: name ?? this.name,
      isRankingEligible: isRankingEligible ?? this.isRankingEligible,
      primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
      muscleGroupWeightsJson:
          muscleGroupWeightsJson ?? this.muscleGroupWeightsJson,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (gymId.present) {
      map['gym_id'] = Variable<String>(gymId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isRankingEligible.present) {
      map['is_ranking_eligible'] = Variable<bool>(isRankingEligible.value);
    }
    if (primaryMuscleGroup.present) {
      map['primary_muscle_group'] = Variable<String>(primaryMuscleGroup.value);
    }
    if (muscleGroupWeightsJson.present) {
      map['muscle_group_weights_json'] = Variable<String>(
        muscleGroupWeightsJson.value,
      );
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExerciseTemplatesCompanion(')
          ..write('key: $key, ')
          ..write('gymId: $gymId, ')
          ..write('name: $name, ')
          ..write('isRankingEligible: $isRankingEligible, ')
          ..write('primaryMuscleGroup: $primaryMuscleGroup, ')
          ..write('muscleGroupWeightsJson: $muscleGroupWeightsJson, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalUserCustomExercisesTable extends LocalUserCustomExercises
    with TableInfo<$LocalUserCustomExercisesTable, LocalUserCustomExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUserCustomExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gymIdMeta = const VerificationMeta('gymId');
  @override
  late final GeneratedColumn<String> gymId = GeneratedColumn<String>(
    'gym_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentIdMeta = const VerificationMeta(
    'equipmentId',
  );
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
    'equipment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_saved'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gymId,
    userId,
    name,
    equipmentId,
    syncStatus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_user_custom_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalUserCustomExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('gym_id')) {
      context.handle(
        _gymIdMeta,
        gymId.isAcceptableOrUnknown(data['gym_id']!, _gymIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gymIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
        _equipmentIdMeta,
        equipmentId.isAcceptableOrUnknown(
          data['equipment_id']!,
          _equipmentIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUserCustomExercise map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUserCustomExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gymId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gym_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      equipmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalUserCustomExercisesTable createAlias(String alias) {
    return $LocalUserCustomExercisesTable(attachedDatabase, alias);
  }
}

class LocalUserCustomExercise extends DataClass
    implements Insertable<LocalUserCustomExercise> {
  final String id;
  final String gymId;
  final String userId;
  final String name;
  final String? equipmentId;
  final String syncStatus;
  final DateTime createdAt;
  const LocalUserCustomExercise({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.name,
    this.equipmentId,
    required this.syncStatus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['gym_id'] = Variable<String>(gymId);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || equipmentId != null) {
      map['equipment_id'] = Variable<String>(equipmentId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalUserCustomExercisesCompanion toCompanion(bool nullToAbsent) {
    return LocalUserCustomExercisesCompanion(
      id: Value(id),
      gymId: Value(gymId),
      userId: Value(userId),
      name: Value(name),
      equipmentId: equipmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(equipmentId),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
    );
  }

  factory LocalUserCustomExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUserCustomExercise(
      id: serializer.fromJson<String>(json['id']),
      gymId: serializer.fromJson<String>(json['gymId']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      equipmentId: serializer.fromJson<String?>(json['equipmentId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'gymId': serializer.toJson<String>(gymId),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'equipmentId': serializer.toJson<String?>(equipmentId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalUserCustomExercise copyWith({
    String? id,
    String? gymId,
    String? userId,
    String? name,
    Value<String?> equipmentId = const Value.absent(),
    String? syncStatus,
    DateTime? createdAt,
  }) => LocalUserCustomExercise(
    id: id ?? this.id,
    gymId: gymId ?? this.gymId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    equipmentId: equipmentId.present ? equipmentId.value : this.equipmentId,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalUserCustomExercise copyWithCompanion(
    LocalUserCustomExercisesCompanion data,
  ) {
    return LocalUserCustomExercise(
      id: data.id.present ? data.id.value : this.id,
      gymId: data.gymId.present ? data.gymId.value : this.gymId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      equipmentId: data.equipmentId.present
          ? data.equipmentId.value
          : this.equipmentId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserCustomExercise(')
          ..write('id: $id, ')
          ..write('gymId: $gymId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gymId, userId, name, equipmentId, syncStatus, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUserCustomExercise &&
          other.id == this.id &&
          other.gymId == this.gymId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.equipmentId == this.equipmentId &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt);
}

class LocalUserCustomExercisesCompanion
    extends UpdateCompanion<LocalUserCustomExercise> {
  final Value<String> id;
  final Value<String> gymId;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> equipmentId;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalUserCustomExercisesCompanion({
    this.id = const Value.absent(),
    this.gymId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUserCustomExercisesCompanion.insert({
    required String id,
    required String gymId,
    required String userId,
    required String name,
    this.equipmentId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       gymId = Value(gymId),
       userId = Value(userId),
       name = Value(name);
  static Insertable<LocalUserCustomExercise> custom({
    Expression<String>? id,
    Expression<String>? gymId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? equipmentId,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gymId != null) 'gym_id': gymId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUserCustomExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? gymId,
    Value<String>? userId,
    Value<String>? name,
    Value<String?>? equipmentId,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalUserCustomExercisesCompanion(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      equipmentId: equipmentId ?? this.equipmentId,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gymId.present) {
      map['gym_id'] = Variable<String>(gymId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserCustomExercisesCompanion(')
          ..write('id: $id, ')
          ..write('gymId: $gymId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalWorkoutSessionsTable extends LocalWorkoutSessions
    with TableInfo<$LocalWorkoutSessionsTable, LocalWorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gymIdMeta = const VerificationMeta('gymId');
  @override
  late final GeneratedColumn<String> gymId = GeneratedColumn<String>(
    'gym_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentIdMeta = const VerificationMeta(
    'equipmentId',
  );
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
    'equipment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionDayAnchorMeta = const VerificationMeta(
    'sessionDayAnchor',
  );
  @override
  late final GeneratedColumn<String> sessionDayAnchor = GeneratedColumn<String>(
    'session_day_anchor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_saved'),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSyncedIdMeta = const VerificationMeta(
    'serverSyncedId',
  );
  @override
  late final GeneratedColumn<String> serverSyncedId = GeneratedColumn<String>(
    'server_synced_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gymId,
    userId,
    equipmentId,
    sessionDayAnchor,
    startedAt,
    finishedAt,
    syncStatus,
    idempotencyKey,
    notes,
    serverSyncedId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalWorkoutSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('gym_id')) {
      context.handle(
        _gymIdMeta,
        gymId.isAcceptableOrUnknown(data['gym_id']!, _gymIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gymIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
        _equipmentIdMeta,
        equipmentId.isAcceptableOrUnknown(
          data['equipment_id']!,
          _equipmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_equipmentIdMeta);
    }
    if (data.containsKey('session_day_anchor')) {
      context.handle(
        _sessionDayAnchorMeta,
        sessionDayAnchor.isAcceptableOrUnknown(
          data['session_day_anchor']!,
          _sessionDayAnchorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionDayAnchorMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('server_synced_id')) {
      context.handle(
        _serverSyncedIdMeta,
        serverSyncedId.isAcceptableOrUnknown(
          data['server_synced_id']!,
          _serverSyncedIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalWorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWorkoutSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gymId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gym_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      equipmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_id'],
      )!,
      sessionDayAnchor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_day_anchor'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      serverSyncedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_synced_id'],
      ),
    );
  }

  @override
  $LocalWorkoutSessionsTable createAlias(String alias) {
    return $LocalWorkoutSessionsTable(attachedDatabase, alias);
  }
}

class LocalWorkoutSession extends DataClass
    implements Insertable<LocalWorkoutSession> {
  final String id;
  final String gymId;
  final String userId;
  final String equipmentId;
  final String sessionDayAnchor;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String syncStatus;
  final String idempotencyKey;
  final String? notes;
  final String? serverSyncedId;
  const LocalWorkoutSession({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.equipmentId,
    required this.sessionDayAnchor,
    required this.startedAt,
    this.finishedAt,
    required this.syncStatus,
    required this.idempotencyKey,
    this.notes,
    this.serverSyncedId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['gym_id'] = Variable<String>(gymId);
    map['user_id'] = Variable<String>(userId);
    map['equipment_id'] = Variable<String>(equipmentId);
    map['session_day_anchor'] = Variable<String>(sessionDayAnchor);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || serverSyncedId != null) {
      map['server_synced_id'] = Variable<String>(serverSyncedId);
    }
    return map;
  }

  LocalWorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalWorkoutSessionsCompanion(
      id: Value(id),
      gymId: Value(gymId),
      userId: Value(userId),
      equipmentId: Value(equipmentId),
      sessionDayAnchor: Value(sessionDayAnchor),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      syncStatus: Value(syncStatus),
      idempotencyKey: Value(idempotencyKey),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      serverSyncedId: serverSyncedId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSyncedId),
    );
  }

  factory LocalWorkoutSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWorkoutSession(
      id: serializer.fromJson<String>(json['id']),
      gymId: serializer.fromJson<String>(json['gymId']),
      userId: serializer.fromJson<String>(json['userId']),
      equipmentId: serializer.fromJson<String>(json['equipmentId']),
      sessionDayAnchor: serializer.fromJson<String>(json['sessionDayAnchor']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      notes: serializer.fromJson<String?>(json['notes']),
      serverSyncedId: serializer.fromJson<String?>(json['serverSyncedId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'gymId': serializer.toJson<String>(gymId),
      'userId': serializer.toJson<String>(userId),
      'equipmentId': serializer.toJson<String>(equipmentId),
      'sessionDayAnchor': serializer.toJson<String>(sessionDayAnchor),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'notes': serializer.toJson<String?>(notes),
      'serverSyncedId': serializer.toJson<String?>(serverSyncedId),
    };
  }

  LocalWorkoutSession copyWith({
    String? id,
    String? gymId,
    String? userId,
    String? equipmentId,
    String? sessionDayAnchor,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    String? syncStatus,
    String? idempotencyKey,
    Value<String?> notes = const Value.absent(),
    Value<String?> serverSyncedId = const Value.absent(),
  }) => LocalWorkoutSession(
    id: id ?? this.id,
    gymId: gymId ?? this.gymId,
    userId: userId ?? this.userId,
    equipmentId: equipmentId ?? this.equipmentId,
    sessionDayAnchor: sessionDayAnchor ?? this.sessionDayAnchor,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    notes: notes.present ? notes.value : this.notes,
    serverSyncedId: serverSyncedId.present
        ? serverSyncedId.value
        : this.serverSyncedId,
  );
  LocalWorkoutSession copyWithCompanion(LocalWorkoutSessionsCompanion data) {
    return LocalWorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      gymId: data.gymId.present ? data.gymId.value : this.gymId,
      userId: data.userId.present ? data.userId.value : this.userId,
      equipmentId: data.equipmentId.present
          ? data.equipmentId.value
          : this.equipmentId,
      sessionDayAnchor: data.sessionDayAnchor.present
          ? data.sessionDayAnchor.value
          : this.sessionDayAnchor,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      notes: data.notes.present ? data.notes.value : this.notes,
      serverSyncedId: data.serverSyncedId.present
          ? data.serverSyncedId.value
          : this.serverSyncedId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutSession(')
          ..write('id: $id, ')
          ..write('gymId: $gymId, ')
          ..write('userId: $userId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('sessionDayAnchor: $sessionDayAnchor, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('notes: $notes, ')
          ..write('serverSyncedId: $serverSyncedId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gymId,
    userId,
    equipmentId,
    sessionDayAnchor,
    startedAt,
    finishedAt,
    syncStatus,
    idempotencyKey,
    notes,
    serverSyncedId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWorkoutSession &&
          other.id == this.id &&
          other.gymId == this.gymId &&
          other.userId == this.userId &&
          other.equipmentId == this.equipmentId &&
          other.sessionDayAnchor == this.sessionDayAnchor &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.syncStatus == this.syncStatus &&
          other.idempotencyKey == this.idempotencyKey &&
          other.notes == this.notes &&
          other.serverSyncedId == this.serverSyncedId);
}

class LocalWorkoutSessionsCompanion
    extends UpdateCompanion<LocalWorkoutSession> {
  final Value<String> id;
  final Value<String> gymId;
  final Value<String> userId;
  final Value<String> equipmentId;
  final Value<String> sessionDayAnchor;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<String> syncStatus;
  final Value<String> idempotencyKey;
  final Value<String?> notes;
  final Value<String?> serverSyncedId;
  final Value<int> rowid;
  const LocalWorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.gymId = const Value.absent(),
    this.userId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.sessionDayAnchor = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.notes = const Value.absent(),
    this.serverSyncedId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalWorkoutSessionsCompanion.insert({
    required String id,
    required String gymId,
    required String userId,
    required String equipmentId,
    required String sessionDayAnchor,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String idempotencyKey,
    this.notes = const Value.absent(),
    this.serverSyncedId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       gymId = Value(gymId),
       userId = Value(userId),
       equipmentId = Value(equipmentId),
       sessionDayAnchor = Value(sessionDayAnchor),
       startedAt = Value(startedAt),
       idempotencyKey = Value(idempotencyKey);
  static Insertable<LocalWorkoutSession> custom({
    Expression<String>? id,
    Expression<String>? gymId,
    Expression<String>? userId,
    Expression<String>? equipmentId,
    Expression<String>? sessionDayAnchor,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? syncStatus,
    Expression<String>? idempotencyKey,
    Expression<String>? notes,
    Expression<String>? serverSyncedId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gymId != null) 'gym_id': gymId,
      if (userId != null) 'user_id': userId,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (sessionDayAnchor != null) 'session_day_anchor': sessionDayAnchor,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (notes != null) 'notes': notes,
      if (serverSyncedId != null) 'server_synced_id': serverSyncedId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalWorkoutSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? gymId,
    Value<String>? userId,
    Value<String>? equipmentId,
    Value<String>? sessionDayAnchor,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<String>? syncStatus,
    Value<String>? idempotencyKey,
    Value<String?>? notes,
    Value<String?>? serverSyncedId,
    Value<int>? rowid,
  }) {
    return LocalWorkoutSessionsCompanion(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      userId: userId ?? this.userId,
      equipmentId: equipmentId ?? this.equipmentId,
      sessionDayAnchor: sessionDayAnchor ?? this.sessionDayAnchor,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      notes: notes ?? this.notes,
      serverSyncedId: serverSyncedId ?? this.serverSyncedId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gymId.present) {
      map['gym_id'] = Variable<String>(gymId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (sessionDayAnchor.present) {
      map['session_day_anchor'] = Variable<String>(sessionDayAnchor.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (serverSyncedId.present) {
      map['server_synced_id'] = Variable<String>(serverSyncedId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('gymId: $gymId, ')
          ..write('userId: $userId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('sessionDayAnchor: $sessionDayAnchor, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('notes: $notes, ')
          ..write('serverSyncedId: $serverSyncedId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSessionExercisesTable extends LocalSessionExercises
    with TableInfo<$LocalSessionExercisesTable, LocalSessionExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSessionExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gymIdMeta = const VerificationMeta('gymId');
  @override
  late final GeneratedColumn<String> gymId = GeneratedColumn<String>(
    'gym_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseKeyMeta = const VerificationMeta(
    'exerciseKey',
  );
  @override
  late final GeneratedColumn<String> exerciseKey = GeneratedColumn<String>(
    'exercise_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customExerciseIdMeta = const VerificationMeta(
    'customExerciseId',
  );
  @override
  late final GeneratedColumn<String> customExerciseId = GeneratedColumn<String>(
    'custom_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentIdMeta = const VerificationMeta(
    'equipmentId',
  );
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
    'equipment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_saved'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    gymId,
    exerciseKey,
    displayName,
    sortOrder,
    customExerciseId,
    equipmentId,
    notes,
    syncStatus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_session_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSessionExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('gym_id')) {
      context.handle(
        _gymIdMeta,
        gymId.isAcceptableOrUnknown(data['gym_id']!, _gymIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gymIdMeta);
    }
    if (data.containsKey('exercise_key')) {
      context.handle(
        _exerciseKeyMeta,
        exerciseKey.isAcceptableOrUnknown(
          data['exercise_key']!,
          _exerciseKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseKeyMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('custom_exercise_id')) {
      context.handle(
        _customExerciseIdMeta,
        customExerciseId.isAcceptableOrUnknown(
          data['custom_exercise_id']!,
          _customExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
        _equipmentIdMeta,
        equipmentId.isAcceptableOrUnknown(
          data['equipment_id']!,
          _equipmentIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSessionExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSessionExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      gymId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gym_id'],
      )!,
      exerciseKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_key'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      customExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_exercise_id'],
      ),
      equipmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalSessionExercisesTable createAlias(String alias) {
    return $LocalSessionExercisesTable(attachedDatabase, alias);
  }
}

class LocalSessionExercise extends DataClass
    implements Insertable<LocalSessionExercise> {
  final String id;
  final String sessionId;
  final String gymId;
  final String exerciseKey;
  final String displayName;
  final int sortOrder;
  final String? customExerciseId;

  /// The gym-equipment ID of the machine/station this exercise was performed
  /// on.  Set when adding the exercise from the gym screen (v3+).
  /// Null for data migrated from before v3 — XP code falls back to exerciseKey.
  final String? equipmentId;
  final String? notes;
  final String syncStatus;
  final DateTime createdAt;
  const LocalSessionExercise({
    required this.id,
    required this.sessionId,
    required this.gymId,
    required this.exerciseKey,
    required this.displayName,
    required this.sortOrder,
    this.customExerciseId,
    this.equipmentId,
    this.notes,
    required this.syncStatus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['gym_id'] = Variable<String>(gymId);
    map['exercise_key'] = Variable<String>(exerciseKey);
    map['display_name'] = Variable<String>(displayName);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || customExerciseId != null) {
      map['custom_exercise_id'] = Variable<String>(customExerciseId);
    }
    if (!nullToAbsent || equipmentId != null) {
      map['equipment_id'] = Variable<String>(equipmentId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalSessionExercisesCompanion toCompanion(bool nullToAbsent) {
    return LocalSessionExercisesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      gymId: Value(gymId),
      exerciseKey: Value(exerciseKey),
      displayName: Value(displayName),
      sortOrder: Value(sortOrder),
      customExerciseId: customExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(customExerciseId),
      equipmentId: equipmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(equipmentId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
    );
  }

  factory LocalSessionExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSessionExercise(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      gymId: serializer.fromJson<String>(json['gymId']),
      exerciseKey: serializer.fromJson<String>(json['exerciseKey']),
      displayName: serializer.fromJson<String>(json['displayName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      customExerciseId: serializer.fromJson<String?>(json['customExerciseId']),
      equipmentId: serializer.fromJson<String?>(json['equipmentId']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'gymId': serializer.toJson<String>(gymId),
      'exerciseKey': serializer.toJson<String>(exerciseKey),
      'displayName': serializer.toJson<String>(displayName),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'customExerciseId': serializer.toJson<String?>(customExerciseId),
      'equipmentId': serializer.toJson<String?>(equipmentId),
      'notes': serializer.toJson<String?>(notes),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalSessionExercise copyWith({
    String? id,
    String? sessionId,
    String? gymId,
    String? exerciseKey,
    String? displayName,
    int? sortOrder,
    Value<String?> customExerciseId = const Value.absent(),
    Value<String?> equipmentId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? syncStatus,
    DateTime? createdAt,
  }) => LocalSessionExercise(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    gymId: gymId ?? this.gymId,
    exerciseKey: exerciseKey ?? this.exerciseKey,
    displayName: displayName ?? this.displayName,
    sortOrder: sortOrder ?? this.sortOrder,
    customExerciseId: customExerciseId.present
        ? customExerciseId.value
        : this.customExerciseId,
    equipmentId: equipmentId.present ? equipmentId.value : this.equipmentId,
    notes: notes.present ? notes.value : this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalSessionExercise copyWithCompanion(LocalSessionExercisesCompanion data) {
    return LocalSessionExercise(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      gymId: data.gymId.present ? data.gymId.value : this.gymId,
      exerciseKey: data.exerciseKey.present
          ? data.exerciseKey.value
          : this.exerciseKey,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      customExerciseId: data.customExerciseId.present
          ? data.customExerciseId.value
          : this.customExerciseId,
      equipmentId: data.equipmentId.present
          ? data.equipmentId.value
          : this.equipmentId,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSessionExercise(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('gymId: $gymId, ')
          ..write('exerciseKey: $exerciseKey, ')
          ..write('displayName: $displayName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('customExerciseId: $customExerciseId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    gymId,
    exerciseKey,
    displayName,
    sortOrder,
    customExerciseId,
    equipmentId,
    notes,
    syncStatus,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSessionExercise &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.gymId == this.gymId &&
          other.exerciseKey == this.exerciseKey &&
          other.displayName == this.displayName &&
          other.sortOrder == this.sortOrder &&
          other.customExerciseId == this.customExerciseId &&
          other.equipmentId == this.equipmentId &&
          other.notes == this.notes &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt);
}

class LocalSessionExercisesCompanion
    extends UpdateCompanion<LocalSessionExercise> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> gymId;
  final Value<String> exerciseKey;
  final Value<String> displayName;
  final Value<int> sortOrder;
  final Value<String?> customExerciseId;
  final Value<String?> equipmentId;
  final Value<String?> notes;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalSessionExercisesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.gymId = const Value.absent(),
    this.exerciseKey = const Value.absent(),
    this.displayName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.customExerciseId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSessionExercisesCompanion.insert({
    required String id,
    required String sessionId,
    required String gymId,
    required String exerciseKey,
    required String displayName,
    this.sortOrder = const Value.absent(),
    this.customExerciseId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       gymId = Value(gymId),
       exerciseKey = Value(exerciseKey),
       displayName = Value(displayName);
  static Insertable<LocalSessionExercise> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? gymId,
    Expression<String>? exerciseKey,
    Expression<String>? displayName,
    Expression<int>? sortOrder,
    Expression<String>? customExerciseId,
    Expression<String>? equipmentId,
    Expression<String>? notes,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (gymId != null) 'gym_id': gymId,
      if (exerciseKey != null) 'exercise_key': exerciseKey,
      if (displayName != null) 'display_name': displayName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (customExerciseId != null) 'custom_exercise_id': customExerciseId,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (notes != null) 'notes': notes,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSessionExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? gymId,
    Value<String>? exerciseKey,
    Value<String>? displayName,
    Value<int>? sortOrder,
    Value<String?>? customExerciseId,
    Value<String?>? equipmentId,
    Value<String?>? notes,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalSessionExercisesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      gymId: gymId ?? this.gymId,
      exerciseKey: exerciseKey ?? this.exerciseKey,
      displayName: displayName ?? this.displayName,
      sortOrder: sortOrder ?? this.sortOrder,
      customExerciseId: customExerciseId ?? this.customExerciseId,
      equipmentId: equipmentId ?? this.equipmentId,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (gymId.present) {
      map['gym_id'] = Variable<String>(gymId.value);
    }
    if (exerciseKey.present) {
      map['exercise_key'] = Variable<String>(exerciseKey.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (customExerciseId.present) {
      map['custom_exercise_id'] = Variable<String>(customExerciseId.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSessionExercisesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('gymId: $gymId, ')
          ..write('exerciseKey: $exerciseKey, ')
          ..write('displayName: $displayName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('customExerciseId: $customExerciseId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSetEntriesTable extends LocalSetEntries
    with TableInfo<$LocalSetEntriesTable, LocalSetEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSetEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionExerciseIdMeta = const VerificationMeta(
    'sessionExerciseId',
  );
  @override
  late final GeneratedColumn<String> sessionExerciseId =
      GeneratedColumn<String>(
        'session_exercise_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _gymIdMeta = const VerificationMeta('gymId');
  @override
  late final GeneratedColumn<String> gymId = GeneratedColumn<String>(
    'gym_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setNumberMeta = const VerificationMeta(
    'setNumber',
  );
  @override
  late final GeneratedColumn<int> setNumber = GeneratedColumn<int>(
    'set_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_saved'),
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionExerciseId,
    gymId,
    setNumber,
    reps,
    weightKg,
    durationSeconds,
    distanceMeters,
    notes,
    syncStatus,
    loggedAt,
    idempotencyKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_set_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_exercise_id')) {
      context.handle(
        _sessionExerciseIdMeta,
        sessionExerciseId.isAcceptableOrUnknown(
          data['session_exercise_id']!,
          _sessionExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionExerciseIdMeta);
    }
    if (data.containsKey('gym_id')) {
      context.handle(
        _gymIdMeta,
        gymId.isAcceptableOrUnknown(data['gym_id']!, _gymIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gymIdMeta);
    }
    if (data.containsKey('set_number')) {
      context.handle(
        _setNumberMeta,
        setNumber.isAcceptableOrUnknown(data['set_number']!, _setNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_setNumberMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSetEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_exercise_id'],
      )!,
      gymId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gym_id'],
      )!,
      setNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_number'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
    );
  }

  @override
  $LocalSetEntriesTable createAlias(String alias) {
    return $LocalSetEntriesTable(attachedDatabase, alias);
  }
}

class LocalSetEntry extends DataClass implements Insertable<LocalSetEntry> {
  final String id;
  final String sessionExerciseId;
  final String gymId;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final String? notes;
  final String syncStatus;
  final DateTime loggedAt;
  final String idempotencyKey;
  const LocalSetEntry({
    required this.id,
    required this.sessionExerciseId,
    required this.gymId,
    required this.setNumber,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
    this.notes,
    required this.syncStatus,
    required this.loggedAt,
    required this.idempotencyKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_exercise_id'] = Variable<String>(sessionExerciseId);
    map['gym_id'] = Variable<String>(gymId);
    map['set_number'] = Variable<int>(setNumber);
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || distanceMeters != null) {
      map['distance_meters'] = Variable<double>(distanceMeters);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    return map;
  }

  LocalSetEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalSetEntriesCompanion(
      id: Value(id),
      sessionExerciseId: Value(sessionExerciseId),
      gymId: Value(gymId),
      setNumber: Value(setNumber),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      distanceMeters: distanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceMeters),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncStatus: Value(syncStatus),
      loggedAt: Value(loggedAt),
      idempotencyKey: Value(idempotencyKey),
    );
  }

  factory LocalSetEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetEntry(
      id: serializer.fromJson<String>(json['id']),
      sessionExerciseId: serializer.fromJson<String>(json['sessionExerciseId']),
      gymId: serializer.fromJson<String>(json['gymId']),
      setNumber: serializer.fromJson<int>(json['setNumber']),
      reps: serializer.fromJson<int?>(json['reps']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      distanceMeters: serializer.fromJson<double?>(json['distanceMeters']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionExerciseId': serializer.toJson<String>(sessionExerciseId),
      'gymId': serializer.toJson<String>(gymId),
      'setNumber': serializer.toJson<int>(setNumber),
      'reps': serializer.toJson<int?>(reps),
      'weightKg': serializer.toJson<double?>(weightKg),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'distanceMeters': serializer.toJson<double?>(distanceMeters),
      'notes': serializer.toJson<String?>(notes),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
    };
  }

  LocalSetEntry copyWith({
    String? id,
    String? sessionExerciseId,
    String? gymId,
    int? setNumber,
    Value<int?> reps = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<double?> distanceMeters = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? syncStatus,
    DateTime? loggedAt,
    String? idempotencyKey,
  }) => LocalSetEntry(
    id: id ?? this.id,
    sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
    gymId: gymId ?? this.gymId,
    setNumber: setNumber ?? this.setNumber,
    reps: reps.present ? reps.value : this.reps,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    distanceMeters: distanceMeters.present
        ? distanceMeters.value
        : this.distanceMeters,
    notes: notes.present ? notes.value : this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
    loggedAt: loggedAt ?? this.loggedAt,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
  );
  LocalSetEntry copyWithCompanion(LocalSetEntriesCompanion data) {
    return LocalSetEntry(
      id: data.id.present ? data.id.value : this.id,
      sessionExerciseId: data.sessionExerciseId.present
          ? data.sessionExerciseId.value
          : this.sessionExerciseId,
      gymId: data.gymId.present ? data.gymId.value : this.gymId,
      setNumber: data.setNumber.present ? data.setNumber.value : this.setNumber,
      reps: data.reps.present ? data.reps.value : this.reps,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetEntry(')
          ..write('id: $id, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('gymId: $gymId, ')
          ..write('setNumber: $setNumber, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('idempotencyKey: $idempotencyKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionExerciseId,
    gymId,
    setNumber,
    reps,
    weightKg,
    durationSeconds,
    distanceMeters,
    notes,
    syncStatus,
    loggedAt,
    idempotencyKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSetEntry &&
          other.id == this.id &&
          other.sessionExerciseId == this.sessionExerciseId &&
          other.gymId == this.gymId &&
          other.setNumber == this.setNumber &&
          other.reps == this.reps &&
          other.weightKg == this.weightKg &&
          other.durationSeconds == this.durationSeconds &&
          other.distanceMeters == this.distanceMeters &&
          other.notes == this.notes &&
          other.syncStatus == this.syncStatus &&
          other.loggedAt == this.loggedAt &&
          other.idempotencyKey == this.idempotencyKey);
}

class LocalSetEntriesCompanion extends UpdateCompanion<LocalSetEntry> {
  final Value<String> id;
  final Value<String> sessionExerciseId;
  final Value<String> gymId;
  final Value<int> setNumber;
  final Value<int?> reps;
  final Value<double?> weightKg;
  final Value<int?> durationSeconds;
  final Value<double?> distanceMeters;
  final Value<String?> notes;
  final Value<String> syncStatus;
  final Value<DateTime> loggedAt;
  final Value<String> idempotencyKey;
  final Value<int> rowid;
  const LocalSetEntriesCompanion({
    this.id = const Value.absent(),
    this.sessionExerciseId = const Value.absent(),
    this.gymId = const Value.absent(),
    this.setNumber = const Value.absent(),
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSetEntriesCompanion.insert({
    required String id,
    required String sessionExerciseId,
    required String gymId,
    required int setNumber,
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.loggedAt = const Value.absent(),
    required String idempotencyKey,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionExerciseId = Value(sessionExerciseId),
       gymId = Value(gymId),
       setNumber = Value(setNumber),
       idempotencyKey = Value(idempotencyKey);
  static Insertable<LocalSetEntry> custom({
    Expression<String>? id,
    Expression<String>? sessionExerciseId,
    Expression<String>? gymId,
    Expression<int>? setNumber,
    Expression<int>? reps,
    Expression<double>? weightKg,
    Expression<int>? durationSeconds,
    Expression<double>? distanceMeters,
    Expression<String>? notes,
    Expression<String>? syncStatus,
    Expression<DateTime>? loggedAt,
    Expression<String>? idempotencyKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionExerciseId != null) 'session_exercise_id': sessionExerciseId,
      if (gymId != null) 'gym_id': gymId,
      if (setNumber != null) 'set_number': setNumber,
      if (reps != null) 'reps': reps,
      if (weightKg != null) 'weight_kg': weightKg,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (notes != null) 'notes': notes,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSetEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionExerciseId,
    Value<String>? gymId,
    Value<int>? setNumber,
    Value<int?>? reps,
    Value<double?>? weightKg,
    Value<int?>? durationSeconds,
    Value<double?>? distanceMeters,
    Value<String?>? notes,
    Value<String>? syncStatus,
    Value<DateTime>? loggedAt,
    Value<String>? idempotencyKey,
    Value<int>? rowid,
  }) {
    return LocalSetEntriesCompanion(
      id: id ?? this.id,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      gymId: gymId ?? this.gymId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      loggedAt: loggedAt ?? this.loggedAt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionExerciseId.present) {
      map['session_exercise_id'] = Variable<String>(sessionExerciseId.value);
    }
    if (gymId.present) {
      map['gym_id'] = Variable<String>(gymId.value);
    }
    if (setNumber.present) {
      map['set_number'] = Variable<int>(setNumber.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('gymId: $gymId, ')
          ..write('setNumber: $setNumber, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalEquipmentFavouritesTable extends LocalEquipmentFavourites
    with TableInfo<$LocalEquipmentFavouritesTable, LocalEquipmentFavourite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalEquipmentFavouritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gymIdMeta = const VerificationMeta('gymId');
  @override
  late final GeneratedColumn<String> gymId = GeneratedColumn<String>(
    'gym_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentIdMeta = const VerificationMeta(
    'equipmentId',
  );
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
    'equipment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, gymId, equipmentId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_equipment_favourites';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalEquipmentFavourite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('gym_id')) {
      context.handle(
        _gymIdMeta,
        gymId.isAcceptableOrUnknown(data['gym_id']!, _gymIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gymIdMeta);
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
        _equipmentIdMeta,
        equipmentId.isAcceptableOrUnknown(
          data['equipment_id']!,
          _equipmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_equipmentIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, gymId, equipmentId};
  @override
  LocalEquipmentFavourite map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalEquipmentFavourite(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      gymId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gym_id'],
      )!,
      equipmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_id'],
      )!,
    );
  }

  @override
  $LocalEquipmentFavouritesTable createAlias(String alias) {
    return $LocalEquipmentFavouritesTable(attachedDatabase, alias);
  }
}

class LocalEquipmentFavourite extends DataClass
    implements Insertable<LocalEquipmentFavourite> {
  final String userId;
  final String gymId;
  final String equipmentId;
  const LocalEquipmentFavourite({
    required this.userId,
    required this.gymId,
    required this.equipmentId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['gym_id'] = Variable<String>(gymId);
    map['equipment_id'] = Variable<String>(equipmentId);
    return map;
  }

  LocalEquipmentFavouritesCompanion toCompanion(bool nullToAbsent) {
    return LocalEquipmentFavouritesCompanion(
      userId: Value(userId),
      gymId: Value(gymId),
      equipmentId: Value(equipmentId),
    );
  }

  factory LocalEquipmentFavourite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalEquipmentFavourite(
      userId: serializer.fromJson<String>(json['userId']),
      gymId: serializer.fromJson<String>(json['gymId']),
      equipmentId: serializer.fromJson<String>(json['equipmentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'gymId': serializer.toJson<String>(gymId),
      'equipmentId': serializer.toJson<String>(equipmentId),
    };
  }

  LocalEquipmentFavourite copyWith({
    String? userId,
    String? gymId,
    String? equipmentId,
  }) => LocalEquipmentFavourite(
    userId: userId ?? this.userId,
    gymId: gymId ?? this.gymId,
    equipmentId: equipmentId ?? this.equipmentId,
  );
  LocalEquipmentFavourite copyWithCompanion(
    LocalEquipmentFavouritesCompanion data,
  ) {
    return LocalEquipmentFavourite(
      userId: data.userId.present ? data.userId.value : this.userId,
      gymId: data.gymId.present ? data.gymId.value : this.gymId,
      equipmentId: data.equipmentId.present
          ? data.equipmentId.value
          : this.equipmentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalEquipmentFavourite(')
          ..write('userId: $userId, ')
          ..write('gymId: $gymId, ')
          ..write('equipmentId: $equipmentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, gymId, equipmentId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalEquipmentFavourite &&
          other.userId == this.userId &&
          other.gymId == this.gymId &&
          other.equipmentId == this.equipmentId);
}

class LocalEquipmentFavouritesCompanion
    extends UpdateCompanion<LocalEquipmentFavourite> {
  final Value<String> userId;
  final Value<String> gymId;
  final Value<String> equipmentId;
  final Value<int> rowid;
  const LocalEquipmentFavouritesCompanion({
    this.userId = const Value.absent(),
    this.gymId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalEquipmentFavouritesCompanion.insert({
    required String userId,
    required String gymId,
    required String equipmentId,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       gymId = Value(gymId),
       equipmentId = Value(equipmentId);
  static Insertable<LocalEquipmentFavourite> custom({
    Expression<String>? userId,
    Expression<String>? gymId,
    Expression<String>? equipmentId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (gymId != null) 'gym_id': gymId,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalEquipmentFavouritesCompanion copyWith({
    Value<String>? userId,
    Value<String>? gymId,
    Value<String>? equipmentId,
    Value<int>? rowid,
  }) {
    return LocalEquipmentFavouritesCompanion(
      userId: userId ?? this.userId,
      gymId: gymId ?? this.gymId,
      equipmentId: equipmentId ?? this.equipmentId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (gymId.present) {
      map['gym_id'] = Variable<String>(gymId.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalEquipmentFavouritesCompanion(')
          ..write('userId: $userId, ')
          ..write('gymId: $gymId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalWorkoutPlansTable extends LocalWorkoutPlans
    with TableInfo<$LocalWorkoutPlansTable, LocalWorkoutPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWorkoutPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gymIdMeta = const VerificationMeta('gymId');
  @override
  late final GeneratedColumn<String> gymId = GeneratedColumn<String>(
    'gym_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_saved'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gymId,
    userId,
    name,
    isActive,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_workout_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalWorkoutPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('gym_id')) {
      context.handle(
        _gymIdMeta,
        gymId.isAcceptableOrUnknown(data['gym_id']!, _gymIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gymIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalWorkoutPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWorkoutPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gymId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gym_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalWorkoutPlansTable createAlias(String alias) {
    return $LocalWorkoutPlansTable(attachedDatabase, alias);
  }
}

class LocalWorkoutPlan extends DataClass
    implements Insertable<LocalWorkoutPlan> {
  final String id;
  final String gymId;
  final String userId;
  final String name;
  final bool isActive;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalWorkoutPlan({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.name,
    required this.isActive,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['gym_id'] = Variable<String>(gymId);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['is_active'] = Variable<bool>(isActive);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalWorkoutPlansCompanion toCompanion(bool nullToAbsent) {
    return LocalWorkoutPlansCompanion(
      id: Value(id),
      gymId: Value(gymId),
      userId: Value(userId),
      name: Value(name),
      isActive: Value(isActive),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalWorkoutPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWorkoutPlan(
      id: serializer.fromJson<String>(json['id']),
      gymId: serializer.fromJson<String>(json['gymId']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'gymId': serializer.toJson<String>(gymId),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'isActive': serializer.toJson<bool>(isActive),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalWorkoutPlan copyWith({
    String? id,
    String? gymId,
    String? userId,
    String? name,
    bool? isActive,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalWorkoutPlan(
    id: id ?? this.id,
    gymId: gymId ?? this.gymId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalWorkoutPlan copyWithCompanion(LocalWorkoutPlansCompanion data) {
    return LocalWorkoutPlan(
      id: data.id.present ? data.id.value : this.id,
      gymId: data.gymId.present ? data.gymId.value : this.gymId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutPlan(')
          ..write('id: $id, ')
          ..write('gymId: $gymId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gymId,
    userId,
    name,
    isActive,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWorkoutPlan &&
          other.id == this.id &&
          other.gymId == this.gymId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.isActive == this.isActive &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalWorkoutPlansCompanion extends UpdateCompanion<LocalWorkoutPlan> {
  final Value<String> id;
  final Value<String> gymId;
  final Value<String> userId;
  final Value<String> name;
  final Value<bool> isActive;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalWorkoutPlansCompanion({
    this.id = const Value.absent(),
    this.gymId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalWorkoutPlansCompanion.insert({
    required String id,
    required String gymId,
    required String userId,
    required String name,
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       gymId = Value(gymId),
       userId = Value(userId),
       name = Value(name);
  static Insertable<LocalWorkoutPlan> custom({
    Expression<String>? id,
    Expression<String>? gymId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<bool>? isActive,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gymId != null) 'gym_id': gymId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalWorkoutPlansCompanion copyWith({
    Value<String>? id,
    Value<String>? gymId,
    Value<String>? userId,
    Value<String>? name,
    Value<bool>? isActive,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalWorkoutPlansCompanion(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gymId.present) {
      map['gym_id'] = Variable<String>(gymId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutPlansCompanion(')
          ..write('id: $id, ')
          ..write('gymId: $gymId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlanItemsTable extends LocalPlanItems
    with TableInfo<$LocalPlanItemsTable, LocalPlanItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlanItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gymIdMeta = const VerificationMeta('gymId');
  @override
  late final GeneratedColumn<String> gymId = GeneratedColumn<String>(
    'gym_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentIdMeta = const VerificationMeta(
    'equipmentId',
  );
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
    'equipment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalExerciseKeyMeta =
      const VerificationMeta('canonicalExerciseKey');
  @override
  late final GeneratedColumn<String> canonicalExerciseKey =
      GeneratedColumn<String>(
        'canonical_exercise_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customExerciseIdMeta = const VerificationMeta(
    'customExerciseId',
  );
  @override
  late final GeneratedColumn<String> customExerciseId = GeneratedColumn<String>(
    'custom_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    gymId,
    equipmentId,
    canonicalExerciseKey,
    customExerciseId,
    displayName,
    position,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_plan_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPlanItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('gym_id')) {
      context.handle(
        _gymIdMeta,
        gymId.isAcceptableOrUnknown(data['gym_id']!, _gymIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gymIdMeta);
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
        _equipmentIdMeta,
        equipmentId.isAcceptableOrUnknown(
          data['equipment_id']!,
          _equipmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_equipmentIdMeta);
    }
    if (data.containsKey('canonical_exercise_key')) {
      context.handle(
        _canonicalExerciseKeyMeta,
        canonicalExerciseKey.isAcceptableOrUnknown(
          data['canonical_exercise_key']!,
          _canonicalExerciseKeyMeta,
        ),
      );
    }
    if (data.containsKey('custom_exercise_id')) {
      context.handle(
        _customExerciseIdMeta,
        customExerciseId.isAcceptableOrUnknown(
          data['custom_exercise_id']!,
          _customExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlanItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlanItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      gymId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gym_id'],
      )!,
      equipmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_id'],
      )!,
      canonicalExerciseKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_exercise_key'],
      ),
      customExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_exercise_id'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalPlanItemsTable createAlias(String alias) {
    return $LocalPlanItemsTable(attachedDatabase, alias);
  }
}

class LocalPlanItem extends DataClass implements Insertable<LocalPlanItem> {
  final String id;
  final String planId;
  final String gymId;
  final String equipmentId;
  final String? canonicalExerciseKey;
  final String? customExerciseId;
  final String displayName;
  final int position;
  final DateTime createdAt;
  const LocalPlanItem({
    required this.id,
    required this.planId,
    required this.gymId,
    required this.equipmentId,
    this.canonicalExerciseKey,
    this.customExerciseId,
    required this.displayName,
    required this.position,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['gym_id'] = Variable<String>(gymId);
    map['equipment_id'] = Variable<String>(equipmentId);
    if (!nullToAbsent || canonicalExerciseKey != null) {
      map['canonical_exercise_key'] = Variable<String>(canonicalExerciseKey);
    }
    if (!nullToAbsent || customExerciseId != null) {
      map['custom_exercise_id'] = Variable<String>(customExerciseId);
    }
    map['display_name'] = Variable<String>(displayName);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalPlanItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlanItemsCompanion(
      id: Value(id),
      planId: Value(planId),
      gymId: Value(gymId),
      equipmentId: Value(equipmentId),
      canonicalExerciseKey: canonicalExerciseKey == null && nullToAbsent
          ? const Value.absent()
          : Value(canonicalExerciseKey),
      customExerciseId: customExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(customExerciseId),
      displayName: Value(displayName),
      position: Value(position),
      createdAt: Value(createdAt),
    );
  }

  factory LocalPlanItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlanItem(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      gymId: serializer.fromJson<String>(json['gymId']),
      equipmentId: serializer.fromJson<String>(json['equipmentId']),
      canonicalExerciseKey: serializer.fromJson<String?>(
        json['canonicalExerciseKey'],
      ),
      customExerciseId: serializer.fromJson<String?>(json['customExerciseId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'gymId': serializer.toJson<String>(gymId),
      'equipmentId': serializer.toJson<String>(equipmentId),
      'canonicalExerciseKey': serializer.toJson<String?>(canonicalExerciseKey),
      'customExerciseId': serializer.toJson<String?>(customExerciseId),
      'displayName': serializer.toJson<String>(displayName),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalPlanItem copyWith({
    String? id,
    String? planId,
    String? gymId,
    String? equipmentId,
    Value<String?> canonicalExerciseKey = const Value.absent(),
    Value<String?> customExerciseId = const Value.absent(),
    String? displayName,
    int? position,
    DateTime? createdAt,
  }) => LocalPlanItem(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    gymId: gymId ?? this.gymId,
    equipmentId: equipmentId ?? this.equipmentId,
    canonicalExerciseKey: canonicalExerciseKey.present
        ? canonicalExerciseKey.value
        : this.canonicalExerciseKey,
    customExerciseId: customExerciseId.present
        ? customExerciseId.value
        : this.customExerciseId,
    displayName: displayName ?? this.displayName,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalPlanItem copyWithCompanion(LocalPlanItemsCompanion data) {
    return LocalPlanItem(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      gymId: data.gymId.present ? data.gymId.value : this.gymId,
      equipmentId: data.equipmentId.present
          ? data.equipmentId.value
          : this.equipmentId,
      canonicalExerciseKey: data.canonicalExerciseKey.present
          ? data.canonicalExerciseKey.value
          : this.canonicalExerciseKey,
      customExerciseId: data.customExerciseId.present
          ? data.customExerciseId.value
          : this.customExerciseId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlanItem(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('gymId: $gymId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('canonicalExerciseKey: $canonicalExerciseKey, ')
          ..write('customExerciseId: $customExerciseId, ')
          ..write('displayName: $displayName, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    gymId,
    equipmentId,
    canonicalExerciseKey,
    customExerciseId,
    displayName,
    position,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlanItem &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.gymId == this.gymId &&
          other.equipmentId == this.equipmentId &&
          other.canonicalExerciseKey == this.canonicalExerciseKey &&
          other.customExerciseId == this.customExerciseId &&
          other.displayName == this.displayName &&
          other.position == this.position &&
          other.createdAt == this.createdAt);
}

class LocalPlanItemsCompanion extends UpdateCompanion<LocalPlanItem> {
  final Value<String> id;
  final Value<String> planId;
  final Value<String> gymId;
  final Value<String> equipmentId;
  final Value<String?> canonicalExerciseKey;
  final Value<String?> customExerciseId;
  final Value<String> displayName;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalPlanItemsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.gymId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.canonicalExerciseKey = const Value.absent(),
    this.customExerciseId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPlanItemsCompanion.insert({
    required String id,
    required String planId,
    required String gymId,
    required String equipmentId,
    this.canonicalExerciseKey = const Value.absent(),
    this.customExerciseId = const Value.absent(),
    required String displayName,
    required int position,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       gymId = Value(gymId),
       equipmentId = Value(equipmentId),
       displayName = Value(displayName),
       position = Value(position);
  static Insertable<LocalPlanItem> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<String>? gymId,
    Expression<String>? equipmentId,
    Expression<String>? canonicalExerciseKey,
    Expression<String>? customExerciseId,
    Expression<String>? displayName,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (gymId != null) 'gym_id': gymId,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (canonicalExerciseKey != null)
        'canonical_exercise_key': canonicalExerciseKey,
      if (customExerciseId != null) 'custom_exercise_id': customExerciseId,
      if (displayName != null) 'display_name': displayName,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPlanItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<String>? gymId,
    Value<String>? equipmentId,
    Value<String?>? canonicalExerciseKey,
    Value<String?>? customExerciseId,
    Value<String>? displayName,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalPlanItemsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      gymId: gymId ?? this.gymId,
      equipmentId: equipmentId ?? this.equipmentId,
      canonicalExerciseKey: canonicalExerciseKey ?? this.canonicalExerciseKey,
      customExerciseId: customExerciseId ?? this.customExerciseId,
      displayName: displayName ?? this.displayName,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (gymId.present) {
      map['gym_id'] = Variable<String>(gymId.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (canonicalExerciseKey.present) {
      map['canonical_exercise_key'] = Variable<String>(
        canonicalExerciseKey.value,
      );
    }
    if (customExerciseId.present) {
      map['custom_exercise_id'] = Variable<String>(customExerciseId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlanItemsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('gymId: $gymId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('canonicalExerciseKey: $canonicalExerciseKey, ')
          ..write('customExerciseId: $customExerciseId, ')
          ..write('displayName: $displayName, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalGymEquipmentTable localGymEquipment =
      $LocalGymEquipmentTable(this);
  late final $LocalExerciseTemplatesTable localExerciseTemplates =
      $LocalExerciseTemplatesTable(this);
  late final $LocalUserCustomExercisesTable localUserCustomExercises =
      $LocalUserCustomExercisesTable(this);
  late final $LocalWorkoutSessionsTable localWorkoutSessions =
      $LocalWorkoutSessionsTable(this);
  late final $LocalSessionExercisesTable localSessionExercises =
      $LocalSessionExercisesTable(this);
  late final $LocalSetEntriesTable localSetEntries = $LocalSetEntriesTable(
    this,
  );
  late final $LocalEquipmentFavouritesTable localEquipmentFavourites =
      $LocalEquipmentFavouritesTable(this);
  late final $LocalWorkoutPlansTable localWorkoutPlans =
      $LocalWorkoutPlansTable(this);
  late final $LocalPlanItemsTable localPlanItems = $LocalPlanItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localGymEquipment,
    localExerciseTemplates,
    localUserCustomExercises,
    localWorkoutSessions,
    localSessionExercises,
    localSetEntries,
    localEquipmentFavourites,
    localWorkoutPlans,
    localPlanItems,
  ];
}

typedef $$LocalGymEquipmentTableCreateCompanionBuilder =
    LocalGymEquipmentCompanion Function({
      required String id,
      required String gymId,
      required String name,
      required String equipmentType,
      required String zoneName,
      Value<String?> nfcTagUid,
      Value<String?> canonicalExerciseKey,
      Value<bool?> rankingEligibleOverride,
      Value<String?> manufacturer,
      Value<bool> isActive,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$LocalGymEquipmentTableUpdateCompanionBuilder =
    LocalGymEquipmentCompanion Function({
      Value<String> id,
      Value<String> gymId,
      Value<String> name,
      Value<String> equipmentType,
      Value<String> zoneName,
      Value<String?> nfcTagUid,
      Value<String?> canonicalExerciseKey,
      Value<bool?> rankingEligibleOverride,
      Value<String?> manufacturer,
      Value<bool> isActive,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$LocalGymEquipmentTableFilterComposer
    extends Composer<_$AppDatabase, $LocalGymEquipmentTable> {
  $$LocalGymEquipmentTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentType => $composableBuilder(
    column: $table.equipmentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneName => $composableBuilder(
    column: $table.zoneName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nfcTagUid => $composableBuilder(
    column: $table.nfcTagUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalExerciseKey => $composableBuilder(
    column: $table.canonicalExerciseKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rankingEligibleOverride => $composableBuilder(
    column: $table.rankingEligibleOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalGymEquipmentTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalGymEquipmentTable> {
  $$LocalGymEquipmentTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentType => $composableBuilder(
    column: $table.equipmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneName => $composableBuilder(
    column: $table.zoneName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nfcTagUid => $composableBuilder(
    column: $table.nfcTagUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalExerciseKey => $composableBuilder(
    column: $table.canonicalExerciseKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rankingEligibleOverride => $composableBuilder(
    column: $table.rankingEligibleOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalGymEquipmentTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalGymEquipmentTable> {
  $$LocalGymEquipmentTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gymId =>
      $composableBuilder(column: $table.gymId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get equipmentType => $composableBuilder(
    column: $table.equipmentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zoneName =>
      $composableBuilder(column: $table.zoneName, builder: (column) => column);

  GeneratedColumn<String> get nfcTagUid =>
      $composableBuilder(column: $table.nfcTagUid, builder: (column) => column);

  GeneratedColumn<String> get canonicalExerciseKey => $composableBuilder(
    column: $table.canonicalExerciseKey,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get rankingEligibleOverride => $composableBuilder(
    column: $table.rankingEligibleOverride,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LocalGymEquipmentTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalGymEquipmentTable,
          LocalGymEquipmentData,
          $$LocalGymEquipmentTableFilterComposer,
          $$LocalGymEquipmentTableOrderingComposer,
          $$LocalGymEquipmentTableAnnotationComposer,
          $$LocalGymEquipmentTableCreateCompanionBuilder,
          $$LocalGymEquipmentTableUpdateCompanionBuilder,
          (
            LocalGymEquipmentData,
            BaseReferences<
              _$AppDatabase,
              $LocalGymEquipmentTable,
              LocalGymEquipmentData
            >,
          ),
          LocalGymEquipmentData,
          PrefetchHooks Function()
        > {
  $$LocalGymEquipmentTableTableManager(
    _$AppDatabase db,
    $LocalGymEquipmentTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalGymEquipmentTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalGymEquipmentTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalGymEquipmentTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> gymId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> equipmentType = const Value.absent(),
                Value<String> zoneName = const Value.absent(),
                Value<String?> nfcTagUid = const Value.absent(),
                Value<String?> canonicalExerciseKey = const Value.absent(),
                Value<bool?> rankingEligibleOverride = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalGymEquipmentCompanion(
                id: id,
                gymId: gymId,
                name: name,
                equipmentType: equipmentType,
                zoneName: zoneName,
                nfcTagUid: nfcTagUid,
                canonicalExerciseKey: canonicalExerciseKey,
                rankingEligibleOverride: rankingEligibleOverride,
                manufacturer: manufacturer,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String gymId,
                required String name,
                required String equipmentType,
                required String zoneName,
                Value<String?> nfcTagUid = const Value.absent(),
                Value<String?> canonicalExerciseKey = const Value.absent(),
                Value<bool?> rankingEligibleOverride = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalGymEquipmentCompanion.insert(
                id: id,
                gymId: gymId,
                name: name,
                equipmentType: equipmentType,
                zoneName: zoneName,
                nfcTagUid: nfcTagUid,
                canonicalExerciseKey: canonicalExerciseKey,
                rankingEligibleOverride: rankingEligibleOverride,
                manufacturer: manufacturer,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalGymEquipmentTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalGymEquipmentTable,
      LocalGymEquipmentData,
      $$LocalGymEquipmentTableFilterComposer,
      $$LocalGymEquipmentTableOrderingComposer,
      $$LocalGymEquipmentTableAnnotationComposer,
      $$LocalGymEquipmentTableCreateCompanionBuilder,
      $$LocalGymEquipmentTableUpdateCompanionBuilder,
      (
        LocalGymEquipmentData,
        BaseReferences<
          _$AppDatabase,
          $LocalGymEquipmentTable,
          LocalGymEquipmentData
        >,
      ),
      LocalGymEquipmentData,
      PrefetchHooks Function()
    >;
typedef $$LocalExerciseTemplatesTableCreateCompanionBuilder =
    LocalExerciseTemplatesCompanion Function({
      required String key,
      required String gymId,
      required String name,
      Value<bool> isRankingEligible,
      Value<String?> primaryMuscleGroup,
      Value<String> muscleGroupWeightsJson,
      Value<bool> isActive,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$LocalExerciseTemplatesTableUpdateCompanionBuilder =
    LocalExerciseTemplatesCompanion Function({
      Value<String> key,
      Value<String> gymId,
      Value<String> name,
      Value<bool> isRankingEligible,
      Value<String?> primaryMuscleGroup,
      Value<String> muscleGroupWeightsJson,
      Value<bool> isActive,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$LocalExerciseTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalExerciseTemplatesTable> {
  $$LocalExerciseTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRankingEligible => $composableBuilder(
    column: $table.isRankingEligible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryMuscleGroup => $composableBuilder(
    column: $table.primaryMuscleGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muscleGroupWeightsJson => $composableBuilder(
    column: $table.muscleGroupWeightsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalExerciseTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalExerciseTemplatesTable> {
  $$LocalExerciseTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRankingEligible => $composableBuilder(
    column: $table.isRankingEligible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryMuscleGroup => $composableBuilder(
    column: $table.primaryMuscleGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleGroupWeightsJson => $composableBuilder(
    column: $table.muscleGroupWeightsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalExerciseTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalExerciseTemplatesTable> {
  $$LocalExerciseTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get gymId =>
      $composableBuilder(column: $table.gymId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isRankingEligible => $composableBuilder(
    column: $table.isRankingEligible,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryMuscleGroup => $composableBuilder(
    column: $table.primaryMuscleGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get muscleGroupWeightsJson => $composableBuilder(
    column: $table.muscleGroupWeightsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LocalExerciseTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalExerciseTemplatesTable,
          LocalExerciseTemplate,
          $$LocalExerciseTemplatesTableFilterComposer,
          $$LocalExerciseTemplatesTableOrderingComposer,
          $$LocalExerciseTemplatesTableAnnotationComposer,
          $$LocalExerciseTemplatesTableCreateCompanionBuilder,
          $$LocalExerciseTemplatesTableUpdateCompanionBuilder,
          (
            LocalExerciseTemplate,
            BaseReferences<
              _$AppDatabase,
              $LocalExerciseTemplatesTable,
              LocalExerciseTemplate
            >,
          ),
          LocalExerciseTemplate,
          PrefetchHooks Function()
        > {
  $$LocalExerciseTemplatesTableTableManager(
    _$AppDatabase db,
    $LocalExerciseTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalExerciseTemplatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalExerciseTemplatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalExerciseTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> gymId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isRankingEligible = const Value.absent(),
                Value<String?> primaryMuscleGroup = const Value.absent(),
                Value<String> muscleGroupWeightsJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalExerciseTemplatesCompanion(
                key: key,
                gymId: gymId,
                name: name,
                isRankingEligible: isRankingEligible,
                primaryMuscleGroup: primaryMuscleGroup,
                muscleGroupWeightsJson: muscleGroupWeightsJson,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String gymId,
                required String name,
                Value<bool> isRankingEligible = const Value.absent(),
                Value<String?> primaryMuscleGroup = const Value.absent(),
                Value<String> muscleGroupWeightsJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalExerciseTemplatesCompanion.insert(
                key: key,
                gymId: gymId,
                name: name,
                isRankingEligible: isRankingEligible,
                primaryMuscleGroup: primaryMuscleGroup,
                muscleGroupWeightsJson: muscleGroupWeightsJson,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalExerciseTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalExerciseTemplatesTable,
      LocalExerciseTemplate,
      $$LocalExerciseTemplatesTableFilterComposer,
      $$LocalExerciseTemplatesTableOrderingComposer,
      $$LocalExerciseTemplatesTableAnnotationComposer,
      $$LocalExerciseTemplatesTableCreateCompanionBuilder,
      $$LocalExerciseTemplatesTableUpdateCompanionBuilder,
      (
        LocalExerciseTemplate,
        BaseReferences<
          _$AppDatabase,
          $LocalExerciseTemplatesTable,
          LocalExerciseTemplate
        >,
      ),
      LocalExerciseTemplate,
      PrefetchHooks Function()
    >;
typedef $$LocalUserCustomExercisesTableCreateCompanionBuilder =
    LocalUserCustomExercisesCompanion Function({
      required String id,
      required String gymId,
      required String userId,
      required String name,
      Value<String?> equipmentId,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$LocalUserCustomExercisesTableUpdateCompanionBuilder =
    LocalUserCustomExercisesCompanion Function({
      Value<String> id,
      Value<String> gymId,
      Value<String> userId,
      Value<String> name,
      Value<String?> equipmentId,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalUserCustomExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalUserCustomExercisesTable> {
  $$LocalUserCustomExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalUserCustomExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalUserCustomExercisesTable> {
  $$LocalUserCustomExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalUserCustomExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalUserCustomExercisesTable> {
  $$LocalUserCustomExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gymId =>
      $composableBuilder(column: $table.gymId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalUserCustomExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalUserCustomExercisesTable,
          LocalUserCustomExercise,
          $$LocalUserCustomExercisesTableFilterComposer,
          $$LocalUserCustomExercisesTableOrderingComposer,
          $$LocalUserCustomExercisesTableAnnotationComposer,
          $$LocalUserCustomExercisesTableCreateCompanionBuilder,
          $$LocalUserCustomExercisesTableUpdateCompanionBuilder,
          (
            LocalUserCustomExercise,
            BaseReferences<
              _$AppDatabase,
              $LocalUserCustomExercisesTable,
              LocalUserCustomExercise
            >,
          ),
          LocalUserCustomExercise,
          PrefetchHooks Function()
        > {
  $$LocalUserCustomExercisesTableTableManager(
    _$AppDatabase db,
    $LocalUserCustomExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUserCustomExercisesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalUserCustomExercisesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalUserCustomExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> gymId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> equipmentId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUserCustomExercisesCompanion(
                id: id,
                gymId: gymId,
                userId: userId,
                name: name,
                equipmentId: equipmentId,
                syncStatus: syncStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String gymId,
                required String userId,
                required String name,
                Value<String?> equipmentId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUserCustomExercisesCompanion.insert(
                id: id,
                gymId: gymId,
                userId: userId,
                name: name,
                equipmentId: equipmentId,
                syncStatus: syncStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalUserCustomExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalUserCustomExercisesTable,
      LocalUserCustomExercise,
      $$LocalUserCustomExercisesTableFilterComposer,
      $$LocalUserCustomExercisesTableOrderingComposer,
      $$LocalUserCustomExercisesTableAnnotationComposer,
      $$LocalUserCustomExercisesTableCreateCompanionBuilder,
      $$LocalUserCustomExercisesTableUpdateCompanionBuilder,
      (
        LocalUserCustomExercise,
        BaseReferences<
          _$AppDatabase,
          $LocalUserCustomExercisesTable,
          LocalUserCustomExercise
        >,
      ),
      LocalUserCustomExercise,
      PrefetchHooks Function()
    >;
typedef $$LocalWorkoutSessionsTableCreateCompanionBuilder =
    LocalWorkoutSessionsCompanion Function({
      required String id,
      required String gymId,
      required String userId,
      required String equipmentId,
      required String sessionDayAnchor,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<String> syncStatus,
      required String idempotencyKey,
      Value<String?> notes,
      Value<String?> serverSyncedId,
      Value<int> rowid,
    });
typedef $$LocalWorkoutSessionsTableUpdateCompanionBuilder =
    LocalWorkoutSessionsCompanion Function({
      Value<String> id,
      Value<String> gymId,
      Value<String> userId,
      Value<String> equipmentId,
      Value<String> sessionDayAnchor,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<String> syncStatus,
      Value<String> idempotencyKey,
      Value<String?> notes,
      Value<String?> serverSyncedId,
      Value<int> rowid,
    });

class $$LocalWorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalWorkoutSessionsTable> {
  $$LocalWorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionDayAnchor => $composableBuilder(
    column: $table.sessionDayAnchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverSyncedId => $composableBuilder(
    column: $table.serverSyncedId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalWorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalWorkoutSessionsTable> {
  $$LocalWorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionDayAnchor => $composableBuilder(
    column: $table.sessionDayAnchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverSyncedId => $composableBuilder(
    column: $table.serverSyncedId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalWorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalWorkoutSessionsTable> {
  $$LocalWorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gymId =>
      $composableBuilder(column: $table.gymId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionDayAnchor => $composableBuilder(
    column: $table.sessionDayAnchor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get serverSyncedId => $composableBuilder(
    column: $table.serverSyncedId,
    builder: (column) => column,
  );
}

class $$LocalWorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalWorkoutSessionsTable,
          LocalWorkoutSession,
          $$LocalWorkoutSessionsTableFilterComposer,
          $$LocalWorkoutSessionsTableOrderingComposer,
          $$LocalWorkoutSessionsTableAnnotationComposer,
          $$LocalWorkoutSessionsTableCreateCompanionBuilder,
          $$LocalWorkoutSessionsTableUpdateCompanionBuilder,
          (
            LocalWorkoutSession,
            BaseReferences<
              _$AppDatabase,
              $LocalWorkoutSessionsTable,
              LocalWorkoutSession
            >,
          ),
          LocalWorkoutSession,
          PrefetchHooks Function()
        > {
  $$LocalWorkoutSessionsTableTableManager(
    _$AppDatabase db,
    $LocalWorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalWorkoutSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalWorkoutSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> gymId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> equipmentId = const Value.absent(),
                Value<String> sessionDayAnchor = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> serverSyncedId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutSessionsCompanion(
                id: id,
                gymId: gymId,
                userId: userId,
                equipmentId: equipmentId,
                sessionDayAnchor: sessionDayAnchor,
                startedAt: startedAt,
                finishedAt: finishedAt,
                syncStatus: syncStatus,
                idempotencyKey: idempotencyKey,
                notes: notes,
                serverSyncedId: serverSyncedId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String gymId,
                required String userId,
                required String equipmentId,
                required String sessionDayAnchor,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required String idempotencyKey,
                Value<String?> notes = const Value.absent(),
                Value<String?> serverSyncedId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutSessionsCompanion.insert(
                id: id,
                gymId: gymId,
                userId: userId,
                equipmentId: equipmentId,
                sessionDayAnchor: sessionDayAnchor,
                startedAt: startedAt,
                finishedAt: finishedAt,
                syncStatus: syncStatus,
                idempotencyKey: idempotencyKey,
                notes: notes,
                serverSyncedId: serverSyncedId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalWorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalWorkoutSessionsTable,
      LocalWorkoutSession,
      $$LocalWorkoutSessionsTableFilterComposer,
      $$LocalWorkoutSessionsTableOrderingComposer,
      $$LocalWorkoutSessionsTableAnnotationComposer,
      $$LocalWorkoutSessionsTableCreateCompanionBuilder,
      $$LocalWorkoutSessionsTableUpdateCompanionBuilder,
      (
        LocalWorkoutSession,
        BaseReferences<
          _$AppDatabase,
          $LocalWorkoutSessionsTable,
          LocalWorkoutSession
        >,
      ),
      LocalWorkoutSession,
      PrefetchHooks Function()
    >;
typedef $$LocalSessionExercisesTableCreateCompanionBuilder =
    LocalSessionExercisesCompanion Function({
      required String id,
      required String sessionId,
      required String gymId,
      required String exerciseKey,
      required String displayName,
      Value<int> sortOrder,
      Value<String?> customExerciseId,
      Value<String?> equipmentId,
      Value<String?> notes,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$LocalSessionExercisesTableUpdateCompanionBuilder =
    LocalSessionExercisesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> gymId,
      Value<String> exerciseKey,
      Value<String> displayName,
      Value<int> sortOrder,
      Value<String?> customExerciseId,
      Value<String?> equipmentId,
      Value<String?> notes,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalSessionExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSessionExercisesTable> {
  $$LocalSessionExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseKey => $composableBuilder(
    column: $table.exerciseKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customExerciseId => $composableBuilder(
    column: $table.customExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSessionExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSessionExercisesTable> {
  $$LocalSessionExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseKey => $composableBuilder(
    column: $table.exerciseKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customExerciseId => $composableBuilder(
    column: $table.customExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSessionExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSessionExercisesTable> {
  $$LocalSessionExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get gymId =>
      $composableBuilder(column: $table.gymId, builder: (column) => column);

  GeneratedColumn<String> get exerciseKey => $composableBuilder(
    column: $table.exerciseKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get customExerciseId => $composableBuilder(
    column: $table.customExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalSessionExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSessionExercisesTable,
          LocalSessionExercise,
          $$LocalSessionExercisesTableFilterComposer,
          $$LocalSessionExercisesTableOrderingComposer,
          $$LocalSessionExercisesTableAnnotationComposer,
          $$LocalSessionExercisesTableCreateCompanionBuilder,
          $$LocalSessionExercisesTableUpdateCompanionBuilder,
          (
            LocalSessionExercise,
            BaseReferences<
              _$AppDatabase,
              $LocalSessionExercisesTable,
              LocalSessionExercise
            >,
          ),
          LocalSessionExercise,
          PrefetchHooks Function()
        > {
  $$LocalSessionExercisesTableTableManager(
    _$AppDatabase db,
    $LocalSessionExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSessionExercisesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalSessionExercisesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalSessionExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> gymId = const Value.absent(),
                Value<String> exerciseKey = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> customExerciseId = const Value.absent(),
                Value<String?> equipmentId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSessionExercisesCompanion(
                id: id,
                sessionId: sessionId,
                gymId: gymId,
                exerciseKey: exerciseKey,
                displayName: displayName,
                sortOrder: sortOrder,
                customExerciseId: customExerciseId,
                equipmentId: equipmentId,
                notes: notes,
                syncStatus: syncStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String gymId,
                required String exerciseKey,
                required String displayName,
                Value<int> sortOrder = const Value.absent(),
                Value<String?> customExerciseId = const Value.absent(),
                Value<String?> equipmentId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSessionExercisesCompanion.insert(
                id: id,
                sessionId: sessionId,
                gymId: gymId,
                exerciseKey: exerciseKey,
                displayName: displayName,
                sortOrder: sortOrder,
                customExerciseId: customExerciseId,
                equipmentId: equipmentId,
                notes: notes,
                syncStatus: syncStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSessionExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSessionExercisesTable,
      LocalSessionExercise,
      $$LocalSessionExercisesTableFilterComposer,
      $$LocalSessionExercisesTableOrderingComposer,
      $$LocalSessionExercisesTableAnnotationComposer,
      $$LocalSessionExercisesTableCreateCompanionBuilder,
      $$LocalSessionExercisesTableUpdateCompanionBuilder,
      (
        LocalSessionExercise,
        BaseReferences<
          _$AppDatabase,
          $LocalSessionExercisesTable,
          LocalSessionExercise
        >,
      ),
      LocalSessionExercise,
      PrefetchHooks Function()
    >;
typedef $$LocalSetEntriesTableCreateCompanionBuilder =
    LocalSetEntriesCompanion Function({
      required String id,
      required String sessionExerciseId,
      required String gymId,
      required int setNumber,
      Value<int?> reps,
      Value<double?> weightKg,
      Value<int?> durationSeconds,
      Value<double?> distanceMeters,
      Value<String?> notes,
      Value<String> syncStatus,
      Value<DateTime> loggedAt,
      required String idempotencyKey,
      Value<int> rowid,
    });
typedef $$LocalSetEntriesTableUpdateCompanionBuilder =
    LocalSetEntriesCompanion Function({
      Value<String> id,
      Value<String> sessionExerciseId,
      Value<String> gymId,
      Value<int> setNumber,
      Value<int?> reps,
      Value<double?> weightKg,
      Value<int?> durationSeconds,
      Value<double?> distanceMeters,
      Value<String?> notes,
      Value<String> syncStatus,
      Value<DateTime> loggedAt,
      Value<String> idempotencyKey,
      Value<int> rowid,
    });

class $$LocalSetEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSetEntriesTable> {
  $$LocalSetEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionExerciseId => $composableBuilder(
    column: $table.sessionExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSetEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSetEntriesTable> {
  $$LocalSetEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionExerciseId => $composableBuilder(
    column: $table.sessionExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSetEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSetEntriesTable> {
  $$LocalSetEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionExerciseId => $composableBuilder(
    column: $table.sessionExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gymId =>
      $composableBuilder(column: $table.gymId, builder: (column) => column);

  GeneratedColumn<int> get setNumber =>
      $composableBuilder(column: $table.setNumber, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );
}

class $$LocalSetEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSetEntriesTable,
          LocalSetEntry,
          $$LocalSetEntriesTableFilterComposer,
          $$LocalSetEntriesTableOrderingComposer,
          $$LocalSetEntriesTableAnnotationComposer,
          $$LocalSetEntriesTableCreateCompanionBuilder,
          $$LocalSetEntriesTableUpdateCompanionBuilder,
          (
            LocalSetEntry,
            BaseReferences<_$AppDatabase, $LocalSetEntriesTable, LocalSetEntry>,
          ),
          LocalSetEntry,
          PrefetchHooks Function()
        > {
  $$LocalSetEntriesTableTableManager(
    _$AppDatabase db,
    $LocalSetEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSetEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSetEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSetEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionExerciseId = const Value.absent(),
                Value<String> gymId = const Value.absent(),
                Value<int> setNumber = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSetEntriesCompanion(
                id: id,
                sessionExerciseId: sessionExerciseId,
                gymId: gymId,
                setNumber: setNumber,
                reps: reps,
                weightKg: weightKg,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                notes: notes,
                syncStatus: syncStatus,
                loggedAt: loggedAt,
                idempotencyKey: idempotencyKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionExerciseId,
                required String gymId,
                required int setNumber,
                Value<int?> reps = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                required String idempotencyKey,
                Value<int> rowid = const Value.absent(),
              }) => LocalSetEntriesCompanion.insert(
                id: id,
                sessionExerciseId: sessionExerciseId,
                gymId: gymId,
                setNumber: setNumber,
                reps: reps,
                weightKg: weightKg,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                notes: notes,
                syncStatus: syncStatus,
                loggedAt: loggedAt,
                idempotencyKey: idempotencyKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSetEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSetEntriesTable,
      LocalSetEntry,
      $$LocalSetEntriesTableFilterComposer,
      $$LocalSetEntriesTableOrderingComposer,
      $$LocalSetEntriesTableAnnotationComposer,
      $$LocalSetEntriesTableCreateCompanionBuilder,
      $$LocalSetEntriesTableUpdateCompanionBuilder,
      (
        LocalSetEntry,
        BaseReferences<_$AppDatabase, $LocalSetEntriesTable, LocalSetEntry>,
      ),
      LocalSetEntry,
      PrefetchHooks Function()
    >;
typedef $$LocalEquipmentFavouritesTableCreateCompanionBuilder =
    LocalEquipmentFavouritesCompanion Function({
      required String userId,
      required String gymId,
      required String equipmentId,
      Value<int> rowid,
    });
typedef $$LocalEquipmentFavouritesTableUpdateCompanionBuilder =
    LocalEquipmentFavouritesCompanion Function({
      Value<String> userId,
      Value<String> gymId,
      Value<String> equipmentId,
      Value<int> rowid,
    });

class $$LocalEquipmentFavouritesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalEquipmentFavouritesTable> {
  $$LocalEquipmentFavouritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalEquipmentFavouritesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalEquipmentFavouritesTable> {
  $$LocalEquipmentFavouritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalEquipmentFavouritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalEquipmentFavouritesTable> {
  $$LocalEquipmentFavouritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get gymId =>
      $composableBuilder(column: $table.gymId, builder: (column) => column);

  GeneratedColumn<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => column,
  );
}

class $$LocalEquipmentFavouritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalEquipmentFavouritesTable,
          LocalEquipmentFavourite,
          $$LocalEquipmentFavouritesTableFilterComposer,
          $$LocalEquipmentFavouritesTableOrderingComposer,
          $$LocalEquipmentFavouritesTableAnnotationComposer,
          $$LocalEquipmentFavouritesTableCreateCompanionBuilder,
          $$LocalEquipmentFavouritesTableUpdateCompanionBuilder,
          (
            LocalEquipmentFavourite,
            BaseReferences<
              _$AppDatabase,
              $LocalEquipmentFavouritesTable,
              LocalEquipmentFavourite
            >,
          ),
          LocalEquipmentFavourite,
          PrefetchHooks Function()
        > {
  $$LocalEquipmentFavouritesTableTableManager(
    _$AppDatabase db,
    $LocalEquipmentFavouritesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalEquipmentFavouritesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalEquipmentFavouritesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalEquipmentFavouritesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> gymId = const Value.absent(),
                Value<String> equipmentId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalEquipmentFavouritesCompanion(
                userId: userId,
                gymId: gymId,
                equipmentId: equipmentId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String gymId,
                required String equipmentId,
                Value<int> rowid = const Value.absent(),
              }) => LocalEquipmentFavouritesCompanion.insert(
                userId: userId,
                gymId: gymId,
                equipmentId: equipmentId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalEquipmentFavouritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalEquipmentFavouritesTable,
      LocalEquipmentFavourite,
      $$LocalEquipmentFavouritesTableFilterComposer,
      $$LocalEquipmentFavouritesTableOrderingComposer,
      $$LocalEquipmentFavouritesTableAnnotationComposer,
      $$LocalEquipmentFavouritesTableCreateCompanionBuilder,
      $$LocalEquipmentFavouritesTableUpdateCompanionBuilder,
      (
        LocalEquipmentFavourite,
        BaseReferences<
          _$AppDatabase,
          $LocalEquipmentFavouritesTable,
          LocalEquipmentFavourite
        >,
      ),
      LocalEquipmentFavourite,
      PrefetchHooks Function()
    >;
typedef $$LocalWorkoutPlansTableCreateCompanionBuilder =
    LocalWorkoutPlansCompanion Function({
      required String id,
      required String gymId,
      required String userId,
      required String name,
      Value<bool> isActive,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalWorkoutPlansTableUpdateCompanionBuilder =
    LocalWorkoutPlansCompanion Function({
      Value<String> id,
      Value<String> gymId,
      Value<String> userId,
      Value<String> name,
      Value<bool> isActive,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalWorkoutPlansTableFilterComposer
    extends Composer<_$AppDatabase, $LocalWorkoutPlansTable> {
  $$LocalWorkoutPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalWorkoutPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalWorkoutPlansTable> {
  $$LocalWorkoutPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalWorkoutPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalWorkoutPlansTable> {
  $$LocalWorkoutPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gymId =>
      $composableBuilder(column: $table.gymId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalWorkoutPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalWorkoutPlansTable,
          LocalWorkoutPlan,
          $$LocalWorkoutPlansTableFilterComposer,
          $$LocalWorkoutPlansTableOrderingComposer,
          $$LocalWorkoutPlansTableAnnotationComposer,
          $$LocalWorkoutPlansTableCreateCompanionBuilder,
          $$LocalWorkoutPlansTableUpdateCompanionBuilder,
          (
            LocalWorkoutPlan,
            BaseReferences<
              _$AppDatabase,
              $LocalWorkoutPlansTable,
              LocalWorkoutPlan
            >,
          ),
          LocalWorkoutPlan,
          PrefetchHooks Function()
        > {
  $$LocalWorkoutPlansTableTableManager(
    _$AppDatabase db,
    $LocalWorkoutPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWorkoutPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalWorkoutPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalWorkoutPlansTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> gymId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutPlansCompanion(
                id: id,
                gymId: gymId,
                userId: userId,
                name: name,
                isActive: isActive,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String gymId,
                required String userId,
                required String name,
                Value<bool> isActive = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutPlansCompanion.insert(
                id: id,
                gymId: gymId,
                userId: userId,
                name: name,
                isActive: isActive,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalWorkoutPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalWorkoutPlansTable,
      LocalWorkoutPlan,
      $$LocalWorkoutPlansTableFilterComposer,
      $$LocalWorkoutPlansTableOrderingComposer,
      $$LocalWorkoutPlansTableAnnotationComposer,
      $$LocalWorkoutPlansTableCreateCompanionBuilder,
      $$LocalWorkoutPlansTableUpdateCompanionBuilder,
      (
        LocalWorkoutPlan,
        BaseReferences<
          _$AppDatabase,
          $LocalWorkoutPlansTable,
          LocalWorkoutPlan
        >,
      ),
      LocalWorkoutPlan,
      PrefetchHooks Function()
    >;
typedef $$LocalPlanItemsTableCreateCompanionBuilder =
    LocalPlanItemsCompanion Function({
      required String id,
      required String planId,
      required String gymId,
      required String equipmentId,
      Value<String?> canonicalExerciseKey,
      Value<String?> customExerciseId,
      required String displayName,
      required int position,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$LocalPlanItemsTableUpdateCompanionBuilder =
    LocalPlanItemsCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<String> gymId,
      Value<String> equipmentId,
      Value<String?> canonicalExerciseKey,
      Value<String?> customExerciseId,
      Value<String> displayName,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalPlanItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlanItemsTable> {
  $$LocalPlanItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalExerciseKey => $composableBuilder(
    column: $table.canonicalExerciseKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customExerciseId => $composableBuilder(
    column: $table.customExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPlanItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlanItemsTable> {
  $$LocalPlanItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalExerciseKey => $composableBuilder(
    column: $table.canonicalExerciseKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customExerciseId => $composableBuilder(
    column: $table.customExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPlanItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlanItemsTable> {
  $$LocalPlanItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get gymId =>
      $composableBuilder(column: $table.gymId, builder: (column) => column);

  GeneratedColumn<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalExerciseKey => $composableBuilder(
    column: $table.canonicalExerciseKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customExerciseId => $composableBuilder(
    column: $table.customExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalPlanItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPlanItemsTable,
          LocalPlanItem,
          $$LocalPlanItemsTableFilterComposer,
          $$LocalPlanItemsTableOrderingComposer,
          $$LocalPlanItemsTableAnnotationComposer,
          $$LocalPlanItemsTableCreateCompanionBuilder,
          $$LocalPlanItemsTableUpdateCompanionBuilder,
          (
            LocalPlanItem,
            BaseReferences<_$AppDatabase, $LocalPlanItemsTable, LocalPlanItem>,
          ),
          LocalPlanItem,
          PrefetchHooks Function()
        > {
  $$LocalPlanItemsTableTableManager(
    _$AppDatabase db,
    $LocalPlanItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlanItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlanItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlanItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> gymId = const Value.absent(),
                Value<String> equipmentId = const Value.absent(),
                Value<String?> canonicalExerciseKey = const Value.absent(),
                Value<String?> customExerciseId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPlanItemsCompanion(
                id: id,
                planId: planId,
                gymId: gymId,
                equipmentId: equipmentId,
                canonicalExerciseKey: canonicalExerciseKey,
                customExerciseId: customExerciseId,
                displayName: displayName,
                position: position,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required String gymId,
                required String equipmentId,
                Value<String?> canonicalExerciseKey = const Value.absent(),
                Value<String?> customExerciseId = const Value.absent(),
                required String displayName,
                required int position,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPlanItemsCompanion.insert(
                id: id,
                planId: planId,
                gymId: gymId,
                equipmentId: equipmentId,
                canonicalExerciseKey: canonicalExerciseKey,
                customExerciseId: customExerciseId,
                displayName: displayName,
                position: position,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPlanItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPlanItemsTable,
      LocalPlanItem,
      $$LocalPlanItemsTableFilterComposer,
      $$LocalPlanItemsTableOrderingComposer,
      $$LocalPlanItemsTableAnnotationComposer,
      $$LocalPlanItemsTableCreateCompanionBuilder,
      $$LocalPlanItemsTableUpdateCompanionBuilder,
      (
        LocalPlanItem,
        BaseReferences<_$AppDatabase, $LocalPlanItemsTable, LocalPlanItem>,
      ),
      LocalPlanItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalGymEquipmentTableTableManager get localGymEquipment =>
      $$LocalGymEquipmentTableTableManager(_db, _db.localGymEquipment);
  $$LocalExerciseTemplatesTableTableManager get localExerciseTemplates =>
      $$LocalExerciseTemplatesTableTableManager(
        _db,
        _db.localExerciseTemplates,
      );
  $$LocalUserCustomExercisesTableTableManager get localUserCustomExercises =>
      $$LocalUserCustomExercisesTableTableManager(
        _db,
        _db.localUserCustomExercises,
      );
  $$LocalWorkoutSessionsTableTableManager get localWorkoutSessions =>
      $$LocalWorkoutSessionsTableTableManager(_db, _db.localWorkoutSessions);
  $$LocalSessionExercisesTableTableManager get localSessionExercises =>
      $$LocalSessionExercisesTableTableManager(_db, _db.localSessionExercises);
  $$LocalSetEntriesTableTableManager get localSetEntries =>
      $$LocalSetEntriesTableTableManager(_db, _db.localSetEntries);
  $$LocalEquipmentFavouritesTableTableManager get localEquipmentFavourites =>
      $$LocalEquipmentFavouritesTableTableManager(
        _db,
        _db.localEquipmentFavourites,
      );
  $$LocalWorkoutPlansTableTableManager get localWorkoutPlans =>
      $$LocalWorkoutPlansTableTableManager(_db, _db.localWorkoutPlans);
  $$LocalPlanItemsTableTableManager get localPlanItems =>
      $$LocalPlanItemsTableTableManager(_db, _db.localPlanItems);
}
