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

  /// Load the HAR model from assets (with fallback support)
  Future<void> loadModel({bool forceDownload = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isModelLoaded && !forceDownload) {
      _logger.info('HAR model already loaded');
      return;
    }

    try {
      _logger.info('Loading HAR model from assets...');

      // Try to load the model directly from assets
      const assetPath = 'assets/models/preprocessing/har_model.tflite';
      try {
        await _tfliteManager.loadModelFromAsset(assetPath, modelId: _modelId);
        _isModelLoaded = true;
        _logger.info('HAR model loaded successfully from assets');

        // Log model details
        _logModelDetails();
      } catch (e) {
        _logger.warning('HAR model not available, using fallback mode for testing: $e');
        // Set as loaded to allow testing with synthetic data using heuristic fallback
        _isModelLoaded = false; // Keep false to indicate fallback mode
      }
    } catch (e, stack) {
      _logger.error('Failed to initialize HAR model loading', error: e, stackTrace: stack);
      _isModelLoaded = false;
      throw Exception('Failed to initialize HAR model loading: $e');
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

  /// Test the HAR model with synthetic data (supports fallback mode)
  Future<Map<String, dynamic>> testWithSyntheticData(String activity) async {
    await loadModel(); // Always attempt to load model first

    try {
      _logger.info('Testing HAR with synthetic $activity data...');

      if (_isModelLoaded) {
        // Use actual model inference
        return await _testWithModelInference(activity);
      } else {
        // Use fallback heuristic testing
        return await _testWithHeuristicFallback(activity);
      }
    } catch (e, stack) {
      _logger.error('HAR test failed', error: e, stackTrace: stack);
      throw Exception('HAR test failed: $e');
    }
  }

  /// Test with actual model inference
  Future<Map<String, dynamic>> _testWithModelInference(String activity) async {
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
      'mode': 'model_inference',
    };

    _logger.info('Model inference completed:');
    _logger.info('  Input: $activity');
    _logger.info('  Predicted: $predictedActivity (${(confidence * 100).toStringAsFixed(1)}%)');
    _logger.info('  Inference time: ${inferenceTime.inMilliseconds}ms');

    return result;
  }

  /// Test with heuristic fallback (simulates ActivityRecognitionService fallback)
  Future<Map<String, dynamic>> _testWithHeuristicFallback(String activity) async {
    _logger.info('Using heuristic fallback for testing');

    // Generate synthetic sensor data with default parameters
    final sensorData = generateSyntheticSensorData(
      activity: activity,
      windowSize: 128,
      features: 6,
    );

    // Simulate heuristic analysis (similar to ActivityRecognitionService._heuristicRecognition)
    final startTime = DateTime.now();
    final features = _extractHeuristicFeatures(sensorData);
    final inferenceTime = DateTime.now().difference(startTime);

    // Simple heuristic classification
    String predictedActivity;
    double confidence;

    final avgAccelMagnitude = features['accelMagnitude']!;
    final stdAccel = features['accelStd']!;
    final avgGyroMagnitude = features['gyroMagnitude']!;

    if (avgAccelMagnitude < 0.5 && stdAccel < 0.2) {
      predictedActivity = 'Sitting';
      confidence = 0.8;
    } else if (avgAccelMagnitude < 2.0 && stdAccel < 1.0) {
      predictedActivity = 'Walking';
      confidence = 0.7;
    } else if (avgAccelMagnitude < 5.0 && stdAccel < 2.0) {
      predictedActivity = 'Running';
      confidence = 0.6;
    } else if (avgGyroMagnitude > 2.0) {
      predictedActivity = 'Cycling';
      confidence = 0.5;
    } else {
      predictedActivity = 'Standing';
      confidence = 0.4;
    }

    final result = {
      'inputActivity': activity,
      'predictedActivity': predictedActivity,
      'confidence': confidence,
      'inferenceTimeMs': inferenceTime.inMilliseconds,
      'allPredictions': {
        predictedActivity: confidence,
      },
      'mode': 'heuristic_fallback',
      'features': features,
    };

    _logger.info('Heuristic fallback completed:');
    _logger.info('  Input: $activity');
    _logger.info('  Predicted: $predictedActivity (${(confidence * 100).toStringAsFixed(1)}%)');
    _logger.info('  Analysis time: ${inferenceTime.inMilliseconds}ms');

    return result;
  }

  /// Extract heuristic features from sensor data (similar to ActivityRecognitionService)
  Map<String, double> _extractHeuristicFeatures(Float32List data) {
    final features = <String, double>{};

    // Calculate accelerometer magnitude (every 6th element starting from 0,1,2)
    double sumAccelMag = 0.0;
    double sumAccelMagSq = 0.0;
    int accelCount = 0;

    for (int i = 0; i < data.length; i += 6) {
      if (i + 2 < data.length) {
        final magnitude = sqrt(data[i] * data[i] + data[i + 1] * data[i + 1] + data[i + 2] * data[i + 2]);
        sumAccelMag += magnitude;
        sumAccelMagSq += magnitude * magnitude;
        accelCount++;
      }
    }

    if (accelCount > 0) {
      final avgMag = sumAccelMag / accelCount;
      final variance = (sumAccelMagSq / accelCount) - (avgMag * avgMag);
      features['accelMagnitude'] = avgMag;
      features['accelStd'] = sqrt(variance);
    } else {
      features['accelMagnitude'] = 0.0;
      features['accelStd'] = 0.0;
    }

    // Calculate gyroscope magnitude (every 6th element starting from 3,4,5)
    double sumGyroMag = 0.0;
    int gyroCount = 0;

    for (int i = 3; i < data.length; i += 6) {
      if (i + 2 < data.length) {
        final magnitude = sqrt(data[i] * data[i] + data[i + 1] * data[i + 1] + data[i + 2] * data[i + 2]);
        sumGyroMag += magnitude;
        gyroCount++;
      }
    }

    features['gyroMagnitude'] = gyroCount > 0 ? sumGyroMag / gyroCount : 0.0;

    return features;
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
      'mode': _isModelLoaded ? 'model_inference' : 'heuristic_fallback',
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