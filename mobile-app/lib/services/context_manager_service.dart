import 'package:drift/drift.dart';
import '../database/context_database.dart';
import '../utils/logger.dart';

class PersonData {
  final int? id;
  final String name;
  final String firstName;
  final String relationship;
  final Uint8List? faceEmbedding;
  final int privacyLevel;
  final String? notes;

  PersonData({
    this.id,
    required this.name,
    required this.firstName,
    required this.relationship,
    this.faceEmbedding,
    this.privacyLevel = 2,
    this.notes,
  });
}

class PlaceData {
  final int? id;
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
  final String? customDescription;
  final bool excludeFromJournal;

  PlaceData({
    this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0,
    this.neighborhood,
    this.city,
    this.state,
    this.country,
    this.significanceLevel = 1,
    this.customDescription,
    this.excludeFromJournal = false,
  });
}

class ContextManagerService {
  static final _logger = AppLogger('ContextManagerService');
  static final ContextManagerService _instance = ContextManagerService._internal();
  
  factory ContextManagerService() => _instance;
  ContextManagerService._internal();

  final ContextDatabase _db = ContextDatabase();

  Future<int> createPerson(PersonData personData) async {
    try {
      final now = DateTime.now();
      final companion = PeopleCompanion.insert(
        name: personData.name,
        firstName: personData.firstName,
        relationship: personData.relationship,
        faceEmbedding: Value(personData.faceEmbedding),
        privacyLevel: Value(personData.privacyLevel),
        firstSeen: now,
        lastSeen: now,
        notes: Value(personData.notes),
      );
      
      final id = await _db.createPerson(companion);
      _logger.info('Created person: ${personData.name} (ID: $id)');
      return id;
    } catch (e, stackTrace) {
      _logger.error('Error creating person', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updatePerson(int id, PersonData personData) async {
    try {
      final existing = await _db.getPersonById(id);
      if (existing == null) {
        throw Exception('Person not found: $id');
      }

      final updated = existing.copyWith(
        name: personData.name,
        firstName: personData.firstName,
        relationship: personData.relationship,
        faceEmbedding: Value(personData.faceEmbedding),
        privacyLevel: personData.privacyLevel,
        notes: Value(personData.notes),
        updatedAt: DateTime.now(),
      );

      await _db.updatePerson(updated);
      _logger.info('Updated person: ${personData.name} (ID: $id)');
    } catch (e, stackTrace) {
      _logger.error('Error updating person', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deletePerson(int id) async {
    try {
      await _db.deletePerson(id);
      _logger.info('Deleted person ID: $id');
    } catch (e, stackTrace) {
      _logger.error('Error deleting person', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Person>> getAllPeople() async {
    try {
      return await _db.getAllPeople();
    } catch (e, stackTrace) {
      _logger.error('Error getting all people', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<Person?> getPersonById(int id) async {
    try {
      return await _db.getPersonById(id);
    } catch (e, stackTrace) {
      _logger.error('Error getting person by ID', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<List<Person>> getPeopleByPrivacyLevel(int minLevel) async {
    try {
      return await _db.getPeopleByPrivacyLevel(minLevel);
    } catch (e, stackTrace) {
      _logger.error('Error getting people by privacy level', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<Person?> findPersonByFaceEmbedding(
    Uint8List faceEmbedding, {
    double confidenceThreshold = 0.7,
  }) async {
    try {
      final people = await _db.getAllPeople();
      
      for (final person in people) {
        if (person.faceEmbedding == null) continue;
        
        final similarity = _calculateCosineSimilarity(
          faceEmbedding,
          person.faceEmbedding!,
        );
        
        if (similarity >= confidenceThreshold) {
          _logger.debug('Found matching person: ${person.name} (similarity: ${similarity.toStringAsFixed(2)})');
          return person;
        }
      }
      
      return null;
    } catch (e, stackTrace) {
      _logger.error('Error finding person by face embedding', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<int> createPlace(PlaceData placeData) async {
    try {
      final now = DateTime.now();
      final companion = PlacesCompanion.insert(
        name: placeData.name,
        category: placeData.category,
        latitude: placeData.latitude,
        longitude: placeData.longitude,
        radiusMeters: Value(placeData.radiusMeters),
        neighborhood: Value(placeData.neighborhood),
        city: Value(placeData.city),
        state: Value(placeData.state),
        country: Value(placeData.country),
        significanceLevel: Value(placeData.significanceLevel),
        firstVisit: now,
        lastVisit: now,
        customDescription: Value(placeData.customDescription),
        excludeFromJournal: Value(placeData.excludeFromJournal),
      );
      
      final id = await _db.createPlace(companion);
      _logger.info('Created place: ${placeData.name} (ID: $id)');
      return id;
    } catch (e, stackTrace) {
      _logger.error('Error creating place', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updatePlace(int id, PlaceData placeData) async {
    try {
      final existing = await _db.getPlaceById(id);
      if (existing == null) {
        throw Exception('Place not found: $id');
      }

      final updated = existing.copyWith(
        name: placeData.name,
        category: placeData.category,
        latitude: placeData.latitude,
        longitude: placeData.longitude,
        radiusMeters: placeData.radiusMeters,
        neighborhood: Value(placeData.neighborhood),
        city: Value(placeData.city),
        state: Value(placeData.state),
        country: Value(placeData.country),
        significanceLevel: placeData.significanceLevel,
        customDescription: Value(placeData.customDescription),
        excludeFromJournal: placeData.excludeFromJournal,
        updatedAt: DateTime.now(),
      );

      await _db.updatePlace(updated);
      _logger.info('Updated place: ${placeData.name} (ID: $id)');
    } catch (e, stackTrace) {
      _logger.error('Error updating place', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deletePlace(int id) async {
    try {
      await _db.deletePlace(id);
      _logger.info('Deleted place ID: $id');
    } catch (e, stackTrace) {
      _logger.error('Error deleting place', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Place>> getAllPlaces() async {
    try {
      return await _db.getAllPlaces();
    } catch (e, stackTrace) {
      _logger.error('Error getting all places', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<Place?> getPlaceById(int id) async {
    try {
      return await _db.getPlaceById(id);
    } catch (e, stackTrace) {
      _logger.error('Error getting place by ID', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<Place?> findPlaceByLocation(
    double latitude,
    double longitude, {
    double searchRadiusKm = 0.5,
  }) async {
    try {
      final nearbyPlaces = await _db.getPlacesNearby(latitude, longitude, searchRadiusKm);
      
      if (nearbyPlaces.isEmpty) {
        return null;
      }
      
      nearbyPlaces.sort((a, b) => (b.significanceLevel).compareTo(a.significanceLevel));
      
      return nearbyPlaces.first;
    } catch (e, stackTrace) {
      _logger.error('Error finding place by location', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<List<Place>> getSignificantPlaces() async {
    try {
      return await _db.getSignificantPlaces();
    } catch (e, stackTrace) {
      _logger.error('Error getting significant places', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> incrementPlaceVisit(int placeId, int durationMinutes) async {
    try {
      final place = await _db.getPlaceById(placeId);
      if (place == null) return;

      final updated = place.copyWith(
        visitCount: place.visitCount + 1,
        lastVisit: DateTime.now(),
        totalTimeMinutes: place.totalTimeMinutes + durationMinutes,
        updatedAt: DateTime.now(),
      );

      await _db.updatePlace(updated);
      _logger.debug('Incremented visit for place: ${place.name}');
    } catch (e, stackTrace) {
      _logger.error('Error incrementing place visit', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> setPreference(String key, String value) async {
    try {
      await _db.setPreference(key, value);
      _logger.debug('Set preference: $key = $value');
    } catch (e, stackTrace) {
      _logger.error('Error setting preference', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<String?> getPreference(String key) async {
    try {
      return await _db.getPreference(key);
    } catch (e, stackTrace) {
      _logger.error('Error getting preference', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<Map<String, String>> getAllPreferences() async {
    try {
      return await _db.getAllPreferences();
    } catch (e, stackTrace) {
      _logger.error('Error getting all preferences', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  Future<void> linkPhotoToPerson(
    String photoId,
    int personId,
    double confidence,
    int faceIndex,
  ) async {
    try {
      final companion = PhotoPersonLinksCompanion.insert(
        photoId: photoId,
        personId: personId,
        confidence: confidence,
        faceIndex: faceIndex,
      );
      
      await _db.createPhotoPersonLink(companion);
      
      final person = await _db.getPersonById(personId);
      if (person != null) {
        final updated = person.copyWith(
          photoCount: person.photoCount + 1,
          lastSeen: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _db.updatePerson(updated);
      }
      
      _logger.debug('Linked photo $photoId to person $personId (confidence: $confidence)');
    } catch (e, stackTrace) {
      _logger.error('Error linking photo to person', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<PhotoPersonLink>> getPhotoPersonLinks(String photoId) async {
    try {
      return await _db.getPhotoPersonLinks(photoId);
    } catch (e, stackTrace) {
      _logger.error('Error getting photo person links', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Person>> getPeopleInPhoto(String photoId) async {
    try {
      final links = await _db.getPhotoPersonLinks(photoId);
      final people = <Person>[];
      
      for (final link in links) {
        final person = await _db.getPersonById(link.personId);
        if (person != null) {
          people.add(person);
        }
      }
      
      return people;
    } catch (e, stackTrace) {
      _logger.error('Error getting people in photo', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<int> createOccasion({
    required String name,
    required DateTime date,
    int? personId,
    required String occasionType,
    bool recurring = true,
    String? notes,
  }) async {
    try {
      final companion = OccasionsCompanion.insert(
        name: name,
        date: date,
        personId: Value(personId),
        occasionType: occasionType,
        recurring: Value(recurring),
        notes: Value(notes),
      );
      
      final id = await _db.createOccasion(companion);
      _logger.info('Created occasion: $name (ID: $id)');
      return id;
    } catch (e, stackTrace) {
      _logger.error('Error creating occasion', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Occasion>> getOccasionsForDate(DateTime date) async {
    try {
      return await _db.getOccasionsForDate(date);
    } catch (e, stackTrace) {
      _logger.error('Error getting occasions for date', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> registerBleDevice({
    required String deviceId,
    int? personId,
    required String deviceType,
    String? deviceName,
  }) async {
    try {
      final existing = await _db.getBleDeviceByDeviceId(deviceId);
      final now = DateTime.now();
      
      if (existing == null) {
        final companion = BleDeviceRegistriesCompanion.insert(
          deviceId: deviceId,
          personId: Value(personId),
          deviceType: deviceType,
          deviceName: Value(deviceName),
          firstSeen: now,
          lastSeen: now,
        );
        await _db.createBleDevice(companion);
        _logger.info('Registered new BLE device: $deviceId');
      } else {
        final updated = existing.copyWith(
          personId: Value(personId),
          deviceType: deviceType,
          deviceName: Value(deviceName),
          lastSeen: now,
          encounterCount: existing.encounterCount + 1,
        );
        await _db.updateBleDevice(updated);
        _logger.debug('Updated BLE device: $deviceId (encounters: ${updated.encounterCount})');
      }
    } catch (e, stackTrace) {
      _logger.error('Error registering BLE device', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Person?> getPersonByBleDevice(String deviceId) async {
    try {
      final device = await _db.getBleDeviceByDeviceId(deviceId);
      if (device?.personId == null) return null;
      
      return await _db.getPersonById(device!.personId!);
    } catch (e, stackTrace) {
      _logger.error('Error getting person by BLE device', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  double _calculateCosineSimilarity(Uint8List embedding1, Uint8List embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same length');
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      final val1 = embedding1[i] / 255.0;
      final val2 = embedding2[i] / 255.0;
      
      dotProduct += val1 * val2;
      norm1 += val1 * val1;
      norm2 += val2 * val2;
    }

    if (norm1 == 0.0 || norm2 == 0.0) {
      return 0.0;
    }

    return dotProduct / (norm1.sqrt() * norm2.sqrt());
  }

  Future<void> dispose() async {
  }
}

extension on double {
  double sqrt() {
    return _sqrt(this);
  }
  
  static double _sqrt(double value) {
    if (value < 0) return 0.0;
    if (value == 0) return 0.0;
    
    double x = value;
    double lastX = 0;
    
    while ((x - lastX).abs() > 0.000001) {
      lastX = x;
      x = (x + value / x) / 2;
    }
    
    return x;
  }
}
