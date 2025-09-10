import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/export/export_service.dart';
import '../services/export/export_schema.dart';
import '../services/export/syncthing_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includeMedia = true;
  bool _includeLocation = true;
  bool _includeSensorData = true;
  bool _enableEncryption = false;
  String _encryptionPassword = '';
  bool _useBlossomStorage = false;
  bool _useSyncthingFolder = false;
  double _exportProgress = 0.0;
  final _passwordController = TextEditingController();
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Journal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Settings',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      // Date range selection
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePicker(
                              context,
                              label: 'Start Date',
                              value: _startDate,
                              onChanged: (date) => setState(() => _startDate = date),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDatePicker(
                              context,
                              label: 'End Date',
                              value: _endDate,
                              onChanged: (date) => setState(() => _endDate = date),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Export options
                      SwitchListTile(
                        title: const Text('Include Media'),
                        subtitle: const Text('Photos, videos, and audio files'),
                        value: _includeMedia,
                        onChanged: (value) => setState(() => _includeMedia = value),
                      ),
                      SwitchListTile(
                        title: const Text('Include Location'),
                        subtitle: const Text('GPS coordinates and place names'),
                        value: _includeLocation,
                        onChanged: (value) => setState(() => _includeLocation = value),
                      ),
                      SwitchListTile(
                        title: const Text('Include Sensor Data'),
                        subtitle: const Text('Health, calendar, and BLE events'),
                        value: _includeSensorData,
                        onChanged: (value) => setState(() => _includeSensorData = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Storage settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud_upload, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Storage',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Use Blossom Storage'),
                        subtitle: const Text('Upload to decentralized content-addressed storage'),
                        value: _useBlossomStorage,
                        onChanged: (value) => setState(() => _useBlossomStorage = value),
                      ),
                      if (_useBlossomStorage) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Your backup will be uploaded to multiple Blossom servers for redundancy. '
                            'You\'ll receive a unique hash to retrieve your data.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      SwitchListTile(
                        title: const Text('Use Syncthing Folder'),
                        subtitle: const Text('Export to folder monitored by Syncthing for automatic sync'),
                        value: _useSyncthingFolder,
                        onChanged: (value) => setState(() => _useSyncthingFolder = value),
                      ),
                      if (_useSyncthingFolder) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Your backup will be saved to a Syncthing-monitored folder. '
                            'Configure Syncthing to sync this folder across your devices.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Encryption settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Encryption',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Enable Encryption'),
                        subtitle: const Text('Protect your export with AES-256 encryption'),
                        value: _enableEncryption,
                        onChanged: (value) => setState(() => _enableEncryption = value),
                      ),
                      if (_enableEncryption) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Encryption Password',
                            hintText: 'Enter a strong password',
                            border: const OutlineInputBorder(),
                            helperText: 'You will need this password to import the data',
                            prefixIcon: const Icon(Icons.vpn_key),
                          ),
                          onChanged: (value) => _encryptionPassword = value,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Export format info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Export Format',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your journal will be exported as a ZIP archive containing:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint('journal.json - Your journal entries and metadata'),
                      _buildBulletPoint('media/ - Photos, videos, and audio files'),
                      _buildBulletPoint('README.md - Documentation for the export format'),
                      const SizedBox(height: 8),
                      Text(
                        'The export format is designed to be self-documenting and can be imported into other applications.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Progress indicator
              if (_exportProgress > 0 && _exportProgress < 1)
                Column(
                  children: [
                    LinearProgressIndicator(value: _exportProgress),
                    const SizedBox(height: 8),
                    Text('Exporting... ${(_exportProgress * 100).toInt()}%'),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Export button
              SizedBox(
                width: double.infinity,
                child: AsyncButtonBuilder(
                  onPressed: _performExport,
                  builder: (context, child, callback, isDisabled) {
                    return FilledButton.icon(
                      onPressed: isDisabled == true ? null : callback,
                      icon: const Icon(Icons.download),
                      label: child,
                    );
                  },
                  child: const Text('Export Journal'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Quick export options
              Text(
                'Quick Export',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Last 7 Days'),
                    onPressed: () => _quickExport(7),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Last Month'),
                    onPressed: () => _quickExport(30),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.all_inclusive, size: 18),
                    label: const Text('All Entries'),
                    onPressed: () => _quickExport(null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDatePicker(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? '${value.day}/${value.month}/${value.year}'
              : 'Select date',
          style: value != null
              ? theme.textTheme.bodyLarge
              : theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  Future<void> _quickExport(int? days) async {
    setState(() {
      if (days == null) {
        _startDate = null;
        _endDate = null;
      } else {
        _endDate = DateTime.now();
        _startDate = DateTime.now().subtract(Duration(days: days));
      }
    });
    
    await _performExport();
  }
  
  Future<void> _performExport() async {
    try {
      setState(() => _exportProgress = 0.1);
      
      // TODO: Fetch actual journal entries from database
      // For now, using sample data
      final List<Map<String, dynamic>> journalEntries = [
        ExportSchema.createJournalEntry(
          id: 'sample-1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          content: 'Sample journal entry for testing export functionality.',
          tags: ['test', 'sample'],
          location: _includeLocation ? ExportSchema.createLocationData(
            latitude: 37.7749,
            longitude: -122.4194,
            placeName: 'San Francisco',
          ) : null,
          sensorData: _includeSensorData ? ExportSchema.createSensorData(
            healthData: {'steps': 10000, 'heartRate': 72},
          ) : null,
        ),
      ];
      
      final List<Map<String, dynamic>> mediaReferences = _includeMedia ? [
        ExportSchema.createMediaReference(
          id: 'media-1',
          filename: 'sample.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1024000,
          capturedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ] : [];
      
      final metadata = ExportSchema.createMetadata(
        exportStartDate: _startDate ?? DateTime(2020),
        exportEndDate: _endDate ?? DateTime.now(),
        totalEntries: journalEntries.length,
        totalMedia: mediaReferences.length,
        totalSizeBytes: 1024000,
        exportReason: 'Manual export',
        statistics: {
          'totalWords': 100,
          'averageWordsPerEntry': 100,
          'mostActiveDay': 'Monday',
        },
      );
      
      final userData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'appVersion': '0.1.0',
      };
      
      // Perform export
      if (_useSyncthingFolder) {
        // Export to Syncthing folder
        if (_enableEncryption && _encryptionPassword.isEmpty) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Please enter an encryption password',
              toastLength: Toast.LENGTH_LONG,
              backgroundColor: Colors.orange,
            );
          }
          setState(() => _exportProgress = 0.0);
          return;
        }
        
        final result = await SyncthingService.exportToSyncthingFolder(
          appVersion: '0.1.0',
          userData: userData,
          journalEntries: journalEntries,
          mediaReferences: mediaReferences,
          metadata: metadata,
          exportDate: DateTime.now(),
          password: _enableEncryption ? _encryptionPassword : null,
          onProgress: (progress) {
            setState(() => _exportProgress = progress);
          },
        );
        
        setState(() => _exportProgress = 0.0);
        
        if (result.success) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Export to Syncthing Successful'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Your journal has been exported to the Syncthing folder.'),
                      const SizedBox(height: 16),
                      Text('Folder: ${result.syncFolderPath}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Text('File: ${result.fileName ?? 'Unknown'}'),
                      Text('Type: ${result.isScheduled == true ? 'Scheduled' : 'Manual'} backup'),
                      if (_enableEncryption)
                        const Text('Encrypted: Yes'),
                      const SizedBox(height: 16),
                      const Text(
                        'Make sure Syncthing is configured to monitor this folder '
                        'to enable automatic synchronization across your devices.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                  if (result.filePath != null && (Platform.isAndroid || Platform.isIOS))
                    TextButton(
                      onPressed: () {
                        Share.shareXFiles(
                          [XFile(result.filePath!)],
                          subject: 'Aura One Journal Export',
                          text: 'Syncthing backup location: ${result.syncFolderPath}',
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Share'),
                    ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Syncthing export failed: ${result.error ?? 'Unknown error'}',
              toastLength: Toast.LENGTH_LONG,
              backgroundColor: Colors.red,
            );
          }
        }
        return;
      } else if (_useBlossomStorage) {
        // Export to Blossom storage
        if (_enableEncryption && _encryptionPassword.isEmpty) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Please enter an encryption password',
              toastLength: Toast.LENGTH_LONG,
              backgroundColor: Colors.orange,
            );
          }
          setState(() => _exportProgress = 0.0);
          return;
        }
        
        final result = await ExportService.exportToBlossom(
          appVersion: '0.1.0',
          userData: userData,
          journalEntries: journalEntries,
          mediaReferences: mediaReferences,
          metadata: metadata,
          exportDate: DateTime.now(),
          password: _enableEncryption ? _encryptionPassword : null,
          onProgress: (progress) {
            setState(() => _exportProgress = progress);
          },
          onServerResult: (server, error) {
            if (error != null) {
              print('Failed to upload to $server: $error');
            }
          },
        );
        
        setState(() => _exportProgress = 0.0);
        
        // Show success with hash and URLs
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Export Successful'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Your journal has been uploaded to Blossom storage.'),
                    const SizedBox(height: 16),
                    Text('Hash: ${result.hash}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('Size: ${(result.size / 1024 / 1024).toStringAsFixed(2)} MB'),
                    Text('Encrypted: ${result.encrypted ? 'Yes' : 'No'}'),
                    const SizedBox(height: 8),
                    Text('Uploaded to ${result.successfulServers.length} servers'),
                    if (result.failedServers.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Failed on ${result.failedServers.length} servers', 
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
                if (result.urls.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Share backup details
                      Share.shareXFiles(
                        [],
                        text: 'Aura One Backup\nHash: ${result.hash}\nURL: ${result.urls.first}',
                        subject: 'Aura One Journal Backup',
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Share'),
                  ),
              ],
            ),
          );
        }
        return;
      }
      
      // Local file export
      final String filePath;
      if (_enableEncryption && _encryptionPassword.isNotEmpty) {
        // Use encrypted export
        filePath = await ExportService.exportToEncryptedFile(
          appVersion: '0.1.0',
          userData: userData,
          journalEntries: journalEntries,
          mediaReferences: mediaReferences,
          metadata: metadata,
          exportDate: DateTime.now(),
          password: _encryptionPassword,
          onProgress: (progress) {
            setState(() => _exportProgress = progress);
          },
        );
      } else if (_enableEncryption && _encryptionPassword.isEmpty) {
        // Show error for missing password
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Please enter an encryption password',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.orange,
          );
        }
        setState(() => _exportProgress = 0.0);
        return;
      } else {
        // Use regular export
        filePath = await ExportService.exportToLocalFile(
          appVersion: '0.1.0',
          userData: userData,
          journalEntries: journalEntries,
          mediaReferences: mediaReferences,
          metadata: metadata,
          exportDate: DateTime.now(),
          onProgress: (progress) {
            setState(() => _exportProgress = progress);
          },
        );
      }
      
      setState(() => _exportProgress = 0.0);
      
      // Show success and share option
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Export completed successfully!',
          toastLength: Toast.LENGTH_LONG,
        );
        
        // Share the file
        if (Platform.isAndroid || Platform.isIOS) {
          await Share.shareXFiles(
            [XFile(filePath)],
            subject: 'Aura One Journal Export',
            text: 'My journal export from Aura One',
          );
        }
      }
    } catch (e) {
      setState(() => _exportProgress = 0.0);
      
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Export failed: $e',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
        );
      }
    }
  }
}