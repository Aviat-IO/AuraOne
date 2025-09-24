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
        importance: Importance.low, // Low importance for persistent notification
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
        initialNotificationTitle: 'Aura One',
        initialNotificationContent: 'Location tracking active',
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
    int intervalMinutes = 5, // Default to 5 minute intervals
    double distanceFilter = 50, // Movement threshold in meters
  }) async {
    try {
      // Check location permissions first
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        appLogger.warning('Location permissions not granted');
        return false;
      }

      // Store tracking preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('location_interval_minutes', intervalMinutes);
      await prefs.setDouble('location_distance_filter', distanceFilter);
      await prefs.setBool('location_tracking_enabled', true);

      // Start the background service
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (!isRunning) {
        await service.startService();
        appLogger.info('Started persistent location tracking');
      } else {
        appLogger.info('Persistent location tracking already running');
      }

      return true;
    } catch (e) {
      appLogger.error('Failed to start persistent location tracking', error: e);
      return false;
    }
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

  try {
    // Load tracking preferences
    final prefs = await SharedPreferences.getInstance();
    final intervalMinutes = prefs.getInt('location_interval_minutes') ?? 5;
    final distanceFilter = prefs.getDouble('location_distance_filter') ?? 50;
    final isEnabled = prefs.getBool('location_tracking_enabled') ?? true;

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
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true, // Keep notification persistent
          showWhen: false,
          autoCancel: false,
        );

        await notificationsPlugin.show(
          PersistentLocationService._notificationId,
          'Aura One',
          content,
          NotificationDetails(android: androidDetails),
        );
      }

      await updateNotification('Location tracking active');

      // Configure location settings
      late LocationSettings locationSettings;
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter.toInt(),
        intervalDuration: Duration(minutes: intervalMinutes),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Aura One is tracking your location for automatic journaling',
          notificationTitle: 'Location Tracking Active',
          enableWakeLock: true,
        ),
      );

      // Track location points collected
      int locationCount = 0;
      DateTime? lastLocationTime;

      // Start location stream
      positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) async {
        try {
          // Store location in database
          await _storeLocationInBackground(position);

          locationCount++;
          lastLocationTime = DateTime.now();

          // Update notification with location count
          final timeAgo = _formatTimeAgo(lastLocationTime!);
          await updateNotification(
            'Tracking active • $locationCount locations today • Last: $timeAgo'
          );

          // Broadcast update to app if it's running
          service.invoke('update', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': position.timestamp.toIso8601String(),
            'count': locationCount,
          });

        } catch (e) {
          debugPrint('Error storing background location: $e');
        }
      });

      // Also set up a periodic timer as backup
      locationTimer = Timer.periodic(Duration(minutes: intervalMinutes), (timer) async {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 30),
            ),
          );

          await _storeLocationInBackground(position);

          locationCount++;
          lastLocationTime = DateTime.now();

          // Update notification
          await updateNotification(
            'Tracking active • $locationCount locations today'
          );

          service.invoke('update', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': position.timestamp.toIso8601String(),
            'count': locationCount,
          });
        } catch (e) {
          debugPrint('Error in periodic location update: $e');
        }
      });
    }
  } catch (e) {
    debugPrint('Error in background location service: $e');
    service.stopSelf();
  }

  // Clean up on service stop
  service.on('stopService').listen((event) {
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
      isSignificant: drift.Value(position.speed != null && position.speed! > 1.0), // Moving
    ));

    // Close database connection
    await database.close();

    debugPrint('Background location stored: ${position.latitude}, ${position.longitude}');
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