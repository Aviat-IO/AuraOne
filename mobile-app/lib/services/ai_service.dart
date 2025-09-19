import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AIService {
  GenerativeModel? _model;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({String? apiKey}) async {
    try {
      final key = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY');

      if (key.isEmpty) {
        debugPrint('Gemini API key not provided - AI features will be disabled');
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );

      _isInitialized = true;
      debugPrint('AI service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AI service: $e');
      _isInitialized = false;
    }
  }

  /// Generate summary of provided content
  Future<String> generateSummary(String content) async {
    if (!_isInitialized || _model == null) {
      return "AI service not available. Please check your API key configuration.";
    }

    try {
      final prompt = 'Please provide a concise summary of the following content:\n\n$content';
      final contentList = [Content.text(prompt)];
      final response = await _model!.generateContent(contentList);
      return response.text ?? 'No summary generated';
    } catch (e) {
      debugPrint('Error generating summary: $e');
      return 'Error generating summary. Please try again.';
    }
  }

  /// Analyze image content (placeholder - requires vision model)
  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    // Image analysis requires vision model - keeping as placeholder for now
    return {
      "analysis": "Image analysis not implemented yet - requires vision model",
      "imagePath": imagePath,
    };
  }

  /// Process and enhance text content
  Future<String> processText(String text) async {
    if (!_isInitialized || _model == null) {
      return text; // Return unchanged if service not available
    }

    try {
      final prompt = '''Please improve and enhance this text while maintaining its original meaning:

Original text: $text

Improved text:''';

      final contentList = [Content.text(prompt)];
      final response = await _model!.generateContent(contentList);
      return response.text ?? text;
    } catch (e) {
      debugPrint('Error processing text: $e');
      return text; // Return original on error
    }
  }

  /// Generate journal entry based on context
  Future<Map<String, dynamic>> generateJournalEntry(Map<String, dynamic> context) async {
    if (!_isInitialized || _model == null) {
      return {
        'content': 'AI journal generation is not available. Please configure your Gemini API key in settings.',
        'summary': 'AI service not available',
      };
    }

    try {
      final date = context['date'] ?? DateTime.now().toIso8601String();
      final mood = context['mood'] ?? 'neutral';
      final activities = context['activities'] ?? [];

      final prompt = '''Create a thoughtful journal entry for $date.

Context:
- Mood: $mood
- Activities: ${activities.join(', ')}

Write a personal, reflective journal entry (2-3 paragraphs) that captures the essence of this day. Include thoughts about experiences, feelings, and any insights or lessons learned.

Journal Entry:''';

      final contentList = [Content.text(prompt)];
      final response = await _model!.generateContent(contentList);
      final content = response.text ?? 'Unable to generate journal entry';

      // Create a brief summary
      final summaryPrompt = 'Create a brief 1-sentence summary of this journal entry:\n\n$content';
      final summaryContentList = [Content.text(summaryPrompt)];
      final summaryResponse = await _model!.generateContent(summaryContentList);
      final summary = summaryResponse.text ?? 'Journal entry for $date';

      return {
        'content': content,
        'summary': summary,
      };
    } catch (e) {
      debugPrint('Error generating journal entry: $e');
      return {
        'content': 'Unable to generate journal entry at this time. Please try again later.',
        'summary': 'Error generating entry',
      };
    }
  }

  /// Process text-based requests
  Future<String> processTextRequest(String request) async {
    if (!_isInitialized || _model == null) {
      return 'AI processing not available. Please check your API key configuration.';
    }

    try {
      final contentList = [Content.text(request)];
      final response = await _model!.generateContent(contentList);
      return response.text ?? 'No response generated';
    } catch (e) {
      debugPrint('Error processing text request: $e');
      return 'Error processing request. Please try again.';
    }
  }
}