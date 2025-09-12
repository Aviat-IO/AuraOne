# TensorFlow Lite Models Directory

This directory should contain the TensorFlow Lite model files (.tflite) used by the AI services.

## Required Models

### 1. HAR Model (`har_model.tflite`)
- **Used by**: ActivityRecognitionService
- **Purpose**: Human Activity Recognition from sensor data
- **Input**: 50 samples × 6 features (3-axis accelerometer + 3-axis gyroscope)
- **Output**: 5 classes (stationary, walking, running, cycling, driving)
- **Size**: ~2-5MB typical for CNN-LSTM architecture

### 2. Image Caption Model (`caption_model.tflite`)
- **Used by**: ImageCaptioningService  
- **Purpose**: Generate captions for photos
- **Input**: 224×224×3 RGB image (normalized)
- **Output**: Token sequence for caption generation
- **Size**: ~10-50MB typical for vision-language models

### 3. Test Model (`test_model.tflite`)
- **Used by**: Hardware acceleration testing
- **Purpose**: Validate GPU/NNAPI delegate availability
- **Input**: Simple tensor for compatibility testing
- **Output**: Basic computation result
- **Size**: <1MB minimal model

## Model Sources

Since these are proprietary TensorFlow Lite models, they need to be:

1. **Trained specifically** for this application's use cases
2. **Converted from PyTorch/TensorFlow** using TFLite converter
3. **Quantized** for mobile performance (INT8 recommended)
4. **Optimized** for the target hardware (ARM64)

## Fallback Behavior

All AI services include fallback implementations when models are missing:

- **ActivityRecognitionService**: Heuristic-based activity detection using sensor magnitude
- **ImageCaptioningService**: Basic image analysis (brightness, colors, aspect ratio)
- **Hardware acceleration**: Falls back to CPU execution

## Development Notes

- Models are loaded lazily when services initialize
- Missing models log warnings but don't crash the app
- Production deployment requires all models for full functionality
- Models should be optimized for mobile inference (<100MB total)

## File Structure

```
assets/models/
├── har_model.tflite          # Activity recognition
├── caption_model.tflite      # Image captioning  
├── test_model.tflite         # Hardware testing
└── README.md                 # This file
```