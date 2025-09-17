import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/privacy_settings.dart';
import '../../providers/privacy_providers.dart';

/// Quick-start guide for new users to understand and configure privacy settings
/// Provides a guided setup experience with clear explanations
class PrivacyQuickStartGuide extends HookConsumerWidget {
  const PrivacyQuickStartGuide({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Quick Start'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              _buildWelcomeSection(context),
              const SizedBox(height: 24),

              // Step-by-step guide
              _buildStepByStepGuide(context),
              const SizedBox(height: 24),

              // Quick setup buttons
              _buildQuickSetupSection(context, ref),
              const SizedBox(height: 24),

              // Next steps
              _buildNextStepsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.security,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to Aura One',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Privacy-first personal journaling',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Let\'s set up your privacy preferences. Don\'t worry - you can change these anytime, and your data always stays on your device.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepByStepGuide(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Setup Guide',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        _buildStep(
          context,
          1,
          'Choose Location Tracking',
          'Decide if you want location context in your journal entries',
          Icons.location_on,
          Colors.blue,
          () => _showLocationSetup(context),
        ),

        _buildStep(
          context,
          2,
          'Set Data Retention',
          'Choose how long to keep your data on this device',
          Icons.schedule,
          Colors.green,
          () => _showDataRetentionSetup(context),
        ),

        _buildStep(
          context,
          3,
          'Configure Permissions',
          'Grant access to features you want to use',
          Icons.security,
          Colors.orange,
          () => _showPermissionsSetup(context),
        ),

        _buildStep(
          context,
          4,
          'Review Privacy Dashboard',
          'See what data is collected and how it\'s used',
          Icons.dashboard,
          Colors.purple,
          () => context.push('/privacy/dashboard'),
        ),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context,
    int stepNumber,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Step $stepNumber: $title. $description',
      hint: 'Double tap to configure',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      stepNumber.toString(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSetupSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Setup Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a preset that matches your privacy preference, or customize individual settings.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),

            _buildPresetOption(
              context,
              'Maximum Privacy',
              'Location off, minimal permissions, 1 week retention',
              Icons.lock,
              theme.colorScheme.error,
              () => _applyMaxPrivacyPreset(context, ref),
            ),

            _buildPresetOption(
              context,
              'Balanced',
              'Approximate location, essential permissions, 6 month retention',
              Icons.balance,
              theme.colorScheme.primary,
              () => _applyBalancedPreset(context, ref),
            ),

            _buildPresetOption(
              context,
              'Full Features',
              'Precise location, all permissions, 1 year retention',
              Icons.all_inclusive,
              theme.colorScheme.secondary,
              () => _applyFullFeaturesPreset(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$title preset: $description',
      hint: 'Double tap to apply this preset',
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
              color: color.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextStepsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Steps',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'After setup, you can:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            _buildNextStepItem(
              context,
              Icons.dashboard,
              'Monitor your privacy dashboard to see what data is collected',
            ),
            _buildNextStepItem(
              context,
              Icons.settings,
              'Adjust settings anytime in Privacy Settings',
            ),
            _buildNextStepItem(
              context,
              Icons.download,
              'Export your data whenever you want',
            ),
            _buildNextStepItem(
              context,
              Icons.delete,
              'Delete specific data or everything with one tap',
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/privacy/settings'),
                icon: const Icon(Icons.settings),
                label: const Text('Go to Privacy Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Semantics(
      label: text,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationSetup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Tracking'),
        content: const Text(
          'Location data helps provide context to your journal entries. Choose your comfort level:\n\n'
          '• Off: No location tracking\n'
          '• Approximate: City level (~1km)\n'
          '• Balanced: Street level (~50m) - Recommended\n'
          '• Precise: GPS accurate (~10m)\n\n'
          'All location data stays on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/privacy/settings');
            },
            child: const Text('Configure Now'),
          ),
        ],
      ),
    );
  }

  void _showDataRetentionSetup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Retention'),
        content: const Text(
          'Choose how long to keep your data:\n\n'
          '• 1 Week: For short-term tracking\n'
          '• 1 Month: Monthly patterns\n'
          '• 6 Months: Recommended for most users\n'
          '• 1 Year: Annual patterns\n'
          '• Forever: Keep everything\n\n'
          'Older data can be automatically deleted to save space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/privacy/settings');
            },
            child: const Text('Configure Now'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsSetup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Permissions'),
        content: const Text(
          'Grant access to features you want to use:\n\n'
          '• Photo Library: Include photos in entries\n'
          '• Camera: Take photos within the app\n'
          '• Microphone: Record voice notes\n'
          '• Calendar: Automatic context from events\n'
          '• Health: Track wellness metrics\n\n'
          'You can enable or disable these anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/privacy/settings');
            },
            child: const Text('Configure Now'),
          ),
        ],
      ),
    );
  }

  void _applyMaxPrivacyPreset(BuildContext context, WidgetRef ref) {
    final preset = ref.read(privacyPresetProvider(PrivacyPresetLevel.minimal));
    if (preset != null) {
      _showPresetConfirmation(
        context,
        ref,
        preset.title,
        'This will set:\n\n${preset.features.map((f) => '• $f').join('\n')}\n\nYou can adjust these later if needed.',
        PrivacyPresetLevel.minimal,
      );
    }
  }

  void _applyBalancedPreset(BuildContext context, WidgetRef ref) {
    final preset = ref.read(privacyPresetProvider(PrivacyPresetLevel.balanced));
    if (preset != null) {
      _showPresetConfirmation(
        context,
        ref,
        preset.title,
        'This will set:\n\n${preset.features.map((f) => '• $f').join('\n')}\n\nRecommended for most users.',
        PrivacyPresetLevel.balanced,
      );
    }
  }

  void _applyFullFeaturesPreset(BuildContext context, WidgetRef ref) {
    final preset = ref.read(privacyPresetProvider(PrivacyPresetLevel.maximum));
    if (preset != null) {
      _showPresetConfirmation(
        context,
        ref,
        preset.title,
        'This will set:\n\n${preset.features.map((f) => '• $f').join('\n')}\n\nProvides the richest experience.',
        PrivacyPresetLevel.maximum,
      );
    }
  }

  void _showPresetConfirmation(
    BuildContext context,
    WidgetRef ref,
    String title,
    String description,
    PrivacyPresetLevel presetLevel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyPreset(context, ref, title, presetLevel);
            },
            child: const Text('Apply Preset'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyPreset(
    BuildContext context,
    WidgetRef ref,
    String presetName,
    PrivacyPresetLevel presetLevel,
  ) async {
    try {
      // Show loading state
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Apply the preset using the privacy settings notifier
      final notifier = ref.read(privacySettingsNotifierProvider.notifier);
      await notifier.applyPreset(presetLevel);

      // Hide loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$presetName applied successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View Settings',
              onPressed: () => context.push('/privacy/settings'),
            ),
          ),
        );
      }
    } catch (error) {
      // Hide loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply preset: ${error.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _applyPreset(context, ref, presetName, presetLevel),
            ),
          ),
        );
      }
    }
  }
}
