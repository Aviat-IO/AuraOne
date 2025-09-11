import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Provider for permission service
final permissionServiceProvider = Provider((ref) => PermissionService());

class PermissionService {
  // Check if microphone permission is granted
  Future<bool> isMicrophoneGranted() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  // Request microphone permission with proper flow
  Future<bool> requestMicrophonePermission(BuildContext context) async {
    // Check current status
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Show rationale dialog before requesting
      final shouldRequest = await _showRationaleDialog(context);
      if (!shouldRequest || !context.mounted) {
        return false;
      }

      // Request permission
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      if (context.mounted) {
        await _showSettingsDialog(context);
      }
      return false;
    }

    // Handle other statuses (restricted, limited)
    return false;
  }

  // Show rationale dialog explaining why we need microphone permission
  Future<bool> _showRationaleDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.mic, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Microphone Permission'),
            ],
          ),
          content: const Text(
            'Aura One needs access to your microphone to enable voice-to-text features for journaling. '
            'This allows you to speak your thoughts instead of typing them. '
            'Your voice data is processed on-device for privacy.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Not Now',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow Access'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Show dialog to guide user to settings
  Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Permission Required'),
            ],
          ),
          content: const Text(
            'Microphone permission has been permanently denied. '
            'Please enable it in your device settings to use voice-to-text features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Check and request microphone permission with UI feedback
  Future<bool> ensureMicrophonePermission(BuildContext context) async {
    try {
      return await requestMicrophonePermission(context);
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      return false;
    }
  }
}
