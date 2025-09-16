import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/privacy_settings.dart';

/// Service for managing privacy settings and presets
class PrivacyService {
  static const String _storageKey = 'privacy_settings';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Get current privacy settings
  Future<PrivacySettings> getPrivacySettings() async {
    try {
      final settingsJson = await _storage.read(key: _storageKey);
      if (settingsJson == null) {
        // Return default balanced settings for first time users
        return PrivacySettings.forPreset(PrivacyPresetLevel.balanced);
      }

      final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
      return PrivacySettings.fromJson(settingsMap);
    } catch (e) {
      // If there's an error reading settings, return default
      return PrivacySettings.forPreset(PrivacyPresetLevel.balanced);
    }
  }

  /// Save privacy settings securely
  Future<void> savePrivacySettings(PrivacySettings settings) async {
    try {
      final updatedSettings = settings.copyWith(
        lastUpdated: DateTime.now(),
        updatedBy: 'user',
      );

      final settingsJson = jsonEncode(updatedSettings.toJson());
      await _storage.write(key: _storageKey, value: settingsJson);
    } catch (e) {
      throw PrivacyServiceException('Failed to save privacy settings: $e');
    }
  }

  /// Apply a privacy preset
  Future<PrivacySettings> applyPreset(PrivacyPresetLevel presetLevel) async {
    try {
      final newSettings = PrivacySettings.forPreset(presetLevel).copyWith(
        lastUpdated: DateTime.now(),
        updatedBy: 'preset_$presetLevel',
      );

      await savePrivacySettings(newSettings);
      return newSettings;
    } catch (e) {
      throw PrivacyServiceException('Failed to apply preset: $e');
    }
  }

  /// Get all available privacy presets
  List<PrivacyPreset> getAvailablePresets() {
    return [
      PrivacyPreset(
        level: PrivacyPresetLevel.minimal,
        title: 'Maximum Privacy',
        description: 'Location off, minimal permissions, 1 week retention',
        features: [
          'Location tracking: OFF',
          'Data retention: 1 Week',
          'All permissions: OFF',
          'Biometric lock: ON',
          'App lock: ON',
          'Local-only mode: ON',
        ],
        settings: PrivacySettings.forPreset(PrivacyPresetLevel.minimal),
      ),
      PrivacyPreset(
        level: PrivacyPresetLevel.balanced,
        title: 'Balanced',
        description: 'Approximate location, essential permissions, 6 month retention',
        features: [
          'Location tracking: Approximate',
          'Data retention: 6 Months',
          'Essential permissions: ON',
          'Crash reporting: ON',
          'Local-only mode: ON',
          'Automatic cleanup: ON',
        ],
        settings: PrivacySettings.forPreset(PrivacyPresetLevel.balanced),
      ),
      PrivacyPreset(
        level: PrivacyPresetLevel.maximum,
        title: 'Full Features',
        description: 'Precise location, all permissions, 1 year retention',
        features: [
          'Location tracking: Precise',
          'Data retention: 1 Year',
          'All permissions: ON',
          'Analytics: ON',
          'Cloud backup: ON',
          'Full feature access: ON',
        ],
        settings: PrivacySettings.forPreset(PrivacyPresetLevel.maximum),
      ),
    ];
  }

  /// Get a specific preset by level
  PrivacyPreset? getPreset(PrivacyPresetLevel level) {
    return getAvailablePresets()
        .where((preset) => preset.level == level)
        .firstOrNull;
  }

  /// Update individual privacy setting
  Future<PrivacySettings> updateSetting<T>(
    PrivacySettings currentSettings,
    T Function(PrivacySettings) getter,
    PrivacySettings Function(PrivacySettings, T) setter,
    T newValue,
  ) async {
    try {
      final updatedSettings = setter(currentSettings, newValue).copyWith(
        isCustomized: true,
        lastUpdated: DateTime.now(),
        updatedBy: 'user',
      );

      await savePrivacySettings(updatedSettings);
      return updatedSettings;
    } catch (e) {
      throw PrivacyServiceException('Failed to update setting: $e');
    }
  }

  /// Reset to default settings
  Future<PrivacySettings> resetToDefaults() async {
    return await applyPreset(PrivacyPresetLevel.balanced);
  }

  /// Check if current settings match a preset
  bool isPresetMatch(PrivacySettings current, PrivacyPresetLevel presetLevel) {
    final presetSettings = PrivacySettings.forPreset(presetLevel);

    // Compare all relevant fields (ignoring metadata)
    return current.locationPrecision == presetSettings.locationPrecision &&
           current.locationTrackingEnabled == presetSettings.locationTrackingEnabled &&
           current.dataRetention == presetSettings.dataRetention &&
           current.automaticCleanupEnabled == presetSettings.automaticCleanupEnabled &&
           current.photoLibraryPermission == presetSettings.photoLibraryPermission &&
           current.cameraPermission == presetSettings.cameraPermission &&
           current.microphonePermission == presetSettings.microphonePermission &&
           current.calendarPermission == presetSettings.calendarPermission &&
           current.healthPermission == presetSettings.healthPermission &&
           current.notificationPermission == presetSettings.notificationPermission &&
           current.analyticsEnabled == presetSettings.analyticsEnabled &&
           current.crashReportingEnabled == presetSettings.crashReportingEnabled &&
           current.localOnlyMode == presetSettings.localOnlyMode &&
           current.cloudBackupEnabled == presetSettings.cloudBackupEnabled &&
           current.biometricLockEnabled == presetSettings.biometricLockEnabled &&
           current.appLockEnabled == presetSettings.appLockEnabled;
  }

  /// Validate privacy settings
  List<String> validateSettings(PrivacySettings settings) {
    final issues = <String>[];

    // Location validation
    if (settings.locationTrackingEnabled &&
        settings.locationPrecision == LocationPrecision.off) {
      issues.add('Location tracking is enabled but precision is set to off');
    }

    // Security validation
    if (settings.presetLevel == PrivacyPresetLevel.minimal) {
      if (!settings.appLockEnabled && !settings.biometricLockEnabled) {
        issues.add('Maximum privacy preset should have some form of app lock enabled');
      }
    }

    // Data retention validation
    if (settings.dataRetention == DataRetentionPeriod.forever &&
        !settings.automaticCleanupEnabled) {
      issues.add('Infinite data retention without cleanup may consume excessive storage');
    }

    // Cloud backup validation
    if (settings.cloudBackupEnabled && settings.localOnlyMode) {
      issues.add('Cloud backup cannot be enabled in local-only mode');
    }

    return issues;
  }

  /// Clear all privacy data (for user data deletion)
  Future<void> clearAllPrivacyData() async {
    try {
      await _storage.delete(key: _storageKey);
    } catch (e) {
      throw PrivacyServiceException('Failed to clear privacy data: $e');
    }
  }

  /// Export privacy settings for backup
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final settings = await getPrivacySettings();
      return {
        'privacy_settings': settings.toJson(),
        'exported_at': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    } catch (e) {
      throw PrivacyServiceException('Failed to export settings: $e');
    }
  }

  /// Import privacy settings from backup
  Future<PrivacySettings> importSettings(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('privacy_settings')) {
        throw PrivacyServiceException('Invalid backup data format');
      }

      final settingsData = data['privacy_settings'] as Map<String, dynamic>;
      final settings = PrivacySettings.fromJson(settingsData);

      // Validate imported settings
      final issues = validateSettings(settings);
      if (issues.isNotEmpty) {
        throw PrivacyServiceException('Invalid settings: ${issues.join(', ')}');
      }

      await savePrivacySettings(settings);
      return settings;
    } catch (e) {
      throw PrivacyServiceException('Failed to import settings: $e');
    }
  }
}

/// Exception thrown by privacy service operations
class PrivacyServiceException implements Exception {
  final String message;
  const PrivacyServiceException(this.message);

  @override
  String toString() => 'PrivacyServiceException: $message';
}