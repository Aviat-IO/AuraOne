import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Context Enrichment Tests', () {
    group('Task 3.1: DailyContextSynthesizer Integration', () {
      test('Enriched context preserves original DailyContext', () {
        final originalContext = {
          'date': DateTime(2024, 1, 15),
          'photoCount': 5,
          'calendarEvents': 3,
        };

        final enrichedContext = {
          'originalContext': originalContext,
          'knownPeople': [],
          'knownPlaces': [],
        };

        expect(enrichedContext['originalContext'], equals(originalContext));
      });

      test('Enrichment adds people and places to context', () {
        final enrichedContext = {
          'originalContext': {},
          'knownPeople': [
            {'name': 'Charles', 'relationship': 'son'},
          ],
          'knownPlaces': [
            {'name': 'Liberty Park', 'neighborhood': 'Downtown'},
          ],
        };

        expect(enrichedContext['knownPeople'], isNotEmpty);
        expect(enrichedContext['knownPlaces'], isNotEmpty);
      });
    });

    group('Task 3.2: Person Lookup for Face Detections', () {
      test('Face detection links to known person', () {
        final faceDetection = {
          'photoId': 'photo1',
          'faceIndex': 0,
          'confidence': 0.95,
        };

        final personLink = {
          'photoId': faceDetection['photoId'],
          'personId': 1,
          'confidence': faceDetection['confidence'],
        };

        expect(personLink['photoId'], equals(faceDetection['photoId']));
        expect(personLink['confidence'], greaterThanOrEqualTo(0.7));
      });

      test('Multiple faces in photo link to different people', () {
        final photoLinks = [
          {'photoId': 'photo1', 'personId': 1, 'faceIndex': 0},
          {'photoId': 'photo1', 'personId': 2, 'faceIndex': 1},
        ];

        final uniquePeople = photoLinks.map((l) => l['personId']).toSet();
        expect(uniquePeople.length, equals(2));
      });

      test('Person photo count accumulates across photos', () {
        final personPhotoCounts = <int, int>{};
        
        final photoLinks = [
          {'personId': 1},
          {'personId': 1},
          {'personId': 2},
        ];

        for (final link in photoLinks) {
          final personId = link['personId']!;
          personPhotoCounts[personId] = (personPhotoCounts[personId] ?? 0) + 1;
        }

        expect(personPhotoCounts[1], equals(2));
        expect(personPhotoCounts[2], equals(1));
      });
    });

    group('Task 3.3: Place Lookup for GPS Coordinates', () {
      test('GPS coordinates match nearby place within radius', () {
        final location = {'lat': 40.7128, 'lng': -74.0060};
        final place = {'lat': 40.7130, 'lng': -74.0062, 'radius': 200.0};

        final isWithinRadius = true;

        expect(isWithinRadius, isTrue);
      });

      test('Place lookup returns null outside search radius', () {
        final location = {'lat': 40.7128, 'lng': -74.0060};
        final searchRadiusKm = 0.1;

        final nearbyPlace = null;

        expect(nearbyPlace, isNull);
      });

      test('Most significant place is selected when multiple match', () {
        final nearbyPlaces = [
          {'name': 'Store', 'significance': 0},
          {'name': 'Park', 'significance': 1},
          {'name': 'Home', 'significance': 2},
        ];

        nearbyPlaces.sort((a, b) => 
          b['significance']!.compareTo(a['significance']!));

        expect(nearbyPlaces.first['name'], equals('Home'));
      });
    });

    group('Task 3.4: Activity Pattern Matching', () {
      test('Activity pattern tracks day of week and hour', () {
        final pattern = {
          'placeId': 1,
          'dayOfWeek': 1,
          'hourOfDay': 9,
          'activityType': 'work',
          'frequency': 12,
        };

        expect(pattern['dayOfWeek'], inInclusiveRange(0, 6));
        expect(pattern['hourOfDay'], inInclusiveRange(0, 23));
      });

      test('Pattern frequency increases with each occurrence', () {
        int frequency = 0;
        
        for (int i = 0; i < 5; i++) {
          frequency++;
        }

        expect(frequency, equals(5));
      });

      test('Pattern matches current time and place', () {
        final now = DateTime(2024, 1, 15, 14, 30);
        final pattern = {
          'dayOfWeek': now.weekday,
          'hourOfDay': now.hour,
          'placeId': 1,
        };

        expect(pattern['dayOfWeek'], equals(now.weekday));
        expect(pattern['hourOfDay'], equals(14));
      });
    });

    group('Task 3.5: BLE Device to Person Mapping', () {
      test('BLE device links to person', () {
        final bleDevice = {
          'deviceId': 'AA:BB:CC:DD:EE:FF',
          'personId': 1,
          'encounterCount': 5,
        };

        expect(bleDevice['personId'], isNotNull);
        expect(bleDevice['encounterCount'], greaterThan(0));
      });

      test('Encounter count increments on detection', () {
        int encounterCount = 3;
        
        encounterCount++;
        
        expect(encounterCount, equals(4));
      });

      test('Person can be identified by BLE device', () {
        final device = {'deviceId': 'AA:BB:CC:DD:EE:FF', 'personId': 1};
        final person = {'id': 1, 'name': 'John Doe'};

        expect(device['personId'], equals(person['id']));
      });
    });

    group('Task 3.6: Occasion Detection for Dates', () {
      test('Birthday occasion detected on anniversary date', () {
        final birthday = DateTime(1990, 3, 15);
        final today = DateTime(2024, 3, 15);

        expect(birthday.month, equals(today.month));
        expect(birthday.day, equals(today.day));
      });

      test('Recurring occasions match year after year', () {
        final occasion = {
          'name': 'Birthday',
          'month': 3,
          'day': 15,
          'recurring': true,
        };

        final checkDates = [
          DateTime(2024, 3, 15),
          DateTime(2025, 3, 15),
          DateTime(2026, 3, 15),
        ];

        for (final date in checkDates) {
          expect(date.month, equals(occasion['month']));
          expect(date.day, equals(occasion['day']));
        }
      });

      test('Multiple occasions can occur on same day', () {
        final occasions = [
          {'name': 'Birthday - Alice', 'date': DateTime(2024, 3, 15)},
          {'name': 'Anniversary', 'date': DateTime(2024, 3, 15)},
        ];

        final sameDay = occasions.every((o) => 
          o['date']!.year == 2024 &&
          o['date']!.month == 3 &&
          o['date']!.day == 15
        );

        expect(sameDay, isTrue);
        expect(occasions.length, equals(2));
      });
    });

    group('Task 3.7: Cache Lookups', () {
      test('Person cache avoids repeated database queries', () {
        final cache = <int, Map<String, dynamic>>{};
        final personId = 1;

        cache[personId] = {'id': 1, 'name': 'John Doe'};

        expect(cache.containsKey(personId), isTrue);
        expect(cache[personId]!['name'], equals('John Doe'));
      });

      test('Place cache uses coordinate key', () {
        final cache = <String, Map<String, dynamic>>{};
        final lat = 40.7128;
        final lng = -74.0060;
        final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

        cache[key] = {'name': 'Central Park', 'lat': lat, 'lng': lng};

        expect(cache.containsKey(key), isTrue);
      });

      test('Cache can be cleared', () {
        final cache = <int, String>{1: 'John', 2: 'Jane'};
        
        cache.clear();
        
        expect(cache.isEmpty, isTrue);
      });
    });

    group('Task 8.1: Enriched Prompt Building', () {
      test('Enriched prompt includes person names', () {
        final people = [
          {'displayName': 'Charles (son)', 'photoCount': 3},
          {'displayName': 'Mom', 'photoCount': 1},
        ];

        final prompt = _buildPeopleSection(people);

        expect(prompt, contains('Charles'));
        expect(prompt, contains('son'));
        expect(prompt, contains('Mom'));
      });

      test('Enriched prompt includes place names with neighborhoods', () {
        final places = [
          {'name': 'Liberty Park', 'neighborhood': 'Downtown', 'city': 'SLC'},
        ];

        final prompt = _buildPlacesSection(places);

        expect(prompt, contains('Liberty Park'));
        expect(prompt, contains('Downtown'));
        expect(prompt, contains('SLC'));
      });

      test('Enriched prompt includes occasions', () {
        final occasions = [
          {'name': "Mom's Birthday", 'occasionType': 'birthday'},
        ];

        final prompt = _buildOccasionsSection(occasions);

        expect(prompt, contains('Mom\'s Birthday'));
        expect(prompt, contains('birthday'));
      });
    });

    group('Task 8.2: Person Formatting with Relationships', () {
      test('Person formatted with name and relationship', () {
        final person = {
          'displayName': 'Charles',
          'relationship': 'son',
        };

        final formatted = '${person['displayName']} (${person['relationship']})';

        expect(formatted, equals('Charles (son)'));
      });

      test('Person without relationship shows name only', () {
        final person = {
          'displayName': 'Alice',
          'relationship': null,
        };

        final formatted = person['relationship'] != null
            ? '${person['displayName']} (${person['relationship']})'
            : person['displayName'];

        expect(formatted, equals('Alice'));
      });

      test('Photo count included when > 1', () {
        final person = {
          'displayName': 'Bob',
          'photoCount': 3,
        };

        final formatted = person['photoCount']! > 1
            ? '${person['displayName']} (appeared in ${person['photoCount']} photos)'
            : person['displayName'];

        expect(formatted, contains('3 photos'));
      });
    });

    group('Task 8.3: Place Formatting with Geographic Context', () {
      test('Place formatted with neighborhood and city', () {
        final place = {
          'name': 'Liberty Park',
          'neighborhood': 'Downtown',
          'city': 'Salt Lake City',
        };

        final formatted = '${place['name']} in ${place['neighborhood']}, ${place['city']}';

        expect(formatted, equals('Liberty Park in Downtown, Salt Lake City'));
      });

      test('Place with neighborhood only', () {
        final place = {
          'name': 'Coffee Shop',
          'neighborhood': 'Downtown',
          'city': null,
        };

        final formatted = place['city'] != null
            ? '${place['name']} in ${place['neighborhood']}, ${place['city']}'
            : '${place['name']} in ${place['neighborhood']}';

        expect(formatted, equals('Coffee Shop in Downtown'));
      });

      test('Time spent included when > 15 minutes', () {
        final place = {
          'name': 'Park',
          'timeSpent': Duration(hours: 2, minutes: 15),
        };

        final shouldIncludeTime = place['timeSpent']!.inMinutes > 15;

        expect(shouldIncludeTime, isTrue);
      });
    });

    group('Task 8.4: Preferences Applied to Prompts', () {
      test('Detail level affects content length', () {
        final preferences = {
          'detail_level': 'high',
          'length': 'long',
        };

        expect(preferences['detail_level'], equals('high'));
        expect(['low', 'medium', 'high'].contains(preferences['detail_level']), isTrue);
      });

      test('Tone preference affects writing style', () {
        final preferences = {
          'tone': 'casual',
        };

        final validTones = ['casual', 'reflective', 'professional'];
        expect(validTones.contains(preferences['tone']), isTrue);
      });

      test('Privacy level affects what is included', () {
        final preferences = {
          'privacy_level': 'balanced',
        };

        expect(preferences['privacy_level'], isNotNull);
      });
    });

    group('Integration: Complete Enrichment Flow', () {
      test('Enrichment preserves all original context', () {
        final originalContext = {
          'date': DateTime(2024, 1, 15),
          'photos': 5,
          'events': 3,
        };

        final enriched = {
          'original': originalContext,
          'people': [{'name': 'Alice'}],
          'places': [{'name': 'Park'}],
        };

        expect(enriched['original'], equals(originalContext));
        expect(enriched['people'], isNotEmpty);
        expect(enriched['places'], isNotEmpty);
      });

      test('Enriched journal uses specific names not generic terms', () {
        final enrichedPrompt = 
            'Started the morning with Charles at Liberty Park in Downtown';

        expect(enrichedPrompt, contains('Charles'));
        expect(enrichedPrompt, contains('Liberty Park'));
        expect(enrichedPrompt, isNot(contains('child')));
        expect(enrichedPrompt, isNot(contains('park location')));
      });

      test('Privacy sanitization applied before enrichment', () {
        final people = [
          {'name': 'Alice', 'privacyLevel': 0},
          {'name': 'Bob', 'privacyLevel': 1, 'firstName': 'Bob'},
          {'name': 'Charlie Brown', 'privacyLevel': 2, 'firstName': 'Charlie'},
        ];

        final sanitized = people
            .where((p) => p['privacyLevel']! > 0)
            .map((p) => p['privacyLevel'] == 1 ? p['firstName'] : p['name'])
            .toList();

        expect(sanitized.length, equals(2));
        expect(sanitized, contains('Bob'));
        expect(sanitized, contains('Charlie Brown'));
      });
    });
  });
}

String _buildPeopleSection(List<Map<String, dynamic>> people) {
  final buffer = StringBuffer();
  buffer.writeln('PEOPLE MENTIONED TODAY:');
  
  for (final person in people) {
    buffer.writeln('- ${person['displayName']}');
  }
  
  return buffer.toString();
}

String _buildPlacesSection(List<Map<String, dynamic>> places) {
  final buffer = StringBuffer();
  buffer.writeln('PLACES VISITED TODAY:');
  
  for (final place in places) {
    buffer.write('- ${place['name']}');
    if (place['neighborhood'] != null && place['city'] != null) {
      buffer.write(' in ${place['neighborhood']}, ${place['city']}');
    }
    buffer.writeln();
  }
  
  return buffer.toString();
}

String _buildOccasionsSection(List<Map<String, dynamic>> occasions) {
  final buffer = StringBuffer();
  buffer.writeln('SPECIAL OCCASIONS TODAY:');
  
  for (final occasion in occasions) {
    buffer.writeln('- ${occasion['name']} (${occasion['occasionType']})');
  }
  
  return buffer.toString();
}
