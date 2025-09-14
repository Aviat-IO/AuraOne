import 'dart:io';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import '../database/media_database.dart';

/// Calendar event data model
class CalendarEventData {
  final String id;
  final String? calendarId;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isAllDay;
  final String? location;
  final List<String> attendees;
  final String? url;
  final RecurrenceRule? recurrenceRule;
  final List<Reminder>? reminders;
  final Map<String, dynamic>? metadata;

  CalendarEventData({
    required this.id,
    this.calendarId,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.isAllDay = false,
    this.location,
    this.attendees = const [],
    this.url,
    this.recurrenceRule,
    this.reminders,
    this.metadata,
  });

  /// Convert from device_calendar Event
  factory CalendarEventData.fromEvent(Event event) {
    return CalendarEventData(
      id: event.eventId ?? '',
      calendarId: event.calendarId,
      title: event.title ?? 'Untitled Event',
      description: event.description,
      startDate: event.start!.toLocal(),
      endDate: event.end?.toLocal(),
      isAllDay: event.allDay ?? false,
      location: event.location,
      attendees: event.attendees?.map((a) => a?.name ?? a?.emailAddress ?? '').toList() ?? [],
      url: event.url?.toString(),
      recurrenceRule: event.recurrenceRule,
      reminders: event.reminders,
      metadata: {
        'availability': event.availability?.toString(),
        'status': event.status?.toString(),
      },
    );
  }

  /// Convert to device_calendar Event
  Event toEvent() {
    return Event(
      calendarId,
      eventId: id,
      title: title,
      description: description,
      start: TZDateTime.from(startDate, tz.local),
      end: endDate != null ? TZDateTime.from(endDate!, tz.local) : null,
      allDay: isAllDay,
      location: location,
      url: url != null ? Uri.parse(url!) : null,
      recurrenceRule: recurrenceRule,
      reminders: reminders,
      attendees: attendees.map((name) => Attendee(name: name)).toList(),
    );
  }
}

/// Calendar metadata
class CalendarMetadata {
  final String id;
  final String name;
  final bool isReadOnly;
  final bool isDefault;
  final Color? color;
  final String? accountName;
  final String? accountType;

  CalendarMetadata({
    required this.id,
    required this.name,
    required this.isReadOnly,
    required this.isDefault,
    this.color,
    this.accountName,
    this.accountType,
  });

  factory CalendarMetadata.fromCalendar(Calendar calendar) {
    return CalendarMetadata(
      id: calendar.id!,
      name: calendar.name ?? 'Unknown Calendar',
      isReadOnly: calendar.isReadOnly ?? false,
      isDefault: calendar.isDefault ?? false,
      color: calendar.color != null ? Color(calendar.color!) : null,
      accountName: calendar.accountName,
      accountType: calendar.accountType,
    );
  }
}

/// Privacy settings for calendar sync
class CalendarPrivacySettings {
  final bool syncEnabled;
  final bool syncPastEvents;
  final int pastEventsDays;
  final bool syncFutureEvents;
  final int futureEventsDays;
  final Set<String> allowedCalendarIds;
  final Set<String> blockedKeywords;
  final bool anonymizeAttendees;
  final bool stripUrls;
  final bool stripDescriptions;

  const CalendarPrivacySettings({
    this.syncEnabled = false,
    this.syncPastEvents = true,
    this.pastEventsDays = 30,
    this.syncFutureEvents = true,
    this.futureEventsDays = 90,
    this.allowedCalendarIds = const {},
    this.blockedKeywords = const {},
    this.anonymizeAttendees = false,
    this.stripUrls = false,
    this.stripDescriptions = false,
  });

  CalendarPrivacySettings copyWith({
    bool? syncEnabled,
    bool? syncPastEvents,
    int? pastEventsDays,
    bool? syncFutureEvents,
    int? futureEventsDays,
    Set<String>? allowedCalendarIds,
    Set<String>? blockedKeywords,
    bool? anonymizeAttendees,
    bool? stripUrls,
    bool? stripDescriptions,
  }) {
    return CalendarPrivacySettings(
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncPastEvents: syncPastEvents ?? this.syncPastEvents,
      pastEventsDays: pastEventsDays ?? this.pastEventsDays,
      syncFutureEvents: syncFutureEvents ?? this.syncFutureEvents,
      futureEventsDays: futureEventsDays ?? this.futureEventsDays,
      allowedCalendarIds: allowedCalendarIds ?? this.allowedCalendarIds,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      anonymizeAttendees: anonymizeAttendees ?? this.anonymizeAttendees,
      stripUrls: stripUrls ?? this.stripUrls,
      stripDescriptions: stripDescriptions ?? this.stripDescriptions,
    );
  }
}

/// Service for managing calendar integration
class CalendarService {
  static final _logger = AppLogger('CalendarService');
  static final _instance = CalendarService._internal();

  factory CalendarService() => _instance;
  CalendarService._internal() {
    _checkPermissions();
  }

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  CalendarPrivacySettings _privacySettings = const CalendarPrivacySettings();
  bool _hasPermissions = false;

  /// Cache for calendars and events
  final Map<String, CalendarMetadata> _calendarsCache = {};
  final Map<String, List<CalendarEventData>> _eventsCache = {};
  DateTime? _lastSyncTime;

  /// Get current privacy settings
  CalendarPrivacySettings get privacySettings => _privacySettings;

  /// Update privacy settings
  void updatePrivacySettings(CalendarPrivacySettings settings) {
    _privacySettings = settings;
    _logger.info('Privacy settings updated: syncEnabled=${settings.syncEnabled}');
  }

  /// Get events in a date range
  Future<List<CalendarEventData>> getEventsInRange(
    DateTime start,
    DateTime end, {
    Set<String>? calendarIds,
  }) async {
    if (!_hasPermissions) {
      // Silently return empty list when no permissions
      return [];
    }

    try {
      final calendars = await _plugin.retrieveCalendars();
      if (calendars.data == null || calendars.data!.isEmpty) {
        _logger.warning('No calendars found');
        return [];
      }

      final events = <CalendarEventData>[];
      final calendarsToQuery = calendarIds != null
          ? calendars.data!.where((c) => calendarIds.contains(c.id))
          : calendars.data!;

      for (final calendar in calendarsToQuery) {
        if (calendar.id == null) continue;

        final result = await _plugin.retrieveEvents(
          calendar.id!,
          RetrieveEventsParams(
            startDate: start,
            endDate: end,
          ),
        );

        if (result.data != null) {
          events.addAll(
            result.data!.map((e) => CalendarEventData.fromEvent(e))
          );
        }
      }

      return events;
    } catch (e, stack) {
      _logger.error('Failed to get events in range', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Request calendar permissions
  Future<bool> requestPermissions() async {
    try {
      _logger.info('Requesting calendar permissions');

      // Platform-specific permission request
      if (Platform.isIOS) {
        // iOS uses EventKit permissions
        final status = await Permission.calendarFullAccess.request();

        if (status.isGranted) {
          _logger.info('iOS calendar permissions granted');
          _hasPermissions = true;
          return true;
        } else if (status.isPermanentlyDenied) {
          _logger.warning('iOS calendar permissions permanently denied');
          // Guide user to settings
          await openAppSettings();
        }
      } else if (Platform.isAndroid) {
        // Android uses Calendar Provider permissions
        final readStatus = await Permission.calendar.request();

        if (readStatus.isGranted) {
          _logger.info('Android calendar permissions granted');
          _hasPermissions = true;
          return true;
        } else if (readStatus.isPermanentlyDenied) {
          _logger.warning('Android calendar permissions permanently denied');
          // Guide user to settings
          await openAppSettings();
        }
      }

      return false;
    } catch (e, stack) {
      _logger.error('Failed to request calendar permissions',
                   error: e, stackTrace: stack);
      return false;
    }
  }

  /// Check permissions on initialization
  Future<void> _checkPermissions() async {
    _hasPermissions = await hasPermissions();
  }

  /// Check if calendar permissions are granted
  Future<bool> hasPermissions() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.calendarFullAccess.status;
        return status.isGranted;
      } else if (Platform.isAndroid) {
        final status = await Permission.calendar.status;
        return status.isGranted;
      }
      return false;
    } catch (e) {
      _logger.error('Failed to check calendar permissions', error: e);
      return false;
    }
  }

  /// Get all calendars on the device
  Future<List<CalendarMetadata>> getCalendars({bool forceRefresh = false}) async {
    try {
      if (!await hasPermissions()) {
        _logger.warning('Calendar permissions not granted');
        return [];
      }

      if (!forceRefresh && _calendarsCache.isNotEmpty) {
        return _calendarsCache.values.toList();
      }

      _logger.info('Fetching device calendars');

      final result = await _plugin.retrieveCalendars();

      if (!result.isSuccess || result.data == null) {
        _logger.error('Failed to retrieve calendars: ${result.errors}');
        return [];
      }

      // Clear and rebuild cache
      _calendarsCache.clear();

      for (final calendar in result.data!) {
        if (calendar.id != null) {
          final metadata = CalendarMetadata.fromCalendar(calendar);
          _calendarsCache[calendar.id!] = metadata;
        }
      }

      _logger.info('Found ${_calendarsCache.length} calendars');
      return _calendarsCache.values.toList();
    } catch (e, stack) {
      _logger.error('Failed to get calendars', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get events from specified calendars
  Future<List<CalendarEventData>> getEvents({
    Set<String>? calendarIds,
    DateTime? startDate,
    DateTime? endDate,
    bool applyPrivacyFilter = true,
  }) async {
    try {
      if (!await hasPermissions()) {
        _logger.warning('Calendar permissions not granted');
        return [];
      }

      if (!_privacySettings.syncEnabled && applyPrivacyFilter) {
        _logger.info('Calendar sync is disabled');
        return [];
      }

      // Set date range based on privacy settings
      final now = DateTime.now();
      startDate ??= _privacySettings.syncPastEvents
          ? now.subtract(Duration(days: _privacySettings.pastEventsDays))
          : now;
      endDate ??= _privacySettings.syncFutureEvents
          ? now.add(Duration(days: _privacySettings.futureEventsDays))
          : now;

      // Filter calendars based on privacy settings
      final calendarsToSync = calendarIds ?? _privacySettings.allowedCalendarIds;
      if (calendarsToSync.isEmpty && applyPrivacyFilter) {
        // Get all calendars if none specified
        final allCalendars = await getCalendars();
        calendarsToSync.addAll(allCalendars.map((c) => c.id));
      }

      final allEvents = <CalendarEventData>[];

      for (final calendarId in calendarsToSync) {
        if (_privacySettings.allowedCalendarIds.isNotEmpty &&
            !_privacySettings.allowedCalendarIds.contains(calendarId) &&
            applyPrivacyFilter) {
          continue;
        }

        _logger.info('Fetching events from calendar: $calendarId');

        final params = RetrieveEventsParams(
          startDate: startDate,
          endDate: endDate,
        );

        final result = await _plugin.retrieveEvents(calendarId, params);

        if (result.isSuccess && result.data != null) {
          for (final event in result.data!) {
            final eventData = CalendarEventData.fromEvent(event);

            // Apply privacy filters
            if (applyPrivacyFilter && !_shouldIncludeEvent(eventData)) {
              continue;
            }

            // Apply privacy transformations
            final filteredEvent = applyPrivacyFilter
                ? _applyPrivacyTransformations(eventData)
                : eventData;

            allEvents.add(filteredEvent);
          }
        }
      }

      _logger.info('Retrieved ${allEvents.length} events');
      _lastSyncTime = DateTime.now();

      return allEvents;
    } catch (e, stack) {
      _logger.error('Failed to get events', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Create a new event
  Future<String?> createEvent(CalendarEventData eventData) async {
    try {
      if (!await hasPermissions()) {
        _logger.warning('Calendar permissions not granted');
        return null;
      }

      if (eventData.calendarId == null) {
        _logger.error('Calendar ID is required to create event');
        return null;
      }

      _logger.info('Creating event: ${eventData.title}');

      final event = eventData.toEvent();
      final result = await _plugin.createOrUpdateEvent(event);

      if (result?.isSuccess == true && result?.data != null) {
        _logger.info('Event created with ID: ${result!.data}');
        return result.data;
      } else {
        _logger.error('Failed to create event: ${result?.errors}');
        return null;
      }
    } catch (e, stack) {
      _logger.error('Failed to create event', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update an existing event
  Future<bool> updateEvent(CalendarEventData eventData) async {
    try {
      if (!await hasPermissions()) {
        _logger.warning('Calendar permissions not granted');
        return false;
      }

      _logger.info('Updating event: ${eventData.id}');

      final event = eventData.toEvent();
      final result = await _plugin.createOrUpdateEvent(event);

      if (result?.isSuccess == true) {
        _logger.info('Event updated successfully');
        return true;
      } else {
        _logger.error('Failed to update event: ${result?.errors}');
        return false;
      }
    } catch (e, stack) {
      _logger.error('Failed to update event', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String calendarId, String eventId) async {
    try {
      if (!await hasPermissions()) {
        _logger.warning('Calendar permissions not granted');
        return false;
      }

      _logger.info('Deleting event: $eventId from calendar: $calendarId');

      final result = await _plugin.deleteEvent(calendarId, eventId);

      if (result.isSuccess) {
        _logger.info('Event deleted successfully');
        return true;
      } else {
        _logger.error('Failed to delete event: ${result.errors}');
        return false;
      }
    } catch (e, stack) {
      _logger.error('Failed to delete event', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Sync calendar events to local database
  Future<void> syncToDatabase(MediaDatabase database) async {
    try {
      if (!_privacySettings.syncEnabled) {
        _logger.info('Calendar sync is disabled');
        return;
      }

      _logger.info('Starting calendar sync to database');

      final events = await getEvents();

      // Store events in database with source attribution
      for (final event in events) {
        // TODO: Store in database with proper source tracking
        // This would integrate with the journal/note system
        _logger.debug('Would store event: ${event.title}');
      }

      _logger.info('Calendar sync completed: ${events.length} events');
    } catch (e, stack) {
      _logger.error('Failed to sync calendar to database',
                   error: e, stackTrace: stack);
    }
  }

  /// Check if event should be included based on privacy settings
  bool _shouldIncludeEvent(CalendarEventData event) {
    // Check blocked keywords
    for (final keyword in _privacySettings.blockedKeywords) {
      if (event.title.toLowerCase().contains(keyword.toLowerCase()) ||
          (event.description?.toLowerCase().contains(keyword.toLowerCase()) ?? false)) {
        return false;
      }
    }

    return true;
  }

  /// Apply privacy transformations to event data
  CalendarEventData _applyPrivacyTransformations(CalendarEventData event) {
    return CalendarEventData(
      id: event.id,
      calendarId: event.calendarId,
      title: event.title,
      description: _privacySettings.stripDescriptions ? null : event.description,
      startDate: event.startDate,
      endDate: event.endDate,
      isAllDay: event.isAllDay,
      location: event.location,
      attendees: _privacySettings.anonymizeAttendees
          ? event.attendees.map((a) => 'Attendee').toList()
          : event.attendees,
      url: _privacySettings.stripUrls ? null : event.url,
      recurrenceRule: event.recurrenceRule,
      reminders: event.reminders,
      metadata: event.metadata,
    );
  }

  /// Create a journal summary entry as a calendar event
  Future<String?> createJournalSummaryEntry({
    required DateTime date,
    required String title,
    required String content,
    String? calendarId,
  }) async {
    try {
      if (!await hasPermissions()) {
        _logger.warning('Calendar permissions not granted');
        return null;
      }

      // Use first available calendar if none specified
      if (calendarId == null) {
        final calendars = await getCalendars();
        if (calendars.isEmpty) {
          _logger.error('No calendars available for journal entries');
          return null;
        }
        calendarId = calendars.first.id;
      }

      // Create all-day journal entry
      final journalEvent = CalendarEventData(
        id: 'journal_${date.millisecondsSinceEpoch}',
        calendarId: calendarId,
        title: title,
        description: content,
        startDate: DateTime(date.year, date.month, date.day),
        endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
        isAllDay: true,
        metadata: {
          'type': 'journal_summary',
          'created_by': 'aura_one',
          'version': '1.0',
        },
      );

      final eventId = await createEvent(journalEvent);

      if (eventId != null) {
        _logger.info('Created journal summary entry for ${date.toIso8601String()}');
        return eventId;
      } else {
        _logger.error('Failed to create journal summary entry');
        return null;
      }
    } catch (e, stack) {
      _logger.error('Failed to create journal summary entry', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update an existing journal summary entry
  Future<bool> updateJournalSummaryEntry({
    required String eventId,
    required String calendarId,
    required DateTime date,
    required String title,
    required String content,
  }) async {
    try {
      if (!await hasPermissions()) {
        _logger.warning('Calendar permissions not granted');
        return false;
      }

      final updatedEvent = CalendarEventData(
        id: eventId,
        calendarId: calendarId,
        title: title,
        description: content,
        startDate: DateTime(date.year, date.month, date.day),
        endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
        isAllDay: true,
        metadata: {
          'type': 'journal_summary',
          'created_by': 'aura_one',
          'version': '1.0',
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      final success = await updateEvent(updatedEvent);

      if (success) {
        _logger.info('Updated journal summary entry: $eventId');
        return true;
      } else {
        _logger.error('Failed to update journal summary entry');
        return false;
      }
    } catch (e, stack) {
      _logger.error('Failed to update journal summary entry', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Get journal summary entries for a date range
  Future<List<CalendarEventData>> getJournalSummaryEntries({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final allEvents = await getEventsInRange(startDate, endDate);

      // Filter for journal summary entries
      final journalEntries = allEvents.where((event) {
        final metadata = event.metadata;
        return metadata != null &&
               metadata['type'] == 'journal_summary' &&
               metadata['created_by'] == 'aura_one';
      }).toList();

      _logger.info('Found ${journalEntries.length} journal entries');
      return journalEntries;
    } catch (e, stack) {
      _logger.error('Failed to get journal summary entries', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Clear all cached data
  void clearCache() {
    _calendarsCache.clear();
    _eventsCache.clear();
    _lastSyncTime = null;
    _logger.info('Calendar cache cleared');
  }
}
