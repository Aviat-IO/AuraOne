import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../services/ai/model_download_manager.dart';
import '../utils/logger.dart';

/// Provider for model download manager
final modelDownloadManagerProvider = Provider<ModelDownloadManager>((ref) {
  return ModelDownloadManager();
});

/// AI Models Management Screen
class AIModelsScreen extends HookConsumerWidget {
  static final _logger = AppLogger('AIModelsScreen');

  const AIModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadManager = ref.watch(modelDownloadManagerProvider);
    final models = downloadManager.getAvailableModels();
    final downloadStates = useState<Map<String, DownloadProgress>>({});
    final isInitialized = useState(false);

    // Initialize download manager
    useEffect(() {
      Future<void> init() async {
        try {
          await downloadManager.initialize();
          isInitialized.value = true;

          // Check which models are already downloaded
          for (final model in models) {
            final isDownloaded = await downloadManager.isModelDownloaded(model.id);
            if (isDownloaded) {
              downloadStates.value = {
                ...downloadStates.value,
                model.id: DownloadProgress(
                  modelId: model.id,
                  state: DownloadState.completed,
                  progress: 1.0,
                ),
              };
            }
          }
        } catch (e) {
          _logger.error('Failed to initialize', error: e);
        }
      }

      init();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Models'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: !isInitialized.value
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: models.length,
              itemBuilder: (context, index) {
                final model = models[index];
                final downloadState = downloadStates.value[model.id];

                return _ModelCard(
                  model: model,
                  downloadProgress: downloadState,
                  onDownload: () => _downloadModel(
                    context,
                    downloadManager,
                    model,
                    downloadStates,
                  ),
                  onCancel: () => downloadManager.cancelDownload(model.id),
                  onDelete: () => _deleteModel(
                    context,
                    downloadManager,
                    model,
                    downloadStates,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _downloadModel(
    BuildContext context,
    ModelDownloadManager manager,
    ModelMetadata model,
    ValueNotifier<Map<String, DownloadProgress>> downloadStates,
  ) async {
    try {
      // Immediately show downloading state
      downloadStates.value = {
        ...downloadStates.value,
        model.id: DownloadProgress(
          modelId: model.id,
          state: DownloadState.checking,
          progress: 0.0,
          message: 'Preparing download...',
        ),
      };

      // Subscribe to progress updates BEFORE starting download
      StreamSubscription? progressSubscription;

      // Create progress stream first (this ensures controller exists)
      final progressStream = manager.getOrCreateDownloadProgress(model.id);

      // Subscribe to updates
      progressSubscription = progressStream.listen(
        (progress) {
          // Update UI with progress (no logging to avoid flooding)
          downloadStates.value = {
            ...downloadStates.value,
            model.id: progress,
          };
        },
        onError: (error) {
          _logger.error('Progress stream error', error: error);
        },
        onDone: () {
          // Stream completed (no logging to avoid flooding)
        },
      );

      // Start download in background
      final downloadFuture = manager.downloadModel(model.id);

      // Wait for download to complete
      await downloadFuture;

      // Clean up subscription
      await progressSubscription?.cancel();

      // Ensure the UI shows the completed state
      downloadStates.value = {
        ...downloadStates.value,
        model.id: DownloadProgress(
          modelId: model.id,
          state: DownloadState.completed,
          progress: 1.0,
          message: 'Model downloaded successfully',
        ),
      };

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Reset UI state on error
      downloadStates.value = {
        ...downloadStates.value,
        model.id: DownloadProgress(
          modelId: model.id,
          state: DownloadState.failed,
          error: e.toString(),
        ),
      };

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${model.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteModel(
    BuildContext context,
    ModelDownloadManager manager,
    ModelMetadata model,
    ValueNotifier<Map<String, DownloadProgress>> downloadStates,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${model.name}?'),
        content: Text(
          'This will remove the downloaded model (${model.formattedSize}). '
          'You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await manager.deleteModel(model.id);
        downloadStates.value = {
          ...downloadStates.value,
          model.id: DownloadProgress(
            modelId: model.id,
            state: DownloadState.idle,
          ),
        };

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${model.name} deleted'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Model card widget
class _ModelCard extends StatelessWidget {
  final ModelMetadata model;
  final DownloadProgress? downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _ModelCard({
    required this.model,
    this.downloadProgress,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDownloaded = downloadProgress?.state == DownloadState.completed;
    final isDownloading = downloadProgress?.state == DownloadState.downloading;
    final isFailed = downloadProgress?.state == DownloadState.failed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model info
            Row(
              children: [
                Icon(
                  _getModelIcon(model.type),
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildChip(
                            context,
                            model.formattedSize,
                            Icons.storage,
                          ),
                          const SizedBox(width: 8),
                          _buildChip(
                            context,
                            'v${model.version}',
                            Icons.info_outline,
                          ),
                          if (model.requiresWifi) ...[
                            const SizedBox(width: 8),
                            _buildChip(
                              context,
                              'WiFi',
                              Icons.wifi,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Progress or status
            if (isDownloading || downloadProgress?.state == DownloadState.checking ||
                downloadProgress?.state == DownloadState.verifying) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        downloadProgress?.message ?? 'Processing...',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (downloadProgress?.state == DownloadState.downloading)
                        Text(
                          '${((downloadProgress?.progress ?? 0) * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: downloadProgress?.progress ?? 0.0,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    progressColor: theme.colorScheme.primary,
                    barRadius: const Radius.circular(4),
                    animation: true,
                    animateFromLastPercent: true,
                    padding: EdgeInsets.zero,
                  ),
                  if (downloadProgress?.state == DownloadState.downloading &&
                      downloadProgress?.bytesDownloaded != null &&
                      downloadProgress?.totalBytes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      downloadProgress!.formattedProgress,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            if (isFailed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        downloadProgress?.error ?? 'Download failed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isDownloaded)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  )
                else if (isDownloading ||
                    downloadProgress?.state == DownloadState.checking ||
                    downloadProgress?.state == DownloadState.verifying)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel),
                    label: Text(
                      downloadProgress?.state == DownloadState.downloading
                        ? 'Cancel'
                        : 'Processing...'
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModelIcon(ModelType type) {
    switch (type) {
      case ModelType.har:
        return Icons.directions_walk;
      case ModelType.imageCaption:
        return Icons.image_search;
      case ModelType.slm:
        return Icons.psychology;
      case ModelType.fusion:
        return Icons.merge_type;
    }
  }
}