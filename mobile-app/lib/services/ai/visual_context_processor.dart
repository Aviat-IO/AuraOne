import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:exif/exif.dart';
import 'ai_service.dart';
import 'spatiotemporal_processor.dart';

// Stage 2: Visual Context Extraction
class VisualContextProcessor extends PipelineStage {
  final AIServiceConfig config;

  // Model interpreters
  Interpreter? _sceneRecognitionInterpreter;
  Interpreter? _objectDetectionInterpreter;
  Interpreter? _imageCaptioningInterpreter;

  // ML Kit for rapid prototyping
  late final ImageLabeler _imageLabeler;
  late final TextRecognizer _textRecognizer;

  bool _initialized = false;

  // Model parameters per AI-SPEC
  static const int mobilenetInputSize = 224;
  static const int efficientnetInputSize = 260;
  static const int lightcapInputSize = 224;
  static const double inferenceTimeTarget = 200.0; // ms

  VisualContextProcessor(this.config);

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize TFLite models
    await _loadVisionModels();

    // Initialize ML Kit for prototyping
    await _initializeMLKit();

    _initialized = true;
  }

  Future<void> _loadVisionModels() async {
    try {
      final options = InterpreterOptions();

      if (config.enableHardwareAcceleration) {
        if (Platform.isAndroid) {
          options.addDelegate(NnApiDelegate());
        }
        // iOS Core ML delegate would be added here
      }

      // Load MobileNet V3 for scene recognition
      try {
        _sceneRecognitionInterpreter = await Interpreter.fromAsset(
          'assets/models/preprocessing/mobilenet_v3_scene.tflite',
          options: options,
        );
        debugPrint('Scene recognition model loaded');
      } catch (e) {
        debugPrint('Scene model not found, using ML Kit fallback');
      }

      // Load EfficientNet-Lite for object detection
      try {
        _objectDetectionInterpreter = await Interpreter.fromAsset(
          'assets/models/preprocessing/efficientnet_lite_object.tflite',
          options: options,
        );
        debugPrint('Object detection model loaded');
      } catch (e) {
        debugPrint('Object model not found, using ML Kit fallback');
      }

      // Load LightCap for image captioning (~112MB)
      try {
        _imageCaptioningInterpreter = await Interpreter.fromAsset(
          'assets/models/preprocessing/lightcap_caption.tflite',
          options: options,
        );
        debugPrint('LightCap model loaded');
      } catch (e) {
        debugPrint('Caption model not found, will use scene+object combination');
      }
    } catch (e) {
      debugPrint('Failed to load vision models: $e');
    }
  }

  Future<void> _initializeMLKit() async {
    // Initialize Google ML Kit components for prototyping
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: 0.7,
      ),
    );

    _textRecognizer = TextRecognizer();
  }

  Future<VisualContextData> process(
    DateTime date,
    List<SpatiotemporalEvent> events,
  ) async {
    // Get photos from the specified date
    final photos = await _getPhotosForDate(date);

    if (photos.isEmpty) {
      return VisualContextData(
        date: date,
        photoCount: 0,
        visualEvents: [],
      );
    }

    final visualEvents = <VisualEvent>[];

    for (final photo in photos) {
      try {
        // Extract EXIF metadata
        final metadata = await _extractMetadata(photo);

        // Process the image
        final imageData = await photo.originBytes;
        if (imageData == null) continue;

        // Run visual analysis pipeline
        final sceneLabels = await _recognizeScene(imageData);
        final objects = await _detectObjects(imageData);
        final caption = await _generateCaption(imageData, sceneLabels, objects);

        // Correlate with spatiotemporal events
        final correlatedEvent = _findCorrelatedEvent(
          metadata.timestamp,
          metadata.location,
          events,
        );

        visualEvents.add(VisualEvent(
          photoId: photo.id,
          timestamp: metadata.timestamp,
          location: metadata.location,
          sceneLabels: sceneLabels,
          detectedObjects: objects,
          caption: caption,
          correlatedEvent: correlatedEvent,
        ));
      } catch (e) {
        debugPrint('Failed to process photo ${photo.id}: $e');
      }
    }

    return VisualContextData(
      date: date,
      photoCount: photos.length,
      visualEvents: visualEvents,
    );
  }

  Future<List<AssetEntity>> _getPhotosForDate(DateTime date) async {
    // Request permission
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      debugPrint('Photo access permission denied');
      return [];
    }

    // Get photos from the specified date
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    final photos = <AssetEntity>[];
    for (final album in albums) {
      final assets = await album.getAssetListRange(
        start: 0,
        end: await album.assetCountAsync,
      );

      photos.addAll(assets.where((asset) {
        final createTime = asset.createDateTime;
        return createTime.isAfter(start) && createTime.isBefore(end);
      }));
    }

    return photos;
  }

  Future<PhotoMetadata> _extractMetadata(AssetEntity photo) async {
    final file = await photo.file;
    if (file == null) {
      return PhotoMetadata(
        timestamp: photo.createDateTime,
        location: null,
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      // Extract GPS coordinates if available
      LatLng? location;
      if (data.containsKey('GPS GPSLatitude') &&
          data.containsKey('GPS GPSLongitude')) {
        final lat = _convertGPSToDecimal(
          data['GPS GPSLatitude']!.values.toList(),
          data['GPS GPSLatitudeRef']?.printable ?? 'N',
        );
        final lon = _convertGPSToDecimal(
          data['GPS GPSLongitude']!.values.toList(),
          data['GPS GPSLongitudeRef']?.printable ?? 'E',
        );
        location = LatLng(lat, lon);
      }

      return PhotoMetadata(
        timestamp: photo.createDateTime,
        location: location ?? LatLng(photo.latitude ?? 0, photo.longitude ?? 0),
      );
    } catch (e) {
      return PhotoMetadata(
        timestamp: photo.createDateTime,
        location: LatLng(photo.latitude ?? 0, photo.longitude ?? 0),
      );
    }
  }

  double _convertGPSToDecimal(List<dynamic> values, String ref) {
    if (values.length < 3) return 0.0;

    final degrees = (values[0] as Ratio).toDouble();
    final minutes = (values[1] as Ratio).toDouble();
    final seconds = (values[2] as Ratio).toDouble();

    double decimal = degrees + (minutes / 60) + (seconds / 3600);

    if (ref == 'S' || ref == 'W') {
      decimal = -decimal;
    }

    return decimal;
  }

  Future<List<SceneLabel>> _recognizeScene(Uint8List imageData) async {
    // Try TFLite model first
    if (_sceneRecognitionInterpreter != null) {
      return await _runSceneRecognitionTFLite(imageData);
    }

    // Fallback to ML Kit
    return await _runSceneRecognitionMLKit(imageData);
  }

  Future<List<SceneLabel>> _runSceneRecognitionTFLite(Uint8List imageData) async {
    // Preprocess image for MobileNet
    final image = img.decodeImage(imageData);
    if (image == null) return [];

    final resized = img.copyResize(
      image,
      width: mobilenetInputSize,
      height: mobilenetInputSize,
    );

    // Convert to normalized float array
    final input = Float32List(1 * mobilenetInputSize * mobilenetInputSize * 3);
    int pixelIndex = 0;
    for (int y = 0; y < mobilenetInputSize; y++) {
      for (int x = 0; x < mobilenetInputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = (img.getRed(pixel) - 127.5) / 127.5;
        input[pixelIndex++] = (img.getGreen(pixel) - 127.5) / 127.5;
        input[pixelIndex++] = (img.getBlue(pixel) - 127.5) / 127.5;
      }
    }

    // Run inference
    final output = Float32List(1000); // ImageNet classes
    final inputs = [input.reshape([1, mobilenetInputSize, mobilenetInputSize, 3])];
    final outputs = {0: output.reshape([1, 1000])};

    _sceneRecognitionInterpreter!.runForMultipleInputs(inputs, outputs);

    // Parse top-5 predictions
    return _parseScenePredictions(output);
  }

  Future<List<SceneLabel>> _runSceneRecognitionMLKit(Uint8List imageData) async {
    final inputImage = InputImage.fromBytes(
      bytes: imageData,
      metadata: InputImageMetadata(
        size: const Size(1080, 1920), // Default size, adjust as needed
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: 1080,
      ),
    );

    final labels = await _imageLabeler.processImage(inputImage);

    return labels.map((label) => SceneLabel(
      label: label.label,
      confidence: label.confidence,
    )).toList();
  }

  List<SceneLabel> _parseScenePredictions(Float32List output) {
    // Get top-5 predictions
    final predictions = <SceneLabel>[];
    final indexed = output.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < 5 && i < indexed.length; i++) {
      predictions.add(SceneLabel(
        label: _getSceneClassName(indexed[i].key),
        confidence: indexed[i].value,
      ));
    }

    return predictions;
  }

  String _getSceneClassName(int index) {
    // Map index to scene class name
    // This would use a proper label map in production
    const sceneClasses = [
      'Office', 'Park', 'Restaurant', 'Home', 'Street',
      'Beach', 'Mountain', 'Forest', 'City', 'Indoor',
    ];

    if (index < sceneClasses.length) {
      return sceneClasses[index];
    }
    return 'Unknown';
  }

  Future<List<DetectedObject>> _detectObjects(Uint8List imageData) async {
    // Try TFLite model first
    if (_objectDetectionInterpreter != null) {
      return await _runObjectDetectionTFLite(imageData);
    }

    // Fallback to ML Kit
    return await _runObjectDetectionMLKit(imageData);
  }

  Future<List<DetectedObject>> _runObjectDetectionTFLite(Uint8List imageData) async {
    // Similar preprocessing for EfficientNet-Lite
    // Implementation would follow object detection model requirements
    return [];
  }

  Future<List<DetectedObject>> _runObjectDetectionMLKit(Uint8List imageData) async {
    // Use ML Kit image labeling as object detection proxy
    final inputImage = InputImage.fromBytes(
      bytes: imageData,
      metadata: InputImageMetadata(
        size: const Size(1080, 1920),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: 1080,
      ),
    );

    final labels = await _imageLabeler.processImage(inputImage);

    return labels.map((label) => DetectedObject(
      className: label.label,
      confidence: label.confidence,
      boundingBox: null, // ML Kit labeling doesn't provide bounding boxes
    )).toList();
  }

  Future<String> _generateCaption(
    Uint8List imageData,
    List<SceneLabel> scenes,
    List<DetectedObject> objects,
  ) async {
    // Try LightCap model first
    if (_imageCaptioningInterpreter != null) {
      return await _runLightCapInference(imageData);
    }

    // Fallback: Combine scene and object information
    return _generateTemplateCaption(scenes, objects);
  }

  Future<String> _runLightCapInference(Uint8List imageData) async {
    // LightCap: CLIP encoder + TinyBERT
    // This would implement the full captioning pipeline
    // For now, return placeholder
    return 'Image caption generation in progress';
  }

  String _generateTemplateCaption(
    List<SceneLabel> scenes,
    List<DetectedObject> objects,
  ) {
    if (scenes.isEmpty && objects.isEmpty) {
      return 'A photo was taken';
    }

    final topScene = scenes.isNotEmpty ? scenes.first.label : '';
    final topObjects = objects.take(3).map((o) => o.className).join(', ');

    if (topScene.isNotEmpty && topObjects.isNotEmpty) {
      return 'A $topScene with $topObjects';
    } else if (topScene.isNotEmpty) {
      return 'A scene showing $topScene';
    } else {
      return 'A photo showing $topObjects';
    }
  }

  SpatiotemporalEvent? _findCorrelatedEvent(
    DateTime photoTime,
    LatLng? photoLocation,
    List<SpatiotemporalEvent> events,
  ) {
    // Find spatiotemporal event that matches photo timestamp and location
    for (final event in events) {
      // Check temporal overlap
      if (photoTime.isAfter(event.startTime) &&
          photoTime.isBefore(event.endTime)) {

        // If photo has location, check spatial proximity
        if (photoLocation != null && event.type == EventType.stay) {
          final distance = _calculateDistance(
            photoLocation,
            event.location,
          );

          if (distance < 100) { // Within 100 meters
            return event;
          }
        } else {
          // No location or journey event - match by time only
          return event;
        }
      }
    }

    return null;
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    // Haversine distance calculation
    const double earthRadius = 6371000; // meters
    final lat1Rad = p1.latitude * 3.14159 / 180;
    final lat2Rad = p2.latitude * 3.14159 / 180;
    final deltaLat = (p2.latitude - p1.latitude) * 3.14159 / 180;
    final deltaLon = (p2.longitude - p1.longitude) * 3.14159 / 180;

    final a = (deltaLat / 2).sin() * (deltaLat / 2).sin() +
        lat1Rad.cos() * lat2Rad.cos() *
        (deltaLon / 2).sin() * (deltaLon / 2).sin();
    final c = 2 * a.sqrt().atan2((1 - a).sqrt());

    return earthRadius * c;
  }

  @override
  Future<void> dispose() async {
    _sceneRecognitionInterpreter?.close();
    _objectDetectionInterpreter?.close();
    _imageCaptioningInterpreter?.close();
    _imageLabeler.close();
    _textRecognizer.close();
    _initialized = false;
  }

  @override
  bool get isInitialized => _initialized;
}

// Extension to reshape Float32List
extension Float32ListReshape on Float32List {
  List<dynamic> reshape(List<int> shape) {
    // Simple reshape implementation
    return [this];
  }
}

// Data models for visual context
class PhotoMetadata {
  final DateTime timestamp;
  final LatLng? location;

  PhotoMetadata({
    required this.timestamp,
    this.location,
  });
}

class SceneLabel {
  final String label;
  final double confidence;

  SceneLabel({
    required this.label,
    required this.confidence,
  });
}

class DetectedObject {
  final String className;
  final double confidence;
  final Rect? boundingBox;

  DetectedObject({
    required this.className,
    required this.confidence,
    this.boundingBox,
  });
}

class Rect {
  final double left, top, width, height;

  Rect(this.left, this.top, this.width, this.height);
}

class VisualEvent {
  final String photoId;
  final DateTime timestamp;
  final LatLng? location;
  final List<SceneLabel> sceneLabels;
  final List<DetectedObject> detectedObjects;
  final String caption;
  final SpatiotemporalEvent? correlatedEvent;

  VisualEvent({
    required this.photoId,
    required this.timestamp,
    this.location,
    required this.sceneLabels,
    required this.detectedObjects,
    required this.caption,
    this.correlatedEvent,
  });
}

class VisualContextData {
  final DateTime date;
  final int photoCount;
  final List<VisualEvent> visualEvents;

  VisualContextData({
    required this.date,
    required this.photoCount,
    required this.visualEvents,
  });
}
