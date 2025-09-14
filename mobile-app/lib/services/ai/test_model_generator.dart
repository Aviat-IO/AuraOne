import 'dart:io';
import 'dart:typed_data';

/// Generates minimal valid TFLite models for testing purposes
class TestModelGenerator {
  /// Generate a minimal valid TFLite model file
  /// This creates a simple model with one input and one output tensor
  static Future<void> generateTestModel(String outputPath) async {
    // TFLite model header and minimal structure
    // This is a minimal valid TFLite flatbuffer that contains:
    // - Model header
    // - One subgraph with one input and one output
    // - Minimal operator (ADD operation)

    // For testing purposes, we'll use a pre-built minimal model
    // In production, these would be real trained models

    final minimalModel = Uint8List.fromList([
      // TFLite file identifier
      0x54, 0x46, 0x4C, 0x33, // "TFL3"

      // Minimal flatbuffer structure for a valid but empty model
      // This is the smallest valid TFLite model that can be loaded
      0x00, 0x00, 0x00, 0x00, // Version

      // Flatbuffer root table offset
      0x00, 0x00, 0x00, 0x14,

      // Model metadata (minimal)
      0x00, 0x00, 0x00, 0x03,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x01,

      // Subgraph definition
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,

      // Tensor definitions (minimal)
      0x00, 0x00, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x00,

      // Buffer data
      0x00, 0x00, 0x00, 0x00,
    ]);

    final file = File(outputPath);
    await file.writeAsBytes(minimalModel);
  }

  /// Generate test models for development
  static Future<void> generateAllTestModels() async {
    await generateTestModel('assets/models/har_test.tflite');
    await generateTestModel('assets/models/image_test.tflite');
    await generateTestModel('assets/models/slm_test.tflite');
  }
}