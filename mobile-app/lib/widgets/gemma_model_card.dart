import 'package:flutter/material.dart';
import '../providers/gemma_model_provider.dart';

class GemmaModelCard extends StatelessWidget {
  const GemmaModelCard({
    super.key,
    required this.state,
    required this.onInstall,
    required this.onDelete,
    required this.onRefresh,
  });

  final GemmaModelState state;
  final VoidCallback onInstall;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.memory,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local AI Model',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gemma 4 is the only local model option for on-device journal generation.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (state.isBusy) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: state.progress),
            const SizedBox(height: 8),
            Text(
              '${(state.progress * 100).round()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: _buildActions(theme)),
        ],
      ),
    );
  }

  String _subtitleText() {
    if (state.isBusy) {
      return 'Downloading Gemma 4 E2B...';
    }

    if (state.isInstalled) {
      return 'Gemma 4 E2B installed (${state.formattedSize})';
    }

    return 'Install Gemma 4 E2B (${state.formattedSize}) for on-device summaries';
  }

  List<Widget> _buildActions(ThemeData theme) {
    if (state.isBusy) {
      return [
        FilledButton.icon(
          onPressed: null,
          icon: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: const Text('Installing'),
        ),
      ];
    }

    if (state.isInstalled) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Installed',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        OutlinedButton(onPressed: onRefresh, child: const Text('Refresh')),
        OutlinedButton(onPressed: onDelete, child: const Text('Remove')),
      ];
    }

    final primaryLabel = state.error == null
        ? 'Install Gemma 4 E2B'
        : 'Retry Install';
    return [
      FilledButton(onPressed: onInstall, child: Text(primaryLabel)),
      OutlinedButton(onPressed: onRefresh, child: const Text('Refresh')),
    ];
  }
}
