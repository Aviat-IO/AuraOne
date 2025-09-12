#!/bin/bash
# Aura One Model Download Script

echo "🚀 Aura One HuggingFace Model Downloader"
echo "========================================="

# Install dependencies
echo "📦 Installing dependencies..."
pip install huggingface_hub transformers torch tensorflow optimum

# Create models directory
mkdir -p mobile-app/assets/models

echo ""
echo "📋 Available Models:"
echo "1. HAR Models (search manually on HuggingFace)"
echo "2. Image Captioning Models" 
echo "3. Small Language Models (TinyLlama, Phi-3)"
echo ""
echo "⚠️  Note: Large models (SLMs) may require 2-4GB storage"
echo "⚠️  TFLite conversion may require additional tools"
echo ""
echo "🔗 Manual download URLs:"
echo "   - HAR models: https://huggingface.co/models?search=human%20activity%20recognition"
echo "   - Image models: https://huggingface.co/models?search=image%20captioning%20mobile"
echo "   - SLMs: https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0"
