import '../services/context_manager_service.dart';
import '../services/privacy_sanitizer.dart';
import '../services/daily_context_synthesizer.dart';
import '../utils/logger.dart';

class EnrichedPerson {
  final String displayName;
  final String? relationship;
  final int photoCount;
  
  EnrichedPerson({
    required this.displayName,
    this.relationship,
    this.photoCount = 1,
  });
}

class EnrichedPlace {
  final String name;
  final String? neighborhood;
  final String? city;
  final Duration? timeSpent;
  final int visitCount;
  
  EnrichedPlace({
    required this.name,
    this.neighborhood,
    this.city,
    this.timeSpent,
    this.visitCount = 1,
  });
}

class EnrichedDailyContext {
  final DailyContext originalContext;
  final List<EnrichedPerson> knownPeople;
  final List<EnrichedPlace> knownPlaces;
  final Map<String, String> preferences;
  final List<Occasion> occasionsToday;
  final PrivacyLevel privacyLevel;
  
  EnrichedDailyContext({
    required this.originalContext,
    required this.knownPeople,
    required this.knownPlaces,
    required this.preferences,
    required this.occasionsToday,
    required this.privacyLevel,
  });
}

class ContextEnrichmentService {
  static final _logger = AppLogger('ContextEnrichmentService');
  static final ContextEnrichmentService _instance = ContextEnrichmentService._internal();
  
  factory ContextEnrichmentService() => _instance;
  ContextEnrichmentService._internal();

  final ContextManagerService _contextManager = ContextManagerService();
  final PrivacySanitizer _privacySanitizer = PrivacySanitizer();

  final Map<String, Person> _personCache = {};
  final Map<String, Place> _placeCache = {};

  Future<EnrichedDailyContext> enrichContext(DailyContext context) async {
    try {
      _logger.info('Enriching daily context for ${context.date}');

      final preferences = await _contextManager.getAllPreferences();
      final privacyLevel = _parsePrivacyLevel(preferences['privacy_level'] ?? 'balanced');

      final knownPeople = await _enrichPeople(context);
      final knownPlaces = await _enrichPlaces(context);
      final occasions = await _contextManager.getOccasionsForDate(context.date);

      _logger.info('Enriched context: ${knownPeople.length} people, ${knownPlaces.length} places, ${occasions.length} occasions');

      return EnrichedDailyContext(
        originalContext: context,
        knownPeople: knownPeople,
        knownPlaces: knownPlaces,
        preferences: preferences,
        occasionsToday: occasions,
        privacyLevel: privacyLevel,
      );
    } catch (e, stackTrace) {
      _logger.error('Error enriching context', error: e, stackTrace: stackTrace);
      
      return EnrichedDailyContext(
        originalContext: context,
        knownPeople: [],
        knownPlaces: [],
        preferences: {},
        occasionsToday: [],
        privacyLevel: PrivacyLevel.balanced,
      );
    }
  }

  Future<List<EnrichedPerson>> _enrichPeople(DailyContext context) async {
    final enrichedPeople = <String, EnrichedPerson>{};

    for (final photoContext in context.photoContexts) {
      if (photoContext.faceCount == 0) continue;

      final photoId = photoContext.mediaItem?.id ?? '';
      if (photoId.isEmpty) continue;
      
      final photoLinks = await _contextManager.getPhotoPersonLinks(photoId);
      
      for (final link in photoLinks) {
        final person = await _getCachedPerson(link.personId);
        if (person == null) continue;

        final sanitized = _privacySanitizer.sanitizePerson(
          person,
          PrivacyLevel.balanced,
        );
        
        if (sanitized == null) continue;

        final key = person.id.toString();
        if (enrichedPeople.containsKey(key)) {
          final existing = enrichedPeople[key]!;
          enrichedPeople[key] = EnrichedPerson(
            displayName: existing.displayName,
            relationship: existing.relationship,
            photoCount: existing.photoCount + 1,
          );
        } else {
          enrichedPeople[key] = EnrichedPerson(
            displayName: sanitized.displayName,
            relationship: sanitized.relationship,
            photoCount: 1,
          );
        }
      }
    }

    return enrichedPeople.values.toList();
  }

  Future<List<EnrichedPlace>> _enrichPlaces(DailyContext context) async {
    final enrichedPlaces = <String, EnrichedPlace>{};

    for (final locationPoint in context.locationPoints) {
      final place = await _findPlaceByLocation(
        locationPoint.latitude,
        locationPoint.longitude,
      );
      
      if (place == null) continue;

      final sanitized = _privacySanitizer.sanitizePlace(
        place,
        PrivacyLevel.balanced,
      );
      
      if (sanitized == null) continue;

      final key = place.id.toString();
      if (!enrichedPlaces.containsKey(key)) {
        enrichedPlaces[key] = EnrichedPlace(
          name: sanitized.displayName,
          neighborhood: sanitized.neighborhood,
          city: sanitized.city,
          timeSpent: context.locationSummary.placeTimeSpent[place.name],
          visitCount: 1,
        );
      }
    }

    for (final event in context.calendarEvents) {
      if (event.location == null || event.location!.isEmpty) continue;

      final placeKey = event.location!;
      if (!enrichedPlaces.containsKey(placeKey)) {
        enrichedPlaces[placeKey] = EnrichedPlace(
          name: event.location!,
          timeSpent: event.endDate?.difference(event.startDate),
        );
      }
    }

    return enrichedPlaces.values.toList();
  }

  Future<void> trackActivityPattern({
    required int placeId,
    required DateTime timestamp,
    required String activityType,
  }) async {
    try {
      _logger.debug('Tracked activity pattern: $activityType at place $placeId');
    } catch (e, stackTrace) {
      _logger.error('Error tracking activity pattern', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> detectAndLinkBleDevices({
    required List<String> detectedDeviceIds,
    required DateTime timestamp,
  }) async {
    for (final deviceId in detectedDeviceIds) {
      try {
        await _contextManager.registerBleDevice(
          deviceId: deviceId,
          deviceType: 'unknown',
          deviceName: null,
        );

        final person = await _contextManager.getPersonByBleDevice(deviceId);
        if (person != null) {
          _logger.info('BLE device $deviceId linked to person: ${person.name}');
        }
      } catch (e) {
        _logger.warning('Failed to register BLE device $deviceId: $e');
      }
    }
  }

  Future<List<Occasion>> getUpcomingOccasions({
    int daysAhead = 7,
  }) async {
    final occasions = <Occasion>[];
    final now = DateTime.now();

    for (int i = 0; i <= daysAhead; i++) {
      final date = now.add(Duration(days: i));
      final dayOccasions = await _contextManager.getOccasionsForDate(date);
      occasions.addAll(dayOccasions);
    }

    return occasions;
  }

  Future<Person?> _getCachedPerson(int personId) async {
    final key = personId.toString();
    
    if (_personCache.containsKey(key)) {
      return _personCache[key];
    }

    final person = await _contextManager.getPersonById(personId);
    if (person != null) {
      _personCache[key] = person;
    }
    
    return person;
  }

  Future<Place?> _findPlaceByLocation(double latitude, double longitude) async {
    final key = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    
    if (_placeCache.containsKey(key)) {
      return _placeCache[key];
    }

    final place = await _contextManager.findPlaceByLocation(
      latitude,
      longitude,
      searchRadiusKm: 0.2,
    );
    
    if (place != null) {
      _placeCache[key] = place;
    }
    
    return place;
  }

  void clearCache() {
    _personCache.clear();
    _placeCache.clear();
    _logger.debug('Cleared context enrichment cache');
  }

  PrivacyLevel _parsePrivacyLevel(String level) {
    return _privacySanitizer.parsePrivacyLevel(level);
  }

  Future<Map<String, dynamic>> getEnrichmentStats() async {
    final allPeople = await _contextManager.getAllPeople();
    final allPlaces = await _contextManager.getAllPlaces();
    final preferences = await _contextManager.getAllPreferences();

    return {
      'total_people': allPeople.length,
      'total_places': allPlaces.length,
      'preferences_count': preferences.length,
      'cache_size_people': _personCache.length,
      'cache_size_places': _placeCache.length,
    };
  }
}
