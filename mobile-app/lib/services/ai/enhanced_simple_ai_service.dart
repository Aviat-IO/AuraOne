import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class EnhancedSimpleAIService {
  GenerativeModel? _model;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({Map<String, String>? apiKeys}) async {
    try {
      final apiKey = apiKeys?['GEMINI_API_KEY'] ??
                    const String.fromEnvironment('GEMINI_API_KEY');

      if (apiKey.isEmpty) {
        debugPrint('Gemini API key not provided - AI features will be disabled');
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
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

  Future<String> generateText(String prompt) async {
    if (!_isInitialized || _model == null) {
      return 'AI service not available. Please check your API key configuration.';
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? 'No response generated';
    } catch (e) {
      debugPrint('Error generating text: $e');
      return 'Error generating AI response. Please try again.';
    }
  }

  Future<Map<String, dynamic>> enhanceContent(String content) async {
    if (!_isInitialized) {
      return {
        'enhanced': content,
        'disabled': true,
      };
    }

    try {
      final prompt = '''Please enhance this journal content by making it more engaging and reflective while maintaining the original meaning and facts:

Original content: $content

Enhanced version:''';

      final enhanced = await generateText(prompt);
      return {
        'enhanced': enhanced,
        'original': content,
        'disabled': false,
      };
    } catch (e) {
      debugPrint('Error enhancing content: $e');
      return {
        'enhanced': content,
        'error': e.toString(),
      };
    }
  }

  Future<List<String>> generateSuggestions(String context) async {
    if (!_isInitialized) {
      return ['AI suggestions not available'];
    }

    try {
      final prompt = '''Based on this journal context, provide 3-5 short, actionable suggestions for reflection or improvement:

Context: $context

Suggestions (one per line):''';

      final response = await generateText(prompt);
      return response.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim().replaceFirst(RegExp(r'^\d+\.\s*'), ''))
          .take(5)
          .toList();
    } catch (e) {
      debugPrint('Error generating suggestions: $e');
      return ['Error generating suggestions'];
    }
  }

  Future<String> generateDailySummary(Map<String, dynamic> context) async {
    if (!_isInitialized) {
      return 'AI journal generation is not available. Please configure your Gemini API key in settings.';
    }

    try {
      final date = context['date'] ?? DateTime.now().toIso8601String();
      final style = context['style'] ?? 'reflective';

      final prompt = '''Write a thoughtful daily journal entry for $date in a $style style.

Create a meaningful reflection that includes:
- Gratitude for the day's experiences
- Lessons learned or insights gained
- Hopes or intentions for tomorrow
- A sense of personal growth or awareness

The entry should be 2-3 paragraphs long, personal, and written in first person. Make it feel authentic and introspective.

Journal Entry:''';

      final summary = await generateText(prompt);
      return summary;
    } catch (e) {
      debugPrint('Error generating daily summary: $e');
      return 'Unable to generate journal entry at this time. Please try again later.';
    }
  }
}