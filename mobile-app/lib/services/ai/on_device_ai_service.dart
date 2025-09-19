import 'dart:math';
import 'package:flutter/foundation.dart';

/// On-device AI service for journal generation without any backend calls
/// Uses template-based generation with contextual intelligence for privacy
class OnDeviceAIService {
  static const List<String> _journalTemplates = [
    // Reflective templates
    "Today was {mood}. I found myself {activity} and it made me feel {emotion}. Looking back, I realize {insight}. Tomorrow, I hope to {aspiration}.",

    // Activity-focused templates
    "My day revolved around {activity}. The experience was {emotion}, and I learned {insight}. It reminded me of {reflection}.",

    // Growth-oriented templates
    "I spent time {activity} today, which felt {emotion}. This experience taught me {insight}. Moving forward, I want to {aspiration}.",

    // Grateful templates
    "Today I'm grateful for {gratitude}. I enjoyed {activity} and felt {emotion}. It's moments like these that remind me {reflection}.",

    // Contemplative templates
    "As I reflect on today, I notice I was {activity}. The feeling of {emotion} stayed with me because {insight}. This makes me want to {aspiration}."
  ];

  static const Map<String, List<String>> _contextualWords = {
    'mood': [
      'peaceful', 'energetic', 'thoughtful', 'content', 'curious', 'motivated',
      'relaxed', 'focused', 'optimistic', 'balanced', 'inspired', 'calm'
    ],
    'activity': [
      'exploring new ideas', 'connecting with nature', 'learning something new',
      'spending time with loved ones', 'working on personal projects', 'practicing mindfulness',
      'organizing my thoughts', 'pursuing my interests', 'taking care of myself',
      'creating something meaningful', 'solving problems', 'helping others'
    ],
    'emotion': [
      'fulfilling', 'rewarding', 'enlightening', 'satisfying', 'peaceful',
      'invigorating', 'meaningful', 'grounding', 'uplifting', 'clarifying',
      'nurturing', 'empowering', 'inspiring', 'centering'
    ],
    'insight': [
      'the importance of being present', 'how much I value genuine connections',
      'that growth happens in small moments', 'how creativity fuels my spirit',
      'the power of taking things one step at a time', 'that self-care isn\'t selfish',
      'how perspective shapes experience', 'the value of embracing uncertainty',
      'that patience is a form of wisdom', 'how gratitude transforms ordinary moments'
    ],
    'aspiration': [
      'continue this positive momentum', 'be more intentional with my time',
      'deepen my understanding', 'cultivate more moments like this',
      'share this feeling with others', 'build on what I learned',
      'trust the process more', 'appreciate the journey',
      'stay open to new possibilities', 'honor my authentic self'
    ],
    'gratitude': [
      'the simple pleasures of life', 'unexpected moments of joy',
      'the support of those around me', 'opportunities to grow',
      'the beauty in everyday experiences', 'my ability to choose my response',
      'the lessons hidden in challenges', 'moments of genuine connection',
      'the gift of this day', 'my capacity for resilience'
    ],
    'reflection': [
      'what truly matters', 'the beauty of imperfection',
      'how far I\'ve come', 'the importance of authenticity',
      'the value of being present', 'that happiness is a choice',
      'how interconnected we all are', 'the power of small acts',
      'that change begins within', 'how precious each moment is'
    ]
  };

  static const List<String> _moodAdjectives = [
    'peaceful', 'vibrant', 'contemplative', 'energetic', 'serene',
    'focused', 'grateful', 'curious', 'balanced', 'inspired'
  ];

  final Random _random;

  OnDeviceAIService() : _random = Random();

  /// Generate a journal entry based on provided context (completely on-device)
  Future<Map<String, dynamic>> generateJournalEntry(Map<String, dynamic> context) async {
    try {
      // Simulate processing time for realistic UX
      await Future.delayed(const Duration(milliseconds: 500 + 1000));

      final date = context['date'] ?? DateTime.now().toIso8601String();
      final mood = context['mood'] ?? _getRandomMood();
      final activities = context['activities'] as List<String>? ?? [];
      final locations = context['locations'] as List<String>? ?? [];

      // Select template based on available context
      final template = _selectTemplate(activities, locations, mood);

      // Generate content by filling template with contextual words
      final content = _fillTemplate(template, mood, activities, locations);

      // Create a thoughtful summary
      final summary = _generateSummary(content, mood);

      debugPrint('OnDevice AI: Generated journal entry for $date');

      return {
        'content': content,
        'summary': summary,
        'mood': mood,
        'generated_on_device': true,
      };
    } catch (e) {
      debugPrint('OnDevice AI: Error generating journal entry - $e');
      return {
        'content': _getFallbackContent(),
        'summary': 'Daily reflection',
        'generated_on_device': true,
      };
    }
  }

  /// Generate a contextual summary for text content
  Future<String> generateSummary(String content) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final words = content.split(' ');
    if (words.length < 20) {
      return 'Brief daily reflection';
    }

    // Extract key themes from content
    final themes = _extractThemes(content);
    if (themes.isNotEmpty) {
      return 'Reflection on ${themes.join(', ')}';
    }

    return 'Personal insights and reflections';
  }

  /// Enhanced text processing for contextual understanding
  Future<String> processText(String text) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // On-device text enhancement without external calls
    if (text.trim().isEmpty) return text;

    // Basic enhancement: proper capitalization and punctuation
    final sentences = text.split(RegExp(r'[.!?]+'));
    final enhanced = sentences.map((sentence) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) return '';

      // Capitalize first letter
      final capitalized = trimmed[0].toUpperCase() + trimmed.substring(1);
      return capitalized;
    }).where((s) => s.isNotEmpty).join('. ');

    return enhanced.endsWith('.') ? enhanced : '$enhanced.';
  }

  String _selectTemplate(List<String> activities, List<String> locations, String mood) {
    // Choose template based on available context
    if (activities.isNotEmpty) {
      return _journalTemplates[1]; // Activity-focused
    } else if (mood.contains('grateful') || mood.contains('thankful')) {
      return _journalTemplates[3]; // Grateful template
    } else {
      return _journalTemplates[_random.nextInt(_journalTemplates.length)];
    }
  }

  String _fillTemplate(String template, String mood, List<String> activities, List<String> locations) {
    String result = template;

    // Replace placeholders with contextual content
    result = result.replaceAll('{mood}', mood);
    result = result.replaceAll('{activity}', _getContextualActivity(activities));
    result = result.replaceAll('{emotion}', _getRandomWord('emotion'));
    result = result.replaceAll('{insight}', _getRandomWord('insight'));
    result = result.replaceAll('{aspiration}', _getRandomWord('aspiration'));
    result = result.replaceAll('{gratitude}', _getRandomWord('gratitude'));
    result = result.replaceAll('{reflection}', _getRandomWord('reflection'));

    return result;
  }

  String _getContextualActivity(List<String> activities) {
    if (activities.isNotEmpty) {
      // Transform activity into first-person narrative
      final activity = activities.first.toLowerCase();
      if (activity.contains('work') || activity.contains('office')) {
        return 'focusing on my professional responsibilities';
      } else if (activity.contains('home') || activity.contains('house')) {
        return 'spending quality time at home';
      } else if (activity.contains('outdoor') || activity.contains('park')) {
        return 'connecting with nature outdoors';
      } else {
        return 'engaging in meaningful activities';
      }
    }
    return _getRandomWord('activity');
  }

  String _getRandomWord(String category) {
    final words = _contextualWords[category];
    if (words == null || words.isEmpty) return '';
    return words[_random.nextInt(words.length)];
  }

  String _getRandomMood() {
    return _moodAdjectives[_random.nextInt(_moodAdjectives.length)];
  }

  String _generateSummary(String content, String mood) {
    final words = content.split(' ').take(10).join(' ');
    return 'A $mood day filled with reflection and insight';
  }

  String _getFallbackContent() {
    return "Today was a meaningful day. I took time to reflect on my experiences and found moments of insight. Each day brings new opportunities for growth and understanding.";
  }

  List<String> _extractThemes(String content) {
    final themes = <String>[];
    final lowerContent = content.toLowerCase();

    if (lowerContent.contains('grateful') || lowerContent.contains('thankful')) {
      themes.add('gratitude');
    }
    if (lowerContent.contains('learn') || lowerContent.contains('understand')) {
      themes.add('learning');
    }
    if (lowerContent.contains('peace') || lowerContent.contains('calm')) {
      themes.add('mindfulness');
    }
    if (lowerContent.contains('growth') || lowerContent.contains('change')) {
      themes.add('personal growth');
    }

    return themes;
  }

  /// Check if service is available (always true for on-device service)
  bool get isAvailable => true;
  bool get isInitialized => true;

  /// Initialize service (no-op for on-device service)
  Future<void> initialize() async {
    debugPrint('OnDevice AI: Service initialized successfully');
  }
}