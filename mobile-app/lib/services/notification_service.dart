import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/logger.dart';

/// Service for managing local notifications and daily reminders
class NotificationService {
  static final _logger = AppLogger('NotificationService');
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      final String timeZoneName = tz.local.name;
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      _logger.info('Notification service initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize notification service', error: e);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.info('Notification tapped: ${response.payload}');
    // TODO: Navigate to journal or appropriate screen
  }

  /// Schedule daily reminder notification
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Check if we need exact alarm permission on Android
      if (Platform.isAndroid) {
        final androidImpl = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        if (androidImpl != null) {
          // Check Android version
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          final sdkInt = androidInfo.version.sdkInt;

          // Android 12-13 (API 31-33): Need to request SCHEDULE_EXACT_ALARM
          if (sdkInt >= 31 && sdkInt <= 33) {
            final granted = await androidImpl.requestExactAlarmsPermission();
            if (granted != true) {
              _logger.error('Exact alarms permission not granted for Android $sdkInt');
              throw Exception('Please enable "Alarms & reminders" permission in app settings');
            }
          }
          // Android 14+ (API 34+): USE_EXACT_ALARM is automatically granted
          // Android 11 and below: No special permission needed
        }
      }

      // Cancel existing daily reminder
      await cancelDailyReminder();

      // Calculate next occurrence of the specified time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'daily_reminder',
        'Daily Reminders',
        channelDescription: 'Daily reminders to check in with your wellness',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification to repeat daily
      await _notifications.zonedSchedule(
        0, // Notification ID for daily reminder
        'Time for your daily check-in! 🌟',
        'How was your day? Take a moment to reflect on your wellness journey.',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
        payload: 'daily_reminder',
      );

      _logger.info('Daily reminder scheduled for ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      _logger.error('Failed to schedule daily reminder', error: e);
    }
  }

  /// Cancel daily reminder notification
  Future<void> cancelDailyReminder() async {
    try {
      await _notifications.cancel(0); // Cancel notification with ID 0 (daily reminder)
      _logger.info('Daily reminder cancelled');
    } catch (e) {
      _logger.error('Failed to cancel daily reminder', error: e);
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        final enabled = await androidImpl.areNotificationsEnabled();
        return enabled ?? false;
      }

      final iosImpl = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImpl != null) {
        // iOS doesn't have a direct method, so we assume true if initialized
        return true;
      }

      return false;
    } catch (e) {
      _logger.error('Failed to check notification status', error: e);
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidImpl = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        if (androidImpl != null) {
          // Request notification permission
          final granted = await androidImpl.requestNotificationsPermission();

          if (granted != true) {
            return false;
          }

          // Check Android version for exact alarm permission
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          final sdkInt = androidInfo.version.sdkInt;

          // Android 12-13 (API 31-33): Request SCHEDULE_EXACT_ALARM
          if (sdkInt >= 31 && sdkInt <= 33) {
            final exactAlarmGranted = await androidImpl.requestExactAlarmsPermission();
            return exactAlarmGranted ?? false;
          }

          // Android 14+ (API 34+): USE_EXACT_ALARM is automatically granted
          // Android 11 and below: No special permission needed
          return true;
        }
      } else if (Platform.isIOS) {
        final iosImpl = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        if (iosImpl != null) {
          final granted = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }

      return false;
    } catch (e) {
      _logger.error('Failed to request notification permissions', error: e);
      return false;
    }
  }

  /// Send an instant test notification
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'test_notification',
        'Test Notifications',
        channelDescription: 'Test notification channel',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        999, // Different ID for test notification
        'Test Notification 🎉',
        'Your daily reminders are working perfectly!',
        notificationDetails,
        payload: 'test',
      );

      _logger.info('Test notification sent');
    } catch (e) {
      _logger.error('Failed to send test notification', error: e);
    }
  }
}