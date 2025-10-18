# Testing Context Enrichment on Device

## Overview

The context enrichment system is now ready to test. Since we haven't built UI
screens yet, you'll need to test programmatically by adding test data and
observing the enriched journal output.

---

## 🚀 Quick Start: 3-Step Testing

### Step 1: Deploy to Device

```bash
cd mobile-app
fvm flutter run --debug
```

### Step 2: Add Test Data (Via Dart Console or Script)

Create a temporary test file to populate the database:

```bash
# Create test script
cat > lib/test_context_data.dart << 'EOF'
import 'services/context_manager_service.dart';
import 'services/privacy_sanitizer.dart';
import 'dart:typed_data';

Future<void> seedTestData() async {
  final contextManager = ContextManagerService();
  
  // Add a person (your friend/family member)
  final person = await contextManager.addPerson(
    name: 'Sarah Johnson',
    firstName: 'Sarah',
    relationship: 'friend',
    faceEmbedding: null, // Can add later when you have face data
    privacyLevel: PrivacyLevel.balanced,
  );
  
  print('✅ Added person: Sarah (ID: ${person.id})');
  
  // Add a place you frequently visit
  final place = await contextManager.addPlace(
    customName: 'Liberty Park',
    latitude: 40.7489,
    longitude: -111.8743,
    radiusMeters: 150.0,
    category: 'park',
    neighborhood: 'Downtown',
    city: 'Salt Lake City',
    significanceLevel: 2,
  );
  
  print('✅ Added place: Liberty Park (ID: ${place.id})');
  
  // Add an occasion
  final occasion = await contextManager.addOccasion(
    title: "Sarah's Birthday",
    occasionType: 'birthday',
    date: DateTime(2025, 5, 15),
    linkedPersonId: person.id,
    isRecurring: true,
  );
  
  print('✅ Added occasion: Sarah\'s Birthday');
  
  // Add a journal preference
  await contextManager.setPreference('tone', 'casual');
  await contextManager.setPreference('detail_level', 'high');
  
  print('✅ Set journal preferences');
  print('\n🎉 Test data seeded successfully!');
}
EOF
```

### Step 3: Test Journal Generation

Add a test button to your app or run this in a screen's `initState`:

```dart
import 'package:flutter/material.dart';
import '../services/daily_context_synthesizer.dart';
import '../services/ai/enriched_journal_generator.dart';
import '../database/media_database.dart';
import '../database/location_database.dart';

class TestEnrichmentButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final synthesizer = DailyContextSynthesizer();
        final generator = EnrichedJournalGenerator();
        
        // Generate context for today
        final dailyContext = await synthesizer.synthesizeDailyContext(
          date: DateTime.now(),
          mediaDatabase: MediaDatabase(),
          locationDatabase: LocationDatabase(),
          activities: [],
          enabledCalendarIds: {},
        );
        
        // Generate enriched journal
        final result = await generator.generateEnrichedJournal(dailyContext);
        
        if (result.success) {
          print('✅ ENRICHED JOURNAL:\n${result.text}');
          
          // Show in dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Enriched Journal'),
              content: SingleChildScrollView(
                child: Text(result.text ?? 'No text generated'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          );
        } else {
          print('❌ Error: ${result.error}');
        }
      },
      child: Text('Test Enriched Journal'),
    );
  }
}
```

---

## 📊 Testing Scenarios

### Scenario 1: Test Person Recognition

**Goal:** Verify that known people are mentioned by name in journals

1. Add a person to the database
2. Take a photo with that person (or use existing photo)
3. Link the photo to the person using `addPhotoPersonLink()`
4. Generate journal - should say "Sarah" instead of "person"

```dart
// Link photo to person
await contextManager.addPhotoPersonLink(
  photoId: 'photo_xyz_123',
  personId: sarahId,
  faceIndex: 0,
  confidence: 0.95,
  boundingBox: null,
);

// Now generate journal - should mention "Sarah"
```

### Scenario 2: Test Place Names

**Goal:** Verify custom place names appear instead of GPS coordinates

1. Add a place with custom name
2. Visit that location (or add location data)
3. Generate journal - should say "Liberty Park" instead of "a park"

```dart
// Add place
final park = await contextManager.addPlace(
  customName: 'My Favorite Coffee Shop',
  latitude: 40.7128,
  longitude: -74.0060,
  radiusMeters: 50.0,
  category: 'cafe',
  neighborhood: 'Greenwich Village',
  city: 'New York',
);

// Journal should now say "My Favorite Coffee Shop in Greenwich Village"
```

### Scenario 3: Test Privacy Levels

**Goal:** Verify privacy controls work correctly

```dart
// Test all 4 privacy levels
final privacyTests = [
  PrivacyLevel.paranoid,  // Should see: "person", "park" (generic)
  PrivacyLevel.high,      // Should see: "Sarah", "Liberty Park" (names only)
  PrivacyLevel.balanced,  // Should see: "Sarah (friend)", "Liberty Park in Downtown"
  PrivacyLevel.minimal,   // Should see: "Sarah Johnson (friend)", full details
];

for (final level in privacyTests) {
  // Update person's privacy
  await contextManager.updatePersonPrivacy(sarahId, level);
  
  // Generate journal
  final result = await generator.generateEnrichedJournal(context);
  
  print('Privacy Level: $level');
  print('Journal: ${result.text}\n');
}
```

### Scenario 4: Test Special Occasions

**Goal:** Verify birthdays/anniversaries are mentioned

1. Add an occasion (birthday on today's date)
2. Generate journal - should mention "Sarah's Birthday"

```dart
// Add birthday for today
await contextManager.addOccasion(
  title: "Sarah's Birthday",
  occasionType: 'birthday',
  date: DateTime.now(),
  linkedPersonId: sarahId,
  isRecurring: true,
);

// Journal should say: "Celebrated Sarah's Birthday today..."
```

### Scenario 5: Test Activity Patterns

**Goal:** Verify behavioral learning

```dart
// Track visits to a place
for (int i = 0; i < 5; i++) {
  await contextManager.incrementPlaceVisitCount(parkId);
}

// Add activity pattern (e.g., go to park on weekends at 9 AM)
await contextManager.addActivityPattern(
  placeId: parkId,
  dayOfWeek: 6, // Saturday
  hourOfDay: 9,
  activityType: 'recreation',
  frequency: 5,
);

// Journal should recognize pattern: "Your usual Saturday morning visit to Liberty Park"
```

---

## 🔍 Testing Without UI: Database Inspection

### Option A: Use Flutter DevTools

1. Run app: `fvm flutter run --debug`
2. Open DevTools in browser
3. Go to "App Inspection" → "Database Inspector"
4. Query tables directly:

```sql
SELECT * FROM people;
SELECT * FROM places;
SELECT * FROM photo_person_links;
SELECT * FROM occasions;
```

### Option B: Add Debug Screen

Create a temporary debug screen to view/add data:

```dart
import 'package:flutter/material.dart';
import '../services/context_manager_service.dart';

class ContextDebugScreen extends StatefulWidget {
  @override
  _ContextDebugScreenState createState() => _ContextDebugScreenState();
}

class _ContextDebugScreenState extends State<ContextDebugScreen> {
  final _contextManager = ContextManagerService();
  List<Person> _people = [];
  List<Place> _places = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final people = await _contextManager.getAllPeople();
    final places = await _contextManager.getAllPlaces();
    setState(() {
      _people = people;
      _places = places;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Context Database Debug')),
      body: ListView(
        children: [
          ListTile(
            title: Text('People (${_people.length})', 
                       style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._people.map((p) => ListTile(
            title: Text(p.name),
            subtitle: Text('${p.relationship} • Privacy: ${p.privacyLevel}'),
            trailing: Text('ID: ${p.id}'),
          )),
          Divider(),
          ListTile(
            title: Text('Places (${_places.length})', 
                       style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._places.map((p) => ListTile(
            title: Text(p.customName),
            subtitle: Text('${p.neighborhood ?? ''} ${p.city ?? ''}'),
            trailing: Text('Visits: ${p.visitCount}'),
          )),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _loadData,
              child: Text('Refresh'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await seedTestData(); // From test_context_data.dart
          _loadData();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

## 📝 Expected Results

### Before Enrichment (Generic)

```
You spent time at a park. You took photos with 2 people. 
You traveled 5.2km today.
```

### After Enrichment (Personalized)

```
Started the morning with Sarah (friend) and Emily (daughter) at 
Liberty Park in Downtown. Spent 2 hours enjoying the sunshine. 
This is your 5th visit here - seems like a favorite spot!
```

---

## 🐛 Debugging Tips

### Check Logs

```dart
// Enable verbose logging
import '../utils/logger.dart';

AppLogger.setLogLevel(LogLevel.debug);

// Watch for these logs:
// ✅ "Generating enriched journal with X people, Y places"
// ✅ "Enriched context with 2 known people"
// ✅ "Found nearby place: Liberty Park"
```

### Verify Database State

```dart
// Add this to your test button
final stats = await _contextManager.getDatabaseStats();
print('📊 Database Stats:');
print('  People: ${stats['peopleCount']}');
print('  Places: ${stats['placesCount']}');
print('  Photo Links: ${stats['photoLinksCount']}');
print('  Occasions: ${stats['occasionsCount']}');
```

### Test Cache

```dart
// The enrichment service uses in-memory cache
// Test that it's working:

final service = ContextEnrichmentService();

// First call - hits database
final start1 = DateTime.now();
final result1 = await service.enrichContext(context);
final duration1 = DateTime.now().difference(start1);

// Second call - uses cache
final start2 = DateTime.now();
final result2 = await service.enrichContext(context);
final duration2 = DateTime.now().difference(start2);

print('First call: ${duration1.inMilliseconds}ms');
print('Cached call: ${duration2.inMilliseconds}ms');
// Cached should be significantly faster
```

---

## 🎯 Success Criteria

Your enrichment is working if:

1. ✅ Journal mentions people by name ("Sarah") not generic ("person")
2. ✅ Journal uses custom place names ("Liberty Park") not generic ("park")
3. ✅ Geographic context included ("in Downtown, Salt Lake City")
4. ✅ Special occasions mentioned ("Today is Sarah's Birthday!")
5. ✅ Privacy levels respected (test all 4 levels)
6. ✅ No raw GPS coordinates in journal text
7. ✅ Cache improves performance on repeated calls

---

## 🚨 Common Issues

### Issue 1: "No people found"

**Cause:** No photo-person links created\
**Fix:** Run `addPhotoPersonLink()` to associate photos with people

### Issue 2: "Generic place names still appearing"

**Cause:** GPS coordinates outside place radius\
**Fix:** Increase `radiusMeters` when adding place, or check coordinates match

### Issue 3: "Cloud adapter not available"

**Cause:** Missing Gemini API key\
**Fix:** Check `.env` file has `GEMINI_API_KEY=your_key_here`

### Issue 4: "Empty enriched context"

**Cause:** No matching people/places for today's data\
**Fix:** Add test data for the same date you're testing

---

## 📱 Recommended Testing Flow

1. **Start Simple**
   - Add 1 person
   - Add 1 place
   - Generate journal
   - Verify names appear

2. **Add Complexity**
   - Add photo-person link
   - Add occasion
   - Test privacy levels
   - Verify occasion appears

3. **Test Edge Cases**
   - Person with privacy level 0 (should be excluded)
   - Place outside radius (should not match)
   - Multiple people in one photo
   - Same person in multiple photos (count should accumulate)

4. **Performance Test**
   - Add 10+ people
   - Add 20+ places
   - Verify cache speeds up lookups
   - Check memory usage

---

## 🎉 Next Steps After Testing

Once you've verified enrichment works:

1. **Integrate into existing journal flow**
   - Replace generic generator with EnrichedJournalGenerator
   - Update UI to show enriched output

2. **Build UI screens** (Optional)
   - Person labeling screen
   - Place naming screen
   - Preferences screen

3. **Add face clustering** (Phase 3)
   - Automatic person detection from faces
   - ML Kit face detection integration

---

## 📞 Need Help?

If you encounter issues:

1. Check logs: `AppLogger.setLogLevel(LogLevel.debug)`
2. Verify database: Query tables directly
3. Test services individually: Run unit tests
4. Check privacy settings: Ensure not at paranoid level when testing

The system is fully functional - just needs data and integration into your
existing UI!
