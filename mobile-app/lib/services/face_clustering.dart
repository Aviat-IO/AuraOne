import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:photo_manager/photo_manager.dart';
import 'face_detector.dart';

/// Face embedding vector for similarity comparison
class FaceEmbedding {
  final String faceId;
  final String photoId;
  final List<double> vector;
  final double confidence;
  final DateTime timestamp;
  final Rect boundingBox;

  const FaceEmbedding({
    required this.faceId,
    required this.photoId,
    required this.vector,
    required this.confidence,
    required this.timestamp,
    required this.boundingBox,
  });

  /// Calculate cosine similarity with another embedding
  double similarity(FaceEmbedding other) {
    if (vector.length != other.vector.length) return 0.0;
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < vector.length; i++) {
      dotProduct += vector[i] * other.vector[i];
      normA += vector[i] * vector[i];
      normB += other.vector[i] * other.vector[i];
    }
    
    if (normA == 0.0 || normB == 0.0) return 0.0;
    
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Calculate Euclidean distance to another embedding
  double distance(FaceEmbedding other) {
    if (vector.length != other.vector.length) return double.infinity;
    
    double sum = 0.0;
    for (int i = 0; i < vector.length; i++) {
      final diff = vector[i] - other.vector[i];
      sum += diff * diff;
    }
    
    return math.sqrt(sum);
  }

  Map<String, dynamic> toJson() => {
    'faceId': faceId,
    'photoId': photoId,
    'vector': vector,
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
    'boundingBox': {
      'left': boundingBox.left,
      'top': boundingBox.top,
      'right': boundingBox.right,
      'bottom': boundingBox.bottom,
    },
  };

  factory FaceEmbedding.fromJson(Map<String, dynamic> json) => FaceEmbedding(
    faceId: json['faceId'],
    photoId: json['photoId'],
    vector: List<double>.from(json['vector']),
    confidence: json['confidence'],
    timestamp: DateTime.parse(json['timestamp']),
    boundingBox: Rect.fromLTRB(
      json['boundingBox']['left'],
      json['boundingBox']['top'],
      json['boundingBox']['right'],
      json['boundingBox']['bottom'],
    ),
  );
}

/// A cluster of faces belonging to the same person
class FaceCluster {
  final String clusterId;
  final List<FaceEmbedding> faces;
  final FaceEmbedding centroid;
  final double confidence;
  final String? personName;
  final DateTime createdAt;
  final DateTime updatedAt;

  FaceCluster({
    required this.clusterId,
    required this.faces,
    required this.centroid,
    required this.confidence,
    this.personName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Get the representative face (highest quality)
  FaceEmbedding get representativeFace {
    if (faces.isEmpty) return centroid;
    
    return faces.reduce((a, b) => 
      a.confidence > b.confidence ? a : b
    );
  }

  /// Get unique photo IDs in this cluster
  Set<String> get photoIds => faces.map((f) => f.photoId).toSet();

  /// Number of unique photos this person appears in
  int get photoCount => photoIds.length;

  /// Average confidence of faces in cluster
  double get averageConfidence {
    if (faces.isEmpty) return 0.0;
    return faces.map((f) => f.confidence).reduce((a, b) => a + b) / faces.length;
  }

  /// Create a new cluster with additional faces
  FaceCluster addFaces(List<FaceEmbedding> newFaces) {
    final allFaces = [...faces, ...newFaces];
    final newCentroid = _calculateCentroid(allFaces);
    final newConfidence = _calculateClusterConfidence(allFaces);
    
    return FaceCluster(
      clusterId: clusterId,
      faces: allFaces,
      centroid: newCentroid,
      confidence: newConfidence,
      personName: personName,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a new cluster with a person name
  FaceCluster withPersonName(String name) {
    return FaceCluster(
      clusterId: clusterId,
      faces: faces,
      centroid: centroid,
      confidence: confidence,
      personName: name,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static FaceEmbedding _calculateCentroid(List<FaceEmbedding> faces) {
    if (faces.isEmpty) throw ArgumentError('Cannot calculate centroid of empty face list');
    
    final vectorLength = faces.first.vector.length;
    final centroidVector = List<double>.filled(vectorLength, 0.0);
    
    for (final face in faces) {
      for (int i = 0; i < vectorLength; i++) {
        centroidVector[i] += face.vector[i];
      }
    }
    
    for (int i = 0; i < vectorLength; i++) {
      centroidVector[i] /= faces.length;
    }
    
    // Use representative face metadata for centroid
    final representative = faces.reduce((a, b) => a.confidence > b.confidence ? a : b);
    
    return FaceEmbedding(
      faceId: 'centroid_${representative.faceId}',
      photoId: representative.photoId,
      vector: centroidVector,
      confidence: faces.map((f) => f.confidence).reduce((a, b) => a + b) / faces.length,
      timestamp: DateTime.now(),
      boundingBox: representative.boundingBox,
    );
  }

  static double _calculateClusterConfidence(List<FaceEmbedding> faces) {
    if (faces.isEmpty) return 0.0;
    if (faces.length == 1) return faces.first.confidence;
    
    // Calculate confidence based on:
    // 1. Average face confidence (40%)
    // 2. Cluster cohesion - how similar faces are to centroid (40%)
    // 3. Cluster size bonus - more faces = higher confidence (20%)
    
    final averageConfidence = faces.map((f) => f.confidence).reduce((a, b) => a + b) / faces.length;
    
    final centroid = _calculateCentroid(faces);
    final cohesion = faces.map((f) => f.similarity(centroid)).reduce((a, b) => a + b) / faces.length;
    
    final sizeBonus = math.min(faces.length / 10.0, 1.0); // Cap at 10 faces for full bonus
    
    return (averageConfidence * 0.4) + (cohesion * 0.4) + (sizeBonus * 0.2);
  }

  Map<String, dynamic> toJson() => {
    'clusterId': clusterId,
    'faces': faces.map((f) => f.toJson()).toList(),
    'centroid': centroid.toJson(),
    'confidence': confidence,
    'personName': personName,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FaceCluster.fromJson(Map<String, dynamic> json) => FaceCluster(
    clusterId: json['clusterId'],
    faces: (json['faces'] as List).map((f) => FaceEmbedding.fromJson(f)).toList(),
    centroid: FaceEmbedding.fromJson(json['centroid']),
    confidence: json['confidence'],
    personName: json['personName'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

/// Configuration for face clustering algorithms
class ClusteringConfig {
  final double similarityThreshold;
  final int minClusterSize;
  final int maxClusters;
  final double dbscanEps;
  final int dbscanMinSamples;
  final bool useDBSCAN;
  
  const ClusteringConfig({
    this.similarityThreshold = 0.7,
    this.minClusterSize = 2,
    this.maxClusters = 100,
    this.dbscanEps = 0.3,
    this.dbscanMinSamples = 2,
    this.useDBSCAN = true,
  });

  /// Configuration optimized for high precision (fewer false positives)
  static const ClusteringConfig highPrecision = ClusteringConfig(
    similarityThreshold: 0.8,
    minClusterSize: 3,
    dbscanEps: 0.2,
    dbscanMinSamples: 3,
  );

  /// Configuration optimized for high recall (catch more faces)
  static const ClusteringConfig highRecall = ClusteringConfig(
    similarityThreshold: 0.6,
    minClusterSize: 2,
    dbscanEps: 0.4,
    dbscanMinSamples: 2,
  );

  /// Balanced configuration for most use cases
  static const ClusteringConfig balanced = ClusteringConfig();
}

/// Service for clustering faces by person using machine learning
class FaceClusteringService {
  final ClusteringConfig _config;
  
  FaceClusteringService({ClusteringConfig? config}) 
    : _config = config ?? const ClusteringConfig();

  /// Generate face embedding from detected face landmarks and features
  FaceEmbedding generateEmbedding(DetectedFace face, String photoId, String faceId) {
    // Create feature vector from available face data
    final features = <double>[];
    
    // Add bounding box features (normalized)
    features.addAll([
      face.boundingBox.left / 1000.0,
      face.boundingBox.top / 1000.0,
      face.boundingBox.width / 1000.0,
      face.boundingBox.height / 1000.0,
    ]);
    
    // Add head pose features (normalized to -1 to 1 range)
    features.addAll([
      (face.headEulerAngleX ?? 0.0) / 180.0,
      (face.headEulerAngleY ?? 0.0) / 180.0,
      (face.headEulerAngleZ ?? 0.0) / 180.0,
    ]);
    
    // Add facial expression features
    features.addAll([
      face.leftEyeOpenProbability ?? 0.5,
      face.rightEyeOpenProbability ?? 0.5,
      face.smilingProbability ?? 0.5,
    ]);
    
    // Add landmark-based features
    if (face.landmarks.isNotEmpty) {
      // Group landmarks by type for consistent feature extraction
      final landmarkFeatures = _extractLandmarkFeatures(face.landmarks);
      features.addAll(landmarkFeatures);
    } else {
      // Add zero padding if no landmarks available
      features.addAll(List<double>.filled(20, 0.0));
    }
    
    // Normalize the feature vector
    final normalizedFeatures = _normalizeVector(features);
    
    return FaceEmbedding(
      faceId: faceId,
      photoId: photoId,
      vector: normalizedFeatures,
      confidence: face.qualityScore,
      timestamp: DateTime.now(),
      boundingBox: face.boundingBox,
    );
  }

  /// Extract features from face landmarks
  List<double> _extractLandmarkFeatures(List<FaceLandmark> landmarks) {
    final features = <double>[];
    
    // Extract landmark positions relative to face bounds
    final Map<FaceLandmarkType, List<FaceLandmark>> groupedLandmarks = {};
    
    for (final landmark in landmarks) {
      groupedLandmarks.putIfAbsent(landmark.type, () => []).add(landmark);
    }
    
    // Define key landmark types for feature extraction
    const keyTypes = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.bottomMouth,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
    ];
    
    for (final type in keyTypes) {
      final landmarks = groupedLandmarks[type];
      if (landmarks != null && landmarks.isNotEmpty) {
        final landmark = landmarks.first;
        // Add normalized position (x, y) - convert Point<int> to double
        features.addAll([
          landmark.position.x.toDouble() / 1000.0,
          landmark.position.y.toDouble() / 1000.0,
        ]);
      } else {
        // Add zero padding for missing landmarks
        features.addAll([0.0, 0.0]);
      }
    }
    
    // Calculate relative distances between key landmarks
    final leftEye = groupedLandmarks[FaceLandmarkType.leftEye]?.first.position;
    final rightEye = groupedLandmarks[FaceLandmarkType.rightEye]?.first.position;
    final nose = groupedLandmarks[FaceLandmarkType.noseBase]?.first.position;
    final mouth = groupedLandmarks[FaceLandmarkType.bottomMouth]?.first.position;
    
    if (leftEye != null && rightEye != null) {
      final eyeDistance = (leftEye.x.toDouble() - rightEye.x.toDouble()).abs() / 1000.0;
      features.add(eyeDistance);
      
      if (nose != null) {
        final eyeNoseRatio = ((leftEye.y.toDouble() + rightEye.y.toDouble()) / 2.0 - nose.y.toDouble()).abs() / 1000.0;
        features.add(eyeNoseRatio);
        
        if (mouth != null) {
          final noseMouthRatio = (nose.y.toDouble() - mouth.y.toDouble()).abs() / 1000.0;
          features.add(noseMouthRatio);
        } else {
          features.add(0.0);
        }
      } else {
        features.addAll([0.0, 0.0]);
      }
    } else {
      features.addAll([0.0, 0.0, 0.0]);
    }
    
    // Pad to consistent length
    while (features.length < 20) {
      features.add(0.0);
    }
    
    return features.take(20).toList();
  }

  /// Normalize feature vector to unit length
  List<double> _normalizeVector(List<double> vector) {
    double magnitude = 0.0;
    for (final value in vector) {
      magnitude += value * value;
    }
    magnitude = math.sqrt(magnitude);
    
    if (magnitude == 0.0) return vector;
    
    return vector.map((v) => v / magnitude).toList();
  }

  /// Cluster faces using DBSCAN algorithm
  Future<List<FaceCluster>> clusterFaces(List<FaceEmbedding> embeddings) async {
    if (embeddings.isEmpty) return [];
    
    if (_config.useDBSCAN) {
      return await _dbscanClustering(embeddings);
    } else {
      return await _hierarchicalClustering(embeddings);
    }
  }

  /// DBSCAN clustering implementation
  Future<List<FaceCluster>> _dbscanClustering(List<FaceEmbedding> embeddings) async {
    final clusters = <List<FaceEmbedding>>[];
    final visited = List<bool>.filled(embeddings.length, false);
    final clustered = List<bool>.filled(embeddings.length, false);
    
    for (int i = 0; i < embeddings.length; i++) {
      if (visited[i]) continue;
      
      visited[i] = true;
      final neighbors = _getNeighbors(embeddings, i, _config.dbscanEps);
      
      if (neighbors.length < _config.dbscanMinSamples) {
        continue; // Mark as noise
      }
      
      // Create new cluster
      final cluster = <FaceEmbedding>[embeddings[i]];
      clustered[i] = true;
      
      // Expand cluster
      final neighborQueue = [...neighbors];
      int queueIndex = 0;
      
      while (queueIndex < neighborQueue.length) {
        final neighborIdx = neighborQueue[queueIndex];
        queueIndex++;
        
        if (!visited[neighborIdx]) {
          visited[neighborIdx] = true;
          final newNeighbors = _getNeighbors(embeddings, neighborIdx, _config.dbscanEps);
          
          if (newNeighbors.length >= _config.dbscanMinSamples) {
            neighborQueue.addAll(newNeighbors.where((n) => !neighborQueue.contains(n)));
          }
        }
        
        if (!clustered[neighborIdx]) {
          cluster.add(embeddings[neighborIdx]);
          clustered[neighborIdx] = true;
        }
      }
      
      if (cluster.length >= _config.minClusterSize) {
        clusters.add(cluster);
      }
    }
    
    // Convert to FaceCluster objects
    final faceClusters = <FaceCluster>[];
    for (int i = 0; i < clusters.length; i++) {
      final clusterFaces = clusters[i];
      if (clusterFaces.isNotEmpty) {
        faceClusters.add(FaceCluster(
          clusterId: 'cluster_${DateTime.now().millisecondsSinceEpoch}_$i',
          faces: clusterFaces,
          centroid: FaceCluster._calculateCentroid(clusterFaces),
          confidence: FaceCluster._calculateClusterConfidence(clusterFaces),
        ));
      }
    }
    
    return faceClusters;
  }

  /// Get neighbors within epsilon distance
  List<int> _getNeighbors(List<FaceEmbedding> embeddings, int pointIndex, double eps) {
    final neighbors = <int>[];
    final point = embeddings[pointIndex];
    
    for (int i = 0; i < embeddings.length; i++) {
      if (i != pointIndex && point.distance(embeddings[i]) <= eps) {
        neighbors.add(i);
      }
    }
    
    return neighbors;
  }

  /// Simple hierarchical clustering as fallback
  Future<List<FaceCluster>> _hierarchicalClustering(List<FaceEmbedding> embeddings) async {
    if (embeddings.isEmpty) return [];
    
    final clusters = <FaceCluster>[];
    final remaining = List<FaceEmbedding>.from(embeddings);
    
    while (remaining.isNotEmpty && clusters.length < _config.maxClusters) {
      final seed = remaining.removeAt(0);
      final clusterFaces = [seed];
      
      // Find similar faces
      final toRemove = <FaceEmbedding>[];
      for (final face in remaining) {
        if (seed.similarity(face) >= _config.similarityThreshold) {
          clusterFaces.add(face);
          toRemove.add(face);
        }
      }
      
      // Remove clustered faces from remaining
      for (final face in toRemove) {
        remaining.remove(face);
      }
      
      // Create cluster if it meets minimum size
      if (clusterFaces.length >= _config.minClusterSize) {
        clusters.add(FaceCluster(
          clusterId: 'cluster_${DateTime.now().millisecondsSinceEpoch}_${clusters.length}',
          faces: clusterFaces,
          centroid: FaceCluster._calculateCentroid(clusterFaces),
          confidence: FaceCluster._calculateClusterConfidence(clusterFaces),
        ));
      }
    }
    
    return clusters;
  }

  /// Find the best matching cluster for a new face
  FaceCluster? findBestMatch(FaceEmbedding embedding, List<FaceCluster> clusters) {
    FaceCluster? bestMatch;
    double bestSimilarity = 0.0;
    
    for (final cluster in clusters) {
      final similarity = embedding.similarity(cluster.centroid);
      if (similarity >= _config.similarityThreshold && similarity > bestSimilarity) {
        bestMatch = cluster;
        bestSimilarity = similarity;
      }
    }
    
    return bestMatch;
  }

  /// Merge two clusters if they are similar enough
  FaceCluster? mergeClusters(FaceCluster cluster1, FaceCluster cluster2) {
    final similarity = cluster1.centroid.similarity(cluster2.centroid);
    
    if (similarity >= _config.similarityThreshold) {
      final allFaces = [...cluster1.faces, ...cluster2.faces];
      return FaceCluster(
        clusterId: cluster1.clusterId, // Keep first cluster ID
        faces: allFaces,
        centroid: FaceCluster._calculateCentroid(allFaces),
        confidence: FaceCluster._calculateClusterConfidence(allFaces),
        personName: cluster1.personName ?? cluster2.personName,
        createdAt: cluster1.createdAt.isBefore(cluster2.createdAt) 
          ? cluster1.createdAt 
          : cluster2.createdAt,
      );
    }
    
    return null;
  }

  /// Update existing clusters with new faces
  Future<List<FaceCluster>> updateClusters(
    List<FaceCluster> existingClusters, 
    List<FaceEmbedding> newEmbeddings,
  ) async {
    final updatedClusters = <FaceCluster>[];
    final unclusteredFaces = <FaceEmbedding>[];
    
    // Try to assign new faces to existing clusters
    for (final embedding in newEmbeddings) {
      final bestMatch = findBestMatch(embedding, existingClusters);
      
      if (bestMatch != null) {
        // Find and update the cluster
        bool updated = false;
        for (int i = 0; i < updatedClusters.length; i++) {
          if (updatedClusters[i].clusterId == bestMatch.clusterId) {
            updatedClusters[i] = updatedClusters[i].addFaces([embedding]);
            updated = true;
            break;
          }
        }
        
        if (!updated) {
          // First update to this cluster
          final existingIndex = existingClusters.indexWhere(
            (c) => c.clusterId == bestMatch.clusterId
          );
          if (existingIndex != -1) {
            updatedClusters.add(existingClusters[existingIndex].addFaces([embedding]));
          }
        }
      } else {
        unclusteredFaces.add(embedding);
      }
    }
    
    // Add existing clusters that weren't updated
    for (final cluster in existingClusters) {
      if (!updatedClusters.any((c) => c.clusterId == cluster.clusterId)) {
        updatedClusters.add(cluster);
      }
    }
    
    // Create new clusters from unclustered faces
    if (unclusteredFaces.isNotEmpty) {
      final newClusters = await clusterFaces(unclusteredFaces);
      updatedClusters.addAll(newClusters);
    }
    
    return updatedClusters;
  }
}

/// Extension to add clustering capabilities to AssetEntity
extension AssetEntityClustering on AssetEntity {
  /// Generate face embeddings for this asset
  Future<List<FaceEmbedding>> generateFaceEmbeddings([
    FaceDetectionService? faceDetector,
    FaceClusteringService? clusteringService,
  ]) async {
    final detector = faceDetector ?? FaceDetectionService();
    final clustering = clusteringService ?? FaceClusteringService();
    
    try {
      final result = await detector.detectFacesInAsset(this);
      final embeddings = <FaceEmbedding>[];
      
      for (int i = 0; i < result.faces.length; i++) {
        final face = result.faces[i];
        final faceId = '${id}_face_$i';
        final embedding = clustering.generateEmbedding(face, id, faceId);
        embeddings.add(embedding);
      }
      
      return embeddings;
    } catch (e) {
      return [];
    } finally {
      if (faceDetector == null) {
        await detector.dispose();
      }
    }
  }
}