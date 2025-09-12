#!/usr/bin/env python3
"""
HuggingFace Model Downloader for Aura One
Downloads specific models recommended in AI-SPEC.md from HuggingFace Hub
"""

import os
import sys
import subprocess
from pathlib import Path

# Paths  
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
MODELS_DIR = PROJECT_ROOT / "mobile-app" / "assets" / "models"

def install_huggingface_hub():
    """Install HuggingFace Hub if not available"""
    try:
        import huggingface_hub
        print("✅ HuggingFace Hub available")
    except ImportError:
        print("📦 Installing HuggingFace Hub...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "huggingface_hub[tensorflow]"])

def install_optimum():
    """Install Optimum for model conversion"""
    try:
        import optimum
        print("✅ Optimum available")
    except ImportError:
        print("📦 Installing Optimum...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "optimum[onnxruntime]"])

def download_tinyllama():
    """Download TinyLlama model and convert to TFLite"""
    print("\n🦙 Downloading TinyLlama...")
    
    try:
        from huggingface_hub import snapshot_download
        from transformers import AutoTokenizer, AutoModelForCausalLM
        import torch
        import tensorflow as tf
        
        # Download model
        model_name = "TinyLlama/TinyLlama-1.1B-Chat-v1.0"
        print(f"📥 Downloading {model_name}...")
        
        # For now, just document the process since full conversion is complex
        print(f"⚠️  TinyLlama requires advanced conversion:")
        print(f"   1. Model size: ~1.1GB")  
        print(f"   2. Requires ONNX → TFLite conversion pipeline")
        print(f"   3. May need custom conversion script")
        print(f"   4. Consider using ONNX Runtime instead of TFLite")
        
    except Exception as e:
        print(f"❌ TinyLlama download failed: {e}")

def download_phi3_mini():
    """Download Phi-3 Mini model"""
    print("\n🔷 Downloading Phi-3 Mini...")
    
    try:
        # Phi-3 Mini is available in ONNX format which is easier to work with
        model_name = "microsoft/Phi-3-mini-4k-instruct-onnx"
        
        print(f"📥 Model: {model_name}")
        print(f"⚠️  Phi-3 Mini considerations:")
        print(f"   1. Available in ONNX format (easier conversion)")
        print(f"   2. Size: ~2.3GB (4-bit quantized)")
        print(f"   3. Better suited for ONNX Runtime on mobile")
        print(f"   4. May require custom TFLite conversion")
        
    except Exception as e:
        print(f"❌ Phi-3 Mini download failed: {e}")

def search_har_models():
    """Search for HAR models on HuggingFace"""
    print("\n🏃 Searching HAR models...")
    
    suggested_searches = [
        "human activity recognition",
        "har accelerometer", 
        "lstm activity classification",
        "sensor activity recognition"
    ]
    
    print("🔍 Suggested HuggingFace searches:")
    for search in suggested_searches:
        print(f"   - https://huggingface.co/models?search={search.replace(' ', '%20')}")

def search_image_captioning_models():
    """Search for lightweight image captioning models"""
    print("\n📸 Searching Image Captioning models...")
    
    suggested_models = [
        ("microsoft/git-base", "General image captioning"),
        ("nlpconnect/vit-gpt2-image-captioning", "ViT + GPT-2 captioning"),
        ("Salesforce/blip-image-captioning-base", "BLIP captioning model"),
    ]
    
    print("🔍 Recommended models:")
    for model, desc in suggested_models:
        print(f"   - {model}: {desc}")
        print(f"     https://huggingface.co/{model}")

def create_download_script():
    """Create a shell script for easy model downloading"""
    script_content = '''#!/bin/bash
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
'''
    
    script_path = SCRIPT_DIR / "download_hf_models.sh"
    with open(script_path, 'w') as f:
        f.write(script_content)
    
    # Make executable
    os.chmod(script_path, 0o755)
    print(f"✅ Download script created: {script_path}")

def main():
    """Main function"""
    print("🤗 HuggingFace Model Downloader for Aura One")
    print("=" * 50)
    
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Install dependencies
    install_huggingface_hub()
    # install_optimum()  # Commented out - install manually if needed
    
    # Search for models
    search_har_models()
    search_image_captioning_models()
    
    # Document large models
    download_tinyllama()
    download_phi3_mini()
    
    # Create helper script
    create_download_script()
    
    print("\n🎯 Next Steps:")
    print("1. Run: python3 scripts/download_models.py (for basic models)")
    print("2. Browse HuggingFace links above for specific models")
    print("3. For SLMs: Consider ONNX Runtime instead of TFLite")
    print("4. Manual conversion may be needed for some models")
    print("\n💡 Pro tip: Start with basic models, add advanced ones later")

if __name__ == "__main__":
    main()