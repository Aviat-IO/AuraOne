import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_manager.dart';

class PermissionGatedFeature extends ConsumerStatefulWidget {
  final Permission permission;
  final Widget child;
  final Widget? fallback;
  final bool requestOnTap;
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const PermissionGatedFeature({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.requestOnTap = true,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  ConsumerState<PermissionGatedFeature> createState() => _PermissionGatedFeatureState();
}

class _PermissionGatedFeatureState extends ConsumerState<PermissionGatedFeature> {
  PermissionStatus? _status;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await widget.permission.status;
    if (mounted) {
      setState(() {
        _status = status;
      });
      
      // Update global permission state
      ref.read(permissionStatesProvider.notifier).updateStatus(widget.permission, status);
    }
  }

  Future<void> _requestPermission() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });

    final manager = ref.read(permissionManagerProvider);
    final status = await manager.requestPermission(
      context,
      widget.permission,
      showEducationalUI: true,
    );

    if (mounted) {
      setState(() {
        _status = status;
        _isChecking = false;
      });
      
      // Update global permission state
      ref.read(permissionStatesProvider.notifier).updateStatus(widget.permission, status);
      
      if (status.isGranted || status.isLimited) {
        widget.onPermissionGranted?.call();
      } else {
        widget.onPermissionDenied?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_status!.isGranted || _status!.isLimited) {
      return widget.child;
    }

    // Permission not granted - show fallback or default UI
    if (widget.fallback != null) {
      if (widget.requestOnTap) {
        return GestureDetector(
          onTap: _requestPermission,
          child: widget.fallback!,
        );
      }
      return widget.fallback!;
    }

    // Default fallback UI
    final config = ref.read(permissionManagerProvider).getConfig(widget.permission);
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: widget.requestOnTap ? _requestPermission : null,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config?.icon ?? Icons.lock_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              config?.title ?? 'Permission Required',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _status!.isPermanentlyDenied
                  ? 'This permission has been denied. Tap to open settings.'
                  : 'Tap to enable this feature',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (config?.alternativeAction != null && _status!.isDenied) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        config!.alternativeAction!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isChecking) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
            if (_status!.isPermanentlyDenied) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await openAppSettings();
                  // Check permission again when returning from settings
                  _checkPermission();
                },
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Open Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Simplified permission gate for inline use
class PermissionGate extends ConsumerWidget {
  final Permission permission;
  final Widget Function(BuildContext context, PermissionStatus status) builder;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PermissionStatus>(
      future: permission.status,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return builder(context, snapshot.data!);
      },
    );
  }
}