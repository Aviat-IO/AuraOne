import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/simple_location_service.dart';

/// Legacy compatibility shims for older location UI code.
///
/// Production tracking state now flows through
/// `backgroundLocationTrackingProvider` and the background location runtime.
/// Do not add new production dependencies on these providers.

// Re-export the providers from simple_location_service.dart
export '../services/simple_location_service.dart'
    show
        simpleLocationServiceProvider,
        currentLocationProvider,
        isTrackingProvider,
        geofencesProvider,
        locationHistoryProvider;

// Location Service Provider (alias for compatibility)
@Deprecated(
  'Compatibility shim; prefer simpleLocationServiceProvider directly or backgroundLocationTrackingProvider for production state',
)
final locationServiceProvider = Provider<SimpleLocationService>((ref) {
  return ref.watch(simpleLocationServiceProvider);
});

// Location tracking state provider (alias for compatibility)
@Deprecated('Compatibility shim; prefer backgroundLocationTrackingProvider')
final isLocationTrackingProvider = StateProvider<bool>((ref) => false);

// Location permission state provider
@Deprecated('Compatibility shim for older UI flows')
final locationPermissionProvider = StateProvider<bool>((ref) => false);

// Current location as LocationData provider (converts from Position)
@Deprecated('Compatibility shim for older UI flows')
final currentLocationDataProvider = Provider<LocationData?>((ref) {
  final position = ref.watch(currentLocationProvider);
  if (position == null) return null;

  return LocationData(
    latitude: position.latitude,
    longitude: position.longitude,
    altitude: position.altitude,
    accuracy: position.accuracy,
    speed: position.speed,
    heading: position.heading,
    timestamp: position.timestamp,
  );
});

// Location updates stream (empty for now - compatibility)
@Deprecated('Compatibility shim; no production stream is exposed here')
final locationUpdatesProvider = StreamProvider.autoDispose<LocationData>((ref) {
  // Return empty stream for now - will be implemented with actual location updates
  return Stream.empty();
});

// Location settings provider
@Deprecated('Compatibility shim for older UI flows')
final locationSettingsProvider = StateProvider<LocationSettings>((ref) {
  return LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
    interval: 5000,
  );
});

class LocationSettings {
  final LocationAccuracy accuracy;
  final double distanceFilter;
  final int interval;

  LocationSettings({
    required this.accuracy,
    required this.distanceFilter,
    required this.interval,
  });
}

enum LocationAccuracy { lowest, low, medium, high, best }

class LocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
  });
}
