import 'package:aura_one/providers/settings_providers.dart';
import 'package:aura_one/services/location_tracking_startup_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('refreshRuntimeState loads actual tracker runtime state', () async {
    SharedPreferences.setMockInitialValues({
      'backgroundLocationTracking': false,
    });

    final container = ProviderContainer(
      overrides: [
        continuousLocationTrackerProvider.overrideWithValue(
          _FakeContinuousLocationTracker(isTrackingEnabledResult: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen<bool?>(
      backgroundLocationTrackingProvider,
      (_, next) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container
        .read(backgroundLocationTrackingProvider.notifier)
        .refreshRuntimeState();

    expect(subscription.read(), isTrue);
  });

  test('syncWithTrackerState persists actual tracker status', () async {
    SharedPreferences.setMockInitialValues({
      'backgroundLocationTracking': false,
    });

    final fakeTracker = _FakeContinuousLocationTracker(
      isTrackingEnabledResult: true,
    );
    final container = ProviderContainer(
      overrides: [
        continuousLocationTrackerProvider.overrideWithValue(fakeTracker),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(
      backgroundLocationTrackingProvider.notifier,
    );

    final synced = await notifier.syncWithTrackerState();
    final prefs = await SharedPreferences.getInstance();

    expect(synced, isTrue);
    expect(container.read(backgroundLocationTrackingProvider), isTrue);
    expect(prefs.getBool('backgroundLocationTracking'), isTrue);
  });

  test(
    'restoreTrackingState clears stale enabled state when startup fails',
    () async {
      SharedPreferences.setMockInitialValues({
        'backgroundLocationTracking': true,
      });

      final fakeTracker = _FakeContinuousLocationTracker(startResult: false);
      final fakeSecondary = _FakeSecondaryLocationTracker();
      final container = ProviderContainer(
        overrides: [
          continuousLocationTrackerProvider.overrideWithValue(fakeTracker),
          secondaryLocationTrackerProvider.overrideWithValue(fakeSecondary),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        backgroundLocationTrackingProvider.notifier,
      );

      final restored = await notifier.restoreTrackingState(
        onboardingCompleted: true,
      );
      final prefs = await SharedPreferences.getInstance();

      expect(restored, isFalse);
      expect(fakeTracker.startCalls, 1);
      expect(fakeSecondary.stopCalls, 1);
      expect(container.read(backgroundLocationTrackingProvider), isFalse);
      expect(prefs.getBool('backgroundLocationTracking'), isFalse);
    },
  );

  test(
    'restoreTrackingState stops a running tracker when desired state is disabled',
    () async {
      SharedPreferences.setMockInitialValues({
        'backgroundLocationTracking': false,
      });

      final fakeTracker = _FakeContinuousLocationTracker(
        isTrackingEnabledResult: true,
      );
      final fakeSecondary = _FakeSecondaryLocationTracker();
      final container = ProviderContainer(
        overrides: [
          continuousLocationTrackerProvider.overrideWithValue(fakeTracker),
          secondaryLocationTrackerProvider.overrideWithValue(fakeSecondary),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        backgroundLocationTrackingProvider.notifier,
      );

      final restored = await notifier.restoreTrackingState(
        onboardingCompleted: true,
      );
      final prefs = await SharedPreferences.getInstance();

      expect(restored, isFalse);
      expect(fakeTracker.startCalls, 0);
      expect(fakeTracker.stopCalls, 1);
      expect(container.read(backgroundLocationTrackingProvider), isFalse);
      expect(prefs.getBool('backgroundLocationTracking'), isFalse);
    },
  );

  test('setEnabled persists state through the authoritative tracker', () async {
    SharedPreferences.setMockInitialValues({});

    final fakeTracker = _FakeContinuousLocationTracker();
    final container = ProviderContainer(
      overrides: [
        continuousLocationTrackerProvider.overrideWithValue(fakeTracker),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(
      backgroundLocationTrackingProvider.notifier,
    );

    final enabled = await notifier.setEnabled(true);
    final prefs = await SharedPreferences.getInstance();

    expect(enabled, isTrue);
    expect(fakeTracker.startCalls, 1);
    expect(fakeTracker.stopCalls, 0);
    expect(container.read(backgroundLocationTrackingProvider), isTrue);
    expect(prefs.getBool('backgroundLocationTracking'), isTrue);
  });

  test('failed tracker start leaves persisted state unchanged', () async {
    SharedPreferences.setMockInitialValues({});

    final fakeTracker = _FakeContinuousLocationTracker(startResult: false);
    final container = ProviderContainer(
      overrides: [
        continuousLocationTrackerProvider.overrideWithValue(fakeTracker),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(
      backgroundLocationTrackingProvider.notifier,
    );

    final enabled = await notifier.setEnabled(true);
    final prefs = await SharedPreferences.getInstance();

    expect(enabled, isFalse);
    expect(fakeTracker.startCalls, 1);
    expect(container.read(backgroundLocationTrackingProvider), isFalse);
    expect(prefs.getBool('backgroundLocationTracking'), isNot(true));
  });
}

class _FakeContinuousLocationTracker implements ContinuousLocationTracker {
  _FakeContinuousLocationTracker({
    this.startResult = true,
    this.isTrackingEnabledResult,
  }) : _runtimeState = isTrackingEnabledResult;

  final bool startResult;
  final bool? isTrackingEnabledResult;
  bool? _runtimeState;
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
  Future<bool> initialize() async {
    initializeCalls += 1;
    return true;
  }

  @override
  Future<bool> isTrackingEnabled() async {
    return _runtimeState ?? (startResult && startCalls > stopCalls);
  }

  @override
  Future<bool> startTracking() async {
    startCalls += 1;
    if (startResult) {
      _runtimeState = true;
    }
    return startResult;
  }

  @override
  Future<bool> stopTracking() async {
    stopCalls += 1;
    _runtimeState = false;
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
