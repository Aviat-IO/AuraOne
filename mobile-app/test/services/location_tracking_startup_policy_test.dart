import 'package:aura_one/services/location_tracking_startup_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'starts only the authoritative tracker when persisted tracking is enabled',
    () async {
      final authoritativeTracker = _FakeContinuousLocationTracker();
      final secondaryTracker = _FakeSecondaryLocationTracker();
      final policy = LocationTrackingStartupPolicy(
        authoritativeTracker: authoritativeTracker,
        secondaryTracker: secondaryTracker,
      );

      final started = await policy.startIfEnabled(
        onboardingCompleted: true,
        trackingEnabled: true,
      );

      expect(started, isTrue);
      expect(authoritativeTracker.initializeCalls, 1);
      expect(authoritativeTracker.permissionChecks, 1);
      expect(authoritativeTracker.startCalls, 1);
      expect(authoritativeTracker.stopCalls, 0);
      expect(secondaryTracker.stopCalls, 1);
    },
  );

  test('skips tracker startup when persisted tracking is disabled', () async {
    final authoritativeTracker = _FakeContinuousLocationTracker();
    final secondaryTracker = _FakeSecondaryLocationTracker();
    final policy = LocationTrackingStartupPolicy(
      authoritativeTracker: authoritativeTracker,
      secondaryTracker: secondaryTracker,
    );

    final started = await policy.startIfEnabled(
      onboardingCompleted: true,
      trackingEnabled: false,
    );

    expect(started, isFalse);
    expect(authoritativeTracker.initializeCalls, 0);
    expect(authoritativeTracker.permissionChecks, 0);
    expect(authoritativeTracker.startCalls, 0);
    expect(authoritativeTracker.stopCalls, 1);
    expect(secondaryTracker.stopCalls, 1);
  });

  test('skips startup when onboarding is incomplete', () async {
    final authoritativeTracker = _FakeContinuousLocationTracker();
    final secondaryTracker = _FakeSecondaryLocationTracker();
    final policy = LocationTrackingStartupPolicy(
      authoritativeTracker: authoritativeTracker,
      secondaryTracker: secondaryTracker,
    );

    final started = await policy.startIfEnabled(
      onboardingCompleted: false,
      trackingEnabled: true,
    );

    expect(started, isFalse);
    expect(authoritativeTracker.startCalls, 0);
    expect(authoritativeTracker.stopCalls, 1);
    expect(secondaryTracker.stopCalls, 1);
  });
}

class _FakeContinuousLocationTracker implements ContinuousLocationTracker {
  _FakeContinuousLocationTracker();

  int initializeCalls = 0;
  int permissionChecks = 0;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<bool> checkLocationPermission() async {
    permissionChecks += 1;
    return true;
  }

  @override
  Future<bool> isTrackingEnabled() async {
    return startCalls > stopCalls;
  }

  @override
  Future<bool> initialize() async {
    initializeCalls += 1;
    return true;
  }

  @override
  Future<bool> startTracking() async {
    startCalls += 1;
    return true;
  }

  @override
  Future<bool> stopTracking() async {
    stopCalls += 1;
    return true;
  }
}

class _FakeSecondaryLocationTracker implements SecondaryLocationTracker {
  int stopCalls = 0;

  @override
  Future<void> stopTracking() async {
    stopCalls += 1;
  }
}
