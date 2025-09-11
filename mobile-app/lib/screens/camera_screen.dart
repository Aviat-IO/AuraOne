import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../hooks/use_permission.dart';
import '../widgets/permission_gated_feature.dart';

class CameraScreen extends HookConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cameraPermission = usePermission(
      Permission.camera,
      ref,
      autoRequest: false, // Don't auto-request, wait for user action
      showEducationalUI: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura Camera'),
      ),
      body: SafeArea(
        child: PermissionGatedFeature(
          permission: Permission.camera,
          fallback: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 60,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Capture Your Aura',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Take photos to visualize and analyze your energy field in real-time.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: cameraPermission.isRequesting
                      ? null
                      : () async {
                          final status = await cameraPermission.request();
                          if (status.isGranted && context.mounted) {
                            // Permission granted - camera UI will show automatically
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Camera ready! You can now capture aura photos.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  icon: cameraPermission.isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera),
                  label: Text(
                    cameraPermission.isRequesting
                        ? 'Requesting...'
                        : 'Enable Camera',
                  ),
                ),
                if (cameraPermission.isPermanentlyDenied) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: cameraPermission.openSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Open Settings'),
                  ),
                ],
              ],
            ),
          ),
          child: _CameraView(),
        ),
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // This would be replaced with actual camera preview
    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Camera Preview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '(Camera functionality would be implemented here)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton.large(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aura photo captured!'),
                  ),
                );
              },
              child: const Icon(Icons.camera),
            ),
          ),
        ),
      ],
    );
  }
}
