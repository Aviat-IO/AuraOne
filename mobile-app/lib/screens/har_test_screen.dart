import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../services/ai/har_test_service.dart';
import '../services/ai/model_download_manager.dart';
import '../utils/logger.dart';

/// Provider for HAR test service
final harTestServiceProvider = Provider<HARTestService>((ref) {
  return HARTestService();
});

/// HAR Model Test Screen
class HARTestScreen extends HookConsumerWidget {
  static final _logger = AppLogger('HARTestScreen');

  const HARTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final harService = ref.watch(harTestServiceProvider);
    final isLoading = useState(false);
    final isModelLoaded = useState(false);
    final testResults = useState<List<Map<String, dynamic>>>([]);
    final selectedActivity = useState('Walking');
    final downloadProgress = useState<double>(0.0);
    final statusMessage = useState('Ready to load model');

    // Initialize service on mount
    useEffect(() {
      Future<void> init() async {
        try {
          await harService.initialize();
          final status = harService.getStatus();
          isModelLoaded.value = status['modelLoaded'] as bool? ?? false;
        } catch (e) {
          _logger.error('Failed to initialize HAR service', error: e);
        }
      }

      init();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HAR Model Test'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Model status card
            _StatusCard(
              isModelLoaded: isModelLoaded.value,
              statusMessage: statusMessage.value,
              downloadProgress: downloadProgress.value,
            ),

            const SizedBox(height: 20),

            // Load model button
            if (!isModelLoaded.value)
              FilledButton.icon(
                onPressed: isLoading.value
                    ? null
                    : () => _loadModel(
                          context,
                          harService,
                          isLoading,
                          isModelLoaded,
                          statusMessage,
                          downloadProgress,
                        ),
                icon: isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(isLoading.value ? 'Loading...' : 'Load HAR Model'),
              ),

            if (isModelLoaded.value) ...[
              const SizedBox(height: 20),

              // Activity selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Activity to Test',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          'Walking',
                          'Running',
                          'Sitting',
                          'Standing',
                          'Cycling',
                        ].map((activity) {
                          return ChoiceChip(
                            label: Text(activity),
                            selected: selectedActivity.value == activity,
                            onSelected: (selected) {
                              if (selected) {
                                selectedActivity.value = activity;
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Test buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isLoading.value
                          ? null
                          : () => _testSingleActivity(
                                context,
                                harService,
                                selectedActivity.value,
                                isLoading,
                                testResults,
                              ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text('Test ${selectedActivity.value}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading.value
                          ? null
                          : () => _runFullTestSuite(
                                context,
                                harService,
                                isLoading,
                                testResults,
                              ),
                      icon: const Icon(Icons.science),
                      label: const Text('Run Full Suite'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Test results
              if (testResults.value.isNotEmpty) ...[
                Text(
                  'Test Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...testResults.value.map((result) => _ResultCard(result: result)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadModel(
    BuildContext context,
    HARTestService service,
    ValueNotifier<bool> isLoading,
    ValueNotifier<bool> isModelLoaded,
    ValueNotifier<String> statusMessage,
    ValueNotifier<double> downloadProgress,
  ) async {
    isLoading.value = true;
    statusMessage.value = 'Loading HAR model...';

    try {
      // Set up download progress monitoring
      final downloadManager = ModelDownloadManager();
      final progressStream = downloadManager.getDownloadProgress('har_cnn_lstm');

      if (progressStream != null) {
        progressStream.listen((progress) {
          downloadProgress.value = progress.progress;
          statusMessage.value = progress.message ?? 'Downloading...';
        });
      }

      await service.loadModel();
      isModelLoaded.value = true;
      statusMessage.value = 'Model loaded successfully';

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('HAR model loaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      statusMessage.value = 'Failed to load model: $e';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _testSingleActivity(
    BuildContext context,
    HARTestService service,
    String activity,
    ValueNotifier<bool> isLoading,
    ValueNotifier<List<Map<String, dynamic>>> testResults,
  ) async {
    isLoading.value = true;

    try {
      final result = await service.testWithSyntheticData(activity);
      testResults.value = [result, ...testResults.value];

      if (context.mounted) {
        final predicted = result['predictedActivity'];
        final confidence = (result['confidence'] * 100).toStringAsFixed(1);
        final isCorrect = predicted == activity;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Predicted: $predicted ($confidence%) - ${isCorrect ? "✓ Correct" : "✗ Incorrect"}',
            ),
            backgroundColor: isCorrect ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _runFullTestSuite(
    BuildContext context,
    HARTestService service,
    ValueNotifier<bool> isLoading,
    ValueNotifier<List<Map<String, dynamic>>> testResults,
  ) async {
    isLoading.value = true;

    try {
      final results = await service.runTestSuite();
      testResults.value = results;

      // Calculate accuracy
      int correct = 0;
      for (final result in results) {
        if (result['inputActivity'] == result['predictedActivity']) {
          correct++;
        }
      }

      final accuracy = (correct / results.length * 100).toStringAsFixed(1);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test suite completed. Accuracy: $accuracy%'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test suite failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}

/// Status card widget
class _StatusCard extends StatelessWidget {
  final bool isModelLoaded;
  final String statusMessage;
  final double downloadProgress;

  const _StatusCard({
    required this.isModelLoaded,
    required this.statusMessage,
    required this.downloadProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isModelLoaded ? Icons.check_circle : Icons.info_outline,
                  color: isModelLoaded ? Colors.green : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Model Status',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(statusMessage),
            if (downloadProgress > 0 && downloadProgress < 1) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: downloadProgress),
              const SizedBox(height: 4),
              Text('${(downloadProgress * 100).toStringAsFixed(1)}%'),
            ],
          ],
        ),
      ),
    );
  }
}

/// Result card widget
class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final input = result['inputActivity'] as String?;
    final predicted = result['predictedActivity'] as String?;
    final confidence = result['confidence'] as double?;
    final inferenceTime = result['inferenceTimeMs'] as int?;
    final error = result['error'] as String?;

    if (error != null) {
      return Card(
        color: Colors.red.withValues(alpha: 0.1),
        child: ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: Text('Test failed for $input'),
          subtitle: Text(error),
        ),
      );
    }

    final isCorrect = input == predicted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.warning,
                  color: isCorrect ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Input: $input → Predicted: $predicted',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confidence: ${((confidence ?? 0) * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Inference: ${inferenceTime}ms',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (result['allPredictions'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'All Predictions:',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              ...((result['allPredictions'] as Map<String, double>).entries
                      .toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .take(3)
                  .map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Text(
                    '${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}