import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/backend_config.dart';
import '../../utils/logger.dart';
import '../../utils/image_compressor.dart';
import '../daily_context_synthesizer.dart';
import '../ai_feature_extractor.dart';
import 'ai_journal_generator.dart';

/// Tier 1 adapter using managed Cloud Gemini endpoint via backend proxy
///
/// Free tier: 3 AI-powered summaries per day
/// Pro tier: 25 AI-powered summaries per day
///
/// Privacy-first architecture:
/// - Anonymous device-ID based authentication (no account required for free tier)
/// - Data sent to backend proxy, then to Google Gemini
/// - Graceful fallback to Template adapter when quota exceeded
/// - Rate limiting tracked in Firestore via backend
///
/// This is Tier 1 (managed service) - Tier 2 is CloudGeminiAdapter (BYOK).
class ManagedCloudGeminiAdapter implements AIJournalGenerator {
  static final _logger = AppLogger('ManagedCloudGeminiAdapter');
  static const String _deviceIdKey = 'device_id';
  static const String _adapterName = 'ManagedCloudGemini';
  static const int _tierLevel = 1; // Tier 1 for managed service

  String? _deviceId;

  ManagedCloudGeminiAdapter();

  /// Get or generate device ID for anonymous authentication
  Future<String> _getDeviceId() async {
    if (_deviceId != null) {
      return _deviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null || deviceId.isEmpty) {
      // Generate a new device ID
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
      _logger.info('Generated new device ID');
    }

    _deviceId = deviceId;
    return deviceId;
  }

  /// Generate a unique device ID
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = List.generate(16, (_) => timestamp.hashCode % 256).join('-');
    return 'device-$timestamp-$random';
  }

  @override
  Future<bool> checkAvailability() async {
    try {
      // Check network connectivity by pinging health endpoint
      final healthUrl = Uri.parse(BackendConfig.healthUrl);
      final response = await http.get(healthUrl).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode == 200) {
        _logger.info('Backend health check passed');
        return true;
      } else {
        _logger.warning('Backend health check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.warning('Backend unavailable: $e');
      return false;
    }
  }

  @override
  AICapabilities getCapabilities() {
    return AICapabilities(
      canGenerateSummary: true,
      canDescribeImage: false, // Backend only supports summary generation
      canRewriteText: false, // Backend only supports summary generation
      isOnDevice: false,
      requiresNetwork: true,
      supportedLanguages: {
        'en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh',
        'nl', 'pl', 'ru', 'tr', 'vi', 'ar', 'hi', 'th', 'id',
        // Gemini 2.5 Pro supports 100+ languages
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
    // Managed service has no assets to download
    return true;
  }

  @override
  Future<AIGenerationResult> generateSummary(DailyContext context) async {
    if (!await checkAvailability()) {
      return AIGenerationResult.failure(
        'Backend unavailable',
        isRetryable: true,
      );
    }

    try {
      final deviceId = await _getDeviceId();
      _logger.info('Generating managed cloud narrative summary');

      // Select and compress top photos for multimodal AI analysis
      final compressedPhotos = await _preparePhotosForAI(context.photoContexts);
      _logger.info('Prepared ${compressedPhotos.length} photos for AI analysis');

      // Build request body matching backend DailyContext interface
      final requestBody = {
        'context': {
          'date': context.date.toIso8601String(),
          'timeline_events': context.timelineEvents.map((event) {
            return {
              'timestamp': event.timestamp.toIso8601String(),
              if (event.placeName != null) 'place_name': event.placeName,
              if (event.description != null) 'description': event.description,
              if (event.objectsSeen != null && event.objectsSeen!.isNotEmpty)
                'objects_seen': event.objectsSeen,
            };
          }).toList(),
          'location_summary': {
            'significant_places': context.locationSummary.significantPlaces,
            'total_distance_meters': context.locationSummary.totalDistance,
          },
          'activity_summary': {
            'primary_activities': context.activitySummary.primaryActivities,
          },
          'social_summary': {
            'total_people_detected': context.socialSummary.totalPeopleDetected,
            'social_contexts': context.socialSummary.socialContexts,
          },
          'photo_contexts': compressedPhotos,
        },
      };

      // Call backend API
      final url = Uri.parse(BackendConfig.generateSummaryUrl);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Device-ID': deviceId,
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final narrative = data['narrative'] as String;
        final remainingQuota = data['remaining_quota'] as int;
        final resetTime = data['reset_time'] as String;
        final tier = data['tier'] as String;
        final model = data['model'] as String;

        _logger.info('Generated narrative: ${narrative.split(' ').length} words');
        _logger.info('Remaining quota: $remainingQuota, Tier: $tier');

        return AIGenerationResult.success(
          narrative,
          metadata: {
            'adapter': _adapterName,
            'tier': _tierLevel,
            'model': model,
            'word_count': narrative.split(' ').length,
            'event_count': context.timelineEvents.length,
            'remaining_quota': remainingQuota,
            'reset_time': resetTime,
            'subscription_tier': tier,
          },
        );
      } else if (response.statusCode == 429) {
        // Quota exceeded
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final resetTime = data['reset_time'] as String?;

        _logger.warning('Daily quota exceeded. Reset at: $resetTime');

        return AIGenerationResult.failure(
          'Daily quota exceeded. Resets at $resetTime',
          isRetryable: false, // Don't retry until quota resets
        );
      } else if (response.statusCode == 408) {
        _logger.error('Request timeout');
        return AIGenerationResult.failure(
          'Request timeout',
          isRetryable: true,
        );
      } else {
        final errorMessage = 'Backend error: ${response.statusCode} - ${response.body}';
        _logger.error(errorMessage);
        return AIGenerationResult.failure(
          errorMessage,
          isRetryable: response.statusCode >= 500, // Retry server errors
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Error generating narrative', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure(
        'Network error: $e',
        isRetryable: true,
      );
    }
  }

  @override
  Future<AIGenerationResult> describeImage(String imagePath) async {
    return AIGenerationResult.failure(
      'Image description not supported in managed service',
      isRetryable: false,
    );
  }

  @override
  Future<AIGenerationResult> rewriteText(
    String text, {
    String? tone,
    String? language,
  }) async {
    return AIGenerationResult.failure(
      'Text rewriting not supported in managed service',
      isRetryable: false,
    );
  }

  /// Prepare top photos for AI analysis
  ///
  /// Selects top 3-5 photos by confidence score, compresses them to <500KB,
  /// and converts to base64 for API transmission.
  Future<List<Map<String, dynamic>>> _preparePhotosForAI(
    List<PhotoContext> photos,
  ) async {
    try {
      // Sort photos by confidence score (descending)
      final sortedPhotos = List<PhotoContext>.from(photos)
        ..sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

      // Take top 3-5 photos with valid file paths
      final selectedPhotos = sortedPhotos
          .where((photo) => photo.filePath != null && photo.filePath!.isNotEmpty)
          .take(5)
          .toList();

      if (selectedPhotos.isEmpty) {
        _logger.warning('No photos with valid file paths available');
        return [];
      }

      _logger.info('Compressing ${selectedPhotos.length} photos for AI analysis');

      // Compress and encode each photo
      final compressedPhotos = <Map<String, dynamic>>[];
      for (final photo in selectedPhotos) {
        try {
          final compressedBytes = await ImageCompressor.compressForAI(photo.filePath!);

          if (compressedBytes == null) {
            _logger.warning('Failed to compress photo ${photo.photoId}');
            continue;
          }

          // Convert to base64
          final base64Image = ImageCompressor.toBase64(compressedBytes);

          // Build photo context with metadata + image data
          compressedPhotos.add({
            'photo_id': photo.photoId,
            'timestamp': photo.timestamp.toIso8601String(),
            'confidence_score': photo.confidenceScore,
            'detected_objects': photo.detectedObjects,
            'object_confidence': photo.objectConfidence,
            if (photo.placeName != null) 'place_name': photo.placeName,
            if (photo.placeType != null) 'place_type': photo.placeType,
            'image_data': base64Image, // Base64-encoded compressed image
          });
        } catch (e) {
          _logger.warning('Error processing photo ${photo.photoId}: $e');
          continue;
        }
      }

      _logger.info('Successfully prepared ${compressedPhotos.length} photos for AI');
      return compressedPhotos;
    } catch (e, stackTrace) {
      _logger.error('Error preparing photos for AI', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get current usage statistics for the device
  Future<Map<String, dynamic>?> getUsageStats() async {
    try {
      final deviceId = await _getDeviceId();
      final url = Uri.parse(BackendConfig.usageUrl(deviceId));
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        _logger.warning('Failed to fetch usage stats: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.warning('Error fetching usage stats: $e');
      return null;
    }
  }
}
