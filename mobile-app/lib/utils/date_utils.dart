import 'package:flutter/material.dart';

/// Utility functions for handling dates with timezone awareness
class DateTimeUtils {
  /// Convert a local date to UTC midnight for that date in the local timezone
  /// This ensures that a "day" in the user's timezone maps correctly to UTC storage
  static DateTime localDateToUtc(DateTime localDate) {
    // Create a DateTime at midnight in local time
    final localMidnight = DateTime(localDate.year, localDate.month, localDate.day);
    // Convert to UTC - this gives us the UTC time when it's midnight locally
    return localMidnight.toUtc();
  }

  /// Convert a UTC date back to local date
  static DateTime utcDateToLocal(DateTime utcDate) {
    return utcDate.toLocal();
  }

  /// Get the start and end of a day in UTC for a given local date
  /// Returns a tuple of (startUtc, endUtc) that represents the full day in local time
  static (DateTime start, DateTime end) getUtcDayBoundaries(DateTime localDate) {
    // Start of day in local time
    final localStart = DateTime(localDate.year, localDate.month, localDate.day);
    // End of day in local time (23:59:59.999)
    final localEnd = DateTime(localDate.year, localDate.month, localDate.day, 23, 59, 59, 999);

    // Convert both to UTC
    return (localStart.toUtc(), localEnd.toUtc());
  }

  /// Get the local date (without time) from any DateTime
  static DateTime getLocalDateOnly(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Check if two DateTimes are on the same local day
  static bool isSameLocalDay(DateTime date1, DateTime date2) {
    final local1 = date1.toLocal();
    final local2 = date2.toLocal();
    return local1.year == local2.year &&
           local1.month == local2.month &&
           local1.day == local2.day;
  }

  /// Get the start of the current local day in UTC
  static DateTime getTodayStartUtc() {
    final now = DateTime.now();
    return localDateToUtc(now);
  }

  /// Format time of day in local timezone
  static String formatLocalTime(DateTime utcDateTime, {bool use24Hour = true}) {
    final local = utcDateTime.toLocal();
    if (use24Hour) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return '${hour}:${local.minute.toString().padLeft(2, '0')} $period';
    }
  }
}