import 'dart:async';
import 'dart:convert';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

final logger = AppLogger('PersonService');

/// Stub implementation of PersonService
/// Face detection and person recognition have been removed for APK size optimization
class Person {
  final String personId;
  final String? name;
  final String? nickname;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  Person({
    required this.personId,
    this.name,
    this.nickname,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.metadata = const {},
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get displayName => name ?? nickname ?? 'Unknown Person';
  bool get isNamed => name != null || nickname != null;
  int get photoCount => 0; // Stub implementation
  double get averageConfidence => 0.0; // Stub implementation

  Person copyWith({
    String? name,
    String? nickname,
    Map<String, dynamic>? metadata,
  }) {
    return Person(
      personId: personId,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'personId': personId,
    'name': name,
    'nickname': nickname,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    personId: json['personId'],
    name: json['name'],
    nickname: json['nickname'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    metadata: json['metadata'] ?? {},
  );
}

/// Stub implementation of PersonService
class PersonService {
  static const String _storageKey = 'person_service_data';
  static const String _personsKey = 'persons';

  final List<Person> _persons = [];
  bool _isInitialized = false;

  PersonService();

  List<Person> get persons => List.unmodifiable(_persons);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadState();
      _isInitialized = true;
      logger.info('Initialized (stub implementation)');
    } catch (e) {
      logger.error('Initialization failed', error: e);
    }
  }

  Future<List<Person>> processEmbeddings(List<dynamic> newEmbeddings) async {
    // Stub implementation - returns empty list
    return [];
  }

  Future<void> addManualPerson({
    required String name,
    String? nickname,
    Map<String, dynamic>? metadata,
  }) async {
    final person = Person(
      personId: 'person_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      nickname: nickname,
      metadata: metadata ?? {},
    );

    _persons.add(person);
    await _saveState();
  }

  Future<void> updatePerson(String personId, {
    String? name,
    String? nickname,
    Map<String, dynamic>? metadata,
  }) async {
    final index = _persons.indexWhere((p) => p.personId == personId);
    if (index == -1) {
      throw ArgumentError('Person not found: $personId');
    }

    _persons[index] = _persons[index].copyWith(
      name: name,
      nickname: nickname,
      metadata: metadata,
    );

    await _saveState();
  }

  Future<void> renamePerson(String personId, String newName) async {
    await updatePerson(personId, name: newName);
  }

  Future<void> mergePerson(String sourceId, String targetId) async {
    // Stub implementation
    logger.info('Merge person stub: $sourceId -> $targetId');
  }

  Future<void> deletePerson(String personId) async {
    _persons.removeWhere((p) => p.personId == personId);
    await _saveState();
  }

  Future<void> processGalleryPhotos({
    bool forceReprocess = false,
    void Function(int processed, int total)? onProgress,
  }) async {
    // Stub implementation
    logger.info('Gallery processing skipped (stub)');
    onProgress?.call(0, 0);
  }

  Future<List<AssetEntity>> getPhotosForPerson(String personId) async {
    // Stub implementation - returns empty list
    return [];
  }

  Future<List<AssetEntity>> getUnknownPersonPhotos() async {
    // Stub implementation - returns empty list
    return [];
  }

  Person? getPersonById(String personId) {
    try {
      return _persons.firstWhere((p) => p.personId == personId);
    } catch (e) {
      return null;
    }
  }

  /// Process photos for person identification (stub)
  Future<List<Person>> processPhotos(List<dynamic> photos) async {
    // Stub implementation - returns empty list
    logger.info('Processing photos skipped (stub)');
    return [];
  }

  /// Get persons in a specific photo (stub)
  List<Person> getPersonsInPhoto(String photoId) {
    // Stub implementation - returns empty list
    return [];
  }

  /// Name a person (stub)
  Future<Person?> namePerson(String personId, String name) async {
    await updatePerson(personId, name: name);
    return getPersonById(personId);
  }

  /// Merge two persons (stub)
  Future<Person?> mergePersons(String person1Id, String person2Id, {String? newName}) async {
    // Stub implementation
    logger.info('Merge persons stub: $person1Id -> $person2Id');
    final person1 = getPersonById(person1Id);
    if (person1 != null && newName != null) {
      await updatePerson(person1Id, name: newName);
    }
    await deletePerson(person2Id);
    return getPersonById(person1Id);
  }

  /// Get statistics (stub)
  Map<String, dynamic> getStatistics() {
    return {
      'total_persons': _persons.length,
      'named_persons': _persons.where((p) => p.isNamed).length,
      'unnamed_persons': _persons.where((p) => !p.isNamed).length,
      'average_confidence': 0.0,
      'photos_processed': 0,
    };
  }

  /// Search persons by name (stub)
  List<Person> searchPersonsByName(String query) {
    final lowerQuery = query.toLowerCase();
    return _persons.where((p) {
      final nameMatch = p.name?.toLowerCase().contains(lowerQuery) ?? false;
      final nicknameMatch = p.nickname?.toLowerCase().contains(lowerQuery) ?? false;
      return nameMatch || nicknameMatch;
    }).toList();
  }

  Future<void> clearAllData() async {
    _persons.clear();
    await _saveState();
  }

  Future<Map<String, dynamic>> exportData() async {
    return {
      'persons': _persons.map((p) => p.toJson()).toList(),
      'version': '1.0.0_stub',
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final personsData = data['persons'] as List<dynamic>? ?? [];

    _persons.clear();
    _persons.addAll(
      personsData.map((p) => Person.fromJson(p as Map<String, dynamic>))
    );

    await _saveState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = prefs.getString(_storageKey);

      if (dataJson != null) {
        final data = jsonDecode(dataJson) as Map<String, dynamic>;
        final personsData = data[_personsKey] as List<dynamic>? ?? [];

        _persons.clear();
        _persons.addAll(
          personsData.map((p) => Person.fromJson(p as Map<String, dynamic>))
        );
      }
    } catch (e) {
      logger.error('Failed to load state', error: e);
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        _personsKey: _persons.map((p) => p.toJson()).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      logger.error('Failed to save state', error: e);
    }
  }
}