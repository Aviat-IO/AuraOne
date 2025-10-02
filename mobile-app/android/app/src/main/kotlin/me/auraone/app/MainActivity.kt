package me.auraone.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BATTERY_CHANNEL = "aura_one/battery_optimization"
    private val MLKIT_GENAI_CHANNEL = "com.auraone.mlkit_genai"

    private var mlkitGenAIHandler: MLKitGenAIHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Battery optimization channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(true)
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(true)
                }
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // ML Kit GenAI channel
        mlkitGenAIHandler = MLKitGenAIHandler(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MLKIT_GENAI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailability" -> {
                    result.success(mlkitGenAIHandler?.checkAvailability() ?: false)
                }
                "downloadFeatures" -> {
                    mlkitGenAIHandler?.downloadFeatures(result) ?: result.error("NOT_INITIALIZED", "Handler not initialized", null)
                }
                "generateSummary" -> {
                    val input = call.argument<String>("input")
                    if (input != null) {
                        mlkitGenAIHandler?.generateSummary(input, result) ?: result.error("NOT_INITIALIZED", "Handler not initialized", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Missing input parameter", null)
                    }
                }
                "describeImage" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath != null) {
                        mlkitGenAIHandler?.describeImage(imagePath, result) ?: result.error("NOT_INITIALIZED", "Handler not initialized", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Missing imagePath parameter", null)
                    }
                }
                "rewriteText" -> {
                    val text = call.argument<String>("text")
                    val tone = call.argument<String>("tone")
                    val language = call.argument<String>("language")
                    if (text != null) {
                        mlkitGenAIHandler?.rewriteText(text, tone, language, result) ?: result.error("NOT_INITIALIZED", "Handler not initialized", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Missing text parameter", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mlkitGenAIHandler?.dispose()
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent()
                val packageName = packageName
                val pm = getSystemService(POWER_SERVICE) as PowerManager

                if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                    intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                }
            } catch (e: Exception) {
                // Fallback to battery optimization settings
                openBatteryOptimizationSettings()
            }
        }
    }

    private fun openBatteryOptimizationSettings() {
        try {
            val intent = Intent()
            intent.action = Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback to general battery settings
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            } catch (e2: Exception) {
                // Last resort - open general settings
                startActivity(Intent(Settings.ACTION_SETTINGS))
            }
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            return pm.isIgnoringBatteryOptimizations(packageName)
        }
        return true // No battery optimization on older Android versions
    }
}