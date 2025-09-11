import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that updates current time every 10 seconds for reactive time displays
final currentTimeProvider =
    StateNotifierProvider<CurrentTimeNotifier, DateTime>((ref) {
      return CurrentTimeNotifier();
    });

class CurrentTimeNotifier extends StateNotifier<DateTime> {
  late final Timer _timer;

  CurrentTimeNotifier() : super(DateTime.now()) {
    // Update every 10 seconds to keep "time ago" displays fresh
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      state = DateTime.now();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class TimeUtils {
  /// Formats a timestamp into a human-readable relative time string
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Formats timestamp relative to a specific current time (useful for testing)
  static String formatTimestampRelativeTo(
    DateTime timestamp,
    DateTime currentTime,
  ) {
    final difference = currentTime.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Formats time in HH:MM format
  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formats date and time in a readable format
  static String formatDateTime(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${formatTime(dateTime)}';
  }

  /// Formats date in readable format
  static String formatDate(DateTime dateTime) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}

/// A reactive text widget that automatically updates time-relative displays
class TimeAgoText extends ConsumerWidget {
  final DateTime timestamp;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TimeAgoText(
    this.timestamp, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current time provider to automatically rebuild when time changes
    final currentTime = ref.watch(currentTimeProvider);

    return Text(
      TimeUtils.formatTimestampRelativeTo(timestamp, currentTime),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
