# Testing ML Kit GenAI on Pixel 9

## Quick Start (5 minutes)

### 1. Build and Deploy to Pixel 9

```bash
cd mobile-app

# Clean and get dependencies
fvm flutter clean
fvm flutter pub get

# Build and install on connected Pixel 9
fvm flutter run --release
```

### 2. Navigate to Test Screen

In the app, navigate to: **Settings → Debug → ML Kit GenAI Test**

Or use deep link:
```bash
adb shell am start -a android.intent.action.VIEW -d "auraone://test/mlkit-genai"
```

### 3. Run Tests in Order

The test screen has 5 buttons:

1. **Check Availability** ← Start here!
   - Should return ✓ YES on Pixel 9
   - Validates device meets all requirements

2. **Download Models** (if Check Availability passed)
   - Downloads 3 ML Kit GenAI models
   - Takes ~2-5 minutes (first time only)
   - Requires internet connection
   - Shows progress bar

3-5. **Test Generation Features**
   - Currently show "NOT YET IMPLEMENTED"
   - Display copy-paste instructions from testing guide
   - Ready to test after you implement the TODOs

## Expected Results on Pixel 9

✅ **Test 1 - Check Availability:** Should PASS
- Pixel 9 is explicitly in the supported devices list
- Android API level check will pass
- Device model detection will succeed

✅ **Test 2 - Download Models:** Should complete successfully
- May take several minutes on first run
- Progress indicator will show download status
- Models are cached after first download

⚠️ **Tests 3-5:** Currently show implementation instructions
- These will work after you copy the code from the testing guide

## Monitor Logs

Open a second terminal and watch the logs:

```bash
# General ML Kit GenAI logs
adb logcat | grep MLKitGenAI

# More detailed logs
adb logcat | grep -E "MLKitGenAI|Summarization|ImageDescription|Rewriting"

# Clear logs and start fresh
adb logcat -c && adb logcat | grep MLKitGenAI
```

## If Check Availability Fails

1. **Check Android version:**
   ```bash
   adb shell getprop ro.build.version.sdk
   ```
   Should be ≥26 (Android 8.0+)

2. **Check device model:**
   ```bash
   adb shell getprop ro.product.model
   ```
   Should show "Pixel 9"

3. **Check logs:**
   ```bash
   adb logcat | grep MLKitGenAI
   ```
   Will show specific failure reason

## What's Already Working

The infrastructure is **100% complete**:

- ✅ Flutter ↔ Native communication via MethodChannel
- ✅ Device capability detection
- ✅ Error handling and logging
- ✅ iOS stub (returns not available)
- ✅ Test UI with progress indicators
- ✅ Gradle dependencies added

## What Needs Implementation

Just the actual ML Kit GenAI API calls (3 functions):

1. `generateSummary()` in MLKitGenAIHandler.kt
2. `describeImage()` in MLKitGenAIHandler.kt
3. `rewriteText()` in MLKitGenAIHandler.kt

All three have:
- TODO markers in the code
- Complete implementation snippets in `docs/MLKIT_GENAI_TESTING.md`
- Copy-paste ready

## Full Implementation Guide

See `mobile-app/docs/MLKIT_GENAI_TESTING.md` for:
- Complete code snippets for all 3 TODOs
- Detailed testing procedures
- Troubleshooting guide
- API usage examples

## Quick Implementation Test Loop

1. Test on device → see what works
2. Open `MLKitGenAIHandler.kt`
3. Find a TODO marker
4. Copy code from testing guide (Steps 2-5)
5. Hot restart: `r` in terminal or `Ctrl+\`
6. Test again

The test screen makes it super easy to validate each change!

## Questions?

- Check `docs/MLKIT_GENAI_TESTING.md` for detailed guide
- Look at logcat output for specific errors
- All code is ready to copy-paste from the testing guide
