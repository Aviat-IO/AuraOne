import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../utils/logger.dart';
import 'model_download_manager.dart';
import 'tflite_manager.dart';

/// Test service for Human Activity Recognition (HAR) model
class HARTestService {
  static final _logger = AppLogger('HARTestService');
  static final _instance = HARTestService._internal();

  factory HARTestService() => _instance;
  HARTestService._internal();

  // Managers
  final ModelDownloadManager _downloadManager = ModelDownloadManager();
  final TFLiteManager _tfliteManager = TFLiteManager();

  // Model configuration
  static const String _modelId = 'har_cnn_lstm';
  bool _isInitialized = false;
  bool _isModelLoaded = false;

  // Activity labels (typical HAR activities)
  static const List<String> _activityLabels = [
    'Walking',
    'Walking Upstairs',
    'Walking Downstairs',
    'Sitting',
    'Standing',
    'Laying',
    'Running',
    'Cycling',
  ];

  /// Initialize the HAR test service
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.info('HAR test service already initialized');
      return;
    }

    try {
      _logger.info('Initializing HAR test service...');

      // Initialize managers
      await _downloadManager.initialize();
      await _tfliteManager.initialize();

      _isInitialized = true;
      _logger.info('HAR test service initialized');
    } catch (e, stack) {
      _logger.error('Failed to initialize HAR test service',
          error: e, stackTrace: stack);
      throw Exception('Failed to initialize HAR test service: $e');
    }
  }

  /// Download and load the HAR model
  Future<void> loadModel({bool forceDownload = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isModelLoaded && !forceDownload) {
      _logger.info('HAR model already loaded');
      return;
    }

    try {
      _logger.info('Loading HAR model...');

      // Check if model is downloaded
      String? modelPath = await _downloadManager.getModelPath(_modelId);

      if (modelPath == null || forceDownload) {
        _logger.info('Downloading HAR model...');

        // Subscribe to download progress
        final progressStream = _downloadManager.getDownloadProgress(_modelId);
        if (progressStream != null) {
          progressStream.listen((progress) {
            _logger.info('Download progress: ${(progress.progress * 100).toStringAsFixed(1)}%');
          });
        }

        modelPath = await _downloadManager.downloadModel(_modelId);
        _logger.info('HAR model downloaded to: $modelPath');
      }

      // Load the model with TFLite manager
      await _tfliteManager.loadModel(modelPath, modelId: _modelId);

      _isModelLoaded = true;
      _logger.info('HAR model loaded successfully');

      // Log model details
      _logModelDetails();
    } catch (e, stack) {
      _logger.error('Failed to load HAR model', error: e, stackTrace: stack);
      _isModelLoaded = false;
      throw Exception('Failed to load HAR model: $e');
    }
  }

  /// Log model details for debugging
  void _logModelDetails() {
    try {
      final inputShape = _tfliteManager.getInputShape(_modelId);
      final outputShape = _tfliteManager.getOutputShape(_modelId);

      _logger.info('HAR Model Details:');
      _logger.info('  Input shape: $inputShape');
      _logger.info('  Output shape: $outputShape');
      _logger.info('  Activity classes: ${_activityLabels.length}');
    } catch (e) {
      _logger.warning('Could not log model details: $e');
    }
  }

  /// Generate synthetic sensor data for testing
  Float32List generateSyntheticSensorData({
    required String activity,
    int windowSize = 128,
    int features = 6, // 3-axis accelerometer + 3-axis gyroscope
  }) {
    final random = Random();
    final data = Float32List(windowSize * features);

    // Generate patterns based on activity type
    for (int i = 0; i < windowSize; i++) {
      final baseIdx = i * features;

      switch (activity.toLowerCase()) {
        case 'walking':
          // Periodic pattern for walking
          data[baseIdx + 0] = sin(i * 0.2) * 2.0 + random.nextDouble() * 0.5; // Acc X
          data[baseIdx + 1] = cos(i * 0.2) * 1.5 + random.nextDouble() * 0.5; // Acc Y
          data[baseIdx + 2] = 9.8 + sin(i * 0.4) * 0.5; // Acc Z (gravity + motion)
          data[baseIdx + 3] = sin(i * 0.15) * 0.3; // Gyro X
          data[baseIdx + 4] = cos(i * 0.15) * 0.2; // Gyro Y
          data[baseIdx + 5] = random.nextDouble() * 0.1; // Gyro Z
          break;

        case 'running':
          // Higher frequency pattern for running
          data[baseIdx + 0] = sin(i * 0.4) * 3.0 + random.nextDouble() * 0.8;
          data[baseIdx + 1] = cos(i * 0.4) * 2.5 + random.nextDouble() * 0.8;
          data[baseIdx + 2] = 9.8 + sin(i * 0.8) * 1.0;
          data[baseIdx + 3] = sin(i * 0.3) * 0.5;
          data[baseIdx + 4] = cos(i * 0.3) * 0.4;
          data[baseIdx + 5] = random.nextDouble() * 0.2;
          break;

        case 'sitting':
        case 'standing':
          // Minimal motion
          data[baseIdx + 0] = random.nextDouble() * 0.1;
          data[baseIdx + 1] = random.nextDouble() * 0.1;
          data[baseIdx + 2] = 9.8 + random.nextDouble() * 0.05; // Mostly gravity
          data[baseIdx + 3] = random.nextDouble() * 0.02;
          data[baseIdx + 4] = random.nextDouble() * 0.02;
          data[baseIdx + 5] = random.nextDouble() * 0.02;
          break;

        case 'cycling':
          // Cyclic pattern with rotation
          data[baseIdx + 0] = sin(i * 0.3) * 1.5 + random.nextDouble() * 0.3;
          data[baseIdx + 1] = cos(i * 0.3) * 1.0 + random.nextDouble() * 0.3;
          data[baseIdx + 2] = 9.8 + sin(i * 0.6) * 0.3;
          data[baseIdx + 3] = sin(i * 0.25) * 0.4;
          data[baseIdx + 4] = cos(i * 0.25) * 0.3;
          data[baseIdx + 5] = sin(i * 0.1) * 0.2;
          break;

        default:
          // Random data for unknown activity
          for (int j = 0; j < features; j++) {
            data[baseIdx + j] = random.nextDouble() * 2.0 - 1.0;
          }
      }
    }

    return data;
  }

  /// Test the HAR model with synthetic data
  Future<Map<String, dynamic>> testWithSyntheticData(String activity) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    try {
      _logger.info('Testing HAR model with synthetic $activity data...');

      // Get model input shape
      final inputShape = _tfliteManager.getInputShape(_modelId);
      _logger.info('Model expects input shape: $inputShape');

      // Generate synthetic sensor data
      final sensorData = generateSyntheticSensorData(
        activity: activity,
        windowSize: inputShape.length > 1 ? inputShape[1] : 128,
        features: inputShape.length > 2 ? inputShape[2] : 6,
      );

      // Reshape data to match model input
      final input = _reshapeInput(sensorData, inputShape);

      // Run inference
      final startTime = DateTime.now();
      final outputs = await _tfliteManager.runInference(_modelId, [input]);
      final inferenceTime = DateTime.now().difference(startTime);

      // Process outputs
      final predictions = outputs[0] as List<double>;
      final predictedActivity = _getPredictedActivity(predictions);
      final confidence = _getConfidence(predictions);

      final result = {
        'inputActivity': activity,
        'predictedActivity': predictedActivity,
        'confidence': confidence,
        'inferenceTimeMs': inferenceTime.inMilliseconds,
        'allPredictions': _getAllPredictions(predictions),
        'modelId': _modelId,
        'inputShape': inputShape,
        'outputShape': _tfliteManager.getOutputShape(_modelId),
      };

      _logger.info('Test completed:');
      _logger.info('  Input: $activity');
      _logger.info('  Predicted: $predictedActivity (${(confidence * 100).toStringAsFixed(1)}%)');
      _logger.info('  Inference time: ${inferenceTime.inMilliseconds}ms');

      return result;
    } catch (e, stack) {
      _logger.error('HAR test failed', error: e, stackTrace: stack);
      throw Exception('HAR test failed: $e');
    }
  }

  /// Test with real sensor data
  Future<Map<String, dynamic>> testWithRealData(Float32List sensorData) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    try {
      _logger.info('Testing HAR model with real sensor data...');

      // Get model input shape
      final inputShape = _tfliteManager.getInputShape(_modelId);

      // Reshape data to match model input
      final input = _reshapeInput(sensorData, inputShape);

      // Run inference
      final startTime = DateTime.now();
      final outputs = await _tfliteManager.runInference(_modelId, [input]);
      final inferenceTime = DateTime.now().difference(startTime);

      // Process outputs
      final predictions = outputs[0] as List<double>;
      final predictedActivity = _getPredictedActivity(predictions);
      final confidence = _getConfidence(predictions);

      return {
        'predictedActivity': predictedActivity,
        'confidence': confidence,
        'inferenceTimeMs': inferenceTime.inMilliseconds,
        'allPredictions': _getAllPredictions(predictions),
      };
    } catch (e, stack) {
      _logger.error('HAR test with real data failed', error: e, stackTrace: stack);
      throw Exception('HAR test failed: $e');
    }
  }

  /// Reshape input data to match model requirements
  List<double> _reshapeInput(Float32List data, List<int> targetShape) {
    // Most HAR models expect shape [batch_size, sequence_length, features]
    // For single inference, batch_size = 1

    if (targetShape.isEmpty) {
      return data.toList();
    }

    // If model expects different shape, reshape accordingly
    // This is a simplified reshaping - adjust based on actual model requirements
    final reshaped = <double>[];

    if (targetShape.length == 3) {
      // [batch, sequence, features]
      final sequenceLength = targetShape[1];
      final features = targetShape[2];
      final expectedSize = sequenceLength * features;

      if (data.length >= expectedSize) {
        // Take first expectedSize elements
        reshaped.addAll(data.take(expectedSize));
      } else {
        // Pad with zeros if needed
        reshaped.addAll(data);
        reshaped.addAll(List.filled(expectedSize - data.length, 0.0));
      }
    } else {
      // Use data as-is
      reshaped.addAll(data);
    }

    return reshaped;
  }

  /// Get predicted activity from model output
  String _getPredictedActivity(List<double> predictions) {
    if (predictions.isEmpty) {
      return 'Unknown';
    }

    // Find index of maximum probability
    double maxProb = predictions[0];
    int maxIndex = 0;

    for (int i = 1; i < predictions.length; i++) {
      if (predictions[i] > maxProb) {
        maxProb = predictions[i];
        maxIndex = i;
      }
    }

    // Return corresponding activity label
    if (maxIndex < _activityLabels.length) {
      return _activityLabels[maxIndex];
    }

    return 'Unknown (index: $maxIndex)';
  }

  /// Get confidence score
  double _getConfidence(List<double> predictions) {
    if (predictions.isEmpty) {
      return 0.0;
    }

    // Return maximum probability as confidence
    return predictions.reduce(max);
  }

  /// Get all predictions with labels
  Map<String, double> _getAllPredictions(List<double> predictions) {
    final result = <String, double>{};

    for (int i = 0; i < predictions.length && i < _activityLabels.length; i++) {
      result[_activityLabels[i]] = predictions[i];
    }

    return result;
  }

  /// Run comprehensive test suite
  Future<List<Map<String, dynamic>>> runTestSuite() async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    final results = <Map<String, dynamic>>[];

    // Test each activity type
    for (final activity in ['Walking', 'Running', 'Sitting', 'Standing', 'Cycling']) {
      try {
        final result = await testWithSyntheticData(activity);
        results.add(result);
      } catch (e) {
        _logger.error('Test failed for $activity: $e');
        results.add({
          'inputActivity': activity,
          'error': e.toString(),
        });
      }
    }

    // Calculate accuracy
    int correct = 0;
    for (final result in results) {
      if (result['inputActivity'] == result['predictedActivity']) {
        correct++;
      }
    }

    final accuracy = correct / results.length;
    _logger.info('Test suite completed. Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%');

    return results;
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'modelLoaded': _isModelLoaded,
      'modelId': _modelId,
      'accelerationStatus': _tfliteManager.getAccelerationStatus(),
      'activityClasses': _activityLabels,
    };
  }

  /// Clean up resources
  void dispose() {
    _tfliteManager.releaseModel(_modelId);
    _isModelLoaded = false;
    _isInitialized = false;
  }
}