// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_database.dart';

// ignore_for_file: type=lint
class $LocationPointsTable extends LocationPoints
    with TableInfo<$LocationPointsTable, LocationPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
    'heading',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityTypeMeta = const VerificationMeta(
    'activityType',
  );
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
    'activity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSignificantMeta = const VerificationMeta(
    'isSignificant',
  );
  @override
  late final GeneratedColumn<bool> isSignificant = GeneratedColumn<bool>(
    'is_significant',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_significant" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    latitude,
    longitude,
    accuracy,
    altitude,
    speed,
    heading,
    timestamp,
    activityType,
    isSignificant,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('activity_type')) {
      context.handle(
        _activityTypeMeta,
        activityType.isAcceptableOrUnknown(
          data['activity_type']!,
          _activityTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_significant')) {
      context.handle(
        _isSignificantMeta,
        isSignificant.isAcceptableOrUnknown(
          data['is_significant']!,
          _isSignificantMeta,
        ),
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
  LocationPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      ),
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      ),
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      activityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_type'],
      ),
      isSignificant: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_significant'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocationPointsTable createAlias(String alias) {
    return $LocationPointsTable(attachedDatabase, alias);
  }
}

class LocationPoint extends DataClass implements Insertable<LocationPoint> {
  final int id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final String? activityType;
  final bool isSignificant;
  final DateTime createdAt;
  const LocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
    this.activityType,
    required this.isSignificant,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<double>(heading);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || activityType != null) {
      map['activity_type'] = Variable<String>(activityType);
    }
    map['is_significant'] = Variable<bool>(isSignificant);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocationPointsCompanion toCompanion(bool nullToAbsent) {
    return LocationPointsCompanion(
      id: Value(id),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      speed: speed == null && nullToAbsent
          ? const Value.absent()
          : Value(speed),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
      timestamp: Value(timestamp),
      activityType: activityType == null && nullToAbsent
          ? const Value.absent()
          : Value(activityType),
      isSignificant: Value(isSignificant),
      createdAt: Value(createdAt),
    );
  }

  factory LocationPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationPoint(
      id: serializer.fromJson<int>(json['id']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      speed: serializer.fromJson<double?>(json['speed']),
      heading: serializer.fromJson<double?>(json['heading']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      activityType: serializer.fromJson<String?>(json['activityType']),
      isSignificant: serializer.fromJson<bool>(json['isSignificant']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracy': serializer.toJson<double?>(accuracy),
      'altitude': serializer.toJson<double?>(altitude),
      'speed': serializer.toJson<double?>(speed),
      'heading': serializer.toJson<double?>(heading),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'activityType': serializer.toJson<String?>(activityType),
      'isSignificant': serializer.toJson<bool>(isSignificant),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocationPoint copyWith({
    int? id,
    double? latitude,
    double? longitude,
    Value<double?> accuracy = const Value.absent(),
    Value<double?> altitude = const Value.absent(),
    Value<double?> speed = const Value.absent(),
    Value<double?> heading = const Value.absent(),
    DateTime? timestamp,
    Value<String?> activityType = const Value.absent(),
    bool? isSignificant,
    DateTime? createdAt,
  }) => LocationPoint(
    id: id ?? this.id,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    altitude: altitude.present ? altitude.value : this.altitude,
    speed: speed.present ? speed.value : this.speed,
    heading: heading.present ? heading.value : this.heading,
    timestamp: timestamp ?? this.timestamp,
    activityType: activityType.present ? activityType.value : this.activityType,
    isSignificant: isSignificant ?? this.isSignificant,
    createdAt: createdAt ?? this.createdAt,
  );
  LocationPoint copyWithCompanion(LocationPointsCompanion data) {
    return LocationPoint(
      id: data.id.present ? data.id.value : this.id,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      speed: data.speed.present ? data.speed.value : this.speed,
      heading: data.heading.present ? data.heading.value : this.heading,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      isSignificant: data.isSignificant.present
          ? data.isSignificant.value
          : this.isSignificant,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationPoint(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('altitude: $altitude, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('timestamp: $timestamp, ')
          ..write('activityType: $activityType, ')
          ..write('isSignificant: $isSignificant, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    latitude,
    longitude,
    accuracy,
    altitude,
    speed,
    heading,
    timestamp,
    activityType,
    isSignificant,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationPoint &&
          other.id == this.id &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracy == this.accuracy &&
          other.altitude == this.altitude &&
          other.speed == this.speed &&
          other.heading == this.heading &&
          other.timestamp == this.timestamp &&
          other.activityType == this.activityType &&
          other.isSignificant == this.isSignificant &&
          other.createdAt == this.createdAt);
}

class LocationPointsCompanion extends UpdateCompanion<LocationPoint> {
  final Value<int> id;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> accuracy;
  final Value<double?> altitude;
  final Value<double?> speed;
  final Value<double?> heading;
  final Value<DateTime> timestamp;
  final Value<String?> activityType;
  final Value<bool> isSignificant;
  final Value<DateTime> createdAt;
  const LocationPointsCompanion({
    this.id = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.altitude = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.activityType = const Value.absent(),
    this.isSignificant = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocationPointsCompanion.insert({
    this.id = const Value.absent(),
    required double latitude,
    required double longitude,
    this.accuracy = const Value.absent(),
    this.altitude = const Value.absent(),
    this.speed = const Value.absent(),
    this.heading = const Value.absent(),
    required DateTime timestamp,
    this.activityType = const Value.absent(),
    this.isSignificant = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : latitude = Value(latitude),
       longitude = Value(longitude),
       timestamp = Value(timestamp);
  static Insertable<LocationPoint> custom({
    Expression<int>? id,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracy,
    Expression<double>? altitude,
    Expression<double>? speed,
    Expression<double>? heading,
    Expression<DateTime>? timestamp,
    Expression<String>? activityType,
    Expression<bool>? isSignificant,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (timestamp != null) 'timestamp': timestamp,
      if (activityType != null) 'activity_type': activityType,
      if (isSignificant != null) 'is_significant': isSignificant,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocationPointsCompanion copyWith({
    Value<int>? id,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? accuracy,
    Value<double?>? altitude,
    Value<double?>? speed,
    Value<double?>? heading,
    Value<DateTime>? timestamp,
    Value<String?>? activityType,
    Value<bool>? isSignificant,
    Value<DateTime>? createdAt,
  }) {
    return LocationPointsCompanion(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      activityType: activityType ?? this.activityType,
      isSignificant: isSignificant ?? this.isSignificant,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (isSignificant.present) {
      map['is_significant'] = Variable<bool>(isSignificant.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationPointsCompanion(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('altitude: $altitude, ')
          ..write('speed: $speed, ')
          ..write('heading: $heading, ')
          ..write('timestamp: $timestamp, ')
          ..write('activityType: $activityType, ')
          ..write('isSignificant: $isSignificant, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GeofenceAreasTable extends GeofenceAreas
    with TableInfo<$GeofenceAreasTable, GeofenceArea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeofenceAreasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusMeta = const VerificationMeta('radius');
  @override
  late final GeneratedColumn<double> radius = GeneratedColumn<double>(
    'radius',
    aliasedName,
    false,
    type: DriftSqlType.double,
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
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    latitude,
    longitude,
    radius,
    isActive,
    metadata,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'geofence_areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<GeofenceArea> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('radius')) {
      context.handle(
        _radiusMeta,
        radius.isAcceptableOrUnknown(data['radius']!, _radiusMeta),
      );
    } else if (isInserting) {
      context.missing(_radiusMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
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
  GeofenceArea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeofenceArea(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      radius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $GeofenceAreasTable createAlias(String alias) {
    return $GeofenceAreasTable(attachedDatabase, alias);
  }
}

class GeofenceArea extends DataClass implements Insertable<GeofenceArea> {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final bool isActive;
  final String? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const GeofenceArea({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.isActive,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['radius'] = Variable<double>(radius);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  GeofenceAreasCompanion toCompanion(bool nullToAbsent) {
    return GeofenceAreasCompanion(
      id: Value(id),
      name: Value(name),
      latitude: Value(latitude),
      longitude: Value(longitude),
      radius: Value(radius),
      isActive: Value(isActive),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory GeofenceArea.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeofenceArea(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      radius: serializer.fromJson<double>(json['radius']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'radius': serializer.toJson<double>(radius),
      'isActive': serializer.toJson<bool>(isActive),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  GeofenceArea copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isActive,
    Value<String?> metadata = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => GeofenceArea(
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radius: radius ?? this.radius,
    isActive: isActive ?? this.isActive,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  GeofenceArea copyWithCompanion(GeofenceAreasCompanion data) {
    return GeofenceArea(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      radius: data.radius.present ? data.radius.value : this.radius,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeofenceArea(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radius: $radius, ')
          ..write('isActive: $isActive, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    latitude,
    longitude,
    radius,
    isActive,
    metadata,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeofenceArea &&
          other.id == this.id &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.radius == this.radius &&
          other.isActive == this.isActive &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GeofenceAreasCompanion extends UpdateCompanion<GeofenceArea> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> radius;
  final Value<bool> isActive;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const GeofenceAreasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radius = const Value.absent(),
    this.isActive = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeofenceAreasCompanion.insert({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    this.isActive = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       latitude = Value(latitude),
       longitude = Value(longitude),
       radius = Value(radius);
  static Insertable<GeofenceArea> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? radius,
    Expression<bool>? isActive,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radius != null) 'radius': radius,
      if (isActive != null) 'is_active': isActive,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeofenceAreasCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? radius,
    Value<bool>? isActive,
    Value<String?>? metadata,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return GeofenceAreasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (radius.present) {
      map['radius'] = Variable<double>(radius.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
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
    return (StringBuffer('GeofenceAreasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radius: $radius, ')
          ..write('isActive: $isActive, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GeofenceEventsTable extends GeofenceEvents
    with TableInfo<$GeofenceEventsTable, GeofenceEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeofenceEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _geofenceIdMeta = const VerificationMeta(
    'geofenceId',
  );
  @override
  late final GeneratedColumn<String> geofenceId = GeneratedColumn<String>(
    'geofence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES geofence_areas (id)',
    ),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dwellTimeMeta = const VerificationMeta(
    'dwellTime',
  );
  @override
  late final GeneratedColumn<int> dwellTime = GeneratedColumn<int>(
    'dwell_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    geofenceId,
    eventType,
    timestamp,
    latitude,
    longitude,
    dwellTime,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'geofence_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<GeofenceEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('geofence_id')) {
      context.handle(
        _geofenceIdMeta,
        geofenceId.isAcceptableOrUnknown(data['geofence_id']!, _geofenceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_geofenceIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('dwell_time')) {
      context.handle(
        _dwellTimeMeta,
        dwellTime.isAcceptableOrUnknown(data['dwell_time']!, _dwellTimeMeta),
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
  GeofenceEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeofenceEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      geofenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geofence_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      dwellTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dwell_time'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GeofenceEventsTable createAlias(String alias) {
    return $GeofenceEventsTable(attachedDatabase, alias);
  }
}

class GeofenceEvent extends DataClass implements Insertable<GeofenceEvent> {
  final int id;
  final String geofenceId;
  final String eventType;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final int? dwellTime;
  final DateTime createdAt;
  const GeofenceEvent({
    required this.id,
    required this.geofenceId,
    required this.eventType,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.dwellTime,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['geofence_id'] = Variable<String>(geofenceId);
    map['event_type'] = Variable<String>(eventType);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || dwellTime != null) {
      map['dwell_time'] = Variable<int>(dwellTime);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GeofenceEventsCompanion toCompanion(bool nullToAbsent) {
    return GeofenceEventsCompanion(
      id: Value(id),
      geofenceId: Value(geofenceId),
      eventType: Value(eventType),
      timestamp: Value(timestamp),
      latitude: Value(latitude),
      longitude: Value(longitude),
      dwellTime: dwellTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dwellTime),
      createdAt: Value(createdAt),
    );
  }

  factory GeofenceEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeofenceEvent(
      id: serializer.fromJson<int>(json['id']),
      geofenceId: serializer.fromJson<String>(json['geofenceId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      dwellTime: serializer.fromJson<int?>(json['dwellTime']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'geofenceId': serializer.toJson<String>(geofenceId),
      'eventType': serializer.toJson<String>(eventType),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'dwellTime': serializer.toJson<int?>(dwellTime),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GeofenceEvent copyWith({
    int? id,
    String? geofenceId,
    String? eventType,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    Value<int?> dwellTime = const Value.absent(),
    DateTime? createdAt,
  }) => GeofenceEvent(
    id: id ?? this.id,
    geofenceId: geofenceId ?? this.geofenceId,
    eventType: eventType ?? this.eventType,
    timestamp: timestamp ?? this.timestamp,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    dwellTime: dwellTime.present ? dwellTime.value : this.dwellTime,
    createdAt: createdAt ?? this.createdAt,
  );
  GeofenceEvent copyWithCompanion(GeofenceEventsCompanion data) {
    return GeofenceEvent(
      id: data.id.present ? data.id.value : this.id,
      geofenceId: data.geofenceId.present
          ? data.geofenceId.value
          : this.geofenceId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      dwellTime: data.dwellTime.present ? data.dwellTime.value : this.dwellTime,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeofenceEvent(')
          ..write('id: $id, ')
          ..write('geofenceId: $geofenceId, ')
          ..write('eventType: $eventType, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('dwellTime: $dwellTime, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    geofenceId,
    eventType,
    timestamp,
    latitude,
    longitude,
    dwellTime,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeofenceEvent &&
          other.id == this.id &&
          other.geofenceId == this.geofenceId &&
          other.eventType == this.eventType &&
          other.timestamp == this.timestamp &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.dwellTime == this.dwellTime &&
          other.createdAt == this.createdAt);
}

class GeofenceEventsCompanion extends UpdateCompanion<GeofenceEvent> {
  final Value<int> id;
  final Value<String> geofenceId;
  final Value<String> eventType;
  final Value<DateTime> timestamp;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int?> dwellTime;
  final Value<DateTime> createdAt;
  const GeofenceEventsCompanion({
    this.id = const Value.absent(),
    this.geofenceId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.dwellTime = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GeofenceEventsCompanion.insert({
    this.id = const Value.absent(),
    required String geofenceId,
    required String eventType,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    this.dwellTime = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : geofenceId = Value(geofenceId),
       eventType = Value(eventType),
       timestamp = Value(timestamp),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<GeofenceEvent> custom({
    Expression<int>? id,
    Expression<String>? geofenceId,
    Expression<String>? eventType,
    Expression<DateTime>? timestamp,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? dwellTime,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (geofenceId != null) 'geofence_id': geofenceId,
      if (eventType != null) 'event_type': eventType,
      if (timestamp != null) 'timestamp': timestamp,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (dwellTime != null) 'dwell_time': dwellTime,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GeofenceEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? geofenceId,
    Value<String>? eventType,
    Value<DateTime>? timestamp,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<int?>? dwellTime,
    Value<DateTime>? createdAt,
  }) {
    return GeofenceEventsCompanion(
      id: id ?? this.id,
      geofenceId: geofenceId ?? this.geofenceId,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dwellTime: dwellTime ?? this.dwellTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (geofenceId.present) {
      map['geofence_id'] = Variable<String>(geofenceId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (dwellTime.present) {
      map['dwell_time'] = Variable<int>(dwellTime.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeofenceEventsCompanion(')
          ..write('id: $id, ')
          ..write('geofenceId: $geofenceId, ')
          ..write('eventType: $eventType, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('dwellTime: $dwellTime, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocationNotesTable extends LocationNotes
    with TableInfo<$LocationNotesTable, LocationNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placeNameMeta = const VerificationMeta(
    'placeName',
  );
  @override
  late final GeneratedColumn<String> placeName = GeneratedColumn<String>(
    'place_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geofenceIdMeta = const VerificationMeta(
    'geofenceId',
  );
  @override
  late final GeneratedColumn<String> geofenceId = GeneratedColumn<String>(
    'geofence_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES geofence_areas (id)',
    ),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPublishedMeta = const VerificationMeta(
    'isPublished',
  );
  @override
  late final GeneratedColumn<bool> isPublished = GeneratedColumn<bool>(
    'is_published',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_published" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    noteId,
    content,
    latitude,
    longitude,
    placeName,
    geofenceId,
    tags,
    timestamp,
    isPublished,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('place_name')) {
      context.handle(
        _placeNameMeta,
        placeName.isAcceptableOrUnknown(data['place_name']!, _placeNameMeta),
      );
    }
    if (data.containsKey('geofence_id')) {
      context.handle(
        _geofenceIdMeta,
        geofenceId.isAcceptableOrUnknown(data['geofence_id']!, _geofenceIdMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_published')) {
      context.handle(
        _isPublishedMeta,
        isPublished.isAcceptableOrUnknown(
          data['is_published']!,
          _isPublishedMeta,
        ),
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
  LocationNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      placeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_name'],
      ),
      geofenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geofence_id'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      isPublished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_published'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocationNotesTable createAlias(String alias) {
    return $LocationNotesTable(attachedDatabase, alias);
  }
}

class LocationNote extends DataClass implements Insertable<LocationNote> {
  final int id;
  final String? noteId;
  final String content;
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? geofenceId;
  final String? tags;
  final DateTime timestamp;
  final bool isPublished;
  final DateTime createdAt;
  const LocationNote({
    required this.id,
    this.noteId,
    required this.content,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.geofenceId,
    this.tags,
    required this.timestamp,
    required this.isPublished,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    map['content'] = Variable<String>(content);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || placeName != null) {
      map['place_name'] = Variable<String>(placeName);
    }
    if (!nullToAbsent || geofenceId != null) {
      map['geofence_id'] = Variable<String>(geofenceId);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_published'] = Variable<bool>(isPublished);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocationNotesCompanion toCompanion(bool nullToAbsent) {
    return LocationNotesCompanion(
      id: Value(id),
      noteId: noteId == null && nullToAbsent
          ? const Value.absent()
          : Value(noteId),
      content: Value(content),
      latitude: Value(latitude),
      longitude: Value(longitude),
      placeName: placeName == null && nullToAbsent
          ? const Value.absent()
          : Value(placeName),
      geofenceId: geofenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(geofenceId),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      timestamp: Value(timestamp),
      isPublished: Value(isPublished),
      createdAt: Value(createdAt),
    );
  }

  factory LocationNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationNote(
      id: serializer.fromJson<int>(json['id']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      content: serializer.fromJson<String>(json['content']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      placeName: serializer.fromJson<String?>(json['placeName']),
      geofenceId: serializer.fromJson<String?>(json['geofenceId']),
      tags: serializer.fromJson<String?>(json['tags']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isPublished: serializer.fromJson<bool>(json['isPublished']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'noteId': serializer.toJson<String?>(noteId),
      'content': serializer.toJson<String>(content),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'placeName': serializer.toJson<String?>(placeName),
      'geofenceId': serializer.toJson<String?>(geofenceId),
      'tags': serializer.toJson<String?>(tags),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isPublished': serializer.toJson<bool>(isPublished),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocationNote copyWith({
    int? id,
    Value<String?> noteId = const Value.absent(),
    String? content,
    double? latitude,
    double? longitude,
    Value<String?> placeName = const Value.absent(),
    Value<String?> geofenceId = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    DateTime? timestamp,
    bool? isPublished,
    DateTime? createdAt,
  }) => LocationNote(
    id: id ?? this.id,
    noteId: noteId.present ? noteId.value : this.noteId,
    content: content ?? this.content,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    placeName: placeName.present ? placeName.value : this.placeName,
    geofenceId: geofenceId.present ? geofenceId.value : this.geofenceId,
    tags: tags.present ? tags.value : this.tags,
    timestamp: timestamp ?? this.timestamp,
    isPublished: isPublished ?? this.isPublished,
    createdAt: createdAt ?? this.createdAt,
  );
  LocationNote copyWithCompanion(LocationNotesCompanion data) {
    return LocationNote(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      content: data.content.present ? data.content.value : this.content,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      placeName: data.placeName.present ? data.placeName.value : this.placeName,
      geofenceId: data.geofenceId.present
          ? data.geofenceId.value
          : this.geofenceId,
      tags: data.tags.present ? data.tags.value : this.tags,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isPublished: data.isPublished.present
          ? data.isPublished.value
          : this.isPublished,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationNote(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('content: $content, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('placeName: $placeName, ')
          ..write('geofenceId: $geofenceId, ')
          ..write('tags: $tags, ')
          ..write('timestamp: $timestamp, ')
          ..write('isPublished: $isPublished, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    noteId,
    content,
    latitude,
    longitude,
    placeName,
    geofenceId,
    tags,
    timestamp,
    isPublished,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationNote &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.content == this.content &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.placeName == this.placeName &&
          other.geofenceId == this.geofenceId &&
          other.tags == this.tags &&
          other.timestamp == this.timestamp &&
          other.isPublished == this.isPublished &&
          other.createdAt == this.createdAt);
}

class LocationNotesCompanion extends UpdateCompanion<LocationNote> {
  final Value<int> id;
  final Value<String?> noteId;
  final Value<String> content;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String?> placeName;
  final Value<String?> geofenceId;
  final Value<String?> tags;
  final Value<DateTime> timestamp;
  final Value<bool> isPublished;
  final Value<DateTime> createdAt;
  const LocationNotesCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.content = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.placeName = const Value.absent(),
    this.geofenceId = const Value.absent(),
    this.tags = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isPublished = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocationNotesCompanion.insert({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    required String content,
    required double latitude,
    required double longitude,
    this.placeName = const Value.absent(),
    this.geofenceId = const Value.absent(),
    this.tags = const Value.absent(),
    required DateTime timestamp,
    this.isPublished = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : content = Value(content),
       latitude = Value(latitude),
       longitude = Value(longitude),
       timestamp = Value(timestamp);
  static Insertable<LocationNote> custom({
    Expression<int>? id,
    Expression<String>? noteId,
    Expression<String>? content,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? placeName,
    Expression<String>? geofenceId,
    Expression<String>? tags,
    Expression<DateTime>? timestamp,
    Expression<bool>? isPublished,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (content != null) 'content': content,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (placeName != null) 'place_name': placeName,
      if (geofenceId != null) 'geofence_id': geofenceId,
      if (tags != null) 'tags': tags,
      if (timestamp != null) 'timestamp': timestamp,
      if (isPublished != null) 'is_published': isPublished,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocationNotesCompanion copyWith({
    Value<int>? id,
    Value<String?>? noteId,
    Value<String>? content,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String?>? placeName,
    Value<String?>? geofenceId,
    Value<String?>? tags,
    Value<DateTime>? timestamp,
    Value<bool>? isPublished,
    Value<DateTime>? createdAt,
  }) {
    return LocationNotesCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      content: content ?? this.content,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeName: placeName ?? this.placeName,
      geofenceId: geofenceId ?? this.geofenceId,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (placeName.present) {
      map['place_name'] = Variable<String>(placeName.value);
    }
    if (geofenceId.present) {
      map['geofence_id'] = Variable<String>(geofenceId.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isPublished.present) {
      map['is_published'] = Variable<bool>(isPublished.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationNotesCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('content: $content, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('placeName: $placeName, ')
          ..write('geofenceId: $geofenceId, ')
          ..write('tags: $tags, ')
          ..write('timestamp: $timestamp, ')
          ..write('isPublished: $isPublished, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocationSummariesTable extends LocationSummaries
    with TableInfo<$LocationSummariesTable, LocationSummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPointsMeta = const VerificationMeta(
    'totalPoints',
  );
  @override
  late final GeneratedColumn<int> totalPoints = GeneratedColumn<int>(
    'total_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalDistanceMeta = const VerificationMeta(
    'totalDistance',
  );
  @override
  late final GeneratedColumn<double> totalDistance = GeneratedColumn<double>(
    'total_distance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placesVisitedMeta = const VerificationMeta(
    'placesVisited',
  );
  @override
  late final GeneratedColumn<int> placesVisited = GeneratedColumn<int>(
    'places_visited',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mainLocationsMeta = const VerificationMeta(
    'mainLocations',
  );
  @override
  late final GeneratedColumn<String> mainLocations = GeneratedColumn<String>(
    'main_locations',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMinutesMeta = const VerificationMeta(
    'activeMinutes',
  );
  @override
  late final GeneratedColumn<int> activeMinutes = GeneratedColumn<int>(
    'active_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    date,
    totalPoints,
    totalDistance,
    placesVisited,
    mainLocations,
    activeMinutes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationSummary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_points')) {
      context.handle(
        _totalPointsMeta,
        totalPoints.isAcceptableOrUnknown(
          data['total_points']!,
          _totalPointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPointsMeta);
    }
    if (data.containsKey('total_distance')) {
      context.handle(
        _totalDistanceMeta,
        totalDistance.isAcceptableOrUnknown(
          data['total_distance']!,
          _totalDistanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalDistanceMeta);
    }
    if (data.containsKey('places_visited')) {
      context.handle(
        _placesVisitedMeta,
        placesVisited.isAcceptableOrUnknown(
          data['places_visited']!,
          _placesVisitedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_placesVisitedMeta);
    }
    if (data.containsKey('main_locations')) {
      context.handle(
        _mainLocationsMeta,
        mainLocations.isAcceptableOrUnknown(
          data['main_locations']!,
          _mainLocationsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mainLocationsMeta);
    }
    if (data.containsKey('active_minutes')) {
      context.handle(
        _activeMinutesMeta,
        activeMinutes.isAcceptableOrUnknown(
          data['active_minutes']!,
          _activeMinutesMeta,
        ),
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {date},
  ];
  @override
  LocationSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationSummary(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      totalPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_points'],
      )!,
      totalDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_distance'],
      )!,
      placesVisited: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}places_visited'],
      )!,
      mainLocations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}main_locations'],
      )!,
      activeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_minutes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocationSummariesTable createAlias(String alias) {
    return $LocationSummariesTable(attachedDatabase, alias);
  }
}

class LocationSummary extends DataClass implements Insertable<LocationSummary> {
  final int id;
  final DateTime date;
  final int totalPoints;
  final double totalDistance;
  final int placesVisited;
  final String mainLocations;
  final int? activeMinutes;
  final DateTime createdAt;
  const LocationSummary({
    required this.id,
    required this.date,
    required this.totalPoints,
    required this.totalDistance,
    required this.placesVisited,
    required this.mainLocations,
    this.activeMinutes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['total_points'] = Variable<int>(totalPoints);
    map['total_distance'] = Variable<double>(totalDistance);
    map['places_visited'] = Variable<int>(placesVisited);
    map['main_locations'] = Variable<String>(mainLocations);
    if (!nullToAbsent || activeMinutes != null) {
      map['active_minutes'] = Variable<int>(activeMinutes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocationSummariesCompanion toCompanion(bool nullToAbsent) {
    return LocationSummariesCompanion(
      id: Value(id),
      date: Value(date),
      totalPoints: Value(totalPoints),
      totalDistance: Value(totalDistance),
      placesVisited: Value(placesVisited),
      mainLocations: Value(mainLocations),
      activeMinutes: activeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(activeMinutes),
      createdAt: Value(createdAt),
    );
  }

  factory LocationSummary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationSummary(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      totalPoints: serializer.fromJson<int>(json['totalPoints']),
      totalDistance: serializer.fromJson<double>(json['totalDistance']),
      placesVisited: serializer.fromJson<int>(json['placesVisited']),
      mainLocations: serializer.fromJson<String>(json['mainLocations']),
      activeMinutes: serializer.fromJson<int?>(json['activeMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'totalPoints': serializer.toJson<int>(totalPoints),
      'totalDistance': serializer.toJson<double>(totalDistance),
      'placesVisited': serializer.toJson<int>(placesVisited),
      'mainLocations': serializer.toJson<String>(mainLocations),
      'activeMinutes': serializer.toJson<int?>(activeMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocationSummary copyWith({
    int? id,
    DateTime? date,
    int? totalPoints,
    double? totalDistance,
    int? placesVisited,
    String? mainLocations,
    Value<int?> activeMinutes = const Value.absent(),
    DateTime? createdAt,
  }) => LocationSummary(
    id: id ?? this.id,
    date: date ?? this.date,
    totalPoints: totalPoints ?? this.totalPoints,
    totalDistance: totalDistance ?? this.totalDistance,
    placesVisited: placesVisited ?? this.placesVisited,
    mainLocations: mainLocations ?? this.mainLocations,
    activeMinutes: activeMinutes.present
        ? activeMinutes.value
        : this.activeMinutes,
    createdAt: createdAt ?? this.createdAt,
  );
  LocationSummary copyWithCompanion(LocationSummariesCompanion data) {
    return LocationSummary(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      totalPoints: data.totalPoints.present
          ? data.totalPoints.value
          : this.totalPoints,
      totalDistance: data.totalDistance.present
          ? data.totalDistance.value
          : this.totalDistance,
      placesVisited: data.placesVisited.present
          ? data.placesVisited.value
          : this.placesVisited,
      mainLocations: data.mainLocations.present
          ? data.mainLocations.value
          : this.mainLocations,
      activeMinutes: data.activeMinutes.present
          ? data.activeMinutes.value
          : this.activeMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationSummary(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('totalPoints: $totalPoints, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('placesVisited: $placesVisited, ')
          ..write('mainLocations: $mainLocations, ')
          ..write('activeMinutes: $activeMinutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    totalPoints,
    totalDistance,
    placesVisited,
    mainLocations,
    activeMinutes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationSummary &&
          other.id == this.id &&
          other.date == this.date &&
          other.totalPoints == this.totalPoints &&
          other.totalDistance == this.totalDistance &&
          other.placesVisited == this.placesVisited &&
          other.mainLocations == this.mainLocations &&
          other.activeMinutes == this.activeMinutes &&
          other.createdAt == this.createdAt);
}

class LocationSummariesCompanion extends UpdateCompanion<LocationSummary> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> totalPoints;
  final Value<double> totalDistance;
  final Value<int> placesVisited;
  final Value<String> mainLocations;
  final Value<int?> activeMinutes;
  final Value<DateTime> createdAt;
  const LocationSummariesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.totalPoints = const Value.absent(),
    this.totalDistance = const Value.absent(),
    this.placesVisited = const Value.absent(),
    this.mainLocations = const Value.absent(),
    this.activeMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocationSummariesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required int totalPoints,
    required double totalDistance,
    required int placesVisited,
    required String mainLocations,
    this.activeMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : date = Value(date),
       totalPoints = Value(totalPoints),
       totalDistance = Value(totalDistance),
       placesVisited = Value(placesVisited),
       mainLocations = Value(mainLocations);
  static Insertable<LocationSummary> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? totalPoints,
    Expression<double>? totalDistance,
    Expression<int>? placesVisited,
    Expression<String>? mainLocations,
    Expression<int>? activeMinutes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (totalPoints != null) 'total_points': totalPoints,
      if (totalDistance != null) 'total_distance': totalDistance,
      if (placesVisited != null) 'places_visited': placesVisited,
      if (mainLocations != null) 'main_locations': mainLocations,
      if (activeMinutes != null) 'active_minutes': activeMinutes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocationSummariesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? totalPoints,
    Value<double>? totalDistance,
    Value<int>? placesVisited,
    Value<String>? mainLocations,
    Value<int?>? activeMinutes,
    Value<DateTime>? createdAt,
  }) {
    return LocationSummariesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      totalPoints: totalPoints ?? this.totalPoints,
      totalDistance: totalDistance ?? this.totalDistance,
      placesVisited: placesVisited ?? this.placesVisited,
      mainLocations: mainLocations ?? this.mainLocations,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (totalPoints.present) {
      map['total_points'] = Variable<int>(totalPoints.value);
    }
    if (totalDistance.present) {
      map['total_distance'] = Variable<double>(totalDistance.value);
    }
    if (placesVisited.present) {
      map['places_visited'] = Variable<int>(placesVisited.value);
    }
    if (mainLocations.present) {
      map['main_locations'] = Variable<String>(mainLocations.value);
    }
    if (activeMinutes.present) {
      map['active_minutes'] = Variable<int>(activeMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationSummariesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('totalPoints: $totalPoints, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('placesVisited: $placesVisited, ')
          ..write('mainLocations: $mainLocations, ')
          ..write('activeMinutes: $activeMinutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MovementDataTable extends MovementData
    with TableInfo<$MovementDataTable, MovementDataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovementDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageMagnitudeMeta = const VerificationMeta(
    'averageMagnitude',
  );
  @override
  late final GeneratedColumn<double> averageMagnitude = GeneratedColumn<double>(
    'average_magnitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stillPercentageMeta = const VerificationMeta(
    'stillPercentage',
  );
  @override
  late final GeneratedColumn<double> stillPercentage = GeneratedColumn<double>(
    'still_percentage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walkingPercentageMeta = const VerificationMeta(
    'walkingPercentage',
  );
  @override
  late final GeneratedColumn<double> walkingPercentage =
      GeneratedColumn<double>(
        'walking_percentage',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _runningPercentageMeta = const VerificationMeta(
    'runningPercentage',
  );
  @override
  late final GeneratedColumn<double> runningPercentage =
      GeneratedColumn<double>(
        'running_percentage',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _drivingPercentageMeta = const VerificationMeta(
    'drivingPercentage',
  );
  @override
  late final GeneratedColumn<double> drivingPercentage =
      GeneratedColumn<double>(
        'driving_percentage',
        aliasedName,
        false,
        type: DriftSqlType.double,
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
    timestamp,
    state,
    averageMagnitude,
    sampleCount,
    stillPercentage,
    walkingPercentage,
    runningPercentage,
    drivingPercentage,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movement_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovementDataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('average_magnitude')) {
      context.handle(
        _averageMagnitudeMeta,
        averageMagnitude.isAcceptableOrUnknown(
          data['average_magnitude']!,
          _averageMagnitudeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averageMagnitudeMeta);
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sampleCountMeta);
    }
    if (data.containsKey('still_percentage')) {
      context.handle(
        _stillPercentageMeta,
        stillPercentage.isAcceptableOrUnknown(
          data['still_percentage']!,
          _stillPercentageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stillPercentageMeta);
    }
    if (data.containsKey('walking_percentage')) {
      context.handle(
        _walkingPercentageMeta,
        walkingPercentage.isAcceptableOrUnknown(
          data['walking_percentage']!,
          _walkingPercentageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_walkingPercentageMeta);
    }
    if (data.containsKey('running_percentage')) {
      context.handle(
        _runningPercentageMeta,
        runningPercentage.isAcceptableOrUnknown(
          data['running_percentage']!,
          _runningPercentageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_runningPercentageMeta);
    }
    if (data.containsKey('driving_percentage')) {
      context.handle(
        _drivingPercentageMeta,
        drivingPercentage.isAcceptableOrUnknown(
          data['driving_percentage']!,
          _drivingPercentageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_drivingPercentageMeta);
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
  MovementDataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovementDataData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      averageMagnitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_magnitude'],
      )!,
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      stillPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}still_percentage'],
      )!,
      walkingPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}walking_percentage'],
      )!,
      runningPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}running_percentage'],
      )!,
      drivingPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}driving_percentage'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MovementDataTable createAlias(String alias) {
    return $MovementDataTable(attachedDatabase, alias);
  }
}

class MovementDataData extends DataClass
    implements Insertable<MovementDataData> {
  final int id;
  final DateTime timestamp;
  final String state;
  final double averageMagnitude;
  final int sampleCount;
  final double stillPercentage;
  final double walkingPercentage;
  final double runningPercentage;
  final double drivingPercentage;
  final DateTime createdAt;
  const MovementDataData({
    required this.id,
    required this.timestamp,
    required this.state,
    required this.averageMagnitude,
    required this.sampleCount,
    required this.stillPercentage,
    required this.walkingPercentage,
    required this.runningPercentage,
    required this.drivingPercentage,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['state'] = Variable<String>(state);
    map['average_magnitude'] = Variable<double>(averageMagnitude);
    map['sample_count'] = Variable<int>(sampleCount);
    map['still_percentage'] = Variable<double>(stillPercentage);
    map['walking_percentage'] = Variable<double>(walkingPercentage);
    map['running_percentage'] = Variable<double>(runningPercentage);
    map['driving_percentage'] = Variable<double>(drivingPercentage);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MovementDataCompanion toCompanion(bool nullToAbsent) {
    return MovementDataCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      state: Value(state),
      averageMagnitude: Value(averageMagnitude),
      sampleCount: Value(sampleCount),
      stillPercentage: Value(stillPercentage),
      walkingPercentage: Value(walkingPercentage),
      runningPercentage: Value(runningPercentage),
      drivingPercentage: Value(drivingPercentage),
      createdAt: Value(createdAt),
    );
  }

  factory MovementDataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovementDataData(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      state: serializer.fromJson<String>(json['state']),
      averageMagnitude: serializer.fromJson<double>(json['averageMagnitude']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      stillPercentage: serializer.fromJson<double>(json['stillPercentage']),
      walkingPercentage: serializer.fromJson<double>(json['walkingPercentage']),
      runningPercentage: serializer.fromJson<double>(json['runningPercentage']),
      drivingPercentage: serializer.fromJson<double>(json['drivingPercentage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'state': serializer.toJson<String>(state),
      'averageMagnitude': serializer.toJson<double>(averageMagnitude),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'stillPercentage': serializer.toJson<double>(stillPercentage),
      'walkingPercentage': serializer.toJson<double>(walkingPercentage),
      'runningPercentage': serializer.toJson<double>(runningPercentage),
      'drivingPercentage': serializer.toJson<double>(drivingPercentage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MovementDataData copyWith({
    int? id,
    DateTime? timestamp,
    String? state,
    double? averageMagnitude,
    int? sampleCount,
    double? stillPercentage,
    double? walkingPercentage,
    double? runningPercentage,
    double? drivingPercentage,
    DateTime? createdAt,
  }) => MovementDataData(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    state: state ?? this.state,
    averageMagnitude: averageMagnitude ?? this.averageMagnitude,
    sampleCount: sampleCount ?? this.sampleCount,
    stillPercentage: stillPercentage ?? this.stillPercentage,
    walkingPercentage: walkingPercentage ?? this.walkingPercentage,
    runningPercentage: runningPercentage ?? this.runningPercentage,
    drivingPercentage: drivingPercentage ?? this.drivingPercentage,
    createdAt: createdAt ?? this.createdAt,
  );
  MovementDataData copyWithCompanion(MovementDataCompanion data) {
    return MovementDataData(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      state: data.state.present ? data.state.value : this.state,
      averageMagnitude: data.averageMagnitude.present
          ? data.averageMagnitude.value
          : this.averageMagnitude,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      stillPercentage: data.stillPercentage.present
          ? data.stillPercentage.value
          : this.stillPercentage,
      walkingPercentage: data.walkingPercentage.present
          ? data.walkingPercentage.value
          : this.walkingPercentage,
      runningPercentage: data.runningPercentage.present
          ? data.runningPercentage.value
          : this.runningPercentage,
      drivingPercentage: data.drivingPercentage.present
          ? data.drivingPercentage.value
          : this.drivingPercentage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovementDataData(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('state: $state, ')
          ..write('averageMagnitude: $averageMagnitude, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('stillPercentage: $stillPercentage, ')
          ..write('walkingPercentage: $walkingPercentage, ')
          ..write('runningPercentage: $runningPercentage, ')
          ..write('drivingPercentage: $drivingPercentage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    state,
    averageMagnitude,
    sampleCount,
    stillPercentage,
    walkingPercentage,
    runningPercentage,
    drivingPercentage,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovementDataData &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.state == this.state &&
          other.averageMagnitude == this.averageMagnitude &&
          other.sampleCount == this.sampleCount &&
          other.stillPercentage == this.stillPercentage &&
          other.walkingPercentage == this.walkingPercentage &&
          other.runningPercentage == this.runningPercentage &&
          other.drivingPercentage == this.drivingPercentage &&
          other.createdAt == this.createdAt);
}

class MovementDataCompanion extends UpdateCompanion<MovementDataData> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<String> state;
  final Value<double> averageMagnitude;
  final Value<int> sampleCount;
  final Value<double> stillPercentage;
  final Value<double> walkingPercentage;
  final Value<double> runningPercentage;
  final Value<double> drivingPercentage;
  final Value<DateTime> createdAt;
  const MovementDataCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.state = const Value.absent(),
    this.averageMagnitude = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.stillPercentage = const Value.absent(),
    this.walkingPercentage = const Value.absent(),
    this.runningPercentage = const Value.absent(),
    this.drivingPercentage = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MovementDataCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required String state,
    required double averageMagnitude,
    required int sampleCount,
    required double stillPercentage,
    required double walkingPercentage,
    required double runningPercentage,
    required double drivingPercentage,
    this.createdAt = const Value.absent(),
  }) : timestamp = Value(timestamp),
       state = Value(state),
       averageMagnitude = Value(averageMagnitude),
       sampleCount = Value(sampleCount),
       stillPercentage = Value(stillPercentage),
       walkingPercentage = Value(walkingPercentage),
       runningPercentage = Value(runningPercentage),
       drivingPercentage = Value(drivingPercentage);
  static Insertable<MovementDataData> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? state,
    Expression<double>? averageMagnitude,
    Expression<int>? sampleCount,
    Expression<double>? stillPercentage,
    Expression<double>? walkingPercentage,
    Expression<double>? runningPercentage,
    Expression<double>? drivingPercentage,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (state != null) 'state': state,
      if (averageMagnitude != null) 'average_magnitude': averageMagnitude,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (stillPercentage != null) 'still_percentage': stillPercentage,
      if (walkingPercentage != null) 'walking_percentage': walkingPercentage,
      if (runningPercentage != null) 'running_percentage': runningPercentage,
      if (drivingPercentage != null) 'driving_percentage': drivingPercentage,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MovementDataCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<String>? state,
    Value<double>? averageMagnitude,
    Value<int>? sampleCount,
    Value<double>? stillPercentage,
    Value<double>? walkingPercentage,
    Value<double>? runningPercentage,
    Value<double>? drivingPercentage,
    Value<DateTime>? createdAt,
  }) {
    return MovementDataCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      state: state ?? this.state,
      averageMagnitude: averageMagnitude ?? this.averageMagnitude,
      sampleCount: sampleCount ?? this.sampleCount,
      stillPercentage: stillPercentage ?? this.stillPercentage,
      walkingPercentage: walkingPercentage ?? this.walkingPercentage,
      runningPercentage: runningPercentage ?? this.runningPercentage,
      drivingPercentage: drivingPercentage ?? this.drivingPercentage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (averageMagnitude.present) {
      map['average_magnitude'] = Variable<double>(averageMagnitude.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    if (stillPercentage.present) {
      map['still_percentage'] = Variable<double>(stillPercentage.value);
    }
    if (walkingPercentage.present) {
      map['walking_percentage'] = Variable<double>(walkingPercentage.value);
    }
    if (runningPercentage.present) {
      map['running_percentage'] = Variable<double>(runningPercentage.value);
    }
    if (drivingPercentage.present) {
      map['driving_percentage'] = Variable<double>(drivingPercentage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovementDataCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('state: $state, ')
          ..write('averageMagnitude: $averageMagnitude, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('stillPercentage: $stillPercentage, ')
          ..write('walkingPercentage: $walkingPercentage, ')
          ..write('runningPercentage: $runningPercentage, ')
          ..write('drivingPercentage: $drivingPercentage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocationDatabase extends GeneratedDatabase {
  _$LocationDatabase(QueryExecutor e) : super(e);
  $LocationDatabaseManager get managers => $LocationDatabaseManager(this);
  late final $LocationPointsTable locationPoints = $LocationPointsTable(this);
  late final $GeofenceAreasTable geofenceAreas = $GeofenceAreasTable(this);
  late final $GeofenceEventsTable geofenceEvents = $GeofenceEventsTable(this);
  late final $LocationNotesTable locationNotes = $LocationNotesTable(this);
  late final $LocationSummariesTable locationSummaries =
      $LocationSummariesTable(this);
  late final $MovementDataTable movementData = $MovementDataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    locationPoints,
    geofenceAreas,
    geofenceEvents,
    locationNotes,
    locationSummaries,
    movementData,
  ];
}

typedef $$LocationPointsTableCreateCompanionBuilder =
    LocationPointsCompanion Function({
      Value<int> id,
      required double latitude,
      required double longitude,
      Value<double?> accuracy,
      Value<double?> altitude,
      Value<double?> speed,
      Value<double?> heading,
      required DateTime timestamp,
      Value<String?> activityType,
      Value<bool> isSignificant,
      Value<DateTime> createdAt,
    });
typedef $$LocationPointsTableUpdateCompanionBuilder =
    LocationPointsCompanion Function({
      Value<int> id,
      Value<double> latitude,
      Value<double> longitude,
      Value<double?> accuracy,
      Value<double?> altitude,
      Value<double?> speed,
      Value<double?> heading,
      Value<DateTime> timestamp,
      Value<String?> activityType,
      Value<bool> isSignificant,
      Value<DateTime> createdAt,
    });

class $$LocationPointsTableFilterComposer
    extends Composer<_$LocationDatabase, $LocationPointsTable> {
  $$LocationPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSignificant => $composableBuilder(
    column: $table.isSignificant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationPointsTableOrderingComposer
    extends Composer<_$LocationDatabase, $LocationPointsTable> {
  $$LocationPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSignificant => $composableBuilder(
    column: $table.isSignificant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationPointsTableAnnotationComposer
    extends Composer<_$LocationDatabase, $LocationPointsTable> {
  $$LocationPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSignificant => $composableBuilder(
    column: $table.isSignificant,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocationPointsTableTableManager
    extends
        RootTableManager<
          _$LocationDatabase,
          $LocationPointsTable,
          LocationPoint,
          $$LocationPointsTableFilterComposer,
          $$LocationPointsTableOrderingComposer,
          $$LocationPointsTableAnnotationComposer,
          $$LocationPointsTableCreateCompanionBuilder,
          $$LocationPointsTableUpdateCompanionBuilder,
          (
            LocationPoint,
            BaseReferences<
              _$LocationDatabase,
              $LocationPointsTable,
              LocationPoint
            >,
          ),
          LocationPoint,
          PrefetchHooks Function()
        > {
  $$LocationPointsTableTableManager(
    _$LocationDatabase db,
    $LocationPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> activityType = const Value.absent(),
                Value<bool> isSignificant = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocationPointsCompanion(
                id: id,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                altitude: altitude,
                speed: speed,
                heading: heading,
                timestamp: timestamp,
                activityType: activityType,
                isSignificant: isSignificant,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double latitude,
                required double longitude,
                Value<double?> accuracy = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                required DateTime timestamp,
                Value<String?> activityType = const Value.absent(),
                Value<bool> isSignificant = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocationPointsCompanion.insert(
                id: id,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                altitude: altitude,
                speed: speed,
                heading: heading,
                timestamp: timestamp,
                activityType: activityType,
                isSignificant: isSignificant,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocationDatabase,
      $LocationPointsTable,
      LocationPoint,
      $$LocationPointsTableFilterComposer,
      $$LocationPointsTableOrderingComposer,
      $$LocationPointsTableAnnotationComposer,
      $$LocationPointsTableCreateCompanionBuilder,
      $$LocationPointsTableUpdateCompanionBuilder,
      (
        LocationPoint,
        BaseReferences<_$LocationDatabase, $LocationPointsTable, LocationPoint>,
      ),
      LocationPoint,
      PrefetchHooks Function()
    >;
typedef $$GeofenceAreasTableCreateCompanionBuilder =
    GeofenceAreasCompanion Function({
      required String id,
      required String name,
      required double latitude,
      required double longitude,
      required double radius,
      Value<bool> isActive,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$GeofenceAreasTableUpdateCompanionBuilder =
    GeofenceAreasCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> radius,
      Value<bool> isActive,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

final class $$GeofenceAreasTableReferences
    extends
        BaseReferences<_$LocationDatabase, $GeofenceAreasTable, GeofenceArea> {
  $$GeofenceAreasTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$GeofenceEventsTable, List<GeofenceEvent>>
  _geofenceEventsRefsTable(_$LocationDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.geofenceEvents,
        aliasName: $_aliasNameGenerator(
          db.geofenceAreas.id,
          db.geofenceEvents.geofenceId,
        ),
      );

  $$GeofenceEventsTableProcessedTableManager get geofenceEventsRefs {
    final manager = $$GeofenceEventsTableTableManager(
      $_db,
      $_db.geofenceEvents,
    ).filter((f) => f.geofenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_geofenceEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocationNotesTable, List<LocationNote>>
  _locationNotesRefsTable(_$LocationDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.locationNotes,
        aliasName: $_aliasNameGenerator(
          db.geofenceAreas.id,
          db.locationNotes.geofenceId,
        ),
      );

  $$LocationNotesTableProcessedTableManager get locationNotesRefs {
    final manager = $$LocationNotesTableTableManager(
      $_db,
      $_db.locationNotes,
    ).filter((f) => f.geofenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_locationNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GeofenceAreasTableFilterComposer
    extends Composer<_$LocationDatabase, $GeofenceAreasTable> {
  $$GeofenceAreasTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radius => $composableBuilder(
    column: $table.radius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
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

  Expression<bool> geofenceEventsRefs(
    Expression<bool> Function($$GeofenceEventsTableFilterComposer f) f,
  ) {
    final $$GeofenceEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.geofenceEvents,
      getReferencedColumn: (t) => t.geofenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GeofenceEventsTableFilterComposer(
            $db: $db,
            $table: $db.geofenceEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> locationNotesRefs(
    Expression<bool> Function($$LocationNotesTableFilterComposer f) f,
  ) {
    final $$LocationNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.locationNotes,
      getReferencedColumn: (t) => t.geofenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationNotesTableFilterComposer(
            $db: $db,
            $table: $db.locationNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GeofenceAreasTableOrderingComposer
    extends Composer<_$LocationDatabase, $GeofenceAreasTable> {
  $$GeofenceAreasTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radius => $composableBuilder(
    column: $table.radius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
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

class $$GeofenceAreasTableAnnotationComposer
    extends Composer<_$LocationDatabase, $GeofenceAreasTable> {
  $$GeofenceAreasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get radius =>
      $composableBuilder(column: $table.radius, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> geofenceEventsRefs<T extends Object>(
    Expression<T> Function($$GeofenceEventsTableAnnotationComposer a) f,
  ) {
    final $$GeofenceEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.geofenceEvents,
      getReferencedColumn: (t) => t.geofenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GeofenceEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.geofenceEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> locationNotesRefs<T extends Object>(
    Expression<T> Function($$LocationNotesTableAnnotationComposer a) f,
  ) {
    final $$LocationNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.locationNotes,
      getReferencedColumn: (t) => t.geofenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.locationNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GeofenceAreasTableTableManager
    extends
        RootTableManager<
          _$LocationDatabase,
          $GeofenceAreasTable,
          GeofenceArea,
          $$GeofenceAreasTableFilterComposer,
          $$GeofenceAreasTableOrderingComposer,
          $$GeofenceAreasTableAnnotationComposer,
          $$GeofenceAreasTableCreateCompanionBuilder,
          $$GeofenceAreasTableUpdateCompanionBuilder,
          (GeofenceArea, $$GeofenceAreasTableReferences),
          GeofenceArea,
          PrefetchHooks Function({
            bool geofenceEventsRefs,
            bool locationNotesRefs,
          })
        > {
  $$GeofenceAreasTableTableManager(
    _$LocationDatabase db,
    $GeofenceAreasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeofenceAreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeofenceAreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeofenceAreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> radius = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GeofenceAreasCompanion(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                radius: radius,
                isActive: isActive,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double latitude,
                required double longitude,
                required double radius,
                Value<bool> isActive = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GeofenceAreasCompanion.insert(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                radius: radius,
                isActive: isActive,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GeofenceAreasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({geofenceEventsRefs = false, locationNotesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (geofenceEventsRefs) db.geofenceEvents,
                    if (locationNotesRefs) db.locationNotes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (geofenceEventsRefs)
                        await $_getPrefetchedData<
                          GeofenceArea,
                          $GeofenceAreasTable,
                          GeofenceEvent
                        >(
                          currentTable: table,
                          referencedTable: $$GeofenceAreasTableReferences
                              ._geofenceEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GeofenceAreasTableReferences(
                                db,
                                table,
                                p0,
                              ).geofenceEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.geofenceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (locationNotesRefs)
                        await $_getPrefetchedData<
                          GeofenceArea,
                          $GeofenceAreasTable,
                          LocationNote
                        >(
                          currentTable: table,
                          referencedTable: $$GeofenceAreasTableReferences
                              ._locationNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GeofenceAreasTableReferences(
                                db,
                                table,
                                p0,
                              ).locationNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.geofenceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GeofenceAreasTableProcessedTableManager =
    ProcessedTableManager<
      _$LocationDatabase,
      $GeofenceAreasTable,
      GeofenceArea,
      $$GeofenceAreasTableFilterComposer,
      $$GeofenceAreasTableOrderingComposer,
      $$GeofenceAreasTableAnnotationComposer,
      $$GeofenceAreasTableCreateCompanionBuilder,
      $$GeofenceAreasTableUpdateCompanionBuilder,
      (GeofenceArea, $$GeofenceAreasTableReferences),
      GeofenceArea,
      PrefetchHooks Function({bool geofenceEventsRefs, bool locationNotesRefs})
    >;
typedef $$GeofenceEventsTableCreateCompanionBuilder =
    GeofenceEventsCompanion Function({
      Value<int> id,
      required String geofenceId,
      required String eventType,
      required DateTime timestamp,
      required double latitude,
      required double longitude,
      Value<int?> dwellTime,
      Value<DateTime> createdAt,
    });
typedef $$GeofenceEventsTableUpdateCompanionBuilder =
    GeofenceEventsCompanion Function({
      Value<int> id,
      Value<String> geofenceId,
      Value<String> eventType,
      Value<DateTime> timestamp,
      Value<double> latitude,
      Value<double> longitude,
      Value<int?> dwellTime,
      Value<DateTime> createdAt,
    });

final class $$GeofenceEventsTableReferences
    extends
        BaseReferences<
          _$LocationDatabase,
          $GeofenceEventsTable,
          GeofenceEvent
        > {
  $$GeofenceEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GeofenceAreasTable _geofenceIdTable(_$LocationDatabase db) =>
      db.geofenceAreas.createAlias(
        $_aliasNameGenerator(db.geofenceEvents.geofenceId, db.geofenceAreas.id),
      );

  $$GeofenceAreasTableProcessedTableManager get geofenceId {
    final $_column = $_itemColumn<String>('geofence_id')!;

    final manager = $$GeofenceAreasTableTableManager(
      $_db,
      $_db.geofenceAreas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_geofenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GeofenceEventsTableFilterComposer
    extends Composer<_$LocationDatabase, $GeofenceEventsTable> {
  $$GeofenceEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dwellTime => $composableBuilder(
    column: $table.dwellTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GeofenceAreasTableFilterComposer get geofenceId {
    final $$GeofenceAreasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.geofenceId,
      referencedTable: $db.geofenceAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GeofenceAreasTableFilterComposer(
            $db: $db,
            $table: $db.geofenceAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GeofenceEventsTableOrderingComposer
    extends Composer<_$LocationDatabase, $GeofenceEventsTable> {
  $$GeofenceEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dwellTime => $composableBuilder(
    column: $table.dwellTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GeofenceAreasTableOrderingComposer get geofenceId {
    final $$GeofenceAreasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.geofenceId,
      referencedTable: $db.geofenceAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GeofenceAreasTableOrderingComposer(
            $db: $db,
            $table: $db.geofenceAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GeofenceEventsTableAnnotationComposer
    extends Composer<_$LocationDatabase, $GeofenceEventsTable> {
  $$GeofenceEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get dwellTime =>
      $composableBuilder(column: $table.dwellTime, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GeofenceAreasTableAnnotationComposer get geofenceId {
    final $$GeofenceAreasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.geofenceId,
      referencedTable: $db.geofenceAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GeofenceAreasTableAnnotationComposer(
            $db: $db,
            $table: $db.geofenceAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GeofenceEventsTableTableManager
    extends
        RootTableManager<
          _$LocationDatabase,
          $GeofenceEventsTable,
          GeofenceEvent,
          $$GeofenceEventsTableFilterComposer,
          $$GeofenceEventsTableOrderingComposer,
          $$GeofenceEventsTableAnnotationComposer,
          $$GeofenceEventsTableCreateCompanionBuilder,
          $$GeofenceEventsTableUpdateCompanionBuilder,
          (GeofenceEvent, $$GeofenceEventsTableReferences),
          GeofenceEvent,
          PrefetchHooks Function({bool geofenceId})
        > {
  $$GeofenceEventsTableTableManager(
    _$LocationDatabase db,
    $GeofenceEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeofenceEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeofenceEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeofenceEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> geofenceId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<int?> dwellTime = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GeofenceEventsCompanion(
                id: id,
                geofenceId: geofenceId,
                eventType: eventType,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                dwellTime: dwellTime,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String geofenceId,
                required String eventType,
                required DateTime timestamp,
                required double latitude,
                required double longitude,
                Value<int?> dwellTime = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GeofenceEventsCompanion.insert(
                id: id,
                geofenceId: geofenceId,
                eventType: eventType,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                dwellTime: dwellTime,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GeofenceEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({geofenceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (geofenceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.geofenceId,
                                referencedTable: $$GeofenceEventsTableReferences
                                    ._geofenceIdTable(db),
                                referencedColumn:
                                    $$GeofenceEventsTableReferences
                                        ._geofenceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GeofenceEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocationDatabase,
      $GeofenceEventsTable,
      GeofenceEvent,
      $$GeofenceEventsTableFilterComposer,
      $$GeofenceEventsTableOrderingComposer,
      $$GeofenceEventsTableAnnotationComposer,
      $$GeofenceEventsTableCreateCompanionBuilder,
      $$GeofenceEventsTableUpdateCompanionBuilder,
      (GeofenceEvent, $$GeofenceEventsTableReferences),
      GeofenceEvent,
      PrefetchHooks Function({bool geofenceId})
    >;
typedef $$LocationNotesTableCreateCompanionBuilder =
    LocationNotesCompanion Function({
      Value<int> id,
      Value<String?> noteId,
      required String content,
      required double latitude,
      required double longitude,
      Value<String?> placeName,
      Value<String?> geofenceId,
      Value<String?> tags,
      required DateTime timestamp,
      Value<bool> isPublished,
      Value<DateTime> createdAt,
    });
typedef $$LocationNotesTableUpdateCompanionBuilder =
    LocationNotesCompanion Function({
      Value<int> id,
      Value<String?> noteId,
      Value<String> content,
      Value<double> latitude,
      Value<double> longitude,
      Value<String?> placeName,
      Value<String?> geofenceId,
      Value<String?> tags,
      Value<DateTime> timestamp,
      Value<bool> isPublished,
      Value<DateTime> createdAt,
    });

final class $$LocationNotesTableReferences
    extends
        BaseReferences<_$LocationDatabase, $LocationNotesTable, LocationNote> {
  $$LocationNotesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GeofenceAreasTable _geofenceIdTable(_$LocationDatabase db) =>
      db.geofenceAreas.createAlias(
        $_aliasNameGenerator(db.locationNotes.geofenceId, db.geofenceAreas.id),
      );

  $$GeofenceAreasTableProcessedTableManager? get geofenceId {
    final $_column = $_itemColumn<String>('geofence_id');
    if ($_column == null) return null;
    final manager = $$GeofenceAreasTableTableManager(
      $_db,
      $_db.geofenceAreas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_geofenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocationNotesTableFilterComposer
    extends Composer<_$LocationDatabase, $LocationNotesTable> {
  $$LocationNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placeName => $composableBuilder(
    column: $table.placeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPublished => $composableBuilder(
    column: $table.isPublished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GeofenceAreasTableFilterComposer get geofenceId {
    final $$GeofenceAreasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.geofenceId,
      referencedTable: $db.geofenceAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GeofenceAreasTableFilterComposer(
            $db: $db,
            $table: $db.geofenceAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocationNotesTableOrderingComposer
    extends Composer<_$LocationDatabase, $LocationNotesTable> {
  $$LocationNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeName => $composableBuilder(
    column: $table.placeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPublished => $composableBuilder(
    column: $table.isPublished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GeofenceAreasTableOrderingComposer get geofenceId {
    final $$GeofenceAreasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.geofenceId,
      referencedTable: $db.geofenceAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GeofenceAreasTableOrderingComposer(
            $db: $db,
            $table: $db.geofenceAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocationNotesTableAnnotationComposer
    extends Composer<_$LocationDatabase, $LocationNotesTable> {
  $$LocationNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get placeName =>
      $composableBuilder(column: $table.placeName, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isPublished => $composableBuilder(
    column: $table.isPublished,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GeofenceAreasTableAnnotationComposer get geofenceId {
    final $$GeofenceAreasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.geofenceId,
      referencedTable: $db.geofenceAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GeofenceAreasTableAnnotationComposer(
            $db: $db,
            $table: $db.geofenceAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocationNotesTableTableManager
    extends
        RootTableManager<
          _$LocationDatabase,
          $LocationNotesTable,
          LocationNote,
          $$LocationNotesTableFilterComposer,
          $$LocationNotesTableOrderingComposer,
          $$LocationNotesTableAnnotationComposer,
          $$LocationNotesTableCreateCompanionBuilder,
          $$LocationNotesTableUpdateCompanionBuilder,
          (LocationNote, $$LocationNotesTableReferences),
          LocationNote,
          PrefetchHooks Function({bool geofenceId})
        > {
  $$LocationNotesTableTableManager(
    _$LocationDatabase db,
    $LocationNotesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String?> placeName = const Value.absent(),
                Value<String?> geofenceId = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> isPublished = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocationNotesCompanion(
                id: id,
                noteId: noteId,
                content: content,
                latitude: latitude,
                longitude: longitude,
                placeName: placeName,
                geofenceId: geofenceId,
                tags: tags,
                timestamp: timestamp,
                isPublished: isPublished,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                required String content,
                required double latitude,
                required double longitude,
                Value<String?> placeName = const Value.absent(),
                Value<String?> geofenceId = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                required DateTime timestamp,
                Value<bool> isPublished = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocationNotesCompanion.insert(
                id: id,
                noteId: noteId,
                content: content,
                latitude: latitude,
                longitude: longitude,
                placeName: placeName,
                geofenceId: geofenceId,
                tags: tags,
                timestamp: timestamp,
                isPublished: isPublished,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocationNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({geofenceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (geofenceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.geofenceId,
                                referencedTable: $$LocationNotesTableReferences
                                    ._geofenceIdTable(db),
                                referencedColumn: $$LocationNotesTableReferences
                                    ._geofenceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocationNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocationDatabase,
      $LocationNotesTable,
      LocationNote,
      $$LocationNotesTableFilterComposer,
      $$LocationNotesTableOrderingComposer,
      $$LocationNotesTableAnnotationComposer,
      $$LocationNotesTableCreateCompanionBuilder,
      $$LocationNotesTableUpdateCompanionBuilder,
      (LocationNote, $$LocationNotesTableReferences),
      LocationNote,
      PrefetchHooks Function({bool geofenceId})
    >;
typedef $$LocationSummariesTableCreateCompanionBuilder =
    LocationSummariesCompanion Function({
      Value<int> id,
      required DateTime date,
      required int totalPoints,
      required double totalDistance,
      required int placesVisited,
      required String mainLocations,
      Value<int?> activeMinutes,
      Value<DateTime> createdAt,
    });
typedef $$LocationSummariesTableUpdateCompanionBuilder =
    LocationSummariesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> totalPoints,
      Value<double> totalDistance,
      Value<int> placesVisited,
      Value<String> mainLocations,
      Value<int?> activeMinutes,
      Value<DateTime> createdAt,
    });

class $$LocationSummariesTableFilterComposer
    extends Composer<_$LocationDatabase, $LocationSummariesTable> {
  $$LocationSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPoints => $composableBuilder(
    column: $table.totalPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get placesVisited => $composableBuilder(
    column: $table.placesVisited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mainLocations => $composableBuilder(
    column: $table.mainLocations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationSummariesTableOrderingComposer
    extends Composer<_$LocationDatabase, $LocationSummariesTable> {
  $$LocationSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPoints => $composableBuilder(
    column: $table.totalPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get placesVisited => $composableBuilder(
    column: $table.placesVisited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mainLocations => $composableBuilder(
    column: $table.mainLocations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationSummariesTableAnnotationComposer
    extends Composer<_$LocationDatabase, $LocationSummariesTable> {
  $$LocationSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get totalPoints => $composableBuilder(
    column: $table.totalPoints,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get placesVisited => $composableBuilder(
    column: $table.placesVisited,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mainLocations => $composableBuilder(
    column: $table.mainLocations,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activeMinutes => $composableBuilder(
    column: $table.activeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocationSummariesTableTableManager
    extends
        RootTableManager<
          _$LocationDatabase,
          $LocationSummariesTable,
          LocationSummary,
          $$LocationSummariesTableFilterComposer,
          $$LocationSummariesTableOrderingComposer,
          $$LocationSummariesTableAnnotationComposer,
          $$LocationSummariesTableCreateCompanionBuilder,
          $$LocationSummariesTableUpdateCompanionBuilder,
          (
            LocationSummary,
            BaseReferences<
              _$LocationDatabase,
              $LocationSummariesTable,
              LocationSummary
            >,
          ),
          LocationSummary,
          PrefetchHooks Function()
        > {
  $$LocationSummariesTableTableManager(
    _$LocationDatabase db,
    $LocationSummariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationSummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationSummariesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> totalPoints = const Value.absent(),
                Value<double> totalDistance = const Value.absent(),
                Value<int> placesVisited = const Value.absent(),
                Value<String> mainLocations = const Value.absent(),
                Value<int?> activeMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocationSummariesCompanion(
                id: id,
                date: date,
                totalPoints: totalPoints,
                totalDistance: totalDistance,
                placesVisited: placesVisited,
                mainLocations: mainLocations,
                activeMinutes: activeMinutes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required int totalPoints,
                required double totalDistance,
                required int placesVisited,
                required String mainLocations,
                Value<int?> activeMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocationSummariesCompanion.insert(
                id: id,
                date: date,
                totalPoints: totalPoints,
                totalDistance: totalDistance,
                placesVisited: placesVisited,
                mainLocations: mainLocations,
                activeMinutes: activeMinutes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationSummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocationDatabase,
      $LocationSummariesTable,
      LocationSummary,
      $$LocationSummariesTableFilterComposer,
      $$LocationSummariesTableOrderingComposer,
      $$LocationSummariesTableAnnotationComposer,
      $$LocationSummariesTableCreateCompanionBuilder,
      $$LocationSummariesTableUpdateCompanionBuilder,
      (
        LocationSummary,
        BaseReferences<
          _$LocationDatabase,
          $LocationSummariesTable,
          LocationSummary
        >,
      ),
      LocationSummary,
      PrefetchHooks Function()
    >;
typedef $$MovementDataTableCreateCompanionBuilder =
    MovementDataCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      required String state,
      required double averageMagnitude,
      required int sampleCount,
      required double stillPercentage,
      required double walkingPercentage,
      required double runningPercentage,
      required double drivingPercentage,
      Value<DateTime> createdAt,
    });
typedef $$MovementDataTableUpdateCompanionBuilder =
    MovementDataCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<String> state,
      Value<double> averageMagnitude,
      Value<int> sampleCount,
      Value<double> stillPercentage,
      Value<double> walkingPercentage,
      Value<double> runningPercentage,
      Value<double> drivingPercentage,
      Value<DateTime> createdAt,
    });

class $$MovementDataTableFilterComposer
    extends Composer<_$LocationDatabase, $MovementDataTable> {
  $$MovementDataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageMagnitude => $composableBuilder(
    column: $table.averageMagnitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stillPercentage => $composableBuilder(
    column: $table.stillPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get walkingPercentage => $composableBuilder(
    column: $table.walkingPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get runningPercentage => $composableBuilder(
    column: $table.runningPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get drivingPercentage => $composableBuilder(
    column: $table.drivingPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MovementDataTableOrderingComposer
    extends Composer<_$LocationDatabase, $MovementDataTable> {
  $$MovementDataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageMagnitude => $composableBuilder(
    column: $table.averageMagnitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stillPercentage => $composableBuilder(
    column: $table.stillPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get walkingPercentage => $composableBuilder(
    column: $table.walkingPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get runningPercentage => $composableBuilder(
    column: $table.runningPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get drivingPercentage => $composableBuilder(
    column: $table.drivingPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MovementDataTableAnnotationComposer
    extends Composer<_$LocationDatabase, $MovementDataTable> {
  $$MovementDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<double> get averageMagnitude => $composableBuilder(
    column: $table.averageMagnitude,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stillPercentage => $composableBuilder(
    column: $table.stillPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get walkingPercentage => $composableBuilder(
    column: $table.walkingPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get runningPercentage => $composableBuilder(
    column: $table.runningPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get drivingPercentage => $composableBuilder(
    column: $table.drivingPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MovementDataTableTableManager
    extends
        RootTableManager<
          _$LocationDatabase,
          $MovementDataTable,
          MovementDataData,
          $$MovementDataTableFilterComposer,
          $$MovementDataTableOrderingComposer,
          $$MovementDataTableAnnotationComposer,
          $$MovementDataTableCreateCompanionBuilder,
          $$MovementDataTableUpdateCompanionBuilder,
          (
            MovementDataData,
            BaseReferences<
              _$LocationDatabase,
              $MovementDataTable,
              MovementDataData
            >,
          ),
          MovementDataData,
          PrefetchHooks Function()
        > {
  $$MovementDataTableTableManager(
    _$LocationDatabase db,
    $MovementDataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovementDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovementDataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovementDataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<double> averageMagnitude = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<double> stillPercentage = const Value.absent(),
                Value<double> walkingPercentage = const Value.absent(),
                Value<double> runningPercentage = const Value.absent(),
                Value<double> drivingPercentage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MovementDataCompanion(
                id: id,
                timestamp: timestamp,
                state: state,
                averageMagnitude: averageMagnitude,
                sampleCount: sampleCount,
                stillPercentage: stillPercentage,
                walkingPercentage: walkingPercentage,
                runningPercentage: runningPercentage,
                drivingPercentage: drivingPercentage,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required String state,
                required double averageMagnitude,
                required int sampleCount,
                required double stillPercentage,
                required double walkingPercentage,
                required double runningPercentage,
                required double drivingPercentage,
                Value<DateTime> createdAt = const Value.absent(),
              }) => MovementDataCompanion.insert(
                id: id,
                timestamp: timestamp,
                state: state,
                averageMagnitude: averageMagnitude,
                sampleCount: sampleCount,
                stillPercentage: stillPercentage,
                walkingPercentage: walkingPercentage,
                runningPercentage: runningPercentage,
                drivingPercentage: drivingPercentage,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MovementDataTableProcessedTableManager =
    ProcessedTableManager<
      _$LocationDatabase,
      $MovementDataTable,
      MovementDataData,
      $$MovementDataTableFilterComposer,
      $$MovementDataTableOrderingComposer,
      $$MovementDataTableAnnotationComposer,
      $$MovementDataTableCreateCompanionBuilder,
      $$MovementDataTableUpdateCompanionBuilder,
      (
        MovementDataData,
        BaseReferences<
          _$LocationDatabase,
          $MovementDataTable,
          MovementDataData
        >,
      ),
      MovementDataData,
      PrefetchHooks Function()
    >;

class $LocationDatabaseManager {
  final _$LocationDatabase _db;
  $LocationDatabaseManager(this._db);
  $$LocationPointsTableTableManager get locationPoints =>
      $$LocationPointsTableTableManager(_db, _db.locationPoints);
  $$GeofenceAreasTableTableManager get geofenceAreas =>
      $$GeofenceAreasTableTableManager(_db, _db.geofenceAreas);
  $$GeofenceEventsTableTableManager get geofenceEvents =>
      $$GeofenceEventsTableTableManager(_db, _db.geofenceEvents);
  $$LocationNotesTableTableManager get locationNotes =>
      $$LocationNotesTableTableManager(_db, _db.locationNotes);
  $$LocationSummariesTableTableManager get locationSummaries =>
      $$LocationSummariesTableTableManager(_db, _db.locationSummaries);
  $$MovementDataTableTableManager get movementData =>
      $$MovementDataTableTableManager(_db, _db.movementData);
}
