import '../daily_context_synthesizer.dart';

/// Result of an AI generation operation
class AIGenerationResult {
  final String content;
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;

  AIGenerationResult({
    required this.content,
    required this.success,
    this.error,
    this.metadata,
  });

  factory AIGenerationResult.success(String content, {Map<String, dynamic>? metadata}) {
    return AIGenerationResult(
      content: content,
      success: true,
      metadata: metadata,
    );
  }

  factory AIGenerationResult.failure(String error) {
    return AIGenerationResult(
      content: '',
      success: false,
      error: error,
    );
  }
}

/// Capabilities of an AI adapter
class AICapabilities {
  final bool canGenerateSummary;
  final bool canDescribeImage;
  final bool canRewriteText;
  final bool isOnDevice;
  final bool requiresNetwork;
  final Set<String> supportedLanguages;
  final Set<String> supportedTones;
  final String adapterName;
  final int tierLevel; // 1-4, lower is better

  AICapabilities({
    required this.canGenerateSummary,
    required this.canDescribeImage,
    required this.canRewriteText,
    required this.isOnDevice,
    required this.requiresNetwork,
    required this.supportedLanguages,
    required this.supportedTones,
    required this.adapterName,
    required this.tierLevel,
  });
}

/// Abstract interface for AI-powered journal generation
///
/// Implementations can use different backends:
/// - ML Kit GenAI APIs (Tier 1)
/// - Hybrid ML Kit + TFLite (Tier 2)
/// - Template-based (Tier 3)
/// - Cloud Gemini API (Tier 4)
abstract class AIJournalGenerator {
  /// Generate a narrative summary from daily context
  Future<AIGenerationResult> generateSummary(DailyContext context);

  /// Generate a natural language description of an image
  Future<AIGenerationResult> describeImage(String imagePath);

  /// Rewrite text with specified tone and language
  ///
  /// [text] - The text to rewrite
  /// [tone] - Desired tone (e.g., 'friendly', 'professional', 'elaborate')
  /// [language] - Target language code (e.g., 'en', 'es', 'fr')
  Future<AIGenerationResult> rewriteText(
    String text, {
    String? tone,
    String? language,
  });

  /// Check if this adapter is currently available
  Future<bool> checkAvailability();

  /// Get the capabilities of this adapter
  AICapabilities getCapabilities();

  /// Optional: Download required models/features if needed
  Future<bool> downloadRequiredAssets({
    void Function(double progress)? onProgress,
  }) async {
    // Default implementation - no download needed
    return true;
  }
}
