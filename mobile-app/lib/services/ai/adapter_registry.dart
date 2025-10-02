import 'package:flutter/foundation.dart';
import '../../utils/logger.dart';
import 'ai_journal_generator.dart';

/// Registry for managing available AI adapters
///
/// Maintains a prioritized list of adapters and selects the best available
/// based on device capabilities and user preferences.
class AdapterRegistry {
  static final _logger = AppLogger('AdapterRegistry');
  static final AdapterRegistry _instance = AdapterRegistry._internal();

  final List<AIJournalGenerator> _adapters = [];
  final Map<String, int> _adapterPriorities = {};

  factory AdapterRegistry() => _instance;
  AdapterRegistry._internal();

  /// Register an adapter with the given priority
  ///
  /// Lower priority values are preferred (Tier 1 = priority 1, Tier 2 = priority 2, etc.)
  void registerAdapter(AIJournalGenerator adapter, int priority) {
    final capabilities = adapter.getCapabilities();
    _logger.info('Registering adapter: ${capabilities.adapterName} (priority: $priority)');

    _adapters.add(adapter);
    _adapterPriorities[capabilities.adapterName] = priority;

    // Sort adapters by priority
    _adapters.sort((a, b) {
      final priorityA = _adapterPriorities[a.getCapabilities().adapterName] ?? 999;
      final priorityB = _adapterPriorities[b.getCapabilities().adapterName] ?? 999;
      return priorityA.compareTo(priorityB);
    });

    _logger.debug('Total registered adapters: ${_adapters.length}');
  }

  /// Unregister an adapter by name
  void unregisterAdapter(String adapterName) {
    _adapters.removeWhere((adapter) => adapter.getCapabilities().adapterName == adapterName);
    _adapterPriorities.remove(adapterName);
    _logger.info('Unregistered adapter: $adapterName');
  }

  /// Get all registered adapters in priority order
  List<AIJournalGenerator> getAllAdapters() {
    return List.unmodifiable(_adapters);
  }

  /// Get the best available adapter
  ///
  /// Returns the highest priority adapter that is currently available.
  /// Returns null if no adapters are available.
  Future<AIJournalGenerator?> getBestAvailableAdapter() async {
    _logger.debug('Finding best available adapter from ${_adapters.length} registered');

    for (final adapter in _adapters) {
      final capabilities = adapter.getCapabilities();
      _logger.debug('Checking adapter: ${capabilities.adapterName} (tier ${capabilities.tierLevel})');

      try {
        final isAvailable = await adapter.checkAvailability();
        if (isAvailable) {
          _logger.info('Selected adapter: ${capabilities.adapterName} (tier ${capabilities.tierLevel})');
          return adapter;
        } else {
          _logger.debug('Adapter not available: ${capabilities.adapterName}');
        }
      } catch (e, stackTrace) {
        _logger.error(
          'Error checking adapter availability: ${capabilities.adapterName}',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    _logger.warning('No available adapters found');
    return null;
  }

  /// Get adapter by name
  AIJournalGenerator? getAdapterByName(String name) {
    try {
      return _adapters.firstWhere(
        (adapter) => adapter.getCapabilities().adapterName == name,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear all registered adapters
  @visibleForTesting
  void clear() {
    _adapters.clear();
    _adapterPriorities.clear();
    _logger.debug('Cleared all adapters');
  }
}
