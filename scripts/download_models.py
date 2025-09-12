#!/usr/bin/env python3
"""
Model Download Script for Aura One
Downloads and converts pre-trained models to TensorFlow Lite format
"""

import os
import urllib.request
import zipfile
import shutil
import subprocess
import sys
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
MODELS_DIR = PROJECT_ROOT / "mobile-app" / "assets" / "models"
TEMP_DIR = PROJECT_ROOT / "temp_models"

def ensure_dependencies():
    """Install required Python packages"""
    try:
        import tensorflow as tf
        import numpy as np
        print(f"✅ TensorFlow {tf.__version__} available")
    except ImportError:
        print("❌ TensorFlow not found. Installing...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "tensorflow"])
        import tensorflow as tf
        
def download_har_model():
    """Download and prepare HAR model"""
    print("\n📱 Downloading HAR Model...")
    
    # Create a simple HAR model if no pre-trained available
    try:
        import tensorflow as tf
        from tensorflow.keras import layers, models
        
        # Create a basic CNN-LSTM model for demonstration
        model = models.Sequential([
            layers.Input(shape=(50, 6)),  # 50 timesteps, 6 features (accel + gyro)
            layers.Conv1D(32, 3, activation='relu'),
            layers.Conv1D(64, 3, activation='relu'),
            layers.Dropout(0.5),
            layers.LSTM(50, return_sequences=False),
            layers.Dropout(0.5),
            layers.Dense(5, activation='softmax')  # 5 activities
        ])
        
        model.compile(
            optimizer='adam',
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        # Save model
        har_path = MODELS_DIR / "har_model.tflite"
        with open(har_path, 'wb') as f:
            f.write(tflite_model)
            
        print(f"✅ HAR model saved: {har_path}")
        print(f"📊 Model size: {len(tflite_model) / 1024:.1f} KB")
        
    except Exception as e:
        print(f"❌ HAR model creation failed: {e}")

def download_test_model():
    """Create a simple test model for hardware acceleration testing"""
    print("\n🧪 Creating test model...")
    
    try:
        import tensorflow as tf
        
        # Simple model for testing
        model = tf.keras.Sequential([
            tf.keras.layers.Input(shape=(10,)),
            tf.keras.layers.Dense(5, activation='relu'),
            tf.keras.layers.Dense(1, activation='sigmoid')
        ])
        
        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        # Save model
        test_path = MODELS_DIR / "test_model.tflite"
        with open(test_path, 'wb') as f:
            f.write(tflite_model)
            
        print(f"✅ Test model saved: {test_path}")
        print(f"📊 Model size: {len(tflite_model) / 1024:.1f} KB")
        
    except Exception as e:
        print(f"❌ Test model creation failed: {e}")

def create_placeholder_caption_model():
    """Create a placeholder for image captioning model"""
    print("\n🖼️  Creating placeholder caption model...")
    
    try:
        import tensorflow as tf
        
        # Placeholder vision model (simplified)
        model = tf.keras.Sequential([
            tf.keras.layers.Input(shape=(224, 224, 3)),
            tf.keras.layers.Conv2D(32, 3, activation='relu'),
            tf.keras.layers.GlobalAveragePooling2D(),
            tf.keras.layers.Dense(128, activation='relu'),
            tf.keras.layers.Dense(50)  # Simplified output for demo
        ])
        
        # Convert to TFLite
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        # Save model
        caption_path = MODELS_DIR / "caption_model.tflite"
        with open(caption_path, 'wb') as f:
            f.write(tflite_model)
            
        print(f"✅ Caption model (placeholder) saved: {caption_path}")
        print(f"📊 Model size: {len(tflite_model) / 1024:.1f} KB")
        print("⚠️  This is a placeholder - replace with actual LightCap model")
        
    except Exception as e:
        print(f"❌ Caption model creation failed: {e}")

def main():
    """Main download process"""
    print("🚀 Aura One Model Downloader")
    print("=" * 50)
    
    # Setup
    TEMP_DIR.mkdir(exist_ok=True)
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Install dependencies
    ensure_dependencies()
    
    # Download models
    download_test_model()
    download_har_model() 
    create_placeholder_caption_model()
    
    # Cleanup
    if TEMP_DIR.exists():
        shutil.rmtree(TEMP_DIR)
    
    print("\n🎉 Model download complete!")
    print("\nNext steps:")
    print("1. Replace placeholder models with actual trained models")
    print("2. For HAR: Find UCI HAR dataset trained model")  
    print("3. For Captioning: Obtain LightCap model from research paper")
    print("4. For SLM: Download Phi-3 Mini or TinyLlama from HuggingFace")
    print("\n📁 Models location: mobile-app/assets/models/")

if __name__ == "__main__":
    main()