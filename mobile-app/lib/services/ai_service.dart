import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';
import '../database/media_database.dart';
import 'calendar_service.dart';
import 'health_service.dart';
import 'photo_service.dart';
import 'data_attribution_service.dart';

/// Model format types
enum ModelFormat {
  tflite,
  onnx,
}

/// AI model configuration
class AIModelConfig {
  final String modelName;
  final ModelFormat format;
  final String modelPath;
  final int maxInputLength;
  final int maxOutputLength;
  final Map<String, dynamic> metadata;
  
  const AIModelConfig({
    required this.modelName,
    required this.format,
    required this.modelPath,
    this.maxInputLength = 512,
    this.maxOutputLength = 256,
    this.metadata = const {},
  });
}

/// Journal entry template
class JournalEntry {
  final String id;
  final DateTime date;
  final String content;
  final String summary;
  final List<String> highlights;
  final Map<String, dynamic> metadata;
  final List<DataAttribution> attributions;
  
  JournalEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.summary,
    this.highlights = const [],
    this.metadata = const {},
    this.attributions = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'content': content,
    'summary': summary,
    'highlights': highlights,
    'metadata': metadata,
    'attributions': attributions.map((a) => a.toJson()).toList(),
  };
  
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      summary: json['summary'] as String,
      highlights: List<String>.from(json['highlights'] ?? []),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      attributions: (json['attributions'] as List?)
          ?.map((a) => DataAttribution.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

/// Service for on-device AI text generation
class AIService {
  static final _logger = AppLogger('AIService');
  static final _instance = AIService._internal();
  
  factory AIService() => _instance;
  AIService._internal();
  
  // Model management
  Interpreter? _tfliteInterpreter;
  OrtSession? _onnxSession;
  AIModelConfig? _currentModel;
  bool _isInitialized = false;
  
  // Service dependencies
  final DataAttributionService _attributionService = DataAttributionService();
  final CalendarService _calendarService = CalendarService();
  final HealthService _healthService = HealthService();
  final PhotoService _photoService = PhotoService();
  
  // Prompt templates
  static const String _defaultPromptTemplate = '''
Based on the following daily data, generate a personal journal entry:

Date: {date}
Events: {events}
Activities: {activities}
Health Data: {health}
Photos: {photos}
Notable Moments: {moments}

Create a thoughtful, personal narrative that captures the essence of the day:
''';
  
  static const String _summaryPromptTemplate = '''
Summarize the following day in 2-3 sentences:

{content}

Summary:
''';
  
  /// Initialize AI service with a model
  Future<void> initialize({AIModelConfig? config}) async {
    try {
      _logger.info('Initializing AI service...');
      
      // Use default config if none provided
      final modelConfig = config ?? _getDefaultModelConfig();
      
      // Load model based on format
      if (modelConfig.format == ModelFormat.tflite) {
        await _loadTFLiteModel(modelConfig);
      } else if (modelConfig.format == ModelFormat.onnx) {
        await _loadONNXModel(modelConfig);
      }
      
      _currentModel = modelConfig;
      _isInitialized = true;
      
      _logger.info('AI service initialized with ${modelConfig.modelName}');
    } catch (e, stack) {
      _logger.error('Failed to initialize AI service', error: e, stackTrace: stack);
      _isInitialized = false;
    }
  }
  
  /// Load TFLite model
  Future<void> _loadTFLiteModel(AIModelConfig config) async {
    try {
      // Check if model exists in assets
      final modelPath = await _getModelPath(config.modelPath);
      
      // Create interpreter
      _tfliteInterpreter = await Interpreter.fromAsset(modelPath);
      
      _logger.info('TFLite model loaded: ${config.modelName}');
    } catch (e) {
      _logger.error('Failed to load TFLite model', error: e);
      throw Exception('Failed to load TFLite model: $e');
    }
  }
  
  /// Load ONNX model
  Future<void> _loadONNXModel(AIModelConfig config) async {
    try {
      // Initialize ONNX Runtime
      OrtEnv.instance.init();
      
      // Get model path
      final modelPath = await _getModelPath(config.modelPath);
      final modelBytes = await _loadModelBytes(modelPath);
      
      // Create session options
      final sessionOptions = OrtSessionOptions();
      
      // Create session
      _onnxSession = OrtSession.fromBuffer(modelBytes, sessionOptions);
      
      _logger.info('ONNX model loaded: ${config.modelName}');
    } catch (e) {
      _logger.error('Failed to load ONNX model', error: e);
      throw Exception('Failed to load ONNX model: $e');
    }
  }
  
  /// Generate journal entry for a specific date
  Future<JournalEntry> generateJournalEntry({
    required DateTime date,
    Map<String, dynamic>? customContext,
  }) async {
    try {
      if (!_isInitialized) {
        _logger.warning('AI service not initialized, using fallback generation');
        return _generateFallbackEntry(date, customContext);
      }
      
      // Aggregate data for the date
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(const Duration(days: 1));
      
      final aggregatedData = await _attributionService.aggregateDataForPeriod(
        startDate: startDate,
        endDate: endDate,
      );
      
      // Synthesize data into context
      final context = _synthesizeContext(aggregatedData, customContext);
      
      // Generate content using AI model
      final content = await _generateContent(context);
      
      // Generate summary
      final summary = await _generateSummary(content);
      
      // Extract highlights
      final highlights = _extractHighlights(content, aggregatedData);
      
      // Create journal entry
      final entry = JournalEntry(
        id: 'journal_${date.millisecondsSinceEpoch}',
        date: date,
        content: content,
        summary: summary,
        highlights: highlights,
        metadata: context,
        attributions: aggregatedData.expand((e) => e.attributions).toList(),
      );
      
      _logger.info('Generated journal entry for ${date.toIso8601String()}');
      
      return entry;
    } catch (e, stack) {
      _logger.error('Failed to generate journal entry', error: e, stackTrace: stack);
      return _generateFallbackEntry(date, customContext);
    }
  }
  
  /// Synthesize context from aggregated data
  Map<String, dynamic> _synthesizeContext(
    List<AttributedDataEntry> entries,
    Map<String, dynamic>? customContext,
  ) {
    final context = <String, dynamic>{};
    
    // Extract events
    final events = entries
        .where((e) => e.hasSource(DataSourceType.calendar))
        .map((e) => {
          'title': e.title,
          'time': e.timestamp.toIso8601String(),
          'description': e.description,
        })
        .toList();
    
    // Extract health data
    final healthData = entries
        .where((e) => e.hasSource(DataSourceType.health))
        .map((e) => e.data)
        .toList();
    
    // Extract photo metadata
    final photos = entries
        .where((e) => e.hasSource(DataSourceType.photos))
        .map((e) => {
          'time': e.timestamp.toIso8601String(),
          'location': e.data['location'],
          'tags': e.tags.toList(),
        })
        .toList();
    
    // Build context
    context['events'] = events;
    context['health'] = healthData;
    context['photos'] = photos;
    context['activities'] = _extractActivities(entries);
    context['moments'] = _extractNotableMoments(entries);
    
    // Merge custom context
    if (customContext != null) {
      context.addAll(customContext);
    }
    
    return context;
  }
  
  /// Extract activities from entries
  List<String> _extractActivities(List<AttributedDataEntry> entries) {
    final activities = <String>[];
    
    for (final entry in entries) {
      // Extract from tags
      for (final tag in entry.tags) {
        if (_isActivityTag(tag)) {
          activities.add(tag);
        }
      }
      
      // Extract from health data
      if (entry.hasSource(DataSourceType.health)) {
        final workouts = entry.data['workouts'] as List?;
        if (workouts != null) {
          for (final workout in workouts) {
            activities.add(workout['type'] ?? 'Exercise');
          }
        }
      }
    }
    
    return activities.toSet().toList();
  }
  
  /// Extract notable moments
  List<String> _extractNotableMoments(List<AttributedDataEntry> entries) {
    final moments = <String>[];
    
    for (final entry in entries) {
      // High-priority events
      if (entry.title.isNotEmpty && entry.description != null) {
        moments.add('${entry.title}: ${entry.description}');
      }
      
      // Significant health achievements
      if (entry.hasSource(DataSourceType.health)) {
        final steps = entry.data['steps'] as int?;
        if (steps != null && steps > 10000) {
          moments.add('Reached $steps steps today!');
        }
      }
    }
    
    return moments.take(5).toList();
  }
  
  /// Generate content using AI model
  Future<String> _generateContent(Map<String, dynamic> context) async {
    if (!_isInitialized || _currentModel == null) {
      return _generateFallbackContent(context);
    }
    
    try {
      // Format prompt
      final prompt = _formatPrompt(_defaultPromptTemplate, context);
      
      // Run inference based on model format
      if (_currentModel!.format == ModelFormat.tflite) {
        return await _runTFLiteInference(prompt);
      } else {
        return await _runONNXInference(prompt);
      }
    } catch (e) {
      _logger.error('Failed to generate content with AI model', error: e);
      return _generateFallbackContent(context);
    }
  }
  
  /// Run TFLite inference
  Future<String> _runTFLiteInference(String prompt) async {
    if (_tfliteInterpreter == null) {
      throw Exception('TFLite interpreter not initialized');
    }
    
    try {
      // Tokenize input (simplified - real implementation would use proper tokenizer)
      final input = _tokenizeInput(prompt);
      
      // Prepare output buffer
      final output = List.filled(_currentModel!.maxOutputLength, 0);
      
      // Run inference
      _tfliteInterpreter!.run(input, output);
      
      // Decode output (simplified - real implementation would use proper decoder)
      return _decodeOutput(output);
    } catch (e) {
      _logger.error('TFLite inference failed', error: e);
      throw e;
    }
  }
  
  /// Run ONNX inference
  Future<String> _runONNXInference(String prompt) async {
    if (_onnxSession == null) {
      throw Exception('ONNX session not initialized');
    }
    
    try {
      // Tokenize input
      final input = _tokenizeInput(prompt);
      
      // Create input tensor
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        input,
        [1, input.length],
      );
      
      // Run inference
      final runOptions = OrtRunOptions();
      final outputs = _onnxSession!.run(
        runOptions,
        {'input': inputTensor},
      );
      
      // Get output tensor
      final outputTensor = outputs.first?.value as List;
      
      // Decode output
      return _decodeOutput(outputTensor);
    } catch (e) {
      _logger.error('ONNX inference failed', error: e);
      throw e;
    }
  }
  
  /// Generate summary of content
  Future<String> _generateSummary(String content) async {
    if (!_isInitialized) {
      return _generateFallbackSummary(content);
    }
    
    try {
      final prompt = _summaryPromptTemplate.replaceAll('{content}', content);
      
      if (_currentModel!.format == ModelFormat.tflite) {
        return await _runTFLiteInference(prompt);
      } else {
        return await _runONNXInference(prompt);
      }
    } catch (e) {
      _logger.error('Failed to generate summary', error: e);
      return _generateFallbackSummary(content);
    }
  }
  
  /// Extract highlights from content
  List<String> _extractHighlights(
    String content,
    List<AttributedDataEntry> entries,
  ) {
    final highlights = <String>[];
    
    // Extract from notable moments
    for (final entry in entries) {
      if (entry.title.isNotEmpty) {
        highlights.add(entry.title);
      }
    }
    
    // Extract key phrases from content (simplified)
    final sentences = content.split('. ');
    for (final sentence in sentences) {
      if (sentence.contains('amazing') || 
          sentence.contains('wonderful') ||
          sentence.contains('achieved') ||
          sentence.contains('milestone')) {
        highlights.add(sentence.trim());
      }
    }
    
    return highlights.take(5).toList();
  }
  
  /// Generate fallback entry when AI is not available
  JournalEntry _generateFallbackEntry(
    DateTime date,
    Map<String, dynamic>? customContext,
  ) {
    final content = _generateFallbackContent(customContext ?? {});
    final summary = _generateFallbackSummary(content);
    
    return JournalEntry(
      id: 'journal_fallback_${date.millisecondsSinceEpoch}',
      date: date,
      content: content,
      summary: summary,
      highlights: ['Daily activities recorded'],
      metadata: customContext ?? {},
    );
  }
  
  /// Generate fallback content
  String _generateFallbackContent(Map<String, dynamic> context) {
    final buffer = StringBuffer();
    
    buffer.writeln('Today\'s Journal Entry\n');
    
    // Add events
    final events = context['events'] as List?;
    if (events != null && events.isNotEmpty) {
      buffer.writeln('Events:');
      for (final event in events) {
        buffer.writeln('• ${event['title']}');
      }
      buffer.writeln();
    }
    
    // Add activities
    final activities = context['activities'] as List?;
    if (activities != null && activities.isNotEmpty) {
      buffer.writeln('Activities:');
      for (final activity in activities) {
        buffer.writeln('• $activity');
      }
      buffer.writeln();
    }
    
    // Add health data
    final health = context['health'] as List?;
    if (health != null && health.isNotEmpty) {
      buffer.writeln('Health Summary:');
      for (final data in health) {
        if (data['steps'] != null) {
          buffer.writeln('• Steps: ${data['steps']}');
        }
        if (data['calories'] != null) {
          buffer.writeln('• Calories: ${data['calories']}');
        }
      }
      buffer.writeln();
    }
    
    // Add moments
    final moments = context['moments'] as List?;
    if (moments != null && moments.isNotEmpty) {
      buffer.writeln('Notable Moments:');
      for (final moment in moments) {
        buffer.writeln('• $moment');
      }
    }
    
    return buffer.toString();
  }
  
  /// Generate fallback summary
  String _generateFallbackSummary(String content) {
    final lines = content.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    
    if (lines.isEmpty) {
      return 'A quiet day with no recorded activities.';
    }
    
    final eventCount = lines.where((l) => l.contains('•')).length;
    return 'Recorded $eventCount activities and events today.';
  }
  
  /// Format prompt with context
  String _formatPrompt(String template, Map<String, dynamic> context) {
    var prompt = template;
    
    prompt = prompt.replaceAll('{date}', DateTime.now().toIso8601String());
    prompt = prompt.replaceAll('{events}', jsonEncode(context['events'] ?? []));
    prompt = prompt.replaceAll('{activities}', jsonEncode(context['activities'] ?? []));
    prompt = prompt.replaceAll('{health}', jsonEncode(context['health'] ?? []));
    prompt = prompt.replaceAll('{photos}', jsonEncode(context['photos'] ?? []));
    prompt = prompt.replaceAll('{moments}', jsonEncode(context['moments'] ?? []));
    
    return prompt;
  }
  
  /// Tokenize input (simplified - real implementation would use proper tokenizer)
  List<int> _tokenizeInput(String input) {
    // Simple character-level tokenization for demonstration
    // Real implementation would use BPE or WordPiece tokenizer
    return input.codeUnits.take(_currentModel!.maxInputLength).toList();
  }
  
  /// Decode output (simplified - real implementation would use proper decoder)
  String _decodeOutput(List<dynamic> output) {
    // Simple character-level decoding for demonstration
    // Real implementation would use BPE or WordPiece decoder
    return String.fromCharCodes(
      output.where((v) => v > 0 && v < 128).cast<int>(),
    );
  }
  
  /// Get model path
  Future<String> _getModelPath(String modelPath) async {
    // Check if it's an asset path
    if (modelPath.startsWith('assets/')) {
      return modelPath;
    }
    
    // Check if it's an absolute path
    if (File(modelPath).existsSync()) {
      return modelPath;
    }
    
    // Check in app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final fullPath = path.join(dir.path, 'models', modelPath);
    
    if (File(fullPath).existsSync()) {
      return fullPath;
    }
    
    // Default to asset path
    return 'assets/models/$modelPath';
  }
  
  /// Load model bytes
  Future<Uint8List> _loadModelBytes(String modelPath) async {
    if (modelPath.startsWith('assets/')) {
      final data = await rootBundle.load(modelPath);
      return data.buffer.asUint8List();
    }
    
    final file = File(modelPath);
    return await file.readAsBytes();
  }
  
  /// Get default model configuration
  AIModelConfig _getDefaultModelConfig() {
    // Default to a lightweight model suitable for mobile
    return const AIModelConfig(
      modelName: 'mobile_gpt2',
      format: ModelFormat.tflite,
      modelPath: 'assets/models/gpt2_mobile.tflite',
      maxInputLength: 256,
      maxOutputLength: 128,
    );
  }
  
  /// Check if tag is an activity
  bool _isActivityTag(String tag) {
    const activityTags = {
      'workout', 'exercise', 'run', 'walk', 'gym',
      'yoga', 'meditation', 'sports', 'cycling', 'swimming',
    };
    return activityTags.contains(tag.toLowerCase());
  }
  
  /// Dispose resources
  void dispose() {
    _tfliteInterpreter?.close();
    _onnxSession?.release();
    _isInitialized = false;
    _logger.info('AI service disposed');
  }
}