import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../database/location_database.dart' as loc_db;
import '../services/ai/dbscan_clustering.dart';
import 'location_database_provider.dart';

// Provider for clustered locations for a specific date
final clusteredLocationsProvider = FutureProvider.family<List<LocationCluster>, DateTime>(
  (ref, date) async {
    // Get the location points for the date from the database
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Watch the location points stream and get the data
    final locationStream = ref.watch(recentLocationPointsProvider(const Duration(days: 7)));

    final locationHistory = await locationStream.when(
      data: (locations) => Future.value(locations),
      loading: () => Future.value(<loc_db.LocationPoint>[]),
      error: (_, __) => Future.value(<loc_db.LocationPoint>[]),
    );

    // Filter locations for the specific date
    final dayLocations = locationHistory
        .where((loc) => loc.timestamp.isAfter(dayStart) && loc.timestamp.isBefore(dayEnd))
        .toList();

    if (dayLocations.isEmpty) {
      return [];
    }

    // Convert database location points to clustering location points
    final clusteringPoints = dayLocations.map((dbPoint) {
      return LocationPoint(
        id: dbPoint.id.toString(),
        latitude: dbPoint.latitude,
        longitude: dbPoint.longitude,
        timestamp: dbPoint.timestamp,
      );
    }).toList();

    // Perform DBSCAN clustering
    // Using 50 meters radius and minimum 3 points for a cluster
    // This means if you stay in roughly the same 50m area for 3+ location samples,
    // it counts as one location
    final dbscan = DBSCANClustering(
      eps: 50.0,  // 50 meters radius
      minPts: 3,   // Minimum 3 points to form a cluster
    );

    final clusters = dbscan.cluster(clusteringPoints);

    return clusters;
  },
);

// Provider for the count of unique locations visited on a date
final uniqueLocationsCountProvider = FutureProvider.family<int, DateTime>(
  (ref, date) async {
    final clusters = await ref.watch(clusteredLocationsProvider(date).future);
    return clusters.length;
  },
);

// Provider for journey segments (movement between locations) on a date
final journeySegmentsProvider = FutureProvider.family<List<JourneySegment>, DateTime>(
  (ref, date) async {
    // Get the location points for the date from the database
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Watch the location points stream and get the data
    final locationStream = ref.watch(recentLocationPointsProvider(const Duration(days: 7)));

    final locationHistory = await locationStream.when(
      data: (locations) => Future.value(locations),
      loading: () => Future.value(<loc_db.LocationPoint>[]),
      error: (_, __) => Future.value(<loc_db.LocationPoint>[]),
    );

    // Filter locations for the specific date
    final dayLocations = locationHistory
        .where((loc) => loc.timestamp.isAfter(dayStart) && loc.timestamp.isBefore(dayEnd))
        .toList();

    if (dayLocations.isEmpty) {
      return [];
    }

    // Convert database location points to clustering location points
    final clusteringPoints = dayLocations.map((dbPoint) {
      return LocationPoint(
        id: dbPoint.id.toString(),
        latitude: dbPoint.latitude,
        longitude: dbPoint.longitude,
        timestamp: dbPoint.timestamp,
      );
    }).toList();

    // Perform DBSCAN clustering to identify noise points (journey points)
    final dbscan = DBSCANClustering(
      eps: 50.0,  // 50 meters radius
      minPts: 3,   // Minimum 3 points to form a cluster
    );

    // Cluster the points
    dbscan.cluster(clusteringPoints);

    // Identify journey segments from noise points
    final journeys = dbscan.identifyJourneys(clusteringPoints);

    return journeys;
  },
);