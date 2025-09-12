import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path/path.dart' as path;
import 'ai_service.dart';
import 'multimodal_fusion_processor.dart';

/// Stage 4: Summary Generator
/// Generates human-readable narratives from fused multimodal data
class SummaryGenerator extends PipelineStage {
  final AIServiceConfig config;
  final ModelFileManager modelFileManager;
  final GemmaLicenseManager licenseManager;
  
  FlutterGemma? _gemmaText;
  bool _isInitialized = false;
  Isolate? _generationIsolate;
  
  // Gemma configuration for text generation
  static const String modelFileName = 'gemma-3n-E2B-it-litert.task';
  static const int maxTokens = 2048;
  static const double temperature = 0.8;
  static const double topP = 0.9;
  static const int topK = 50;
  
  SummaryGenerator(
    this.config, {
    ModelFileManager? modelFileManager,
    GemmaLicenseManager? licenseManager,
  }) : modelFileManager = modelFileManager ?? ModelFileManager(
          Directory.systemTemp.path,
        ),
        licenseManager = licenseManager ?? GemmaLicenseManager();

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check if user has accepted Gemma Terms of Use
      if (!await licenseManager.hasAcceptedTerms()) {
        debugPrint('Gemma Terms of Use not accepted - using templates');
        _isInitialized = true;
        return;
      }
      
      // Check if model is downloaded
      final modelPath = await modelFileManager.getModelPath(modelFileName);
      if (!await File(modelPath).exists()) {
        debugPrint('Gemma model not found - using template generation');
        _isInitialized = true;
        return;
      }
      
      // Initialize Gemma for text generation
      _gemmaText = FlutterGemma(
        maxTokens: maxTokens,
        temperature: temperature,
        topK: topK,
        topP: topP,
        randomSeed: DateTime.now().millisecondsSinceEpoch,
      );
      
      await _gemmaText!.init(
        modelPath: modelPath,
        modelType: config.enableHardwareAcceleration 
          ? GemmaModelType.gpu 
          : GemmaModelType.cpu,
      );
      
      // Set up generation isolate
      await _setupGenerationIsolate();
      
      _isInitialized = true;
      debugPrint('SummaryGenerator initialized with Gemma 3 Nano');
    } catch (e) {
      debugPrint('Failed to initialize Gemma for summary: $e');
      _isInitialized = true;
    }
  }
  
  Future<void> _setupGenerationIsolate() async {
    final receivePort = ReceivePort();
    _generationIsolate = await Isolate.spawn(
      _generationIsolateEntryPoint,
      receivePort.sendPort,
    );
  }
  
  static void _generationIsolateEntryPoint(SendPort sendPort) {
    // Isolate for background text generation
  }

  /// Generate daily summary from fused multimodal data
  Future<DailySummary> generate(FusedMultimodalData fusedData) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Determine generation strategy based on data quality
      final strategy = _selectGenerationStrategy(fusedData);
      
      String content;
      GenerationType generationType;
      
      switch (strategy) {
        case GenerationStrategy.fullAI:
          content = await _generateWithGemma(fusedData);
          generationType = GenerationType.full;
          break;
          
        case GenerationStrategy.hybridAI:
          content = await _generateHybrid(fusedData);
          generationType = GenerationType.reduced;
          break;
          
        case GenerationStrategy.template:
          content = _generateFromTemplate(fusedData);
          generationType = GenerationType.template;
          break;
          
        case GenerationStrategy.simple:
          content = _generateSimple(fusedData);
          generationType = GenerationType.simple;
          break;
      }
      
      return DailySummary(
        date: fusedData.timestamp.toLocal(),
        content: content,
        generationType: generationType,
        metadata: {
          'eventCount': fusedData.structuredEvents.length,
          'imageCount': fusedData.keyImages.length,
          'confidence': fusedData.confidence,
          'fusionMethod': fusedData.fusionMethod,
          'processingTime': DateTime.now().millisecondsSinceEpoch -
                           fusedData.timestamp.millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('Summary generation error: $e');
      return _createFallbackSummary(fusedData);
    }
  }
  
  GenerationStrategy _selectGenerationStrategy(FusedMultimodalData fusedData) {
    // Check if Gemma is available
    if (_gemmaText == null) {
      return fusedData.structuredEvents.length > 5
          ? GenerationStrategy.template
          : GenerationStrategy.simple;
    }
    
    // Check battery optimization settings
    if (config.batteryOptimization == BatteryOptimizationLevel.minimal) {
      return GenerationStrategy.template;
    }
    
    // Select based on data quality and confidence
    if (fusedData.confidence > 0.8 && fusedData.structuredEvents.length > 8) {
      return GenerationStrategy.fullAI;
    } else if (fusedData.confidence > 0.6 && fusedData.structuredEvents.length > 4) {
      return GenerationStrategy.hybridAI;
    } else if (fusedData.structuredEvents.isNotEmpty) {
      return GenerationStrategy.template;
    } else {
      return GenerationStrategy.simple;
    }
  }

  Future<String> _generateWithGemma(FusedMultimodalData fusedData) async {
    final prompt = _buildGenerationPrompt(fusedData, detailed: true);
    
    final response = await _gemmaText!.generateResponse(
      prompt: prompt,
    );
    
    final generatedText = response.text ?? '';
    
    // Post-process to ensure quality
    if (generatedText.isEmpty || generatedText.length < 100) {
      // Fallback to hybrid if generation fails
      return await _generateHybrid(fusedData);
    }
    
    return _postProcessSummary(generatedText);
  }
  
  Future<String> _generateHybrid(FusedMultimodalData fusedData) async {
    // Combine template structure with AI enhancement
    final template = _generateFromTemplate(fusedData);
    
    if (_gemmaText != null) {
      final enhancePrompt = '''
Enhance this daily summary with more natural language and insights:

$template

Create an improved version that maintains all facts but sounds more engaging:''';
      
      try {
        final response = await _gemmaText!.generateResponse(
          prompt: enhancePrompt,
        );
        
        if (response.text != null && response.text!.isNotEmpty) {
          return _postProcessSummary(response.text!);
        }
      } catch (e) {
        debugPrint('Hybrid enhancement failed: $e');
      }
    }
    
    return template;
  }

  String _buildGenerationPrompt(FusedMultimodalData fusedData, {required bool detailed}) {
    final buffer = StringBuffer();
    
    buffer.writeln('Generate a ${detailed ? "detailed" : "brief"} daily summary based on the following information:');
    buffer.writeln();
    
    // Add narrative context from fusion
    if (fusedData.narrativeContext.isNotEmpty) {
      buffer.writeln('Context from multimodal analysis:');
      buffer.writeln(fusedData.narrativeContext);
      buffer.writeln();
    }
    
    // Add structured event details
    buffer.writeln('Structured Events:');
    for (final event in fusedData.structuredEvents) {
      buffer.writeln('- ${event.activity.name} at ${event.location.name} '
                    '(${_formatTimeRange(event.startTime, event.endTime)}) '
                    '[importance: ${(event.importance * 100).round()}%]');
    }
    buffer.writeln();
    
    // Add generation instructions
    if (detailed) {
      buffer.writeln('''
Create a comprehensive narrative summary that:
1. Tells the story of the day in a natural, engaging way
2. Highlights significant moments and transitions
3. Incorporates visual elements naturally
4. Provides meaningful insights about patterns or notable aspects
5. Uses varied sentence structure and engaging language

Write in first person, past tense. Be specific but concise.''');
    } else {
      buffer.writeln('''
Create a brief summary that captures the essence of the day in 2-3 paragraphs.''');
    }
    
    return buffer.toString();
  }
  
  String _postProcessSummary(String summary) {
    // Clean up and format the generated summary
    String processed = summary.trim();
    
    // Remove any AI artifacts or repetitions
    processed = processed.replaceAll(RegExp(r'\[.*?\]'), ''); // Remove brackets
    processed = processed.replaceAll(RegExp(r'\n{3,}'), '\n\n'); // Fix spacing
    
    // Ensure proper capitalization
    if (processed.isNotEmpty && processed[0] == processed[0].toLowerCase()) {
      processed = processed[0].toUpperCase() + processed.substring(1);
    }
    
    // Add structure if missing
    if (!processed.contains('\n\n') && processed.length > 500) {
      // Break into paragraphs at sentence boundaries
      final sentences = processed.split('. ');
      final paragraphSize = sentences.length ~/ 3;
      
      if (paragraphSize > 0) {
        final paragraphs = <String>[];
        for (int i = 0; i < sentences.length; i += paragraphSize) {
          final end = (i + paragraphSize < sentences.length) 
              ? i + paragraphSize 
              : sentences.length;
          paragraphs.add(sentences.sublist(i, end).join('. '));
        }
        processed = paragraphs.join('\n\n');
      }
    }
    
    return processed;
  }

  String _generateFromTemplate(FusedMultimodalData fusedData) {
    final buffer = StringBuffer();

    final events = fusedData.structuredEvents;
    
    // Opening
    buffer.writeln(_generateOpening(fusedData.timestamp));
    buffer.writeln();

    // Main activities
    if (events.isNotEmpty) {
      buffer.writeln('## Key Activities');
      buffer.writeln();
      
      // Group events by time of day
      final morning = events.where((e) => e.startTime.hour < 12).toList();
      final afternoon = events.where((e) => e.startTime.hour >= 12 && e.startTime.hour < 17).toList();
      final evening = events.where((e) => e.startTime.hour >= 17).toList();
      
      if (morning.isNotEmpty) {
        buffer.writeln('**Morning:**');
        _describeEvents(buffer, morning);
        buffer.writeln();
      }
      
      if (afternoon.isNotEmpty) {
        buffer.writeln('**Afternoon:**');
        _describeEvents(buffer, afternoon);
        buffer.writeln();
      }
      
      if (evening.isNotEmpty) {
        buffer.writeln('**Evening:**');
        _describeEvents(buffer, evening);
        buffer.writeln();
      }
    }
    
    // Visual highlights
    if (fusedData.keyImages.isNotEmpty) {
      buffer.writeln('## Captured Moments');
      buffer.writeln();
      _describeKeyImages(buffer, fusedData.keyImages);
      buffer.writeln();
    }
    
    // Insights
    final insights = _generateInsights(fusedData);
    if (insights.isNotEmpty) {
      buffer.writeln('## Daily Insights');
      buffer.writeln();
      for (final insight in insights) {
        buffer.writeln('• $insight');
      }
    }
    
    return buffer.toString();
  }
  
  String _generateSimple(FusedMultimodalData fusedData) {
    final buffer = StringBuffer();
    
    buffer.writeln('Daily Summary for ${_formatDate(fusedData.timestamp)}');
    buffer.writeln();
    
    if (fusedData.structuredEvents.isEmpty) {
      buffer.writeln('Limited activity data available for this day.');
    } else {
      buffer.writeln('Activities recorded: ${fusedData.structuredEvents.length}');
      
      for (final event in fusedData.structuredEvents.take(3)) {
        buffer.writeln('• ${event.activity.name} at ${event.location.name}');
      }
    }
    
    if (fusedData.keyImages.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Photos captured: ${fusedData.keyImages.length}');
    }
    
    return buffer.toString();
  }

  String _generateOpening(DateTime date) {
    final dayOfWeek = _getDayOfWeek(date.weekday);
    final formattedDate = _formatDate(date);
    
    final openings = [
      'Today, $dayOfWeek, $formattedDate, was filled with various activities and moments.',
      'On $dayOfWeek, $formattedDate, the day unfolded with a mix of experiences.',
      'This $dayOfWeek, $formattedDate, brought together different activities throughout the day.',
    ];
    
    return openings[date.day % openings.length];
  }
  
  void _describeEvents(StringBuffer buffer, List<StructuredEvent> events) {
    for (final event in events.take(3)) { // Limit to top 3 per period
      final duration = event.endTime.difference(event.startTime);
      final durationStr = _formatDuration(duration);
      
      buffer.writeln('• ${event.activity.name} at ${event.location.name} for $durationStr');
    }
  }
  
  void _describeKeyImages(StringBuffer buffer, List<KeyImage> keyImages) {
    for (final keyImage in keyImages) {
      final timeStr = _formatTime(keyImage.image.timestamp);
      buffer.writeln('• Moment captured at $timeStr during ${keyImage.event.activity.name}');
    }
  }
  
  List<String> _generateInsights(FusedMultimodalData fusedData) {
    final insights = <String>[];
    final events = fusedData.structuredEvents;
    
    if (events.isEmpty) return insights;
    
    // Activity diversity
    final uniqueActivities = events.map((e) => e.activity).toSet();
    if (uniqueActivities.length > 5) {
      insights.add('A particularly varied day with ${uniqueActivities.length} different types of activities');
    }
    
    // Time distribution
    final totalMinutes = events.fold(0, (sum, e) => 
      sum + e.endTime.difference(e.startTime).inMinutes);
    final totalHours = totalMinutes / 60.0;
    
    if (totalHours > 10) {
      insights.add('An active day with over ${totalHours.round()} hours of recorded activities');
    }
    
    // Most significant activity
    final mostImportant = events.reduce((a, b) => 
      a.importance > b.importance ? a : b);
    insights.add('Key highlight: ${mostImportant.activity.name} at ${mostImportant.location.name}');
    
    // Photo moments
    if (fusedData.keyImages.length > 5) {
      insights.add('A well-documented day with ${fusedData.keyImages.length} memorable moments captured');
    }
    
    return insights;
  }
  
  DailySummary _createFallbackSummary(FusedMultimodalData fusedData) {
    return DailySummary(
      date: fusedData.timestamp.toLocal(),
      content: 'Summary generation temporarily unavailable. '
               'Recorded ${fusedData.structuredEvents.length} activities today.',
      generationType: GenerationType.fallback,
      metadata: {
        'error': 'Generation failed',
        'eventCount': fusedData.structuredEvents.length,
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  String _getDayOfWeek(int weekday) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 
                  'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minutes';
    } else {
      return 'a few moments';
    }
  }

  @override
  Future<void> dispose() async {
    _generationIsolate?.kill(priority: Isolate.immediate);
    _gemmaText?.dispose();
    _isInitialized = false;
  }

  @override
  bool get isInitialized => _isInitialized;
}

// Generation strategies
enum GenerationStrategy {
  fullAI,    // Full Gemma generation
  hybridAI,  // Template + AI enhancement
  template,  // Pure template-based
  simple,    // Minimal summary
}

// Reuse GemmaModelType from multimodal_fusion_processor.dart
