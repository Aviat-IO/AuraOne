import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'background_location_service.dart';
import 'simple_location_service.dart';

const backgroundLocationTrackingPreferenceKey = 'backgroundLocationTracking';

abstract class ContinuousLocationTracker {
  Future<bool> initialize();

  Future<bool> isTrackingEnabled();

  Future<bool> checkLocationPermission();

  Future<bool> startTracking();

  Future<bool> stopTracking();
}

abstract class SecondaryLocationTracker {
  Future<void> stopTracking();
}

final continuousLocationTrackerProvider = Provider<ContinuousLocationTracker>((
  ref,
) {
  return _BackgroundContinuousLocationTracker(
    ref.watch(backgroundLocationServiceProvider),
  );
});

final secondaryLocationTrackerProvider = Provider<SecondaryLocationTracker>((
  ref,
) {
  return _SimpleSecondaryLocationTracker(
    ref.watch(simpleLocationServiceProvider),
  );
});

class LocationTrackingStartupPolicy {
  LocationTrackingStartupPolicy({
    required this.authoritativeTracker,
    required this.secondaryTracker,
  });

  final ContinuousLocationTracker authoritativeTracker;
  final SecondaryLocationTracker secondaryTracker;

  Future<bool> startIfEnabled({
    required bool onboardingCompleted,
    required bool trackingEnabled,
  }) async {
    if (!onboardingCompleted || !trackingEnabled) {
      await secondaryTracker.stopTracking();
      await authoritativeTracker.stopTracking();
      return false;
    }

    await secondaryTracker.stopTracking();

    final initialized = await authoritativeTracker.initialize();
    if (!initialized) {
      return false;
    }

    final hasPermission = await authoritativeTracker.checkLocationPermission();
    if (!hasPermission) {
      return false;
    }

    return authoritativeTracker.startTracking();
  }
}

class _BackgroundContinuousLocationTracker
    implements ContinuousLocationTracker {
  _BackgroundContinuousLocationTracker(this._service);

  final BackgroundLocationService _service;

  @override
  Future<bool> checkLocationPermission() => _service.checkLocationPermission();

  @override
  Future<bool> initialize() => _service.initialize();

  @override
  Future<bool> isTrackingEnabled() => _service.isTrackingEnabled();

  @override
  Future<bool> startTracking() => _service.startTracking();

  @override
  Future<bool> stopTracking() => _service.stopTracking();
}

class _SimpleSecondaryLocationTracker implements SecondaryLocationTracker {
  _SimpleSecondaryLocationTracker(this._service);

  final SimpleLocationService _service;

  @override
  Future<void> stopTracking() => _service.stopTracking();
}
