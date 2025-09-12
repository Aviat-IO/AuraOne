# Model Acquisition Guide

Based on AI-SPEC.md recommendations, here are the specific models and sources:

## 1. HAR Model (Human Activity Recognition)
**Recommended**: CNN-LSTM architecture for time-series classification

### Option A: Pre-trained TensorFlow Models
```bash
# UCI HAR Dataset trained model
wget https://github.com/guillaume-chevalier/LSTM-Human-Activity-Recognition/blob/master/LSTMHumanActivityRecognition.ipynb
# Convert to TFLite after downloading
```

### Option B: HuggingFace Models
- Search: "human activity recognition cnn lstm"
- Look for models with accelerometer/gyroscope inputs
- Convert using TensorFlow Lite converter

### Option C: Research Papers with Code
- Paper: "Design and optimization of a TensorFlow Lite deep learning neural network for human activity recognition"
- GitHub repos often include trained models

## 2. Image Captioning Model
**Recommended**: LightCap (specifically designed for edge devices)

### Primary Source
- Paper: "Efficient Image Captioning for Edge Devices" (AAAI)
- GitHub: Search for "LightCap image captioning mobile"
- HuggingFace: Search "lightweight image captioning"

### Alternative Options
- **CapDec**: Lightweight captioning decoder
- **Show, Attend and Tell**: Mobile-optimized version
- **BLIP-2**: Quantized version for mobile

## 3. Small Language Model (SLM)
**Recommended**: Phi-3 Mini or TinyLlama

### Phi-3 Mini
```bash
# HuggingFace model
https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-onnx
# Need to convert ONNX to TFLite
```

### TinyLlama
```bash
# HuggingFace model  
https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0
# Available in multiple formats
```

### Alternative SLMs
- **DistilGPT-2**: Smaller, faster
- **GPT-2 Mobile**: Quantized version
- **MobileBERT**: For text generation tasks

## Model Size Expectations
- **HAR Model**: 2-5 MB (quantized)
- **Image Captioning**: 10-50 MB (quantized) 
- **Small Language Model**: 500MB-2GB (4-bit quantized)
- **Total**: ~600MB-2GB for full pipeline

## Integration Priority
1. **Start with HAR** (smallest, most stable)
2. **Add Image Captioning** (medium complexity)
3. **Finish with SLM** (largest, most resource-intensive)