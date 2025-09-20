import 'package:intl/intl.dart';

/// Utility class for time and date formatting
class TimeUtils {
  /// Format a DateTime to a readable date string (e.g., "Jan 15, 2025")
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format a DateTime to a month and year string (e.g., "January 2025")
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Format a DateTime to a short date string (e.g., "1/15/25")
  static String formatShortDate(DateTime date) {
    return DateFormat('M/d/yy').format(date);
  }

  /// Format a DateTime to a day of week string (e.g., "Monday")
  static String formatDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Format a DateTime to a short day of week string (e.g., "Mon")
  static String formatShortDayOfWeek(DateTime date) {
    return DateFormat('E').format(date);
  }

  /// Format a DateTime to a time string (e.g., "2:30 PM")
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Format a DateTime to a full date and time string (e.g., "Jan 15, 2025 at 2:30 PM")
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} at ${formatTime(date)}';
  }

  /// Get the start of the week for a given date (Monday as the first day)
  static DateTime getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Get the end of the week for a given date (Sunday as the last day)
  static DateTime getWeekEnd(DateTime date) {
    final weekStart = getWeekStart(date);
    return weekStart.add(const Duration(days: 6));
  }

  /// Get the start of the month for a given date
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get the end of the month for a given date
  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get a relative time description (e.g., "2 days ago", "Tomorrow")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (isSameDay(date, now)) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays == -1) {
      return 'Tomorrow';
    } else if (difference.inDays > 0) {
      if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      }
    } else {
      final futureDays = difference.inDays.abs();
      if (futureDays < 7) {
        return 'In $futureDays days';
      } else if (futureDays < 30) {
        final weeks = (futureDays / 7).floor();
        return weeks == 1 ? 'In 1 week' : 'In $weeks weeks';
      } else {
        final months = (futureDays / 30).floor();
        return months == 1 ? 'In 1 month' : 'In $months months';
      }
    }
  }
}