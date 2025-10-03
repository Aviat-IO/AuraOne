import 'package:flutter_test/flutter_test.dart';
import 'package:aura_one/services/ai/model_download_manager.dart';
import 'package:aura_one/services/ai/tflite_manager.dart';
import 'package:aura_one/services/ai/har_test_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('HAR Model Tests', () {
    late ModelDownloadManager downloadManager;
    late TFLiteManager tfliteManager;
    late HARTestService harService;

    setUp(() async {
      downloadManager = ModelDownloadManager();
      tfliteManager = TFLiteManager();
      harService = HARTestService();
    });

    test('Download Manager Initialization', () async {
      await downloadManager.initialize();

      // Check available models
      final models = downloadManager.getAvailableModels();
      expect(models.isNotEmpty, true);

      // Check HAR model is registered
      final harModel = downloadManager.getModelMetadata('har_cnn_lstm');
      expect(harModel, isNotNull);
      expect(harModel?.name, 'Activity Recognition Model');
    });

    test('TFLite Manager Initialization', () async {
      await tfliteManager.initialize();

      // Check hardware acceleration status
      final accelerationStatus = tfliteManager.getAccelerationStatus();
      expect(accelerationStatus, isNotNull);
      print('Hardware acceleration status: $accelerationStatus');
    });

    test('HAR Service Initialization', () async {
      await harService.initialize();

      // Check service status
      final status = harService.getStatus();
      expect(status['initialized'], true);
      expect(status['modelLoaded'], false); // Not loaded yet
    });

    test('Synthetic Data Generation', () async {
      // Test synthetic data generation for different activities
      final activities = ['Walking', 'Running', 'Sitting', 'Standing', 'Cycling'];

      for (final activity in activities) {
        final data = harService.generateSyntheticSensorData(
          activity: activity,
          windowSize: 128,
          features: 6,
        );

        expect(data.length, 128 * 6);

        // Check data is not all zeros
        final nonZeroCount = data.where((v) => v != 0).length;
        expect(nonZeroCount > 0, true);

        print('Generated synthetic data for $activity: ${data.length} values');
      }
    });

    // Skip this test as it requires network access and actual model download
    test('HAR Model Download', skip: 'Requires network access', () async {
      await downloadManager.initialize();

      // Check if model is already downloaded
      final isDownloaded = await downloadManager.isModelDownloaded('har_cnn_lstm');

      if (!isDownloaded) {
        print('Downloading HAR model...');

        // Subscribe to progress
        final progressStream = downloadManager.getDownloadProgress('har_cnn_lstm');
        progressStream?.listen((progress) {
          print('Download progress: ${(progress.progress * 100).toStringAsFixed(1)}%');
        });

        // Download model
        final modelPath = await downloadManager.downloadModel('har_cnn_lstm');
        expect(modelPath, isNotNull);
        print('Model downloaded to: $modelPath');
      } else {
        print('HAR model already downloaded');
      }
    });

    // Skip this test as it requires the model to be downloaded
    test('HAR Model Inference', skip: 'Requires model download', () async {
      await harService.initialize();
      await harService.loadModel();

      // Test with synthetic walking data
      final result = await harService.testWithSyntheticData('Walking');

      expect(result['predictedActivity'], isNotNull);
      expect(result['confidence'], isNotNull);
      expect(result['inferenceTimeMs'], isNotNull);

      print('Inference result:');
      print('  Input: ${result['inputActivity']}');
      print('  Predicted: ${result['predictedActivity']}');
      print('  Confidence: ${(result['confidence'] * 100).toStringAsFixed(1)}%');
      print('  Inference time: ${result['inferenceTimeMs']}ms');
    });
  });
}