// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_database.dart';

// ignore_for_file: type=lint
class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdDateMeta = const VerificationMeta(
    'createdDate',
  );
  @override
  late final GeneratedColumn<DateTime> createdDate = GeneratedColumn<DateTime>(
    'created_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedDateMeta = const VerificationMeta(
    'modifiedDate',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedDate = GeneratedColumn<DateTime>(
    'modified_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedDateMeta = const VerificationMeta(
    'addedDate',
  );
  @override
  late final GeneratedColumn<DateTime> addedDate = GeneratedColumn<DateTime>(
    'added_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isProcessedMeta = const VerificationMeta(
    'isProcessed',
  );
  @override
  late final GeneratedColumn<bool> isProcessed = GeneratedColumn<bool>(
    'is_processed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_processed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    fileName,
    mimeType,
    fileSize,
    fileHash,
    createdDate,
    modifiedDate,
    addedDate,
    isDeleted,
    isProcessed,
    width,
    height,
    duration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    }
    if (data.containsKey('created_date')) {
      context.handle(
        _createdDateMeta,
        createdDate.isAcceptableOrUnknown(
          data['created_date']!,
          _createdDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdDateMeta);
    }
    if (data.containsKey('modified_date')) {
      context.handle(
        _modifiedDateMeta,
        modifiedDate.isAcceptableOrUnknown(
          data['modified_date']!,
          _modifiedDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modifiedDateMeta);
    }
    if (data.containsKey('added_date')) {
      context.handle(
        _addedDateMeta,
        addedDate.isAcceptableOrUnknown(data['added_date']!, _addedDateMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('is_processed')) {
      context.handle(
        _isProcessedMeta,
        isProcessed.isAcceptableOrUnknown(
          data['is_processed']!,
          _isProcessedMeta,
        ),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      ),
      createdDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_date'],
      )!,
      modifiedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_date'],
      )!,
      addedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_date'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      isProcessed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_processed'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }
}

class MediaItem extends DataClass implements Insertable<MediaItem> {
  final String id;
  final String? filePath;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String? fileHash;
  final DateTime createdDate;
  final DateTime modifiedDate;
  final DateTime addedDate;
  final bool isDeleted;
  final bool isProcessed;
  final int? width;
  final int? height;
  final int? duration;
  const MediaItem({
    required this.id,
    this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.fileHash,
    required this.createdDate,
    required this.modifiedDate,
    required this.addedDate,
    required this.isDeleted,
    required this.isProcessed,
    this.width,
    this.height,
    this.duration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    map['file_name'] = Variable<String>(fileName);
    map['mime_type'] = Variable<String>(mimeType);
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || fileHash != null) {
      map['file_hash'] = Variable<String>(fileHash);
    }
    map['created_date'] = Variable<DateTime>(createdDate);
    map['modified_date'] = Variable<DateTime>(modifiedDate);
    map['added_date'] = Variable<DateTime>(addedDate);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_processed'] = Variable<bool>(isProcessed);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      id: Value(id),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      fileName: Value(fileName),
      mimeType: Value(mimeType),
      fileSize: Value(fileSize),
      fileHash: fileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fileHash),
      createdDate: Value(createdDate),
      modifiedDate: Value(modifiedDate),
      addedDate: Value(addedDate),
      isDeleted: Value(isDeleted),
      isProcessed: Value(isProcessed),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
    );
  }

  factory MediaItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItem(
      id: serializer.fromJson<String>(json['id']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      fileHash: serializer.fromJson<String?>(json['fileHash']),
      createdDate: serializer.fromJson<DateTime>(json['createdDate']),
      modifiedDate: serializer.fromJson<DateTime>(json['modifiedDate']),
      addedDate: serializer.fromJson<DateTime>(json['addedDate']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isProcessed: serializer.fromJson<bool>(json['isProcessed']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      duration: serializer.fromJson<int?>(json['duration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'filePath': serializer.toJson<String?>(filePath),
      'fileName': serializer.toJson<String>(fileName),
      'mimeType': serializer.toJson<String>(mimeType),
      'fileSize': serializer.toJson<int>(fileSize),
      'fileHash': serializer.toJson<String?>(fileHash),
      'createdDate': serializer.toJson<DateTime>(createdDate),
      'modifiedDate': serializer.toJson<DateTime>(modifiedDate),
      'addedDate': serializer.toJson<DateTime>(addedDate),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isProcessed': serializer.toJson<bool>(isProcessed),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'duration': serializer.toJson<int?>(duration),
    };
  }

  MediaItem copyWith({
    String? id,
    Value<String?> filePath = const Value.absent(),
    String? fileName,
    String? mimeType,
    int? fileSize,
    Value<String?> fileHash = const Value.absent(),
    DateTime? createdDate,
    DateTime? modifiedDate,
    DateTime? addedDate,
    bool? isDeleted,
    bool? isProcessed,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> duration = const Value.absent(),
  }) => MediaItem(
    id: id ?? this.id,
    filePath: filePath.present ? filePath.value : this.filePath,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    fileSize: fileSize ?? this.fileSize,
    fileHash: fileHash.present ? fileHash.value : this.fileHash,
    createdDate: createdDate ?? this.createdDate,
    modifiedDate: modifiedDate ?? this.modifiedDate,
    addedDate: addedDate ?? this.addedDate,
    isDeleted: isDeleted ?? this.isDeleted,
    isProcessed: isProcessed ?? this.isProcessed,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    duration: duration.present ? duration.value : this.duration,
  );
  MediaItem copyWithCompanion(MediaItemsCompanion data) {
    return MediaItem(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      createdDate: data.createdDate.present
          ? data.createdDate.value
          : this.createdDate,
      modifiedDate: data.modifiedDate.present
          ? data.modifiedDate.value
          : this.modifiedDate,
      addedDate: data.addedDate.present ? data.addedDate.value : this.addedDate,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isProcessed: data.isProcessed.present
          ? data.isProcessed.value
          : this.isProcessed,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      duration: data.duration.present ? data.duration.value : this.duration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItem(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileHash: $fileHash, ')
          ..write('createdDate: $createdDate, ')
          ..write('modifiedDate: $modifiedDate, ')
          ..write('addedDate: $addedDate, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isProcessed: $isProcessed, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('duration: $duration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    fileName,
    mimeType,
    fileSize,
    fileHash,
    createdDate,
    modifiedDate,
    addedDate,
    isDeleted,
    isProcessed,
    width,
    height,
    duration,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItem &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.fileSize == this.fileSize &&
          other.fileHash == this.fileHash &&
          other.createdDate == this.createdDate &&
          other.modifiedDate == this.modifiedDate &&
          other.addedDate == this.addedDate &&
          other.isDeleted == this.isDeleted &&
          other.isProcessed == this.isProcessed &&
          other.width == this.width &&
          other.height == this.height &&
          other.duration == this.duration);
}

class MediaItemsCompanion extends UpdateCompanion<MediaItem> {
  final Value<String> id;
  final Value<String?> filePath;
  final Value<String> fileName;
  final Value<String> mimeType;
  final Value<int> fileSize;
  final Value<String?> fileHash;
  final Value<DateTime> createdDate;
  final Value<DateTime> modifiedDate;
  final Value<DateTime> addedDate;
  final Value<bool> isDeleted;
  final Value<bool> isProcessed;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> duration;
  final Value<int> rowid;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.createdDate = const Value.absent(),
    this.modifiedDate = const Value.absent(),
    this.addedDate = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isProcessed = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.duration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    required String id,
    this.filePath = const Value.absent(),
    required String fileName,
    required String mimeType,
    required int fileSize,
    this.fileHash = const Value.absent(),
    required DateTime createdDate,
    required DateTime modifiedDate,
    this.addedDate = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isProcessed = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.duration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fileName = Value(fileName),
       mimeType = Value(mimeType),
       fileSize = Value(fileSize),
       createdDate = Value(createdDate),
       modifiedDate = Value(modifiedDate);
  static Insertable<MediaItem> custom({
    Expression<String>? id,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<int>? fileSize,
    Expression<String>? fileHash,
    Expression<DateTime>? createdDate,
    Expression<DateTime>? modifiedDate,
    Expression<DateTime>? addedDate,
    Expression<bool>? isDeleted,
    Expression<bool>? isProcessed,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? duration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSize != null) 'file_size': fileSize,
      if (fileHash != null) 'file_hash': fileHash,
      if (createdDate != null) 'created_date': createdDate,
      if (modifiedDate != null) 'modified_date': modifiedDate,
      if (addedDate != null) 'added_date': addedDate,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isProcessed != null) 'is_processed': isProcessed,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (duration != null) 'duration': duration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaItemsCompanion copyWith({
    Value<String>? id,
    Value<String?>? filePath,
    Value<String>? fileName,
    Value<String>? mimeType,
    Value<int>? fileSize,
    Value<String?>? fileHash,
    Value<DateTime>? createdDate,
    Value<DateTime>? modifiedDate,
    Value<DateTime>? addedDate,
    Value<bool>? isDeleted,
    Value<bool>? isProcessed,
    Value<int?>? width,
    Value<int?>? height,
    Value<int?>? duration,
    Value<int>? rowid,
  }) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      fileHash: fileHash ?? this.fileHash,
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      addedDate: addedDate ?? this.addedDate,
      isDeleted: isDeleted ?? this.isDeleted,
      isProcessed: isProcessed ?? this.isProcessed,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (createdDate.present) {
      map['created_date'] = Variable<DateTime>(createdDate.value);
    }
    if (modifiedDate.present) {
      map['modified_date'] = Variable<DateTime>(modifiedDate.value);
    }
    if (addedDate.present) {
      map['added_date'] = Variable<DateTime>(addedDate.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isProcessed.present) {
      map['is_processed'] = Variable<bool>(isProcessed.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileHash: $fileHash, ')
          ..write('createdDate: $createdDate, ')
          ..write('modifiedDate: $modifiedDate, ')
          ..write('addedDate: $addedDate, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isProcessed: $isProcessed, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('duration: $duration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaMetadataTable extends MediaMetadata
    with TableInfo<$MediaMetadataTable, MediaMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaMetadataTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _metadataTypeMeta = const VerificationMeta(
    'metadataType',
  );
  @override
  late final GeneratedColumn<String> metadataType = GeneratedColumn<String>(
    'metadata_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractedAtMeta = const VerificationMeta(
    'extractedAt',
  );
  @override
  late final GeneratedColumn<DateTime> extractedAt = GeneratedColumn<DateTime>(
    'extracted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaId,
    metadataType,
    key,
    value,
    confidence,
    extractedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('metadata_type')) {
      context.handle(
        _metadataTypeMeta,
        metadataType.isAcceptableOrUnknown(
          data['metadata_type']!,
          _metadataTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataTypeMeta);
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
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('extracted_at')) {
      context.handle(
        _extractedAtMeta,
        extractedAt.isAcceptableOrUnknown(
          data['extracted_at']!,
          _extractedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {mediaId, metadataType, key},
  ];
  @override
  MediaMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaMetadataData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      metadataType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_type'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      extractedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}extracted_at'],
      )!,
    );
  }

  @override
  $MediaMetadataTable createAlias(String alias) {
    return $MediaMetadataTable(attachedDatabase, alias);
  }
}

class MediaMetadataData extends DataClass
    implements Insertable<MediaMetadataData> {
  final int id;
  final String mediaId;
  final String metadataType;
  final String key;
  final String value;
  final double? confidence;
  final DateTime extractedAt;
  const MediaMetadataData({
    required this.id,
    required this.mediaId,
    required this.metadataType,
    required this.key,
    required this.value,
    this.confidence,
    required this.extractedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['media_id'] = Variable<String>(mediaId);
    map['metadata_type'] = Variable<String>(metadataType);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    map['extracted_at'] = Variable<DateTime>(extractedAt);
    return map;
  }

  MediaMetadataCompanion toCompanion(bool nullToAbsent) {
    return MediaMetadataCompanion(
      id: Value(id),
      mediaId: Value(mediaId),
      metadataType: Value(metadataType),
      key: Value(key),
      value: Value(value),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      extractedAt: Value(extractedAt),
    );
  }

  factory MediaMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaMetadataData(
      id: serializer.fromJson<int>(json['id']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      metadataType: serializer.fromJson<String>(json['metadataType']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      extractedAt: serializer.fromJson<DateTime>(json['extractedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mediaId': serializer.toJson<String>(mediaId),
      'metadataType': serializer.toJson<String>(metadataType),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'confidence': serializer.toJson<double?>(confidence),
      'extractedAt': serializer.toJson<DateTime>(extractedAt),
    };
  }

  MediaMetadataData copyWith({
    int? id,
    String? mediaId,
    String? metadataType,
    String? key,
    String? value,
    Value<double?> confidence = const Value.absent(),
    DateTime? extractedAt,
  }) => MediaMetadataData(
    id: id ?? this.id,
    mediaId: mediaId ?? this.mediaId,
    metadataType: metadataType ?? this.metadataType,
    key: key ?? this.key,
    value: value ?? this.value,
    confidence: confidence.present ? confidence.value : this.confidence,
    extractedAt: extractedAt ?? this.extractedAt,
  );
  MediaMetadataData copyWithCompanion(MediaMetadataCompanion data) {
    return MediaMetadataData(
      id: data.id.present ? data.id.value : this.id,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      metadataType: data.metadataType.present
          ? data.metadataType.value
          : this.metadataType,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      extractedAt: data.extractedAt.present
          ? data.extractedAt.value
          : this.extractedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaMetadataData(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('metadataType: $metadataType, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('confidence: $confidence, ')
          ..write('extractedAt: $extractedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaId,
    metadataType,
    key,
    value,
    confidence,
    extractedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaMetadataData &&
          other.id == this.id &&
          other.mediaId == this.mediaId &&
          other.metadataType == this.metadataType &&
          other.key == this.key &&
          other.value == this.value &&
          other.confidence == this.confidence &&
          other.extractedAt == this.extractedAt);
}

class MediaMetadataCompanion extends UpdateCompanion<MediaMetadataData> {
  final Value<int> id;
  final Value<String> mediaId;
  final Value<String> metadataType;
  final Value<String> key;
  final Value<String> value;
  final Value<double?> confidence;
  final Value<DateTime> extractedAt;
  const MediaMetadataCompanion({
    this.id = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.metadataType = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.confidence = const Value.absent(),
    this.extractedAt = const Value.absent(),
  });
  MediaMetadataCompanion.insert({
    this.id = const Value.absent(),
    required String mediaId,
    required String metadataType,
    required String key,
    required String value,
    this.confidence = const Value.absent(),
    this.extractedAt = const Value.absent(),
  }) : mediaId = Value(mediaId),
       metadataType = Value(metadataType),
       key = Value(key),
       value = Value(value);
  static Insertable<MediaMetadataData> custom({
    Expression<int>? id,
    Expression<String>? mediaId,
    Expression<String>? metadataType,
    Expression<String>? key,
    Expression<String>? value,
    Expression<double>? confidence,
    Expression<DateTime>? extractedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaId != null) 'media_id': mediaId,
      if (metadataType != null) 'metadata_type': metadataType,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (confidence != null) 'confidence': confidence,
      if (extractedAt != null) 'extracted_at': extractedAt,
    });
  }

  MediaMetadataCompanion copyWith({
    Value<int>? id,
    Value<String>? mediaId,
    Value<String>? metadataType,
    Value<String>? key,
    Value<String>? value,
    Value<double?>? confidence,
    Value<DateTime>? extractedAt,
  }) {
    return MediaMetadataCompanion(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      metadataType: metadataType ?? this.metadataType,
      key: key ?? this.key,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      extractedAt: extractedAt ?? this.extractedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (metadataType.present) {
      map['metadata_type'] = Variable<String>(metadataType.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (extractedAt.present) {
      map['extracted_at'] = Variable<DateTime>(extractedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaMetadataCompanion(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('metadataType: $metadataType, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('confidence: $confidence, ')
          ..write('extractedAt: $extractedAt')
          ..write(')'))
        .toString();
  }
}

class $PersonTagsTable extends PersonTags
    with TableInfo<$PersonTagsTable, PersonTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonTagsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta(
    'personName',
  );
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personNicknameMeta = const VerificationMeta(
    'personNickname',
  );
  @override
  late final GeneratedColumn<String> personNickname = GeneratedColumn<String>(
    'person_nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _boundingBoxXMeta = const VerificationMeta(
    'boundingBoxX',
  );
  @override
  late final GeneratedColumn<double> boundingBoxX = GeneratedColumn<double>(
    'bounding_box_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingBoxYMeta = const VerificationMeta(
    'boundingBoxY',
  );
  @override
  late final GeneratedColumn<double> boundingBoxY = GeneratedColumn<double>(
    'bounding_box_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingBoxWidthMeta = const VerificationMeta(
    'boundingBoxWidth',
  );
  @override
  late final GeneratedColumn<double> boundingBoxWidth = GeneratedColumn<double>(
    'bounding_box_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingBoxHeightMeta = const VerificationMeta(
    'boundingBoxHeight',
  );
  @override
  late final GeneratedColumn<double> boundingBoxHeight =
      GeneratedColumn<double>(
        'bounding_box_height',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
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
  static const VerificationMeta _similarityMeta = const VerificationMeta(
    'similarity',
  );
  @override
  late final GeneratedColumn<double> similarity = GeneratedColumn<double>(
    'similarity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isConfirmedMeta = const VerificationMeta(
    'isConfirmed',
  );
  @override
  late final GeneratedColumn<bool> isConfirmed = GeneratedColumn<bool>(
    'is_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isRejectedMeta = const VerificationMeta(
    'isRejected',
  );
  @override
  late final GeneratedColumn<bool> isRejected = GeneratedColumn<bool>(
    'is_rejected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_rejected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
    'detected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    personName,
    personNickname,
    mediaId,
    boundingBoxX,
    boundingBoxY,
    boundingBoxWidth,
    boundingBoxHeight,
    confidence,
    similarity,
    isConfirmed,
    isRejected,
    detectedAt,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'person_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('person_name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta),
      );
    }
    if (data.containsKey('person_nickname')) {
      context.handle(
        _personNicknameMeta,
        personNickname.isAcceptableOrUnknown(
          data['person_nickname']!,
          _personNicknameMeta,
        ),
      );
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('bounding_box_x')) {
      context.handle(
        _boundingBoxXMeta,
        boundingBoxX.isAcceptableOrUnknown(
          data['bounding_box_x']!,
          _boundingBoxXMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingBoxXMeta);
    }
    if (data.containsKey('bounding_box_y')) {
      context.handle(
        _boundingBoxYMeta,
        boundingBoxY.isAcceptableOrUnknown(
          data['bounding_box_y']!,
          _boundingBoxYMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingBoxYMeta);
    }
    if (data.containsKey('bounding_box_width')) {
      context.handle(
        _boundingBoxWidthMeta,
        boundingBoxWidth.isAcceptableOrUnknown(
          data['bounding_box_width']!,
          _boundingBoxWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingBoxWidthMeta);
    }
    if (data.containsKey('bounding_box_height')) {
      context.handle(
        _boundingBoxHeightMeta,
        boundingBoxHeight.isAcceptableOrUnknown(
          data['bounding_box_height']!,
          _boundingBoxHeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingBoxHeightMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('similarity')) {
      context.handle(
        _similarityMeta,
        similarity.isAcceptableOrUnknown(data['similarity']!, _similarityMeta),
      );
    }
    if (data.containsKey('is_confirmed')) {
      context.handle(
        _isConfirmedMeta,
        isConfirmed.isAcceptableOrUnknown(
          data['is_confirmed']!,
          _isConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('is_rejected')) {
      context.handle(
        _isRejectedMeta,
        isRejected.isAcceptableOrUnknown(data['is_rejected']!, _isRejectedMeta),
      );
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {mediaId, boundingBoxX, boundingBoxY, boundingBoxWidth, boundingBoxHeight},
  ];
  @override
  PersonTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name'],
      ),
      personNickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_nickname'],
      ),
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      boundingBoxX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_box_x'],
      )!,
      boundingBoxY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_box_y'],
      )!,
      boundingBoxWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_box_width'],
      )!,
      boundingBoxHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_box_height'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      similarity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}similarity'],
      ),
      isConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_confirmed'],
      )!,
      isRejected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_rejected'],
      )!,
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detected_at'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
    );
  }

  @override
  $PersonTagsTable createAlias(String alias) {
    return $PersonTagsTable(attachedDatabase, alias);
  }
}

class PersonTag extends DataClass implements Insertable<PersonTag> {
  final int id;
  final String personId;
  final String? personName;
  final String? personNickname;
  final String mediaId;
  final double boundingBoxX;
  final double boundingBoxY;
  final double boundingBoxWidth;
  final double boundingBoxHeight;
  final double confidence;
  final double? similarity;
  final bool isConfirmed;
  final bool isRejected;
  final DateTime detectedAt;
  final DateTime? confirmedAt;
  const PersonTag({
    required this.id,
    required this.personId,
    this.personName,
    this.personNickname,
    required this.mediaId,
    required this.boundingBoxX,
    required this.boundingBoxY,
    required this.boundingBoxWidth,
    required this.boundingBoxHeight,
    required this.confidence,
    this.similarity,
    required this.isConfirmed,
    required this.isRejected,
    required this.detectedAt,
    this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<String>(personId);
    if (!nullToAbsent || personName != null) {
      map['person_name'] = Variable<String>(personName);
    }
    if (!nullToAbsent || personNickname != null) {
      map['person_nickname'] = Variable<String>(personNickname);
    }
    map['media_id'] = Variable<String>(mediaId);
    map['bounding_box_x'] = Variable<double>(boundingBoxX);
    map['bounding_box_y'] = Variable<double>(boundingBoxY);
    map['bounding_box_width'] = Variable<double>(boundingBoxWidth);
    map['bounding_box_height'] = Variable<double>(boundingBoxHeight);
    map['confidence'] = Variable<double>(confidence);
    if (!nullToAbsent || similarity != null) {
      map['similarity'] = Variable<double>(similarity);
    }
    map['is_confirmed'] = Variable<bool>(isConfirmed);
    map['is_rejected'] = Variable<bool>(isRejected);
    map['detected_at'] = Variable<DateTime>(detectedAt);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    return map;
  }

  PersonTagsCompanion toCompanion(bool nullToAbsent) {
    return PersonTagsCompanion(
      id: Value(id),
      personId: Value(personId),
      personName: personName == null && nullToAbsent
          ? const Value.absent()
          : Value(personName),
      personNickname: personNickname == null && nullToAbsent
          ? const Value.absent()
          : Value(personNickname),
      mediaId: Value(mediaId),
      boundingBoxX: Value(boundingBoxX),
      boundingBoxY: Value(boundingBoxY),
      boundingBoxWidth: Value(boundingBoxWidth),
      boundingBoxHeight: Value(boundingBoxHeight),
      confidence: Value(confidence),
      similarity: similarity == null && nullToAbsent
          ? const Value.absent()
          : Value(similarity),
      isConfirmed: Value(isConfirmed),
      isRejected: Value(isRejected),
      detectedAt: Value(detectedAt),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory PersonTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonTag(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      personName: serializer.fromJson<String?>(json['personName']),
      personNickname: serializer.fromJson<String?>(json['personNickname']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      boundingBoxX: serializer.fromJson<double>(json['boundingBoxX']),
      boundingBoxY: serializer.fromJson<double>(json['boundingBoxY']),
      boundingBoxWidth: serializer.fromJson<double>(json['boundingBoxWidth']),
      boundingBoxHeight: serializer.fromJson<double>(json['boundingBoxHeight']),
      confidence: serializer.fromJson<double>(json['confidence']),
      similarity: serializer.fromJson<double?>(json['similarity']),
      isConfirmed: serializer.fromJson<bool>(json['isConfirmed']),
      isRejected: serializer.fromJson<bool>(json['isRejected']),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<String>(personId),
      'personName': serializer.toJson<String?>(personName),
      'personNickname': serializer.toJson<String?>(personNickname),
      'mediaId': serializer.toJson<String>(mediaId),
      'boundingBoxX': serializer.toJson<double>(boundingBoxX),
      'boundingBoxY': serializer.toJson<double>(boundingBoxY),
      'boundingBoxWidth': serializer.toJson<double>(boundingBoxWidth),
      'boundingBoxHeight': serializer.toJson<double>(boundingBoxHeight),
      'confidence': serializer.toJson<double>(confidence),
      'similarity': serializer.toJson<double?>(similarity),
      'isConfirmed': serializer.toJson<bool>(isConfirmed),
      'isRejected': serializer.toJson<bool>(isRejected),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
    };
  }

  PersonTag copyWith({
    int? id,
    String? personId,
    Value<String?> personName = const Value.absent(),
    Value<String?> personNickname = const Value.absent(),
    String? mediaId,
    double? boundingBoxX,
    double? boundingBoxY,
    double? boundingBoxWidth,
    double? boundingBoxHeight,
    double? confidence,
    Value<double?> similarity = const Value.absent(),
    bool? isConfirmed,
    bool? isRejected,
    DateTime? detectedAt,
    Value<DateTime?> confirmedAt = const Value.absent(),
  }) => PersonTag(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    personName: personName.present ? personName.value : this.personName,
    personNickname: personNickname.present
        ? personNickname.value
        : this.personNickname,
    mediaId: mediaId ?? this.mediaId,
    boundingBoxX: boundingBoxX ?? this.boundingBoxX,
    boundingBoxY: boundingBoxY ?? this.boundingBoxY,
    boundingBoxWidth: boundingBoxWidth ?? this.boundingBoxWidth,
    boundingBoxHeight: boundingBoxHeight ?? this.boundingBoxHeight,
    confidence: confidence ?? this.confidence,
    similarity: similarity.present ? similarity.value : this.similarity,
    isConfirmed: isConfirmed ?? this.isConfirmed,
    isRejected: isRejected ?? this.isRejected,
    detectedAt: detectedAt ?? this.detectedAt,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
  );
  PersonTag copyWithCompanion(PersonTagsCompanion data) {
    return PersonTag(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
      personNickname: data.personNickname.present
          ? data.personNickname.value
          : this.personNickname,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      boundingBoxX: data.boundingBoxX.present
          ? data.boundingBoxX.value
          : this.boundingBoxX,
      boundingBoxY: data.boundingBoxY.present
          ? data.boundingBoxY.value
          : this.boundingBoxY,
      boundingBoxWidth: data.boundingBoxWidth.present
          ? data.boundingBoxWidth.value
          : this.boundingBoxWidth,
      boundingBoxHeight: data.boundingBoxHeight.present
          ? data.boundingBoxHeight.value
          : this.boundingBoxHeight,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      similarity: data.similarity.present
          ? data.similarity.value
          : this.similarity,
      isConfirmed: data.isConfirmed.present
          ? data.isConfirmed.value
          : this.isConfirmed,
      isRejected: data.isRejected.present
          ? data.isRejected.value
          : this.isRejected,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonTag(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('personNickname: $personNickname, ')
          ..write('mediaId: $mediaId, ')
          ..write('boundingBoxX: $boundingBoxX, ')
          ..write('boundingBoxY: $boundingBoxY, ')
          ..write('boundingBoxWidth: $boundingBoxWidth, ')
          ..write('boundingBoxHeight: $boundingBoxHeight, ')
          ..write('confidence: $confidence, ')
          ..write('similarity: $similarity, ')
          ..write('isConfirmed: $isConfirmed, ')
          ..write('isRejected: $isRejected, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    personName,
    personNickname,
    mediaId,
    boundingBoxX,
    boundingBoxY,
    boundingBoxWidth,
    boundingBoxHeight,
    confidence,
    similarity,
    isConfirmed,
    isRejected,
    detectedAt,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonTag &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.personName == this.personName &&
          other.personNickname == this.personNickname &&
          other.mediaId == this.mediaId &&
          other.boundingBoxX == this.boundingBoxX &&
          other.boundingBoxY == this.boundingBoxY &&
          other.boundingBoxWidth == this.boundingBoxWidth &&
          other.boundingBoxHeight == this.boundingBoxHeight &&
          other.confidence == this.confidence &&
          other.similarity == this.similarity &&
          other.isConfirmed == this.isConfirmed &&
          other.isRejected == this.isRejected &&
          other.detectedAt == this.detectedAt &&
          other.confirmedAt == this.confirmedAt);
}

class PersonTagsCompanion extends UpdateCompanion<PersonTag> {
  final Value<int> id;
  final Value<String> personId;
  final Value<String?> personName;
  final Value<String?> personNickname;
  final Value<String> mediaId;
  final Value<double> boundingBoxX;
  final Value<double> boundingBoxY;
  final Value<double> boundingBoxWidth;
  final Value<double> boundingBoxHeight;
  final Value<double> confidence;
  final Value<double?> similarity;
  final Value<bool> isConfirmed;
  final Value<bool> isRejected;
  final Value<DateTime> detectedAt;
  final Value<DateTime?> confirmedAt;
  const PersonTagsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.personNickname = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.boundingBoxX = const Value.absent(),
    this.boundingBoxY = const Value.absent(),
    this.boundingBoxWidth = const Value.absent(),
    this.boundingBoxHeight = const Value.absent(),
    this.confidence = const Value.absent(),
    this.similarity = const Value.absent(),
    this.isConfirmed = const Value.absent(),
    this.isRejected = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
  });
  PersonTagsCompanion.insert({
    this.id = const Value.absent(),
    required String personId,
    this.personName = const Value.absent(),
    this.personNickname = const Value.absent(),
    required String mediaId,
    required double boundingBoxX,
    required double boundingBoxY,
    required double boundingBoxWidth,
    required double boundingBoxHeight,
    required double confidence,
    this.similarity = const Value.absent(),
    this.isConfirmed = const Value.absent(),
    this.isRejected = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
  }) : personId = Value(personId),
       mediaId = Value(mediaId),
       boundingBoxX = Value(boundingBoxX),
       boundingBoxY = Value(boundingBoxY),
       boundingBoxWidth = Value(boundingBoxWidth),
       boundingBoxHeight = Value(boundingBoxHeight),
       confidence = Value(confidence);
  static Insertable<PersonTag> custom({
    Expression<int>? id,
    Expression<String>? personId,
    Expression<String>? personName,
    Expression<String>? personNickname,
    Expression<String>? mediaId,
    Expression<double>? boundingBoxX,
    Expression<double>? boundingBoxY,
    Expression<double>? boundingBoxWidth,
    Expression<double>? boundingBoxHeight,
    Expression<double>? confidence,
    Expression<double>? similarity,
    Expression<bool>? isConfirmed,
    Expression<bool>? isRejected,
    Expression<DateTime>? detectedAt,
    Expression<DateTime>? confirmedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (personName != null) 'person_name': personName,
      if (personNickname != null) 'person_nickname': personNickname,
      if (mediaId != null) 'media_id': mediaId,
      if (boundingBoxX != null) 'bounding_box_x': boundingBoxX,
      if (boundingBoxY != null) 'bounding_box_y': boundingBoxY,
      if (boundingBoxWidth != null) 'bounding_box_width': boundingBoxWidth,
      if (boundingBoxHeight != null) 'bounding_box_height': boundingBoxHeight,
      if (confidence != null) 'confidence': confidence,
      if (similarity != null) 'similarity': similarity,
      if (isConfirmed != null) 'is_confirmed': isConfirmed,
      if (isRejected != null) 'is_rejected': isRejected,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
    });
  }

  PersonTagsCompanion copyWith({
    Value<int>? id,
    Value<String>? personId,
    Value<String?>? personName,
    Value<String?>? personNickname,
    Value<String>? mediaId,
    Value<double>? boundingBoxX,
    Value<double>? boundingBoxY,
    Value<double>? boundingBoxWidth,
    Value<double>? boundingBoxHeight,
    Value<double>? confidence,
    Value<double?>? similarity,
    Value<bool>? isConfirmed,
    Value<bool>? isRejected,
    Value<DateTime>? detectedAt,
    Value<DateTime?>? confirmedAt,
  }) {
    return PersonTagsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      personNickname: personNickname ?? this.personNickname,
      mediaId: mediaId ?? this.mediaId,
      boundingBoxX: boundingBoxX ?? this.boundingBoxX,
      boundingBoxY: boundingBoxY ?? this.boundingBoxY,
      boundingBoxWidth: boundingBoxWidth ?? this.boundingBoxWidth,
      boundingBoxHeight: boundingBoxHeight ?? this.boundingBoxHeight,
      confidence: confidence ?? this.confidence,
      similarity: similarity ?? this.similarity,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isRejected: isRejected ?? this.isRejected,
      detectedAt: detectedAt ?? this.detectedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (personNickname.present) {
      map['person_nickname'] = Variable<String>(personNickname.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (boundingBoxX.present) {
      map['bounding_box_x'] = Variable<double>(boundingBoxX.value);
    }
    if (boundingBoxY.present) {
      map['bounding_box_y'] = Variable<double>(boundingBoxY.value);
    }
    if (boundingBoxWidth.present) {
      map['bounding_box_width'] = Variable<double>(boundingBoxWidth.value);
    }
    if (boundingBoxHeight.present) {
      map['bounding_box_height'] = Variable<double>(boundingBoxHeight.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (similarity.present) {
      map['similarity'] = Variable<double>(similarity.value);
    }
    if (isConfirmed.present) {
      map['is_confirmed'] = Variable<bool>(isConfirmed.value);
    }
    if (isRejected.present) {
      map['is_rejected'] = Variable<bool>(isRejected.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonTagsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('personNickname: $personNickname, ')
          ..write('mediaId: $mediaId, ')
          ..write('boundingBoxX: $boundingBoxX, ')
          ..write('boundingBoxY: $boundingBoxY, ')
          ..write('boundingBoxWidth: $boundingBoxWidth, ')
          ..write('boundingBoxHeight: $boundingBoxHeight, ')
          ..write('confidence: $confidence, ')
          ..write('similarity: $similarity, ')
          ..write('isConfirmed: $isConfirmed, ')
          ..write('isRejected: $isRejected, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }
}

class $FaceClustersTable extends FaceClusters
    with TableInfo<$FaceClustersTable, FaceCluster> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FaceClustersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clusterIdMeta = const VerificationMeta(
    'clusterId',
  );
  @override
  late final GeneratedColumn<String> clusterId = GeneratedColumn<String>(
    'cluster_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _representativeFaceIdMeta =
      const VerificationMeta('representativeFaceId');
  @override
  late final GeneratedColumn<String> representativeFaceId =
      GeneratedColumn<String>(
        'representative_face_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _faceCountMeta = const VerificationMeta(
    'faceCount',
  );
  @override
  late final GeneratedColumn<int> faceCount = GeneratedColumn<int>(
    'face_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageConfidenceMeta = const VerificationMeta(
    'averageConfidence',
  );
  @override
  late final GeneratedColumn<double> averageConfidence =
      GeneratedColumn<double>(
        'average_confidence',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cohesionMeta = const VerificationMeta(
    'cohesion',
  );
  @override
  late final GeneratedColumn<double> cohesion = GeneratedColumn<double>(
    'cohesion',
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
    clusterId,
    personId,
    representativeFaceId,
    faceCount,
    averageConfidence,
    cohesion,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'face_clusters';
  @override
  VerificationContext validateIntegrity(
    Insertable<FaceCluster> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cluster_id')) {
      context.handle(
        _clusterIdMeta,
        clusterId.isAcceptableOrUnknown(data['cluster_id']!, _clusterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clusterIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('representative_face_id')) {
      context.handle(
        _representativeFaceIdMeta,
        representativeFaceId.isAcceptableOrUnknown(
          data['representative_face_id']!,
          _representativeFaceIdMeta,
        ),
      );
    }
    if (data.containsKey('face_count')) {
      context.handle(
        _faceCountMeta,
        faceCount.isAcceptableOrUnknown(data['face_count']!, _faceCountMeta),
      );
    } else if (isInserting) {
      context.missing(_faceCountMeta);
    }
    if (data.containsKey('average_confidence')) {
      context.handle(
        _averageConfidenceMeta,
        averageConfidence.isAcceptableOrUnknown(
          data['average_confidence']!,
          _averageConfidenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averageConfidenceMeta);
    }
    if (data.containsKey('cohesion')) {
      context.handle(
        _cohesionMeta,
        cohesion.isAcceptableOrUnknown(data['cohesion']!, _cohesionMeta),
      );
    } else if (isInserting) {
      context.missing(_cohesionMeta);
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
  Set<GeneratedColumn> get $primaryKey => {clusterId};
  @override
  FaceCluster map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FaceCluster(
      clusterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cluster_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      ),
      representativeFaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}representative_face_id'],
      ),
      faceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}face_count'],
      )!,
      averageConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_confidence'],
      )!,
      cohesion: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cohesion'],
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
  $FaceClustersTable createAlias(String alias) {
    return $FaceClustersTable(attachedDatabase, alias);
  }
}

class FaceCluster extends DataClass implements Insertable<FaceCluster> {
  final String clusterId;
  final String? personId;
  final String? representativeFaceId;
  final int faceCount;
  final double averageConfidence;
  final double cohesion;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FaceCluster({
    required this.clusterId,
    this.personId,
    this.representativeFaceId,
    required this.faceCount,
    required this.averageConfidence,
    required this.cohesion,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cluster_id'] = Variable<String>(clusterId);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<String>(personId);
    }
    if (!nullToAbsent || representativeFaceId != null) {
      map['representative_face_id'] = Variable<String>(representativeFaceId);
    }
    map['face_count'] = Variable<int>(faceCount);
    map['average_confidence'] = Variable<double>(averageConfidence);
    map['cohesion'] = Variable<double>(cohesion);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FaceClustersCompanion toCompanion(bool nullToAbsent) {
    return FaceClustersCompanion(
      clusterId: Value(clusterId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      representativeFaceId: representativeFaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(representativeFaceId),
      faceCount: Value(faceCount),
      averageConfidence: Value(averageConfidence),
      cohesion: Value(cohesion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FaceCluster.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FaceCluster(
      clusterId: serializer.fromJson<String>(json['clusterId']),
      personId: serializer.fromJson<String?>(json['personId']),
      representativeFaceId: serializer.fromJson<String?>(
        json['representativeFaceId'],
      ),
      faceCount: serializer.fromJson<int>(json['faceCount']),
      averageConfidence: serializer.fromJson<double>(json['averageConfidence']),
      cohesion: serializer.fromJson<double>(json['cohesion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clusterId': serializer.toJson<String>(clusterId),
      'personId': serializer.toJson<String?>(personId),
      'representativeFaceId': serializer.toJson<String?>(representativeFaceId),
      'faceCount': serializer.toJson<int>(faceCount),
      'averageConfidence': serializer.toJson<double>(averageConfidence),
      'cohesion': serializer.toJson<double>(cohesion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FaceCluster copyWith({
    String? clusterId,
    Value<String?> personId = const Value.absent(),
    Value<String?> representativeFaceId = const Value.absent(),
    int? faceCount,
    double? averageConfidence,
    double? cohesion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FaceCluster(
    clusterId: clusterId ?? this.clusterId,
    personId: personId.present ? personId.value : this.personId,
    representativeFaceId: representativeFaceId.present
        ? representativeFaceId.value
        : this.representativeFaceId,
    faceCount: faceCount ?? this.faceCount,
    averageConfidence: averageConfidence ?? this.averageConfidence,
    cohesion: cohesion ?? this.cohesion,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FaceCluster copyWithCompanion(FaceClustersCompanion data) {
    return FaceCluster(
      clusterId: data.clusterId.present ? data.clusterId.value : this.clusterId,
      personId: data.personId.present ? data.personId.value : this.personId,
      representativeFaceId: data.representativeFaceId.present
          ? data.representativeFaceId.value
          : this.representativeFaceId,
      faceCount: data.faceCount.present ? data.faceCount.value : this.faceCount,
      averageConfidence: data.averageConfidence.present
          ? data.averageConfidence.value
          : this.averageConfidence,
      cohesion: data.cohesion.present ? data.cohesion.value : this.cohesion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FaceCluster(')
          ..write('clusterId: $clusterId, ')
          ..write('personId: $personId, ')
          ..write('representativeFaceId: $representativeFaceId, ')
          ..write('faceCount: $faceCount, ')
          ..write('averageConfidence: $averageConfidence, ')
          ..write('cohesion: $cohesion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clusterId,
    personId,
    representativeFaceId,
    faceCount,
    averageConfidence,
    cohesion,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FaceCluster &&
          other.clusterId == this.clusterId &&
          other.personId == this.personId &&
          other.representativeFaceId == this.representativeFaceId &&
          other.faceCount == this.faceCount &&
          other.averageConfidence == this.averageConfidence &&
          other.cohesion == this.cohesion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FaceClustersCompanion extends UpdateCompanion<FaceCluster> {
  final Value<String> clusterId;
  final Value<String?> personId;
  final Value<String?> representativeFaceId;
  final Value<int> faceCount;
  final Value<double> averageConfidence;
  final Value<double> cohesion;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FaceClustersCompanion({
    this.clusterId = const Value.absent(),
    this.personId = const Value.absent(),
    this.representativeFaceId = const Value.absent(),
    this.faceCount = const Value.absent(),
    this.averageConfidence = const Value.absent(),
    this.cohesion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FaceClustersCompanion.insert({
    required String clusterId,
    this.personId = const Value.absent(),
    this.representativeFaceId = const Value.absent(),
    required int faceCount,
    required double averageConfidence,
    required double cohesion,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clusterId = Value(clusterId),
       faceCount = Value(faceCount),
       averageConfidence = Value(averageConfidence),
       cohesion = Value(cohesion);
  static Insertable<FaceCluster> custom({
    Expression<String>? clusterId,
    Expression<String>? personId,
    Expression<String>? representativeFaceId,
    Expression<int>? faceCount,
    Expression<double>? averageConfidence,
    Expression<double>? cohesion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clusterId != null) 'cluster_id': clusterId,
      if (personId != null) 'person_id': personId,
      if (representativeFaceId != null)
        'representative_face_id': representativeFaceId,
      if (faceCount != null) 'face_count': faceCount,
      if (averageConfidence != null) 'average_confidence': averageConfidence,
      if (cohesion != null) 'cohesion': cohesion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FaceClustersCompanion copyWith({
    Value<String>? clusterId,
    Value<String?>? personId,
    Value<String?>? representativeFaceId,
    Value<int>? faceCount,
    Value<double>? averageConfidence,
    Value<double>? cohesion,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FaceClustersCompanion(
      clusterId: clusterId ?? this.clusterId,
      personId: personId ?? this.personId,
      representativeFaceId: representativeFaceId ?? this.representativeFaceId,
      faceCount: faceCount ?? this.faceCount,
      averageConfidence: averageConfidence ?? this.averageConfidence,
      cohesion: cohesion ?? this.cohesion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clusterId.present) {
      map['cluster_id'] = Variable<String>(clusterId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (representativeFaceId.present) {
      map['representative_face_id'] = Variable<String>(
        representativeFaceId.value,
      );
    }
    if (faceCount.present) {
      map['face_count'] = Variable<int>(faceCount.value);
    }
    if (averageConfidence.present) {
      map['average_confidence'] = Variable<double>(averageConfidence.value);
    }
    if (cohesion.present) {
      map['cohesion'] = Variable<double>(cohesion.value);
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
    return (StringBuffer('FaceClustersCompanion(')
          ..write('clusterId: $clusterId, ')
          ..write('personId: $personId, ')
          ..write('representativeFaceId: $representativeFaceId, ')
          ..write('faceCount: $faceCount, ')
          ..write('averageConfidence: $averageConfidence, ')
          ..write('cohesion: $cohesion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FaceEmbeddingsTable extends FaceEmbeddings
    with TableInfo<$FaceEmbeddingsTable, FaceEmbedding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FaceEmbeddingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _faceIdMeta = const VerificationMeta('faceId');
  @override
  late final GeneratedColumn<String> faceId = GeneratedColumn<String>(
    'face_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _clusterIdMeta = const VerificationMeta(
    'clusterId',
  );
  @override
  late final GeneratedColumn<String> clusterId = GeneratedColumn<String>(
    'cluster_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES face_clusters (cluster_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<String> embedding = GeneratedColumn<String>(
    'embedding',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityScoreMeta = const VerificationMeta(
    'qualityScore',
  );
  @override
  late final GeneratedColumn<double> qualityScore = GeneratedColumn<double>(
    'quality_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingBoxXMeta = const VerificationMeta(
    'boundingBoxX',
  );
  @override
  late final GeneratedColumn<double> boundingBoxX = GeneratedColumn<double>(
    'bounding_box_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingBoxYMeta = const VerificationMeta(
    'boundingBoxY',
  );
  @override
  late final GeneratedColumn<double> boundingBoxY = GeneratedColumn<double>(
    'bounding_box_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingBoxWidthMeta = const VerificationMeta(
    'boundingBoxWidth',
  );
  @override
  late final GeneratedColumn<double> boundingBoxWidth = GeneratedColumn<double>(
    'bounding_box_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingBoxHeightMeta = const VerificationMeta(
    'boundingBoxHeight',
  );
  @override
  late final GeneratedColumn<double> boundingBoxHeight =
      GeneratedColumn<double>(
        'bounding_box_height',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _extractedAtMeta = const VerificationMeta(
    'extractedAt',
  );
  @override
  late final GeneratedColumn<DateTime> extractedAt = GeneratedColumn<DateTime>(
    'extracted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    faceId,
    mediaId,
    clusterId,
    embedding,
    qualityScore,
    boundingBoxX,
    boundingBoxY,
    boundingBoxWidth,
    boundingBoxHeight,
    extractedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'face_embeddings';
  @override
  VerificationContext validateIntegrity(
    Insertable<FaceEmbedding> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('face_id')) {
      context.handle(
        _faceIdMeta,
        faceId.isAcceptableOrUnknown(data['face_id']!, _faceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_faceIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('cluster_id')) {
      context.handle(
        _clusterIdMeta,
        clusterId.isAcceptableOrUnknown(data['cluster_id']!, _clusterIdMeta),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    } else if (isInserting) {
      context.missing(_embeddingMeta);
    }
    if (data.containsKey('quality_score')) {
      context.handle(
        _qualityScoreMeta,
        qualityScore.isAcceptableOrUnknown(
          data['quality_score']!,
          _qualityScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_qualityScoreMeta);
    }
    if (data.containsKey('bounding_box_x')) {
      context.handle(
        _boundingBoxXMeta,
        boundingBoxX.isAcceptableOrUnknown(
          data['bounding_box_x']!,
          _boundingBoxXMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingBoxXMeta);
    }
    if (data.containsKey('bounding_box_y')) {
      context.handle(
        _boundingBoxYMeta,
        boundingBoxY.isAcceptableOrUnknown(
          data['bounding_box_y']!,
          _boundingBoxYMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingBoxYMeta);
    }
    if (data.containsKey('bounding_box_width')) {
      context.handle(
        _boundingBoxWidthMeta,
        boundingBoxWidth.isAcceptableOrUnknown(
          data['bounding_box_width']!,
          _boundingBoxWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingBoxWidthMeta);
    }
    if (data.containsKey('bounding_box_height')) {
      context.handle(
        _boundingBoxHeightMeta,
        boundingBoxHeight.isAcceptableOrUnknown(
          data['bounding_box_height']!,
          _boundingBoxHeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingBoxHeightMeta);
    }
    if (data.containsKey('extracted_at')) {
      context.handle(
        _extractedAtMeta,
        extractedAt.isAcceptableOrUnknown(
          data['extracted_at']!,
          _extractedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {faceId},
    {mediaId, boundingBoxX, boundingBoxY, boundingBoxWidth, boundingBoxHeight},
  ];
  @override
  FaceEmbedding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FaceEmbedding(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      faceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      clusterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cluster_id'],
      ),
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding'],
      )!,
      qualityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quality_score'],
      )!,
      boundingBoxX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_box_x'],
      )!,
      boundingBoxY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_box_y'],
      )!,
      boundingBoxWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_box_width'],
      )!,
      boundingBoxHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_box_height'],
      )!,
      extractedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}extracted_at'],
      )!,
    );
  }

  @override
  $FaceEmbeddingsTable createAlias(String alias) {
    return $FaceEmbeddingsTable(attachedDatabase, alias);
  }
}

class FaceEmbedding extends DataClass implements Insertable<FaceEmbedding> {
  final int id;
  final String faceId;
  final String mediaId;
  final String? clusterId;
  final String embedding;
  final double qualityScore;
  final double boundingBoxX;
  final double boundingBoxY;
  final double boundingBoxWidth;
  final double boundingBoxHeight;
  final DateTime extractedAt;
  const FaceEmbedding({
    required this.id,
    required this.faceId,
    required this.mediaId,
    this.clusterId,
    required this.embedding,
    required this.qualityScore,
    required this.boundingBoxX,
    required this.boundingBoxY,
    required this.boundingBoxWidth,
    required this.boundingBoxHeight,
    required this.extractedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['face_id'] = Variable<String>(faceId);
    map['media_id'] = Variable<String>(mediaId);
    if (!nullToAbsent || clusterId != null) {
      map['cluster_id'] = Variable<String>(clusterId);
    }
    map['embedding'] = Variable<String>(embedding);
    map['quality_score'] = Variable<double>(qualityScore);
    map['bounding_box_x'] = Variable<double>(boundingBoxX);
    map['bounding_box_y'] = Variable<double>(boundingBoxY);
    map['bounding_box_width'] = Variable<double>(boundingBoxWidth);
    map['bounding_box_height'] = Variable<double>(boundingBoxHeight);
    map['extracted_at'] = Variable<DateTime>(extractedAt);
    return map;
  }

  FaceEmbeddingsCompanion toCompanion(bool nullToAbsent) {
    return FaceEmbeddingsCompanion(
      id: Value(id),
      faceId: Value(faceId),
      mediaId: Value(mediaId),
      clusterId: clusterId == null && nullToAbsent
          ? const Value.absent()
          : Value(clusterId),
      embedding: Value(embedding),
      qualityScore: Value(qualityScore),
      boundingBoxX: Value(boundingBoxX),
      boundingBoxY: Value(boundingBoxY),
      boundingBoxWidth: Value(boundingBoxWidth),
      boundingBoxHeight: Value(boundingBoxHeight),
      extractedAt: Value(extractedAt),
    );
  }

  factory FaceEmbedding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FaceEmbedding(
      id: serializer.fromJson<int>(json['id']),
      faceId: serializer.fromJson<String>(json['faceId']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      clusterId: serializer.fromJson<String?>(json['clusterId']),
      embedding: serializer.fromJson<String>(json['embedding']),
      qualityScore: serializer.fromJson<double>(json['qualityScore']),
      boundingBoxX: serializer.fromJson<double>(json['boundingBoxX']),
      boundingBoxY: serializer.fromJson<double>(json['boundingBoxY']),
      boundingBoxWidth: serializer.fromJson<double>(json['boundingBoxWidth']),
      boundingBoxHeight: serializer.fromJson<double>(json['boundingBoxHeight']),
      extractedAt: serializer.fromJson<DateTime>(json['extractedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'faceId': serializer.toJson<String>(faceId),
      'mediaId': serializer.toJson<String>(mediaId),
      'clusterId': serializer.toJson<String?>(clusterId),
      'embedding': serializer.toJson<String>(embedding),
      'qualityScore': serializer.toJson<double>(qualityScore),
      'boundingBoxX': serializer.toJson<double>(boundingBoxX),
      'boundingBoxY': serializer.toJson<double>(boundingBoxY),
      'boundingBoxWidth': serializer.toJson<double>(boundingBoxWidth),
      'boundingBoxHeight': serializer.toJson<double>(boundingBoxHeight),
      'extractedAt': serializer.toJson<DateTime>(extractedAt),
    };
  }

  FaceEmbedding copyWith({
    int? id,
    String? faceId,
    String? mediaId,
    Value<String?> clusterId = const Value.absent(),
    String? embedding,
    double? qualityScore,
    double? boundingBoxX,
    double? boundingBoxY,
    double? boundingBoxWidth,
    double? boundingBoxHeight,
    DateTime? extractedAt,
  }) => FaceEmbedding(
    id: id ?? this.id,
    faceId: faceId ?? this.faceId,
    mediaId: mediaId ?? this.mediaId,
    clusterId: clusterId.present ? clusterId.value : this.clusterId,
    embedding: embedding ?? this.embedding,
    qualityScore: qualityScore ?? this.qualityScore,
    boundingBoxX: boundingBoxX ?? this.boundingBoxX,
    boundingBoxY: boundingBoxY ?? this.boundingBoxY,
    boundingBoxWidth: boundingBoxWidth ?? this.boundingBoxWidth,
    boundingBoxHeight: boundingBoxHeight ?? this.boundingBoxHeight,
    extractedAt: extractedAt ?? this.extractedAt,
  );
  FaceEmbedding copyWithCompanion(FaceEmbeddingsCompanion data) {
    return FaceEmbedding(
      id: data.id.present ? data.id.value : this.id,
      faceId: data.faceId.present ? data.faceId.value : this.faceId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      clusterId: data.clusterId.present ? data.clusterId.value : this.clusterId,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      qualityScore: data.qualityScore.present
          ? data.qualityScore.value
          : this.qualityScore,
      boundingBoxX: data.boundingBoxX.present
          ? data.boundingBoxX.value
          : this.boundingBoxX,
      boundingBoxY: data.boundingBoxY.present
          ? data.boundingBoxY.value
          : this.boundingBoxY,
      boundingBoxWidth: data.boundingBoxWidth.present
          ? data.boundingBoxWidth.value
          : this.boundingBoxWidth,
      boundingBoxHeight: data.boundingBoxHeight.present
          ? data.boundingBoxHeight.value
          : this.boundingBoxHeight,
      extractedAt: data.extractedAt.present
          ? data.extractedAt.value
          : this.extractedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FaceEmbedding(')
          ..write('id: $id, ')
          ..write('faceId: $faceId, ')
          ..write('mediaId: $mediaId, ')
          ..write('clusterId: $clusterId, ')
          ..write('embedding: $embedding, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('boundingBoxX: $boundingBoxX, ')
          ..write('boundingBoxY: $boundingBoxY, ')
          ..write('boundingBoxWidth: $boundingBoxWidth, ')
          ..write('boundingBoxHeight: $boundingBoxHeight, ')
          ..write('extractedAt: $extractedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    faceId,
    mediaId,
    clusterId,
    embedding,
    qualityScore,
    boundingBoxX,
    boundingBoxY,
    boundingBoxWidth,
    boundingBoxHeight,
    extractedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FaceEmbedding &&
          other.id == this.id &&
          other.faceId == this.faceId &&
          other.mediaId == this.mediaId &&
          other.clusterId == this.clusterId &&
          other.embedding == this.embedding &&
          other.qualityScore == this.qualityScore &&
          other.boundingBoxX == this.boundingBoxX &&
          other.boundingBoxY == this.boundingBoxY &&
          other.boundingBoxWidth == this.boundingBoxWidth &&
          other.boundingBoxHeight == this.boundingBoxHeight &&
          other.extractedAt == this.extractedAt);
}

class FaceEmbeddingsCompanion extends UpdateCompanion<FaceEmbedding> {
  final Value<int> id;
  final Value<String> faceId;
  final Value<String> mediaId;
  final Value<String?> clusterId;
  final Value<String> embedding;
  final Value<double> qualityScore;
  final Value<double> boundingBoxX;
  final Value<double> boundingBoxY;
  final Value<double> boundingBoxWidth;
  final Value<double> boundingBoxHeight;
  final Value<DateTime> extractedAt;
  const FaceEmbeddingsCompanion({
    this.id = const Value.absent(),
    this.faceId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.clusterId = const Value.absent(),
    this.embedding = const Value.absent(),
    this.qualityScore = const Value.absent(),
    this.boundingBoxX = const Value.absent(),
    this.boundingBoxY = const Value.absent(),
    this.boundingBoxWidth = const Value.absent(),
    this.boundingBoxHeight = const Value.absent(),
    this.extractedAt = const Value.absent(),
  });
  FaceEmbeddingsCompanion.insert({
    this.id = const Value.absent(),
    required String faceId,
    required String mediaId,
    this.clusterId = const Value.absent(),
    required String embedding,
    required double qualityScore,
    required double boundingBoxX,
    required double boundingBoxY,
    required double boundingBoxWidth,
    required double boundingBoxHeight,
    this.extractedAt = const Value.absent(),
  }) : faceId = Value(faceId),
       mediaId = Value(mediaId),
       embedding = Value(embedding),
       qualityScore = Value(qualityScore),
       boundingBoxX = Value(boundingBoxX),
       boundingBoxY = Value(boundingBoxY),
       boundingBoxWidth = Value(boundingBoxWidth),
       boundingBoxHeight = Value(boundingBoxHeight);
  static Insertable<FaceEmbedding> custom({
    Expression<int>? id,
    Expression<String>? faceId,
    Expression<String>? mediaId,
    Expression<String>? clusterId,
    Expression<String>? embedding,
    Expression<double>? qualityScore,
    Expression<double>? boundingBoxX,
    Expression<double>? boundingBoxY,
    Expression<double>? boundingBoxWidth,
    Expression<double>? boundingBoxHeight,
    Expression<DateTime>? extractedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (faceId != null) 'face_id': faceId,
      if (mediaId != null) 'media_id': mediaId,
      if (clusterId != null) 'cluster_id': clusterId,
      if (embedding != null) 'embedding': embedding,
      if (qualityScore != null) 'quality_score': qualityScore,
      if (boundingBoxX != null) 'bounding_box_x': boundingBoxX,
      if (boundingBoxY != null) 'bounding_box_y': boundingBoxY,
      if (boundingBoxWidth != null) 'bounding_box_width': boundingBoxWidth,
      if (boundingBoxHeight != null) 'bounding_box_height': boundingBoxHeight,
      if (extractedAt != null) 'extracted_at': extractedAt,
    });
  }

  FaceEmbeddingsCompanion copyWith({
    Value<int>? id,
    Value<String>? faceId,
    Value<String>? mediaId,
    Value<String?>? clusterId,
    Value<String>? embedding,
    Value<double>? qualityScore,
    Value<double>? boundingBoxX,
    Value<double>? boundingBoxY,
    Value<double>? boundingBoxWidth,
    Value<double>? boundingBoxHeight,
    Value<DateTime>? extractedAt,
  }) {
    return FaceEmbeddingsCompanion(
      id: id ?? this.id,
      faceId: faceId ?? this.faceId,
      mediaId: mediaId ?? this.mediaId,
      clusterId: clusterId ?? this.clusterId,
      embedding: embedding ?? this.embedding,
      qualityScore: qualityScore ?? this.qualityScore,
      boundingBoxX: boundingBoxX ?? this.boundingBoxX,
      boundingBoxY: boundingBoxY ?? this.boundingBoxY,
      boundingBoxWidth: boundingBoxWidth ?? this.boundingBoxWidth,
      boundingBoxHeight: boundingBoxHeight ?? this.boundingBoxHeight,
      extractedAt: extractedAt ?? this.extractedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (faceId.present) {
      map['face_id'] = Variable<String>(faceId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (clusterId.present) {
      map['cluster_id'] = Variable<String>(clusterId.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<String>(embedding.value);
    }
    if (qualityScore.present) {
      map['quality_score'] = Variable<double>(qualityScore.value);
    }
    if (boundingBoxX.present) {
      map['bounding_box_x'] = Variable<double>(boundingBoxX.value);
    }
    if (boundingBoxY.present) {
      map['bounding_box_y'] = Variable<double>(boundingBoxY.value);
    }
    if (boundingBoxWidth.present) {
      map['bounding_box_width'] = Variable<double>(boundingBoxWidth.value);
    }
    if (boundingBoxHeight.present) {
      map['bounding_box_height'] = Variable<double>(boundingBoxHeight.value);
    }
    if (extractedAt.present) {
      map['extracted_at'] = Variable<DateTime>(extractedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FaceEmbeddingsCompanion(')
          ..write('id: $id, ')
          ..write('faceId: $faceId, ')
          ..write('mediaId: $mediaId, ')
          ..write('clusterId: $clusterId, ')
          ..write('embedding: $embedding, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('boundingBoxX: $boundingBoxX, ')
          ..write('boundingBoxY: $boundingBoxY, ')
          ..write('boundingBoxWidth: $boundingBoxWidth, ')
          ..write('boundingBoxHeight: $boundingBoxHeight, ')
          ..write('extractedAt: $extractedAt')
          ..write(')'))
        .toString();
  }
}

class $MediaCollectionsTable extends MediaCollections
    with TableInfo<$MediaCollectionsTable, MediaCollection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaCollectionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverMediaIdMeta = const VerificationMeta(
    'coverMediaId',
  );
  @override
  late final GeneratedColumn<String> coverMediaId = GeneratedColumn<String>(
    'cover_media_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _mediaCountMeta = const VerificationMeta(
    'mediaCount',
  );
  @override
  late final GeneratedColumn<int> mediaCount = GeneratedColumn<int>(
    'media_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSystemCollectionMeta =
      const VerificationMeta('isSystemCollection');
  @override
  late final GeneratedColumn<bool> isSystemCollection = GeneratedColumn<bool>(
    'is_system_collection',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system_collection" IN (0, 1))',
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
    description,
    coverMediaId,
    mediaCount,
    isSystemCollection,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaCollection> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cover_media_id')) {
      context.handle(
        _coverMediaIdMeta,
        coverMediaId.isAcceptableOrUnknown(
          data['cover_media_id']!,
          _coverMediaIdMeta,
        ),
      );
    }
    if (data.containsKey('media_count')) {
      context.handle(
        _mediaCountMeta,
        mediaCount.isAcceptableOrUnknown(data['media_count']!, _mediaCountMeta),
      );
    }
    if (data.containsKey('is_system_collection')) {
      context.handle(
        _isSystemCollectionMeta,
        isSystemCollection.isAcceptableOrUnknown(
          data['is_system_collection']!,
          _isSystemCollectionMeta,
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
  MediaCollection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaCollection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      coverMediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_media_id'],
      ),
      mediaCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_count'],
      )!,
      isSystemCollection: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system_collection'],
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
  $MediaCollectionsTable createAlias(String alias) {
    return $MediaCollectionsTable(attachedDatabase, alias);
  }
}

class MediaCollection extends DataClass implements Insertable<MediaCollection> {
  final String id;
  final String name;
  final String? description;
  final String? coverMediaId;
  final int mediaCount;
  final bool isSystemCollection;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MediaCollection({
    required this.id,
    required this.name,
    this.description,
    this.coverMediaId,
    required this.mediaCount,
    required this.isSystemCollection,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || coverMediaId != null) {
      map['cover_media_id'] = Variable<String>(coverMediaId);
    }
    map['media_count'] = Variable<int>(mediaCount);
    map['is_system_collection'] = Variable<bool>(isSystemCollection);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MediaCollectionsCompanion toCompanion(bool nullToAbsent) {
    return MediaCollectionsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      coverMediaId: coverMediaId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverMediaId),
      mediaCount: Value(mediaCount),
      isSystemCollection: Value(isSystemCollection),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MediaCollection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaCollection(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      coverMediaId: serializer.fromJson<String?>(json['coverMediaId']),
      mediaCount: serializer.fromJson<int>(json['mediaCount']),
      isSystemCollection: serializer.fromJson<bool>(json['isSystemCollection']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'coverMediaId': serializer.toJson<String?>(coverMediaId),
      'mediaCount': serializer.toJson<int>(mediaCount),
      'isSystemCollection': serializer.toJson<bool>(isSystemCollection),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MediaCollection copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> coverMediaId = const Value.absent(),
    int? mediaCount,
    bool? isSystemCollection,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MediaCollection(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    coverMediaId: coverMediaId.present ? coverMediaId.value : this.coverMediaId,
    mediaCount: mediaCount ?? this.mediaCount,
    isSystemCollection: isSystemCollection ?? this.isSystemCollection,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MediaCollection copyWithCompanion(MediaCollectionsCompanion data) {
    return MediaCollection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      coverMediaId: data.coverMediaId.present
          ? data.coverMediaId.value
          : this.coverMediaId,
      mediaCount: data.mediaCount.present
          ? data.mediaCount.value
          : this.mediaCount,
      isSystemCollection: data.isSystemCollection.present
          ? data.isSystemCollection.value
          : this.isSystemCollection,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaCollection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverMediaId: $coverMediaId, ')
          ..write('mediaCount: $mediaCount, ')
          ..write('isSystemCollection: $isSystemCollection, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    coverMediaId,
    mediaCount,
    isSystemCollection,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaCollection &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.coverMediaId == this.coverMediaId &&
          other.mediaCount == this.mediaCount &&
          other.isSystemCollection == this.isSystemCollection &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MediaCollectionsCompanion extends UpdateCompanion<MediaCollection> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> coverMediaId;
  final Value<int> mediaCount;
  final Value<bool> isSystemCollection;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MediaCollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.coverMediaId = const Value.absent(),
    this.mediaCount = const Value.absent(),
    this.isSystemCollection = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaCollectionsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.coverMediaId = const Value.absent(),
    this.mediaCount = const Value.absent(),
    this.isSystemCollection = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<MediaCollection> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? coverMediaId,
    Expression<int>? mediaCount,
    Expression<bool>? isSystemCollection,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (coverMediaId != null) 'cover_media_id': coverMediaId,
      if (mediaCount != null) 'media_count': mediaCount,
      if (isSystemCollection != null)
        'is_system_collection': isSystemCollection,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaCollectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? coverMediaId,
    Value<int>? mediaCount,
    Value<bool>? isSystemCollection,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MediaCollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverMediaId: coverMediaId ?? this.coverMediaId,
      mediaCount: mediaCount ?? this.mediaCount,
      isSystemCollection: isSystemCollection ?? this.isSystemCollection,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverMediaId.present) {
      map['cover_media_id'] = Variable<String>(coverMediaId.value);
    }
    if (mediaCount.present) {
      map['media_count'] = Variable<int>(mediaCount.value);
    }
    if (isSystemCollection.present) {
      map['is_system_collection'] = Variable<bool>(isSystemCollection.value);
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
    return (StringBuffer('MediaCollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverMediaId: $coverMediaId, ')
          ..write('mediaCount: $mediaCount, ')
          ..write('isSystemCollection: $isSystemCollection, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaCollectionItemsTable extends MediaCollectionItems
    with TableInfo<$MediaCollectionItemsTable, MediaCollectionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaCollectionItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_collections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    collectionId,
    mediaId,
    sortOrder,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_collection_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaCollectionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {collectionId, mediaId},
  ];
  @override
  MediaCollectionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaCollectionItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $MediaCollectionItemsTable createAlias(String alias) {
    return $MediaCollectionItemsTable(attachedDatabase, alias);
  }
}

class MediaCollectionItem extends DataClass
    implements Insertable<MediaCollectionItem> {
  final int id;
  final String collectionId;
  final String mediaId;
  final int? sortOrder;
  final DateTime addedAt;
  const MediaCollectionItem({
    required this.id,
    required this.collectionId,
    required this.mediaId,
    this.sortOrder,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['collection_id'] = Variable<String>(collectionId);
    map['media_id'] = Variable<String>(mediaId);
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  MediaCollectionItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaCollectionItemsCompanion(
      id: Value(id),
      collectionId: Value(collectionId),
      mediaId: Value(mediaId),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
      addedAt: Value(addedAt),
    );
  }

  factory MediaCollectionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaCollectionItem(
      id: serializer.fromJson<int>(json['id']),
      collectionId: serializer.fromJson<String>(json['collectionId']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      sortOrder: serializer.fromJson<int?>(json['sortOrder']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'collectionId': serializer.toJson<String>(collectionId),
      'mediaId': serializer.toJson<String>(mediaId),
      'sortOrder': serializer.toJson<int?>(sortOrder),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  MediaCollectionItem copyWith({
    int? id,
    String? collectionId,
    String? mediaId,
    Value<int?> sortOrder = const Value.absent(),
    DateTime? addedAt,
  }) => MediaCollectionItem(
    id: id ?? this.id,
    collectionId: collectionId ?? this.collectionId,
    mediaId: mediaId ?? this.mediaId,
    sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
    addedAt: addedAt ?? this.addedAt,
  );
  MediaCollectionItem copyWithCompanion(MediaCollectionItemsCompanion data) {
    return MediaCollectionItem(
      id: data.id.present ? data.id.value : this.id,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaCollectionItem(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('mediaId: $mediaId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, collectionId, mediaId, sortOrder, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaCollectionItem &&
          other.id == this.id &&
          other.collectionId == this.collectionId &&
          other.mediaId == this.mediaId &&
          other.sortOrder == this.sortOrder &&
          other.addedAt == this.addedAt);
}

class MediaCollectionItemsCompanion
    extends UpdateCompanion<MediaCollectionItem> {
  final Value<int> id;
  final Value<String> collectionId;
  final Value<String> mediaId;
  final Value<int?> sortOrder;
  final Value<DateTime> addedAt;
  const MediaCollectionItemsCompanion({
    this.id = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  MediaCollectionItemsCompanion.insert({
    this.id = const Value.absent(),
    required String collectionId,
    required String mediaId,
    this.sortOrder = const Value.absent(),
    this.addedAt = const Value.absent(),
  }) : collectionId = Value(collectionId),
       mediaId = Value(mediaId);
  static Insertable<MediaCollectionItem> custom({
    Expression<int>? id,
    Expression<String>? collectionId,
    Expression<String>? mediaId,
    Expression<int>? sortOrder,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectionId != null) 'collection_id': collectionId,
      if (mediaId != null) 'media_id': mediaId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  MediaCollectionItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? collectionId,
    Value<String>? mediaId,
    Value<int?>? sortOrder,
    Value<DateTime>? addedAt,
  }) {
    return MediaCollectionItemsCompanion(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      mediaId: mediaId ?? this.mediaId,
      sortOrder: sortOrder ?? this.sortOrder,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaCollectionItemsCompanion(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('mediaId: $mediaId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$MediaDatabase extends GeneratedDatabase {
  _$MediaDatabase(QueryExecutor e) : super(e);
  $MediaDatabaseManager get managers => $MediaDatabaseManager(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $MediaMetadataTable mediaMetadata = $MediaMetadataTable(this);
  late final $PersonTagsTable personTags = $PersonTagsTable(this);
  late final $FaceClustersTable faceClusters = $FaceClustersTable(this);
  late final $FaceEmbeddingsTable faceEmbeddings = $FaceEmbeddingsTable(this);
  late final $MediaCollectionsTable mediaCollections = $MediaCollectionsTable(
    this,
  );
  late final $MediaCollectionItemsTable mediaCollectionItems =
      $MediaCollectionItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mediaItems,
    mediaMetadata,
    personTags,
    faceClusters,
    faceEmbeddings,
    mediaCollections,
    mediaCollectionItems,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('media_metadata', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('person_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('face_embeddings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'face_clusters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('face_embeddings', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('media_collections', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_collections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('media_collection_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('media_collection_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MediaItemsTableCreateCompanionBuilder =
    MediaItemsCompanion Function({
      required String id,
      Value<String?> filePath,
      required String fileName,
      required String mimeType,
      required int fileSize,
      Value<String?> fileHash,
      required DateTime createdDate,
      required DateTime modifiedDate,
      Value<DateTime> addedDate,
      Value<bool> isDeleted,
      Value<bool> isProcessed,
      Value<int?> width,
      Value<int?> height,
      Value<int?> duration,
      Value<int> rowid,
    });
typedef $$MediaItemsTableUpdateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<String> id,
      Value<String?> filePath,
      Value<String> fileName,
      Value<String> mimeType,
      Value<int> fileSize,
      Value<String?> fileHash,
      Value<DateTime> createdDate,
      Value<DateTime> modifiedDate,
      Value<DateTime> addedDate,
      Value<bool> isDeleted,
      Value<bool> isProcessed,
      Value<int?> width,
      Value<int?> height,
      Value<int?> duration,
      Value<int> rowid,
    });

final class $$MediaItemsTableReferences
    extends BaseReferences<_$MediaDatabase, $MediaItemsTable, MediaItem> {
  $$MediaItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaMetadataTable, List<MediaMetadataData>>
  _mediaMetadataRefsTable(_$MediaDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaMetadata,
    aliasName: $_aliasNameGenerator(db.mediaItems.id, db.mediaMetadata.mediaId),
  );

  $$MediaMetadataTableProcessedTableManager get mediaMetadataRefs {
    final manager = $$MediaMetadataTableTableManager(
      $_db,
      $_db.mediaMetadata,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaMetadataRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PersonTagsTable, List<PersonTag>>
  _personTagsRefsTable(_$MediaDatabase db) => MultiTypedResultKey.fromTable(
    db.personTags,
    aliasName: $_aliasNameGenerator(db.mediaItems.id, db.personTags.mediaId),
  );

  $$PersonTagsTableProcessedTableManager get personTagsRefs {
    final manager = $$PersonTagsTableTableManager(
      $_db,
      $_db.personTags,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_personTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FaceEmbeddingsTable, List<FaceEmbedding>>
  _faceEmbeddingsRefsTable(_$MediaDatabase db) => MultiTypedResultKey.fromTable(
    db.faceEmbeddings,
    aliasName: $_aliasNameGenerator(
      db.mediaItems.id,
      db.faceEmbeddings.mediaId,
    ),
  );

  $$FaceEmbeddingsTableProcessedTableManager get faceEmbeddingsRefs {
    final manager = $$FaceEmbeddingsTableTableManager(
      $_db,
      $_db.faceEmbeddings,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_faceEmbeddingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MediaCollectionsTable, List<MediaCollection>>
  _mediaCollectionsRefsTable(_$MediaDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.mediaCollections,
        aliasName: $_aliasNameGenerator(
          db.mediaItems.id,
          db.mediaCollections.coverMediaId,
        ),
      );

  $$MediaCollectionsTableProcessedTableManager get mediaCollectionsRefs {
    final manager = $$MediaCollectionsTableTableManager(
      $_db,
      $_db.mediaCollections,
    ).filter((f) => f.coverMediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _mediaCollectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MediaCollectionItemsTable,
    List<MediaCollectionItem>
  >
  _mediaCollectionItemsRefsTable(_$MediaDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.mediaCollectionItems,
        aliasName: $_aliasNameGenerator(
          db.mediaItems.id,
          db.mediaCollectionItems.mediaId,
        ),
      );

  $$MediaCollectionItemsTableProcessedTableManager
  get mediaCollectionItemsRefs {
    final manager = $$MediaCollectionItemsTableTableManager(
      $_db,
      $_db.mediaCollectionItems,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _mediaCollectionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MediaItemsTableFilterComposer
    extends Composer<_$MediaDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
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

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedDate => $composableBuilder(
    column: $table.modifiedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedDate => $composableBuilder(
    column: $table.addedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isProcessed => $composableBuilder(
    column: $table.isProcessed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaMetadataRefs(
    Expression<bool> Function($$MediaMetadataTableFilterComposer f) f,
  ) {
    final $$MediaMetadataTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaMetadata,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaMetadataTableFilterComposer(
            $db: $db,
            $table: $db.mediaMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> personTagsRefs(
    Expression<bool> Function($$PersonTagsTableFilterComposer f) f,
  ) {
    final $$PersonTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personTags,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonTagsTableFilterComposer(
            $db: $db,
            $table: $db.personTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> faceEmbeddingsRefs(
    Expression<bool> Function($$FaceEmbeddingsTableFilterComposer f) f,
  ) {
    final $$FaceEmbeddingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.faceEmbeddings,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceEmbeddingsTableFilterComposer(
            $db: $db,
            $table: $db.faceEmbeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mediaCollectionsRefs(
    Expression<bool> Function($$MediaCollectionsTableFilterComposer f) f,
  ) {
    final $$MediaCollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaCollections,
      getReferencedColumn: (t) => t.coverMediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaCollectionsTableFilterComposer(
            $db: $db,
            $table: $db.mediaCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mediaCollectionItemsRefs(
    Expression<bool> Function($$MediaCollectionItemsTableFilterComposer f) f,
  ) {
    final $$MediaCollectionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaCollectionItems,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaCollectionItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaCollectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$MediaDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
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

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedDate => $composableBuilder(
    column: $table.modifiedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedDate => $composableBuilder(
    column: $table.addedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isProcessed => $composableBuilder(
    column: $table.isProcessed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$MediaDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get modifiedDate => $composableBuilder(
    column: $table.modifiedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedDate =>
      $composableBuilder(column: $table.addedDate, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isProcessed => $composableBuilder(
    column: $table.isProcessed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  Expression<T> mediaMetadataRefs<T extends Object>(
    Expression<T> Function($$MediaMetadataTableAnnotationComposer a) f,
  ) {
    final $$MediaMetadataTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaMetadata,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaMetadataTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> personTagsRefs<T extends Object>(
    Expression<T> Function($$PersonTagsTableAnnotationComposer a) f,
  ) {
    final $$PersonTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personTags,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.personTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> faceEmbeddingsRefs<T extends Object>(
    Expression<T> Function($$FaceEmbeddingsTableAnnotationComposer a) f,
  ) {
    final $$FaceEmbeddingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.faceEmbeddings,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceEmbeddingsTableAnnotationComposer(
            $db: $db,
            $table: $db.faceEmbeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mediaCollectionsRefs<T extends Object>(
    Expression<T> Function($$MediaCollectionsTableAnnotationComposer a) f,
  ) {
    final $$MediaCollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaCollections,
      getReferencedColumn: (t) => t.coverMediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaCollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mediaCollectionItemsRefs<T extends Object>(
    Expression<T> Function($$MediaCollectionItemsTableAnnotationComposer a) f,
  ) {
    final $$MediaCollectionItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.mediaCollectionItems,
          getReferencedColumn: (t) => t.mediaId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MediaCollectionItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.mediaCollectionItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MediaItemsTableTableManager
    extends
        RootTableManager<
          _$MediaDatabase,
          $MediaItemsTable,
          MediaItem,
          $$MediaItemsTableFilterComposer,
          $$MediaItemsTableOrderingComposer,
          $$MediaItemsTableAnnotationComposer,
          $$MediaItemsTableCreateCompanionBuilder,
          $$MediaItemsTableUpdateCompanionBuilder,
          (MediaItem, $$MediaItemsTableReferences),
          MediaItem,
          PrefetchHooks Function({
            bool mediaMetadataRefs,
            bool personTagsRefs,
            bool faceEmbeddingsRefs,
            bool mediaCollectionsRefs,
            bool mediaCollectionItemsRefs,
          })
        > {
  $$MediaItemsTableTableManager(_$MediaDatabase db, $MediaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<DateTime> createdDate = const Value.absent(),
                Value<DateTime> modifiedDate = const Value.absent(),
                Value<DateTime> addedDate = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isProcessed = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsCompanion(
                id: id,
                filePath: filePath,
                fileName: fileName,
                mimeType: mimeType,
                fileSize: fileSize,
                fileHash: fileHash,
                createdDate: createdDate,
                modifiedDate: modifiedDate,
                addedDate: addedDate,
                isDeleted: isDeleted,
                isProcessed: isProcessed,
                width: width,
                height: height,
                duration: duration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> filePath = const Value.absent(),
                required String fileName,
                required String mimeType,
                required int fileSize,
                Value<String?> fileHash = const Value.absent(),
                required DateTime createdDate,
                required DateTime modifiedDate,
                Value<DateTime> addedDate = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isProcessed = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsCompanion.insert(
                id: id,
                filePath: filePath,
                fileName: fileName,
                mimeType: mimeType,
                fileSize: fileSize,
                fileHash: fileHash,
                createdDate: createdDate,
                modifiedDate: modifiedDate,
                addedDate: addedDate,
                isDeleted: isDeleted,
                isProcessed: isProcessed,
                width: width,
                height: height,
                duration: duration,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                mediaMetadataRefs = false,
                personTagsRefs = false,
                faceEmbeddingsRefs = false,
                mediaCollectionsRefs = false,
                mediaCollectionItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaMetadataRefs) db.mediaMetadata,
                    if (personTagsRefs) db.personTags,
                    if (faceEmbeddingsRefs) db.faceEmbeddings,
                    if (mediaCollectionsRefs) db.mediaCollections,
                    if (mediaCollectionItemsRefs) db.mediaCollectionItems,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaMetadataRefs)
                        await $_getPrefetchedData<
                          MediaItem,
                          $MediaItemsTable,
                          MediaMetadataData
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._mediaMetadataRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaMetadataRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (personTagsRefs)
                        await $_getPrefetchedData<
                          MediaItem,
                          $MediaItemsTable,
                          PersonTag
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._personTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).personTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (faceEmbeddingsRefs)
                        await $_getPrefetchedData<
                          MediaItem,
                          $MediaItemsTable,
                          FaceEmbedding
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._faceEmbeddingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).faceEmbeddingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (mediaCollectionsRefs)
                        await $_getPrefetchedData<
                          MediaItem,
                          $MediaItemsTable,
                          MediaCollection
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._mediaCollectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaCollectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.coverMediaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (mediaCollectionItemsRefs)
                        await $_getPrefetchedData<
                          MediaItem,
                          $MediaItemsTable,
                          MediaCollectionItem
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._mediaCollectionItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaCollectionItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaId == item.id,
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

typedef $$MediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$MediaDatabase,
      $MediaItemsTable,
      MediaItem,
      $$MediaItemsTableFilterComposer,
      $$MediaItemsTableOrderingComposer,
      $$MediaItemsTableAnnotationComposer,
      $$MediaItemsTableCreateCompanionBuilder,
      $$MediaItemsTableUpdateCompanionBuilder,
      (MediaItem, $$MediaItemsTableReferences),
      MediaItem,
      PrefetchHooks Function({
        bool mediaMetadataRefs,
        bool personTagsRefs,
        bool faceEmbeddingsRefs,
        bool mediaCollectionsRefs,
        bool mediaCollectionItemsRefs,
      })
    >;
typedef $$MediaMetadataTableCreateCompanionBuilder =
    MediaMetadataCompanion Function({
      Value<int> id,
      required String mediaId,
      required String metadataType,
      required String key,
      required String value,
      Value<double?> confidence,
      Value<DateTime> extractedAt,
    });
typedef $$MediaMetadataTableUpdateCompanionBuilder =
    MediaMetadataCompanion Function({
      Value<int> id,
      Value<String> mediaId,
      Value<String> metadataType,
      Value<String> key,
      Value<String> value,
      Value<double?> confidence,
      Value<DateTime> extractedAt,
    });

final class $$MediaMetadataTableReferences
    extends
        BaseReferences<
          _$MediaDatabase,
          $MediaMetadataTable,
          MediaMetadataData
        > {
  $$MediaMetadataTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MediaItemsTable _mediaIdTable(_$MediaDatabase db) =>
      db.mediaItems.createAlias(
        $_aliasNameGenerator(db.mediaMetadata.mediaId, db.mediaItems.id),
      );

  $$MediaItemsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MediaMetadataTableFilterComposer
    extends Composer<_$MediaDatabase, $MediaMetadataTable> {
  $$MediaMetadataTableFilterComposer({
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

  ColumnFilters<String> get metadataType => $composableBuilder(
    column: $table.metadataType,
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

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get extractedAt => $composableBuilder(
    column: $table.extractedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaItemsTableFilterComposer get mediaId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaMetadataTableOrderingComposer
    extends Composer<_$MediaDatabase, $MediaMetadataTable> {
  $$MediaMetadataTableOrderingComposer({
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

  ColumnOrderings<String> get metadataType => $composableBuilder(
    column: $table.metadataType,
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

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get extractedAt => $composableBuilder(
    column: $table.extractedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaItemsTableOrderingComposer get mediaId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaMetadataTableAnnotationComposer
    extends Composer<_$MediaDatabase, $MediaMetadataTable> {
  $$MediaMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metadataType => $composableBuilder(
    column: $table.metadataType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get extractedAt => $composableBuilder(
    column: $table.extractedAt,
    builder: (column) => column,
  );

  $$MediaItemsTableAnnotationComposer get mediaId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaMetadataTableTableManager
    extends
        RootTableManager<
          _$MediaDatabase,
          $MediaMetadataTable,
          MediaMetadataData,
          $$MediaMetadataTableFilterComposer,
          $$MediaMetadataTableOrderingComposer,
          $$MediaMetadataTableAnnotationComposer,
          $$MediaMetadataTableCreateCompanionBuilder,
          $$MediaMetadataTableUpdateCompanionBuilder,
          (MediaMetadataData, $$MediaMetadataTableReferences),
          MediaMetadataData,
          PrefetchHooks Function({bool mediaId})
        > {
  $$MediaMetadataTableTableManager(
    _$MediaDatabase db,
    $MediaMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<String> metadataType = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<DateTime> extractedAt = const Value.absent(),
              }) => MediaMetadataCompanion(
                id: id,
                mediaId: mediaId,
                metadataType: metadataType,
                key: key,
                value: value,
                confidence: confidence,
                extractedAt: extractedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String mediaId,
                required String metadataType,
                required String key,
                required String value,
                Value<double?> confidence = const Value.absent(),
                Value<DateTime> extractedAt = const Value.absent(),
              }) => MediaMetadataCompanion.insert(
                id: id,
                mediaId: mediaId,
                metadataType: metadataType,
                key: key,
                value: value,
                confidence: confidence,
                extractedAt: extractedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaMetadataTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
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
                    if (mediaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mediaId,
                                referencedTable: $$MediaMetadataTableReferences
                                    ._mediaIdTable(db),
                                referencedColumn: $$MediaMetadataTableReferences
                                    ._mediaIdTable(db)
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

typedef $$MediaMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$MediaDatabase,
      $MediaMetadataTable,
      MediaMetadataData,
      $$MediaMetadataTableFilterComposer,
      $$MediaMetadataTableOrderingComposer,
      $$MediaMetadataTableAnnotationComposer,
      $$MediaMetadataTableCreateCompanionBuilder,
      $$MediaMetadataTableUpdateCompanionBuilder,
      (MediaMetadataData, $$MediaMetadataTableReferences),
      MediaMetadataData,
      PrefetchHooks Function({bool mediaId})
    >;
typedef $$PersonTagsTableCreateCompanionBuilder =
    PersonTagsCompanion Function({
      Value<int> id,
      required String personId,
      Value<String?> personName,
      Value<String?> personNickname,
      required String mediaId,
      required double boundingBoxX,
      required double boundingBoxY,
      required double boundingBoxWidth,
      required double boundingBoxHeight,
      required double confidence,
      Value<double?> similarity,
      Value<bool> isConfirmed,
      Value<bool> isRejected,
      Value<DateTime> detectedAt,
      Value<DateTime?> confirmedAt,
    });
typedef $$PersonTagsTableUpdateCompanionBuilder =
    PersonTagsCompanion Function({
      Value<int> id,
      Value<String> personId,
      Value<String?> personName,
      Value<String?> personNickname,
      Value<String> mediaId,
      Value<double> boundingBoxX,
      Value<double> boundingBoxY,
      Value<double> boundingBoxWidth,
      Value<double> boundingBoxHeight,
      Value<double> confidence,
      Value<double?> similarity,
      Value<bool> isConfirmed,
      Value<bool> isRejected,
      Value<DateTime> detectedAt,
      Value<DateTime?> confirmedAt,
    });

final class $$PersonTagsTableReferences
    extends BaseReferences<_$MediaDatabase, $PersonTagsTable, PersonTag> {
  $$PersonTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediaItemsTable _mediaIdTable(_$MediaDatabase db) =>
      db.mediaItems.createAlias(
        $_aliasNameGenerator(db.personTags.mediaId, db.mediaItems.id),
      );

  $$MediaItemsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PersonTagsTableFilterComposer
    extends Composer<_$MediaDatabase, $PersonTagsTable> {
  $$PersonTagsTableFilterComposer({
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

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personNickname => $composableBuilder(
    column: $table.personNickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingBoxX => $composableBuilder(
    column: $table.boundingBoxX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingBoxY => $composableBuilder(
    column: $table.boundingBoxY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingBoxWidth => $composableBuilder(
    column: $table.boundingBoxWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingBoxHeight => $composableBuilder(
    column: $table.boundingBoxHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get similarity => $composableBuilder(
    column: $table.similarity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRejected => $composableBuilder(
    column: $table.isRejected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaItemsTableFilterComposer get mediaId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonTagsTableOrderingComposer
    extends Composer<_$MediaDatabase, $PersonTagsTable> {
  $$PersonTagsTableOrderingComposer({
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

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personNickname => $composableBuilder(
    column: $table.personNickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingBoxX => $composableBuilder(
    column: $table.boundingBoxX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingBoxY => $composableBuilder(
    column: $table.boundingBoxY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingBoxWidth => $composableBuilder(
    column: $table.boundingBoxWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingBoxHeight => $composableBuilder(
    column: $table.boundingBoxHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get similarity => $composableBuilder(
    column: $table.similarity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRejected => $composableBuilder(
    column: $table.isRejected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaItemsTableOrderingComposer get mediaId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonTagsTableAnnotationComposer
    extends Composer<_$MediaDatabase, $PersonTagsTable> {
  $$PersonTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get personNickname => $composableBuilder(
    column: $table.personNickname,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingBoxX => $composableBuilder(
    column: $table.boundingBoxX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingBoxY => $composableBuilder(
    column: $table.boundingBoxY,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingBoxWidth => $composableBuilder(
    column: $table.boundingBoxWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingBoxHeight => $composableBuilder(
    column: $table.boundingBoxHeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get similarity => $composableBuilder(
    column: $table.similarity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRejected => $composableBuilder(
    column: $table.isRejected,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  $$MediaItemsTableAnnotationComposer get mediaId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonTagsTableTableManager
    extends
        RootTableManager<
          _$MediaDatabase,
          $PersonTagsTable,
          PersonTag,
          $$PersonTagsTableFilterComposer,
          $$PersonTagsTableOrderingComposer,
          $$PersonTagsTableAnnotationComposer,
          $$PersonTagsTableCreateCompanionBuilder,
          $$PersonTagsTableUpdateCompanionBuilder,
          (PersonTag, $$PersonTagsTableReferences),
          PersonTag,
          PrefetchHooks Function({bool mediaId})
        > {
  $$PersonTagsTableTableManager(_$MediaDatabase db, $PersonTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<String?> personNickname = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<double> boundingBoxX = const Value.absent(),
                Value<double> boundingBoxY = const Value.absent(),
                Value<double> boundingBoxWidth = const Value.absent(),
                Value<double> boundingBoxHeight = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<double?> similarity = const Value.absent(),
                Value<bool> isConfirmed = const Value.absent(),
                Value<bool> isRejected = const Value.absent(),
                Value<DateTime> detectedAt = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
              }) => PersonTagsCompanion(
                id: id,
                personId: personId,
                personName: personName,
                personNickname: personNickname,
                mediaId: mediaId,
                boundingBoxX: boundingBoxX,
                boundingBoxY: boundingBoxY,
                boundingBoxWidth: boundingBoxWidth,
                boundingBoxHeight: boundingBoxHeight,
                confidence: confidence,
                similarity: similarity,
                isConfirmed: isConfirmed,
                isRejected: isRejected,
                detectedAt: detectedAt,
                confirmedAt: confirmedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String personId,
                Value<String?> personName = const Value.absent(),
                Value<String?> personNickname = const Value.absent(),
                required String mediaId,
                required double boundingBoxX,
                required double boundingBoxY,
                required double boundingBoxWidth,
                required double boundingBoxHeight,
                required double confidence,
                Value<double?> similarity = const Value.absent(),
                Value<bool> isConfirmed = const Value.absent(),
                Value<bool> isRejected = const Value.absent(),
                Value<DateTime> detectedAt = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
              }) => PersonTagsCompanion.insert(
                id: id,
                personId: personId,
                personName: personName,
                personNickname: personNickname,
                mediaId: mediaId,
                boundingBoxX: boundingBoxX,
                boundingBoxY: boundingBoxY,
                boundingBoxWidth: boundingBoxWidth,
                boundingBoxHeight: boundingBoxHeight,
                confidence: confidence,
                similarity: similarity,
                isConfirmed: isConfirmed,
                isRejected: isRejected,
                detectedAt: detectedAt,
                confirmedAt: confirmedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
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
                    if (mediaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mediaId,
                                referencedTable: $$PersonTagsTableReferences
                                    ._mediaIdTable(db),
                                referencedColumn: $$PersonTagsTableReferences
                                    ._mediaIdTable(db)
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

typedef $$PersonTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$MediaDatabase,
      $PersonTagsTable,
      PersonTag,
      $$PersonTagsTableFilterComposer,
      $$PersonTagsTableOrderingComposer,
      $$PersonTagsTableAnnotationComposer,
      $$PersonTagsTableCreateCompanionBuilder,
      $$PersonTagsTableUpdateCompanionBuilder,
      (PersonTag, $$PersonTagsTableReferences),
      PersonTag,
      PrefetchHooks Function({bool mediaId})
    >;
typedef $$FaceClustersTableCreateCompanionBuilder =
    FaceClustersCompanion Function({
      required String clusterId,
      Value<String?> personId,
      Value<String?> representativeFaceId,
      required int faceCount,
      required double averageConfidence,
      required double cohesion,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FaceClustersTableUpdateCompanionBuilder =
    FaceClustersCompanion Function({
      Value<String> clusterId,
      Value<String?> personId,
      Value<String?> representativeFaceId,
      Value<int> faceCount,
      Value<double> averageConfidence,
      Value<double> cohesion,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FaceClustersTableReferences
    extends BaseReferences<_$MediaDatabase, $FaceClustersTable, FaceCluster> {
  $$FaceClustersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FaceEmbeddingsTable, List<FaceEmbedding>>
  _faceEmbeddingsRefsTable(_$MediaDatabase db) => MultiTypedResultKey.fromTable(
    db.faceEmbeddings,
    aliasName: $_aliasNameGenerator(
      db.faceClusters.clusterId,
      db.faceEmbeddings.clusterId,
    ),
  );

  $$FaceEmbeddingsTableProcessedTableManager get faceEmbeddingsRefs {
    final manager = $$FaceEmbeddingsTableTableManager($_db, $_db.faceEmbeddings)
        .filter(
          (f) => f.clusterId.clusterId.sqlEquals(
            $_itemColumn<String>('cluster_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_faceEmbeddingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FaceClustersTableFilterComposer
    extends Composer<_$MediaDatabase, $FaceClustersTable> {
  $$FaceClustersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get representativeFaceId => $composableBuilder(
    column: $table.representativeFaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get faceCount => $composableBuilder(
    column: $table.faceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageConfidence => $composableBuilder(
    column: $table.averageConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cohesion => $composableBuilder(
    column: $table.cohesion,
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

  Expression<bool> faceEmbeddingsRefs(
    Expression<bool> Function($$FaceEmbeddingsTableFilterComposer f) f,
  ) {
    final $$FaceEmbeddingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clusterId,
      referencedTable: $db.faceEmbeddings,
      getReferencedColumn: (t) => t.clusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceEmbeddingsTableFilterComposer(
            $db: $db,
            $table: $db.faceEmbeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FaceClustersTableOrderingComposer
    extends Composer<_$MediaDatabase, $FaceClustersTable> {
  $$FaceClustersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get representativeFaceId => $composableBuilder(
    column: $table.representativeFaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get faceCount => $composableBuilder(
    column: $table.faceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageConfidence => $composableBuilder(
    column: $table.averageConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cohesion => $composableBuilder(
    column: $table.cohesion,
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

class $$FaceClustersTableAnnotationComposer
    extends Composer<_$MediaDatabase, $FaceClustersTable> {
  $$FaceClustersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clusterId =>
      $composableBuilder(column: $table.clusterId, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get representativeFaceId => $composableBuilder(
    column: $table.representativeFaceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get faceCount =>
      $composableBuilder(column: $table.faceCount, builder: (column) => column);

  GeneratedColumn<double> get averageConfidence => $composableBuilder(
    column: $table.averageConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cohesion =>
      $composableBuilder(column: $table.cohesion, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> faceEmbeddingsRefs<T extends Object>(
    Expression<T> Function($$FaceEmbeddingsTableAnnotationComposer a) f,
  ) {
    final $$FaceEmbeddingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clusterId,
      referencedTable: $db.faceEmbeddings,
      getReferencedColumn: (t) => t.clusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceEmbeddingsTableAnnotationComposer(
            $db: $db,
            $table: $db.faceEmbeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FaceClustersTableTableManager
    extends
        RootTableManager<
          _$MediaDatabase,
          $FaceClustersTable,
          FaceCluster,
          $$FaceClustersTableFilterComposer,
          $$FaceClustersTableOrderingComposer,
          $$FaceClustersTableAnnotationComposer,
          $$FaceClustersTableCreateCompanionBuilder,
          $$FaceClustersTableUpdateCompanionBuilder,
          (FaceCluster, $$FaceClustersTableReferences),
          FaceCluster,
          PrefetchHooks Function({bool faceEmbeddingsRefs})
        > {
  $$FaceClustersTableTableManager(_$MediaDatabase db, $FaceClustersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FaceClustersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FaceClustersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FaceClustersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clusterId = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                Value<String?> representativeFaceId = const Value.absent(),
                Value<int> faceCount = const Value.absent(),
                Value<double> averageConfidence = const Value.absent(),
                Value<double> cohesion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FaceClustersCompanion(
                clusterId: clusterId,
                personId: personId,
                representativeFaceId: representativeFaceId,
                faceCount: faceCount,
                averageConfidence: averageConfidence,
                cohesion: cohesion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clusterId,
                Value<String?> personId = const Value.absent(),
                Value<String?> representativeFaceId = const Value.absent(),
                required int faceCount,
                required double averageConfidence,
                required double cohesion,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FaceClustersCompanion.insert(
                clusterId: clusterId,
                personId: personId,
                representativeFaceId: representativeFaceId,
                faceCount: faceCount,
                averageConfidence: averageConfidence,
                cohesion: cohesion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FaceClustersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({faceEmbeddingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (faceEmbeddingsRefs) db.faceEmbeddings,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (faceEmbeddingsRefs)
                    await $_getPrefetchedData<
                      FaceCluster,
                      $FaceClustersTable,
                      FaceEmbedding
                    >(
                      currentTable: table,
                      referencedTable: $$FaceClustersTableReferences
                          ._faceEmbeddingsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FaceClustersTableReferences(
                            db,
                            table,
                            p0,
                          ).faceEmbeddingsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.clusterId == item.clusterId,
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

typedef $$FaceClustersTableProcessedTableManager =
    ProcessedTableManager<
      _$MediaDatabase,
      $FaceClustersTable,
      FaceCluster,
      $$FaceClustersTableFilterComposer,
      $$FaceClustersTableOrderingComposer,
      $$FaceClustersTableAnnotationComposer,
      $$FaceClustersTableCreateCompanionBuilder,
      $$FaceClustersTableUpdateCompanionBuilder,
      (FaceCluster, $$FaceClustersTableReferences),
      FaceCluster,
      PrefetchHooks Function({bool faceEmbeddingsRefs})
    >;
typedef $$FaceEmbeddingsTableCreateCompanionBuilder =
    FaceEmbeddingsCompanion Function({
      Value<int> id,
      required String faceId,
      required String mediaId,
      Value<String?> clusterId,
      required String embedding,
      required double qualityScore,
      required double boundingBoxX,
      required double boundingBoxY,
      required double boundingBoxWidth,
      required double boundingBoxHeight,
      Value<DateTime> extractedAt,
    });
typedef $$FaceEmbeddingsTableUpdateCompanionBuilder =
    FaceEmbeddingsCompanion Function({
      Value<int> id,
      Value<String> faceId,
      Value<String> mediaId,
      Value<String?> clusterId,
      Value<String> embedding,
      Value<double> qualityScore,
      Value<double> boundingBoxX,
      Value<double> boundingBoxY,
      Value<double> boundingBoxWidth,
      Value<double> boundingBoxHeight,
      Value<DateTime> extractedAt,
    });

final class $$FaceEmbeddingsTableReferences
    extends
        BaseReferences<_$MediaDatabase, $FaceEmbeddingsTable, FaceEmbedding> {
  $$FaceEmbeddingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MediaItemsTable _mediaIdTable(_$MediaDatabase db) =>
      db.mediaItems.createAlias(
        $_aliasNameGenerator(db.faceEmbeddings.mediaId, db.mediaItems.id),
      );

  $$MediaItemsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FaceClustersTable _clusterIdTable(_$MediaDatabase db) =>
      db.faceClusters.createAlias(
        $_aliasNameGenerator(
          db.faceEmbeddings.clusterId,
          db.faceClusters.clusterId,
        ),
      );

  $$FaceClustersTableProcessedTableManager? get clusterId {
    final $_column = $_itemColumn<String>('cluster_id');
    if ($_column == null) return null;
    final manager = $$FaceClustersTableTableManager(
      $_db,
      $_db.faceClusters,
    ).filter((f) => f.clusterId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clusterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FaceEmbeddingsTableFilterComposer
    extends Composer<_$MediaDatabase, $FaceEmbeddingsTable> {
  $$FaceEmbeddingsTableFilterComposer({
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

  ColumnFilters<String> get faceId => $composableBuilder(
    column: $table.faceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingBoxX => $composableBuilder(
    column: $table.boundingBoxX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingBoxY => $composableBuilder(
    column: $table.boundingBoxY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingBoxWidth => $composableBuilder(
    column: $table.boundingBoxWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingBoxHeight => $composableBuilder(
    column: $table.boundingBoxHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get extractedAt => $composableBuilder(
    column: $table.extractedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaItemsTableFilterComposer get mediaId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FaceClustersTableFilterComposer get clusterId {
    final $$FaceClustersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clusterId,
      referencedTable: $db.faceClusters,
      getReferencedColumn: (t) => t.clusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceClustersTableFilterComposer(
            $db: $db,
            $table: $db.faceClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FaceEmbeddingsTableOrderingComposer
    extends Composer<_$MediaDatabase, $FaceEmbeddingsTable> {
  $$FaceEmbeddingsTableOrderingComposer({
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

  ColumnOrderings<String> get faceId => $composableBuilder(
    column: $table.faceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingBoxX => $composableBuilder(
    column: $table.boundingBoxX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingBoxY => $composableBuilder(
    column: $table.boundingBoxY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingBoxWidth => $composableBuilder(
    column: $table.boundingBoxWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingBoxHeight => $composableBuilder(
    column: $table.boundingBoxHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get extractedAt => $composableBuilder(
    column: $table.extractedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaItemsTableOrderingComposer get mediaId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FaceClustersTableOrderingComposer get clusterId {
    final $$FaceClustersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clusterId,
      referencedTable: $db.faceClusters,
      getReferencedColumn: (t) => t.clusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceClustersTableOrderingComposer(
            $db: $db,
            $table: $db.faceClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FaceEmbeddingsTableAnnotationComposer
    extends Composer<_$MediaDatabase, $FaceEmbeddingsTable> {
  $$FaceEmbeddingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get faceId =>
      $composableBuilder(column: $table.faceId, builder: (column) => column);

  GeneratedColumn<String> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<double> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingBoxX => $composableBuilder(
    column: $table.boundingBoxX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingBoxY => $composableBuilder(
    column: $table.boundingBoxY,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingBoxWidth => $composableBuilder(
    column: $table.boundingBoxWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingBoxHeight => $composableBuilder(
    column: $table.boundingBoxHeight,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get extractedAt => $composableBuilder(
    column: $table.extractedAt,
    builder: (column) => column,
  );

  $$MediaItemsTableAnnotationComposer get mediaId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FaceClustersTableAnnotationComposer get clusterId {
    final $$FaceClustersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clusterId,
      referencedTable: $db.faceClusters,
      getReferencedColumn: (t) => t.clusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceClustersTableAnnotationComposer(
            $db: $db,
            $table: $db.faceClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FaceEmbeddingsTableTableManager
    extends
        RootTableManager<
          _$MediaDatabase,
          $FaceEmbeddingsTable,
          FaceEmbedding,
          $$FaceEmbeddingsTableFilterComposer,
          $$FaceEmbeddingsTableOrderingComposer,
          $$FaceEmbeddingsTableAnnotationComposer,
          $$FaceEmbeddingsTableCreateCompanionBuilder,
          $$FaceEmbeddingsTableUpdateCompanionBuilder,
          (FaceEmbedding, $$FaceEmbeddingsTableReferences),
          FaceEmbedding,
          PrefetchHooks Function({bool mediaId, bool clusterId})
        > {
  $$FaceEmbeddingsTableTableManager(
    _$MediaDatabase db,
    $FaceEmbeddingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FaceEmbeddingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FaceEmbeddingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FaceEmbeddingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> faceId = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<String?> clusterId = const Value.absent(),
                Value<String> embedding = const Value.absent(),
                Value<double> qualityScore = const Value.absent(),
                Value<double> boundingBoxX = const Value.absent(),
                Value<double> boundingBoxY = const Value.absent(),
                Value<double> boundingBoxWidth = const Value.absent(),
                Value<double> boundingBoxHeight = const Value.absent(),
                Value<DateTime> extractedAt = const Value.absent(),
              }) => FaceEmbeddingsCompanion(
                id: id,
                faceId: faceId,
                mediaId: mediaId,
                clusterId: clusterId,
                embedding: embedding,
                qualityScore: qualityScore,
                boundingBoxX: boundingBoxX,
                boundingBoxY: boundingBoxY,
                boundingBoxWidth: boundingBoxWidth,
                boundingBoxHeight: boundingBoxHeight,
                extractedAt: extractedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String faceId,
                required String mediaId,
                Value<String?> clusterId = const Value.absent(),
                required String embedding,
                required double qualityScore,
                required double boundingBoxX,
                required double boundingBoxY,
                required double boundingBoxWidth,
                required double boundingBoxHeight,
                Value<DateTime> extractedAt = const Value.absent(),
              }) => FaceEmbeddingsCompanion.insert(
                id: id,
                faceId: faceId,
                mediaId: mediaId,
                clusterId: clusterId,
                embedding: embedding,
                qualityScore: qualityScore,
                boundingBoxX: boundingBoxX,
                boundingBoxY: boundingBoxY,
                boundingBoxWidth: boundingBoxWidth,
                boundingBoxHeight: boundingBoxHeight,
                extractedAt: extractedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FaceEmbeddingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false, clusterId = false}) {
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
                    if (mediaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mediaId,
                                referencedTable: $$FaceEmbeddingsTableReferences
                                    ._mediaIdTable(db),
                                referencedColumn:
                                    $$FaceEmbeddingsTableReferences
                                        ._mediaIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (clusterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.clusterId,
                                referencedTable: $$FaceEmbeddingsTableReferences
                                    ._clusterIdTable(db),
                                referencedColumn:
                                    $$FaceEmbeddingsTableReferences
                                        ._clusterIdTable(db)
                                        .clusterId,
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

typedef $$FaceEmbeddingsTableProcessedTableManager =
    ProcessedTableManager<
      _$MediaDatabase,
      $FaceEmbeddingsTable,
      FaceEmbedding,
      $$FaceEmbeddingsTableFilterComposer,
      $$FaceEmbeddingsTableOrderingComposer,
      $$FaceEmbeddingsTableAnnotationComposer,
      $$FaceEmbeddingsTableCreateCompanionBuilder,
      $$FaceEmbeddingsTableUpdateCompanionBuilder,
      (FaceEmbedding, $$FaceEmbeddingsTableReferences),
      FaceEmbedding,
      PrefetchHooks Function({bool mediaId, bool clusterId})
    >;
typedef $$MediaCollectionsTableCreateCompanionBuilder =
    MediaCollectionsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<String?> coverMediaId,
      Value<int> mediaCount,
      Value<bool> isSystemCollection,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MediaCollectionsTableUpdateCompanionBuilder =
    MediaCollectionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> coverMediaId,
      Value<int> mediaCount,
      Value<bool> isSystemCollection,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MediaCollectionsTableReferences
    extends
        BaseReferences<
          _$MediaDatabase,
          $MediaCollectionsTable,
          MediaCollection
        > {
  $$MediaCollectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MediaItemsTable _coverMediaIdTable(_$MediaDatabase db) =>
      db.mediaItems.createAlias(
        $_aliasNameGenerator(
          db.mediaCollections.coverMediaId,
          db.mediaItems.id,
        ),
      );

  $$MediaItemsTableProcessedTableManager? get coverMediaId {
    final $_column = $_itemColumn<String>('cover_media_id');
    if ($_column == null) return null;
    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coverMediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $MediaCollectionItemsTable,
    List<MediaCollectionItem>
  >
  _mediaCollectionItemsRefsTable(_$MediaDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.mediaCollectionItems,
        aliasName: $_aliasNameGenerator(
          db.mediaCollections.id,
          db.mediaCollectionItems.collectionId,
        ),
      );

  $$MediaCollectionItemsTableProcessedTableManager
  get mediaCollectionItemsRefs {
    final manager = $$MediaCollectionItemsTableTableManager(
      $_db,
      $_db.mediaCollectionItems,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _mediaCollectionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MediaCollectionsTableFilterComposer
    extends Composer<_$MediaDatabase, $MediaCollectionsTable> {
  $$MediaCollectionsTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaCount => $composableBuilder(
    column: $table.mediaCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystemCollection => $composableBuilder(
    column: $table.isSystemCollection,
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

  $$MediaItemsTableFilterComposer get coverMediaId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverMediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> mediaCollectionItemsRefs(
    Expression<bool> Function($$MediaCollectionItemsTableFilterComposer f) f,
  ) {
    final $$MediaCollectionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaCollectionItems,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaCollectionItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaCollectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaCollectionsTableOrderingComposer
    extends Composer<_$MediaDatabase, $MediaCollectionsTable> {
  $$MediaCollectionsTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaCount => $composableBuilder(
    column: $table.mediaCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystemCollection => $composableBuilder(
    column: $table.isSystemCollection,
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

  $$MediaItemsTableOrderingComposer get coverMediaId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverMediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaCollectionsTableAnnotationComposer
    extends Composer<_$MediaDatabase, $MediaCollectionsTable> {
  $$MediaCollectionsTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaCount => $composableBuilder(
    column: $table.mediaCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSystemCollection => $composableBuilder(
    column: $table.isSystemCollection,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MediaItemsTableAnnotationComposer get coverMediaId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverMediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> mediaCollectionItemsRefs<T extends Object>(
    Expression<T> Function($$MediaCollectionItemsTableAnnotationComposer a) f,
  ) {
    final $$MediaCollectionItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.mediaCollectionItems,
          getReferencedColumn: (t) => t.collectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MediaCollectionItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.mediaCollectionItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MediaCollectionsTableTableManager
    extends
        RootTableManager<
          _$MediaDatabase,
          $MediaCollectionsTable,
          MediaCollection,
          $$MediaCollectionsTableFilterComposer,
          $$MediaCollectionsTableOrderingComposer,
          $$MediaCollectionsTableAnnotationComposer,
          $$MediaCollectionsTableCreateCompanionBuilder,
          $$MediaCollectionsTableUpdateCompanionBuilder,
          (MediaCollection, $$MediaCollectionsTableReferences),
          MediaCollection,
          PrefetchHooks Function({
            bool coverMediaId,
            bool mediaCollectionItemsRefs,
          })
        > {
  $$MediaCollectionsTableTableManager(
    _$MediaDatabase db,
    $MediaCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaCollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> coverMediaId = const Value.absent(),
                Value<int> mediaCount = const Value.absent(),
                Value<bool> isSystemCollection = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaCollectionsCompanion(
                id: id,
                name: name,
                description: description,
                coverMediaId: coverMediaId,
                mediaCount: mediaCount,
                isSystemCollection: isSystemCollection,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> coverMediaId = const Value.absent(),
                Value<int> mediaCount = const Value.absent(),
                Value<bool> isSystemCollection = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaCollectionsCompanion.insert(
                id: id,
                name: name,
                description: description,
                coverMediaId: coverMediaId,
                mediaCount: mediaCount,
                isSystemCollection: isSystemCollection,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaCollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({coverMediaId = false, mediaCollectionItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaCollectionItemsRefs) db.mediaCollectionItems,
                  ],
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
                        if (coverMediaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.coverMediaId,
                                    referencedTable:
                                        $$MediaCollectionsTableReferences
                                            ._coverMediaIdTable(db),
                                    referencedColumn:
                                        $$MediaCollectionsTableReferences
                                            ._coverMediaIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaCollectionItemsRefs)
                        await $_getPrefetchedData<
                          MediaCollection,
                          $MediaCollectionsTable,
                          MediaCollectionItem
                        >(
                          currentTable: table,
                          referencedTable: $$MediaCollectionsTableReferences
                              ._mediaCollectionItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaCollectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaCollectionItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.collectionId == item.id,
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

typedef $$MediaCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$MediaDatabase,
      $MediaCollectionsTable,
      MediaCollection,
      $$MediaCollectionsTableFilterComposer,
      $$MediaCollectionsTableOrderingComposer,
      $$MediaCollectionsTableAnnotationComposer,
      $$MediaCollectionsTableCreateCompanionBuilder,
      $$MediaCollectionsTableUpdateCompanionBuilder,
      (MediaCollection, $$MediaCollectionsTableReferences),
      MediaCollection,
      PrefetchHooks Function({bool coverMediaId, bool mediaCollectionItemsRefs})
    >;
typedef $$MediaCollectionItemsTableCreateCompanionBuilder =
    MediaCollectionItemsCompanion Function({
      Value<int> id,
      required String collectionId,
      required String mediaId,
      Value<int?> sortOrder,
      Value<DateTime> addedAt,
    });
typedef $$MediaCollectionItemsTableUpdateCompanionBuilder =
    MediaCollectionItemsCompanion Function({
      Value<int> id,
      Value<String> collectionId,
      Value<String> mediaId,
      Value<int?> sortOrder,
      Value<DateTime> addedAt,
    });

final class $$MediaCollectionItemsTableReferences
    extends
        BaseReferences<
          _$MediaDatabase,
          $MediaCollectionItemsTable,
          MediaCollectionItem
        > {
  $$MediaCollectionItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MediaCollectionsTable _collectionIdTable(_$MediaDatabase db) =>
      db.mediaCollections.createAlias(
        $_aliasNameGenerator(
          db.mediaCollectionItems.collectionId,
          db.mediaCollections.id,
        ),
      );

  $$MediaCollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<String>('collection_id')!;

    final manager = $$MediaCollectionsTableTableManager(
      $_db,
      $_db.mediaCollections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MediaItemsTable _mediaIdTable(_$MediaDatabase db) =>
      db.mediaItems.createAlias(
        $_aliasNameGenerator(db.mediaCollectionItems.mediaId, db.mediaItems.id),
      );

  $$MediaItemsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MediaCollectionItemsTableFilterComposer
    extends Composer<_$MediaDatabase, $MediaCollectionItemsTable> {
  $$MediaCollectionItemsTableFilterComposer({
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

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaCollectionsTableFilterComposer get collectionId {
    final $$MediaCollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.mediaCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaCollectionsTableFilterComposer(
            $db: $db,
            $table: $db.mediaCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaItemsTableFilterComposer get mediaId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaCollectionItemsTableOrderingComposer
    extends Composer<_$MediaDatabase, $MediaCollectionItemsTable> {
  $$MediaCollectionItemsTableOrderingComposer({
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

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaCollectionsTableOrderingComposer get collectionId {
    final $$MediaCollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.mediaCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaCollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaItemsTableOrderingComposer get mediaId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaCollectionItemsTableAnnotationComposer
    extends Composer<_$MediaDatabase, $MediaCollectionItemsTable> {
  $$MediaCollectionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$MediaCollectionsTableAnnotationComposer get collectionId {
    final $$MediaCollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.mediaCollections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaCollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaItemsTableAnnotationComposer get mediaId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaCollectionItemsTableTableManager
    extends
        RootTableManager<
          _$MediaDatabase,
          $MediaCollectionItemsTable,
          MediaCollectionItem,
          $$MediaCollectionItemsTableFilterComposer,
          $$MediaCollectionItemsTableOrderingComposer,
          $$MediaCollectionItemsTableAnnotationComposer,
          $$MediaCollectionItemsTableCreateCompanionBuilder,
          $$MediaCollectionItemsTableUpdateCompanionBuilder,
          (MediaCollectionItem, $$MediaCollectionItemsTableReferences),
          MediaCollectionItem,
          PrefetchHooks Function({bool collectionId, bool mediaId})
        > {
  $$MediaCollectionItemsTableTableManager(
    _$MediaDatabase db,
    $MediaCollectionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaCollectionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaCollectionItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MediaCollectionItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> collectionId = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<int?> sortOrder = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => MediaCollectionItemsCompanion(
                id: id,
                collectionId: collectionId,
                mediaId: mediaId,
                sortOrder: sortOrder,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String collectionId,
                required String mediaId,
                Value<int?> sortOrder = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => MediaCollectionItemsCompanion.insert(
                id: id,
                collectionId: collectionId,
                mediaId: mediaId,
                sortOrder: sortOrder,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaCollectionItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionId = false, mediaId = false}) {
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
                    if (collectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.collectionId,
                                referencedTable:
                                    $$MediaCollectionItemsTableReferences
                                        ._collectionIdTable(db),
                                referencedColumn:
                                    $$MediaCollectionItemsTableReferences
                                        ._collectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (mediaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mediaId,
                                referencedTable:
                                    $$MediaCollectionItemsTableReferences
                                        ._mediaIdTable(db),
                                referencedColumn:
                                    $$MediaCollectionItemsTableReferences
                                        ._mediaIdTable(db)
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

typedef $$MediaCollectionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$MediaDatabase,
      $MediaCollectionItemsTable,
      MediaCollectionItem,
      $$MediaCollectionItemsTableFilterComposer,
      $$MediaCollectionItemsTableOrderingComposer,
      $$MediaCollectionItemsTableAnnotationComposer,
      $$MediaCollectionItemsTableCreateCompanionBuilder,
      $$MediaCollectionItemsTableUpdateCompanionBuilder,
      (MediaCollectionItem, $$MediaCollectionItemsTableReferences),
      MediaCollectionItem,
      PrefetchHooks Function({bool collectionId, bool mediaId})
    >;

class $MediaDatabaseManager {
  final _$MediaDatabase _db;
  $MediaDatabaseManager(this._db);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$MediaMetadataTableTableManager get mediaMetadata =>
      $$MediaMetadataTableTableManager(_db, _db.mediaMetadata);
  $$PersonTagsTableTableManager get personTags =>
      $$PersonTagsTableTableManager(_db, _db.personTags);
  $$FaceClustersTableTableManager get faceClusters =>
      $$FaceClustersTableTableManager(_db, _db.faceClusters);
  $$FaceEmbeddingsTableTableManager get faceEmbeddings =>
      $$FaceEmbeddingsTableTableManager(_db, _db.faceEmbeddings);
  $$MediaCollectionsTableTableManager get mediaCollections =>
      $$MediaCollectionsTableTableManager(_db, _db.mediaCollections);
  $$MediaCollectionItemsTableTableManager get mediaCollectionItems =>
      $$MediaCollectionItemsTableTableManager(_db, _db.mediaCollectionItems);
}
