import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../utils/logger.dart';

/// Activity types that can be recognized
enum ActivityType {
  stationary,
  walking,
  running,
  cycling,
  driving,
  unknown,
}

/// Activity recognition result
class ActivityRecognitionResult {
  final ActivityType activity;
  final double confidence;
  final DateTime timestamp;
  final Map<String, double> probabilities;

  ActivityRecognitionResult({
    required this.activity,
    required this.confidence,
    required this.timestamp,
    required this.probabilities,
  });

  Map<String, dynamic> toJson() => {
    'activity': activity.name,
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
    'probabilities': probabilities,
  };
}

/// Sensor data window for activity recognition
class SensorDataWindow {
  final List<AccelerometerEvent> accelerometer;
  final List<GyroscopeEvent> gyroscope;
  final DateTime startTime;
  final DateTime endTime;

  SensorDataWindow({
    required this.accelerometer,
    required this.gyroscope,
    required this.startTime,
    required this.endTime,
  });

  /// Convert to feature vector for model input
  Float32List toFeatureVector() {
    const windowSize = 50; // 50 samples (2.5 seconds at 20Hz)
    const features = 6; // 3-axis accelerometer + 3-axis gyroscope

    final vector = Float32List(windowSize * features);
    int index = 0;

    // Fill with sensor data
    for (int i = 0; i < windowSize; i++) {
      if (i < accelerometer.length) {
        vector[index++] = accelerometer[i].x.toDouble();
        vector[index++] = accelerometer[i].y.toDouble();
        vector[index++] = accelerometer[i].z.toDouble();
      } else {
        // Pad with zeros if not enough samples
        vector[index++] = 0.0;
        vector[index++] = 0.0;
        vector[index++] = 0.0;
      }

      if (i < gyroscope.length) {
        vector[index++] = gyroscope[i].x.toDouble();
        vector[index++] = gyroscope[i].y.toDouble();
        vector[index++] = gyroscope[i].z.toDouble();
      } else {
        vector[index++] = 0.0;
        vector[index++] = 0.0;
        vector[index++] = 0.0;
      }
    }

    return vector;
  }
}

/// Human Activity Recognition (HAR) service using CNN-LSTM model
class ActivityRecognitionService {
  static final _logger = AppLogger('ActivityRecognitionService');
  static final _instance = ActivityRecognitionService._internal();

  factory ActivityRecognitionService() => _instance;
  ActivityRecognitionService._internal();

  // Model management
  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  bool _isInitialized = false;

  // Sensor data collection
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  final List<AccelerometerEvent> _accelerometerBuffer = [];
  final List<GyroscopeEvent> _gyroscopeBuffer = [];
  DateTime _bufferStartTime = DateTime.now();

  // Activity stream
  final _activityController = StreamController<ActivityRecognitionResult>.broadcast();
  Stream<ActivityRecognitionResult> get activityStream => _activityController.stream;

  // Configuration
  static const int _windowSize = 50; // 2.5 seconds at 20Hz
  static const int _strideSize = 25; // 50% overlap
  static const Duration _samplingInterval = Duration(milliseconds: 50); // 20Hz

  /// Initialize the activity recognition service
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.info('Activity recognition service already initialized');
      return;
    }

    try {
      _logger.info('Initializing activity recognition service...');

      // Load the HAR model
      await _loadModel();

      // Start sensor data collection
      _startSensorCollection();

      _isInitialized = true;
      _logger.info('Activity recognition service initialized successfully');
    } catch (e, stack) {
      _logger.error('Failed to initialize activity recognition', error: e, stackTrace: stack);
      throw Exception('Failed to initialize activity recognition: $e');
    }
  }

  /// Load the CNN-LSTM HAR model
  Future<void> _loadModel() async {
    try {
      // Check if model exists in assets
      const modelPath = 'assets/models/har_model.tflite';

      // Try to load the model
      try {
        _interpreter = await Interpreter.fromAsset(modelPath);

        // Create isolate interpreter for background processing
        _isolateInterpreter = await IsolateInterpreter.create(
          address: _interpreter!.address,
        );

        _logger.info('HAR model loaded successfully');
      } catch (e) {
        _logger.warning('HAR model not found, using fallback activity detection');
        // Model will be downloaded/generated in a production app
      }
    } catch (e) {
      _logger.error('Failed to load HAR model', error: e);
      throw e;
    }
  }

  /// Start collecting sensor data
  void _startSensorCollection() {
    _logger.info('Starting sensor data collection...');

    // Subscribe to accelerometer
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: _samplingInterval,
    ).listen((event) {
      _accelerometerBuffer.add(event);
      _processBufferIfReady();
    });

    // Subscribe to gyroscope
    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: _samplingInterval,
    ).listen((event) {
      _gyroscopeBuffer.add(event);
    });

    _bufferStartTime = DateTime.now();
  }

  /// Process sensor buffer when enough data is collected
  void _processBufferIfReady() {
    if (_accelerometerBuffer.length >= _windowSize) {
      final window = SensorDataWindow(
        accelerometer: _accelerometerBuffer.sublist(0, _windowSize),
        gyroscope: _gyroscopeBuffer.length >= _windowSize
            ? _gyroscopeBuffer.sublist(0, _windowSize)
            : _gyroscopeBuffer,
        startTime: _bufferStartTime,
        endTime: DateTime.now(),
      );

      // Process the window
      _recognizeActivity(window);

      // Slide the window
      if (_accelerometerBuffer.length >= _strideSize) {
        _accelerometerBuffer.removeRange(0, _strideSize);
      }
      if (_gyroscopeBuffer.length >= _strideSize) {
        _gyroscopeBuffer.removeRange(0, _strideSize);
      }

      _bufferStartTime = DateTime.now();
    }
  }

  /// Recognize activity from sensor data window
  Future<void> _recognizeActivity(SensorDataWindow window) async {
    try {
      ActivityRecognitionResult result;

      if (_isolateInterpreter != null) {
        // Use ML model for recognition
        result = await _runModelInference(window);
      } else {
        // Use fallback heuristic-based recognition
        result = _heuristicRecognition(window);
      }

      // Emit result
      _activityController.add(result);

      _logger.debug('Activity recognized: ${result.activity.name} '
          '(confidence: ${result.confidence.toStringAsFixed(2)})');
    } catch (e) {
      _logger.error('Failed to recognize activity', error: e);
    }
  }

  /// Run model inference on sensor data
  Future<ActivityRecognitionResult> _runModelInference(SensorDataWindow window) async {
    try {
      // Prepare input tensor
      final input = window.toFeatureVector();

      // Reshape for model input [1, windowSize, features]
      final inputTensor = input.reshape([1, _windowSize, 6]);

      // Prepare output tensor [1, numClasses]
      final output = List.filled(5, 0.0); // 5 activity classes

      // Run inference in isolate
      await _isolateInterpreter!.run(inputTensor, output);

      // Apply softmax to get probabilities
      final probabilities = _softmax(output);

      // Find the activity with highest probability
      int maxIndex = 0;
      double maxProb = probabilities[0];
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      // Map index to activity type
      final activity = _indexToActivity(maxIndex);

      return ActivityRecognitionResult(
        activity: activity,
        confidence: maxProb,
        timestamp: DateTime.now(),
        probabilities: {
          'stationary': probabilities[0],
          'walking': probabilities[1],
          'running': probabilities[2],
          'cycling': probabilities[3],
          'driving': probabilities[4],
        },
      );
    } catch (e) {
      _logger.error('Model inference failed', error: e);
      // Fallback to heuristic recognition
      return _heuristicRecognition(window);
    }
  }

  /// Heuristic-based activity recognition (fallback)
  ActivityRecognitionResult _heuristicRecognition(SensorDataWindow window) {
    // Calculate features from sensor data
    final features = _extractStatisticalFeatures(window);

    // Simple rule-based classification
    ActivityType activity;
    double confidence;

    final avgAccelMagnitude = features['accelMagnitude']!;
    final stdAccel = features['accelStd']!;
    final avgGyroMagnitude = features['gyroMagnitude']!;

    if (avgAccelMagnitude < 0.5 && stdAccel < 0.2) {
      activity = ActivityType.stationary;
      confidence = 0.8;
    } else if (avgAccelMagnitude < 2.0 && stdAccel < 1.0) {
      activity = ActivityType.walking;
      confidence = 0.7;
    } else if (avgAccelMagnitude < 5.0 && stdAccel < 2.0) {
      activity = ActivityType.running;
      confidence = 0.6;
    } else if (avgGyroMagnitude > 2.0) {
      activity = ActivityType.cycling;
      confidence = 0.5;
    } else {
      activity = ActivityType.driving;
      confidence = 0.4;
    }

    return ActivityRecognitionResult(
      activity: activity,
      confidence: confidence,
      timestamp: DateTime.now(),
      probabilities: {
        activity.name: confidence,
      },
    );
  }

  /// Extract statistical features from sensor data
  Map<String, double> _extractStatisticalFeatures(SensorDataWindow window) {
    final features = <String, double>{};

    // Calculate accelerometer magnitude
    double sumAccelMag = 0.0;
    double sumAccelMagSq = 0.0;

    for (final event in window.accelerometer) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      sumAccelMag += magnitude;
      sumAccelMagSq += magnitude * magnitude;
    }

    final count = window.accelerometer.length;
    if (count > 0) {
      final avgMag = sumAccelMag / count;
      final variance = (sumAccelMagSq / count) - (avgMag * avgMag);
      features['accelMagnitude'] = avgMag;
      features['accelStd'] = sqrt(variance);
    } else {
      features['accelMagnitude'] = 0.0;
      features['accelStd'] = 0.0;
    }

    // Calculate gyroscope magnitude
    double sumGyroMag = 0.0;

    for (final event in window.gyroscope) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      sumGyroMag += magnitude;
    }

    features['gyroMagnitude'] = window.gyroscope.isNotEmpty
        ? sumGyroMag / window.gyroscope.length
        : 0.0;

    return features;
  }

  /// Apply softmax to convert logits to probabilities
  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(max);
    final expValues = logits.map((x) => exp(x - maxLogit)).toList();
    final sum = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sum).toList();
  }

  /// Map activity index to ActivityType
  ActivityType _indexToActivity(int index) {
    switch (index) {
      case 0:
        return ActivityType.stationary;
      case 1:
        return ActivityType.walking;
      case 2:
        return ActivityType.running;
      case 3:
        return ActivityType.cycling;
      case 4:
        return ActivityType.driving;
      default:
        return ActivityType.unknown;
    }
  }

  /// Get current activity
  Future<ActivityRecognitionResult?> getCurrentActivity() async {
    if (!_isInitialized) {
      return null;
    }

    // Collect a window of data and process it
    if (_accelerometerBuffer.length >= _windowSize) {
      final window = SensorDataWindow(
        accelerometer: _accelerometerBuffer.sublist(
          _accelerometerBuffer.length - _windowSize,
        ),
        gyroscope: _gyroscopeBuffer.isNotEmpty
            ? _gyroscopeBuffer.sublist(
                max(0, _gyroscopeBuffer.length - _windowSize),
              )
            : [],
        startTime: DateTime.now().subtract(const Duration(seconds: 3)),
        endTime: DateTime.now(),
      );

      if (_isolateInterpreter != null) {
        return await _runModelInference(window);
      } else {
        return _heuristicRecognition(window);
      }
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _activityController.close();
    _interpreter?.close();
    _isolateInterpreter?.close();
    _isInitialized = false;
    _logger.info('Activity recognition service disposed');
  }
}

/// Extension to reshape Float32List
extension Float32ListExtension on Float32List {
  List<List<List<double>>> reshape(List<int> shape) {
    if (shape.length != 3) {
      throw ArgumentError('Shape must have 3 dimensions');
    }

    final result = List.generate(
      shape[0],
      (_) => List.generate(
        shape[1],
        (_) => List.filled(shape[2], 0.0),
      ),
    );

    int index = 0;
    for (int i = 0; i < shape[0]; i++) {
      for (int j = 0; j < shape[1]; j++) {
        for (int k = 0; k < shape[2]; k++) {
          if (index < length) {
            result[i][j][k] = this[index++];
          }
        }
      }
    }

    return result;
  }
}
