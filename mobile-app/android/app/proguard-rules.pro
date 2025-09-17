# TensorFlow Lite rules for ML Kit
-keep class org.tensorflow.** { *; }
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Google ML Kit rules
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Google ML Kit Text Recognition specific rules
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes that might be loaded dynamically
-keep class * implements org.tensorflow.lite.Delegate { *; }

# Play Core missing classes - ignore them since we don't use Play Store features
-dontwarn com.google.android.play.core.**

# Flutter Map networking for tile loading
-keep class io.flutter.plugins.flutter_map.** { *; }
-dontwarn io.flutter.plugins.flutter_map.**

# HTTP networking classes needed for map tiles
-keep class java.net.HttpURLConnection { *; }
-keep class javax.net.ssl.HttpsURLConnection { *; }
-keep class java.net.URL { *; }

# Keep Flutter platform channels for plugins
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.StandardMessageCodec { *; }
-keep class io.flutter.plugin.common.EventChannel { *; }