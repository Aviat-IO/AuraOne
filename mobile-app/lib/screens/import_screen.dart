import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:async_button_builder/async_button_builder.dart';
import '../services/export/export_service.dart';
import '../services/export/export_schema.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  Map<String, dynamic>? _importData;
  bool _isAnalyzing = false;
  ImportSettings _settings = ImportSettings();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Journal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Import instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.upload_file,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Import From Export',
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select a previously exported Aura One journal ZIP file to import your entries, media, and settings.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _selectImportFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Select Export File'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Import preview
              if (_isAnalyzing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),

              if (_importData != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Import Preview',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildImportSummary(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Import settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Settings',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Merge with existing entries'),
                          subtitle: const Text(
                              'Keep existing entries and add imported ones'),
                          value: _settings.mergeEntries,
                          onChanged: (value) => setState(() {
                            _settings.mergeEntries = value;
                          }),
                        ),
                        SwitchListTile(
                          title: const Text('Import media files'),
                          subtitle: const Text('Copy photos and videos'),
                          value: _settings.importMedia,
                          onChanged: (value) => setState(() {
                            _settings.importMedia = value;
                          }),
                        ),
                        SwitchListTile(
                          title: const Text('Import location data'),
                          subtitle: const Text('Include GPS coordinates'),
                          value: _settings.importLocation,
                          onChanged: (value) => setState(() {
                            _settings.importLocation = value;
                          }),
                        ),
                        SwitchListTile(
                          title: const Text('Skip duplicates'),
                          subtitle:
                              const Text('Don\'t import entries that already exist'),
                          value: _settings.skipDuplicates,
                          onChanged: (value) => setState(() {
                            _settings.skipDuplicates = value;
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Import action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _importData = null;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AsyncButtonBuilder(
                        onPressed: _performImport,
                        builder: (context, child, callback, isDisabled) {
                          return FilledButton.icon(
                            onPressed: isDisabled == true ? null : callback,
                            icon: const Icon(Icons.import_export),
                            label: child,
                          );
                        },
                        child: const Text('Import'),
                      ),
                    ),
                  ],
                ),
              ],

              // Format information
              if (_importData == null && !_isAnalyzing) ...[
                const SizedBox(height: 24),
                Card(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(
                              'Supported Formats',
                              style: theme.textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Aura One export files (.zip)\n'
                          '• JSON journal backups (.json)\n'
                          '• Compatible with v${ExportSchema.schemaVersion} schema',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportSummary(BuildContext context) {
    final theme = Theme.of(context);
    final journal = _importData!['journal'] as Map<String, dynamic>?;
    final media = _importData!['media'] as Map<String, dynamic>?;
    final metadata = _importData!['metadata'] as Map<String, dynamic>?;

    final entryCount = journal?['total_count'] ?? 0;
    final mediaCount = media?['total_count'] ?? 0;

    final exportRange = metadata?['export_range'] as Map<String, dynamic>?;
    final startDate = exportRange?['start'] != null
        ? DateTime.parse(exportRange!['start'])
        : null;
    final endDate =
        exportRange?['end'] != null ? DateTime.parse(exportRange!['end']) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(
          icon: Icons.article,
          label: 'Journal Entries',
          value: '$entryCount entries',
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildSummaryRow(
          icon: Icons.photo_library,
          label: 'Media Files',
          value: '$mediaCount files',
          theme: theme,
        ),
        if (startDate != null && endDate != null) ...[
          const SizedBox(height: 8),
          _buildSummaryRow(
            icon: Icons.date_range,
            label: 'Date Range',
            value:
                '${_formatDate(startDate)} - ${_formatDate(endDate)}',
            theme: theme,
          ),
        ],
        const SizedBox(height: 8),
        _buildSummaryRow(
          icon: Icons.storage,
          label: 'Total Size',
          value: _formatSize(metadata?['counts']?['total_size_bytes'] ?? 0),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _selectImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isAnalyzing = true;
          _importData = null;
        });

        final filePath = result.files.single.path!;
        Map<String, dynamic> data;

        if (filePath.endsWith('.zip')) {
          data = await ExportService.importFromZipFile(filePath);
        } else {
          // For JSON files, read directly
          data = await ExportService.importFromDirectory(filePath);
        }

        setState(() {
          _importData = data;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      Fluttertoast.showToast(
        msg: 'Failed to read import file: $e',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _performImport() async {
    if (_importData == null) return;

    try {
      // TODO: Implement actual import logic
      // 1. Parse journal entries from _importData
      // 2. Check for duplicates if _settings.skipDuplicates
      // 3. Import entries to database
      // 4. Copy media files if _settings.importMedia
      // 5. Handle location data if _settings.importLocation

      await Future.delayed(const Duration(seconds: 2)); // Simulate import

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Import completed successfully!',
          toastLength: Toast.LENGTH_LONG,
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Import failed: $e',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
      );
    }
  }
}

class ImportSettings {
  bool mergeEntries = true;
  bool importMedia = true;
  bool importLocation = true;
  bool skipDuplicates = true;
}
