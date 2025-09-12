# AI Models Directory

This directory contains the TensorFlow Lite models for the 4-stage AI pipeline.

## Directory Structure

```
assets/models/
├── preprocessing/       # Small models bundled with app
│   ├── har_model.tflite       # Human Activity Recognition CNN-LSTM (~27KB)
│   ├── mobilenet_v3_scene.tflite  # Scene recognition (<50MB)
│   ├── efficientnet_lite_object.tflite  # Object detection (<50MB)
│   └── lightcap_caption.tflite    # Image captioning (~112MB)
└── models_readme.md
```

## Downloaded Models

Large models like Gemma 3 Nano are downloaded on first launch and stored in:
- `app_documents/models/gemma-3-nano.bin` (~2GB)

## Model Specifications

Per AI-SPEC.md requirements:

### Stage 1: Spatiotemporal Analysis
- **HAR Model**: CNN-LSTM, INT8 quantized, ~27KB
- **Accuracy**: 92-97%
- **Inference**: <50ms on mobile

### Stage 2: Visual Context
- **Scene Recognition**: MobileNet V3, INT8 quantized, <50MB
- **Object Detection**: EfficientNet-Lite, INT8 quantized, <50MB
- **Image Captioning**: LightCap (CLIP + TinyBERT), ~112MB
- **Combined Size Target**: <200MB (excluding Gemma)

### Stage 3&4: Multimodal Summarization
- **Gemma 3 Nano**: 2B/4B parameters
- **Size**: ~2GB (downloaded separately)
- **Format**: Native Gemma format (not TFLite)

## Hardware Acceleration

Models are optimized for:
- **Android**: NNAPI delegate for NPU/GPU/DSP
- **iOS**: Core ML delegate for Apple Neural Engine

## Quantization

All preprocessing models use INT8 quantization for:
- 4x size reduction
- Faster inference
- Lower power consumption
- Minimal accuracy loss (<2%)