import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_attribution_service.dart';
import '../services/calendar_service.dart';
import '../services/health_service.dart';
import '../services/ble_scanning_service.dart';
import '../services/ai_service.dart';
import '../services/background_data_service.dart';

// Data Attribution Service Provider
final dataAttributionServiceProvider = Provider<DataAttributionService>((ref) {
  return DataAttributionService();
});

// Calendar Service Provider
final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

// Health Service Provider
final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

// BLE Service Provider
final bleServiceProvider = Provider<BleScanningService>((ref) {
  return BleScanningService();
});

// AI Service Provider
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

// Background Data Service Provider
final backgroundDataServiceProvider = Provider<BackgroundDataService>((ref) {
  return BackgroundDataService(ref);
});
