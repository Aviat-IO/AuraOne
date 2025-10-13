import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/calendar_service.dart';
import '../providers/settings_providers.dart';
import '../utils/logger.dart';

/// Service to handle calendar initialization during app startup
class CalendarInitializationService {
  final Ref ref;

  CalendarInitializationService(this.ref);

  /// Initialize calendar settings and permissions check
  /// This ensures calendar events are available without requiring
  /// the user to visit the calendar settings page first
  Future<void> initialize() async {
    try {
      appLogger.info('Initializing calendar settings...');

      final calendarService = CalendarService();

      // Check if we have calendar permissions
      final hasPermission = await calendarService.hasPermissions();

      if (!hasPermission) {
        appLogger.info('Calendar permissions not granted yet');
        return;
      }

      // Check if calendars are already enabled
      final currentSettings = ref.read(calendarSettingsProvider);
      if (currentSettings.enabledCalendarIds.isNotEmpty) {
        appLogger.info('Calendar settings already configured with ${currentSettings.enabledCalendarIds.length} enabled calendars');
        return;
      }

      appLogger.info('Setting up calendars - enabling all by default');

      try {
        // Get all available calendars
        final calendars = await calendarService.getCalendars(forceRefresh: true);

        if (calendars.isNotEmpty) {
          // Extract calendar IDs
          final calendarIds = calendars.map((c) => c.id).toList();

          // Enable all calendars by default using the notifier's method
          await ref.read(calendarSettingsProvider.notifier)
              .setAllCalendarsEnabled(calendarIds, true);

          // Mark as initialized
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasSetInitialCalendars', true);

          appLogger.info('Enabled ${calendars.length} calendars by default');
        } else {
          appLogger.warning('No calendars found on device');
        }
      } catch (e) {
        appLogger.error('Failed to initialize calendars', error: e);
      }
    } catch (e) {
      appLogger.error('Calendar initialization failed', error: e);
      // Don't throw - calendar features are optional
    }
  }
}

// Provider for the calendar initialization service
final calendarInitializationServiceProvider = Provider<CalendarInitializationService>((ref) {
  return CalendarInitializationService(ref);
});