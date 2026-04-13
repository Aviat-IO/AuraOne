import 'dart:io';

import '../../utils/logger.dart';
import '../daily_context_synthesizer.dart';
import 'ai_journal_generator.dart';
import 'gemma_model_service.dart';

class GemmaLocalAdapter implements AIJournalGenerator {
  GemmaLocalAdapter({GemmaModelService? service})
    : _service = service ?? GemmaModelService(),
      _isSupportedPlatform = (() => Platform.isAndroid || Platform.isIOS);

  GemmaLocalAdapter.testable({
    required GemmaModelService service,
    required bool Function() isSupportedPlatform,
  }) : _service = service,
       _isSupportedPlatform = isSupportedPlatform;

  static final _logger = AppLogger('GemmaLocalAdapter');
  static const String _adapterName = 'GemmaLocal';
  static const int _tierLevel = 4;

  final GemmaModelService _service;
  final bool Function() _isSupportedPlatform;

  @override
  Future<bool> checkAvailability() async {
    if (!_isSupportedPlatform()) {
      return false;
    }

    return _service.isInstalled();
  }

  @override
  AICapabilities getCapabilities() {
    return AICapabilities(
      canGenerateSummary: true,
      canDescribeImage: false,
      canRewriteText: false,
      isOnDevice: true,
      requiresNetwork: false,
      supportedLanguages: {'en'},
      supportedTones: {'friendly', 'professional', 'elaborate', 'concise'},
      adapterName: _adapterName,
      tierLevel: _tierLevel,
    );
  }

  @override
  Future<bool> downloadRequiredAssets({
    void Function(double progress)? onProgress,
  }) async {
    try {
      await _service.install(onProgress: onProgress);
      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to install Gemma model',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<AIGenerationResult> generateSummary(DailyContext context) async {
    if (!await checkAvailability()) {
      return AIGenerationResult.failure(
        'Gemma 4 local model is not installed',
        isRetryable: false,
      );
    }

    try {
      final response = await _service.generateText(
        _buildNarrativePrompt(context),
      );

      if (response.trim().isEmpty) {
        return AIGenerationResult.failure('Gemma returned an empty response');
      }

      return AIGenerationResult.success(
        response,
        metadata: {
          'adapter': _adapterName,
          'tier': _tierLevel,
          'model': _service.descriptor.displayName,
          'is_on_device': true,
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Gemma local generation failed',
        error: e,
        stackTrace: stackTrace,
      );
      return AIGenerationResult.failure(
        'Gemma local generation failed: $e',
        isRetryable: true,
      );
    }
  }

  @override
  Future<AIGenerationResult> describeImage(String imagePath) async {
    return AIGenerationResult.failure(
      'Gemma local image description is not implemented yet',
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
      'Gemma local text rewriting is not implemented yet',
      isRetryable: false,
    );
  }

  String _buildNarrativePrompt(DailyContext context) {
    final buffer = StringBuffer()
      ..writeln('Write a short, factual journal entry in first person.')
      ..writeln(
        'Use only the provided details and avoid inventing emotions or facts.',
      )
      ..writeln('')
      ..writeln('Date: ${context.date.toIso8601String()}')
      ..writeln('Overview: ${context.narrativeOverview}')
      ..writeln('Timeline events: ${context.timelineEvents.length}')
      ..writeln('Photos: ${context.photoContexts.length}')
      ..writeln('Calendar events: ${context.calendarEvents.length}')
      ..writeln(
        'Locations: ${context.locationSummary.significantPlaces.join(', ')}',
      )
      ..writeln(
        'Activities: ${context.activitySummary.primaryActivities.join(', ')}',
      )
      ..writeln('Distance: ${context.locationSummary.formattedDistance}')
      ..writeln('')
      ..writeln('Write 2 short paragraphs.');

    if (context.timelineEvents.isNotEmpty) {
      buffer.writeln('Notable events:');
      for (final event in context.timelineEvents.take(8)) {
        buffer.writeln('- ${event.summary}');
      }
    }

    return buffer.toString();
  }
}
