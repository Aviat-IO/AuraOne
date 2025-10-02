package me.auraone.app

import android.content.Context
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import com.google.mlkit.genai.common.DownloadCallback
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.imagedescription.ImageDescription
import com.google.mlkit.genai.imagedescription.ImageDescriptionRequest
import com.google.mlkit.genai.imagedescription.ImageDescriberOptions
import com.google.mlkit.genai.rewriting.Rewriting
import com.google.mlkit.genai.rewriting.RewritingRequest
import com.google.mlkit.genai.rewriting.RewriterOptions
import com.google.mlkit.genai.summarization.Summarization
import com.google.mlkit.genai.summarization.SummarizationRequest
import com.google.mlkit.genai.summarization.SummarizerOptions
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch
import java.io.File
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

/**
 * Handler for ML Kit GenAI platform channel
 *
 * Integrates with ML Kit GenAI APIs for on-device AI features:
 * - Summarization API for narrative generation
 * - Image Description API for photo analysis
 * - Rewriting API for text transformation
 *
 * Requirements:
 * - Android API 26+ (Oreo)
 * - AICore support (Pixel 8+, Galaxy S24+)
 * - ML Kit GenAI features downloaded
 */
class MLKitGenAIHandler(private val context: Context) {
    companion object {
        private const val TAG = "MLKitGenAIHandler"
        private const val MIN_API_LEVEL = 26

        // Supported device models with AICore
        private val SUPPORTED_DEVICES = setOf(
            "Pixel 8", "Pixel 8 Pro", "Pixel 8a",
            "Pixel 9", "Pixel 9 Pro", "Pixel 9 Pro XL",
            "SM-S921", "SM-S926", "SM-S928" // Galaxy S24 series
        )
    }

    private var isInitialized = false
    private var isAvailable = false
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    // ML Kit GenAI clients (lazy initialization)
    private val summarizer by lazy {
        val options = SummarizerOptions.builder(context)
            .setInputType(SummarizerOptions.InputType.ARTICLE)
            .setOutputType(SummarizerOptions.OutputType.TWO_BULLETS)  // ~150-200 words
            .setLanguage(SummarizerOptions.Language.ENGLISH)
            .build()
        Summarization.getClient(options)
    }

    private val imageDescriber by lazy {
        val options = ImageDescriberOptions.builder(context).build()
        ImageDescription.getClient(options)
    }

    private fun getRewriter(tone: String?): com.google.mlkit.genai.rewriting.Rewriter {
        val outputType = when (tone?.lowercase()) {
            "elaborate" -> RewriterOptions.OutputType.ELABORATE
            "emojify" -> RewriterOptions.OutputType.EMOJIFY
            "shorten" -> RewriterOptions.OutputType.SHORTEN
            "friendly" -> RewriterOptions.OutputType.FRIENDLY
            "professional" -> RewriterOptions.OutputType.PROFESSIONAL
            "rephrase" -> RewriterOptions.OutputType.REPHRASE
            else -> RewriterOptions.OutputType.REPHRASE
        }

        val options = RewriterOptions.builder(context)
            .setOutputType(outputType)
            .setLanguage(RewriterOptions.Language.ENGLISH)
            .build()

        return Rewriting.getClient(options)
    }

    /**
     * Suspend wrapper for callback-based downloadFeature API
     */
    private suspend fun downloadFeatureAsync(
        client: Any,
        onProgress: ((Long) -> Unit)? = null
    ): Unit = suspendCoroutine { continuation ->
        val callback = object : DownloadCallback {
            override fun onDownloadStarted(bytesToDownload: Long) {
                Log.i(TAG, "Download started: $bytesToDownload bytes")
            }

            override fun onDownloadProgress(totalBytesDownloaded: Long) {
                Log.d(TAG, "Download progress: $totalBytesDownloaded bytes")
                onProgress?.invoke(totalBytesDownloaded)
            }

            override fun onDownloadCompleted() {
                Log.i(TAG, "Download completed successfully")
                continuation.resume(Unit)
            }

            override fun onDownloadFailed(e: GenAiException) {
                Log.e(TAG, "Download failed", e)
                continuation.resumeWithException(e)
            }
        }

        // Call the appropriate downloadFeature method based on client type
        when (client) {
            is com.google.mlkit.genai.summarization.Summarizer -> client.downloadFeature(callback)
            is com.google.mlkit.genai.imagedescription.ImageDescriber -> client.downloadFeature(callback)
            is com.google.mlkit.genai.rewriting.Rewriter -> client.downloadFeature(callback)
            else -> continuation.resumeWithException(IllegalArgumentException("Unknown client type"))
        }
    }

    /**
     * Check if ML Kit GenAI is available on this device
     */
    fun checkAvailability(): Boolean {
        if (isInitialized) {
            return isAvailable
        }

        try {
            // Check Android version
            if (Build.VERSION.SDK_INT < MIN_API_LEVEL) {
                Log.d(TAG, "Device API level ${Build.VERSION.SDK_INT} is below minimum $MIN_API_LEVEL")
                isAvailable = false
                isInitialized = true
                return false
            }

            // Check device model
            val deviceModel = Build.MODEL
            val isSupported = SUPPORTED_DEVICES.any { deviceModel.contains(it, ignoreCase = true) }

            if (!isSupported) {
                Log.d(TAG, "Device model '$deviceModel' not in supported list")
                isAvailable = false
                isInitialized = true
                return false
            }

            // TODO: Check if AICore app is installed and features are available
            // This would use the actual ML Kit GenAI API to check feature status
            // For now, we return true for supported devices

            Log.i(TAG, "ML Kit GenAI is available on this device")
            isAvailable = true
            isInitialized = true
            return true

        } catch (e: Exception) {
            Log.e(TAG, "Error checking availability", e)
            isAvailable = false
            isInitialized = true
            return false
        }
    }

    /**
     * Download required ML Kit GenAI features
     *
     * This will trigger download of:
     * - Summarization model
     * - Image description model
     * - Rewriting model
     */
    fun downloadFeatures(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                if (!isAvailable) {
                    result.error("NOT_AVAILABLE", "ML Kit GenAI not available", null)
                    return@launch
                }

                Log.i(TAG, "Starting feature download")

                // Check and download each feature
                var downloadCount = 0

                // Download summarization feature
                val summarizerStatus = summarizer.checkFeatureStatus().await()
                if (summarizerStatus == FeatureStatus.DOWNLOADABLE) {
                    Log.i(TAG, "Downloading summarization feature...")
                    downloadFeatureAsync(summarizer)
                    downloadCount++
                }

                // Download image description feature
                val imageDescriberStatus = imageDescriber.checkFeatureStatus().await()
                if (imageDescriberStatus == FeatureStatus.DOWNLOADABLE) {
                    Log.i(TAG, "Downloading image description feature...")
                    downloadFeatureAsync(imageDescriber)
                    downloadCount++
                }

                // Download rewriting feature (check all tone variants)
                val rewriter = getRewriter("rephrase")
                val rewriterStatus = rewriter.checkFeatureStatus().await()
                if (rewriterStatus == FeatureStatus.DOWNLOADABLE) {
                    Log.i(TAG, "Downloading rewriting feature...")
                    downloadFeatureAsync(rewriter)
                    downloadCount++
                }

                Log.i(TAG, "Downloaded $downloadCount features successfully")
                result.success(true)

            } catch (e: Exception) {
                Log.e(TAG, "Error downloading features", e)
                result.error("DOWNLOAD_ERROR", e.message, null)
            }
        }
    }

    /**
     * Generate summary from structured text input
     */
    fun generateSummary(input: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                if (!isAvailable) {
                    result.error("NOT_AVAILABLE", "ML Kit GenAI not available", null)
                    return@launch
                }

                Log.d(TAG, "Generating summary (input length: ${input.length})")

                // Check if feature is available, download if needed
                val featureStatus = summarizer.checkFeatureStatus().await()
                when (featureStatus) {
                    FeatureStatus.UNAVAILABLE -> {
                        Log.e(TAG, "Summarization feature unavailable on this device")
                        result.error("FEATURE_UNAVAILABLE", "AI summarization is not supported on this device. Requires Pixel 8+ or Galaxy S24+", null)
                        return@launch
                    }
                    FeatureStatus.DOWNLOADABLE -> {
                        Log.i(TAG, "Summarization feature needs download - triggering automatic download")
                        result.error("FEATURE_DOWNLOADING", "Downloading AI model (first time only). This may take a few minutes. Please try again shortly.", null)
                        // Trigger background download
                        downloadFeatureAsync(summarizer)
                        return@launch
                    }
                    FeatureStatus.DOWNLOADING -> {
                        Log.i(TAG, "Summarization feature is currently downloading")
                        result.error("FEATURE_DOWNLOADING", "AI model is downloading. Please wait a few moments and try again.", null)
                        return@launch
                    }
                    FeatureStatus.AVAILABLE -> {
                        // Continue with generation
                    }
                }

                // Create summarization request
                val request = SummarizationRequest.builder(input).build()

                // Run inference (non-streaming for simplicity)
                val summary = summarizer.runInference(request).await().summary

                Log.i(TAG, "Generated summary: ${summary.length} characters")
                result.success(summary)

            } catch (e: Exception) {
                Log.e(TAG, "Error generating summary", e)
                result.error("GENERATION_ERROR", e.message, null)
            }
        }
    }

    /**
     * Describe image using natural language
     */
    fun describeImage(imagePath: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                if (!isAvailable) {
                    result.error("NOT_AVAILABLE", "ML Kit GenAI not available", null)
                    return@launch
                }

                val imageFile = File(imagePath)
                if (!imageFile.exists()) {
                    result.error("FILE_NOT_FOUND", "Image file not found: $imagePath", null)
                    return@launch
                }

                Log.d(TAG, "Describing image: $imagePath")

                // Check if feature is available
                val featureStatus = imageDescriber.checkFeatureStatus().await()
                if (featureStatus != FeatureStatus.AVAILABLE) {
                    Log.w(TAG, "Image description feature not available: $featureStatus")
                    result.error("FEATURE_NOT_AVAILABLE", "Image description feature needs to be downloaded first", null)
                    return@launch
                }

                // Load image as bitmap
                val bitmap = BitmapFactory.decodeFile(imagePath)
                if (bitmap == null) {
                    result.error("INVALID_IMAGE", "Could not decode image file", null)
                    return@launch
                }

                // Create image description request
                val request = ImageDescriptionRequest.builder(bitmap).build()

                // Run inference (non-streaming)
                val description = imageDescriber.runInference(request).await().description

                bitmap.recycle() // Clean up bitmap

                Log.i(TAG, "Generated image description: ${description.length} characters")
                result.success(description)

            } catch (e: Exception) {
                Log.e(TAG, "Error describing image", e)
                result.error("DESCRIPTION_ERROR", e.message, null)
            }
        }
    }

    /**
     * Rewrite text with specified tone and language
     */
    fun rewriteText(text: String, tone: String?, language: String?, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                if (!isAvailable) {
                    result.error("NOT_AVAILABLE", "ML Kit GenAI not available", null)
                    return@launch
                }

                Log.d(TAG, "Rewriting text (tone: $tone, language: $language)")

                // Get rewriter with specified tone
                val rewriter = getRewriter(tone)

                // Check if feature is available
                val featureStatus = rewriter.checkFeatureStatus().await()
                if (featureStatus != FeatureStatus.AVAILABLE) {
                    Log.w(TAG, "Rewriting feature not available: $featureStatus")
                    result.error("FEATURE_NOT_AVAILABLE", "Rewriting feature needs to be downloaded first", null)
                    return@launch
                }

                // Create rewriting request
                val request = RewritingRequest.builder(text).build()

                // Run inference (non-streaming)
                val rewritingResult = rewriter.runInference(request).await()
                val rewrittenResults = rewritingResult.results

                // Get the rewritten text (usually just one result)
                val rewrittenText: String = rewrittenResults.firstOrNull()?.text ?: text

                Log.i(TAG, "Rewritten text: ${rewrittenText.length} characters")
                result.success(rewrittenText)

                // Clean up rewriter
                rewriter.close()

            } catch (e: Exception) {
                Log.e(TAG, "Error rewriting text", e)
                result.error("REWRITING_ERROR", e.message, null)
            }
        }
    }

    /**
     * Clean up resources
     */
    fun dispose() {
        try {
            // Clean up ML Kit GenAI resources
            if (isInitialized && isAvailable) {
                summarizer.close()
                imageDescriber.close()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing resources", e)
        }

        isInitialized = false
        isAvailable = false
    }
}
