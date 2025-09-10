import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/export/backup_scheduler.dart';

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  BackupConfig _config = BackupConfig();
  BackupStatus _status = BackupStatus();
  List<BackupHistoryEntry> _history = [];
  bool _isLoading = true;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final config = await BackupScheduler.getConfig();
      final status = await BackupScheduler.getStatus();
      final history = await BackupScheduler.getHistory();
      
      setState(() {
        _config = config;
        _status = status;
        _history = history;
        _passwordController.text = config.encryptionPassword ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to load backup settings: $e',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  
  /// Auto-save settings when they change
  Future<void> _autoSaveSettings() async {
    try {
      await BackupScheduler.saveConfig(_config);
      
      if (_config.frequency != BackupFrequency.disabled) {
        await BackupScheduler.scheduleBackup(_config);
      } else {
        await BackupScheduler.cancelScheduledBackup();
      }
      
      // Reload status to get updated next scheduled time
      final status = await BackupScheduler.getStatus();
      if (mounted) {
        setState(() => _status = status);
      }
    } catch (e) {
      // Silently fail for auto-save to avoid disrupting user experience
      debugPrint('Auto-save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _status.lastBackupSuccess 
                              ? Icons.check_circle 
                              : Icons.error,
                          color: _status.lastBackupSuccess 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Backup Status',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow('Last Backup', 
                      _status.lastBackupTime != null
                        ? _formatDateTime(_status.lastBackupTime!)
                        : 'Never'),
                    _buildStatusRow('Next Scheduled', 
                      _status.nextScheduledBackup != null
                        ? _formatDateTime(_status.nextScheduledBackup!)
                        : 'Not scheduled'),
                    _buildStatusRow('Total Backups', '${_status.totalBackups}'),
                    _buildStatusRow('Successful', '${_status.successfulBackups}'),
                    _buildStatusRow('Failed', '${_status.failedBackups}'),
                    _buildStatusRow('Total Size', '${_status.totalSizeMB.toStringAsFixed(1)} MB'),
                    if (_status.lastBackupError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Last Error: ${_status.lastBackupError}',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          try {
                            // First check if we have storage permissions
                            final hasPermissions = await BackupScheduler.hasStoragePermissions();
                            if (!hasPermissions) {
                              // Request permissions first
                              final granted = await BackupScheduler.requestStoragePermissions();
                              if (!granted) {
                                if (mounted) {
                                  Fluttertoast.showToast(
                                    msg: 'Storage permission is required for backups',
                                    toastLength: Toast.LENGTH_LONG,
                                    backgroundColor: Colors.red,
                                  );
                                }
                                return;
                              }
                            }
                            
                            // Perform the backup
                            await BackupScheduler.performManualBackup();
                            
                            // Refresh settings to update status
                            await _loadSettings();
                            
                            if (mounted) {
                              Fluttertoast.showToast(
                                msg: 'Manual backup started',
                                toastLength: Toast.LENGTH_SHORT,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Fluttertoast.showToast(
                                msg: 'Backup failed: $e',
                                toastLength: Toast.LENGTH_LONG,
                                backgroundColor: Colors.red,
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.backup),
                        label: const Text('Backup Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Schedule Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Schedule',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BackupFrequency>(
                      value: _config.frequency,
                      decoration: const InputDecoration(
                        labelText: 'Backup Frequency',
                        border: OutlineInputBorder(),
                      ),
                      items: BackupFrequency.values.map((freq) {
                        return DropdownMenuItem(
                          value: freq,
                          child: Text(freq.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _config = BackupConfig(
                              frequency: value,
                              preferredTime: _config.preferredTime,
                              includeMedia: _config.includeMedia,
                              includeLocation: _config.includeLocation,
                              includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                              enableEncryption: _config.enableEncryption,
                              encryptionPassword: _config.encryptionPassword,
                              useBlossomStorage: _config.useBlossomStorage,
                              useSyncthingFolder: _config.useSyncthingFolder,
                              maxBackupsToKeep: _config.maxBackupsToKeep,
                              onlyOnWifi: _config.onlyOnWifi,
                              onlyWhenCharging: _config.onlyWhenCharging,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Preferred Time'),
                      subtitle: Text(
                        '${_config.preferredTime.hour.toString().padLeft(2, '0')}:${_config.preferredTime.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: _config.frequency != BackupFrequency.disabled
                          ? () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _config.preferredTime,
                              );
                              if (time != null) {
                                setState(() {
                                  _config = BackupConfig(
                                    frequency: _config.frequency,
                                    preferredTime: time,
                                    includeMedia: _config.includeMedia,
                                    includeLocation: _config.includeLocation,
                                    includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                                    enableEncryption: _config.enableEncryption,
                                    encryptionPassword: _config.encryptionPassword,
                                    useBlossomStorage: _config.useBlossomStorage,
                                    useSyncthingFolder: _config.useSyncthingFolder,
                                    maxBackupsToKeep: _config.maxBackupsToKeep,
                                    onlyOnWifi: _config.onlyOnWifi,
                                    onlyWhenCharging: _config.onlyWhenCharging,
                                  );
                                });
                              }
                            }
                          : null,
                    ),
                    SwitchListTile(
                      title: const Text('Only on Wi-Fi'),
                      subtitle: const Text('Backup only when connected to Wi-Fi'),
                      value: _config.onlyOnWifi,
                      onChanged: _config.frequency != BackupFrequency.disabled
                          ? (value) {
                              setState(() {
                                _config = BackupConfig(
                                  frequency: _config.frequency,
                                  preferredTime: _config.preferredTime,
                                  includeMedia: _config.includeMedia,
                                  includeLocation: _config.includeLocation,
                                  includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                                  enableEncryption: _config.enableEncryption,
                                  encryptionPassword: _config.encryptionPassword,
                                  useBlossomStorage: _config.useBlossomStorage,
                                  useSyncthingFolder: _config.useSyncthingFolder,
                                  maxBackupsToKeep: _config.maxBackupsToKeep,
                                  onlyOnWifi: value,
                                  onlyWhenCharging: _config.onlyWhenCharging,
                                );
                              });
                            }
                          : null,
                    ),
                    SwitchListTile(
                      title: const Text('Only When Charging'),
                      subtitle: const Text('Backup only when device is charging'),
                      value: _config.onlyWhenCharging,
                      onChanged: _config.frequency != BackupFrequency.disabled
                          ? (value) {
                              setState(() {
                                _config = BackupConfig(
                                  frequency: _config.frequency,
                                  preferredTime: _config.preferredTime,
                                  includeMedia: _config.includeMedia,
                                  includeLocation: _config.includeLocation,
                                  includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                                  enableEncryption: _config.enableEncryption,
                                  encryptionPassword: _config.encryptionPassword,
                                  useBlossomStorage: _config.useBlossomStorage,
                                  useSyncthingFolder: _config.useSyncthingFolder,
                                  maxBackupsToKeep: _config.maxBackupsToKeep,
                                  onlyOnWifi: _config.onlyOnWifi,
                                  onlyWhenCharging: value,
                                );
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Backup Content Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Backup Content',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Include Media'),
                      subtitle: const Text('Back up photos, videos, and audio'),
                      value: _config.includeMedia,
                      onChanged: (value) {
                        setState(() {
                          _config = BackupConfig(
                            frequency: _config.frequency,
                            preferredTime: _config.preferredTime,
                            includeMedia: value,
                            includeLocation: _config.includeLocation,
                            includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                            enableEncryption: _config.enableEncryption,
                            encryptionPassword: _config.encryptionPassword,
                            useBlossomStorage: _config.useBlossomStorage,
                            useSyncthingFolder: _config.useSyncthingFolder,
                            maxBackupsToKeep: _config.maxBackupsToKeep,
                            onlyOnWifi: _config.onlyOnWifi,
                            onlyWhenCharging: _config.onlyWhenCharging,
                          );
                        });
                        _autoSaveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Include Location'),
                      subtitle: const Text('Back up GPS data and places'),
                      value: _config.includeLocation,
                      onChanged: (value) {
                        setState(() {
                          _config = BackupConfig(
                            frequency: _config.frequency,
                            preferredTime: _config.preferredTime,
                            includeMedia: _config.includeMedia,
                            includeLocation: value,
                            includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                            enableEncryption: _config.enableEncryption,
                            encryptionPassword: _config.encryptionPassword,
                            useBlossomStorage: _config.useBlossomStorage,
                            useSyncthingFolder: _config.useSyncthingFolder,
                            maxBackupsToKeep: _config.maxBackupsToKeep,
                            onlyOnWifi: _config.onlyOnWifi,
                            onlyWhenCharging: _config.onlyWhenCharging,
                          );
                        });
                        _autoSaveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Include Health Data'),
                      subtitle: const Text('Back up fitness and wellness data'),
                      value: _config.includeHealthData,
                      onChanged: (value) {
                        setState(() {
                          _config = BackupConfig(
                            frequency: _config.frequency,
                            preferredTime: _config.preferredTime,
                            includeMedia: _config.includeMedia,
                            includeLocation: _config.includeLocation,
                            includeHealthData: value,
                            includeCalendarData: _config.includeCalendarData,
                            enableEncryption: _config.enableEncryption,
                            encryptionPassword: _config.encryptionPassword,
                            useBlossomStorage: _config.useBlossomStorage,
                            useSyncthingFolder: _config.useSyncthingFolder,
                            maxBackupsToKeep: _config.maxBackupsToKeep,
                            onlyOnWifi: _config.onlyOnWifi,
                            onlyWhenCharging: _config.onlyWhenCharging,
                          );
                        });
                        _autoSaveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Include Calendar Data'),
                      subtitle: const Text('Back up events and appointments'),
                      value: _config.includeCalendarData,
                      onChanged: (value) {
                        setState(() {
                          _config = BackupConfig(
                            frequency: _config.frequency,
                            preferredTime: _config.preferredTime,
                            includeMedia: _config.includeMedia,
                            includeLocation: _config.includeLocation,
                            includeHealthData: _config.includeHealthData,
                            includeCalendarData: value,
                            enableEncryption: _config.enableEncryption,
                            encryptionPassword: _config.encryptionPassword,
                            useBlossomStorage: _config.useBlossomStorage,
                            useSyncthingFolder: _config.useSyncthingFolder,
                            maxBackupsToKeep: _config.maxBackupsToKeep,
                            onlyOnWifi: _config.onlyOnWifi,
                            onlyWhenCharging: _config.onlyWhenCharging,
                          );
                        });
                        _autoSaveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Storage Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storage, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Storage',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('Local Storage'),
                      subtitle: const Text('Save backups to device storage'),
                      value: 'local',
                      groupValue: _config.useBlossomStorage
                          ? 'blossom'
                          : _config.useSyncthingFolder
                              ? 'syncthing'
                              : 'local',
                      onChanged: (value) {
                        setState(() {
                          _config = BackupConfig(
                            frequency: _config.frequency,
                            preferredTime: _config.preferredTime,
                            includeMedia: _config.includeMedia,
                            includeLocation: _config.includeLocation,
                            includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                            enableEncryption: _config.enableEncryption,
                            encryptionPassword: _config.encryptionPassword,
                            useBlossomStorage: false,
                            useSyncthingFolder: false,
                            maxBackupsToKeep: _config.maxBackupsToKeep,
                            onlyOnWifi: _config.onlyOnWifi,
                            onlyWhenCharging: _config.onlyWhenCharging,
                          );
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Blossom Storage'),
                      subtitle: const Text('Upload to decentralized storage'),
                      value: 'blossom',
                      groupValue: _config.useBlossomStorage
                          ? 'blossom'
                          : _config.useSyncthingFolder
                              ? 'syncthing'
                              : 'local',
                      onChanged: (value) {
                        setState(() {
                          _config = BackupConfig(
                            frequency: _config.frequency,
                            preferredTime: _config.preferredTime,
                            includeMedia: _config.includeMedia,
                            includeLocation: _config.includeLocation,
                            includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                            enableEncryption: _config.enableEncryption,
                            encryptionPassword: _config.encryptionPassword,
                            useBlossomStorage: true,
                            useSyncthingFolder: false,
                            maxBackupsToKeep: _config.maxBackupsToKeep,
                            onlyOnWifi: _config.onlyOnWifi,
                            onlyWhenCharging: _config.onlyWhenCharging,
                          );
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Syncthing Folder'),
                      subtitle: const Text('Save to Syncthing-monitored folder'),
                      value: 'syncthing',
                      groupValue: _config.useBlossomStorage
                          ? 'blossom'
                          : _config.useSyncthingFolder
                              ? 'syncthing'
                              : 'local',
                      onChanged: (value) {
                        setState(() {
                          _config = BackupConfig(
                            frequency: _config.frequency,
                            preferredTime: _config.preferredTime,
                            includeMedia: _config.includeMedia,
                            includeLocation: _config.includeLocation,
                            includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                            enableEncryption: _config.enableEncryption,
                            encryptionPassword: _config.encryptionPassword,
                            useBlossomStorage: false,
                            useSyncthingFolder: true,
                            maxBackupsToKeep: _config.maxBackupsToKeep,
                            onlyOnWifi: _config.onlyOnWifi,
                            onlyWhenCharging: _config.onlyWhenCharging,
                          );
                        });
                      },
                    ),
                    
                    // Blossom Storage Configuration
                    if (_config.useBlossomStorage) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Blossom Configuration',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: _config.blossomServerUrl,
                                decoration: const InputDecoration(
                                  labelText: 'Blossom Server URL',
                                  hintText: 'https://blossom.example.com',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.cloud_upload),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _config = BackupConfig(
                                      frequency: _config.frequency,
                                      preferredTime: _config.preferredTime,
                                      includeMedia: _config.includeMedia,
                                      includeLocation: _config.includeLocation,
                                      includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                                      enableEncryption: _config.enableEncryption,
                                      encryptionPassword: _config.encryptionPassword,
                                      useBlossomStorage: _config.useBlossomStorage,
                                      blossomServerUrl: value.isEmpty ? null : value,
                                      blossomNsec: _config.blossomNsec,
                                      useSyncthingFolder: _config.useSyncthingFolder,
                                      syncthingFolderPath: _config.syncthingFolderPath,
                                      maxBackupsToKeep: _config.maxBackupsToKeep,
                                      onlyOnWifi: _config.onlyOnWifi,
                                      onlyWhenCharging: _config.onlyWhenCharging,
                                    );
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: _config.blossomNsec,
                                decoration: InputDecoration(
                                  labelText: 'Nostr Private Key (nsec)',
                                  hintText: 'nsec1...',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.key),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('About nsec'),
                                          content: const Text(
                                            'Your Nostr private key is used to authenticate with the Blossom server. '
                                            'It will be stored securely on your device.\n\n'
                                            'For better security, consider using a signing app or browser extension instead.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                obscureText: true,
                                onChanged: (value) {
                                  setState(() {
                                    _config = BackupConfig(
                                      frequency: _config.frequency,
                                      preferredTime: _config.preferredTime,
                                      includeMedia: _config.includeMedia,
                                      includeLocation: _config.includeLocation,
                                      includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                                      enableEncryption: _config.enableEncryption,
                                      encryptionPassword: _config.encryptionPassword,
                                      useBlossomStorage: _config.useBlossomStorage,
                                      blossomServerUrl: _config.blossomServerUrl,
                                      blossomNsec: value.isEmpty ? null : value,
                                      useSyncthingFolder: _config.useSyncthingFolder,
                                      syncthingFolderPath: _config.syncthingFolderPath,
                                      maxBackupsToKeep: _config.maxBackupsToKeep,
                                      onlyOnWifi: _config.onlyOnWifi,
                                      onlyWhenCharging: _config.onlyWhenCharging,
                                    );
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  // TODO: Test Blossom connection
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Testing Blossom connection...')),
                                  );
                                },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Test Connection'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Syncthing Folder Configuration
                    if (_config.useSyncthingFolder) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Syncthing Configuration',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: _config.syncthingFolderPath ?? '/sdcard/Syncthing/AuraOneBackup',
                                decoration: const InputDecoration(
                                  labelText: 'Syncthing Folder Path',
                                  hintText: '/sdcard/Syncthing/AuraOneBackup',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.folder),
                                  helperText: 'Folder must be monitored by Syncthing',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _config = BackupConfig(
                                      frequency: _config.frequency,
                                      preferredTime: _config.preferredTime,
                                      includeMedia: _config.includeMedia,
                                      includeLocation: _config.includeLocation,
                                      includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                                      enableEncryption: _config.enableEncryption,
                                      encryptionPassword: _config.encryptionPassword,
                                      useBlossomStorage: _config.useBlossomStorage,
                                      blossomServerUrl: _config.blossomServerUrl,
                                      blossomNsec: _config.blossomNsec,
                                      useSyncthingFolder: _config.useSyncthingFolder,
                                      syncthingFolderPath: value.isEmpty ? null : value,
                                      maxBackupsToKeep: _config.maxBackupsToKeep,
                                      onlyOnWifi: _config.onlyOnWifi,
                                      onlyWhenCharging: _config.onlyWhenCharging,
                                    );
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Make sure this folder is configured in your Syncthing app to sync with other devices.',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _config.maxBackupsToKeep.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Maximum Backups to Keep',
                        border: OutlineInputBorder(),
                        helperText: 'Older backups will be automatically deleted',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final count = int.tryParse(value) ?? 10;
                        setState(() {
                          _config = BackupConfig(
                            frequency: _config.frequency,
                            preferredTime: _config.preferredTime,
                            includeMedia: _config.includeMedia,
                            includeLocation: _config.includeLocation,
                            includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                            enableEncryption: _config.enableEncryption,
                            encryptionPassword: _config.encryptionPassword,
                            useBlossomStorage: _config.useBlossomStorage,
                            useSyncthingFolder: _config.useSyncthingFolder,
                            maxBackupsToKeep: count,
                            onlyOnWifi: _config.onlyOnWifi,
                            onlyWhenCharging: _config.onlyWhenCharging,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Encryption Settings
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
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Enable Encryption'),
                      subtitle: const Text('Protect backups with AES-256'),
                      value: _config.enableEncryption,
                      onChanged: (value) {
                        setState(() {
                          _config = BackupConfig(
                            frequency: _config.frequency,
                            preferredTime: _config.preferredTime,
                            includeMedia: _config.includeMedia,
                            includeLocation: _config.includeLocation,
                            includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                            enableEncryption: value,
                            encryptionPassword: value ? _passwordController.text : null,
                            useBlossomStorage: _config.useBlossomStorage,
                            useSyncthingFolder: _config.useSyncthingFolder,
                            maxBackupsToKeep: _config.maxBackupsToKeep,
                            onlyOnWifi: _config.onlyOnWifi,
                            onlyWhenCharging: _config.onlyWhenCharging,
                          );
                        });
                      },
                    ),
                    if (_config.enableEncryption) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Encryption Password',
                          border: OutlineInputBorder(),
                          helperText: 'Required to restore encrypted backups',
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _config = BackupConfig(
                              frequency: _config.frequency,
                              preferredTime: _config.preferredTime,
                              includeMedia: _config.includeMedia,
                              includeLocation: _config.includeLocation,
                              includeHealthData: _config.includeHealthData,
                            includeCalendarData: _config.includeCalendarData,
                              enableEncryption: _config.enableEncryption,
                              encryptionPassword: value,
                              useBlossomStorage: _config.useBlossomStorage,
                              useSyncthingFolder: _config.useSyncthingFolder,
                              maxBackupsToKeep: _config.maxBackupsToKeep,
                              onlyOnWifi: _config.onlyOnWifi,
                              onlyWhenCharging: _config.onlyWhenCharging,
                            );
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Backup History
            if (_history.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.history, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Recent Backups',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              await BackupScheduler.clearHistory();
                              setState(() => _history = []);
                              if (mounted) {
                                Fluttertoast.showToast(
                                  msg: 'History cleared',
                                  toastLength: Toast.LENGTH_SHORT,
                                );
                              }
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.take(5).length,
                        itemBuilder: (context, index) {
                          final entry = _history[index];
                          return ListTile(
                            leading: Icon(
                              entry.success ? Icons.check_circle : Icons.error,
                              color: entry.success ? Colors.green : Colors.red,
                            ),
                            title: Text(_formatDateTime(entry.timestamp)),
                            subtitle: Text(
                              entry.success
                                  ? '${entry.sizeMB?.toStringAsFixed(1) ?? '?'} MB • ${entry.entriesCount ?? '?'} entries'
                                  : entry.error ?? 'Failed',
                            ),
                            trailing: entry.encrypted == true
                                ? const Icon(Icons.lock, size: 16)
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}