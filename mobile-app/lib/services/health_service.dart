// Stub implementation for APK size optimization
// Original health service temporarily disabled to reduce APK size

class HealthService {
  Future<Map<String, dynamic>> getHealthData() async {
    return {
      'health_data': 'Health data collection temporarily disabled for optimized build',
      'disabled': true,
    };
  }

  Future<void> requestPermissions() async {
    // Stub - no permissions needed in optimized build
  }

  Future<bool> get isAvailable async => false;
}