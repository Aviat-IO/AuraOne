import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import 'ai_service.dart';

/// Model metadata
class ModelMetadata {
  final String id;
  final String name;
  final String description;
  final ModelFormat format;
  final int sizeBytes;
  final String downloadUrl;
  final String checksum;
  final Map<String, dynamic> config;
  final DateTime releaseDate;
  final double accuracy;
  final int inferenceTimeMs;
  
  ModelMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.format,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.checksum,
    required this.config,
    required this.releaseDate,
    this.accuracy = 0.0,
    this.inferenceTimeMs = 0,
  });
  
  factory ModelMetadata.fromJson(Map<String, dynamic> json) {
    return ModelMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      format: ModelFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => ModelFormat.tflite,
      ),
      sizeBytes: json['sizeBytes'] as int,
      downloadUrl: json['downloadUrl'] as String,
      checksum: json['checksum'] as String,
      config: json['config'] as Map<String, dynamic>? ?? {},
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      inferenceTimeMs: json['inferenceTimeMs'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'format': format.name,
    'sizeBytes': sizeBytes,
    'downloadUrl': downloadUrl,
    'checksum': checksum,
    'config': config,
    'releaseDate': releaseDate.toIso8601String(),
    'accuracy': accuracy,
    'inferenceTimeMs': inferenceTimeMs,
  };
}

/// Download progress callback
typedef DownloadProgressCallback = void Function(double progress, int bytesReceived, int totalBytes);

/// Model manager for downloading and managing AI models
class ModelManager {
  static final _logger = AppLogger('ModelManager');
  static final _instance = ModelManager._internal();
  
  factory ModelManager() => _instance;
  ModelManager._internal();
  
  // Available models (in production, this would come from a server)
  static final List<ModelMetadata> availableModels = [
    ModelMetadata(
      id: 'gpt2_mobile_v1',
      name: 'GPT-2 Mobile',
      description: 'Lightweight GPT-2 model optimized for mobile devices',
      format: ModelFormat.tflite,
      sizeBytes: 20 * 1024 * 1024, // 20MB
      downloadUrl: 'https://example.com/models/gpt2_mobile.tflite',
      checksum: 'abc123',
      config: {
        'maxInputLength': 256,
        'maxOutputLength': 128,
        'vocabSize': 50257,
      },
      releaseDate: DateTime(2024, 1, 1),
      accuracy: 0.85,
      inferenceTimeMs: 100,
    ),
    ModelMetadata(
      id: 'gemma_nano_v1',
      name: 'Gemma Nano',
      description: 'Google\'s Gemma model quantized for edge devices',
      format: ModelFormat.tflite,
      sizeBytes: 50 * 1024 * 1024, // 50MB
      downloadUrl: 'https://example.com/models/gemma_nano.tflite',
      checksum: 'def456',
      config: {
        'maxInputLength': 512,
        'maxOutputLength': 256,
        'vocabSize': 32000,
      },
      releaseDate: DateTime(2024, 2, 1),
      accuracy: 0.92,
      inferenceTimeMs: 200,
    ),
    ModelMetadata(
      id: 'llama_mobile_v1',
      name: 'LLaMA Mobile',
      description: 'Quantized LLaMA model for mobile inference',
      format: ModelFormat.onnx,
      sizeBytes: 100 * 1024 * 1024, // 100MB
      downloadUrl: 'https://example.com/models/llama_mobile.onnx',
      checksum: 'ghi789',
      config: {
        'maxInputLength': 1024,
        'maxOutputLength': 512,
        'vocabSize': 32000,
      },
      releaseDate: DateTime(2024, 3, 1),
      accuracy: 0.95,
      inferenceTimeMs: 500,
    ),
  ];
  
  /// Get models directory
  Future<Directory> getModelsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(path.join(appDir.path, 'models'));
    
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    
    return modelsDir;
  }
  
  /// Get installed models
  Future<List<ModelMetadata>> getInstalledModels() async {
    try {
      final modelsDir = await getModelsDirectory();
      final metadataFile = File(path.join(modelsDir.path, 'models.json'));
      
      if (!await metadataFile.exists()) {
        return [];
      }
      
      final content = await metadataFile.readAsString();
      final List<dynamic> json = jsonDecode(content);
      
      return json.map((m) => ModelMetadata.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      _logger.error('Failed to get installed models', error: e);
      return [];
    }
  }
  
  /// Check if model is installed
  Future<bool> isModelInstalled(String modelId) async {
    final installedModels = await getInstalledModels();
    return installedModels.any((m) => m.id == modelId);
  }
  
  /// Download model
  Future<void> downloadModel(
    ModelMetadata model, {
    DownloadProgressCallback? onProgress,
  }) async {
    try {
      _logger.info('Downloading model: ${model.name}');
      
      // Check if already installed
      if (await isModelInstalled(model.id)) {
        _logger.info('Model already installed: ${model.name}');
        return;
      }
      
      // Get models directory
      final modelsDir = await getModelsDirectory();
      final modelFile = File(path.join(modelsDir.path, '${model.id}.${model.format.name}'));
      
      // Download model
      final request = http.Request('GET', Uri.parse(model.downloadUrl));
      final response = await request.send();
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download model: ${response.statusCode}');
      }
      
      // Get total size
      final totalBytes = response.contentLength ?? model.sizeBytes;
      var bytesReceived = 0;
      
      // Create file sink
      final sink = modelFile.openWrite();
      
      // Download with progress
      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          bytesReceived += chunk.length;
          
          if (onProgress != null) {
            final progress = bytesReceived / totalBytes;
            onProgress(progress, bytesReceived, totalBytes);
          }
        },
        onDone: () async {
          await sink.close();
          _logger.info('Model downloaded: ${model.name}');
        },
        onError: (error) {
          sink.close();
          modelFile.deleteSync();
          throw error;
        },
      ).asFuture();
      
      // Save metadata
      await _saveModelMetadata(model);
      
      _logger.info('Model installed successfully: ${model.name}');
    } catch (e, stack) {
      _logger.error('Failed to download model', error: e, stackTrace: stack);
      throw Exception('Failed to download model: $e');
    }
  }
  
  /// Delete model
  Future<void> deleteModel(String modelId) async {
    try {
      final modelsDir = await getModelsDirectory();
      final installedModels = await getInstalledModels();
      
      final model = installedModels.firstWhere(
        (m) => m.id == modelId,
        orElse: () => throw Exception('Model not found'),
      );
      
      // Delete model file
      final modelFile = File(path.join(modelsDir.path, '${model.id}.${model.format.name}'));
      if (await modelFile.exists()) {
        await modelFile.delete();
      }
      
      // Update metadata
      installedModels.removeWhere((m) => m.id == modelId);
      await _saveInstalledModels(installedModels);
      
      _logger.info('Model deleted: $modelId');
    } catch (e) {
      _logger.error('Failed to delete model', error: e);
      throw Exception('Failed to delete model: $e');
    }
  }
  
  /// Get model path
  Future<String> getModelPath(String modelId) async {
    final modelsDir = await getModelsDirectory();
    final installedModels = await getInstalledModels();
    
    final model = installedModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw Exception('Model not found'),
    );
    
    return path.join(modelsDir.path, '${model.id}.${model.format.name}');
  }
  
  /// Get recommended model based on device capabilities
  Future<ModelMetadata?> getRecommendedModel() async {
    try {
      // Get device info
      final freeMemory = await _getAvailableMemory();
      final isHighPerformance = await _isHighPerformanceDevice();
      
      // Filter models based on device capabilities
      final suitableModels = availableModels.where((model) {
        // Check size constraints
        if (model.sizeBytes > freeMemory * 0.1) {
          return false; // Model too large (>10% of free memory)
        }
        
        // Check performance requirements
        if (!isHighPerformance && model.inferenceTimeMs > 300) {
          return false; // Model too slow for device
        }
        
        return true;
      }).toList();
      
      if (suitableModels.isEmpty) {
        return null;
      }
      
      // Sort by accuracy and performance balance
      suitableModels.sort((a, b) {
        final scoreA = a.accuracy - (a.inferenceTimeMs / 1000);
        final scoreB = b.accuracy - (b.inferenceTimeMs / 1000);
        return scoreB.compareTo(scoreA);
      });
      
      return suitableModels.first;
    } catch (e) {
      _logger.error('Failed to get recommended model', error: e);
      return availableModels.first; // Return default model
    }
  }
  
  /// Create AI model configuration from metadata
  AIModelConfig createModelConfig(ModelMetadata model) {
    return AIModelConfig(
      modelName: model.name,
      format: model.format,
      modelPath: '${model.id}.${model.format.name}',
      maxInputLength: model.config['maxInputLength'] as int? ?? 256,
      maxOutputLength: model.config['maxOutputLength'] as int? ?? 128,
      metadata: model.config,
    );
  }
  
  /// Optimize model for device
  Future<void> optimizeModel(String modelId) async {
    try {
      _logger.info('Optimizing model: $modelId');
      
      // Get model path
      final modelPath = await getModelPath(modelId);
      
      // In a real implementation, this would:
      // 1. Quantize the model (int8, int16)
      // 2. Prune unnecessary layers
      // 3. Apply device-specific optimizations
      // 4. Cache optimized version
      
      _logger.info('Model optimization complete: $modelId');
    } catch (e) {
      _logger.error('Failed to optimize model', error: e);
    }
  }
  
  /// Benchmark model performance
  Future<Map<String, dynamic>> benchmarkModel(String modelId) async {
    try {
      _logger.info('Benchmarking model: $modelId');
      
      final results = <String, dynamic>{};
      final modelPath = await getModelPath(modelId);
      
      // Load model
      final startLoad = DateTime.now();
      // Model loading logic here
      final loadTime = DateTime.now().difference(startLoad).inMilliseconds;
      results['loadTimeMs'] = loadTime;
      
      // Run inference benchmark
      const testPrompt = 'Hello, this is a test prompt for benchmarking.';
      final startInference = DateTime.now();
      // Inference logic here
      final inferenceTime = DateTime.now().difference(startInference).inMilliseconds;
      results['inferenceTimeMs'] = inferenceTime;
      
      // Memory usage
      results['memoryUsageMB'] = await _getModelMemoryUsage(modelPath);
      
      // Accuracy test (would need test dataset)
      results['accuracy'] = 0.85; // Placeholder
      
      _logger.info('Benchmark complete: $results');
      return results;
    } catch (e) {
      _logger.error('Failed to benchmark model', error: e);
      return {};
    }
  }
  
  /// Save model metadata
  Future<void> _saveModelMetadata(ModelMetadata model) async {
    final installedModels = await getInstalledModels();
    installedModels.add(model);
    await _saveInstalledModels(installedModels);
  }
  
  /// Save installed models list
  Future<void> _saveInstalledModels(List<ModelMetadata> models) async {
    final modelsDir = await getModelsDirectory();
    final metadataFile = File(path.join(modelsDir.path, 'models.json'));
    
    final json = models.map((m) => m.toJson()).toList();
    await metadataFile.writeAsString(jsonEncode(json));
  }
  
  /// Get available memory
  Future<int> _getAvailableMemory() async {
    // Platform-specific implementation would go here
    // For now, return a reasonable default (1GB)
    return 1024 * 1024 * 1024;
  }
  
  /// Check if device is high performance
  Future<bool> _isHighPerformanceDevice() async {
    // Platform-specific implementation would check:
    // - CPU cores and speed
    // - Available RAM
    // - GPU capabilities
    // For now, return true for development
    return true;
  }
  
  /// Get model memory usage
  Future<int> _getModelMemoryUsage(String modelPath) async {
    final file = File(modelPath);
    if (await file.exists()) {
      final stats = await file.stat();
      return stats.size ~/ (1024 * 1024); // Convert to MB
    }
    return 0;
  }
}