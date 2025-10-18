import '../database/context_database.dart';
import '../utils/logger.dart';

enum PrivacyLevel {
  paranoid,
  high,
  balanced,
  minimal,
}

class SanitizedPerson {
  final String displayName;
  final String? relationship;
  final bool includeRelationship;

  SanitizedPerson({
    required this.displayName,
    this.relationship,
    this.includeRelationship = false,
  });
}

class SanitizedPlace {
  final String displayName;
  final String? neighborhood;
  final String? city;
  final bool includeNeighborhood;
  final bool includeCity;

  SanitizedPlace({
    required this.displayName,
    this.neighborhood,
    this.city,
    this.includeNeighborhood = false,
    this.includeCity = false,
  });
}

class PrivacySanitizer {
  static final _logger = AppLogger('PrivacySanitizer');
  static final PrivacySanitizer _instance = PrivacySanitizer._internal();
  
  factory PrivacySanitizer() => _instance;
  PrivacySanitizer._internal();

  SanitizedPerson? sanitizePerson(Person person, PrivacyLevel globalLevel) {
    if (person.privacyLevel == 0) {
      _logger.debug('Person ${person.name} excluded (privacy level 0)');
      return null;
    }

    if (person.privacyLevel == 1) {
      return SanitizedPerson(
        displayName: person.firstName,
        relationship: null,
        includeRelationship: false,
      );
    }

    final includeRelationship = _shouldIncludeRelationship(globalLevel);
    
    return SanitizedPerson(
      displayName: includeRelationship 
          ? '${person.firstName} (${person.relationship})'
          : person.firstName,
      relationship: person.relationship,
      includeRelationship: includeRelationship,
    );
  }

  SanitizedPlace? sanitizePlace(Place place, PrivacyLevel globalLevel) {
    if (place.excludeFromJournal) {
      _logger.debug('Place ${place.name} excluded from journal');
      return null;
    }

    if (place.significanceLevel == 0) {
      _logger.debug('Place ${place.name} excluded (significance level 0)');
      return null;
    }

    switch (globalLevel) {
      case PrivacyLevel.paranoid:
        return SanitizedPlace(
          displayName: _getGenericPlaceDescription(place.category),
          includeNeighborhood: false,
          includeCity: false,
        );

      case PrivacyLevel.high:
        return SanitizedPlace(
          displayName: place.name,
          includeNeighborhood: false,
          includeCity: false,
        );

      case PrivacyLevel.balanced:
        return SanitizedPlace(
          displayName: place.name,
          neighborhood: place.neighborhood,
          includeNeighborhood: true,
          includeCity: false,
        );

      case PrivacyLevel.minimal:
        return SanitizedPlace(
          displayName: place.name,
          neighborhood: place.neighborhood,
          city: place.city,
          includeNeighborhood: true,
          includeCity: true,
        );
    }
  }

  List<SanitizedPerson> sanitizePeople(
    List<Person> people,
    PrivacyLevel globalLevel,
  ) {
    final sanitized = <SanitizedPerson>[];
    
    for (final person in people) {
      final result = sanitizePerson(person, globalLevel);
      if (result != null) {
        sanitized.add(result);
      }
    }
    
    return sanitized;
  }

  List<SanitizedPlace> sanitizePlaces(
    List<Place> places,
    PrivacyLevel globalLevel,
  ) {
    final sanitized = <SanitizedPlace>[];
    
    for (final place in places) {
      final result = sanitizePlace(place, globalLevel);
      if (result != null) {
        sanitized.add(result);
      }
    }
    
    return sanitized;
  }

  Map<String, dynamic> sanitizeContextForCloud({
    required List<Person> people,
    required List<Place> places,
    required PrivacyLevel privacyLevel,
    required bool includeRawGPS,
    required bool includeUnknownPeople,
  }) {
    final sanitizedPeople = sanitizePeople(people, privacyLevel);
    final sanitizedPlaces = sanitizePlaces(places, privacyLevel);

    final result = <String, dynamic>{
      'people': sanitizedPeople.map((p) => {
        'name': p.displayName,
        if (p.includeRelationship && p.relationship != null)
          'relationship': p.relationship,
      }).toList(),
      'places': sanitizedPlaces.map((p) => {
        'name': p.displayName,
        if (p.includeNeighborhood && p.neighborhood != null)
          'neighborhood': p.neighborhood,
        if (p.includeCity && p.city != null)
          'city': p.city,
      }).toList(),
      'privacy_level': privacyLevel.name,
      'raw_gps_included': includeRawGPS,
      'unknown_people_included': includeUnknownPeople,
    };

    if (privacyLevel == PrivacyLevel.paranoid) {
      _logger.info('Applied PARANOID privacy level - minimal context shared');
    }

    return result;
  }

  bool shouldIncludeHealthData(PrivacyLevel level) {
    return level == PrivacyLevel.minimal || level == PrivacyLevel.balanced;
  }

  bool shouldIncludeWeatherData(PrivacyLevel level) {
    return level != PrivacyLevel.paranoid;
  }

  bool shouldIncludeUnknownPeople(PrivacyLevel level) {
    return level == PrivacyLevel.minimal;
  }

  bool shouldIncludeRawGPS(PrivacyLevel level) {
    return false;
  }

  int getLocationSpecificity(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.paranoid:
        return 0;
      case PrivacyLevel.high:
        return 1;
      case PrivacyLevel.balanced:
        return 2;
      case PrivacyLevel.minimal:
        return 3;
    }
  }

  bool _shouldIncludeRelationship(PrivacyLevel level) {
    return level == PrivacyLevel.minimal || level == PrivacyLevel.balanced;
  }

  String _getGenericPlaceDescription(String category) {
    final genericDescriptions = {
      'home': 'home',
      'work': 'workplace',
      'restaurant': 'restaurant',
      'park': 'park',
      'gym': 'fitness center',
      'store': 'store',
      'friend_home': "friend's home",
      'cafe': 'cafe',
      'bar': 'bar',
      'library': 'library',
      'hospital': 'medical facility',
      'school': 'educational institution',
      'church': 'place of worship',
      'other': 'location',
    };

    return genericDescriptions[category] ?? 'location';
  }

  String describePrivacyLevel(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.paranoid:
        return 'Maximum privacy - generic descriptions only, no names or specific locations';
      case PrivacyLevel.high:
        return 'High privacy - first names only, place names without neighborhoods';
      case PrivacyLevel.balanced:
        return 'Balanced - first names with relationships, place names with neighborhoods';
      case PrivacyLevel.minimal:
        return 'Minimal privacy - full names with relationships, complete location details';
    }
  }

  PrivacyLevel parsePrivacyLevel(String levelString) {
    switch (levelString.toLowerCase()) {
      case 'paranoid':
      case 'maximum':
        return PrivacyLevel.paranoid;
      case 'high':
        return PrivacyLevel.high;
      case 'balanced':
      case 'medium':
        return PrivacyLevel.balanced;
      case 'minimal':
      case 'low':
        return PrivacyLevel.minimal;
      default:
        _logger.warning('Unknown privacy level: $levelString, defaulting to balanced');
        return PrivacyLevel.balanced;
    }
  }
}
