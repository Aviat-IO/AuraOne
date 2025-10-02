import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../services/ai/mlkit_genai_adapter.dart';

/// Test screen for ML Kit GenAI adapter on Pixel 9
///
/// This screen provides buttons to test:
/// 1. Device capability detection
/// 2. Feature download
/// 3. Summary generation (placeholder)
/// 4. Image description (placeholder)
/// 5. Text rewriting (placeholder)
class TestMLKitGenAIScreen extends HookWidget {
  const TestMLKitGenAIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adapter = useMemoized(() => MLKitGenAIAdapter());
    final isAvailable = useState<bool?>(null);
    final downloadProgress = useState<double>(0.0);
    final isDownloading = useState(false);
    final testResult = useState<String>('');
    final isLoading = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ML Kit GenAI Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('ML Kit GenAI Available: '),
                        const SizedBox(width: 8),
                        if (isAvailable.value == null)
                          const Text('Not checked', style: TextStyle(color: Colors.grey))
                        else if (isAvailable.value == true)
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 4),
                              Text('Yes', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          )
                        else
                          const Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 20),
                              SizedBox(width: 4),
                              Text('No', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Expected: ✓ Yes on Pixel 9',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test 1: Check Availability
            ElevatedButton.icon(
              onPressed: isLoading.value ? null : () async {
                isLoading.value = true;
                testResult.value = 'Checking device capabilities...';
                try {
                  final available = await adapter.checkAvailability();
                  isAvailable.value = available;
                  testResult.value = available
                      ? '✓ SUCCESS: ML Kit GenAI is available on this device!\n\n'
                        'Your Pixel 9 meets all requirements:\n'
                        '• Android API 26+ ✓\n'
                        '• Supported device model ✓\n'
                        '• Ready for AI features ✓'
                      : '✗ FAILED: ML Kit GenAI not available\n\n'
                        'This device does not meet requirements.\n'
                        'Check logcat for details.';
                } catch (e) {
                  testResult.value = '✗ ERROR: $e';
                } finally {
                  isLoading.value = false;
                }
              },
              icon: const Icon(Icons.devices),
              label: const Text('1. Check Availability'),
            ),

            const SizedBox(height: 8),

            // Test 2: Download Features
            ElevatedButton.icon(
              onPressed: (isAvailable.value == true && !isDownloading.value)
                  ? () async {
                      isDownloading.value = true;
                      downloadProgress.value = 0.0;
                      testResult.value = 'Downloading ML Kit GenAI models...\n\n'
                          'This may take a few minutes on first run.';

                      try {
                        final success = await adapter.downloadRequiredAssets(
                          onProgress: (progress) {
                            downloadProgress.value = progress;
                            testResult.value = 'Downloading ML Kit GenAI models...\n\n'
                                'Progress: ${(progress * 100).toStringAsFixed(1)}%';
                          },
                        );

                        if (success) {
                          testResult.value = '✓ SUCCESS: Models downloaded!\n\n'
                              'Downloaded:\n'
                              '• Summarization model ✓\n'
                              '• Image Description model ✓\n'
                              '• Rewriting model ✓\n\n'
                              'Ready to generate content!';
                        } else {
                          testResult.value = '✗ FAILED: Download failed\n\n'
                              'Check logcat for details:\n'
                              'adb logcat | grep MLKitGenAI';
                        }
                      } catch (e) {
                        testResult.value = '✗ ERROR: $e\n\n'
                            'Make sure you have internet connection.';
                      } finally {
                        isDownloading.value = false;
                        downloadProgress.value = 0.0;
                      }
                    }
                  : null,
              icon: isDownloading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(isDownloading.value
                  ? '${(downloadProgress.value * 100).toStringAsFixed(0)}%'
                  : '2. Download Models'),
            ),

            const SizedBox(height: 8),

            // Test 3: Test Summary (placeholder)
            ElevatedButton.icon(
              onPressed: isAvailable.value == true
                  ? () {
                      testResult.value = '⚠️ NOT YET IMPLEMENTED\n\n'
                          'To implement:\n'
                          '1. Open MLKitGenAIHandler.kt\n'
                          '2. Find generateSummary() TODO\n'
                          '3. Copy code from docs/MLKIT_GENAI_TESTING.md Step 3\n'
                          '4. Rebuild and test again';
                    }
                  : null,
              icon: const Icon(Icons.description),
              label: const Text('3. Test Summary Generation'),
            ),

            const SizedBox(height: 8),

            // Test 4: Test Image Description (placeholder)
            ElevatedButton.icon(
              onPressed: isAvailable.value == true
                  ? () {
                      testResult.value = '⚠️ NOT YET IMPLEMENTED\n\n'
                          'To implement:\n'
                          '1. Open MLKitGenAIHandler.kt\n'
                          '2. Find describeImage() TODO\n'
                          '3. Copy code from docs/MLKIT_GENAI_TESTING.md Step 4\n'
                          '4. Rebuild and test again';
                    }
                  : null,
              icon: const Icon(Icons.image),
              label: const Text('4. Test Image Description'),
            ),

            const SizedBox(height: 8),

            // Test 5: Test Text Rewriting (placeholder)
            ElevatedButton.icon(
              onPressed: isAvailable.value == true
                  ? () {
                      testResult.value = '⚠️ NOT YET IMPLEMENTED\n\n'
                          'To implement:\n'
                          '1. Open MLKitGenAIHandler.kt\n'
                          '2. Find rewriteText() TODO\n'
                          '3. Copy code from docs/MLKIT_GENAI_TESTING.md Step 5\n'
                          '4. Rebuild and test again';
                    }
                  : null,
              icon: const Icon(Icons.edit),
              label: const Text('5. Test Text Rewriting'),
            ),

            const SizedBox(height: 24),

            // Results Card
            if (testResult.value.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (testResult.value.startsWith('✓'))
                            Icon(Icons.check_circle, color: Colors.green[600], size: 20)
                          else if (testResult.value.startsWith('✗'))
                            Icon(Icons.error, color: Colors.red[600], size: 20)
                          else if (testResult.value.startsWith('⚠️'))
                            Icon(Icons.warning, color: Colors.orange[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Test Result',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        testResult.value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Testing Instructions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Start with "Check Availability" - should be ✓ on Pixel 9\n\n'
                      '2. Then "Download Models" - requires internet, ~5 min\n\n'
                      '3. Tests 3-5 show implementation instructions\n\n'
                      '4. Full guide: mobile-app/docs/MLKIT_GENAI_TESTING.md\n\n'
                      '5. Monitor logs: adb logcat | grep MLKitGenAI',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
