import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import '../database/location_database.dart';
import '../utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

enum BatteryOptimizationStatus {
  alreadyOptimized,
  settingsOpened,
  needsManualSetup,
  notRequired,
  error,
}

class PersistentLocationService {
  static const String _notificationChannelId = 'aura_one_location';
  static const String _notificationChannelName = 'Location Tracking';
  static const String _notificationChannelDescription =
      'Continuous location tracking for automatic journaling';
  static const int _notificationId = 888;

  static final PersistentLocationService _instance = PersistentLocationService._internal();
  factory PersistentLocationService() => _instance;
  PersistentLocationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the persistent location service
  Future<void> initialize() async {
    if (_isInitialized) {
      appLogger.info('Persistent location service already initialized');
      return;
    }

    try {
      // Initialize notifications
      await _initializeNotifications();

      // Initialize background service
      await _initializeBackgroundService();

      _isInitialized = true;
      appLogger.info('Persistent location service initialized');
    } catch (e) {
      appLogger.error('Failed to initialize persistent location service', error: e);
    }
  }

  /// Initialize notification system
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: null, // Not using iOS background service yet
    );

    await _notificationsPlugin.initialize(initSettings);

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _notificationChannelId,
        _notificationChannelName,
        description: _notificationChannelDescription,
        importance: Importance.high, // Changed to high for better reliability
        showBadge: false,
        playSound: false,
        enableVibration: false,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Initialize background service
  Future<void> _initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // We'll start it manually when needed
        isForegroundMode: true, // Run as foreground service for reliability
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Aura One Location Tracking',
        initialNotificationContent: 'Initializing location tracking...',
        foregroundServiceNotificationId: _notificationId,
        autoStartOnBoot: true, // Start on device boot
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Start persistent location tracking
  Future<bool> startTracking({
    int intervalMinutes = 2, // Reduced to 2 minute intervals for better coverage
    double distanceFilter = 0, // Changed to 0 to ensure all positions are captured
  }) async {
    try {
      // Check location permissions first
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        appLogger.warning('Location permissions not granted');
        return false;
      }

      // Request battery optimization exemption
      await _requestBatteryOptimizationExemption();

      // Store tracking preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('location_interval_minutes', intervalMinutes);
      await prefs.setDouble('location_distance_filter', distanceFilter);
      await prefs.setBool('location_tracking_enabled', true);
      await prefs.setInt('location_start_time', DateTime.now().millisecondsSinceEpoch);

      // Start the background service
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (!isRunning) {
        await service.startService();
        appLogger.info('Started persistent location tracking');
      } else {
        // Restart service to apply new settings
        service.invoke('stopService');
        await Future.delayed(Duration(seconds: 2));
        await service.startService();
        appLogger.info('Restarted persistent location tracking with new settings');
      }

      return true;
    } catch (e) {
      appLogger.error('Failed to start persistent location tracking', error: e);
      return false;
    }
  }

  /// Request battery optimization exemption
  Future<BatteryOptimizationStatus> _requestBatteryOptimizationExemption() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // Check if battery optimization is ignored
        final isIgnoringOptimization = await _checkBatteryOptimization();

        if (isIgnoringOptimization) {
          appLogger.info('Battery optimization already disabled for this app');
          return BatteryOptimizationStatus.alreadyOptimized;
        }

        // Try to open battery optimization settings
        try {
          await _openBatteryOptimizationSettings();
          return BatteryOptimizationStatus.settingsOpened;
        } catch (e) {
          appLogger.warning('Could not open battery optimization settings: $e');
          return BatteryOptimizationStatus.needsManualSetup;
        }
      }

      return BatteryOptimizationStatus.notRequired;
    } catch (e) {
      appLogger.error('Error requesting battery optimization exemption', error: e);
      return BatteryOptimizationStatus.error;
    }
  }

  /// Check if battery optimization is already disabled
  Future<bool> _checkBatteryOptimization() async {
    try {
      // This would need native Android implementation
      // For now, return false to assume optimization is enabled
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Open battery optimization settings
  Future<void> _openBatteryOptimizationSettings() async {
    try {
      // Try to open the ignore battery optimization dialog
      const platform = MethodChannel('aura_one/battery_optimization');
      await platform.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      // Fallback: try to open general battery optimization settings
      try {
        const platform = MethodChannel('aura_one/battery_optimization');
        await platform.invokeMethod('openBatteryOptimizationSettings');
      } catch (fallbackError) {
        appLogger.warning('Could not open battery settings: $fallbackError');
        rethrow;
      }
    }
  }

  /// Get battery optimization guidance for user
  String getBatteryOptimizationGuidance() {
    return '''
📱 **Improve Location Tracking Reliability**

Your device's battery optimization may be stopping location tracking when the app isn't active.

**Steps to fix this:**

1. **Open your device Settings**
2. **Go to Apps & notifications** (or similar)
3. **Find "Aura One"**
4. **Tap "Battery"** (or "Battery optimization")
5. **Select "Don't optimize"** or **"Allow background activity"**

**Alternative path:**
- Settings → Battery → Battery optimization → Aura One → Don't optimize

**Why this helps:**
- Prevents Android from killing the location tracking service
- Ensures continuous location collection even when app is closed
- Required for automatic journaling to work properly

⚡ **Note**: This will slightly increase battery usage but is necessary for continuous location tracking.
''';
  }

  /// Stop persistent location tracking
  Future<void> stopTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_tracking_enabled', false);

      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (isRunning) {
        service.invoke('stopService');
        appLogger.info('Stopped persistent location tracking');
      }
    } catch (e) {
      appLogger.error('Failed to stop persistent location tracking', error: e);
    }
  }

  /// Check if tracking is currently active
  Future<bool> isTracking() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// Check and request location permissions
  Future<bool> _checkAndRequestPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
    }

    // Check current permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    // For Android, request background location if not already granted
    if (Platform.isAndroid && permission == LocationPermission.whileInUse) {
      // Note: Background location permission must be requested separately on Android 10+
      // The app will work with whileInUse + foreground service
      appLogger.info('Using foreground service for background location tracking');
    }

    return true;
  }
}

/// Background service entry point (must be top-level)
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // Only for Android
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Initialize location tracking
  Timer? locationTimer;
  StreamSubscription<Position>? positionStream;
  Timer? heartbeatTimer;

  try {
    // Load tracking preferences
    final prefs = await SharedPreferences.getInstance();
    final intervalMinutes = prefs.getInt('location_interval_minutes') ?? 2;
    final distanceFilter = prefs.getDouble('location_distance_filter') ?? 0;
    final isEnabled = prefs.getBool('location_tracking_enabled') ?? true;
    final startTime = prefs.getInt('location_start_time') ?? DateTime.now().millisecondsSinceEpoch;

    if (!isEnabled) {
      service.stopSelf();
      return;
    }

    // Update notification
    if (service is AndroidServiceInstance) {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();

      // Initialize notifications in background
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      await notificationsPlugin.initialize(
        const InitializationSettings(android: androidSettings),
      );

      // Function to show/update notification
      Future<void> updateNotification(String content) async {
        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          PersistentLocationService._notificationChannelId,
          PersistentLocationService._notificationChannelName,
          channelDescription: PersistentLocationService._notificationChannelDescription,
          importance: Importance.high, // Changed to high
          priority: Priority.high, // Changed to high
          ongoing: true, // Keep notification persistent
          showWhen: false,
          autoCancel: false,
          usesChronometer: true, // Show elapsed time
          chronometerCountDown: false,
          when: startTime,
        );

        await notificationsPlugin.show(
          PersistentLocationService._notificationId,
          'Aura One - Location Tracking Active',
          content,
          NotificationDetails(android: androidDetails),
        );
      }

      await updateNotification('Starting location tracking service...');

      // Track location points collected
      int locationCount = 0;
      DateTime? lastLocationTime;

      // Set up heartbeat timer to keep service alive
      heartbeatTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
        try {
          // Update notification to show service is alive
          final now = DateTime.now();
          final elapsed = Duration(milliseconds: now.millisecondsSinceEpoch - startTime);
          final hours = elapsed.inHours;
          final minutes = elapsed.inMinutes % 60;

          await updateNotification(
            'Active ${hours}h ${minutes}m • $locationCount locations collected'
          );

          // Send heartbeat to main app
          service.invoke('heartbeat', {
            'timestamp': now.toIso8601String(),
            'locationCount': locationCount,
            'uptime': elapsed.inMinutes,
          });
        } catch (e) {
          debugPrint('Heartbeat error: $e');
        }
      });

      // Configure location settings for maximum reliability
      late LocationSettings locationSettings;
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter.toInt(),
        intervalDuration: Duration(minutes: intervalMinutes),
        forceLocationManager: true, // Force LocationManager instead of FusedLocation
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationText: 'Aura One is continuously tracking your location for journaling',
          notificationTitle: 'Background Location Tracking',
          enableWakeLock: true,
        ),
      );

      // Main periodic timer for guaranteed location updates
      locationTimer = Timer.periodic(Duration(minutes: intervalMinutes), (timer) async {
        try {
          debugPrint('Periodic location update attempt...');

          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 45), // Increased timeout
            ),
          );

          await _storeLocationInBackground(position);

          locationCount++;
          lastLocationTime = DateTime.now();

          debugPrint('Location stored: ${position.latitude}, ${position.longitude}');

          // Update notification with success
          final timeAgo = _formatTimeAgo(lastLocationTime!);
          await updateNotification(
            'Last update: $timeAgo • $locationCount total locations'
          );

          service.invoke('locationUpdate', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': position.timestamp.toIso8601String(),
            'count': locationCount,
          });

        } catch (e) {
          debugPrint('Error in periodic location update: $e');
          // Update notification with error
          await updateNotification(
            'Error getting location: ${e.toString().substring(0, 50)}...'
          );
        }
      });

      // Also try to start location stream as backup (may not work reliably in background)
      try {
        positionStream = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) async {
          try {
            // Only store if we haven't stored a location in the last 1.5 minutes
            if (lastLocationTime == null ||
                DateTime.now().difference(lastLocationTime!).inMinutes >= 1) {

              await _storeLocationInBackground(position);
              locationCount++;
              lastLocationTime = DateTime.now();

              debugPrint('Stream location stored: ${position.latitude}, ${position.longitude}');

              final timeAgo = _formatTimeAgo(lastLocationTime!);
              await updateNotification(
                'Stream update: $timeAgo • $locationCount total locations'
              );

              service.invoke('streamUpdate', {
                'latitude': position.latitude,
                'longitude': position.longitude,
                'timestamp': position.timestamp.toIso8601String(),
                'count': locationCount,
              });
            }
          } catch (e) {
            debugPrint('Error storing stream location: $e');
          }
        });
      } catch (e) {
        debugPrint('Could not start location stream: $e');
        // This is okay, we rely on the timer primarily
      }
    }
  } catch (e) {
    debugPrint('Error in background location service: $e');
    if (service is AndroidServiceInstance) {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      try {
        await notificationsPlugin.show(
          PersistentLocationService._notificationId,
          'Location Service Error',
          'Service failed: ${e.toString()}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'error_channel',
              'Errors',
              importance: Importance.high,
            ),
          ),
        );
      } catch (_) {}
    }
    service.stopSelf();
  }

  // Clean up on service stop
  service.on('stopService').listen((event) {
    debugPrint('Stopping location service...');
    heartbeatTimer?.cancel();
    locationTimer?.cancel();
    positionStream?.cancel();
    service.stopSelf();
  });
}

/// iOS background handler (required but not implemented yet)
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  // iOS background location tracking would go here
  return true;
}

/// Store location in background (isolated from main app)
Future<void> _storeLocationInBackground(Position position) async {
  try {
    // Get documents directory
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDir.path, 'location_database.db');

    // Open database connection
    final database = LocationDatabase.withConnection(
      openConnection: NativeDatabase.createInBackground(File(dbPath)),
    );

    // Store location point
    await database.insertLocationPoint(LocationPointsCompanion(
      latitude: drift.Value(position.latitude),
      longitude: drift.Value(position.longitude),
      altitude: drift.Value(position.altitude),
      speed: drift.Value(position.speed),
      heading: drift.Value(position.heading),
      timestamp: drift.Value(position.timestamp),
      accuracy: drift.Value(position.accuracy),
      isSignificant: drift.Value(true), // Mark all as significant for now
    ));

    // Close database connection
    await database.close();

    debugPrint('Background location stored successfully: ${position.latitude}, ${position.longitude} at ${position.timestamp}');
  } catch (e) {
    debugPrint('Failed to store background location: $e');
  }
}

/// Format time ago for notification
String _formatTimeAgo(DateTime time) {
  final now = DateTime.now();
  final difference = now.difference(time);

  if (difference.inMinutes < 1) {
    return 'just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else {
    return '${difference.inDays}d ago';
  }
}