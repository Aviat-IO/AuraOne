import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'ai_service.dart';
import 'multimodal_fusion_processor.dart';

// Stage 4: Narrative Generation with Gemma 3 Nano
class SummaryGenerator extends PipelineStage {
  final AIServiceConfig config;
  bool _initialized = false;
  bool _gemmaAvailable = false;

  // Gemma model parameters per AI-SPEC
  static const String gemmaModelName = 'gemma-3-nano';
  static const int gemmaParametersB = 2; // 2B or 4B variant

  // Personality and tone options
  SummaryTone _tone = SummaryTone.balanced;
  SummaryStyle _style = SummaryStyle.narrative;

  SummaryGenerator(this.config);

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Check if Gemma model is available
    _gemmaAvailable = await _checkGemmaAvailability();

    if (!_gemmaAvailable) {
      debugPrint('Gemma 3 Nano not available, using fallback generation');
    }

    _initialized = true;
  }

  Future<bool> _checkGemmaAvailability() async {
    // Check if Gemma model is downloaded
    final appDir = await getApplicationDocumentsDirectory();
    final modelPath = path.join(appDir.path, 'models', 'gemma-3-nano.bin');
    final modelFile = File(modelPath);

    if (!modelFile.existsSync()) {
      debugPrint('Gemma model not found at $modelPath');
      // Note: flutter_gemma package doesn't exist yet
      // This is preparation for when Google releases it
      return false;
    }

    // Check license acceptance
    final licenseManager = GemmaLicenseManager();
    if (!await licenseManager.hasAcceptedTerms()) {
      debugPrint('Gemma Terms of Use not accepted');
      return false;
    }

    return true;
  }

  Future<DailySummary> generate(MultimodalData data) async {
    if (_gemmaAvailable) {
      try {
        return await _generateWithGemma(data);
      } catch (e) {
        debugPrint('Gemma generation failed: $e');
      }
    }

    // Fallback to template-based generation
    return await _generateWithTemplate(data);
  }

  Future<DailySummary> _generateWithGemma(MultimodalData data) async {
    // Prepare structured prompt for Gemma
    final prompt = _buildGemmaPrompt(data);

    // This would use the flutter_gemma package when available
    // For now, it's a placeholder for the future implementation

    // Simulated Gemma response
    final generatedText = await _simulateGemmaInference(prompt);

    return DailySummary(
      date: data.date,
      content: generatedText,
      generationType: GenerationType.full,
      metadata: {
        'model': gemmaModelName,
        'parameters': '${gemmaParametersB}B',
        'tone': _tone.toString(),
        'style': _style.toString(),
      },
    );
  }

  String _buildGemmaPrompt(MultimodalData data) {
    final buffer = StringBuffer();

    // System instruction
    buffer.writeln('Generate a daily summary for ${_formatDate(data.date)}.');
    buffer.writeln('Tone: ${_toneToString(_tone)}');
    buffer.writeln('Style: ${_styleToString(_style)}');
    buffer.writeln();

    // Structured event data
    buffer.writeln('Events of the day:');
    for (final event in data.enrichedEvents) {
      buffer.writeln('- ${_formatTimeRange(event.startTime, event.endTime)}: ${event.description}');
    }
    buffer.writeln();

    // Generation instruction
    buffer.writeln('Create a coherent, engaging narrative that:');
    buffer.writeln('1. Captures the essence of the day');
    buffer.writeln('2. Highlights significant moments');
    buffer.writeln('3. Maintains chronological flow');
    buffer.writeln('4. Uses the specified tone and style');

    return buffer.toString();
  }

  Future<String> _simulateGemmaInference(String prompt) async {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    // This is a placeholder - actual Gemma would generate rich narrative
    return '''
## Daily Summary

Your day began with a morning routine at home, followed by a productive work session at the office.
The highlight was a lunch meeting at a local restaurant, where engaging conversations flowed alongside good food.

The afternoon brought a refreshing walk through the park, providing a nice break from indoor activities.
Evening hours were spent back home, winding down with relaxation and preparation for the next day.

Overall, it was a well-balanced day combining work, social interaction, and personal time.
''';
  }

  Future<DailySummary> _generateWithTemplate(MultimodalData data) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# Daily Summary for ${_formatDate(data.date)}');
    buffer.writeln();

    if (data.enrichedEvents.isEmpty) {
      buffer.writeln('No significant events recorded for this day.');
    } else {
      // Adaptive generation based on data richness
      if (data.hasLocationData && data.hasVisualData) {
        // Rich data - detailed narrative
        buffer.writeln('## Your Day in Detail');
        buffer.writeln();

        // Morning events (before noon)
        final morningEvents = data.enrichedEvents
            .where((e) => e.startTime.hour < 12)
            .toList();
        if (morningEvents.isNotEmpty) {
          buffer.writeln('### Morning');
          for (final event in morningEvents) {
            buffer.writeln('- **${_formatTime(event.startTime)}**: ${event.description}');
          }
          buffer.writeln();
        }

        // Afternoon events (noon to 6pm)
        final afternoonEvents = data.enrichedEvents
            .where((e) => e.startTime.hour >= 12 && e.startTime.hour < 18)
            .toList();
        if (afternoonEvents.isNotEmpty) {
          buffer.writeln('### Afternoon');
          for (final event in afternoonEvents) {
            buffer.writeln('- **${_formatTime(event.startTime)}**: ${event.description}');
          }
          buffer.writeln();
        }

        // Evening events (after 6pm)
        final eveningEvents = data.enrichedEvents
            .where((e) => e.startTime.hour >= 18)
            .toList();
        if (eveningEvents.isNotEmpty) {
          buffer.writeln('### Evening');
          for (final event in eveningEvents) {
            buffer.writeln('- **${_formatTime(event.startTime)}**: ${event.description}');
          }
          buffer.writeln();
        }
      } else if (data.hasLocationData) {
        // Location data only - activity summary
        buffer.writeln('## Places & Activities');
        buffer.writeln();

        final stayEvents = data.enrichedEvents
            .where((e) => e.spatiotemporalEvent?.type == EventType.stay)
            .toList();
        final journeyEvents = data.enrichedEvents
            .where((e) => e.spatiotemporalEvent?.type == EventType.journey)
            .toList();

        if (stayEvents.isNotEmpty) {
          buffer.writeln('**Locations visited:** ${stayEvents.length}');
          for (final event in stayEvents) {
            buffer.writeln('- ${event.description}');
          }
        }

        if (journeyEvents.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('**Travel:** ${journeyEvents.length} journeys');
        }
      } else if (data.hasVisualData) {
        // Visual data only - photo summary
        buffer.writeln('## Photo Memories');
        buffer.writeln();

        buffer.writeln('You captured ${data.enrichedEvents.length} moments today:');
        for (final event in data.enrichedEvents) {
          buffer.writeln('- ${event.description}');
        }
      } else {
        // Minimal data - simple list
        buffer.writeln('## Activity Log');
        for (final event in data.enrichedEvents) {
          buffer.writeln('- ${_formatTime(event.startTime)}: ${event.description}');
        }
      }

      // Summary statistics
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln('*Summary: ${data.totalEvents} events recorded*');
    }

    return DailySummary(
      date: data.date,
      content: buffer.toString(),
      generationType: data.enrichedEvents.isEmpty
          ? GenerationType.simple
          : GenerationType.template,
      metadata: {
        'hasLocation': data.hasLocationData,
        'hasVisual': data.hasVisualData,
        'eventCount': data.totalEvents,
      },
    );
  }

  void setTone(SummaryTone tone) {
    _tone = tone;
  }

  void setStyle(SummaryStyle style) {
    _style = style;
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  String _toneToString(SummaryTone tone) {
    switch (tone) {
      case SummaryTone.professional:
        return 'Professional and formal';
      case SummaryTone.casual:
        return 'Casual and friendly';
      case SummaryTone.reflective:
        return 'Reflective and thoughtful';
      case SummaryTone.balanced:
        return 'Balanced and neutral';
    }
  }

  String _styleToString(SummaryStyle style) {
    switch (style) {
      case SummaryStyle.narrative:
        return 'Narrative storytelling';
      case SummaryStyle.bullet:
        return 'Bullet point list';
      case SummaryStyle.detailed:
        return 'Detailed and comprehensive';
      case SummaryStyle.brief:
        return 'Brief and concise';
    }
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }

  @override
  bool get isInitialized => _initialized;
}

// Enums for summary customization
enum SummaryTone {
  professional,
  casual,
  reflective,
  balanced,
}

enum SummaryStyle {
  narrative,
  bullet,
  detailed,
  brief,
}
