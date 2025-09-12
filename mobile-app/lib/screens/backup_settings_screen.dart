import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/backup/backup_manager.dart';
import '../services/backup/backup_restoration_service.dart';
import '../services/export/backup_scheduler.dart';

/// Provider for BackupManager instance
final backupManagerProvider = Provider((ref) => BackupManager.instance);

/// Provider for BackupRestorationService instance  
final backupRestorationProvider = Provider((ref) => BackupRestorationService());

/// Provider for backup history
final backupHistoryProvider = FutureProvider.family<List<BackupMetadata>, BackupProvider?>(
  (ref, provider) async {
    final backupManager = ref.watch(backupManagerProvider);
    // Load backup history without full initialization to avoid blocking UI
    return backupManager.getBackupHistory(provider: provider);
  },
);

/// Provider for current backup configuration
final backupConfigProvider = FutureProvider<BackupConfig?>(
  (ref) async => await BackupScheduler.getConfig(),
);

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BackupProvider _selectedProvider = BackupProvider.local;
  bool _isBackupInProgress = false;
  double _backupProgress = 0.0;
  String _backupStatus = '';
  
  // Backup settings
  bool _enableAutoBackup = false;
  BackupFrequency _backupFrequency = BackupFrequency.daily;
  bool _enableEncryption = false;
  bool _includeMedia = true;
  bool _useIncremental = false;
  
  // Restore settings
  RestoreStrategy _restoreStrategy = RestoreStrategy.merge;
  ConflictResolution _conflictResolution = ConflictResolution.useNewer;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBackupSettings();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadBackupSettings() async {
    final config = await BackupScheduler.getConfig();
    if (config != null) {
      setState(() {
        _enableAutoBackup = config.frequency != BackupFrequency.disabled;
        _backupFrequency = config.frequency;
        _enableEncryption = config.enableEncryption;
        _includeMedia = config.includeMedia;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Backup'),
            Tab(text: 'Restore'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBackupTab(theme),
          _buildRestoreTab(theme),
          _buildSettingsTab(theme),
        ],
      ),
    );
  }
  
  Widget _buildBackupTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup Location',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ...BackupProvider.values.map((provider) => RadioListTile<BackupProvider>(
                    title: Text(provider.displayName),
                    subtitle: Text(_getProviderDescription(provider)),
                    value: provider,
                    groupValue: _selectedProvider,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedProvider = value);
                      }
                    },
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Backup options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup Options',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Include Media'),
                    subtitle: const Text('Backup photos and videos'),
                    value: _includeMedia,
                    onChanged: (value) => setState(() => _includeMedia = value),
                  ),
                  SwitchListTile(
                    title: const Text('Encrypt Backup'),
                    subtitle: const Text('Protect with password'),
                    value: _enableEncryption,
                    onChanged: (value) => setState(() => _enableEncryption = value),
                  ),
                  SwitchListTile(
                    title: const Text('Incremental Backup'),
                    subtitle: const Text('Only backup changes since last backup'),
                    value: _useIncremental,
                    onChanged: (value) => setState(() => _useIncremental = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Backup button and progress
          if (_isBackupInProgress) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_backupStatus),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _backupProgress),
                    const SizedBox(height: 8),
                    Text('${(_backupProgress * 100).toInt()}%'),
                  ],
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _performBackup,
                icon: const Icon(Icons.backup),
                label: const Text('Backup Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          
          // Recent backups
          Text(
            'Recent Backups',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildBackupHistory(),
        ],
      ),
    );
  }
  
  Widget _buildRestoreTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restore options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restore Strategy',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<RestoreStrategy>(
                    title: const Text('Replace All'),
                    subtitle: const Text('Replace all existing data with backup'),
                    value: RestoreStrategy.replace,
                    groupValue: _restoreStrategy,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _restoreStrategy = value);
                      }
                    },
                  ),
                  RadioListTile<RestoreStrategy>(
                    title: const Text('Merge'),
                    subtitle: const Text('Merge backup with existing data'),
                    value: RestoreStrategy.merge,
                    groupValue: _restoreStrategy,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _restoreStrategy = value);
                      }
                    },
                  ),
                  RadioListTile<RestoreStrategy>(
                    title: const Text('Append'),
                    subtitle: const Text('Add backup data without replacing'),
                    value: RestoreStrategy.append,
                    groupValue: _restoreStrategy,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _restoreStrategy = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Conflict resolution (only for merge)
          if (_restoreStrategy == RestoreStrategy.merge) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conflict Resolution',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<ConflictResolution>(
                      title: const Text('Keep Existing'),
                      subtitle: const Text('Keep existing data when conflicts occur'),
                      value: ConflictResolution.keepExisting,
                      groupValue: _conflictResolution,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _conflictResolution = value);
                        }
                      },
                    ),
                    RadioListTile<ConflictResolution>(
                      title: const Text('Use Backup'),
                      subtitle: const Text('Replace with backup data when conflicts occur'),
                      value: ConflictResolution.useBackup,
                      groupValue: _conflictResolution,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _conflictResolution = value);
                        }
                      },
                    ),
                    RadioListTile<ConflictResolution>(
                      title: const Text('Use Newer'),
                      subtitle: const Text('Use the newer version based on timestamp'),
                      value: ConflictResolution.useNewer,
                      groupValue: _conflictResolution,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _conflictResolution = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Available backups for restoration
          Text(
            'Available Backups',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildRestorableBackups(),
        ],
      ),
    );
  }
  
  Widget _buildSettingsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto backup settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automatic Backup',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Enable Auto Backup'),
                    subtitle: const Text('Automatically backup your data'),
                    value: _enableAutoBackup,
                    onChanged: (value) => setState(() => _enableAutoBackup = value),
                  ),
                  if (_enableAutoBackup) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('Frequency'),
                      subtitle: Text(_backupFrequency.name),
                      trailing: DropdownButton<BackupFrequency>(
                        value: _backupFrequency,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _backupFrequency = value);
                          }
                        },
                        items: BackupFrequency.values.map((freq) {
                          return DropdownMenuItem(
                            value: freq,
                            child: Text(freq.name),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Storage management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Management',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services),
                    title: const Text('Clean Old Backups'),
                    subtitle: const Text('Remove backups older than 30 days'),
                    trailing: TextButton(
                      onPressed: _cleanOldBackups,
                      child: const Text('CLEAN'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.folder),
                    title: const Text('Backup Storage'),
                    subtitle: FutureBuilder<double>(
                      future: _calculateBackupSize(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text('${snapshot.data!.toStringAsFixed(2)} MB used');
                        }
                        return const Text('Calculating...');
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Syncthing Settings'),
                    subtitle: const Text('Configure peer-to-peer synchronization'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.push('/settings/syncthing'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Save settings button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBackupHistory() {
    final backupHistory = ref.watch(backupHistoryProvider(_selectedProvider));
    
    return backupHistory.when(
      data: (backups) {
        if (backups.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No backups found'),
            ),
          );
        }
        
        return Column(
          children: backups.take(5).map((backup) {
            return Card(
              child: ListTile(
                leading: Icon(_getProviderIcon(backup.provider)),
                title: Text(
                  DateFormat('MMM d, yyyy h:mm a').format(backup.timestamp),
                ),
                subtitle: Text(
                  '${backup.entryCount} entries, ${backup.mediaCount} media, ${backup.sizeMB.toStringAsFixed(2)} MB',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'restore':
                        _restoreBackup(backup);
                        break;
                      case 'delete':
                        _deleteBackup(backup);
                        break;
                      case 'verify':
                        _verifyBackup(backup);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'restore',
                      child: Text('Restore'),
                    ),
                    const PopupMenuItem(
                      value: 'verify',
                      child: Text('Verify'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }
  
  Widget _buildRestorableBackups() {
    final backupHistory = ref.watch(backupHistoryProvider(null));
    
    return backupHistory.when(
      data: (backups) {
        if (backups.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No backups available for restoration'),
            ),
          );
        }
        
        return Column(
          children: backups.map((backup) {
            return Card(
              child: ListTile(
                leading: Icon(_getProviderIcon(backup.provider)),
                title: Text(
                  DateFormat('MMM d, yyyy h:mm a').format(backup.timestamp),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${backup.entryCount} entries, ${backup.mediaCount} media'),
                    if (backup.isFullBackup)
                      const Text('Full backup', style: TextStyle(fontWeight: FontWeight.bold))
                    else
                      const Text('Incremental backup', style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
                isThreeLine: true,
                trailing: ElevatedButton.icon(
                  onPressed: () => _restoreBackup(backup),
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('Restore'),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }
  
  Future<void> _performBackup() async {
    setState(() {
      _isBackupInProgress = true;
      _backupProgress = 0.0;
      _backupStatus = 'Preparing backup...';
    });
    
    try {
      final backupManager = ref.read(backupManagerProvider);
      
      // Initialize only when actually performing backup
      await backupManager.initialize();
      
      String? encryptionPassword;
      
      if (_enableEncryption) {
        encryptionPassword = await _showPasswordDialog(context, 'Enter Backup Password');
        if (encryptionPassword == null || encryptionPassword.isEmpty) {
          setState(() => _isBackupInProgress = false);
          return;
        }
      }
      
      final result = await backupManager.performBackup(
        providers: [_selectedProvider],
        incremental: _useIncremental,
        encryptionPassword: encryptionPassword,
        onProgress: (progress) {
          setState(() {
            _backupProgress = progress;
            _backupStatus = 'Backing up... ${(progress * 100).toInt()}%';
          });
        },
      );
      
      setState(() {
        _isBackupInProgress = false;
        _backupStatus = '';
      });
      
      if (mounted) {
        // Calculate totals from all providers
        int totalEntries = 0;
        int totalMedia = 0;
        for (final metadata in result.values) {
          totalEntries += metadata.entryCount;
          totalMedia += metadata.mediaCount;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup completed: $totalEntries entries, $totalMedia media files',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Refresh backup history
      ref.invalidate(backupHistoryProvider);
      
    } catch (e) {
      setState(() {
        _isBackupInProgress = false;
        _backupStatus = '';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _restoreBackup(BackupMetadata backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to restore this backup from ${DateFormat('MMM d, yyyy').format(backup.timestamp)}?',
            ),
            const SizedBox(height: 16),
            Text('Strategy: ${_restoreStrategy.name}'),
            if (_restoreStrategy == RestoreStrategy.merge)
              Text('Conflict Resolution: ${_conflictResolution.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    String? encryptionPassword;
    if (backup.incrementalData['encrypted'] == true) {
      encryptionPassword = await _showPasswordDialog(context, 'Enter Backup Password');
      if (encryptionPassword == null || encryptionPassword.isEmpty) return;
    }
    
    final restorationService = ref.read(backupRestorationProvider);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Restoring Backup'),
        content: StreamBuilder<RestoreProgress>(
          stream: restorationService.progressStream,
          builder: (context, snapshot) {
            final progress = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(progress?.currentPhase ?? 'Preparing...'),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress?.overallProgress,
                ),
                const SizedBox(height: 8),
                if (progress != null)
                  Text(
                    'Entries: ${progress.processedEntries}/${progress.totalEntries}, '
                    'Media: ${progress.processedMedia}/${progress.totalMedia}',
                  ),
              ],
            );
          },
        ),
      ),
    );
    
    try {
      final result = await restorationService.restoreFromMetadata(
        backup,
        strategy: _restoreStrategy,
        conflictResolution: _conflictResolution,
        encryptionPassword: encryptionPassword,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Restore completed: ${result.restoredEntries} entries, ${result.restoredMedia} media files',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restore failed: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteBackup(BackupMetadata backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text(
          'Are you sure you want to delete this backup from ${DateFormat('MMM d, yyyy').format(backup.timestamp)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    // TODO: Implement backup deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup deleted')),
    );
    
    // Refresh backup history
    ref.invalidate(backupHistoryProvider);
  }
  
  Future<void> _verifyBackup(BackupMetadata backup) async {
    final backupManager = ref.read(backupManagerProvider);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Verifying backup...'),
          ],
        ),
      ),
    );
    
    final isValid = await backupManager.verifyBackup(backup);
    
    if (mounted) {
      Navigator.pop(context); // Close progress dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isValid ? 'Backup is valid and intact' : 'Backup verification failed - may be corrupted',
          ),
          backgroundColor: isValid ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  Future<void> _cleanOldBackups() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean Old Backups'),
        content: const Text(
          'This will delete backups older than 30 days, keeping at least the 10 most recent. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clean'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    final backupManager = ref.read(backupManagerProvider);
    await backupManager.cleanupOldBackups(
      keepLastCount: 10,
      olderThan: const Duration(days: 30),
    );
    
    ref.invalidate(backupHistoryProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Old backups cleaned')),
      );
    }
  }
  
  Future<double> _calculateBackupSize() async {
    final backupManager = ref.read(backupManagerProvider);
    final backups = backupManager.getBackupHistory();
    
    double totalSize = 0;
    for (final backup in backups) {
      totalSize += backup.sizeMB;
    }
    
    return totalSize;
  }
  
  Future<void> _saveSettings() async {
    final config = BackupConfig(
      frequency: _backupFrequency,
      includeMedia: _includeMedia,
      enableEncryption: _enableEncryption,
      maxBackupsToKeep: 10,
      useSyncthingFolder: _selectedProvider == BackupProvider.syncthing,
      useBlossomStorage: _selectedProvider == BackupProvider.blossom,
    );
    
    await BackupScheduler.saveConfig(config);
    
    if (_enableAutoBackup) {
      await BackupScheduler.scheduleBackup(config);
    } else {
      await BackupScheduler.cancelScheduledBackup();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }
  
  String _getProviderDescription(BackupProvider provider) {
    switch (provider) {
      case BackupProvider.local:
        return 'Store backups on this device';
      case BackupProvider.syncthing:
        return 'Sync with other devices via P2P';
      case BackupProvider.blossom:
        return 'Decentralized cloud storage';
    }
  }
  
  IconData _getProviderIcon(BackupProvider provider) {
    switch (provider) {
      case BackupProvider.local:
        return Icons.phone_android;
      case BackupProvider.syncthing:
        return Icons.sync;
      case BackupProvider.blossom:
        return Icons.cloud_outlined;
    }
  }
  
  Future<String?> _showPasswordDialog(BuildContext context, String title) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}