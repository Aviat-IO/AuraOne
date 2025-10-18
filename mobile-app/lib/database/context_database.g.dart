// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_database.dart';

// ignore_for_file: type=lint
class $PeopleTable extends People with TableInfo<$PeopleTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationshipMeta = const VerificationMeta(
    'relationship',
  );
  @override
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
    'relationship',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faceEmbeddingMeta = const VerificationMeta(
    'faceEmbedding',
  );
  @override
  late final GeneratedColumn<Uint8List> faceEmbedding =
      GeneratedColumn<Uint8List>(
        'face_embedding',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _privacyLevelMeta = const VerificationMeta(
    'privacyLevel',
  );
  @override
  late final GeneratedColumn<int> privacyLevel = GeneratedColumn<int>(
    'privacy_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _firstSeenMeta = const VerificationMeta(
    'firstSeen',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeen = GeneratedColumn<DateTime>(
    'first_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoCountMeta = const VerificationMeta(
    'photoCount',
  );
  @override
  late final GeneratedColumn<int> photoCount = GeneratedColumn<int>(
    'photo_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    name,
    firstName,
    relationship,
    faceEmbedding,
    privacyLevel,
    firstSeen,
    lastSeen,
    photoCount,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('relationship')) {
      context.handle(
        _relationshipMeta,
        relationship.isAcceptableOrUnknown(
          data['relationship']!,
          _relationshipMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationshipMeta);
    }
    if (data.containsKey('face_embedding')) {
      context.handle(
        _faceEmbeddingMeta,
        faceEmbedding.isAcceptableOrUnknown(
          data['face_embedding']!,
          _faceEmbeddingMeta,
        ),
      );
    }
    if (data.containsKey('privacy_level')) {
      context.handle(
        _privacyLevelMeta,
        privacyLevel.isAcceptableOrUnknown(
          data['privacy_level']!,
          _privacyLevelMeta,
        ),
      );
    }
    if (data.containsKey('first_seen')) {
      context.handle(
        _firstSeenMeta,
        firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_firstSeenMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('photo_count')) {
      context.handle(
        _photoCountMeta,
        photoCount.isAcceptableOrUnknown(data['photo_count']!, _photoCountMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      relationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship'],
      )!,
      faceEmbedding: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}face_embedding'],
      ),
      privacyLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}privacy_level'],
      )!,
      firstSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_seen'],
      )!,
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen'],
      )!,
      photoCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photo_count'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
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
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final int id;
  final String name;
  final String firstName;
  final String relationship;
  final Uint8List? faceEmbedding;
  final int privacyLevel;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int photoCount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Person({
    required this.id,
    required this.name,
    required this.firstName,
    required this.relationship,
    this.faceEmbedding,
    required this.privacyLevel,
    required this.firstSeen,
    required this.lastSeen,
    required this.photoCount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['first_name'] = Variable<String>(firstName);
    map['relationship'] = Variable<String>(relationship);
    if (!nullToAbsent || faceEmbedding != null) {
      map['face_embedding'] = Variable<Uint8List>(faceEmbedding);
    }
    map['privacy_level'] = Variable<int>(privacyLevel);
    map['first_seen'] = Variable<DateTime>(firstSeen);
    map['last_seen'] = Variable<DateTime>(lastSeen);
    map['photo_count'] = Variable<int>(photoCount);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      name: Value(name),
      firstName: Value(firstName),
      relationship: Value(relationship),
      faceEmbedding: faceEmbedding == null && nullToAbsent
          ? const Value.absent()
          : Value(faceEmbedding),
      privacyLevel: Value(privacyLevel),
      firstSeen: Value(firstSeen),
      lastSeen: Value(lastSeen),
      photoCount: Value(photoCount),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      firstName: serializer.fromJson<String>(json['firstName']),
      relationship: serializer.fromJson<String>(json['relationship']),
      faceEmbedding: serializer.fromJson<Uint8List?>(json['faceEmbedding']),
      privacyLevel: serializer.fromJson<int>(json['privacyLevel']),
      firstSeen: serializer.fromJson<DateTime>(json['firstSeen']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
      photoCount: serializer.fromJson<int>(json['photoCount']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'firstName': serializer.toJson<String>(firstName),
      'relationship': serializer.toJson<String>(relationship),
      'faceEmbedding': serializer.toJson<Uint8List?>(faceEmbedding),
      'privacyLevel': serializer.toJson<int>(privacyLevel),
      'firstSeen': serializer.toJson<DateTime>(firstSeen),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'photoCount': serializer.toJson<int>(photoCount),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Person copyWith({
    int? id,
    String? name,
    String? firstName,
    String? relationship,
    Value<Uint8List?> faceEmbedding = const Value.absent(),
    int? privacyLevel,
    DateTime? firstSeen,
    DateTime? lastSeen,
    int? photoCount,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Person(
    id: id ?? this.id,
    name: name ?? this.name,
    firstName: firstName ?? this.firstName,
    relationship: relationship ?? this.relationship,
    faceEmbedding: faceEmbedding.present
        ? faceEmbedding.value
        : this.faceEmbedding,
    privacyLevel: privacyLevel ?? this.privacyLevel,
    firstSeen: firstSeen ?? this.firstSeen,
    lastSeen: lastSeen ?? this.lastSeen,
    photoCount: photoCount ?? this.photoCount,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Person copyWithCompanion(PeopleCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      faceEmbedding: data.faceEmbedding.present
          ? data.faceEmbedding.value
          : this.faceEmbedding,
      privacyLevel: data.privacyLevel.present
          ? data.privacyLevel.value
          : this.privacyLevel,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      photoCount: data.photoCount.present
          ? data.photoCount.value
          : this.photoCount,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('firstName: $firstName, ')
          ..write('relationship: $relationship, ')
          ..write('faceEmbedding: $faceEmbedding, ')
          ..write('privacyLevel: $privacyLevel, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('photoCount: $photoCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    firstName,
    relationship,
    $driftBlobEquality.hash(faceEmbedding),
    privacyLevel,
    firstSeen,
    lastSeen,
    photoCount,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.name == this.name &&
          other.firstName == this.firstName &&
          other.relationship == this.relationship &&
          $driftBlobEquality.equals(other.faceEmbedding, this.faceEmbedding) &&
          other.privacyLevel == this.privacyLevel &&
          other.firstSeen == this.firstSeen &&
          other.lastSeen == this.lastSeen &&
          other.photoCount == this.photoCount &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PeopleCompanion extends UpdateCompanion<Person> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> firstName;
  final Value<String> relationship;
  final Value<Uint8List?> faceEmbedding;
  final Value<int> privacyLevel;
  final Value<DateTime> firstSeen;
  final Value<DateTime> lastSeen;
  final Value<int> photoCount;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.firstName = const Value.absent(),
    this.relationship = const Value.absent(),
    this.faceEmbedding = const Value.absent(),
    this.privacyLevel = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.photoCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PeopleCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String firstName,
    required String relationship,
    this.faceEmbedding = const Value.absent(),
    this.privacyLevel = const Value.absent(),
    required DateTime firstSeen,
    required DateTime lastSeen,
    this.photoCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       firstName = Value(firstName),
       relationship = Value(relationship),
       firstSeen = Value(firstSeen),
       lastSeen = Value(lastSeen);
  static Insertable<Person> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? firstName,
    Expression<String>? relationship,
    Expression<Uint8List>? faceEmbedding,
    Expression<int>? privacyLevel,
    Expression<DateTime>? firstSeen,
    Expression<DateTime>? lastSeen,
    Expression<int>? photoCount,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (firstName != null) 'first_name': firstName,
      if (relationship != null) 'relationship': relationship,
      if (faceEmbedding != null) 'face_embedding': faceEmbedding,
      if (privacyLevel != null) 'privacy_level': privacyLevel,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (photoCount != null) 'photo_count': photoCount,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PeopleCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? firstName,
    Value<String>? relationship,
    Value<Uint8List?>? faceEmbedding,
    Value<int>? privacyLevel,
    Value<DateTime>? firstSeen,
    Value<DateTime>? lastSeen,
    Value<int>? photoCount,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      relationship: relationship ?? this.relationship,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      photoCount: photoCount ?? this.photoCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (faceEmbedding.present) {
      map['face_embedding'] = Variable<Uint8List>(faceEmbedding.value);
    }
    if (privacyLevel.present) {
      map['privacy_level'] = Variable<int>(privacyLevel.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<DateTime>(firstSeen.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (photoCount.present) {
      map['photo_count'] = Variable<int>(photoCount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('firstName: $firstName, ')
          ..write('relationship: $relationship, ')
          ..write('faceEmbedding: $faceEmbedding, ')
          ..write('privacyLevel: $privacyLevel, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('photoCount: $photoCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PlacesTable extends Places with TableInfo<$PlacesTable, Place> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
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
  static const VerificationMeta _radiusMetersMeta = const VerificationMeta(
    'radiusMeters',
  );
  @override
  late final GeneratedColumn<double> radiusMeters = GeneratedColumn<double>(
    'radius_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(100.0),
  );
  static const VerificationMeta _neighborhoodMeta = const VerificationMeta(
    'neighborhood',
  );
  @override
  late final GeneratedColumn<String> neighborhood = GeneratedColumn<String>(
    'neighborhood',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _significanceLevelMeta = const VerificationMeta(
    'significanceLevel',
  );
  @override
  late final GeneratedColumn<int> significanceLevel = GeneratedColumn<int>(
    'significance_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _visitCountMeta = const VerificationMeta(
    'visitCount',
  );
  @override
  late final GeneratedColumn<int> visitCount = GeneratedColumn<int>(
    'visit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _firstVisitMeta = const VerificationMeta(
    'firstVisit',
  );
  @override
  late final GeneratedColumn<DateTime> firstVisit = GeneratedColumn<DateTime>(
    'first_visit',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastVisitMeta = const VerificationMeta(
    'lastVisit',
  );
  @override
  late final GeneratedColumn<DateTime> lastVisit = GeneratedColumn<DateTime>(
    'last_visit',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalTimeMinutesMeta = const VerificationMeta(
    'totalTimeMinutes',
  );
  @override
  late final GeneratedColumn<int> totalTimeMinutes = GeneratedColumn<int>(
    'total_time_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customDescriptionMeta = const VerificationMeta(
    'customDescription',
  );
  @override
  late final GeneratedColumn<String> customDescription =
      GeneratedColumn<String>(
        'custom_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _excludeFromJournalMeta =
      const VerificationMeta('excludeFromJournal');
  @override
  late final GeneratedColumn<bool> excludeFromJournal = GeneratedColumn<bool>(
    'exclude_from_journal',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("exclude_from_journal" IN (0, 1))',
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
    name,
    category,
    latitude,
    longitude,
    radiusMeters,
    neighborhood,
    city,
    state,
    country,
    significanceLevel,
    visitCount,
    firstVisit,
    lastVisit,
    totalTimeMinutes,
    customDescription,
    excludeFromJournal,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'places';
  @override
  VerificationContext validateIntegrity(
    Insertable<Place> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
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
    if (data.containsKey('radius_meters')) {
      context.handle(
        _radiusMetersMeta,
        radiusMeters.isAcceptableOrUnknown(
          data['radius_meters']!,
          _radiusMetersMeta,
        ),
      );
    }
    if (data.containsKey('neighborhood')) {
      context.handle(
        _neighborhoodMeta,
        neighborhood.isAcceptableOrUnknown(
          data['neighborhood']!,
          _neighborhoodMeta,
        ),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('significance_level')) {
      context.handle(
        _significanceLevelMeta,
        significanceLevel.isAcceptableOrUnknown(
          data['significance_level']!,
          _significanceLevelMeta,
        ),
      );
    }
    if (data.containsKey('visit_count')) {
      context.handle(
        _visitCountMeta,
        visitCount.isAcceptableOrUnknown(data['visit_count']!, _visitCountMeta),
      );
    }
    if (data.containsKey('first_visit')) {
      context.handle(
        _firstVisitMeta,
        firstVisit.isAcceptableOrUnknown(data['first_visit']!, _firstVisitMeta),
      );
    } else if (isInserting) {
      context.missing(_firstVisitMeta);
    }
    if (data.containsKey('last_visit')) {
      context.handle(
        _lastVisitMeta,
        lastVisit.isAcceptableOrUnknown(data['last_visit']!, _lastVisitMeta),
      );
    } else if (isInserting) {
      context.missing(_lastVisitMeta);
    }
    if (data.containsKey('total_time_minutes')) {
      context.handle(
        _totalTimeMinutesMeta,
        totalTimeMinutes.isAcceptableOrUnknown(
          data['total_time_minutes']!,
          _totalTimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('custom_description')) {
      context.handle(
        _customDescriptionMeta,
        customDescription.isAcceptableOrUnknown(
          data['custom_description']!,
          _customDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('exclude_from_journal')) {
      context.handle(
        _excludeFromJournalMeta,
        excludeFromJournal.isAcceptableOrUnknown(
          data['exclude_from_journal']!,
          _excludeFromJournalMeta,
        ),
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
  Place map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Place(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      radiusMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_meters'],
      )!,
      neighborhood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}neighborhood'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      significanceLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}significance_level'],
      )!,
      visitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}visit_count'],
      )!,
      firstVisit: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_visit'],
      )!,
      lastVisit: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_visit'],
      )!,
      totalTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_time_minutes'],
      )!,
      customDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_description'],
      ),
      excludeFromJournal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exclude_from_journal'],
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
  $PlacesTable createAlias(String alias) {
    return $PlacesTable(attachedDatabase, alias);
  }
}

class Place extends DataClass implements Insertable<Place> {
  final int id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? country;
  final int significanceLevel;
  final int visitCount;
  final DateTime firstVisit;
  final DateTime lastVisit;
  final int totalTimeMinutes;
  final String? customDescription;
  final bool excludeFromJournal;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.neighborhood,
    this.city,
    this.state,
    this.country,
    required this.significanceLevel,
    required this.visitCount,
    required this.firstVisit,
    required this.lastVisit,
    required this.totalTimeMinutes,
    this.customDescription,
    required this.excludeFromJournal,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['radius_meters'] = Variable<double>(radiusMeters);
    if (!nullToAbsent || neighborhood != null) {
      map['neighborhood'] = Variable<String>(neighborhood);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    map['significance_level'] = Variable<int>(significanceLevel);
    map['visit_count'] = Variable<int>(visitCount);
    map['first_visit'] = Variable<DateTime>(firstVisit);
    map['last_visit'] = Variable<DateTime>(lastVisit);
    map['total_time_minutes'] = Variable<int>(totalTimeMinutes);
    if (!nullToAbsent || customDescription != null) {
      map['custom_description'] = Variable<String>(customDescription);
    }
    map['exclude_from_journal'] = Variable<bool>(excludeFromJournal);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlacesCompanion toCompanion(bool nullToAbsent) {
    return PlacesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      latitude: Value(latitude),
      longitude: Value(longitude),
      radiusMeters: Value(radiusMeters),
      neighborhood: neighborhood == null && nullToAbsent
          ? const Value.absent()
          : Value(neighborhood),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      state: state == null && nullToAbsent
          ? const Value.absent()
          : Value(state),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      significanceLevel: Value(significanceLevel),
      visitCount: Value(visitCount),
      firstVisit: Value(firstVisit),
      lastVisit: Value(lastVisit),
      totalTimeMinutes: Value(totalTimeMinutes),
      customDescription: customDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(customDescription),
      excludeFromJournal: Value(excludeFromJournal),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Place.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Place(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      radiusMeters: serializer.fromJson<double>(json['radiusMeters']),
      neighborhood: serializer.fromJson<String?>(json['neighborhood']),
      city: serializer.fromJson<String?>(json['city']),
      state: serializer.fromJson<String?>(json['state']),
      country: serializer.fromJson<String?>(json['country']),
      significanceLevel: serializer.fromJson<int>(json['significanceLevel']),
      visitCount: serializer.fromJson<int>(json['visitCount']),
      firstVisit: serializer.fromJson<DateTime>(json['firstVisit']),
      lastVisit: serializer.fromJson<DateTime>(json['lastVisit']),
      totalTimeMinutes: serializer.fromJson<int>(json['totalTimeMinutes']),
      customDescription: serializer.fromJson<String?>(
        json['customDescription'],
      ),
      excludeFromJournal: serializer.fromJson<bool>(json['excludeFromJournal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'radiusMeters': serializer.toJson<double>(radiusMeters),
      'neighborhood': serializer.toJson<String?>(neighborhood),
      'city': serializer.toJson<String?>(city),
      'state': serializer.toJson<String?>(state),
      'country': serializer.toJson<String?>(country),
      'significanceLevel': serializer.toJson<int>(significanceLevel),
      'visitCount': serializer.toJson<int>(visitCount),
      'firstVisit': serializer.toJson<DateTime>(firstVisit),
      'lastVisit': serializer.toJson<DateTime>(lastVisit),
      'totalTimeMinutes': serializer.toJson<int>(totalTimeMinutes),
      'customDescription': serializer.toJson<String?>(customDescription),
      'excludeFromJournal': serializer.toJson<bool>(excludeFromJournal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Place copyWith({
    int? id,
    String? name,
    String? category,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    Value<String?> neighborhood = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> state = const Value.absent(),
    Value<String?> country = const Value.absent(),
    int? significanceLevel,
    int? visitCount,
    DateTime? firstVisit,
    DateTime? lastVisit,
    int? totalTimeMinutes,
    Value<String?> customDescription = const Value.absent(),
    bool? excludeFromJournal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Place(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    neighborhood: neighborhood.present ? neighborhood.value : this.neighborhood,
    city: city.present ? city.value : this.city,
    state: state.present ? state.value : this.state,
    country: country.present ? country.value : this.country,
    significanceLevel: significanceLevel ?? this.significanceLevel,
    visitCount: visitCount ?? this.visitCount,
    firstVisit: firstVisit ?? this.firstVisit,
    lastVisit: lastVisit ?? this.lastVisit,
    totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
    customDescription: customDescription.present
        ? customDescription.value
        : this.customDescription,
    excludeFromJournal: excludeFromJournal ?? this.excludeFromJournal,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Place copyWithCompanion(PlacesCompanion data) {
    return Place(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      radiusMeters: data.radiusMeters.present
          ? data.radiusMeters.value
          : this.radiusMeters,
      neighborhood: data.neighborhood.present
          ? data.neighborhood.value
          : this.neighborhood,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      country: data.country.present ? data.country.value : this.country,
      significanceLevel: data.significanceLevel.present
          ? data.significanceLevel.value
          : this.significanceLevel,
      visitCount: data.visitCount.present
          ? data.visitCount.value
          : this.visitCount,
      firstVisit: data.firstVisit.present
          ? data.firstVisit.value
          : this.firstVisit,
      lastVisit: data.lastVisit.present ? data.lastVisit.value : this.lastVisit,
      totalTimeMinutes: data.totalTimeMinutes.present
          ? data.totalTimeMinutes.value
          : this.totalTimeMinutes,
      customDescription: data.customDescription.present
          ? data.customDescription.value
          : this.customDescription,
      excludeFromJournal: data.excludeFromJournal.present
          ? data.excludeFromJournal.value
          : this.excludeFromJournal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Place(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('neighborhood: $neighborhood, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('country: $country, ')
          ..write('significanceLevel: $significanceLevel, ')
          ..write('visitCount: $visitCount, ')
          ..write('firstVisit: $firstVisit, ')
          ..write('lastVisit: $lastVisit, ')
          ..write('totalTimeMinutes: $totalTimeMinutes, ')
          ..write('customDescription: $customDescription, ')
          ..write('excludeFromJournal: $excludeFromJournal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    latitude,
    longitude,
    radiusMeters,
    neighborhood,
    city,
    state,
    country,
    significanceLevel,
    visitCount,
    firstVisit,
    lastVisit,
    totalTimeMinutes,
    customDescription,
    excludeFromJournal,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Place &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.radiusMeters == this.radiusMeters &&
          other.neighborhood == this.neighborhood &&
          other.city == this.city &&
          other.state == this.state &&
          other.country == this.country &&
          other.significanceLevel == this.significanceLevel &&
          other.visitCount == this.visitCount &&
          other.firstVisit == this.firstVisit &&
          other.lastVisit == this.lastVisit &&
          other.totalTimeMinutes == this.totalTimeMinutes &&
          other.customDescription == this.customDescription &&
          other.excludeFromJournal == this.excludeFromJournal &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlacesCompanion extends UpdateCompanion<Place> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> category;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> radiusMeters;
  final Value<String?> neighborhood;
  final Value<String?> city;
  final Value<String?> state;
  final Value<String?> country;
  final Value<int> significanceLevel;
  final Value<int> visitCount;
  final Value<DateTime> firstVisit;
  final Value<DateTime> lastVisit;
  final Value<int> totalTimeMinutes;
  final Value<String?> customDescription;
  final Value<bool> excludeFromJournal;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PlacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radiusMeters = const Value.absent(),
    this.neighborhood = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.country = const Value.absent(),
    this.significanceLevel = const Value.absent(),
    this.visitCount = const Value.absent(),
    this.firstVisit = const Value.absent(),
    this.lastVisit = const Value.absent(),
    this.totalTimeMinutes = const Value.absent(),
    this.customDescription = const Value.absent(),
    this.excludeFromJournal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlacesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String category,
    required double latitude,
    required double longitude,
    this.radiusMeters = const Value.absent(),
    this.neighborhood = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.country = const Value.absent(),
    this.significanceLevel = const Value.absent(),
    this.visitCount = const Value.absent(),
    required DateTime firstVisit,
    required DateTime lastVisit,
    this.totalTimeMinutes = const Value.absent(),
    this.customDescription = const Value.absent(),
    this.excludeFromJournal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       category = Value(category),
       latitude = Value(latitude),
       longitude = Value(longitude),
       firstVisit = Value(firstVisit),
       lastVisit = Value(lastVisit);
  static Insertable<Place> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? radiusMeters,
    Expression<String>? neighborhood,
    Expression<String>? city,
    Expression<String>? state,
    Expression<String>? country,
    Expression<int>? significanceLevel,
    Expression<int>? visitCount,
    Expression<DateTime>? firstVisit,
    Expression<DateTime>? lastVisit,
    Expression<int>? totalTimeMinutes,
    Expression<String>? customDescription,
    Expression<bool>? excludeFromJournal,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radius_meters': radiusMeters,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (significanceLevel != null) 'significance_level': significanceLevel,
      if (visitCount != null) 'visit_count': visitCount,
      if (firstVisit != null) 'first_visit': firstVisit,
      if (lastVisit != null) 'last_visit': lastVisit,
      if (totalTimeMinutes != null) 'total_time_minutes': totalTimeMinutes,
      if (customDescription != null) 'custom_description': customDescription,
      if (excludeFromJournal != null)
        'exclude_from_journal': excludeFromJournal,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlacesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? category,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? radiusMeters,
    Value<String?>? neighborhood,
    Value<String?>? city,
    Value<String?>? state,
    Value<String?>? country,
    Value<int>? significanceLevel,
    Value<int>? visitCount,
    Value<DateTime>? firstVisit,
    Value<DateTime>? lastVisit,
    Value<int>? totalTimeMinutes,
    Value<String?>? customDescription,
    Value<bool>? excludeFromJournal,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PlacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      significanceLevel: significanceLevel ?? this.significanceLevel,
      visitCount: visitCount ?? this.visitCount,
      firstVisit: firstVisit ?? this.firstVisit,
      lastVisit: lastVisit ?? this.lastVisit,
      totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
      customDescription: customDescription ?? this.customDescription,
      excludeFromJournal: excludeFromJournal ?? this.excludeFromJournal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (radiusMeters.present) {
      map['radius_meters'] = Variable<double>(radiusMeters.value);
    }
    if (neighborhood.present) {
      map['neighborhood'] = Variable<String>(neighborhood.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (significanceLevel.present) {
      map['significance_level'] = Variable<int>(significanceLevel.value);
    }
    if (visitCount.present) {
      map['visit_count'] = Variable<int>(visitCount.value);
    }
    if (firstVisit.present) {
      map['first_visit'] = Variable<DateTime>(firstVisit.value);
    }
    if (lastVisit.present) {
      map['last_visit'] = Variable<DateTime>(lastVisit.value);
    }
    if (totalTimeMinutes.present) {
      map['total_time_minutes'] = Variable<int>(totalTimeMinutes.value);
    }
    if (customDescription.present) {
      map['custom_description'] = Variable<String>(customDescription.value);
    }
    if (excludeFromJournal.present) {
      map['exclude_from_journal'] = Variable<bool>(excludeFromJournal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('neighborhood: $neighborhood, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('country: $country, ')
          ..write('significanceLevel: $significanceLevel, ')
          ..write('visitCount: $visitCount, ')
          ..write('firstVisit: $firstVisit, ')
          ..write('lastVisit: $lastVisit, ')
          ..write('totalTimeMinutes: $totalTimeMinutes, ')
          ..write('customDescription: $customDescription, ')
          ..write('excludeFromJournal: $excludeFromJournal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ActivityPatternsTable extends ActivityPatterns
    with TableInfo<$ActivityPatternsTable, ActivityPattern> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityPatternsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _placeIdMeta = const VerificationMeta(
    'placeId',
  );
  @override
  late final GeneratedColumn<int> placeId = GeneratedColumn<int>(
    'place_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES places (id)',
    ),
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hourOfDayMeta = const VerificationMeta(
    'hourOfDay',
  );
  @override
  late final GeneratedColumn<int> hourOfDay = GeneratedColumn<int>(
    'hour_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityTypeMeta = const VerificationMeta(
    'activityType',
  );
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
    'activity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<int> frequency = GeneratedColumn<int>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastOccurrenceMeta = const VerificationMeta(
    'lastOccurrence',
  );
  @override
  late final GeneratedColumn<DateTime> lastOccurrence =
      GeneratedColumn<DateTime>(
        'last_occurrence',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
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
    placeId,
    dayOfWeek,
    hourOfDay,
    activityType,
    frequency,
    lastOccurrence,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_patterns';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityPattern> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('place_id')) {
      context.handle(
        _placeIdMeta,
        placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta),
      );
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('hour_of_day')) {
      context.handle(
        _hourOfDayMeta,
        hourOfDay.isAcceptableOrUnknown(data['hour_of_day']!, _hourOfDayMeta),
      );
    } else if (isInserting) {
      context.missing(_hourOfDayMeta);
    }
    if (data.containsKey('activity_type')) {
      context.handle(
        _activityTypeMeta,
        activityType.isAcceptableOrUnknown(
          data['activity_type']!,
          _activityTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityTypeMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('last_occurrence')) {
      context.handle(
        _lastOccurrenceMeta,
        lastOccurrence.isAcceptableOrUnknown(
          data['last_occurrence']!,
          _lastOccurrenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastOccurrenceMeta);
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
  ActivityPattern map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityPattern(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      placeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}place_id'],
      ),
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      hourOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour_of_day'],
      )!,
      activityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_type'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frequency'],
      )!,
      lastOccurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_occurrence'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ActivityPatternsTable createAlias(String alias) {
    return $ActivityPatternsTable(attachedDatabase, alias);
  }
}

class ActivityPattern extends DataClass implements Insertable<ActivityPattern> {
  final int id;
  final int? placeId;
  final int dayOfWeek;
  final int hourOfDay;
  final String activityType;
  final int frequency;
  final DateTime lastOccurrence;
  final DateTime createdAt;
  const ActivityPattern({
    required this.id,
    this.placeId,
    required this.dayOfWeek,
    required this.hourOfDay,
    required this.activityType,
    required this.frequency,
    required this.lastOccurrence,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || placeId != null) {
      map['place_id'] = Variable<int>(placeId);
    }
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['hour_of_day'] = Variable<int>(hourOfDay);
    map['activity_type'] = Variable<String>(activityType);
    map['frequency'] = Variable<int>(frequency);
    map['last_occurrence'] = Variable<DateTime>(lastOccurrence);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ActivityPatternsCompanion toCompanion(bool nullToAbsent) {
    return ActivityPatternsCompanion(
      id: Value(id),
      placeId: placeId == null && nullToAbsent
          ? const Value.absent()
          : Value(placeId),
      dayOfWeek: Value(dayOfWeek),
      hourOfDay: Value(hourOfDay),
      activityType: Value(activityType),
      frequency: Value(frequency),
      lastOccurrence: Value(lastOccurrence),
      createdAt: Value(createdAt),
    );
  }

  factory ActivityPattern.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityPattern(
      id: serializer.fromJson<int>(json['id']),
      placeId: serializer.fromJson<int?>(json['placeId']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      hourOfDay: serializer.fromJson<int>(json['hourOfDay']),
      activityType: serializer.fromJson<String>(json['activityType']),
      frequency: serializer.fromJson<int>(json['frequency']),
      lastOccurrence: serializer.fromJson<DateTime>(json['lastOccurrence']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'placeId': serializer.toJson<int?>(placeId),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'hourOfDay': serializer.toJson<int>(hourOfDay),
      'activityType': serializer.toJson<String>(activityType),
      'frequency': serializer.toJson<int>(frequency),
      'lastOccurrence': serializer.toJson<DateTime>(lastOccurrence),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ActivityPattern copyWith({
    int? id,
    Value<int?> placeId = const Value.absent(),
    int? dayOfWeek,
    int? hourOfDay,
    String? activityType,
    int? frequency,
    DateTime? lastOccurrence,
    DateTime? createdAt,
  }) => ActivityPattern(
    id: id ?? this.id,
    placeId: placeId.present ? placeId.value : this.placeId,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    hourOfDay: hourOfDay ?? this.hourOfDay,
    activityType: activityType ?? this.activityType,
    frequency: frequency ?? this.frequency,
    lastOccurrence: lastOccurrence ?? this.lastOccurrence,
    createdAt: createdAt ?? this.createdAt,
  );
  ActivityPattern copyWithCompanion(ActivityPatternsCompanion data) {
    return ActivityPattern(
      id: data.id.present ? data.id.value : this.id,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      hourOfDay: data.hourOfDay.present ? data.hourOfDay.value : this.hourOfDay,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      lastOccurrence: data.lastOccurrence.present
          ? data.lastOccurrence.value
          : this.lastOccurrence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityPattern(')
          ..write('id: $id, ')
          ..write('placeId: $placeId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('hourOfDay: $hourOfDay, ')
          ..write('activityType: $activityType, ')
          ..write('frequency: $frequency, ')
          ..write('lastOccurrence: $lastOccurrence, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    placeId,
    dayOfWeek,
    hourOfDay,
    activityType,
    frequency,
    lastOccurrence,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityPattern &&
          other.id == this.id &&
          other.placeId == this.placeId &&
          other.dayOfWeek == this.dayOfWeek &&
          other.hourOfDay == this.hourOfDay &&
          other.activityType == this.activityType &&
          other.frequency == this.frequency &&
          other.lastOccurrence == this.lastOccurrence &&
          other.createdAt == this.createdAt);
}

class ActivityPatternsCompanion extends UpdateCompanion<ActivityPattern> {
  final Value<int> id;
  final Value<int?> placeId;
  final Value<int> dayOfWeek;
  final Value<int> hourOfDay;
  final Value<String> activityType;
  final Value<int> frequency;
  final Value<DateTime> lastOccurrence;
  final Value<DateTime> createdAt;
  const ActivityPatternsCompanion({
    this.id = const Value.absent(),
    this.placeId = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.hourOfDay = const Value.absent(),
    this.activityType = const Value.absent(),
    this.frequency = const Value.absent(),
    this.lastOccurrence = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ActivityPatternsCompanion.insert({
    this.id = const Value.absent(),
    this.placeId = const Value.absent(),
    required int dayOfWeek,
    required int hourOfDay,
    required String activityType,
    this.frequency = const Value.absent(),
    required DateTime lastOccurrence,
    this.createdAt = const Value.absent(),
  }) : dayOfWeek = Value(dayOfWeek),
       hourOfDay = Value(hourOfDay),
       activityType = Value(activityType),
       lastOccurrence = Value(lastOccurrence);
  static Insertable<ActivityPattern> custom({
    Expression<int>? id,
    Expression<int>? placeId,
    Expression<int>? dayOfWeek,
    Expression<int>? hourOfDay,
    Expression<String>? activityType,
    Expression<int>? frequency,
    Expression<DateTime>? lastOccurrence,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (placeId != null) 'place_id': placeId,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (hourOfDay != null) 'hour_of_day': hourOfDay,
      if (activityType != null) 'activity_type': activityType,
      if (frequency != null) 'frequency': frequency,
      if (lastOccurrence != null) 'last_occurrence': lastOccurrence,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ActivityPatternsCompanion copyWith({
    Value<int>? id,
    Value<int?>? placeId,
    Value<int>? dayOfWeek,
    Value<int>? hourOfDay,
    Value<String>? activityType,
    Value<int>? frequency,
    Value<DateTime>? lastOccurrence,
    Value<DateTime>? createdAt,
  }) {
    return ActivityPatternsCompanion(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hourOfDay: hourOfDay ?? this.hourOfDay,
      activityType: activityType ?? this.activityType,
      frequency: frequency ?? this.frequency,
      lastOccurrence: lastOccurrence ?? this.lastOccurrence,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<int>(placeId.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (hourOfDay.present) {
      map['hour_of_day'] = Variable<int>(hourOfDay.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<int>(frequency.value);
    }
    if (lastOccurrence.present) {
      map['last_occurrence'] = Variable<DateTime>(lastOccurrence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityPatternsCompanion(')
          ..write('id: $id, ')
          ..write('placeId: $placeId, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('hourOfDay: $hourOfDay, ')
          ..write('activityType: $activityType, ')
          ..write('frequency: $frequency, ')
          ..write('lastOccurrence: $lastOccurrence, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $JournalPreferencesTable extends JournalPreferences
    with TableInfo<$JournalPreferencesTable, JournalPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalPreferencesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [id, key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
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
  JournalPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalPreference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $JournalPreferencesTable createAlias(String alias) {
    return $JournalPreferencesTable(attachedDatabase, alias);
  }
}

class JournalPreference extends DataClass
    implements Insertable<JournalPreference> {
  final int id;
  final String key;
  final String value;
  final DateTime updatedAt;
  const JournalPreference({
    required this.id,
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  JournalPreferencesCompanion toCompanion(bool nullToAbsent) {
    return JournalPreferencesCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory JournalPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalPreference(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  JournalPreference copyWith({
    int? id,
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => JournalPreference(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  JournalPreference copyWithCompanion(JournalPreferencesCompanion data) {
    return JournalPreference(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalPreference(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalPreference &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class JournalPreferencesCompanion extends UpdateCompanion<JournalPreference> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  const JournalPreferencesCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  JournalPreferencesCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<JournalPreference> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  JournalPreferencesCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
  }) {
    return JournalPreferencesCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BleDeviceRegistriesTable extends BleDeviceRegistries
    with TableInfo<$BleDeviceRegistriesTable, BleDeviceRegistry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BleDeviceRegistriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _deviceTypeMeta = const VerificationMeta(
    'deviceType',
  );
  @override
  late final GeneratedColumn<String> deviceType = GeneratedColumn<String>(
    'device_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstSeenMeta = const VerificationMeta(
    'firstSeen',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeen = GeneratedColumn<DateTime>(
    'first_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encounterCountMeta = const VerificationMeta(
    'encounterCount',
  );
  @override
  late final GeneratedColumn<int> encounterCount = GeneratedColumn<int>(
    'encounter_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    deviceId,
    personId,
    deviceType,
    deviceName,
    firstSeen,
    lastSeen,
    encounterCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ble_device_registries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BleDeviceRegistry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('device_type')) {
      context.handle(
        _deviceTypeMeta,
        deviceType.isAcceptableOrUnknown(data['device_type']!, _deviceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceTypeMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('first_seen')) {
      context.handle(
        _firstSeenMeta,
        firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_firstSeenMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('encounter_count')) {
      context.handle(
        _encounterCountMeta,
        encounterCount.isAcceptableOrUnknown(
          data['encounter_count']!,
          _encounterCountMeta,
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
  BleDeviceRegistry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BleDeviceRegistry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      deviceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_type'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      ),
      firstSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_seen'],
      )!,
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen'],
      )!,
      encounterCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}encounter_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BleDeviceRegistriesTable createAlias(String alias) {
    return $BleDeviceRegistriesTable(attachedDatabase, alias);
  }
}

class BleDeviceRegistry extends DataClass
    implements Insertable<BleDeviceRegistry> {
  final int id;
  final String deviceId;
  final int? personId;
  final String deviceType;
  final String? deviceName;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int encounterCount;
  final DateTime createdAt;
  const BleDeviceRegistry({
    required this.id,
    required this.deviceId,
    this.personId,
    required this.deviceType,
    this.deviceName,
    required this.firstSeen,
    required this.lastSeen,
    required this.encounterCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    map['device_type'] = Variable<String>(deviceType);
    if (!nullToAbsent || deviceName != null) {
      map['device_name'] = Variable<String>(deviceName);
    }
    map['first_seen'] = Variable<DateTime>(firstSeen);
    map['last_seen'] = Variable<DateTime>(lastSeen);
    map['encounter_count'] = Variable<int>(encounterCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BleDeviceRegistriesCompanion toCompanion(bool nullToAbsent) {
    return BleDeviceRegistriesCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      deviceType: Value(deviceType),
      deviceName: deviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceName),
      firstSeen: Value(firstSeen),
      lastSeen: Value(lastSeen),
      encounterCount: Value(encounterCount),
      createdAt: Value(createdAt),
    );
  }

  factory BleDeviceRegistry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BleDeviceRegistry(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      personId: serializer.fromJson<int?>(json['personId']),
      deviceType: serializer.fromJson<String>(json['deviceType']),
      deviceName: serializer.fromJson<String?>(json['deviceName']),
      firstSeen: serializer.fromJson<DateTime>(json['firstSeen']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
      encounterCount: serializer.fromJson<int>(json['encounterCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'personId': serializer.toJson<int?>(personId),
      'deviceType': serializer.toJson<String>(deviceType),
      'deviceName': serializer.toJson<String?>(deviceName),
      'firstSeen': serializer.toJson<DateTime>(firstSeen),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'encounterCount': serializer.toJson<int>(encounterCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BleDeviceRegistry copyWith({
    int? id,
    String? deviceId,
    Value<int?> personId = const Value.absent(),
    String? deviceType,
    Value<String?> deviceName = const Value.absent(),
    DateTime? firstSeen,
    DateTime? lastSeen,
    int? encounterCount,
    DateTime? createdAt,
  }) => BleDeviceRegistry(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    personId: personId.present ? personId.value : this.personId,
    deviceType: deviceType ?? this.deviceType,
    deviceName: deviceName.present ? deviceName.value : this.deviceName,
    firstSeen: firstSeen ?? this.firstSeen,
    lastSeen: lastSeen ?? this.lastSeen,
    encounterCount: encounterCount ?? this.encounterCount,
    createdAt: createdAt ?? this.createdAt,
  );
  BleDeviceRegistry copyWithCompanion(BleDeviceRegistriesCompanion data) {
    return BleDeviceRegistry(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      personId: data.personId.present ? data.personId.value : this.personId,
      deviceType: data.deviceType.present
          ? data.deviceType.value
          : this.deviceType,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      encounterCount: data.encounterCount.present
          ? data.encounterCount.value
          : this.encounterCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BleDeviceRegistry(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('personId: $personId, ')
          ..write('deviceType: $deviceType, ')
          ..write('deviceName: $deviceName, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('encounterCount: $encounterCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    personId,
    deviceType,
    deviceName,
    firstSeen,
    lastSeen,
    encounterCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BleDeviceRegistry &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.personId == this.personId &&
          other.deviceType == this.deviceType &&
          other.deviceName == this.deviceName &&
          other.firstSeen == this.firstSeen &&
          other.lastSeen == this.lastSeen &&
          other.encounterCount == this.encounterCount &&
          other.createdAt == this.createdAt);
}

class BleDeviceRegistriesCompanion extends UpdateCompanion<BleDeviceRegistry> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<int?> personId;
  final Value<String> deviceType;
  final Value<String?> deviceName;
  final Value<DateTime> firstSeen;
  final Value<DateTime> lastSeen;
  final Value<int> encounterCount;
  final Value<DateTime> createdAt;
  const BleDeviceRegistriesCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.personId = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.encounterCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BleDeviceRegistriesCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    this.personId = const Value.absent(),
    required String deviceType,
    this.deviceName = const Value.absent(),
    required DateTime firstSeen,
    required DateTime lastSeen,
    this.encounterCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : deviceId = Value(deviceId),
       deviceType = Value(deviceType),
       firstSeen = Value(firstSeen),
       lastSeen = Value(lastSeen);
  static Insertable<BleDeviceRegistry> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<int>? personId,
    Expression<String>? deviceType,
    Expression<String>? deviceName,
    Expression<DateTime>? firstSeen,
    Expression<DateTime>? lastSeen,
    Expression<int>? encounterCount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (personId != null) 'person_id': personId,
      if (deviceType != null) 'device_type': deviceType,
      if (deviceName != null) 'device_name': deviceName,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (encounterCount != null) 'encounter_count': encounterCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BleDeviceRegistriesCompanion copyWith({
    Value<int>? id,
    Value<String>? deviceId,
    Value<int?>? personId,
    Value<String>? deviceType,
    Value<String?>? deviceName,
    Value<DateTime>? firstSeen,
    Value<DateTime>? lastSeen,
    Value<int>? encounterCount,
    Value<DateTime>? createdAt,
  }) {
    return BleDeviceRegistriesCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      personId: personId ?? this.personId,
      deviceType: deviceType ?? this.deviceType,
      deviceName: deviceName ?? this.deviceName,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      encounterCount: encounterCount ?? this.encounterCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (deviceType.present) {
      map['device_type'] = Variable<String>(deviceType.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<DateTime>(firstSeen.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (encounterCount.present) {
      map['encounter_count'] = Variable<int>(encounterCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BleDeviceRegistriesCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('personId: $personId, ')
          ..write('deviceType: $deviceType, ')
          ..write('deviceName: $deviceName, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('encounterCount: $encounterCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OccasionsTable extends Occasions
    with TableInfo<$OccasionsTable, Occasion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccasionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _occasionTypeMeta = const VerificationMeta(
    'occasionType',
  );
  @override
  late final GeneratedColumn<String> occasionType = GeneratedColumn<String>(
    'occasion_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recurringMeta = const VerificationMeta(
    'recurring',
  );
  @override
  late final GeneratedColumn<bool> recurring = GeneratedColumn<bool>(
    'recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    name,
    date,
    personId,
    occasionType,
    recurring,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occasions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Occasion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('occasion_type')) {
      context.handle(
        _occasionTypeMeta,
        occasionType.isAcceptableOrUnknown(
          data['occasion_type']!,
          _occasionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occasionTypeMeta);
    }
    if (data.containsKey('recurring')) {
      context.handle(
        _recurringMeta,
        recurring.isAcceptableOrUnknown(data['recurring']!, _recurringMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  Occasion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Occasion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      occasionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occasion_type'],
      )!,
      recurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recurring'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OccasionsTable createAlias(String alias) {
    return $OccasionsTable(attachedDatabase, alias);
  }
}

class Occasion extends DataClass implements Insertable<Occasion> {
  final int id;
  final String name;
  final DateTime date;
  final int? personId;
  final String occasionType;
  final bool recurring;
  final String? notes;
  final DateTime createdAt;
  const Occasion({
    required this.id,
    required this.name,
    required this.date,
    this.personId,
    required this.occasionType,
    required this.recurring,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    map['occasion_type'] = Variable<String>(occasionType);
    map['recurring'] = Variable<bool>(recurring);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OccasionsCompanion toCompanion(bool nullToAbsent) {
    return OccasionsCompanion(
      id: Value(id),
      name: Value(name),
      date: Value(date),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      occasionType: Value(occasionType),
      recurring: Value(recurring),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Occasion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Occasion(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      date: serializer.fromJson<DateTime>(json['date']),
      personId: serializer.fromJson<int?>(json['personId']),
      occasionType: serializer.fromJson<String>(json['occasionType']),
      recurring: serializer.fromJson<bool>(json['recurring']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'date': serializer.toJson<DateTime>(date),
      'personId': serializer.toJson<int?>(personId),
      'occasionType': serializer.toJson<String>(occasionType),
      'recurring': serializer.toJson<bool>(recurring),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Occasion copyWith({
    int? id,
    String? name,
    DateTime? date,
    Value<int?> personId = const Value.absent(),
    String? occasionType,
    bool? recurring,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => Occasion(
    id: id ?? this.id,
    name: name ?? this.name,
    date: date ?? this.date,
    personId: personId.present ? personId.value : this.personId,
    occasionType: occasionType ?? this.occasionType,
    recurring: recurring ?? this.recurring,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  Occasion copyWithCompanion(OccasionsCompanion data) {
    return Occasion(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      date: data.date.present ? data.date.value : this.date,
      personId: data.personId.present ? data.personId.value : this.personId,
      occasionType: data.occasionType.present
          ? data.occasionType.value
          : this.occasionType,
      recurring: data.recurring.present ? data.recurring.value : this.recurring,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Occasion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('personId: $personId, ')
          ..write('occasionType: $occasionType, ')
          ..write('recurring: $recurring, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    date,
    personId,
    occasionType,
    recurring,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Occasion &&
          other.id == this.id &&
          other.name == this.name &&
          other.date == this.date &&
          other.personId == this.personId &&
          other.occasionType == this.occasionType &&
          other.recurring == this.recurring &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class OccasionsCompanion extends UpdateCompanion<Occasion> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> date;
  final Value<int?> personId;
  final Value<String> occasionType;
  final Value<bool> recurring;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const OccasionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.date = const Value.absent(),
    this.personId = const Value.absent(),
    this.occasionType = const Value.absent(),
    this.recurring = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OccasionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime date,
    this.personId = const Value.absent(),
    required String occasionType,
    this.recurring = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       date = Value(date),
       occasionType = Value(occasionType);
  static Insertable<Occasion> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? date,
    Expression<int>? personId,
    Expression<String>? occasionType,
    Expression<bool>? recurring,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (personId != null) 'person_id': personId,
      if (occasionType != null) 'occasion_type': occasionType,
      if (recurring != null) 'recurring': recurring,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OccasionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? date,
    Value<int?>? personId,
    Value<String>? occasionType,
    Value<bool>? recurring,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return OccasionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      personId: personId ?? this.personId,
      occasionType: occasionType ?? this.occasionType,
      recurring: recurring ?? this.recurring,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (occasionType.present) {
      map['occasion_type'] = Variable<String>(occasionType.value);
    }
    if (recurring.present) {
      map['recurring'] = Variable<bool>(recurring.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccasionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('personId: $personId, ')
          ..write('occasionType: $occasionType, ')
          ..write('recurring: $recurring, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PhotoPersonLinksTable extends PhotoPersonLinks
    with TableInfo<$PhotoPersonLinksTable, PhotoPersonLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoPersonLinksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faceIndexMeta = const VerificationMeta(
    'faceIndex',
  );
  @override
  late final GeneratedColumn<int> faceIndex = GeneratedColumn<int>(
    'face_index',
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
    photoId,
    personId,
    confidence,
    faceIndex,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_person_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoPersonLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('face_index')) {
      context.handle(
        _faceIndexMeta,
        faceIndex.isAcceptableOrUnknown(data['face_index']!, _faceIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_faceIndexMeta);
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
  PhotoPersonLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoPersonLink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      faceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}face_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PhotoPersonLinksTable createAlias(String alias) {
    return $PhotoPersonLinksTable(attachedDatabase, alias);
  }
}

class PhotoPersonLink extends DataClass implements Insertable<PhotoPersonLink> {
  final int id;
  final String photoId;
  final int personId;
  final double confidence;
  final int faceIndex;
  final DateTime createdAt;
  const PhotoPersonLink({
    required this.id,
    required this.photoId,
    required this.personId,
    required this.confidence,
    required this.faceIndex,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['photo_id'] = Variable<String>(photoId);
    map['person_id'] = Variable<int>(personId);
    map['confidence'] = Variable<double>(confidence);
    map['face_index'] = Variable<int>(faceIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PhotoPersonLinksCompanion toCompanion(bool nullToAbsent) {
    return PhotoPersonLinksCompanion(
      id: Value(id),
      photoId: Value(photoId),
      personId: Value(personId),
      confidence: Value(confidence),
      faceIndex: Value(faceIndex),
      createdAt: Value(createdAt),
    );
  }

  factory PhotoPersonLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoPersonLink(
      id: serializer.fromJson<int>(json['id']),
      photoId: serializer.fromJson<String>(json['photoId']),
      personId: serializer.fromJson<int>(json['personId']),
      confidence: serializer.fromJson<double>(json['confidence']),
      faceIndex: serializer.fromJson<int>(json['faceIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'photoId': serializer.toJson<String>(photoId),
      'personId': serializer.toJson<int>(personId),
      'confidence': serializer.toJson<double>(confidence),
      'faceIndex': serializer.toJson<int>(faceIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PhotoPersonLink copyWith({
    int? id,
    String? photoId,
    int? personId,
    double? confidence,
    int? faceIndex,
    DateTime? createdAt,
  }) => PhotoPersonLink(
    id: id ?? this.id,
    photoId: photoId ?? this.photoId,
    personId: personId ?? this.personId,
    confidence: confidence ?? this.confidence,
    faceIndex: faceIndex ?? this.faceIndex,
    createdAt: createdAt ?? this.createdAt,
  );
  PhotoPersonLink copyWithCompanion(PhotoPersonLinksCompanion data) {
    return PhotoPersonLink(
      id: data.id.present ? data.id.value : this.id,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      personId: data.personId.present ? data.personId.value : this.personId,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      faceIndex: data.faceIndex.present ? data.faceIndex.value : this.faceIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoPersonLink(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('personId: $personId, ')
          ..write('confidence: $confidence, ')
          ..write('faceIndex: $faceIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, photoId, personId, confidence, faceIndex, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoPersonLink &&
          other.id == this.id &&
          other.photoId == this.photoId &&
          other.personId == this.personId &&
          other.confidence == this.confidence &&
          other.faceIndex == this.faceIndex &&
          other.createdAt == this.createdAt);
}

class PhotoPersonLinksCompanion extends UpdateCompanion<PhotoPersonLink> {
  final Value<int> id;
  final Value<String> photoId;
  final Value<int> personId;
  final Value<double> confidence;
  final Value<int> faceIndex;
  final Value<DateTime> createdAt;
  const PhotoPersonLinksCompanion({
    this.id = const Value.absent(),
    this.photoId = const Value.absent(),
    this.personId = const Value.absent(),
    this.confidence = const Value.absent(),
    this.faceIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PhotoPersonLinksCompanion.insert({
    this.id = const Value.absent(),
    required String photoId,
    required int personId,
    required double confidence,
    required int faceIndex,
    this.createdAt = const Value.absent(),
  }) : photoId = Value(photoId),
       personId = Value(personId),
       confidence = Value(confidence),
       faceIndex = Value(faceIndex);
  static Insertable<PhotoPersonLink> custom({
    Expression<int>? id,
    Expression<String>? photoId,
    Expression<int>? personId,
    Expression<double>? confidence,
    Expression<int>? faceIndex,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (photoId != null) 'photo_id': photoId,
      if (personId != null) 'person_id': personId,
      if (confidence != null) 'confidence': confidence,
      if (faceIndex != null) 'face_index': faceIndex,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PhotoPersonLinksCompanion copyWith({
    Value<int>? id,
    Value<String>? photoId,
    Value<int>? personId,
    Value<double>? confidence,
    Value<int>? faceIndex,
    Value<DateTime>? createdAt,
  }) {
    return PhotoPersonLinksCompanion(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      personId: personId ?? this.personId,
      confidence: confidence ?? this.confidence,
      faceIndex: faceIndex ?? this.faceIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (faceIndex.present) {
      map['face_index'] = Variable<int>(faceIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoPersonLinksCompanion(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('personId: $personId, ')
          ..write('confidence: $confidence, ')
          ..write('faceIndex: $faceIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContextDatabase extends GeneratedDatabase {
  _$ContextDatabase(QueryExecutor e) : super(e);
  $ContextDatabaseManager get managers => $ContextDatabaseManager(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $PlacesTable places = $PlacesTable(this);
  late final $ActivityPatternsTable activityPatterns = $ActivityPatternsTable(
    this,
  );
  late final $JournalPreferencesTable journalPreferences =
      $JournalPreferencesTable(this);
  late final $BleDeviceRegistriesTable bleDeviceRegistries =
      $BleDeviceRegistriesTable(this);
  late final $OccasionsTable occasions = $OccasionsTable(this);
  late final $PhotoPersonLinksTable photoPersonLinks = $PhotoPersonLinksTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    people,
    places,
    activityPatterns,
    journalPreferences,
    bleDeviceRegistries,
    occasions,
    photoPersonLinks,
  ];
}

typedef $$PeopleTableCreateCompanionBuilder =
    PeopleCompanion Function({
      Value<int> id,
      required String name,
      required String firstName,
      required String relationship,
      Value<Uint8List?> faceEmbedding,
      Value<int> privacyLevel,
      required DateTime firstSeen,
      required DateTime lastSeen,
      Value<int> photoCount,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PeopleTableUpdateCompanionBuilder =
    PeopleCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> firstName,
      Value<String> relationship,
      Value<Uint8List?> faceEmbedding,
      Value<int> privacyLevel,
      Value<DateTime> firstSeen,
      Value<DateTime> lastSeen,
      Value<int> photoCount,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$PeopleTableReferences
    extends BaseReferences<_$ContextDatabase, $PeopleTable, Person> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BleDeviceRegistriesTable, List<BleDeviceRegistry>>
  _bleDeviceRegistriesRefsTable(_$ContextDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.bleDeviceRegistries,
        aliasName: $_aliasNameGenerator(
          db.people.id,
          db.bleDeviceRegistries.personId,
        ),
      );

  $$BleDeviceRegistriesTableProcessedTableManager get bleDeviceRegistriesRefs {
    final manager = $$BleDeviceRegistriesTableTableManager(
      $_db,
      $_db.bleDeviceRegistries,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _bleDeviceRegistriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OccasionsTable, List<Occasion>>
  _occasionsRefsTable(_$ContextDatabase db) => MultiTypedResultKey.fromTable(
    db.occasions,
    aliasName: $_aliasNameGenerator(db.people.id, db.occasions.personId),
  );

  $$OccasionsTableProcessedTableManager get occasionsRefs {
    final manager = $$OccasionsTableTableManager(
      $_db,
      $_db.occasions,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_occasionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PhotoPersonLinksTable, List<PhotoPersonLink>>
  _photoPersonLinksRefsTable(_$ContextDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.photoPersonLinks,
        aliasName: $_aliasNameGenerator(
          db.people.id,
          db.photoPersonLinks.personId,
        ),
      );

  $$PhotoPersonLinksTableProcessedTableManager get photoPersonLinksRefs {
    final manager = $$PhotoPersonLinksTableTableManager(
      $_db,
      $_db.photoPersonLinks,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _photoPersonLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$ContextDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get faceEmbedding => $composableBuilder(
    column: $table.faceEmbedding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get privacyLevel => $composableBuilder(
    column: $table.privacyLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get photoCount => $composableBuilder(
    column: $table.photoCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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

  Expression<bool> bleDeviceRegistriesRefs(
    Expression<bool> Function($$BleDeviceRegistriesTableFilterComposer f) f,
  ) {
    final $$BleDeviceRegistriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bleDeviceRegistries,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BleDeviceRegistriesTableFilterComposer(
            $db: $db,
            $table: $db.bleDeviceRegistries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> occasionsRefs(
    Expression<bool> Function($$OccasionsTableFilterComposer f) f,
  ) {
    final $$OccasionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableFilterComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> photoPersonLinksRefs(
    Expression<bool> Function($$PhotoPersonLinksTableFilterComposer f) f,
  ) {
    final $$PhotoPersonLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photoPersonLinks,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotoPersonLinksTableFilterComposer(
            $db: $db,
            $table: $db.photoPersonLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$ContextDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get faceEmbedding => $composableBuilder(
    column: $table.faceEmbedding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get privacyLevel => $composableBuilder(
    column: $table.privacyLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get photoCount => $composableBuilder(
    column: $table.photoCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

class $$PeopleTableAnnotationComposer
    extends Composer<_$ContextDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get faceEmbedding => $composableBuilder(
    column: $table.faceEmbedding,
    builder: (column) => column,
  );

  GeneratedColumn<int> get privacyLevel => $composableBuilder(
    column: $table.privacyLevel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<int> get photoCount => $composableBuilder(
    column: $table.photoCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> bleDeviceRegistriesRefs<T extends Object>(
    Expression<T> Function($$BleDeviceRegistriesTableAnnotationComposer a) f,
  ) {
    final $$BleDeviceRegistriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.bleDeviceRegistries,
          getReferencedColumn: (t) => t.personId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BleDeviceRegistriesTableAnnotationComposer(
                $db: $db,
                $table: $db.bleDeviceRegistries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> occasionsRefs<T extends Object>(
    Expression<T> Function($$OccasionsTableAnnotationComposer a) f,
  ) {
    final $$OccasionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableAnnotationComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> photoPersonLinksRefs<T extends Object>(
    Expression<T> Function($$PhotoPersonLinksTableAnnotationComposer a) f,
  ) {
    final $$PhotoPersonLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photoPersonLinks,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotoPersonLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.photoPersonLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$ContextDatabase,
          $PeopleTable,
          Person,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (Person, $$PeopleTableReferences),
          Person,
          PrefetchHooks Function({
            bool bleDeviceRegistriesRefs,
            bool occasionsRefs,
            bool photoPersonLinksRefs,
          })
        > {
  $$PeopleTableTableManager(_$ContextDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> relationship = const Value.absent(),
                Value<Uint8List?> faceEmbedding = const Value.absent(),
                Value<int> privacyLevel = const Value.absent(),
                Value<DateTime> firstSeen = const Value.absent(),
                Value<DateTime> lastSeen = const Value.absent(),
                Value<int> photoCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                name: name,
                firstName: firstName,
                relationship: relationship,
                faceEmbedding: faceEmbedding,
                privacyLevel: privacyLevel,
                firstSeen: firstSeen,
                lastSeen: lastSeen,
                photoCount: photoCount,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String firstName,
                required String relationship,
                Value<Uint8List?> faceEmbedding = const Value.absent(),
                Value<int> privacyLevel = const Value.absent(),
                required DateTime firstSeen,
                required DateTime lastSeen,
                Value<int> photoCount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                name: name,
                firstName: firstName,
                relationship: relationship,
                faceEmbedding: faceEmbedding,
                privacyLevel: privacyLevel,
                firstSeen: firstSeen,
                lastSeen: lastSeen,
                photoCount: photoCount,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PeopleTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bleDeviceRegistriesRefs = false,
                occasionsRefs = false,
                photoPersonLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bleDeviceRegistriesRefs) db.bleDeviceRegistries,
                    if (occasionsRefs) db.occasions,
                    if (photoPersonLinksRefs) db.photoPersonLinks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bleDeviceRegistriesRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          BleDeviceRegistry
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._bleDeviceRegistriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).bleDeviceRegistriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (occasionsRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          Occasion
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._occasionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).occasionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (photoPersonLinksRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          PhotoPersonLink
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._photoPersonLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).photoPersonLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
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

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$ContextDatabase,
      $PeopleTable,
      Person,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (Person, $$PeopleTableReferences),
      Person,
      PrefetchHooks Function({
        bool bleDeviceRegistriesRefs,
        bool occasionsRefs,
        bool photoPersonLinksRefs,
      })
    >;
typedef $$PlacesTableCreateCompanionBuilder =
    PlacesCompanion Function({
      Value<int> id,
      required String name,
      required String category,
      required double latitude,
      required double longitude,
      Value<double> radiusMeters,
      Value<String?> neighborhood,
      Value<String?> city,
      Value<String?> state,
      Value<String?> country,
      Value<int> significanceLevel,
      Value<int> visitCount,
      required DateTime firstVisit,
      required DateTime lastVisit,
      Value<int> totalTimeMinutes,
      Value<String?> customDescription,
      Value<bool> excludeFromJournal,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PlacesTableUpdateCompanionBuilder =
    PlacesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> category,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> radiusMeters,
      Value<String?> neighborhood,
      Value<String?> city,
      Value<String?> state,
      Value<String?> country,
      Value<int> significanceLevel,
      Value<int> visitCount,
      Value<DateTime> firstVisit,
      Value<DateTime> lastVisit,
      Value<int> totalTimeMinutes,
      Value<String?> customDescription,
      Value<bool> excludeFromJournal,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$PlacesTableReferences
    extends BaseReferences<_$ContextDatabase, $PlacesTable, Place> {
  $$PlacesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ActivityPatternsTable, List<ActivityPattern>>
  _activityPatternsRefsTable(_$ContextDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.activityPatterns,
        aliasName: $_aliasNameGenerator(
          db.places.id,
          db.activityPatterns.placeId,
        ),
      );

  $$ActivityPatternsTableProcessedTableManager get activityPatternsRefs {
    final manager = $$ActivityPatternsTableTableManager(
      $_db,
      $_db.activityPatterns,
    ).filter((f) => f.placeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _activityPatternsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlacesTableFilterComposer
    extends Composer<_$ContextDatabase, $PlacesTable> {
  $$PlacesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
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

  ColumnFilters<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get neighborhood => $composableBuilder(
    column: $table.neighborhood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get significanceLevel => $composableBuilder(
    column: $table.significanceLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstVisit => $composableBuilder(
    column: $table.firstVisit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastVisit => $composableBuilder(
    column: $table.lastVisit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTimeMinutes => $composableBuilder(
    column: $table.totalTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customDescription => $composableBuilder(
    column: $table.customDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excludeFromJournal => $composableBuilder(
    column: $table.excludeFromJournal,
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

  Expression<bool> activityPatternsRefs(
    Expression<bool> Function($$ActivityPatternsTableFilterComposer f) f,
  ) {
    final $$ActivityPatternsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activityPatterns,
      getReferencedColumn: (t) => t.placeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivityPatternsTableFilterComposer(
            $db: $db,
            $table: $db.activityPatterns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlacesTableOrderingComposer
    extends Composer<_$ContextDatabase, $PlacesTable> {
  $$PlacesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
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

  ColumnOrderings<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get neighborhood => $composableBuilder(
    column: $table.neighborhood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get significanceLevel => $composableBuilder(
    column: $table.significanceLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstVisit => $composableBuilder(
    column: $table.firstVisit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastVisit => $composableBuilder(
    column: $table.lastVisit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTimeMinutes => $composableBuilder(
    column: $table.totalTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customDescription => $composableBuilder(
    column: $table.customDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excludeFromJournal => $composableBuilder(
    column: $table.excludeFromJournal,
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

class $$PlacesTableAnnotationComposer
    extends Composer<_$ContextDatabase, $PlacesTable> {
  $$PlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get neighborhood => $composableBuilder(
    column: $table.neighborhood,
    builder: (column) => column,
  );

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<int> get significanceLevel => $composableBuilder(
    column: $table.significanceLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstVisit => $composableBuilder(
    column: $table.firstVisit,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastVisit =>
      $composableBuilder(column: $table.lastVisit, builder: (column) => column);

  GeneratedColumn<int> get totalTimeMinutes => $composableBuilder(
    column: $table.totalTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customDescription => $composableBuilder(
    column: $table.customDescription,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get excludeFromJournal => $composableBuilder(
    column: $table.excludeFromJournal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> activityPatternsRefs<T extends Object>(
    Expression<T> Function($$ActivityPatternsTableAnnotationComposer a) f,
  ) {
    final $$ActivityPatternsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activityPatterns,
      getReferencedColumn: (t) => t.placeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivityPatternsTableAnnotationComposer(
            $db: $db,
            $table: $db.activityPatterns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlacesTableTableManager
    extends
        RootTableManager<
          _$ContextDatabase,
          $PlacesTable,
          Place,
          $$PlacesTableFilterComposer,
          $$PlacesTableOrderingComposer,
          $$PlacesTableAnnotationComposer,
          $$PlacesTableCreateCompanionBuilder,
          $$PlacesTableUpdateCompanionBuilder,
          (Place, $$PlacesTableReferences),
          Place,
          PrefetchHooks Function({bool activityPatternsRefs})
        > {
  $$PlacesTableTableManager(_$ContextDatabase db, $PlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> radiusMeters = const Value.absent(),
                Value<String?> neighborhood = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<int> significanceLevel = const Value.absent(),
                Value<int> visitCount = const Value.absent(),
                Value<DateTime> firstVisit = const Value.absent(),
                Value<DateTime> lastVisit = const Value.absent(),
                Value<int> totalTimeMinutes = const Value.absent(),
                Value<String?> customDescription = const Value.absent(),
                Value<bool> excludeFromJournal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlacesCompanion(
                id: id,
                name: name,
                category: category,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                neighborhood: neighborhood,
                city: city,
                state: state,
                country: country,
                significanceLevel: significanceLevel,
                visitCount: visitCount,
                firstVisit: firstVisit,
                lastVisit: lastVisit,
                totalTimeMinutes: totalTimeMinutes,
                customDescription: customDescription,
                excludeFromJournal: excludeFromJournal,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String category,
                required double latitude,
                required double longitude,
                Value<double> radiusMeters = const Value.absent(),
                Value<String?> neighborhood = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<int> significanceLevel = const Value.absent(),
                Value<int> visitCount = const Value.absent(),
                required DateTime firstVisit,
                required DateTime lastVisit,
                Value<int> totalTimeMinutes = const Value.absent(),
                Value<String?> customDescription = const Value.absent(),
                Value<bool> excludeFromJournal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlacesCompanion.insert(
                id: id,
                name: name,
                category: category,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                neighborhood: neighborhood,
                city: city,
                state: state,
                country: country,
                significanceLevel: significanceLevel,
                visitCount: visitCount,
                firstVisit: firstVisit,
                lastVisit: lastVisit,
                totalTimeMinutes: totalTimeMinutes,
                customDescription: customDescription,
                excludeFromJournal: excludeFromJournal,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PlacesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({activityPatternsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (activityPatternsRefs) db.activityPatterns,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (activityPatternsRefs)
                    await $_getPrefetchedData<
                      Place,
                      $PlacesTable,
                      ActivityPattern
                    >(
                      currentTable: table,
                      referencedTable: $$PlacesTableReferences
                          ._activityPatternsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PlacesTableReferences(
                        db,
                        table,
                        p0,
                      ).activityPatternsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.placeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContextDatabase,
      $PlacesTable,
      Place,
      $$PlacesTableFilterComposer,
      $$PlacesTableOrderingComposer,
      $$PlacesTableAnnotationComposer,
      $$PlacesTableCreateCompanionBuilder,
      $$PlacesTableUpdateCompanionBuilder,
      (Place, $$PlacesTableReferences),
      Place,
      PrefetchHooks Function({bool activityPatternsRefs})
    >;
typedef $$ActivityPatternsTableCreateCompanionBuilder =
    ActivityPatternsCompanion Function({
      Value<int> id,
      Value<int?> placeId,
      required int dayOfWeek,
      required int hourOfDay,
      required String activityType,
      Value<int> frequency,
      required DateTime lastOccurrence,
      Value<DateTime> createdAt,
    });
typedef $$ActivityPatternsTableUpdateCompanionBuilder =
    ActivityPatternsCompanion Function({
      Value<int> id,
      Value<int?> placeId,
      Value<int> dayOfWeek,
      Value<int> hourOfDay,
      Value<String> activityType,
      Value<int> frequency,
      Value<DateTime> lastOccurrence,
      Value<DateTime> createdAt,
    });

final class $$ActivityPatternsTableReferences
    extends
        BaseReferences<
          _$ContextDatabase,
          $ActivityPatternsTable,
          ActivityPattern
        > {
  $$ActivityPatternsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlacesTable _placeIdTable(_$ContextDatabase db) =>
      db.places.createAlias(
        $_aliasNameGenerator(db.activityPatterns.placeId, db.places.id),
      );

  $$PlacesTableProcessedTableManager? get placeId {
    final $_column = $_itemColumn<int>('place_id');
    if ($_column == null) return null;
    final manager = $$PlacesTableTableManager(
      $_db,
      $_db.places,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_placeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ActivityPatternsTableFilterComposer
    extends Composer<_$ContextDatabase, $ActivityPatternsTable> {
  $$ActivityPatternsTableFilterComposer({
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

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hourOfDay => $composableBuilder(
    column: $table.hourOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOccurrence => $composableBuilder(
    column: $table.lastOccurrence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlacesTableFilterComposer get placeId {
    final $$PlacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeId,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableFilterComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityPatternsTableOrderingComposer
    extends Composer<_$ContextDatabase, $ActivityPatternsTable> {
  $$ActivityPatternsTableOrderingComposer({
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

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hourOfDay => $composableBuilder(
    column: $table.hourOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOccurrence => $composableBuilder(
    column: $table.lastOccurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlacesTableOrderingComposer get placeId {
    final $$PlacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeId,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableOrderingComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityPatternsTableAnnotationComposer
    extends Composer<_$ContextDatabase, $ActivityPatternsTable> {
  $$ActivityPatternsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get hourOfDay =>
      $composableBuilder(column: $table.hourOfDay, builder: (column) => column);

  GeneratedColumn<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOccurrence => $composableBuilder(
    column: $table.lastOccurrence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PlacesTableAnnotationComposer get placeId {
    final $$PlacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeId,
      referencedTable: $db.places,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacesTableAnnotationComposer(
            $db: $db,
            $table: $db.places,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityPatternsTableTableManager
    extends
        RootTableManager<
          _$ContextDatabase,
          $ActivityPatternsTable,
          ActivityPattern,
          $$ActivityPatternsTableFilterComposer,
          $$ActivityPatternsTableOrderingComposer,
          $$ActivityPatternsTableAnnotationComposer,
          $$ActivityPatternsTableCreateCompanionBuilder,
          $$ActivityPatternsTableUpdateCompanionBuilder,
          (ActivityPattern, $$ActivityPatternsTableReferences),
          ActivityPattern,
          PrefetchHooks Function({bool placeId})
        > {
  $$ActivityPatternsTableTableManager(
    _$ContextDatabase db,
    $ActivityPatternsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityPatternsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityPatternsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityPatternsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> placeId = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<int> hourOfDay = const Value.absent(),
                Value<String> activityType = const Value.absent(),
                Value<int> frequency = const Value.absent(),
                Value<DateTime> lastOccurrence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ActivityPatternsCompanion(
                id: id,
                placeId: placeId,
                dayOfWeek: dayOfWeek,
                hourOfDay: hourOfDay,
                activityType: activityType,
                frequency: frequency,
                lastOccurrence: lastOccurrence,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> placeId = const Value.absent(),
                required int dayOfWeek,
                required int hourOfDay,
                required String activityType,
                Value<int> frequency = const Value.absent(),
                required DateTime lastOccurrence,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ActivityPatternsCompanion.insert(
                id: id,
                placeId: placeId,
                dayOfWeek: dayOfWeek,
                hourOfDay: hourOfDay,
                activityType: activityType,
                frequency: frequency,
                lastOccurrence: lastOccurrence,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ActivityPatternsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({placeId = false}) {
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
                    if (placeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.placeId,
                                referencedTable:
                                    $$ActivityPatternsTableReferences
                                        ._placeIdTable(db),
                                referencedColumn:
                                    $$ActivityPatternsTableReferences
                                        ._placeIdTable(db)
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

typedef $$ActivityPatternsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContextDatabase,
      $ActivityPatternsTable,
      ActivityPattern,
      $$ActivityPatternsTableFilterComposer,
      $$ActivityPatternsTableOrderingComposer,
      $$ActivityPatternsTableAnnotationComposer,
      $$ActivityPatternsTableCreateCompanionBuilder,
      $$ActivityPatternsTableUpdateCompanionBuilder,
      (ActivityPattern, $$ActivityPatternsTableReferences),
      ActivityPattern,
      PrefetchHooks Function({bool placeId})
    >;
typedef $$JournalPreferencesTableCreateCompanionBuilder =
    JournalPreferencesCompanion Function({
      Value<int> id,
      required String key,
      required String value,
      Value<DateTime> updatedAt,
    });
typedef $$JournalPreferencesTableUpdateCompanionBuilder =
    JournalPreferencesCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
    });

class $$JournalPreferencesTableFilterComposer
    extends Composer<_$ContextDatabase, $JournalPreferencesTable> {
  $$JournalPreferencesTableFilterComposer({
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

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalPreferencesTableOrderingComposer
    extends Composer<_$ContextDatabase, $JournalPreferencesTable> {
  $$JournalPreferencesTableOrderingComposer({
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

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalPreferencesTableAnnotationComposer
    extends Composer<_$ContextDatabase, $JournalPreferencesTable> {
  $$JournalPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$JournalPreferencesTableTableManager
    extends
        RootTableManager<
          _$ContextDatabase,
          $JournalPreferencesTable,
          JournalPreference,
          $$JournalPreferencesTableFilterComposer,
          $$JournalPreferencesTableOrderingComposer,
          $$JournalPreferencesTableAnnotationComposer,
          $$JournalPreferencesTableCreateCompanionBuilder,
          $$JournalPreferencesTableUpdateCompanionBuilder,
          (
            JournalPreference,
            BaseReferences<
              _$ContextDatabase,
              $JournalPreferencesTable,
              JournalPreference
            >,
          ),
          JournalPreference,
          PrefetchHooks Function()
        > {
  $$JournalPreferencesTableTableManager(
    _$ContextDatabase db,
    $JournalPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => JournalPreferencesCompanion(
                id: id,
                key: key,
                value: value,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => JournalPreferencesCompanion.insert(
                id: id,
                key: key,
                value: value,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContextDatabase,
      $JournalPreferencesTable,
      JournalPreference,
      $$JournalPreferencesTableFilterComposer,
      $$JournalPreferencesTableOrderingComposer,
      $$JournalPreferencesTableAnnotationComposer,
      $$JournalPreferencesTableCreateCompanionBuilder,
      $$JournalPreferencesTableUpdateCompanionBuilder,
      (
        JournalPreference,
        BaseReferences<
          _$ContextDatabase,
          $JournalPreferencesTable,
          JournalPreference
        >,
      ),
      JournalPreference,
      PrefetchHooks Function()
    >;
typedef $$BleDeviceRegistriesTableCreateCompanionBuilder =
    BleDeviceRegistriesCompanion Function({
      Value<int> id,
      required String deviceId,
      Value<int?> personId,
      required String deviceType,
      Value<String?> deviceName,
      required DateTime firstSeen,
      required DateTime lastSeen,
      Value<int> encounterCount,
      Value<DateTime> createdAt,
    });
typedef $$BleDeviceRegistriesTableUpdateCompanionBuilder =
    BleDeviceRegistriesCompanion Function({
      Value<int> id,
      Value<String> deviceId,
      Value<int?> personId,
      Value<String> deviceType,
      Value<String?> deviceName,
      Value<DateTime> firstSeen,
      Value<DateTime> lastSeen,
      Value<int> encounterCount,
      Value<DateTime> createdAt,
    });

final class $$BleDeviceRegistriesTableReferences
    extends
        BaseReferences<
          _$ContextDatabase,
          $BleDeviceRegistriesTable,
          BleDeviceRegistry
        > {
  $$BleDeviceRegistriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PeopleTable _personIdTable(_$ContextDatabase db) =>
      db.people.createAlias(
        $_aliasNameGenerator(db.bleDeviceRegistries.personId, db.people.id),
      );

  $$PeopleTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<int>('person_id');
    if ($_column == null) return null;
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BleDeviceRegistriesTableFilterComposer
    extends Composer<_$ContextDatabase, $BleDeviceRegistriesTable> {
  $$BleDeviceRegistriesTableFilterComposer({
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

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get encounterCount => $composableBuilder(
    column: $table.encounterCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BleDeviceRegistriesTableOrderingComposer
    extends Composer<_$ContextDatabase, $BleDeviceRegistriesTable> {
  $$BleDeviceRegistriesTableOrderingComposer({
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

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get encounterCount => $composableBuilder(
    column: $table.encounterCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BleDeviceRegistriesTableAnnotationComposer
    extends Composer<_$ContextDatabase, $BleDeviceRegistriesTable> {
  $$BleDeviceRegistriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<int> get encounterCount => $composableBuilder(
    column: $table.encounterCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BleDeviceRegistriesTableTableManager
    extends
        RootTableManager<
          _$ContextDatabase,
          $BleDeviceRegistriesTable,
          BleDeviceRegistry,
          $$BleDeviceRegistriesTableFilterComposer,
          $$BleDeviceRegistriesTableOrderingComposer,
          $$BleDeviceRegistriesTableAnnotationComposer,
          $$BleDeviceRegistriesTableCreateCompanionBuilder,
          $$BleDeviceRegistriesTableUpdateCompanionBuilder,
          (BleDeviceRegistry, $$BleDeviceRegistriesTableReferences),
          BleDeviceRegistry,
          PrefetchHooks Function({bool personId})
        > {
  $$BleDeviceRegistriesTableTableManager(
    _$ContextDatabase db,
    $BleDeviceRegistriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BleDeviceRegistriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BleDeviceRegistriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BleDeviceRegistriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String> deviceType = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<DateTime> firstSeen = const Value.absent(),
                Value<DateTime> lastSeen = const Value.absent(),
                Value<int> encounterCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BleDeviceRegistriesCompanion(
                id: id,
                deviceId: deviceId,
                personId: personId,
                deviceType: deviceType,
                deviceName: deviceName,
                firstSeen: firstSeen,
                lastSeen: lastSeen,
                encounterCount: encounterCount,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deviceId,
                Value<int?> personId = const Value.absent(),
                required String deviceType,
                Value<String?> deviceName = const Value.absent(),
                required DateTime firstSeen,
                required DateTime lastSeen,
                Value<int> encounterCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BleDeviceRegistriesCompanion.insert(
                id: id,
                deviceId: deviceId,
                personId: personId,
                deviceType: deviceType,
                deviceName: deviceName,
                firstSeen: firstSeen,
                lastSeen: lastSeen,
                encounterCount: encounterCount,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BleDeviceRegistriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
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
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable:
                                    $$BleDeviceRegistriesTableReferences
                                        ._personIdTable(db),
                                referencedColumn:
                                    $$BleDeviceRegistriesTableReferences
                                        ._personIdTable(db)
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

typedef $$BleDeviceRegistriesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContextDatabase,
      $BleDeviceRegistriesTable,
      BleDeviceRegistry,
      $$BleDeviceRegistriesTableFilterComposer,
      $$BleDeviceRegistriesTableOrderingComposer,
      $$BleDeviceRegistriesTableAnnotationComposer,
      $$BleDeviceRegistriesTableCreateCompanionBuilder,
      $$BleDeviceRegistriesTableUpdateCompanionBuilder,
      (BleDeviceRegistry, $$BleDeviceRegistriesTableReferences),
      BleDeviceRegistry,
      PrefetchHooks Function({bool personId})
    >;
typedef $$OccasionsTableCreateCompanionBuilder =
    OccasionsCompanion Function({
      Value<int> id,
      required String name,
      required DateTime date,
      Value<int?> personId,
      required String occasionType,
      Value<bool> recurring,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });
typedef $$OccasionsTableUpdateCompanionBuilder =
    OccasionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> date,
      Value<int?> personId,
      Value<String> occasionType,
      Value<bool> recurring,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });

final class $$OccasionsTableReferences
    extends BaseReferences<_$ContextDatabase, $OccasionsTable, Occasion> {
  $$OccasionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _personIdTable(_$ContextDatabase db) => db.people
      .createAlias($_aliasNameGenerator(db.occasions.personId, db.people.id));

  $$PeopleTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<int>('person_id');
    if ($_column == null) return null;
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OccasionsTableFilterComposer
    extends Composer<_$ContextDatabase, $OccasionsTable> {
  $$OccasionsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occasionType => $composableBuilder(
    column: $table.occasionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get recurring => $composableBuilder(
    column: $table.recurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccasionsTableOrderingComposer
    extends Composer<_$ContextDatabase, $OccasionsTable> {
  $$OccasionsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occasionType => $composableBuilder(
    column: $table.occasionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get recurring => $composableBuilder(
    column: $table.recurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccasionsTableAnnotationComposer
    extends Composer<_$ContextDatabase, $OccasionsTable> {
  $$OccasionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get occasionType => $composableBuilder(
    column: $table.occasionType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get recurring =>
      $composableBuilder(column: $table.recurring, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccasionsTableTableManager
    extends
        RootTableManager<
          _$ContextDatabase,
          $OccasionsTable,
          Occasion,
          $$OccasionsTableFilterComposer,
          $$OccasionsTableOrderingComposer,
          $$OccasionsTableAnnotationComposer,
          $$OccasionsTableCreateCompanionBuilder,
          $$OccasionsTableUpdateCompanionBuilder,
          (Occasion, $$OccasionsTableReferences),
          Occasion,
          PrefetchHooks Function({bool personId})
        > {
  $$OccasionsTableTableManager(_$ContextDatabase db, $OccasionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccasionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccasionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OccasionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String> occasionType = const Value.absent(),
                Value<bool> recurring = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OccasionsCompanion(
                id: id,
                name: name,
                date: date,
                personId: personId,
                occasionType: occasionType,
                recurring: recurring,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime date,
                Value<int?> personId = const Value.absent(),
                required String occasionType,
                Value<bool> recurring = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OccasionsCompanion.insert(
                id: id,
                name: name,
                date: date,
                personId: personId,
                occasionType: occasionType,
                recurring: recurring,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OccasionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
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
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$OccasionsTableReferences
                                    ._personIdTable(db),
                                referencedColumn: $$OccasionsTableReferences
                                    ._personIdTable(db)
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

typedef $$OccasionsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContextDatabase,
      $OccasionsTable,
      Occasion,
      $$OccasionsTableFilterComposer,
      $$OccasionsTableOrderingComposer,
      $$OccasionsTableAnnotationComposer,
      $$OccasionsTableCreateCompanionBuilder,
      $$OccasionsTableUpdateCompanionBuilder,
      (Occasion, $$OccasionsTableReferences),
      Occasion,
      PrefetchHooks Function({bool personId})
    >;
typedef $$PhotoPersonLinksTableCreateCompanionBuilder =
    PhotoPersonLinksCompanion Function({
      Value<int> id,
      required String photoId,
      required int personId,
      required double confidence,
      required int faceIndex,
      Value<DateTime> createdAt,
    });
typedef $$PhotoPersonLinksTableUpdateCompanionBuilder =
    PhotoPersonLinksCompanion Function({
      Value<int> id,
      Value<String> photoId,
      Value<int> personId,
      Value<double> confidence,
      Value<int> faceIndex,
      Value<DateTime> createdAt,
    });

final class $$PhotoPersonLinksTableReferences
    extends
        BaseReferences<
          _$ContextDatabase,
          $PhotoPersonLinksTable,
          PhotoPersonLink
        > {
  $$PhotoPersonLinksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PeopleTable _personIdTable(_$ContextDatabase db) =>
      db.people.createAlias(
        $_aliasNameGenerator(db.photoPersonLinks.personId, db.people.id),
      );

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PhotoPersonLinksTableFilterComposer
    extends Composer<_$ContextDatabase, $PhotoPersonLinksTable> {
  $$PhotoPersonLinksTableFilterComposer({
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

  ColumnFilters<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get faceIndex => $composableBuilder(
    column: $table.faceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotoPersonLinksTableOrderingComposer
    extends Composer<_$ContextDatabase, $PhotoPersonLinksTable> {
  $$PhotoPersonLinksTableOrderingComposer({
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

  ColumnOrderings<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get faceIndex => $composableBuilder(
    column: $table.faceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotoPersonLinksTableAnnotationComposer
    extends Composer<_$ContextDatabase, $PhotoPersonLinksTable> {
  $$PhotoPersonLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get faceIndex =>
      $composableBuilder(column: $table.faceIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotoPersonLinksTableTableManager
    extends
        RootTableManager<
          _$ContextDatabase,
          $PhotoPersonLinksTable,
          PhotoPersonLink,
          $$PhotoPersonLinksTableFilterComposer,
          $$PhotoPersonLinksTableOrderingComposer,
          $$PhotoPersonLinksTableAnnotationComposer,
          $$PhotoPersonLinksTableCreateCompanionBuilder,
          $$PhotoPersonLinksTableUpdateCompanionBuilder,
          (PhotoPersonLink, $$PhotoPersonLinksTableReferences),
          PhotoPersonLink,
          PrefetchHooks Function({bool personId})
        > {
  $$PhotoPersonLinksTableTableManager(
    _$ContextDatabase db,
    $PhotoPersonLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoPersonLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoPersonLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoPersonLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> photoId = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<int> faceIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhotoPersonLinksCompanion(
                id: id,
                photoId: photoId,
                personId: personId,
                confidence: confidence,
                faceIndex: faceIndex,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String photoId,
                required int personId,
                required double confidence,
                required int faceIndex,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhotoPersonLinksCompanion.insert(
                id: id,
                photoId: photoId,
                personId: personId,
                confidence: confidence,
                faceIndex: faceIndex,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PhotoPersonLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
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
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable:
                                    $$PhotoPersonLinksTableReferences
                                        ._personIdTable(db),
                                referencedColumn:
                                    $$PhotoPersonLinksTableReferences
                                        ._personIdTable(db)
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

typedef $$PhotoPersonLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$ContextDatabase,
      $PhotoPersonLinksTable,
      PhotoPersonLink,
      $$PhotoPersonLinksTableFilterComposer,
      $$PhotoPersonLinksTableOrderingComposer,
      $$PhotoPersonLinksTableAnnotationComposer,
      $$PhotoPersonLinksTableCreateCompanionBuilder,
      $$PhotoPersonLinksTableUpdateCompanionBuilder,
      (PhotoPersonLink, $$PhotoPersonLinksTableReferences),
      PhotoPersonLink,
      PrefetchHooks Function({bool personId})
    >;

class $ContextDatabaseManager {
  final _$ContextDatabase _db;
  $ContextDatabaseManager(this._db);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$PlacesTableTableManager get places =>
      $$PlacesTableTableManager(_db, _db.places);
  $$ActivityPatternsTableTableManager get activityPatterns =>
      $$ActivityPatternsTableTableManager(_db, _db.activityPatterns);
  $$JournalPreferencesTableTableManager get journalPreferences =>
      $$JournalPreferencesTableTableManager(_db, _db.journalPreferences);
  $$BleDeviceRegistriesTableTableManager get bleDeviceRegistries =>
      $$BleDeviceRegistriesTableTableManager(_db, _db.bleDeviceRegistries);
  $$OccasionsTableTableManager get occasions =>
      $$OccasionsTableTableManager(_db, _db.occasions);
  $$PhotoPersonLinksTableTableManager get photoPersonLinks =>
      $$PhotoPersonLinksTableTableManager(_db, _db.photoPersonLinks);
}
