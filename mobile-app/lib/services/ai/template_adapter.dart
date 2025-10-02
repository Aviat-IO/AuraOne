import 'dart:io';
import '../../utils/logger.dart';
import '../daily_context_synthesizer.dart';
import '../data_rich_narrative_builder.dart';
import 'ai_journal_generator.dart';

/// Tier 3 adapter using template-based narrative generation
///
/// Wraps the existing DataRichNarrativeBuilder to provide
/// a guaranteed fallback that works on all devices.
///
/// Capabilities:
/// - generateSummary: Uses DataRichNarrativeBuilder
/// - describeImage: Uses ML Kit image labeling (Android) or placeholder (iOS)
/// - rewriteText: Template-based transformations
/// - 100% availability guarantee
class TemplateAdapter implements AIJournalGenerator {
  static final _logger = AppLogger('TemplateAdapter');
  final DataRichNarrativeBuilder _narrativeBuilder = DataRichNarrativeBuilder();

  static const String _adapterName = 'Template';
  static const int _tierLevel = 3;

  @override
  Future<bool> checkAvailability() async {
    // Always available - this is the guaranteed fallback
    return true;
  }

  @override
  AICapabilities getCapabilities() {
    return AICapabilities(
      canGenerateSummary: true,
      canDescribeImage: Platform.isAndroid, // Only Android has ML Kit image labeling
      canRewriteText: true,
      isOnDevice: true,
      requiresNetwork: false,
      supportedLanguages: {'en'}, // Template system is English-only
      supportedTones: {
        'friendly',
        'professional',
        'elaborate',
        'concise',
      },
      adapterName: _adapterName,
      tierLevel: _tierLevel,
    );
  }

  @override
  Future<bool> downloadRequiredAssets({
    void Function(double progress)? onProgress,
  }) async {
    // Template adapter has no assets to download
    // All logic is built into the code
    return true;
  }

  @override
  Future<AIGenerationResult> generateSummary(DailyContext context) async {
    try {
      _logger.info('Generating template-based narrative summary');

      final narrative = await _narrativeBuilder.buildNarrative(context: context);

      _logger.info('Generated narrative: ${narrative.split(' ').length} words');

      return AIGenerationResult.success(
        narrative,
        metadata: {
          'adapter': _adapterName,
          'tier': _tierLevel,
          'word_count': narrative.split(' ').length,
          'event_count': context.timelineEvents.length,
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error generating narrative', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure('Template generation failed: $e');
    }
  }

  @override
  Future<AIGenerationResult> describeImage(String imagePath) async {
    if (!Platform.isAndroid) {
      return AIGenerationResult.failure('Image description not available on iOS');
    }

    try {
      _logger.info('Describing image using ML Kit image labeling: $imagePath');

      // TODO: Implement ML Kit image labeling
      // This would use the existing ML Kit Image Labeling API
      // (different from ML Kit GenAI)
      // For now, return a placeholder

      return AIGenerationResult.failure(
        'ML Kit image labeling not yet implemented',
      );
    } catch (e, stackTrace) {
      _logger.error('Error describing image', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure('Image description failed: $e');
    }
  }

  @override
  Future<AIGenerationResult> rewriteText(
    String text, {
    String? tone,
    String? language,
  }) async {
    try {
      _logger.info('Rewriting text with tone: $tone, language: $language');

      // Language support check
      if (language != null && language.toLowerCase() != 'en') {
        return AIGenerationResult.failure('Only English language supported in template mode');
      }

      // Apply tone transformation
      final rewritten = _applyToneTransformation(text, tone?.toLowerCase());

      return AIGenerationResult.success(
        rewritten,
        metadata: {
          'adapter': _adapterName,
          'tier': _tierLevel,
          'tone': tone,
          'original_length': text.length,
          'rewritten_length': rewritten.length,
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error rewriting text', error: e, stackTrace: stackTrace);
      return AIGenerationResult.failure('Text rewriting failed: $e');
    }
  }

  /// Apply tone transformation to text using template rules
  String _applyToneTransformation(String text, String? tone) {
    if (tone == null) {
      return text; // No transformation
    }

    switch (tone) {
      case 'friendly':
        return _makeFriendly(text);
      case 'professional':
        return _makeProfessional(text);
      case 'elaborate':
        return _makeElaborate(text);
      case 'concise':
        return _makeConcise(text);
      default:
        return text;
    }
  }

  /// Transform text to friendly tone
  String _makeFriendly(String text) {
    // Add friendly markers and casual language
    var result = text;

    // Add friendly opening if not present
    if (!result.toLowerCase().startsWith('hey') &&
        !result.toLowerCase().startsWith('hi')) {
      result = 'Hey! $result';
    }

    // Replace formal terms with casual equivalents
    result = result
        .replaceAll('However,', 'But hey,')
        .replaceAll('Therefore,', 'So,')
        .replaceAll('Subsequently,', 'Then,')
        .replaceAll('Additionally,', 'Also,');

    return result;
  }

  /// Transform text to professional tone
  String _makeProfessional(String text) {
    // Remove casual language and add formal structure
    var result = text;

    // Remove casual openings
    result = result
        .replaceAll(RegExp(r'^(Hey!?|Hi!?)\s*', caseSensitive: false), '')
        .trim();

    // Replace casual terms with formal equivalents
    result = result
        .replaceAll('But hey,', 'However,')
        .replaceAll('So,', 'Therefore,')
        .replaceAll('Then,', 'Subsequently,')
        .replaceAll('Also,', 'Additionally,');

    return result;
  }

  /// Transform text to elaborate form
  String _makeElaborate(String text) {
    // Add more descriptive language and context
    final sentences = text.split('. ').where((s) => s.trim().isNotEmpty).toList();

    final elaborated = <String>[];
    for (final sentence in sentences) {
      var enhanced = sentence;

      // Add descriptive words
      enhanced = enhanced
          .replaceAll('went to', 'traveled to')
          .replaceAll('saw', 'observed')
          .replaceAll('met', 'encountered')
          .replaceAll('did', 'accomplished');

      // Add context phrases
      if (!enhanced.contains('Throughout the day') &&
          !enhanced.contains('During this time')) {
        if (elaborated.isEmpty) {
          enhanced = 'Throughout the day, $enhanced';
        }
      }

      elaborated.add(enhanced);
    }

    return elaborated.join('. ') + (text.endsWith('.') ? '' : '.');
  }

  /// Transform text to concise form
  String _makeConcise(String text) {
    // Remove unnecessary words and phrases
    var result = text;

    // Remove filler phrases
    result = result
        .replaceAll(RegExp(r'Throughout the day,?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'During this time,?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'In essence,?\s*', caseSensitive: false), '');

    // Replace verbose terms with concise equivalents
    result = result
        .replaceAll('traveled to', 'went to')
        .replaceAll('observed', 'saw')
        .replaceAll('encountered', 'met')
        .replaceAll('accomplished', 'did');

    // Remove consecutive spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}
