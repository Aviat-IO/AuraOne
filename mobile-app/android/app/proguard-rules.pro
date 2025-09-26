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

# Device Calendar plugin rules
-keep class com.builttoroam.devicecalendar.** { *; }
-keepclasseswithmembers class com.builttoroam.devicecalendar.** { *; }
-dontwarn com.builttoroam.devicecalendar.**

# Android Calendar Provider API
-keep class android.provider.CalendarContract { *; }
-keep class android.provider.CalendarContract$** { *; }

# Permission Handler plugin
-keep class com.baseflow.permissionhandler.** { *; }
-keepclasseswithmembers class com.baseflow.permissionhandler.** { *; }

# Photo Manager plugin rules
-keep class com.fluttercandies.photo_manager.** { *; }
-keepclasseswithmembers class com.fluttercandies.photo_manager.** { *; }
-dontwarn com.fluttercandies.photo_manager.**

# Android Media Store API
-keep class android.provider.MediaStore { *; }
-keep class android.provider.MediaStore$** { *; }

# Location service rules
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.maps.** { *; }

# Flutter Background Service rules - CRITICAL for location tracking
-keep class id.flutter.flutter_background_service.** { *; }
-keepclassmembers class id.flutter.flutter_background_service.** { *; }
-keep class id.flutter.flutter_background_service_android.** { *; }
-keepclassmembers class id.flutter.flutter_background_service_android.** { *; }
-dontwarn id.flutter.flutter_background_service.**
-dontwarn id.flutter.flutter_background_service_android.**

# Keep all background service related classes
-keep class androidx.work.** { *; }
-keep class androidx.concurrent.** { *; }

# Geolocator plugin rules
-keep class com.baseflow.geolocator.** { *; }
-keepclassmembers class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# Flutter Local Notifications plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Shared Preferences plugin
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }

# Path Provider plugin
-keep class io.flutter.plugins.pathprovider.** { *; }
-keepclassmembers class io.flutter.plugins.pathprovider.** { *; }

# Device Info plugin
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-keepclassmembers class dev.fluttercommunity.plus.device_info.** { *; }

# Keep Dart VM and Flutter Engine entry points
-keep @io.flutter.embedding.android.FlutterApplication class * { *; }
-keep @io.flutter.plugin.common.PluginRegistry$Registrar class * { *; }
-keep @androidx.annotation.Keep class * { *; }

# Keep all service classes
-keep public class * extends android.app.Service
-keep public class * extends android.app.IntentService
-keep public class * extends android.app.JobService
-keep public class * extends androidx.work.Worker
-keep public class * extends androidx.work.ListenableWorker

# Keep broadcast receivers
-keep public class * extends android.content.BroadcastReceiver

# Keep all native methods and JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Dart plugin registrant
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }