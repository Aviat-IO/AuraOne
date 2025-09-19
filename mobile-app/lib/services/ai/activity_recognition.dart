// Stub implementation for APK size optimization
// Original activity recognition temporarily disabled to reduce APK size

enum ActivityType {
  walking,
  cycling,
  driving,
  stationary,
  unknown,
}

class ActivityRecognitionResult {
  final ActivityType activity;
  final DateTime timestamp;
  final double confidence;

  ActivityRecognitionResult({
    required this.activity,
    required this.timestamp,
    required this.confidence,
  });
}

class ActivityRecognitionService {
  Future<ActivityRecognitionResult> recognizeActivity() async {
    return ActivityRecognitionResult(
      activity: ActivityType.unknown,
      timestamp: DateTime.now(),
      confidence: 0.0,
    );
  }

  Future<List<ActivityRecognitionResult>> getActivitiesInRange(
    DateTime start,
    DateTime end,
  ) async {
    return [];
  }
}