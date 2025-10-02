# ML Kit GenAI Testing Guide (Pixel 9)

## Prerequisites

1. **Device**: Pixel 9 (you have this ✓)
2. **Android Version**: Android 14+ recommended
3. **AICore**: Should be pre-installed on Pixel 9

## Current Implementation Status

The platform channel infrastructure is **COMPLETE** but the actual ML Kit GenAI API calls are **STUBBED**. This means:

✅ **Implemented:**
- Flutter-to-native communication via MethodChannel
- Device capability detection (API level, device model)
- Error handling and logging
- iOS stub (returns not available)

⏳ **To Be Implemented:**
- Actual ML Kit GenAI API dependencies
- Feature download management
- Summarization API integration
- Image Description API integration
- Rewriting API integration

## Next Steps to Complete Implementation

### Step 1: Add ML Kit GenAI Dependencies

Add to `mobile-app/android/app/build.gradle` in the `dependencies` section:

```gradle
dependencies {
    // ... existing dependencies ...

    // ML Kit GenAI APIs (Beta)
    implementation 'com.google.mlkit:genai-summarization:1.0.0-beta1'
    implementation 'com.google.mlkit:genai-image-description:1.0.0-beta1'
    implementation 'com.google.mlkit:genai-rewriting:1.0.0-beta1'
}
```

### Step 2: Implement Feature Download

In `MLKitGenAIHandler.kt`, replace the `downloadFeatures` TODO with:

```kotlin
fun downloadFeatures(result: MethodChannel.Result) {
    try {
        if (!isAvailable) {
            result.error("NOT_AVAILABLE", "ML Kit GenAI not available", null)
            return
        }

        Log.i(TAG, "Starting feature download")

        // Check and download summarization feature
        val summarizerOptions = SummarizationOptions.Builder()
            .setInputType(InputType.ARTICLE)
            .build()

        val summarizer = Summarization.getClient(summarizerOptions)
        summarizer.downloadModel()
            .addOnSuccessListener {
                Log.i(TAG, "Summarization model downloaded")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to download summarization model", e)
            }

        // Check and download image description feature
        val imageDescriberOptions = ImageDescriptionOptions.Builder()
            .build()

        val imageDescriber = ImageDescription.getClient(imageDescriberOptions)
        imageDescriber.downloadModel()
            .addOnSuccessListener {
                Log.i(TAG, "Image description model downloaded")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to download image description model", e)
            }

        // Check and download rewriting feature
        val rewriterOptions = RewritingOptions.Builder()
            .build()

        val rewriter = Rewriting.getClient(rewriterOptions)
        rewriter.downloadModel()
            .addOnSuccessListener {
                Log.i(TAG, "Rewriting model downloaded")
                result.success(true)
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to download rewriting model", e)
                result.error("DOWNLOAD_ERROR", e.message, null)
            }

    } catch (e: Exception) {
        Log.e(TAG, "Error downloading features", e)
        result.error("DOWNLOAD_ERROR", e.message, null)
    }
}
```

### Step 3: Implement Summarization

Replace the `generateSummary` TODO with:

```kotlin
fun generateSummary(input: String, result: MethodChannel.Result) {
    try {
        if (!isAvailable) {
            result.error("NOT_AVAILABLE", "ML Kit GenAI not available", null)
            return
        }

        Log.d(TAG, "Generating summary (input length: ${input.length})")

        val options = SummarizationOptions.Builder()
            .setInputType(InputType.ARTICLE)
            .build()

        val summarizer = Summarization.getClient(options)

        summarizer.summarize(input)
            .addOnSuccessListener { summary ->
                Log.d(TAG, "Summary generated: ${summary.length} characters")
                result.success(summary)
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Error generating summary", e)
                result.error("GENERATION_ERROR", e.message, null)
            }

    } catch (e: Exception) {
        Log.e(TAG, "Error generating summary", e)
        result.error("GENERATION_ERROR", e.message, null)
    }
}
```

### Step 4: Implement Image Description

Replace the `describeImage` TODO with:

```kotlin
fun describeImage(imagePath: String, result: MethodChannel.Result) {
    try {
        if (!isAvailable) {
            result.error("NOT_AVAILABLE", "ML Kit GenAI not available", null)
            return
        }

        val imageFile = File(imagePath)
        if (!imageFile.exists()) {
            result.error("FILE_NOT_FOUND", "Image file not found: $imagePath", null)
            return
        }

        Log.d(TAG, "Describing image: $imagePath")

        val options = ImageDescriptionOptions.Builder()
            .build()

        val imageDescriber = ImageDescription.getClient(options)

        val inputImage = InputImage.fromFilePath(context, Uri.fromFile(imageFile))

        imageDescriber.describeImage(inputImage)
            .addOnSuccessListener { description ->
                Log.d(TAG, "Image described: ${description.length} characters")
                result.success(description)
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Error describing image", e)
                result.error("DESCRIPTION_ERROR", e.message, null)
            }

    } catch (e: Exception) {
        Log.e(TAG, "Error describing image", e)
        result.error("DESCRIPTION_ERROR", e.message, null)
    }
}
```

### Step 5: Implement Text Rewriting

Replace the `rewriteText` TODO with:

```kotlin
fun rewriteText(text: String, tone: String?, language: String?, result: MethodChannel.Result) {
    try {
        if (!isAvailable) {
            result.error("NOT_AVAILABLE", "ML Kit GenAI not available", null)
            return
        }

        Log.d(TAG, "Rewriting text (tone: $tone, language: $language)")

        // Map tone string to RewritingTone enum
        val rewritingTone = when(tone?.lowercase()) {
            "elaborate" -> RewritingTone.ELABORATE
            "emojify" -> RewritingTone.EMOJIFY
            "shorten" -> RewritingTone.SHORTEN
            "friendly" -> RewritingTone.FRIENDLY
            "professional" -> RewritingTone.PROFESSIONAL
            "rephrase" -> RewritingTone.REPHRASE
            else -> RewritingTone.REPHRASE // Default
        }

        val optionsBuilder = RewritingOptions.Builder()
            .setTone(rewritingTone)

        // Set language if provided
        if (language != null) {
            optionsBuilder.setLanguage(language)
        }

        val options = optionsBuilder.build()
        val rewriter = Rewriting.getClient(options)

        rewriter.rewrite(text)
            .addOnSuccessListener { rewritten ->
                Log.d(TAG, "Text rewritten: ${rewritten.length} characters")
                result.success(rewritten)
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Error rewriting text", e)
                result.error("REWRITING_ERROR", e.message, null)
            }

    } catch (e: Exception) {
        Log.e(TAG, "Error rewriting text", e)
        result.error("REWRITING_ERROR", e.message, null)
    }
}
```

## Testing on Your Pixel 9

### Test 1: Check Availability

```dart
import 'package:aura_one/services/ai/mlkit_genai_adapter.dart';

final adapter = MLKitGenAIAdapter();
final isAvailable = await adapter.checkAvailability();
print('ML Kit GenAI available: $isAvailable'); // Should be true on Pixel 9
```

**Expected Result**: `true` (Pixel 9 should pass all checks)

### Test 2: Download Features

```dart
final adapter = MLKitGenAIAdapter();
final downloaded = await adapter.downloadRequiredAssets(
  onProgress: (progress) {
    print('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
  },
);
print('Download successful: $downloaded');
```

**Expected Result**: Models download successfully

### Test 3: Generate Summary

```dart
// Create a test DailyContext (you'll need to construct this with real data)
final summary = await adapter.generateSummary(testContext);
if (summary.success) {
  print('Generated summary: ${summary.content}');
} else {
  print('Error: ${summary.error}');
}
```

**Expected Result**: Natural language summary generated

### Test 4: Describe Image

```dart
final description = await adapter.describeImage('/path/to/test/image.jpg');
if (description.success) {
  print('Image description: ${description.content}');
} else {
  print('Error: ${description.error}');
}
```

**Expected Result**: Natural language description of the image

### Test 5: Rewrite Text

```dart
final rewritten = await adapter.rewriteText(
  'This is a test sentence.',
  tone: 'friendly',
  language: 'en',
);
if (rewritten.success) {
  print('Rewritten: ${rewritten.content}');
} else {
  print('Error: ${rewritten.error}');
}
```

**Expected Result**: Text rewritten in friendly tone

## Troubleshooting

### "ML Kit GenAI not available"
- Check Android version is 14+
- Verify device is Pixel 9 (should auto-detect)
- Check logcat for specific error: `adb logcat | grep MLKitGenAI`

### "Models not downloaded"
- Ensure device has internet connection
- Check Google Play Services is updated
- Try manual download via Test 2

### Import Errors After Adding Dependencies
- Sync Gradle: Android Studio → File → Sync Project with Gradle Files
- Clean build: `cd mobile-app && fvm flutter clean && fvm flutter pub get`
- Rebuild: `cd android && ./gradlew clean`

## Logcat Commands

Monitor ML Kit GenAI operations:
```bash
adb logcat | grep -E "MLKitGenAI|Summarization|ImageDescription|Rewriting"
```

Clear logs and start fresh:
```bash
adb logcat -c && adb logcat | grep MLKitGenAI
```

## What to Report Back

Please test and report:
1. ✅ Device detection works (checkAvailability returns true)
2. ✅ Feature download completes successfully
3. ✅ Summarization generates reasonable output
4. ✅ Image description produces good descriptions
5. ✅ Text rewriting works across different tones
6. ❌ Any errors or unexpected behavior (include logcat output)

## Future iOS Support

Once Apple provides on-device AI APIs (Apple Intelligence or similar), we'll implement:
- Similar platform channel in Swift
- Native iOS AI API integration
- Unified Flutter interface (already prepared)

The adapter pattern ensures seamless addition of iOS support without changing the Flutter layer.
