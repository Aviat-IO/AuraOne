import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Font size provider
enum FontSize {
  small,
  medium,
  large,
}

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, FontSize>((ref) {
  return FontSizeNotifier();
});

class FontSizeNotifier extends StateNotifier<FontSize> {
  FontSizeNotifier() : super(FontSize.medium) {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getInt('fontSize') ?? 1; // Default to medium
    state = FontSize.values[savedValue];
  }

  Future<void> setFontSize(FontSize size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fontSize', size.index);
  }

  double get scaleFactor {
    return switch (state) {
      FontSize.small => 1.0,  // Previously medium
      FontSize.medium => 1.15, // Previously large
      FontSize.large => 1.3,   // Previously extraLarge
    };
  }
}

// Daily reminders provider
final dailyRemindersEnabledProvider = StateNotifierProvider<DailyRemindersNotifier, bool>((ref) {
  return DailyRemindersNotifier(ref);
});

class DailyRemindersNotifier extends StateNotifier<bool> {
  final Ref _ref;

  DailyRemindersNotifier(this._ref) : super(true) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('dailyReminders') ?? true;
    state = isEnabled;

    // If reminders are enabled, schedule them
    if (isEnabled) {
      await _scheduleReminders();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailyReminders', enabled);

    final notificationService = _ref.read(notificationServiceProvider);

    if (enabled) {
      // Schedule daily reminders when enabled
      await _scheduleReminders();
    } else {
      // Cancel reminders when disabled
      await notificationService.cancelDailyReminder();
    }
  }

  Future<void> _scheduleReminders() async {
    final notificationService = _ref.read(notificationServiceProvider);
    final reminderTime = _ref.read(reminderTimeProvider);

    // Convert DateTime to TimeOfDay
    final timeOfDay = TimeOfDay(
      hour: reminderTime.hour,
      minute: reminderTime.minute,
    );

    await notificationService.scheduleDailyReminder(timeOfDay);
  }
}

// Reminder time provider
final reminderTimeProvider = StateNotifierProvider<ReminderTimeNotifier, DateTime>((ref) {
  return ReminderTimeNotifier(ref);
});

class ReminderTimeNotifier extends StateNotifier<DateTime> {
  final Ref _ref;

  ReminderTimeNotifier(this._ref) : super(DateTime(2024, 1, 1, 20, 0)) {
    _loadTime();
  }

  Future<void> _loadTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminderHour') ?? 20;
    final minute = prefs.getInt('reminderMinute') ?? 0;
    state = DateTime(2024, 1, 1, hour, minute);
  }

  Future<void> setTime(DateTime time) async {
    state = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderHour', time.hour);
    await prefs.setInt('reminderMinute', time.minute);

    // Reschedule reminders with new time if they're enabled
    final remindersEnabled = _ref.read(dailyRemindersEnabledProvider);
    if (remindersEnabled) {
      final notificationService = _ref.read(notificationServiceProvider);
      final timeOfDay = TimeOfDay(hour: time.hour, minute: time.minute);
      await notificationService.scheduleDailyReminder(timeOfDay);
    }
  }
}
