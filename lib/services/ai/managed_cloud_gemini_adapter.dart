import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../utils/logger.dart';
import '../daily_context_synthesizer.dart';
import '../device_id_service.dart';
import 'ai_journal_generator.dart';

/// Tier 1 adapter using managed backend proxy service
///
/// This adapter provides secure, rate-limited access to Vertex AI Gemini
/// through a backend proxy without exposing API credentials in the app.
///
/// Features:
/// - No API credentials in mobile binary
/// - Device-based rate limiting (3/day free, 25/day Pro)
/// - Privacy-first anonymous authentication
/// - Automatic quota tracking and enforcement
/// - Graceful degradation to lower-tier adapters
///
/// Privacy model:
/// - Free tier: Device UUID only (no PII)
/// - Pro tier: Receipt validation + optional account linking
class ManagedCloudGeminiAdapter implements AIJournalGenerator {
  static final _logger = AppLogger('ManagedCloudGeminiAdapter');
  static const String _adapterName = 'ManagedCloudGemini';
  static const int _tierLevel = 1;

  // Backend configuration
  static const String _defaultBackendUrl = 'http://localhost:5566';
  static const String _generateEndpoint = '/api/generate-summary';
  static const String _usageEndpoint = '/api/usage';
  static const String _healthEndpoint = '/health';

  final DeviceIdService _deviceIdService;
  final String _backendUrl;
  final http.Client _httpClient;

  // Quota tracking
  int? _remainingQuota;
  DateTime? _quotaResetTime;

  ManagedCloudGeminiAdapter({
    required DeviceIdService deviceIdService,
    String? backendUrl,
    http.Client? httpClient,
  })  : _deviceIdService = deviceIdService,
        _backendUrl = backendUrl ?? _defaultBackendUrl,
        _httpClient = httpClient ?? http.Client();

  @override
  Future<bool> checkAvailability() async {
    try {
      // Check if backend is reachable
      final healthUrl = Uri.parse('$_backendUrl$_healthEndpoint');
      final response = await _httpClient
          .get(healthUrl)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        _logger.info('Backend health check failed: ${response.statusCode}');
        return false;
      }

      // Check quota
      final hasQuota = await _checkQuota();
      if (!hasQuota) {
        _logger.info('No remaining quota available');
        return false;
      }

      _logger.info('Managed adapter available with quota: $_remainingQuota');
      return true;
    } catch (e) {
      _logger.warning('Backend unavailable: $e');
      return false;
    }
  }

  @override
  AICapabilities getCapabilities() {
    return AICapabilities(
      canGenerateSummary: true,
      canDescribeImage: false, // Not implemented in initial version
      canRewriteText: false, // Not implemented in initial version
      isOnDevice: false,
      requiresNetwork: true,
      supportedLanguages: {
        'en',
        'es',
        'fr',
        'de',
        'it',
        'pt',
        'ja',
        'ko',
        'zh',
        'nl',
        'pl',
        'ru',
        'tr',
        'vi',
        'ar',
        'hi',
        'th',
        'id',
      },
      supportedTones: {
        'friendly',
        'professional',
        'elaborate',
        'concise',
        'casual',
        'formal',
        'empathetic',
        'enthusiastic',
      },
      adapterName: _adapterName,
      tierLevel: _tierLevel,
    );
  }

  @override
  Future<bool> downloadRequiredAssets({
    void Function(double progress)? onProgress,
  }) async {
    // No assets to download - backend handles everything
    return true;
  }

  @override
  Future<AIGenerationResult> generateSummary(DailyContext context) async {
    if (!await checkAvailability()) {
      return AIGenerationResult.failure(
        'Managed service unavailable. Please check your network connection.',
        isRetryable: true,
      );
    }

    try {
      _logger.info('Generating summary via managed backend');

      final deviceId = await _deviceIdService.getDeviceId();
      final url = Uri.parse('$_backendUrl$_generateEndpoint');

      final requestBody = {
        'device_id': deviceId,
        'context': _serializeContext(context),
      };

      final response = await _httpClient
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Device-ID': deviceId,
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 429) {
        // Rate limit exceeded
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final resetTime = data['reset_time'] as String?;
        _logger.warning('Rate limit exceeded. Reset time: $resetTime');

        return AIGenerationResult.failure(
          'Daily quota exceeded. You have used all your AI generations for today. '
          'Upgrade to Pro for more generations or try again tomorrow.',
          isRetryable: false,
        );
      }

      if (response.statusCode != 200) {
        _logger.error('Backend error: ${response.statusCode} ${response.body}');
        return AIGenerationResult.failure(
          'AI service temporarily unavailable (${response.statusCode})',
          isRetryable: true,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final narrative = data['narrative'] as String?;
      final remainingQuota = data['remaining_quota'] as int?;

      if (narrative == null || narrative.isEmpty) {
        return AIGenerationResult.failure('Empty response from AI service');
      }

      // Update quota tracking
      if (remainingQuota != null) {
        _remainingQuota = remainingQuota;
        _quotaResetTime = DateTime.now().add(const Duration(days: 1));
      }

      _logger.info('Generated narrative: ${narrative.split(' ').length} words');
      _logger.info('Remaining quota: $_remainingQuota');

      return AIGenerationResult.success(
        narrative,
        metadata: {
          'adapter': _adapterName,
          'tier': _tierLevel,
          'backend_model': data['model'] ?? 'gemini-2.0-flash',
          'word_count': narrative.split(' ').length,
          'remaining_quota': _remainingQuota,
          'quota_reset_time': _quotaResetTime?.toIso8601String(),
        },
      );
    } on SocketException catch (e) {
      _logger.error('Network error', error: e);
      return AIGenerationResult.failure(
        'Network error. Please check your internet connection.',
        isRetryable: true,
      );
    } on http.ClientException catch (e) {
      _logger.error('HTTP client error', error: e);
      return AIGenerationResult.failure(
        'Connection error. Please try again.',
        isRetryable: true,
      );
    } catch (e, stackTrace) {
      _logger.error('Error generating summary', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure(
        'Unexpected error: $e',
        isRetryable: false,
      );
    }
  }

  @override
  Future<AIGenerationResult> describeImage(String imagePath) async {
    // Not implemented in initial version
    return AIGenerationResult.failure(
      'Image description not yet supported in managed service',
    );
  }

  @override
  Future<AIGenerationResult> rewriteText(
    String text, {
    String? tone,
    String? language,
  }) async {
    // Not implemented in initial version
    return AIGenerationResult.failure(
      'Text rewriting not yet supported in managed service',
    );
  }

  /// Check remaining quota from backend
  Future<bool> _checkQuota() async {
    try {
      final deviceId = await _deviceIdService.getDeviceId();
      final url = Uri.parse('$_backendUrl$_usageEndpoint/$deviceId');

      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        _logger.warning('Quota check failed: ${response.statusCode}');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _remainingQuota = data['remaining'] as int?;
      final resetAt = data['reset_at'] as String?;

      if (resetAt != null) {
        _quotaResetTime = DateTime.parse(resetAt);
      }

      return _remainingQuota != null && _remainingQuota! > 0;
    } catch (e) {
      _logger.warning('Error checking quota: $e');
      // Assume quota available if check fails (fail open)
      return true;
    }
  }

  /// Get current quota status
  ///
  /// Returns a map with quota information or null if unavailable
  Future<Map<String, dynamic>?> getQuotaStatus() async {
    try {
      await _checkQuota();

      return {
        'remaining': _remainingQuota,
        'reset_time': _quotaResetTime?.toIso8601String(),
        'has_quota': _remainingQuota != null && _remainingQuota! > 0,
      };
    } catch (e) {
      _logger.error('Error getting quota status: $e');
      return null;
    }
  }

  /// Serialize DailyContext for backend API
  Map<String, dynamic> _serializeContext(DailyContext context) {
    return {
      'date': context.date.toIso8601String(),
      'timeline_events': context.timelineEvents.map((event) => {
        'timestamp': event.timestamp.toIso8601String(),
        'place_name': event.placeName,
        'description': event.description,
        'objects_seen': event.objectsSeen,
      }).toList(),
      'location_summary': {
        'significant_places': context.locationSummary.significantPlaces,
        'total_distance_meters': context.locationSummary.totalDistanceMeters,
      },
      'activity_summary': {
        'primary_activities': context.activitySummary.primaryActivities,
      },
      'social_summary': {
        'total_people_detected': context.socialSummary.totalPeopleDetected,
        'social_contexts': context.socialSummary.socialContexts,
      },
      'photo_contexts': context.photoContexts.map((photo) => {
        'timestamp': photo.timestamp.toIso8601String(),
        'detected_objects': photo.detectedObjects,
      }).toList(),
    };
  }
}
