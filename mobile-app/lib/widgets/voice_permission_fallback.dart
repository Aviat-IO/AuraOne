import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/permission_service.dart';

class VoicePermissionFallback extends ConsumerWidget {
  final VoidCallback? onPermissionGranted;
  final Widget? alternativeAction;

  const VoicePermissionFallback({
    super.key,
    this.onPermissionGranted,
    this.alternativeAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissionService = ref.watch(permissionServiceProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_off,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Voice Input Unavailable',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Microphone permission is required for voice-to-text features.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (alternativeAction != null) ...[
                Expanded(child: alternativeAction!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final granted = await permissionService.ensureMicrophonePermission(context);
                    if (granted && onPermissionGranted != null) {
                      onPermissionGranted!();
                    }
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Enable Microphone'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A simple icon button that shows permission fallback when pressed without permission
class VoiceInputButton extends ConsumerStatefulWidget {
  final Function(String) onTextReceived;
  final VoidCallback? onListeningStateChanged;
  final bool isListening;

  const VoiceInputButton({
    super.key,
    required this.onTextReceived,
    this.onListeningStateChanged,
    this.isListening = false,
  });

  @override
  ConsumerState<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends ConsumerState<VoiceInputButton> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final permissionService = ref.read(permissionServiceProvider);
    final granted = await permissionService.isMicrophoneGranted();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permissionService = ref.watch(permissionServiceProvider);

    return IconButton(
      icon: Icon(
        widget.isListening ? Icons.stop : Icons.mic,
        color: widget.isListening
          ? theme.colorScheme.error
          : (_hasPermission ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
      onPressed: () async {
        if (!_hasPermission) {
          // Request permission
          final granted = await permissionService.ensureMicrophonePermission(context);
          if (granted) {
            setState(() {
              _hasPermission = true;
            });
            widget.onListeningStateChanged?.call();
          }
        } else {
          // Permission already granted, trigger listening
          widget.onListeningStateChanged?.call();
        }
      },
      tooltip: !_hasPermission
        ? 'Enable microphone access'
        : (widget.isListening ? 'Stop recording' : 'Start voice input'),
    );
  }
}
