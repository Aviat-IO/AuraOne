import 'package:flutter/foundation.dart';

/// On-device AI service for journal generation without any backend calls
/// Uses data-driven content generation for factual journal entries
class OnDeviceAIService {

  OnDeviceAIService();

  /// Generate a journal entry based on provided context (completely on-device)
  Future<Map<String, dynamic>> generateJournalEntry(Map<String, dynamic> context) async {
    try {
      // Simulate processing time for realistic UX
      await Future.delayed(const Duration(milliseconds: 800));

      final date = context['date'] ?? DateTime.now().toIso8601String();
      final photosCount = context['photosCount'] as int? ?? 0;
      final locationsCount = context['locationsCount'] as int? ?? 0;
      final calendarEvents = context['calendarEvents'] as List<String>? ?? [];

      // Generate data-driven content only based on what actually happened
      final content = _generateDataDrivenContent(photosCount, locationsCount, calendarEvents, date);

      // Create a factual summary
      final summary = _generateFactualSummary(photosCount, locationsCount, calendarEvents);

      debugPrint('OnDevice AI: Generated journal entry for $date');

      return {
        'content': content,
        'summary': summary,
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

  String _generateDataDrivenContent(int photosCount, int locationsCount, List<String> calendarEvents, String date) {
    final List<String> contentParts = [];

    // Add date header
    final dateObj = DateTime.tryParse(date) ?? DateTime.now();
    final dateStr = _formatDate(dateObj);
    contentParts.add('$dateStr\n');

    // Only add factual information about what actually happened
    if (calendarEvents.isNotEmpty) {
      contentParts.add('Events today:');
      for (final event in calendarEvents.take(3)) {
        contentParts.add('• $event');
      }
      contentParts.add('');
    }

    if (photosCount > 0) {
      if (photosCount == 1) {
        contentParts.add('Captured 1 photo today.');
      } else if (photosCount < 5) {
        contentParts.add('Captured $photosCount photos today.');
      } else if (photosCount < 10) {
        contentParts.add('Documented the day with $photosCount photos.');
      } else {
        contentParts.add('Extensively documented today with $photosCount photos.');
      }
    }

    if (locationsCount > 0) {
      if (locationsCount == 1) {
        contentParts.add('Stayed in one area today.');
      } else if (locationsCount == 2) {
        contentParts.add('Visited 2 different locations.');
      } else if (locationsCount <= 5) {
        contentParts.add('Visited $locationsCount different places.');
      } else {
        contentParts.add('Had an active day visiting $locationsCount locations.');
      }
    }

    // If no data, add minimal entry
    if (contentParts.length <= 1) {
      contentParts.add('A quiet day.');
    }

    return contentParts.join('\n').trim();
  }

  String _generateFactualSummary(int photosCount, int locationsCount, List<String> calendarEvents) {
    final List<String> summaryParts = [];

    if (calendarEvents.isNotEmpty) {
      summaryParts.add('${calendarEvents.length} event${calendarEvents.length > 1 ? 's' : ''}');
    }

    if (photosCount > 0) {
      summaryParts.add('$photosCount photo${photosCount > 1 ? 's' : ''}');
    }

    if (locationsCount > 0) {
      summaryParts.add('$locationsCount location${locationsCount > 1 ? 's' : ''}');
    }

    if (summaryParts.isEmpty) {
      return 'Daily journal entry';
    }

    return 'Day with ${summaryParts.join(', ')}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getFallbackContent() {
    return "Today's journal entry.";
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