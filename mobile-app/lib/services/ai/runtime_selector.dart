import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';
import 'ai_journal_generator.dart';
import 'adapter_registry.dart';
import 'capability_matrix.dart';

/// User preferences for AI adapter selection
class AdapterPreferences {
  final bool cloudEnabled;
  final String? preferredAdapter;
  final bool autoDownloadModels;

  AdapterPreferences({
    required this.cloudEnabled,
    this.preferredAdapter,
    this.autoDownloadModels = true,
  });

  factory AdapterPreferences.defaults() {
    return AdapterPreferences(
      cloudEnabled: false, // Cloud disabled by default for privacy
      autoDownloadModels: true,
    );
  }

  factory AdapterPreferences.fromPrefs(SharedPreferences prefs) {
    return AdapterPreferences(
      cloudEnabled: prefs.getBool('ai_cloud_enabled') ?? false,
      preferredAdapter: prefs.getString('ai_preferred_adapter'),
      autoDownloadModels: prefs.getBool('ai_auto_download') ?? true,
    );
  }

  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setBool('ai_cloud_enabled', cloudEnabled);
    if (preferredAdapter != null) {
      await prefs.setString('ai_preferred_adapter', preferredAdapter!);
    } else {
      await prefs.remove('ai_preferred_adapter');
    }
    await prefs.setBool('ai_auto_download', autoDownloadModels);
  }
}

/// Selects the best available AI adapter based on device capabilities and user preferences
class RuntimeSelector {
  static final _logger = AppLogger('RuntimeSelector');
  static final RuntimeSelector _instance = RuntimeSelector._internal();

  final AdapterRegistry _registry = AdapterRegistry();
  final CapabilityMatrix _capabilityMatrix = CapabilityMatrix();

  AIJournalGenerator? _selectedAdapter;
  AdapterPreferences? _preferences;

  factory RuntimeSelector() => _instance;
  RuntimeSelector._internal();

  /// Get user preferences from SharedPreferences
  Future<AdapterPreferences> getPreferences() async {
    if (_preferences != null) {
      return _preferences!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _preferences = AdapterPreferences.fromPrefs(prefs);
      return _preferences!;
    } catch (e, stackTrace) {
      _logger.error('Error loading preferences', error: e, stackTrace: stackTrace);
      _preferences = AdapterPreferences.defaults();
      return _preferences!;
    }
  }

  /// Update user preferences
  Future<void> updatePreferences(AdapterPreferences newPreferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await newPreferences.saveToPrefs(prefs);
      _preferences = newPreferences;

      // Clear selected adapter to force re-selection with new preferences
      _selectedAdapter = null;

      _logger.info('Updated adapter preferences: cloudEnabled=${newPreferences.cloudEnabled}, preferred=${newPreferences.preferredAdapter}');
    } catch (e, stackTrace) {
      _logger.error('Error saving preferences', error: e, stackTrace: stackTrace);
    }
  }

  /// Select the best available adapter based on capabilities and preferences
  Future<AIJournalGenerator?> selectAdapter({bool forceReselect = false}) async {
    if (_selectedAdapter != null && !forceReselect) {
      return _selectedAdapter;
    }

    _logger.info('Selecting best available adapter (forceReselect: $forceReselect)');

    try {
      final preferences = await getPreferences();

      // If user has a preferred adapter, try that first
      if (preferences.preferredAdapter != null) {
        final preferred = _registry.getAdapterByName(preferences.preferredAdapter!);
        if (preferred != null) {
          final isAvailable = await preferred.checkAvailability();
          if (isAvailable) {
            final capabilities = preferred.getCapabilities();

            // Check if cloud adapter and cloud is disabled
            if (capabilities.requiresNetwork && !preferences.cloudEnabled) {
              _logger.warning('Preferred adapter ${preferences.preferredAdapter} requires cloud but cloud is disabled');
            } else {
              _logger.info('Using preferred adapter: ${preferences.preferredAdapter}');
              _selectedAdapter = preferred;
              return _selectedAdapter;
            }
          }
        }
      }

      // Special logic: If cloud is enabled, prefer Cloud Gemini (Tier 4) for narrative generation
      if (preferences.cloudEnabled) {
        _logger.info('Cloud enabled - checking for Cloud Gemini adapter');
        final cloudGemini = _registry.getAdapterByName('CloudGemini');
        if (cloudGemini != null) {
          final isAvailable = await cloudGemini.checkAvailability();
          if (isAvailable) {
            _logger.info('Using Cloud Gemini adapter (user consented to cloud processing)');
            _selectedAdapter = cloudGemini;
            return _selectedAdapter;
          } else {
            _logger.warning('Cloud Gemini not available (likely missing API key or network), falling back');
          }
        }
      }

      // Find best available on-device adapter (Tier 1 or Tier 3)
      _logger.info('Selecting best on-device adapter');
      final adapters = _registry.getAllAdapters();
      AIJournalGenerator? bestOnDevice;
      int highestTier = 0;

      for (final adapter in adapters) {
        final caps = adapter.getCapabilities();
        // Skip cloud adapters when cloudEnabled is false
        if (caps.requiresNetwork && !preferences.cloudEnabled) {
          continue;
        }
        // Skip cloud adapters in general for on-device preference
        if (caps.requiresNetwork) {
          continue;
        }

        final isAvailable = await adapter.checkAvailability();
        if (isAvailable && caps.tierLevel > highestTier) {
          bestOnDevice = adapter;
          highestTier = caps.tierLevel;
        }
      }

      if (bestOnDevice == null) {
        _logger.error('No on-device adapters available!');
        return null;
      }

      final capabilities = bestOnDevice.getCapabilities();
      _logger.info('Selected on-device adapter: ${capabilities.adapterName} (tier ${capabilities.tierLevel})');
      _selectedAdapter = bestOnDevice;
      return _selectedAdapter;
    } catch (e, stackTrace) {
      _logger.error('Error selecting adapter', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get currently selected adapter without reselecting
  AIJournalGenerator? getCurrentAdapter() {
    return _selectedAdapter;
  }

  /// Clear the selected adapter (forces reselection on next selectAdapter call)
  void clearSelection() {
    _selectedAdapter = null;
    _logger.debug('Cleared adapter selection');
  }

  /// Get all available adapters with their current availability status
  Future<List<AdapterInfo>> getAvailableAdapters() async {
    final adapters = _registry.getAllAdapters();
    final results = <AdapterInfo>[];

    for (final adapter in adapters) {
      final capabilities = adapter.getCapabilities();
      final isAvailable = await adapter.checkAvailability();

      results.add(AdapterInfo(
        name: capabilities.adapterName,
        tierLevel: capabilities.tierLevel,
        isAvailable: isAvailable,
        capabilities: capabilities,
      ));
    }

    return results;
  }
}

/// Information about an adapter's availability
class AdapterInfo {
  final String name;
  final int tierLevel;
  final bool isAvailable;
  final AICapabilities capabilities;

  AdapterInfo({
    required this.name,
    required this.tierLevel,
    required this.isAvailable,
    required this.capabilities,
  });
}
