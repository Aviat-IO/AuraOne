import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Activity types for tracking
enum ActivityType {
  location,
  photo,
  calendar,
  health,
  bluetooth,
  analysis,
  sync,
}

/// Represents a data activity event
class DataActivity {
  final ActivityType type;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  DataActivity({
    required this.type,
    required this.action,
    required this.timestamp,
    this.metadata,
  });

  /// Get relative time description
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'More than a week ago';
    }
  }
}

/// Tracks data collection and processing activities
class DataActivityTracker extends StateNotifier<List<DataActivity>> {
  static const int maxActivities = 100;

  DataActivityTracker() : super([]);

  /// Add a new activity
  void addActivity(ActivityType type, String action, {Map<String, dynamic>? metadata}) {
    final activity = DataActivity(
      type: type,
      action: action,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    state = [
      activity,
      ...state.take(maxActivities - 1),
    ];
  }

  /// Get recent activities
  List<DataActivity> getRecentActivities({int limit = 10}) {
    return state.take(limit).toList();
  }

  /// Get activities by type
  List<DataActivity> getActivitiesByType(ActivityType type, {int limit = 10}) {
    return state
        .where((activity) => activity.type == type)
        .take(limit)
        .toList();
  }

  /// Get activities within a time range
  List<DataActivity> getActivitiesInRange(DateTime start, DateTime end) {
    return state
        .where((activity) =>
            activity.timestamp.isAfter(start) &&
            activity.timestamp.isBefore(end))
        .toList();
  }

  /// Clear all activities
  void clearActivities() {
    state = [];
  }

  /// Get activity count by type for the last period
  Map<ActivityType, int> getActivityCountByType({Duration period = const Duration(hours: 24)}) {
    final cutoff = DateTime.now().subtract(period);
    final counts = <ActivityType, int>{};

    for (final activity in state) {
      if (activity.timestamp.isAfter(cutoff)) {
        counts[activity.type] = (counts[activity.type] ?? 0) + 1;
      }
    }

    return counts;
  }
}

/// Provider for the data activity tracker
final dataActivityTrackerProvider = StateNotifierProvider<DataActivityTracker, List<DataActivity>>(
  (ref) => DataActivityTracker(),
);

/// Provider for recent activities
final recentActivitiesProvider = Provider<List<DataActivity>>((ref) {
  final activities = ref.watch(dataActivityTrackerProvider);
  return activities.take(10).toList();
});

/// Provider for activity counts by type
final activityCountsByTypeProvider = Provider<Map<ActivityType, int>>((ref) {
  final tracker = ref.read(dataActivityTrackerProvider.notifier);
  return tracker.getActivityCountByType();
});