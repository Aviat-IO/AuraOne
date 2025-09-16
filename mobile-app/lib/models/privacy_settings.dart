/// Enumeration of privacy preset levels
enum PrivacyPresetLevel {
  minimal('minimal', 'Maximum Privacy'),
  balanced('balanced', 'Balanced'),
  maximum('maximum', 'Full Features');

  const PrivacyPresetLevel(this.value, this.displayName);

  final String value;
  final String displayName;
}

/// Location tracking precision levels
enum LocationPrecision {
  off('off', 'Off'),
  approximate('approximate', 'Approximate (City level)'),
  balanced('balanced', 'Balanced (Street level)'),
  precise('precise', 'Precise (GPS accurate)');

  const LocationPrecision(this.value, this.displayName);

  final String value;
  final String displayName;
}

/// Data retention period options
enum DataRetentionPeriod {
  week('week', '1 Week', Duration(days: 7)),
  month('month', '1 Month', Duration(days: 30)),
  sixMonths('sixMonths', '6 Months', Duration(days: 180)),
  year('year', '1 Year', Duration(days: 365)),
  forever('forever', 'Forever', Duration(days: 36500)); // 100 years

  const DataRetentionPeriod(this.value, this.displayName, this.duration);

  final String value;
  final String displayName;
  final Duration duration;
}

/// Comprehensive privacy settings configuration
class PrivacySettings {
  // General settings
  final PrivacyPresetLevel presetLevel;
  final bool isCustomized;

  // Location settings
  final LocationPrecision locationPrecision;
  final bool locationTrackingEnabled;

  // Data retention settings
  final DataRetentionPeriod dataRetention;
  final bool automaticCleanupEnabled;

  // Permission settings
  final bool photoLibraryPermission;
  final bool cameraPermission;
  final bool microphonePermission;
  final bool calendarPermission;
  final bool healthPermission;
  final bool notificationPermission;

  // Advanced privacy settings
  final bool analyticsEnabled;
  final bool crashReportingEnabled;
  final bool localOnlyMode;
  final bool cloudBackupEnabled;

  // Security settings
  final bool biometricLockEnabled;
  final bool appLockEnabled;
  final int autoLockTimeoutMinutes;

  // Metadata
  final DateTime? lastUpdated;
  final String updatedBy;

  const PrivacySettings({
    this.presetLevel = PrivacyPresetLevel.balanced,
    this.isCustomized = false,
    this.locationPrecision = LocationPrecision.balanced,
    this.locationTrackingEnabled = true,
    this.dataRetention = DataRetentionPeriod.sixMonths,
    this.automaticCleanupEnabled = true,
    this.photoLibraryPermission = false,
    this.cameraPermission = false,
    this.microphonePermission = false,
    this.calendarPermission = false,
    this.healthPermission = false,
    this.notificationPermission = false,
    this.analyticsEnabled = false,
    this.crashReportingEnabled = false,
    this.localOnlyMode = true,
    this.cloudBackupEnabled = false,
    this.biometricLockEnabled = false,
    this.appLockEnabled = false,
    this.autoLockTimeoutMinutes = 5,
    this.lastUpdated,
    this.updatedBy = 'system',
  });

  /// Create default settings for a specific preset level
  factory PrivacySettings.forPreset(PrivacyPresetLevel preset) {
    switch (preset) {
      case PrivacyPresetLevel.minimal:
        return const PrivacySettings(
          presetLevel: PrivacyPresetLevel.minimal,
          isCustomized: false,
          locationPrecision: LocationPrecision.off,
          locationTrackingEnabled: false,
          dataRetention: DataRetentionPeriod.week,
          automaticCleanupEnabled: true,
          photoLibraryPermission: false,
          cameraPermission: false,
          microphonePermission: false,
          calendarPermission: false,
          healthPermission: false,
          notificationPermission: false,
          analyticsEnabled: false,
          crashReportingEnabled: false,
          localOnlyMode: true,
          cloudBackupEnabled: false,
          biometricLockEnabled: true,
          appLockEnabled: true,
          autoLockTimeoutMinutes: 1,
        );

      case PrivacyPresetLevel.balanced:
        return const PrivacySettings(
          presetLevel: PrivacyPresetLevel.balanced,
          isCustomized: false,
          locationPrecision: LocationPrecision.approximate,
          locationTrackingEnabled: true,
          dataRetention: DataRetentionPeriod.sixMonths,
          automaticCleanupEnabled: true,
          photoLibraryPermission: true,
          cameraPermission: true,
          microphonePermission: false,
          calendarPermission: true,
          healthPermission: false,
          notificationPermission: true,
          analyticsEnabled: false,
          crashReportingEnabled: true,
          localOnlyMode: true,
          cloudBackupEnabled: false,
          biometricLockEnabled: false,
          appLockEnabled: false,
          autoLockTimeoutMinutes: 5,
        );

      case PrivacyPresetLevel.maximum:
        return const PrivacySettings(
          presetLevel: PrivacyPresetLevel.maximum,
          isCustomized: false,
          locationPrecision: LocationPrecision.precise,
          locationTrackingEnabled: true,
          dataRetention: DataRetentionPeriod.year,
          automaticCleanupEnabled: true,
          photoLibraryPermission: true,
          cameraPermission: true,
          microphonePermission: true,
          calendarPermission: true,
          healthPermission: true,
          notificationPermission: true,
          analyticsEnabled: true,
          crashReportingEnabled: true,
          localOnlyMode: false,
          cloudBackupEnabled: true,
          biometricLockEnabled: false,
          appLockEnabled: false,
          autoLockTimeoutMinutes: 30,
        );
    }
  }

  /// Create a copy of this settings with modified values
  PrivacySettings copyWith({
    PrivacyPresetLevel? presetLevel,
    bool? isCustomized,
    LocationPrecision? locationPrecision,
    bool? locationTrackingEnabled,
    DataRetentionPeriod? dataRetention,
    bool? automaticCleanupEnabled,
    bool? photoLibraryPermission,
    bool? cameraPermission,
    bool? microphonePermission,
    bool? calendarPermission,
    bool? healthPermission,
    bool? notificationPermission,
    bool? analyticsEnabled,
    bool? crashReportingEnabled,
    bool? localOnlyMode,
    bool? cloudBackupEnabled,
    bool? biometricLockEnabled,
    bool? appLockEnabled,
    int? autoLockTimeoutMinutes,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return PrivacySettings(
      presetLevel: presetLevel ?? this.presetLevel,
      isCustomized: isCustomized ?? this.isCustomized,
      locationPrecision: locationPrecision ?? this.locationPrecision,
      locationTrackingEnabled: locationTrackingEnabled ?? this.locationTrackingEnabled,
      dataRetention: dataRetention ?? this.dataRetention,
      automaticCleanupEnabled: automaticCleanupEnabled ?? this.automaticCleanupEnabled,
      photoLibraryPermission: photoLibraryPermission ?? this.photoLibraryPermission,
      cameraPermission: cameraPermission ?? this.cameraPermission,
      microphonePermission: microphonePermission ?? this.microphonePermission,
      calendarPermission: calendarPermission ?? this.calendarPermission,
      healthPermission: healthPermission ?? this.healthPermission,
      notificationPermission: notificationPermission ?? this.notificationPermission,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashReportingEnabled: crashReportingEnabled ?? this.crashReportingEnabled,
      localOnlyMode: localOnlyMode ?? this.localOnlyMode,
      cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      autoLockTimeoutMinutes: autoLockTimeoutMinutes ?? this.autoLockTimeoutMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'presetLevel': presetLevel.value,
    'isCustomized': isCustomized,
    'locationPrecision': locationPrecision.value,
    'locationTrackingEnabled': locationTrackingEnabled,
    'dataRetention': dataRetention.value,
    'automaticCleanupEnabled': automaticCleanupEnabled,
    'photoLibraryPermission': photoLibraryPermission,
    'cameraPermission': cameraPermission,
    'microphonePermission': microphonePermission,
    'calendarPermission': calendarPermission,
    'healthPermission': healthPermission,
    'notificationPermission': notificationPermission,
    'analyticsEnabled': analyticsEnabled,
    'crashReportingEnabled': crashReportingEnabled,
    'localOnlyMode': localOnlyMode,
    'cloudBackupEnabled': cloudBackupEnabled,
    'biometricLockEnabled': biometricLockEnabled,
    'appLockEnabled': appLockEnabled,
    'autoLockTimeoutMinutes': autoLockTimeoutMinutes,
    'lastUpdated': lastUpdated?.toIso8601String(),
    'updatedBy': updatedBy,
  };

  /// Create from JSON
  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      presetLevel: PrivacyPresetLevel.values.firstWhere(
        (e) => e.value == json['presetLevel'],
        orElse: () => PrivacyPresetLevel.balanced,
      ),
      isCustomized: json['isCustomized'] ?? false,
      locationPrecision: LocationPrecision.values.firstWhere(
        (e) => e.value == json['locationPrecision'],
        orElse: () => LocationPrecision.balanced,
      ),
      locationTrackingEnabled: json['locationTrackingEnabled'] ?? true,
      dataRetention: DataRetentionPeriod.values.firstWhere(
        (e) => e.value == json['dataRetention'],
        orElse: () => DataRetentionPeriod.sixMonths,
      ),
      automaticCleanupEnabled: json['automaticCleanupEnabled'] ?? true,
      photoLibraryPermission: json['photoLibraryPermission'] ?? false,
      cameraPermission: json['cameraPermission'] ?? false,
      microphonePermission: json['microphonePermission'] ?? false,
      calendarPermission: json['calendarPermission'] ?? false,
      healthPermission: json['healthPermission'] ?? false,
      notificationPermission: json['notificationPermission'] ?? false,
      analyticsEnabled: json['analyticsEnabled'] ?? false,
      crashReportingEnabled: json['crashReportingEnabled'] ?? false,
      localOnlyMode: json['localOnlyMode'] ?? true,
      cloudBackupEnabled: json['cloudBackupEnabled'] ?? false,
      biometricLockEnabled: json['biometricLockEnabled'] ?? false,
      appLockEnabled: json['appLockEnabled'] ?? false,
      autoLockTimeoutMinutes: json['autoLockTimeoutMinutes'] ?? 5,
      lastUpdated: json['lastUpdated'] != null
        ? DateTime.parse(json['lastUpdated'])
        : null,
      updatedBy: json['updatedBy'] ?? 'system',
    );
  }
}

/// Privacy preset configuration details
class PrivacyPreset {
  final PrivacyPresetLevel level;
  final String title;
  final String description;
  final List<String> features;
  final PrivacySettings settings;

  const PrivacyPreset({
    required this.level,
    required this.title,
    required this.description,
    required this.features,
    required this.settings,
  });

  Map<String, dynamic> toJson() => {
    'level': level.value,
    'title': title,
    'description': description,
    'features': features,
    'settings': settings.toJson(),
  };

  factory PrivacyPreset.fromJson(Map<String, dynamic> json) {
    return PrivacyPreset(
      level: PrivacyPresetLevel.values.firstWhere(
        (e) => e.value == json['level'],
        orElse: () => PrivacyPresetLevel.balanced,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      settings: PrivacySettings.fromJson(json['settings'] ?? {}),
    );
  }
}