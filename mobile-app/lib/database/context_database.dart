import 'dart:io';
import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'context_database.g.dart';

@DataClassName('Person')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get firstName => text()();
  TextColumn get relationship => text()();
  BlobColumn get faceEmbedding => blob().nullable()();
  IntColumn get privacyLevel => integer().withDefault(const Constant(2))();
  DateTimeColumn get firstSeen => dateTime()();
  DateTimeColumn get lastSeen => dateTime()();
  IntColumn get photoCount => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Place')
class Places extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radiusMeters => real().withDefault(const Constant(100.0))();
  TextColumn get neighborhood => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get country => text().nullable()();
  IntColumn get significanceLevel => integer().withDefault(const Constant(1))();
  IntColumn get visitCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get firstVisit => dateTime()();
  DateTimeColumn get lastVisit => dateTime()();
  IntColumn get totalTimeMinutes => integer().withDefault(const Constant(0))();
  TextColumn get customDescription => text().nullable()();
  BoolColumn get excludeFromJournal => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ActivityPattern')
class ActivityPatterns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get placeId => integer().nullable().references(Places, #id)();
  IntColumn get dayOfWeek => integer()();
  IntColumn get hourOfDay => integer()();
  TextColumn get activityType => text()();
  IntColumn get frequency => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastOccurrence => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('JournalPreference')
class JournalPreferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('BleDeviceRegistry')
class BleDeviceRegistries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().unique()();
  IntColumn get personId => integer().nullable().references(People, #id)();
  TextColumn get deviceType => text()();
  TextColumn get deviceName => text().nullable()();
  DateTimeColumn get firstSeen => dateTime()();
  DateTimeColumn get lastSeen => dateTime()();
  IntColumn get encounterCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Occasion')
class Occasions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get personId => integer().nullable().references(People, #id)();
  TextColumn get occasionType => text()();
  BoolColumn get recurring => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PhotoPersonLink')
class PhotoPersonLinks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get photoId => text()();
  IntColumn get personId => integer().references(People, #id)();
  RealColumn get confidence => real()();
  IntColumn get faceIndex => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  People,
  Places,
  ActivityPatterns,
  JournalPreferences,
  BleDeviceRegistries,
  Occasions,
  PhotoPersonLinks,
])
class ContextDatabase extends _$ContextDatabase {
  ContextDatabase() : super(_openConnection());

  ContextDatabase.withConnection({required QueryExecutor openConnection})
      : super(openConnection);

  int get schemaVersion => 1;

  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
        },
      );

  Future<List<Person>> getAllPeople() {
    return select(people).get();
  }

  Future<Person?> getPersonById(int id) {
    return (select(people)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<List<Person>> getPeopleByPrivacyLevel(int minLevel) {
    return (select(people)..where((tbl) => tbl.privacyLevel.isBiggerOrEqualValue(minLevel))).get();
  }

  Future<int> createPerson(PeopleCompanion person) {
    return into(people).insert(person);
  }

  Future<bool> updatePerson(Person person) {
    return update(people).replace(person);
  }

  Future<int> deletePerson(int id) {
    return (delete(people)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<Place>> getAllPlaces() {
    return select(places).get();
  }

  Future<Place?> getPlaceById(int id) {
    return (select(places)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<List<Place>> getPlacesNearby(double lat, double lng, double radiusKm) async {
    final allPlaces = await select(places).get();
    
    return allPlaces.where((place) {
      final distance = _calculateDistance(lat, lng, place.latitude, place.longitude);
      return distance <= radiusKm * 1000;
    }).toList();
  }

  Future<List<Place>> getSignificantPlaces() {
    return (select(places)
          ..where((tbl) => tbl.significanceLevel.isBiggerOrEqualValue(1))
          ..where((tbl) => tbl.excludeFromJournal.equals(false))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.visitCount)]))
        .get();
  }

  Future<int> createPlace(PlacesCompanion place) {
    return into(places).insert(place);
  }

  Future<bool> updatePlace(Place place) {
    return update(places).replace(place);
  }

  Future<int> deletePlace(int id) {
    return (delete(places)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<ActivityPattern>> getActivityPatternsForPlace(int placeId) {
    return (select(activityPatterns)..where((tbl) => tbl.placeId.equals(placeId))).get();
  }

  Future<List<ActivityPattern>> getActivityPatternsForTime(int dayOfWeek, int hourOfDay) {
    return (select(activityPatterns)
          ..where((tbl) => tbl.dayOfWeek.equals(dayOfWeek) & tbl.hourOfDay.equals(hourOfDay)))
        .get();
  }

  Future<int> createActivityPattern(ActivityPatternsCompanion pattern) {
    return into(activityPatterns).insert(pattern);
  }

  Future<String?> getPreference(String key) async {
    final result = await (select(journalPreferences)
          ..where((tbl) => tbl.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setPreference(String key, String value) async {
    await into(journalPreferences).insert(
      JournalPreferencesCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<Map<String, String>> getAllPreferences() async {
    final prefs = await select(journalPreferences).get();
    return {for (var pref in prefs) pref.key: pref.value};
  }

  Future<BleDeviceRegistry?> getBleDeviceByDeviceId(String deviceId) {
    return (select(bleDeviceRegistries)..where((tbl) => tbl.deviceId.equals(deviceId)))
        .getSingleOrNull();
  }

  Future<List<BleDeviceRegistry>> getBleDevicesForPerson(int personId) {
    return (select(bleDeviceRegistries)..where((tbl) => tbl.personId.equals(personId))).get();
  }

  Future<int> createBleDevice(BleDeviceRegistriesCompanion device) {
    return into(bleDeviceRegistries).insert(device);
  }

  Future<bool> updateBleDevice(BleDeviceRegistry device) {
    return update(bleDeviceRegistries).replace(device);
  }

  Future<List<Occasion>> getOccasionsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return (select(occasions)
          ..where((tbl) => tbl.date.isBetweenValues(startOfDay, endOfDay)))
        .get();
  }

  Future<List<Occasion>> getOccasionsForPerson(int personId) {
    return (select(occasions)..where((tbl) => tbl.personId.equals(personId))).get();
  }

  Future<int> createOccasion(OccasionsCompanion occasion) {
    return into(occasions).insert(occasion);
  }

  Future<bool> updateOccasion(Occasion occasion) {
    return update(occasions).replace(occasion);
  }

  Future<int> deleteOccasion(int id) {
    return (delete(occasions)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<PhotoPersonLink>> getPhotoPersonLinks(String photoId) {
    return (select(photoPersonLinks)..where((tbl) => tbl.photoId.equals(photoId))).get();
  }

  Future<List<PhotoPersonLink>> getPersonPhotoLinks(int personId) {
    return (select(photoPersonLinks)..where((tbl) => tbl.personId.equals(personId))).get();
  }

  Future<int> createPhotoPersonLink(PhotoPersonLinksCompanion link) {
    return into(photoPersonLinks).insert(link);
  }

  Future<int> deletePhotoPersonLinks(String photoId) {
    return (delete(photoPersonLinks)..where((tbl) => tbl.photoId.equals(photoId))).go();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'context.db'));
    return NativeDatabase(file);
  });
}
