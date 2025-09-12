import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/syncthing/enhanced_syncthing_service.dart';

class SyncthingSettingsScreen extends HookConsumerWidget {
  const SyncthingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncthingService = useMemoized(() => EnhancedSyncthingService());
    final isConnected = useState(false);
    final devices = useState<List<SyncthingDevice>>([]);
    final folders = useState<List<SyncthingFolder>>([]);
    final isLoading = useState(true);
    final errorMessage = useState<String?>(null);

    // Initialize and check connection
    useEffect(() {
      Future<void> initSyncthing() async {
        try {
          final connected = await syncthingService.isConnected();
          isConnected.value = connected;
          
          if (connected) {
            final results = await Future.wait([
              syncthingService.getDevices(),
              syncthingService.getFolders(),
            ]);
            devices.value = results[0] as List<SyncthingDevice>;
            folders.value = results[1] as List<SyncthingFolder>;
            
            // Listen to device discovery
            syncthingService.deviceDiscoveryStream.listen((discoveredDevices) {
              devices.value = discoveredDevices;
            });
            
            // Listen to sync status
            syncthingService.syncStatusStream.listen((status) {
              // Update UI based on sync status if needed
            });
          }
        } catch (e) {
          errorMessage.value = e.toString();
        } finally {
          isLoading.value = false;
        }
      }
      
      initSyncthing();
      return null;
    }, []);

    if (isLoading.value) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Syncthing Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!isConnected.value) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Syncthing Settings'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sync_disabled,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Syncthing Not Connected',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure Syncthing is running and accessible',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (errorMessage.value != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Error: ${errorMessage.value}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  isLoading.value = true;
                  errorMessage.value = null;
                  // Retry connection
                },
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Syncthing Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.devices), text: 'Devices'),
              Tab(icon: Icon(Icons.folder), text: 'Folders'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DevicesTab(
              devices: devices.value,
              syncthingService: syncthingService,
            ),
            _FoldersTab(
              folders: folders.value,
              syncthingService: syncthingService,
            ),
            _SettingsTab(
              syncthingService: syncthingService,
            ),
          ],
        ),
      ),
    );
  }
}

class _DevicesTab extends HookWidget {
  final List<SyncthingDevice> devices;
  final EnhancedSyncthingService syncthingService;

  const _DevicesTab({
    required this.devices,
    required this.syncthingService,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh devices list
        await syncthingService.getDevices();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Device'),
              subtitle: const Text('Pair with another Syncthing device'),
              onTap: () => _showAddDeviceDialog(context),
            ),
          ),
          const SizedBox(height: 16),
          if (devices.isEmpty)
            const Center(
              child: Text('No devices configured'),
            )
          else
            ...devices.map((device) => _DeviceCard(
              device: device,
              syncthingService: syncthingService,
            )),
        ],
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddDeviceDialog(syncthingService: syncthingService),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final SyncthingDevice device;
  final EnhancedSyncthingService syncthingService;

  const _DeviceCard({
    required this.device,
    required this.syncthingService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          device.connected ? Icons.devices : Icons.devices_other,
          color: device.connected 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
        ),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.connected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: device.connected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              ),
            ),
            if (device.lastSeen != null)
              Text('Last seen: ${_DeviceCard._formatLastSeen(device.lastSeen!)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Device ID', device.deviceId),
                if (device.address != null)
                  _infoRow('Address', device.address!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!device.connected)
                      TextButton(
                        onPressed: () => syncthingService.connectDevice(device.deviceId),
                        child: const Text('Connect'),
                      ),
                    if (device.connected)
                      TextButton(
                        onPressed: () => syncthingService.pauseDevice(device.deviceId),
                        child: const Text('Pause'),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _confirmRemoveDevice(context, device),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveDevice(BuildContext context, SyncthingDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text('Are you sure you want to remove "${device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              syncthingService.removeDevice(device.deviceId);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
  
  static String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    }
  }
}

class _AddDeviceDialog extends HookWidget {
  final EnhancedSyncthingService syncthingService;

  const _AddDeviceDialog({required this.syncthingService});

  @override
  Widget build(BuildContext context) {
    final deviceIdController = useTextEditingController();
    final nameController = useTextEditingController();
    final isLoading = useState(false);

    return AlertDialog(
      title: const Text('Add Device'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: deviceIdController,
            decoration: const InputDecoration(
              labelText: 'Device ID',
              hintText: 'Enter Syncthing device ID',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Device Name',
              hintText: 'Enter a friendly name',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading.value ? null : () async {
            if (deviceIdController.text.isEmpty || nameController.text.isEmpty) {
              return;
            }
            
            isLoading.value = true;
            try {
              await syncthingService.addDevice(
                deviceIdController.text.trim(),
                nameController.text.trim(),
              );
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device added successfully')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding device: $e')),
                );
              }
            } finally {
              isLoading.value = false;
            }
          },
          child: isLoading.value 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Add'),
        ),
      ],
    );
  }
}

class _FoldersTab extends HookWidget {
  final List<SyncthingFolder> folders;
  final EnhancedSyncthingService syncthingService;

  const _FoldersTab({
    required this.folders,
    required this.syncthingService,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh folders list
        await syncthingService.getFolders();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('Configure AuraOne Sync'),
              subtitle: const Text('Set up backup folder synchronization'),
              onTap: () => _showConfigureFolderDialog(context),
            ),
          ),
          const SizedBox(height: 16),
          if (folders.isEmpty)
            const Center(
              child: Text('No folders configured'),
            )
          else
            ...folders.map((folder) => _FolderCard(
              folder: folder,
              syncthingService: syncthingService,
            )),
        ],
      ),
    );
  }

  void _showConfigureFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ConfigureFolderDialog(syncthingService: syncthingService),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final SyncthingFolder folder;
  final EnhancedSyncthingService syncthingService;

  const _FolderCard({
    required this.folder,
    required this.syncthingService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          Icons.folder_outlined,
          color: folder.paused 
            ? Theme.of(context).colorScheme.outline
            : Theme.of(context).colorScheme.primary,
        ),
        title: Text(folder.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(folder.paused ? 'Paused' : 'Active'),
            Text(
              folder.path,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Folder ID', folder.id),
                _infoRow('Path', folder.path),
                _infoRow('Type', folder.type),
                if (folder.devices.isNotEmpty) ...[
                  const Text('Shared with:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...folder.devices.map((deviceId) => Text('  • $deviceId')),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (folder.paused)
                      TextButton(
                        onPressed: () => syncthingService.resumeFolder(folder.id),
                        child: const Text('Resume'),
                      )
                    else
                      TextButton(
                        onPressed: () => syncthingService.pauseFolder(folder.id),
                        child: const Text('Pause'),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => syncthingService.scanFolder(folder.id),
                      child: const Text('Scan Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
}

class _ConfigureFolderDialog extends HookWidget {
  final EnhancedSyncthingService syncthingService;

  const _ConfigureFolderDialog({required this.syncthingService});

  @override
  Widget build(BuildContext context) {
    final labelController = useTextEditingController(text: 'AuraOne Backup');
    final isLoading = useState(false);

    return AlertDialog(
      title: const Text('Configure Sync Folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: labelController,
            decoration: const InputDecoration(
              labelText: 'Folder Label',
              hintText: 'Enter a friendly name',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This will configure Syncthing to sync your AuraOne backup folder with other devices.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading.value ? null : () async {
            isLoading.value = true;
            try {
              // Get AuraOne sync folder path
              final syncFolder = await syncthingService.getSyncFolder();
              
              await syncthingService.configureFolder(
                folderId: 'auraone-backup',
                folderPath: syncFolder.path,
                label: labelController.text.trim(),
                versioning: true,
              );
              
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Folder configured successfully')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error configuring folder: $e')),
                );
              }
            } finally {
              isLoading.value = false;
            }
          },
          child: isLoading.value 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Configure'),
        ),
      ],
    );
  }
}

class _SettingsTab extends HookWidget {
  final EnhancedSyncthingService syncthingService;

  const _SettingsTab({required this.syncthingService});

  @override
  Widget build(BuildContext context) {
    final syncStatus = useState<SyncthingStatus?>(null);

    useEffect(() {
      final subscription = syncthingService.syncStatusStream.listen((status) {
        syncStatus.value = status;
      });
      return subscription.cancel;
    }, []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (syncStatus.value != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _statusRow('Global State', syncStatus.value!.globalState),
                  _statusRow('My ID', syncStatus.value!.myId),
                  if (syncStatus.value!.inSyncBytes != null)
                    _statusRow('In Sync', '${syncStatus.value!.inSyncBytes} bytes'),
                  if (syncStatus.value!.needBytes != null)
                    _statusRow('Need to Sync', '${syncStatus.value!.needBytes} bytes'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Restart Syncthing'),
                subtitle: const Text('Restart the Syncthing service'),
                onTap: () => _confirmRestart(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.pause),
                title: const Text('Pause All'),
                subtitle: const Text('Pause all synchronization'),
                onTap: () => syncthingService.pauseAll(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Resume All'),
                subtitle: const Text('Resume all synchronization'),
                onTap: () => syncthingService.resumeAll(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Syncthing'),
                subtitle: const Text('Learn more about Syncthing'),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }

  void _confirmRestart(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Syncthing'),
        content: const Text(
          'This will restart the Syncthing service. You may temporarily lose connection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              syncthingService.restart();
              Navigator.of(context).pop();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Syncthing'),
        content: const Text(
          'Syncthing is a continuous file synchronization program. '
          'It synchronizes files between two or more computers in real time, '
          'safely protected from prying eyes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
}