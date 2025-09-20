import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
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

  DailyRemindersNotifier(this._ref) : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we have a saved preference
    final savedPref = prefs.getBool('dailyReminders');

    if (savedPref != null) {
      // Use saved preference
      state = savedPref;
    } else {
      // First time - check actual notification permission status
      final status = await Permission.notification.status;
      final hasPermission = status.isGranted;
      state = hasPermission;

      // Save the initial state based on permission
      await prefs.setBool('dailyReminders', hasPermission);
    }

    // If reminders are enabled and we have permission, schedule them
    if (state) {
      final permissionStatus = await Permission.notification.status;
      if (permissionStatus.isGranted) {
        await _scheduleReminders();
      } else {
        // Permission was revoked, update state
        state = false;
        await prefs.setBool('dailyReminders', false);
      }
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

// Reverse geocoding provider - OFF BY DEFAULT for privacy
final reverseGeocodingEnabledProvider = StateNotifierProvider<ReverseGeocodingNotifier, bool>((ref) {
  return ReverseGeocodingNotifier();
});

class ReverseGeocodingNotifier extends StateNotifier<bool> {
  ReverseGeocodingNotifier() : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to false for privacy - users must explicitly opt-in
    state = prefs.getBool('reverseGeocodingEnabled') ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reverseGeocodingEnabled', enabled);
  }
}

// Calendar settings provider
final calendarSettingsProvider = StateNotifierProvider<CalendarSettingsNotifier, CalendarSettings>((ref) {
  return CalendarSettingsNotifier();
});

class CalendarSettings {
  final Set<String> enabledCalendarIds;

  const CalendarSettings({
    this.enabledCalendarIds = const {},
  });

  CalendarSettings copyWith({
    Set<String>? enabledCalendarIds,
  }) {
    return CalendarSettings(
      enabledCalendarIds: enabledCalendarIds ?? this.enabledCalendarIds,
    );
  }
}

class CalendarSettingsNotifier extends StateNotifier<CalendarSettings> {
  CalendarSettingsNotifier() : super(const CalendarSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabledIds = prefs.getStringList('enabledCalendarIds') ?? [];
    state = CalendarSettings(
      enabledCalendarIds: enabledIds.toSet(),
    );
  }

  Future<void> enableAllCalendarsIfFirstTime(List<String> allCalendarIds) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSetInitialCalendars = prefs.getBool('hasSetInitialCalendars') ?? false;

    if (!hasSetInitialCalendars && allCalendarIds.isNotEmpty) {
      // First time loading calendars - enable all by default
      state = state.copyWith(enabledCalendarIds: allCalendarIds.toSet());
      await prefs.setStringList('enabledCalendarIds', allCalendarIds);
      await prefs.setBool('hasSetInitialCalendars', true);
    }
  }

  Future<void> setCalendarEnabled(String calendarId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final currentIds = Set<String>.from(state.enabledCalendarIds);

    if (enabled) {
      currentIds.add(calendarId);
    } else {
      currentIds.remove(calendarId);
    }

    state = state.copyWith(enabledCalendarIds: currentIds);
    await prefs.setStringList('enabledCalendarIds', currentIds.toList());
  }

  Future<void> setAllCalendarsEnabled(List<String> calendarIds, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final newIds = enabled ? calendarIds.toSet() : <String>{};

    state = state.copyWith(enabledCalendarIds: newIds);
    await prefs.setStringList('enabledCalendarIds', newIds.toList());
  }
}
