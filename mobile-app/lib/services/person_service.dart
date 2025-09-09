import 'dart:async';
import 'dart:convert';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'face_clustering.dart';
import '../utils/logger.dart';

/// A person identified through face clustering
class Person {
  final String personId;
  final String? name;
  final String? nickname;
  final FaceCluster cluster;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  Person({
    required this.personId,
    this.name,
    this.nickname,
    required this.cluster,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.metadata = const {},
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Display name with fallback to "Unknown Person"
  String get displayName => name ?? nickname ?? 'Unknown Person';

  /// Whether this person has been named by the user
  bool get isNamed => name != null || nickname != null;

  /// Get the best representative photo for this person
  FaceEmbedding get representativeFace => cluster.representativeFace;

  /// Number of photos this person appears in
  int get photoCount => cluster.photoCount;

  /// Average confidence score for this person's face detection
  double get averageConfidence => cluster.averageConfidence;

  /// Create a copy with updated information
  Person copyWith({
    String? name,
    String? nickname,
    FaceCluster? cluster,
    Map<String, dynamic>? metadata,
  }) {
    return Person(
      personId: personId,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      cluster: cluster ?? this.cluster,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'personId': personId,
    'name': name,
    'nickname': nickname,
    'cluster': cluster.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    personId: json['personId'],
    name: json['name'],
    nickname: json['nickname'],
    cluster: FaceCluster.fromJson(json['cluster']),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
  );
}

/// Configuration for person identification
class PersonServiceConfig {
  final int maxPersons;
  final double mergeThreshold;
  final int minPhotosForPerson;
  final bool autoMerge;
  final Duration cacheExpiry;

  const PersonServiceConfig({
    this.maxPersons = 1000,
    this.mergeThreshold = 0.8,
    this.minPhotosForPerson = 2,
    this.autoMerge = true,
    this.cacheExpiry = const Duration(hours: 24),
  });
}

/// Service for person identification and management
class PersonService {
  static final _logger = AppLogger('PersonService');
  final PersonServiceConfig _config;
  final FaceClusteringService _clusteringService;
  
  static const String _storageKey = 'persons_data';
  static const String _embeddinKey = 'face_embeddings';
  
  List<Person> _persons = [];
  List<FaceEmbedding> _embeddings = [];
  SharedPreferences? _prefs;

  PersonService({
    PersonServiceConfig? config,
    FaceClusteringService? clusteringService,
  }) : _config = config ?? const PersonServiceConfig(),
       _clusteringService = clusteringService ?? FaceClusteringService();

  /// Initialize the service
  Future<void> initialize() async {
    _logger.info('Initializing PersonService...');
    
    _prefs = await SharedPreferences.getInstance();
    await _loadData();
    
    _logger.info('PersonService initialized with ${_persons.length} persons');
  }

  /// Get all identified persons
  List<Person> get persons => List.unmodifiable(_persons);

  /// Get all face embeddings
  List<FaceEmbedding> get embeddings => List.unmodifiable(_embeddings);

  /// Get a person by ID
  Person? getPersonById(String personId) {
    try {
      return _persons.firstWhere((p) => p.personId == personId);
    } catch (e) {
      return null;
    }
  }

  /// Get persons by name (case-insensitive partial match)
  List<Person> searchPersonsByName(String query) {
    final queryLower = query.toLowerCase();
    return _persons.where((p) => 
      p.displayName.toLowerCase().contains(queryLower)
    ).toList();
  }

  /// Get the person that appears in a specific photo
  List<Person> getPersonsInPhoto(String photoId) {
    return _persons.where((p) => 
      p.cluster.photoIds.contains(photoId)
    ).toList();
  }

  /// Process face embeddings to identify or create persons
  Future<List<Person>> processEmbeddings(List<FaceEmbedding> newEmbeddings) async {
    if (newEmbeddings.isEmpty) return [];
    
    _logger.info('Processing ${newEmbeddings.length} face embeddings for person identification');
    
    // Add new embeddings to our collection
    _embeddings.addAll(newEmbeddings);
    
    // Update clusters with new embeddings
    final existingClusters = _persons.map((p) => p.cluster).toList();
    final updatedClusters = await _clusteringService.updateClusters(
      existingClusters, 
      newEmbeddings,
    );
    
    // Convert clusters back to persons, preserving existing person data
    final updatedPersons = <Person>[];
    final newClusters = <FaceCluster>[];
    
    for (final cluster in updatedClusters) {
      final existingPerson = _persons.where(
        (p) => p.cluster.clusterId == cluster.clusterId
      ).firstOrNull;
      
      if (existingPerson != null) {
        // Update existing person with new cluster data
        updatedPersons.add(existingPerson.copyWith(cluster: cluster));
      } else {
        // New cluster - will become a new person
        newClusters.add(cluster);
      }
    }
    
    // Create new persons for new clusters
    for (final cluster in newClusters) {
      if (cluster.faces.length >= _config.minPhotosForPerson) {
        final person = Person(
          personId: 'person_${DateTime.now().millisecondsSinceEpoch}_${updatedPersons.length}',
          cluster: cluster,
        );
        updatedPersons.add(person);
      }
    }
    
    // Auto-merge similar persons if enabled
    if (_config.autoMerge) {
      final mergedPersons = await _autoMergePersons(updatedPersons);
      _persons = mergedPersons;
    } else {
      _persons = updatedPersons;
    }
    
    // Save updated data
    await _saveData();
    
    _logger.info('Person identification complete: ${_persons.length} total persons');
    
    return _persons;
  }

  /// Process photos to extract faces and identify persons
  Future<List<Person>> processPhotos(List<AssetEntity> photos) async {
    _logger.info('Processing ${photos.length} photos for person identification');
    
    final allEmbeddings = <FaceEmbedding>[];
    
    // Extract face embeddings from all photos
    for (final photo in photos) {
      try {
        final embeddings = await photo.generateFaceEmbeddings(null, _clusteringService);
        allEmbeddings.addAll(embeddings);
      } catch (e) {
        _logger.error('Failed to process photo ${photo.id}: $e');
      }
    }
    
    return await processEmbeddings(allEmbeddings);
  }

  /// Name a person
  Future<Person?> namePerson(String personId, String name) async {
    final person = getPersonById(personId);
    if (person == null) return null;
    
    _logger.info('Naming person $personId as "$name"');
    
    final updatedPerson = person.copyWith(name: name);
    
    // Update the person in our list
    final index = _persons.indexWhere((p) => p.personId == personId);
    if (index != -1) {
      _persons[index] = updatedPerson;
      await _saveData();
    }
    
    return updatedPerson;
  }

  /// Set a nickname for a person
  Future<Person?> setNickname(String personId, String nickname) async {
    final person = getPersonById(personId);
    if (person == null) return null;
    
    _logger.info('Setting nickname for person $personId: "$nickname"');
    
    final updatedPerson = person.copyWith(nickname: nickname);
    
    // Update the person in our list
    final index = _persons.indexWhere((p) => p.personId == personId);
    if (index != -1) {
      _persons[index] = updatedPerson;
      await _saveData();
    }
    
    return updatedPerson;
  }

  /// Merge two persons into one
  Future<Person?> mergePersons(String person1Id, String person2Id, {String? newName}) async {
    final person1 = getPersonById(person1Id);
    final person2 = getPersonById(person2Id);
    
    if (person1 == null || person2 == null) return null;
    
    _logger.info('Merging persons $person1Id and $person2Id');
    
    // Merge clusters
    final mergedCluster = _clusteringService.mergeClusters(person1.cluster, person2.cluster);
    if (mergedCluster == null) {
      _logger.warning('Could not merge persons - clusters are too dissimilar');
      return null;
    }
    
    // Create new merged person
    final mergedPerson = Person(
      personId: person1Id, // Keep first person's ID
      name: newName ?? person1.name ?? person2.name,
      nickname: person1.nickname ?? person2.nickname,
      cluster: mergedCluster,
      createdAt: person1.createdAt.isBefore(person2.createdAt) ? person1.createdAt : person2.createdAt,
      metadata: {...person1.metadata, ...person2.metadata},
    );
    
    // Remove both old persons and add merged person
    _persons.removeWhere((p) => p.personId == person1Id || p.personId == person2Id);
    _persons.add(mergedPerson);
    
    await _saveData();
    return mergedPerson;
  }

  /// Delete a person
  Future<bool> deletePerson(String personId) async {
    final initialLength = _persons.length;
    _persons.removeWhere((p) => p.personId == personId);
    final removedCount = initialLength - _persons.length;
    
    if (removedCount > 0) {
      _logger.info('Deleted person $personId');
      await _saveData();
      return true;
    }
    return false;
  }

  /// Get statistics about person identification
  Map<String, dynamic> getStatistics() {
    final namedPersons = _persons.where((p) => p.isNamed).length;
    final totalFaces = _embeddings.length;
    final totalPhotos = _persons.fold<Set<String>>(
      {},
      (photos, person) => photos..addAll(person.cluster.photoIds),
    ).length;
    
    return {
      'totalPersons': _persons.length,
      'namedPersons': namedPersons,
      'unnamedPersons': _persons.length - namedPersons,
      'totalFaces': totalFaces,
      'photosWithFaces': totalPhotos,
      'averagePhotosPerPerson': _persons.isEmpty ? 0.0 : totalPhotos / _persons.length,
      'averageConfidence': _persons.isEmpty ? 0.0 : 
        _persons.map((p) => p.averageConfidence).reduce((a, b) => a + b) / _persons.length,
    };
  }

  /// Clear all person data
  Future<void> clearAllData() async {
    _logger.info('Clearing all person data');
    
    _persons.clear();
    _embeddings.clear();
    
    await _prefs?.remove(_storageKey);
    await _prefs?.remove(_embeddinKey);
  }

  /// Auto-merge similar persons
  Future<List<Person>> _autoMergePersons(List<Person> persons) async {
    final mergedPersons = <Person>[];
    final processed = <String>{};
    
    for (final person1 in persons) {
      if (processed.contains(person1.personId)) continue;
      
      Person currentPerson = person1;
      
      // Look for persons to merge with this one
      for (final person2 in persons) {
        if (person2.personId == person1.personId || processed.contains(person2.personId)) continue;
        
        final similarity = person1.cluster.centroid.similarity(person2.cluster.centroid);
        
        if (similarity >= _config.mergeThreshold) {
          // Merge person2 into currentPerson
          final mergedCluster = _clusteringService.mergeClusters(
            currentPerson.cluster, 
            person2.cluster,
          );
          
          if (mergedCluster != null) {
            _logger.info('Auto-merging persons ${person1.personId} and ${person2.personId} (similarity: ${similarity.toStringAsFixed(3)})');
            
            currentPerson = Person(
              personId: currentPerson.personId,
              name: currentPerson.name ?? person2.name,
              nickname: currentPerson.nickname ?? person2.nickname,
              cluster: mergedCluster,
              createdAt: currentPerson.createdAt.isBefore(person2.createdAt) 
                ? currentPerson.createdAt 
                : person2.createdAt,
              metadata: {...currentPerson.metadata, ...person2.metadata},
            );
            
            processed.add(person2.personId);
          }
        }
      }
      
      mergedPersons.add(currentPerson);
      processed.add(person1.personId);
    }
    
    return mergedPersons;
  }

  /// Load data from persistent storage
  Future<void> _loadData() async {
    try {
      // Load persons
      final personsJson = _prefs?.getString(_storageKey);
      if (personsJson != null) {
        final data = jsonDecode(personsJson) as Map<String, dynamic>;
        _persons = (data['persons'] as List)
          .map((p) => Person.fromJson(p))
          .toList();
        // Parse timestamp if needed
      }
      
      // Load embeddings
      final embeddingsJson = _prefs?.getString(_embeddinKey);
      if (embeddingsJson != null) {
        final data = jsonDecode(embeddingsJson) as List;
        _embeddings = data.map((e) => FaceEmbedding.fromJson(e)).toList();
      }
      
      _logger.info('Loaded ${_persons.length} persons and ${_embeddings.length} face embeddings from storage');
    } catch (e) {
      _logger.error('Failed to load person data: $e');
      _persons = [];
      _embeddings = [];
    }
  }

  /// Save data to persistent storage
  Future<void> _saveData() async {
    try {
      // Save persons
      final personsData = {
        'persons': _persons.map((p) => p.toJson()).toList(),
        'lastUpdate': DateTime.now().toIso8601String(),
      };
      await _prefs?.setString(_storageKey, jsonEncode(personsData));
      
      // Save embeddings
      final embeddingsData = _embeddings.map((e) => e.toJson()).toList();
      await _prefs?.setString(_embeddinKey, jsonEncode(embeddingsData));
      
      _logger.info('Saved ${_persons.length} persons and ${_embeddings.length} embeddings to storage');
    } catch (e) {
      _logger.error('Failed to save person data: $e');
    }
  }
}

/// Extension methods for working with persons in photos
extension AssetEntityPersons on AssetEntity {
  /// Get all persons identified in this photo
  Future<List<Person>> getPersons([PersonService? personService]) async {
    final service = personService ?? PersonService();
    if (personService == null) {
      await service.initialize();
    }
    
    return service.getPersonsInPhoto(id);
  }
}