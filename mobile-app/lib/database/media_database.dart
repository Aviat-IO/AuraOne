import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'media_database.g.dart';

// Table for storing media item references
class MediaItems extends Table {
  TextColumn get id => text()(); // Asset ID from photo_manager
  TextColumn get filePath => text().nullable()(); // Local file path (can be null if file moved)
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSize => integer()(); // in bytes
  TextColumn get fileHash => text().nullable()(); // SHA256 hash for deduplication
  DateTimeColumn get createdDate => dateTime()(); // When photo was taken
  DateTimeColumn get modifiedDate => dateTime()(); // When file was last modified
  DateTimeColumn get addedDate => dateTime().withDefault(currentDateAndTime)(); // When added to database
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))(); // Soft delete flag
  BoolColumn get isProcessed => boolean().withDefault(const Constant(false))(); // Whether metadata extraction is complete
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get duration => integer().nullable()(); // For videos, in seconds

  @override
  Set<Column> get primaryKey => {id};
}

// Table for storing extracted metadata
class MediaMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mediaId => text().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get metadataType => text()(); // 'exif', 'face', 'object', 'text', 'location'
  TextColumn get key => text()(); // Metadata key (e.g., 'camera_model', 'face_count', 'gps_latitude')
  TextColumn get value => text()(); // Metadata value (JSON string for complex data)
  RealColumn get confidence => real().nullable()(); // Confidence score for ML-detected metadata
  DateTimeColumn get extractedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {mediaId, metadataType, key}, // Prevent duplicate metadata entries
  ];
}

// Table for person tags and identification
class PersonTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get personId => text()(); // Unique identifier for the person
  TextColumn get personName => text().nullable()(); // Human-readable name
  TextColumn get personNickname => text().nullable()(); // Nickname or alternate name
  TextColumn get mediaId => text().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  RealColumn get boundingBoxX => real()(); // Face bounding box coordinates (normalized 0-1)
  RealColumn get boundingBoxY => real()();
  RealColumn get boundingBoxWidth => real()();
  RealColumn get boundingBoxHeight => real()();
  RealColumn get confidence => real()(); // Face detection confidence
  RealColumn get similarity => real().nullable()(); // Similarity to other faces of same person
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(false))(); // User confirmed identity
  BoolColumn get isRejected => boolean().withDefault(const Constant(false))(); // User rejected identity
  DateTimeColumn get detectedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get confirmedAt => dateTime().nullable()(); // When user confirmed/rejected

  @override
  List<Set<Column>> get uniqueKeys => [
    {mediaId, boundingBoxX, boundingBoxY, boundingBoxWidth, boundingBoxHeight}, // Prevent duplicate face regions
  ];
}

// Table for face clustering information
class FaceClusters extends Table {
  TextColumn get clusterId => text()();
  TextColumn get personId => text().nullable()(); // Link to identified person
  TextColumn get representativeFaceId => text().nullable()(); // ID of the best representative face
  IntColumn get faceCount => integer()(); // Number of faces in this cluster
  RealColumn get averageConfidence => real()(); // Average detection confidence
  RealColumn get cohesion => real()(); // Cluster cohesion score (how similar faces are)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {clusterId};
}

// Table for face embeddings (for clustering)
class FaceEmbeddings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get faceId => text()(); // Unique identifier for this face
  TextColumn get mediaId => text().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get clusterId => text().nullable().references(FaceClusters, #clusterId, onDelete: KeyAction.setNull)();
  TextColumn get embedding => text()(); // Serialized face embedding vector
  RealColumn get qualityScore => real()(); // Face quality score
  RealColumn get boundingBoxX => real()(); // Face bounding box
  RealColumn get boundingBoxY => real()();
  RealColumn get boundingBoxWidth => real()();
  RealColumn get boundingBoxHeight => real()();
  DateTimeColumn get extractedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {faceId}, // Each face should be unique
    {mediaId, boundingBoxX, boundingBoxY, boundingBoxWidth, boundingBoxHeight}, // Prevent duplicate faces in same location
  ];
}

// Table for media collections/albums
class MediaCollections extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get coverMediaId => text().nullable().references(MediaItems, #id, onDelete: KeyAction.setNull)();
  IntColumn get mediaCount => integer().withDefault(const Constant(0))();
  BoolColumn get isSystemCollection => boolean().withDefault(const Constant(false))(); // e.g., "Favorites", "Recently Added"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// Table for media-to-collection relationships
class MediaCollectionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collectionId => text().references(MediaCollections, #id, onDelete: KeyAction.cascade)();
  TextColumn get mediaId => text().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer().nullable()(); // Order within collection
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {collectionId, mediaId}, // Media can only be in collection once
  ];
}

@DriftDatabase(tables: [
  MediaItems,
  MediaMetadata,
  PersonTags,
  FaceClusters,
  FaceEmbeddings,
  MediaCollections,
  MediaCollectionItems,
])
class MediaDatabase extends _$MediaDatabase {
  MediaDatabase() : super(_openConnection());

  MediaDatabase.withPath(String path) : super(_openConnectionWithPath(path));

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'media_database');
  }

  static QueryExecutor _openConnectionWithPath(String path) {
    return driftDatabase(name: path);
  }

  // Media Items Methods
  Future<int> insertMediaItem(MediaItemsCompanion item) {
    return into(mediaItems).insert(item);
  }

  Future<bool> updateMediaItem(MediaItemsCompanion item) {
    return update(mediaItems).replace(item);
  }

  Future<MediaItem?> getMediaItem(String id) async {
    return await (select(mediaItems)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Stream<List<MediaItem>> watchMediaItems({
    bool includeDeleted = false,
    bool processedOnly = false,
  }) {
    return (select(mediaItems)
          ..where((tbl) {
            Expression<bool> filter = const Constant(true);
            if (!includeDeleted) {
              filter = filter & tbl.isDeleted.equals(false);
            }
            if (processedOnly) {
              filter = filter & tbl.isProcessed.equals(true);
            }
            return filter;
          })
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdDate)]))
        .watch();
  }

  Future<List<MediaItem>> getRecentMedia({
    Duration duration = const Duration(days: 7),
    int limit = 50,
    bool includeDeleted = false,
  }) {
    final cutoff = DateTime.now().subtract(duration);
    return (select(mediaItems)
          ..where((tbl) {
            Expression<bool> filter = tbl.createdDate.isBiggerOrEqualValue(cutoff);
            if (!includeDeleted) {
              filter = filter & tbl.isDeleted.equals(false);
            }
            return filter;
          })
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdDate)])
          ..limit(limit))
        .get();
  }

  Future<List<MediaItem>> getMediaByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    bool includeDeleted = false,
    bool processedOnly = true,
  }) {
    return (select(mediaItems)
          ..where((tbl) {
            Expression<bool> filter = tbl.createdDate.isBiggerOrEqualValue(startDate) &
                                     tbl.createdDate.isSmallerOrEqualValue(endDate);

            if (!includeDeleted) {
              filter = filter & tbl.isDeleted.equals(false);
            }

            if (processedOnly) {
              filter = filter & tbl.isProcessed.equals(true);
            }

            return filter;
          })
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdDate)]))
        .get();
  }

  Future<List<MediaItem>> getUnprocessedMedia({int? limit}) {
    final query = select(mediaItems)
      ..where((tbl) =>
          tbl.isProcessed.equals(false) &
          tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdDate)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  Future<int> softDeleteMediaItem(String id) {
    return (update(mediaItems)..where((tbl) => tbl.id.equals(id)))
        .write(const MediaItemsCompanion(isDeleted: Value(true)));
  }

  // Metadata Methods
  Future<int> insertMetadata(MediaMetadataCompanion metadata) {
    return into(mediaMetadata).insert(metadata, mode: InsertMode.insertOrReplace);
  }

  Future<List<MediaMetadataData>> getMetadataForMedia(String mediaId, [String? metadataType]) {
    return (select(mediaMetadata)
          ..where((tbl) {
            Expression<bool> filter = tbl.mediaId.equals(mediaId);
            if (metadataType != null) {
              filter = filter & tbl.metadataType.equals(metadataType);
            }
            return filter;
          }))
        .get();
  }

  Future<Map<String, dynamic>> getMetadataMap(String mediaId, String metadataType) async {
    final metadata = await (select(mediaMetadata)
          ..where((tbl) =>
              tbl.mediaId.equals(mediaId) &
              tbl.metadataType.equals(metadataType)))
        .get();

    final Map<String, dynamic> result = {};
    for (final item in metadata) {
      try {
        result[item.key] = json.decode(item.value);
      } catch (_) {
        result[item.key] = item.value; // Store as string if not JSON
      }
    }
    return result;
  }

  // Person Tags Methods
  Future<int> insertPersonTag(PersonTagsCompanion tag) {
    return into(personTags).insert(tag);
  }

  Future<List<PersonTag>> getPersonTagsForMedia(String mediaId) {
    return (select(personTags)
          ..where((tbl) => tbl.mediaId.equals(mediaId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.confidence)]))
        .get();
  }

  Stream<List<PersonTag>> watchPersonTags({
    String? personId,
    bool confirmedOnly = false,
  }) {
    return (select(personTags)
          ..where((tbl) {
            Expression<bool> filter = const Constant(true);
            if (personId != null) {
              filter = filter & tbl.personId.equals(personId);
            }
            if (confirmedOnly) {
              filter = filter & tbl.isConfirmed.equals(true);
            }
            return filter;
          })
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.detectedAt)]))
        .watch();
  }

  Future<void> confirmPersonTag(int tagId, bool isConfirmed) async {
    await (update(personTags)..where((tbl) => tbl.id.equals(tagId)))
        .write(PersonTagsCompanion(
          isConfirmed: Value(isConfirmed),
          isRejected: Value(!isConfirmed),
          confirmedAt: Value(DateTime.now()),
        ));
  }

  // Face Clustering Methods
  Future<int> insertFaceCluster(FaceClustersCompanion cluster) {
    return into(faceClusters).insert(cluster, mode: InsertMode.insertOrReplace);
  }

  Future<int> insertFaceEmbedding(FaceEmbeddingsCompanion embedding) {
    return into(faceEmbeddings).insert(embedding);
  }

  Future<List<FaceEmbedding>> getFaceEmbeddings({String? clusterId}) {
    return (select(faceEmbeddings)
          ..where((tbl) {
            if (clusterId != null) {
              return tbl.clusterId.equals(clusterId);
            }
            return const Constant(true);
          })
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.qualityScore)]))
        .get();
  }

  Future<void> updateFaceClusterAssignment(String faceId, String? clusterId) async {
    await (update(faceEmbeddings)..where((tbl) => tbl.faceId.equals(faceId)))
        .write(FaceEmbeddingsCompanion(clusterId: Value(clusterId)));
  }

  // Collection Methods
  Future<int> insertCollection(MediaCollectionsCompanion collection) {
    return into(mediaCollections).insert(collection);
  }

  Future<int> addMediaToCollection(String collectionId, String mediaId, {int? sortOrder}) {
    return into(mediaCollectionItems).insert(
      MediaCollectionItemsCompanion(
        collectionId: Value(collectionId),
        mediaId: Value(mediaId),
        sortOrder: Value(sortOrder),
      ),
    );
  }

  Stream<List<MediaCollection>> watchCollections() {
    return (select(mediaCollections)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
        .watch();
  }

  Future<List<MediaItem>> getMediaInCollection(String collectionId) async {
    final query = select(mediaItems).join([
      innerJoin(mediaCollectionItems,
        mediaCollectionItems.mediaId.equalsExp(mediaItems.id))
    ])..where(mediaCollectionItems.collectionId.equals(collectionId))
     ..orderBy([OrderingTerm.asc(mediaCollectionItems.sortOrder)]);

    final results = await query.get();
    return results.map((row) => row.readTable(mediaItems)).toList();
  }

  // Statistics and Analytics Methods
  Future<Map<String, int>> getMediaStatistics() async {
    final totalCount = await (selectOnly(mediaItems)
          ..addColumns([mediaItems.id.count()]))
        .getSingle();

    final imageCount = await (selectOnly(mediaItems)
          ..addColumns([mediaItems.id.count()])
          ..where(mediaItems.mimeType.like('image/%')))
        .getSingle();

    final videoCount = await (selectOnly(mediaItems)
          ..addColumns([mediaItems.id.count()])
          ..where(mediaItems.mimeType.like('video/%')))
        .getSingle();

    final facesCount = await (selectOnly(personTags)
          ..addColumns([personTags.id.count()]))
        .getSingle();

    final confirmedFaces = await (selectOnly(personTags)
          ..addColumns([personTags.id.count()])
          ..where(personTags.isConfirmed.equals(true)))
        .getSingle();

    return {
      'total_media': totalCount.read(mediaItems.id.count()) ?? 0,
      'images': imageCount.read(mediaItems.id.count()) ?? 0,
      'videos': videoCount.read(mediaItems.id.count()) ?? 0,
      'faces_detected': facesCount.read(personTags.id.count()) ?? 0,
      'faces_confirmed': confirmedFaces.read(personTags.id.count()) ?? 0,
    };
  }

  // Data Cleanup Methods
  Future<void> cleanupDeletedMedia({Duration retentionPeriod = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(retentionPeriod);

    // Get deleted media items older than retention period
    final deletedItems = await (select(mediaItems)
          ..where((tbl) =>
              tbl.isDeleted.equals(true) &
              tbl.addedDate.isSmallerThanValue(cutoff)))
        .get();

    // Delete associated metadata and tags first (cascade will handle this automatically)
    final ids = deletedItems.map((item) => item.id).toList();
    if (ids.isNotEmpty) {
      await (delete(mediaItems)
            ..where((tbl) => tbl.id.isIn(ids)))
          .go();
    }
  }

  Future<void> optimizeDatabase() async {
    // Run VACUUM to reclaim space
    await customStatement('VACUUM;');

    // Update statistics
    await customStatement('ANALYZE;');
  }

  // Migration and schema updates
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();

          // Create indices for better performance
          await customStatement('''
            CREATE INDEX idx_media_items_created_date ON media_items(created_date DESC);
          ''');
          await customStatement('''
            CREATE INDEX idx_media_items_file_hash ON media_items(file_hash);
          ''');
          await customStatement('''
            CREATE INDEX idx_media_metadata_media_type ON media_metadata(media_id, metadata_type);
          ''');
          await customStatement('''
            CREATE INDEX idx_person_tags_person_media ON person_tags(person_id, media_id);
          ''');
          await customStatement('''
            CREATE INDEX idx_face_embeddings_cluster ON face_embeddings(cluster_id);
          ''');
          await customStatement('''
            CREATE INDEX idx_collection_items_collection ON media_collection_items(collection_id, sort_order);
          ''');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle future schema updates
        },
      );
}
