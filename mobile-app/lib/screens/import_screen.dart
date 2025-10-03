import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../services/export/export_service.dart';
import '../services/export/export_schema.dart';
import '../services/journal_service.dart';
import '../database/journal_database.dart';
import '../utils/date_utils.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  Map<String, dynamic>? _importData;
  bool _isAnalyzing = false;
  final ImportSettings _settings = ImportSettings();
  Directory? _mediaDirectory;
  int _totalEntries = 0;
  int _processedEntries = 0;

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

          // Extract media directory from zip if exists
          final tempDir = Directory.systemTemp.createTempSync('import_');
          _mediaDirectory = Directory(path.join(tempDir.path, 'media'));
        } else {
          // For JSON files, read directly
          data = await ExportService.importFromDirectory(filePath);

          // Check for media directory
          final parentDir = Directory(path.dirname(filePath));
          final mediaDir = Directory(path.join(parentDir.path, 'media'));
          if (await mediaDir.exists()) {
            _mediaDirectory = mediaDir;
          }
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
      final db = ref.read(journalDatabaseProvider);

      // Extract journal entries from import data
      final journalData = _importData!['journal'] as Map<String, dynamic>?;
      if (journalData == null) {
        throw Exception('No journal data found in import file');
      }

      final entries = journalData['entries'] as List<dynamic>? ?? [];
      _totalEntries = entries.length;
      _processedEntries = 0;

      // Get app's media directory for copying files
      Directory? appMediaDir;
      if (_settings.importMedia && _mediaDirectory != null) {
        final appDir = await getApplicationDocumentsDirectory();
        appMediaDir = Directory(path.join(appDir.path, 'media'));
        if (!await appMediaDir.exists()) {
          await appMediaDir.create(recursive: true);
        }
      }

      // Track imported entries for success reporting
      int importedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;

      // Process each journal entry
      for (final entryData in entries) {
        try {
          _processedEntries++;

          // Parse entry data
          final entry = entryData as Map<String, dynamic>;
          final dateStr = entry['date'] as String?;
          if (dateStr == null) {
            errorCount++;
            continue;
          }

          final entryDate = DateTime.parse(dateStr);
          final content = entry['content'] as String? ?? '';
          final title = entry['title'] as String? ??
                       'Journal Entry - ${_formatDate(entryDate)}';

          // Check for duplicates if settings require it
          if (_settings.skipDuplicates) {
            final existingEntry = await db.getJournalEntryForDate(entryDate);
            if (existingEntry != null) {
              if (!_settings.mergeEntries) {
                skippedCount++;
                continue;
              }
            }
          }

          // Parse optional fields
          final mood = entry['mood'] as String?;
          final tags = entry['tags'] as List<dynamic>?;
          final tagsJson = tags != null ? jsonEncode(tags) : null;
          final summary = entry['ai_summary'] as String?;
          final isAutoGenerated = entry['is_auto_generated'] as bool? ?? false;
          final isEdited = entry['is_edited'] as bool? ?? false;

          // Parse timestamps
          final timestamps = entry['timestamps'] as Map<String, dynamic>?;
          DateTime? createdAt;
          DateTime? updatedAt;
          if (timestamps != null) {
            final createdStr = timestamps['created'] as String?;
            final updatedStr = timestamps['updated'] as String?;
            if (createdStr != null) createdAt = DateTime.parse(createdStr);
            if (updatedStr != null) updatedAt = DateTime.parse(updatedStr);
          }

          // Create journal entry companion
          final journalEntry = JournalEntriesCompanion(
            date: drift.Value(DateTimeUtils.localDateToUtc(entryDate)),
            title: drift.Value(title),
            content: drift.Value(content),
            mood: drift.Value(mood),
            tags: drift.Value(tagsJson),
            summary: drift.Value(summary),
            isAutoGenerated: drift.Value(isAutoGenerated),
            isEdited: drift.Value(isEdited),
            createdAt: drift.Value(createdAt ?? DateTime.now()),
            updatedAt: drift.Value(updatedAt ?? DateTime.now()),
          );

          // Insert or replace the entry
          final entryId = await db.insertJournalEntry(journalEntry);

          // Process activities if present
          final activities = entry['activities'] as List<dynamic>?;
          if (activities != null) {
            for (final activityData in activities) {
              try {
                final activity = activityData as Map<String, dynamic>;
                final activityType = activity['type'] as String? ?? 'manual';
                final description = activity['description'] as String? ?? '';
                final activityTimestampStr = activity['timestamp'] as String?;
                final activityMetadata = activity['metadata'] as Map<String, dynamic>?;

                // Handle location data if settings allow
                if (!_settings.importLocation && activityType == 'location') {
                  continue;
                }

                final activityTimestamp = activityTimestampStr != null
                    ? DateTime.parse(activityTimestampStr)
                    : entryDate;

                final journalActivity = JournalActivitiesCompanion(
                  journalEntryId: drift.Value(entryId),
                  activityType: drift.Value(activityType),
                  description: drift.Value(description),
                  metadata: drift.Value(
                    activityMetadata != null ? jsonEncode(activityMetadata) : null
                  ),
                  timestamp: drift.Value(activityTimestamp),
                );

                await db.insertJournalActivity(journalActivity);
              } catch (e) {
                // Log activity error but continue processing
                debugPrint('Failed to import activity: $e');
              }
            }
          }

          // Process media files if settings allow
          if (_settings.importMedia && _mediaDirectory != null && appMediaDir != null) {
            final mediaIds = entry['media_ids'] as List<dynamic>?;
            if (mediaIds != null) {
              for (final mediaId in mediaIds) {
                try {
                  // Find media reference
                  final mediaRefs = _importData!['media']?['references'] as List<dynamic>? ?? [];
                  final mediaRef = mediaRefs.firstWhere(
                    (ref) => ref['id'] == mediaId,
                    orElse: () => null,
                  );

                  if (mediaRef != null) {
                    final filename = mediaRef['filename'] as String?;
                    final relativePath = mediaRef['relative_path'] as String?;

                    if (filename != null && relativePath != null) {
                      // Copy media file
                      final sourceFile = File(path.join(_mediaDirectory!.path, filename));
                      if (await sourceFile.exists()) {
                        final destFile = File(path.join(appMediaDir.path, filename));
                        await sourceFile.copy(destFile.path);
                      }
                    }
                  }
                } catch (e) {
                  // Log media error but continue processing
                  debugPrint('Failed to import media file: $e');
                }
              }
            }
          }

          importedCount++;
        } catch (e) {
          errorCount++;
          debugPrint('Failed to import entry: $e');
        }
      }

      // Rebuild search index after bulk import
      await db.rebuildSearchIndex();

      // Clean up temporary media directory if it exists
      if (_mediaDirectory != null && _mediaDirectory!.path.contains('import_')) {
        try {
          await _mediaDirectory!.delete(recursive: true);
        } catch (e) {
          debugPrint('Failed to clean up temp directory: $e');
        }
      }

      if (mounted) {
        String message = 'Import completed!\n';
        message += 'Imported: $importedCount entries';
        if (skippedCount > 0) message += '\nSkipped: $skippedCount duplicates';
        if (errorCount > 0) message += '\nErrors: $errorCount entries';

        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
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
