import 'package:flutter/foundation.dart';
import 'on_device_ai_service.dart';
import '../ai_service.dart';

/// Hybrid AI service that prioritizes on-device processing for privacy
/// Falls back to cloud services only when on-device processing is insufficient
class HybridAIService {
  final OnDeviceAIService _onDeviceService;
  final AIService _cloudService;

  bool _preferOnDevice = true;
  bool _isInitialized = false;

  HybridAIService()
    : _onDeviceService = OnDeviceAIService(),
      _cloudService = AIService();

  /// Initialize the hybrid service
  Future<void> initialize({String? apiKey}) async {
    try {
      // Always initialize on-device service first
      await _onDeviceService.initialize();

      // Initialize cloud service only if API key is provided
      if (apiKey != null && apiKey.isNotEmpty) {
        await _cloudService.initialize(apiKey: apiKey);
        debugPrint('Hybrid AI: Both on-device and cloud services available');
      } else {
        debugPrint('Hybrid AI: Only on-device service available (no API key)');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Hybrid AI: Initialization error - $e');
      _isInitialized = false;
    }
  }

  /// Generate journal entry with privacy-first approach
  Future<Map<String, dynamic>> generateJournalEntry(Map<String, dynamic> context) async {
    if (!_isInitialized) {
      return _getFallbackResponse();
    }

    try {
      // Always try on-device first for privacy
      if (_preferOnDevice && _onDeviceService.isAvailable) {
        debugPrint('Hybrid AI: Using on-device generation for privacy');
        return await _onDeviceService.generateJournalEntry(context);
      }

      // Fallback to cloud only if explicitly enabled and available
      if (_cloudService.isInitialized) {
        debugPrint('Hybrid AI: Warning - Using cloud service (privacy implications)');
        final result = await _cloudService.generateJournalEntry(context);

        // Mark that this was generated using cloud service
        result['generated_on_device'] = false;
        result['privacy_warning'] = 'Generated using cloud service';

        return result;
      }

      // If nothing else works, use on-device fallback
      debugPrint('Hybrid AI: Using on-device fallback');
      return await _onDeviceService.generateJournalEntry(context);

    } catch (e) {
      debugPrint('Hybrid AI: Error in journal generation - $e');
      return _getFallbackResponse();
    }
  }

  /// Generate summary with privacy preference
  Future<String> generateSummary(String content) async {
    try {
      // Prefer on-device processing for privacy
      if (_onDeviceService.isAvailable) {
        return await _onDeviceService.generateSummary(content);
      }

      // Only use cloud if on-device fails
      if (_cloudService.isInitialized) {
        debugPrint('Hybrid AI: Using cloud for summary (privacy impact)');
        return await _cloudService.generateSummary(content);
      }

      return 'Summary not available';
    } catch (e) {
      debugPrint('Hybrid AI: Error generating summary - $e');
      return 'Summary generation failed';
    }
  }

  /// Process text with privacy focus
  Future<String> processText(String text) async {
    try {
      // Always use on-device processing for text enhancement
      return await _onDeviceService.processText(text);
    } catch (e) {
      debugPrint('Hybrid AI: Error processing text - $e');
      return text; // Return original text on error
    }
  }

  /// Configure privacy preferences
  void setPrivacyPreference({required bool preferOnDevice}) {
    _preferOnDevice = preferOnDevice;
    debugPrint('Hybrid AI: Privacy preference set to ${preferOnDevice ? 'on-device' : 'cloud-enabled'}');
  }

  /// Get current privacy status
  Map<String, dynamic> getPrivacyStatus() {
    return {
      'prefers_on_device': _preferOnDevice,
      'on_device_available': _onDeviceService.isAvailable,
      'cloud_available': _cloudService.isInitialized,
      'current_mode': _getCurrentMode(),
    };
  }

  String _getCurrentMode() {
    if (_preferOnDevice && _onDeviceService.isAvailable) {
      return 'on_device_only';
    } else if (_cloudService.isInitialized) {
      return 'cloud_fallback';
    } else {
      return 'limited_on_device';
    }
  }

  Map<String, dynamic> _getFallbackResponse() {
    return {
      'content': 'Today was a day of reflection and growth. I took time to appreciate the moments that mattered and found insights in my experiences.',
      'summary': 'Daily reflection and mindfulness',
      'generated_on_device': true,
      'fallback_used': true,
    };
  }

  /// Check if service is ready to use
  bool get isInitialized => _isInitialized;

  /// Check if any AI capability is available
  bool get isAvailable => _onDeviceService.isAvailable || _cloudService.isInitialized;

  /// Get privacy-friendly service description
  String get serviceDescription {
    final status = getPrivacyStatus();
    switch (status['current_mode']) {
      case 'on_device_only':
        return 'Privacy-first: All processing happens on your device';
      case 'cloud_fallback':
        return 'Hybrid: On-device preferred, cloud available as fallback';
      case 'limited_on_device':
        return 'Limited: Only basic on-device processing available';
      default:
        return 'AI service not available';
    }
  }
}