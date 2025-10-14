import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../services/data_deletion_service.dart';
import '../../widgets/common/warning_dialog.dart';

class DataDeletionScreen extends HookConsumerWidget {
  const DataDeletionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final startDate = useState<DateTime?>(null);
    final endDate = useState<DateTime?>(null);
    final selectedDataTypes = useState<Set<DataType>>({});
    final keepSignificantLocations = useState(true);
    final exportBeforeDeletion = useState(false);
    final isPreviewLoading = useState(false);
    final deletionPreview = useState<DeletionPreview?>(null);
    final isDeletionInProgress = useState(false);
    final deletionProgress = useState(0.0);

    final dataDeletionService = ref.read(dataDeletionServiceProvider);

    Future<void> loadPreview() async {
      if (selectedDataTypes.value.isEmpty) {
        deletionPreview.value = null;
        return;
      }

      isPreviewLoading.value = true;
      try {
        final preview = await dataDeletionService.previewDeletion(
          startDate: startDate.value,
          endDate: endDate.value,
          dataTypes: selectedDataTypes.value,
          keepSignificantLocations: keepSignificantLocations.value,
        );
        deletionPreview.value = preview;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading preview: $e'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } finally {
        isPreviewLoading.value = false;
      }
    }

    useEffect(() {
      if (selectedDataTypes.value.isNotEmpty) {
        loadPreview();
      }
      return null;
    }, [
      selectedDataTypes.value,
      startDate.value,
      endDate.value,
      keepSignificantLocations.value,
    ]);

    Future<void> selectDateRange() async {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: startDate.value != null && endDate.value != null
            ? DateTimeRange(start: startDate.value!, end: endDate.value!)
            : null,
        builder: (context, child) {
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme,
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        startDate.value = picked.start;
        endDate.value = picked.end;
      }
    }

    Future<void> performDeletion() async {
      if (deletionPreview.value == null || deletionPreview.value!.isEmpty) {
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => WarningDialog(
          title: 'Confirm Data Deletion',
          message:
              'This will permanently delete ${deletionPreview.value!.totalItemCount} items. This action cannot be undone.',
          confirmText: 'Delete',
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      );

      if (confirmed != true) return;

      isDeletionInProgress.value = true;
      deletionProgress.value = 0.0;

      try {
        await dataDeletionService.deleteData(
          startDate: startDate.value,
          endDate: endDate.value,
          dataTypes: selectedDataTypes.value,
          keepSignificantLocations: keepSignificantLocations.value,
          exportBeforeDeletion: exportBeforeDeletion.value,
          onProgress: (progress) {
            deletionProgress.value = progress;
          },
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Reset state
          selectedDataTypes.value = {};
          startDate.value = null;
          endDate.value = null;
          deletionPreview.value = null;
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting data: $e'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } finally {
        isDeletionInProgress.value = false;
        deletionProgress.value = 0.0;
      }
    }

    Future<void> performCompleteWipe() async {
      // Show multiple confirmation dialogs for complete wipe
      final firstConfirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => WarningDialog(
          title: 'Complete Data Wipe',
          message:
              'This will permanently DELETE ALL DATA from the app. All journal entries, photos, locations, and settings will be lost forever.',
          confirmText: 'I Understand',
          confirmColor: theme.colorScheme.error,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      );

      if (firstConfirm != true) return;

      if (!context.mounted) return;
      
      final secondConfirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => WarningDialog(
          title: 'Final Confirmation',
          message: 'Are you absolutely sure? This action CANNOT be undone.',
          confirmText: 'Delete Everything',
          confirmColor: theme.colorScheme.error,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      );

      if (secondConfirm != true) return;

      isDeletionInProgress.value = true;

      try {
        await dataDeletionService.wipeAllData(
          exportBeforeDeletion: exportBeforeDeletion.value,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data has been deleted'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );

          // Navigate back to home
          context.go('/');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error wiping data: $e'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } finally {
        isDeletionInProgress.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Deletion'),
        elevation: 0,
      ),
      body: isDeletionInProgress.value
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: deletionProgress.value > 0
                        ? deletionProgress.value
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    exportBeforeDeletion.value && deletionProgress.value < 0.3
                        ? 'Exporting data...'
                        : 'Deleting data...',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (deletionProgress.value > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(deletionProgress.value * 100).toInt()}%',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Data Type Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Data to Delete',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DataTypeCheckbox(
                          title: 'Location History',
                          subtitle: 'GPS tracks and visited places',
                          icon: Icons.location_on,
                          dataType: DataType.locations,
                          selectedTypes: selectedDataTypes,
                        ),
                        // Photos and videos are never deleted to preserve user media
                        // These options have been removed for safety
                        _DataTypeCheckbox(
                          title: 'Calendar & Notes',
                          subtitle: 'Events and location notes',
                          icon: Icons.event,
                          dataType: DataType.calendar,
                          selectedTypes: selectedDataTypes,
                        ),
                        const Divider(height: 24),
                        CheckboxListTile(
                          title: const Text('Select All'),
                          subtitle: const Text('Delete all data types'),
                          value: selectedDataTypes.value.contains(DataType.all),
                          onChanged: (bool? value) {
                            if (value == true) {
                              selectedDataTypes.value = {DataType.all};
                            } else {
                              selectedDataTypes.value = {};
                            }
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date Range Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Range',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Leave empty to delete all data',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.date_range),
                          title: Text(
                            startDate.value != null && endDate.value != null
                                ? '${DateFormat.yMMMd().format(startDate.value!)} - ${DateFormat.yMMMd().format(endDate.value!)}'
                                : 'Select date range',
                          ),
                          subtitle: startDate.value != null
                              ? Text(
                                  '${endDate.value!.difference(startDate.value!).inDays + 1} days')
                              : null,
                          trailing: startDate.value != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    startDate.value = null;
                                    endDate.value = null;
                                  },
                                )
                              : null,
                          onTap: selectDateRange,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Options
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Options',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Keep Significant Locations'),
                          subtitle: const Text(
                              'Preserve important places even within date range'),
                          value: keepSignificantLocations.value,
                          onChanged: selectedDataTypes.value
                                  .contains(DataType.locations)
                              ? (value) =>
                                  keepSignificantLocations.value = value
                              : null,
                        ),
                        SwitchListTile(
                          title: const Text('Export Before Deletion'),
                          subtitle: const Text(
                              'Create a backup before deleting data'),
                          value: exportBeforeDeletion.value,
                          onChanged: (value) =>
                              exportBeforeDeletion.value = value,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Preview
                if (selectedDataTypes.value.isNotEmpty) ...[
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Deletion Preview',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Skeletonizer(
                            enabled: isPreviewLoading.value,
                            child: deletionPreview.value != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (deletionPreview
                                              .value!.locationPointCount >
                                          0)
                                        _PreviewItem(
                                          icon: Icons.location_on,
                                          label: 'Location Points',
                                          count: deletionPreview
                                              .value!.locationPointCount,
                                        ),
                                      // Photos and videos are never deleted
                                      if (deletionPreview
                                              .value!.calendarEventCount >
                                          0)
                                        _PreviewItem(
                                          icon: Icons.event,
                                          label: 'Calendar Events',
                                          count: deletionPreview
                                              .value!.calendarEventCount,
                                        ),
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Items:',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${deletionPreview.value!.totalItemCount}',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme
                                                  .colorScheme.onErrorContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (deletionPreview.value!.oldestDate !=
                                              null &&
                                          deletionPreview.value!.newestDate !=
                                              null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Date range: ${DateFormat.yMMMd().format(deletionPreview.value!.oldestDate!)} - ${DateFormat.yMMMd().format(deletionPreview.value!.newestDate!)}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme
                                                .onErrorContainer
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _PreviewItem(
                                        icon: Icons.location_on,
                                        label: 'Location Points',
                                        count: 0,
                                      ),
                                      _PreviewItem(
                                        icon: Icons.photo,
                                        label: 'Photos',
                                        count: 0,
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                if (selectedDataTypes.value.isNotEmpty &&
                    deletionPreview.value != null &&
                    !deletionPreview.value!.isEmpty)
                  FilledButton.icon(
                    onPressed: performDeletion,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Selected Data'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                const SizedBox(height: 32),

                // Complete Wipe Section
                Card(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.delete_forever,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Danger Zone',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completely erase all app data. This action cannot be undone.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: performCompleteWipe,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Wipe All Data'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DataTypeCheckbox extends HookWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final DataType dataType;
  final ValueNotifier<Set<DataType>> selectedTypes;

  const _DataTypeCheckbox({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.dataType,
    required this.selectedTypes,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedTypes.value.contains(dataType) ||
        selectedTypes.value.contains(DataType.all);

    return CheckboxListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: isSelected,
      onChanged: selectedTypes.value.contains(DataType.all)
          ? null
          : (bool? value) {
              final newSet = Set<DataType>.from(selectedTypes.value);
              if (value == true) {
                newSet.add(dataType);
              } else {
                newSet.remove(dataType);
              }
              selectedTypes.value = newSet;
            },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _PreviewItem({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}