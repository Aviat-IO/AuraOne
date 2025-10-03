import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../services/data_attribution_service.dart';  // Temporarily disabled for APK size optimization
import '../services/calendar_service.dart';
// import '../services/health_service.dart';  // Temporarily disabled for APK size optimization
// import '../services/ble_scanning_service.dart';  // Temporarily disabled for APK size optimization
import '../services/ai/hybrid_ai_service.dart';  // Privacy-first hybrid AI service
import './settings_providers.dart';

// Data Attribution Service Provider - Temporarily disabled
// final dataAttributionServiceProvider = Provider<DataAttributionService>((ref) {
//   return DataAttributionService();
// });

// Calendar Service Provider
final calendarServiceProvider = Provider<CalendarService>((ref) {
  final service = CalendarService();

  // Sync calendar settings with privacy settings
  final calendarSettings = ref.watch(calendarSettingsProvider);
  final currentPrivacySettings = service.privacySettings;

  // Update privacy settings with enabled calendars
  service.updatePrivacySettings(
    currentPrivacySettings.copyWith(
      syncEnabled: calendarSettings.enabledCalendarIds.isNotEmpty,
      allowedCalendarIds: calendarSettings.enabledCalendarIds,
    ),
  );

  return service;
});

// Health Service Provider - Temporarily disabled
// final healthServiceProvider = Provider<HealthService>((ref) {
//   return HealthService();
// });

// BLE Service Provider - Temporarily disabled
// final bleServiceProvider = Provider<BleScanningService>((ref) {
//   return BleScanningService();
// });

// AI Service Provider - Privacy-first hybrid service with on-device preference
final aiServiceProvider = Provider<HybridAIService>((ref) {
  return HybridAIService();
});

