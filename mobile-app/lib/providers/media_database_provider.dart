import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/media_database.dart';

// Singleton provider for the media database
final mediaDatabaseProvider = Provider<MediaDatabase>((ref) {
  final database = MediaDatabase();
  
  // Dispose the database when the provider is disposed
  ref.onDispose(() {
    database.close();
  });
  
  return database;
});

// Provider for watching media items
final mediaItemsProvider = StreamProvider.family<List<MediaItem>, ({bool includeDeleted, bool processedOnly})>(
  (ref, params) {
    final db = ref.watch(mediaDatabaseProvider);
    return db.watchMediaItems(
      includeDeleted: params.includeDeleted,
      processedOnly: params.processedOnly,
    );
  },
);

// Provider for recent media items
final recentMediaProvider = FutureProvider.family<List<MediaItem>, ({Duration duration, int limit})>(
  (ref, params) {
    final db = ref.watch(mediaDatabaseProvider);
    return db.getRecentMedia(
      duration: params.duration,
      limit: params.limit,
    );
  },
);

// Provider for person tags
final personTagsProvider = StreamProvider.family<List<PersonTag>, ({String? personId, bool confirmedOnly})>(
  (ref, params) {
    final db = ref.watch(mediaDatabaseProvider);
    return db.watchPersonTags(
      personId: params.personId,
      confirmedOnly: params.confirmedOnly,
    );
  },
);

// Provider for media collections
final mediaCollectionsProvider = StreamProvider<List<MediaCollection>>((ref) {
  final db = ref.watch(mediaDatabaseProvider);
  return db.watchCollections();
});

// Provider for media in a specific collection
final mediaInCollectionProvider = FutureProvider.family<List<MediaItem>, String>(
  (ref, collectionId) {
    final db = ref.watch(mediaDatabaseProvider);
    return db.getMediaInCollection(collectionId);
  },
);

// Provider for media statistics
final mediaStatisticsProvider = FutureProvider<Map<String, int>>((ref) {
  final db = ref.watch(mediaDatabaseProvider);
  return db.getMediaStatistics();
});

// Provider for media metadata
final mediaMetadataProvider = FutureProvider.family<List<MediaMetadataData>, ({String mediaId, String? metadataType})>(
  (ref, params) {
    final db = ref.watch(mediaDatabaseProvider);
    return db.getMetadataForMedia(params.mediaId, params.metadataType);
  },
);

// Provider for metadata map (key-value pairs)
final mediaMetadataMapProvider = FutureProvider.family<Map<String, dynamic>, ({String mediaId, String metadataType})>(
  (ref, params) {
    final db = ref.watch(mediaDatabaseProvider);
    return db.getMetadataMap(params.mediaId, params.metadataType);
  },
);

// Provider for face embeddings
final faceEmbeddingsProvider = FutureProvider.family<List<FaceEmbedding>, String?>(
  (ref, clusterId) {
    final db = ref.watch(mediaDatabaseProvider);
    return db.getFaceEmbeddings(clusterId: clusterId);
  },
);

// Provider for media management service
final mediaManagementProvider = Provider((ref) {
  return MediaManagementService(ref);
});

class MediaManagementService {
  final Ref ref;

  MediaManagementService(this.ref);

  MediaDatabase get _db => ref.read(mediaDatabaseProvider);

  // Media item management
  Future<void> addMediaItem({
    required String id,
    required String fileName,
    required String mimeType,
    required int fileSize,
    required DateTime createdDate,
    required DateTime modifiedDate,
    String? filePath,
    String? fileHash,
    int? width,
    int? height,
    int? duration,
  }) async {
    await _db.insertMediaItem(
      MediaItemsCompanion.insert(
        id: id,
        fileName: fileName,
        mimeType: mimeType,
        fileSize: fileSize,
        createdDate: createdDate,
        modifiedDate: modifiedDate,
        filePath: Value(filePath),
        fileHash: Value(fileHash),
        width: Value(width),
        height: Value(height),
        duration: Value(duration),
      ),
    );
  }

  Future<void> markMediaProcessed(String mediaId) async {
    await _db.updateMediaItem(
      MediaItemsCompanion(
        id: Value(mediaId),
        isProcessed: const Value(true),
      ),
    );
  }

  Future<void> deleteMediaItem(String mediaId) async {
    await _db.softDeleteMediaItem(mediaId);
  }

  // Metadata management
  Future<void> addMetadata({
    required String mediaId,
    required String metadataType,
    required String key,
    required String value,
    double? confidence,
  }) async {
    await _db.insertMetadata(
      MediaMetadataCompanion.insert(
        mediaId: mediaId,
        metadataType: metadataType,
        key: key,
        value: value,
        confidence: Value(confidence),
      ),
    );
  }

  // Person tagging
  Future<void> addPersonTag({
    required String personId,
    required String mediaId,
    required double boundingBoxX,
    required double boundingBoxY,
    required double boundingBoxWidth,
    required double boundingBoxHeight,
    required double confidence,
    String? personName,
    String? personNickname,
    double? similarity,
  }) async {
    await _db.insertPersonTag(
      PersonTagsCompanion.insert(
        personId: personId,
        mediaId: mediaId,
        boundingBoxX: boundingBoxX,
        boundingBoxY: boundingBoxY,
        boundingBoxWidth: boundingBoxWidth,
        boundingBoxHeight: boundingBoxHeight,
        confidence: confidence,
        personName: Value(personName),
        personNickname: Value(personNickname),
        similarity: Value(similarity),
      ),
    );
  }

  Future<void> confirmPersonTag(int tagId, bool isConfirmed) async {
    await _db.confirmPersonTag(tagId, isConfirmed);
  }

  // Face clustering
  Future<void> addFaceCluster({
    required String clusterId,
    String? personId,
    String? representativeFaceId,
    required int faceCount,
    required double averageConfidence,
    required double cohesion,
  }) async {
    await _db.insertFaceCluster(
      FaceClustersCompanion.insert(
        clusterId: clusterId,
        personId: Value(personId),
        representativeFaceId: Value(representativeFaceId),
        faceCount: faceCount,
        averageConfidence: averageConfidence,
        cohesion: cohesion,
      ),
    );
  }

  Future<void> addFaceEmbedding({
    required String faceId,
    required String mediaId,
    required String embedding,
    required double qualityScore,
    required double boundingBoxX,
    required double boundingBoxY,
    required double boundingBoxWidth,
    required double boundingBoxHeight,
    String? clusterId,
  }) async {
    await _db.insertFaceEmbedding(
      FaceEmbeddingsCompanion.insert(
        faceId: faceId,
        mediaId: mediaId,
        embedding: embedding,
        qualityScore: qualityScore,
        boundingBoxX: boundingBoxX,
        boundingBoxY: boundingBoxY,
        boundingBoxWidth: boundingBoxWidth,
        boundingBoxHeight: boundingBoxHeight,
        clusterId: Value(clusterId),
      ),
    );
  }

  Future<void> updateFaceClusterAssignment(String faceId, String? clusterId) async {
    await _db.updateFaceClusterAssignment(faceId, clusterId);
  }

  // Collection management
  Future<void> createCollection({
    required String id,
    required String name,
    String? description,
    String? coverMediaId,
  }) async {
    await _db.insertCollection(
      MediaCollectionsCompanion.insert(
        id: id,
        name: name,
        description: Value(description),
        coverMediaId: Value(coverMediaId),
      ),
    );
  }

  Future<void> addMediaToCollection(String collectionId, String mediaId, {int? sortOrder}) async {
    await _db.addMediaToCollection(collectionId, mediaId, sortOrder: sortOrder);
  }

  // Data cleanup
  Future<void> performCleanup({
    Duration retentionPeriod = const Duration(days: 30),
  }) async {
    await _db.cleanupDeletedMedia(retentionPeriod: retentionPeriod);
  }

  Future<void> optimizeDatabase() async {
    await _db.optimizeDatabase();
  }
}