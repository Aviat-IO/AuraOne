import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/privacy_settings.dart';
import '../services/privacy_service.dart';

/// Provider for the privacy service singleton
final privacyServiceProvider = Provider<PrivacyService>((ref) {
  return PrivacyService();
});

/// Provider for current privacy settings
final privacySettingsProvider = FutureProvider<PrivacySettings>((ref) async {
  final privacyService = ref.watch(privacyServiceProvider);
  return await privacyService.getPrivacySettings();
});

/// Provider for available privacy presets
final privacyPresetsProvider = Provider<List<PrivacyPreset>>((ref) {
  final privacyService = ref.watch(privacyServiceProvider);
  return privacyService.getAvailablePresets();
});

/// Provider for a specific privacy preset
final privacyPresetProvider = Provider.family<PrivacyPreset?, PrivacyPresetLevel>((ref, level) {
  final privacyService = ref.watch(privacyServiceProvider);
  return privacyService.getPreset(level);
});

/// State notifier for managing privacy settings
class PrivacySettingsNotifier extends StateNotifier<AsyncValue<PrivacySettings>> {
  PrivacySettingsNotifier(this._privacyService) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  final PrivacyService _privacyService;

  Future<void> _loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _privacyService.getPrivacySettings();
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Apply a privacy preset
  Future<void> applyPreset(PrivacyPresetLevel presetLevel) async {
    try {
      state = const AsyncValue.loading();
      final newSettings = await _privacyService.applyPreset(presetLevel);
      state = AsyncValue.data(newSettings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update location precision
  Future<void> updateLocationPrecision(LocationPrecision precision) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      state = const AsyncValue.loading();
      final newSettings = await _privacyService.updateSetting<LocationPrecision>(
        currentSettings,
        (settings) => settings.locationPrecision,
        (settings, value) => settings.copyWith(
          locationPrecision: value,
          locationTrackingEnabled: value != LocationPrecision.off,
        ),
        precision,
      );
      state = AsyncValue.data(newSettings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update data retention period
  Future<void> updateDataRetention(DataRetentionPeriod period) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      state = const AsyncValue.loading();
      final newSettings = await _privacyService.updateSetting<DataRetentionPeriod>(
        currentSettings,
        (settings) => settings.dataRetention,
        (settings, value) => settings.copyWith(dataRetention: value),
        period,
      );
      state = AsyncValue.data(newSettings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Toggle a permission setting
  Future<void> togglePermission(String permissionType, bool enabled) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      state = const AsyncValue.loading();

      PrivacySettings updatedSettings;
      switch (permissionType) {
        case 'photoLibrary':
          updatedSettings = currentSettings.copyWith(
            photoLibraryPermission: enabled,
            isCustomized: true,
            lastUpdated: DateTime.now(),
            updatedBy: 'user',
          );
          break;
        case 'camera':
          updatedSettings = currentSettings.copyWith(
            cameraPermission: enabled,
            isCustomized: true,
            lastUpdated: DateTime.now(),
            updatedBy: 'user',
          );
          break;
        case 'microphone':
          updatedSettings = currentSettings.copyWith(
            microphonePermission: enabled,
            isCustomized: true,
            lastUpdated: DateTime.now(),
            updatedBy: 'user',
          );
          break;
        case 'calendar':
          updatedSettings = currentSettings.copyWith(
            calendarPermission: enabled,
            isCustomized: true,
            lastUpdated: DateTime.now(),
            updatedBy: 'user',
          );
          break;
        case 'health':
          updatedSettings = currentSettings.copyWith(
            healthPermission: enabled,
            isCustomized: true,
            lastUpdated: DateTime.now(),
            updatedBy: 'user',
          );
          break;
        case 'notification':
          updatedSettings = currentSettings.copyWith(
            notificationPermission: enabled,
            isCustomized: true,
            lastUpdated: DateTime.now(),
            updatedBy: 'user',
          );
          break;
        default:
          throw ArgumentError('Unknown permission type: $permissionType');
      }

      await _privacyService.savePrivacySettings(updatedSettings);
      state = AsyncValue.data(updatedSettings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Toggle automatic cleanup
  Future<void> toggleAutomaticCleanup(bool enabled) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      state = const AsyncValue.loading();
      final newSettings = await _privacyService.updateSetting<bool>(
        currentSettings,
        (settings) => settings.automaticCleanupEnabled,
        (settings, value) => settings.copyWith(automaticCleanupEnabled: value),
        enabled,
      );
      state = AsyncValue.data(newSettings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Toggle app lock
  Future<void> toggleAppLock(bool enabled) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      state = const AsyncValue.loading();
      final newSettings = await _privacyService.updateSetting<bool>(
        currentSettings,
        (settings) => settings.appLockEnabled,
        (settings, value) => settings.copyWith(appLockEnabled: value),
        enabled,
      );
      state = AsyncValue.data(newSettings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Toggle biometric lock
  Future<void> toggleBiometricLock(bool enabled) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      state = const AsyncValue.loading();
      final newSettings = await _privacyService.updateSetting<bool>(
        currentSettings,
        (settings) => settings.biometricLockEnabled,
        (settings, value) => settings.copyWith(biometricLockEnabled: value),
        enabled,
      );
      state = AsyncValue.data(newSettings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    try {
      state = const AsyncValue.loading();
      final defaultSettings = await _privacyService.resetToDefaults();
      state = AsyncValue.data(defaultSettings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh settings from storage
  Future<void> refresh() async {
    await _loadSettings();
  }

  /// Validate current settings
  List<String> validateCurrentSettings() {
    final currentSettings = state.value;
    if (currentSettings == null) return [];

    return _privacyService.validateSettings(currentSettings);
  }

  /// Check if current settings match a preset
  bool isPresetMatch(PrivacyPresetLevel presetLevel) {
    final currentSettings = state.value;
    if (currentSettings == null) return false;

    return _privacyService.isPresetMatch(currentSettings, presetLevel);
  }
}

/// Provider for the privacy settings state notifier
final privacySettingsNotifierProvider = StateNotifierProvider<PrivacySettingsNotifier, AsyncValue<PrivacySettings>>((ref) {
  final privacyService = ref.watch(privacyServiceProvider);
  return PrivacySettingsNotifier(privacyService);
});

/// Provider to check if settings match a specific preset
final presetMatchProvider = Provider.family<bool, PrivacyPresetLevel>((ref, presetLevel) {
  final notifier = ref.watch(privacySettingsNotifierProvider.notifier);
  return notifier.isPresetMatch(presetLevel);
});

/// Provider for privacy settings validation issues
final privacyValidationProvider = Provider<List<String>>((ref) {
  final notifier = ref.watch(privacySettingsNotifierProvider.notifier);
  return notifier.validateCurrentSettings();
});

/// Provider for privacy settings export data
final privacyExportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final privacyService = ref.watch(privacyServiceProvider);
  return await privacyService.exportSettings();
});

/// Provider to check if any permissions are enabled
final hasEnabledPermissionsProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(privacySettingsNotifierProvider);

  return settingsAsync.when(
    data: (settings) => settings.photoLibraryPermission ||
                        settings.cameraPermission ||
                        settings.microphonePermission ||
                        settings.calendarPermission ||
                        settings.healthPermission ||
                        settings.notificationPermission,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider to check if location tracking is enabled
final isLocationTrackingEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(privacySettingsNotifierProvider);

  return settingsAsync.when(
    data: (settings) => settings.locationTrackingEnabled,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for smart place recognition setting (enabled by default)
final smartPlaceRecognitionProvider = StateProvider<bool>((ref) {
  // Load from SharedPreferences in the future if needed
  return true; // Enabled by default
});