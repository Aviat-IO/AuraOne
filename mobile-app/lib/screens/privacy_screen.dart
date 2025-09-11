import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/simple_location_service.dart';
import '../theme/colors.dart';
import '../widgets/common/help_tooltip.dart';
import '../widgets/privacy/privacy_help_guide.dart';
import '../widgets/privacy/privacy_quick_start.dart';

// Providers for privacy settings
final locationTrackingEnabledProvider = StateProvider<bool>((ref) => true);
final photoAccessEnabledProvider = StateProvider<bool>((ref) => false);

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final locationEnabled = ref.watch(locationTrackingEnabledProvider);
    final photoAccessEnabled = ref.watch(photoAccessEnabledProvider);
    final locationService = ref.watch(simpleLocationServiceProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight ? [
              AuraColors.lightSurface,
              AuraColors.lightSurface.withValues(alpha: 0.95),
              AuraColors.lightSurfaceContainerLow.withValues(alpha: 0.9),
            ] : [
              AuraColors.darkSurface,
              AuraColors.darkSurface.withValues(alpha: 0.98),
              AuraColors.darkSurfaceContainerLow.withValues(alpha: 0.95),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy header (scrollable)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isLight
                            ? AuraColors.lightLogoGradient
                            : AuraColors.darkLogoGradient,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isLight
                              ? AuraColors.lightPrimary.withValues(alpha: 0.2)
                              : AuraColors.darkPrimary.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              'Privacy & Security',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your privacy settings',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Privacy overview card (scrollable)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLight
                        ? AuraColors.lightCardGradient
                        : AuraColors.darkCardGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isLight
                          ? AuraColors.lightPrimary.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Your Privacy Matters',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aura One is designed with privacy at its core. Your personal data stays on your device, and you have complete control over what information is shared.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Local-first data storage',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'End-to-end encryption for sensitive data',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No tracking or analytics without consent',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Privacy Dashboard Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: isLight
                        ? [theme.colorScheme.primary, theme.colorScheme.secondary]
                        : [theme.colorScheme.primary, theme.colorScheme.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/privacy/dashboard'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.dashboard,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Privacy Dashboard',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'View data collection insights and statistics',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Permission Settings with help
                HelpSectionHeader(
                  title: 'Permission Settings',
                  subtitle: 'Control what device features the app can access',
                  helpText: 'These permissions enable specific features in the app. Location tracking helps provide context to your journal entries, while photo access lets you include images. You can enable or disable these anytime without affecting other app functionality.',
                  icon: Icons.tune,
                ),
                const SizedBox(height: 16),

                // Location tracking toggle
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLight
                        ? AuraColors.lightCardGradient
                        : AuraColors.darkCardGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isLight
                          ? AuraColors.lightPrimary.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: HelpTooltip(
                      message: 'Location tracking provides context for your journal entries',
                      detailedHelp: 'When enabled, the app tracks your location to automatically provide context for your journal entries. This helps you remember where you were when you wrote specific entries. Location data is stored locally on your device and never shared with external servers.',
                      child: Text(
                        'Location Tracking',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    subtitle: Text(
                      'Track places you visit for journal context',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: Switch(
                      value: locationEnabled,
                      onChanged: (value) async {
                        ref.read(locationTrackingEnabledProvider.notifier).state = value;
                        if (value) {
                          await locationService.startTracking();
                        } else {
                          await locationService.stopTracking();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Photo library access toggle
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLight
                        ? AuraColors.lightCardGradient
                        : AuraColors.darkCardGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isLight
                          ? AuraColors.lightPrimary.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.photo_library,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: HelpTooltip(
                      message: 'Access device photos to include in journal entries',
                      detailedHelp: 'Photo library access allows you to select existing photos from your device to include in journal entries. This makes it easy to add visual memories to your writing. The app only accesses photos you specifically select.',
                      child: Text(
                        'Photo Library Access',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    subtitle: Text(
                      'Access photos to enrich your journal entries',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: Switch(
                      value: photoAccessEnabled,
                      onChanged: (value) {
                        ref.read(photoAccessEnabledProvider.notifier).state = value;
                        // TODO: Request photo library permission when enabled
                        if (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Photo library access enabled')),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // View location history button
                if (locationEnabled)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isLight
                          ? AuraColors.lightCardGradient
                          : AuraColors.darkCardGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isLight
                            ? AuraColors.lightPrimary.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.history,
                          color: theme.colorScheme.secondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Location History',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'View and manage your location data',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      onTap: () => context.push('/privacy/location-history'),
                    ),
                  ),

                const SizedBox(height: 24),

                // Data & Privacy section with help
                HelpSectionHeader(
                  title: 'Data & Privacy',
                  subtitle: 'Manage your personal data and privacy settings',
                  helpText: 'These options let you control your personal data. You can export a complete copy of your data, view our privacy policy, or delete all data from your device. All operations are performed locally and securely.',
                  icon: Icons.folder_shared,
                ),
                const SizedBox(height: 16),

                // Privacy Guide option
                _buildPrivacyOptionWithTooltip(
                  context: context,
                  theme: theme,
                  isLight: isLight,
                  icon: Icons.school,
                  title: 'Privacy Guide',
                  subtitle: 'Complete guide to privacy controls and settings',
                  helpMessage: 'Learn about all privacy features',
                  detailedHelp: 'A comprehensive guide explaining all privacy features, settings, and best practices for protecting your personal data.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PrivacyHelpGuide(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Start Guide option
                _buildPrivacyOptionWithTooltip(
                  context: context,
                  theme: theme,
                  isLight: isLight,
                  icon: Icons.rocket_launch,
                  title: 'Quick Start Guide',
                  subtitle: 'Guided setup for new users',
                  helpMessage: 'Configure privacy settings with guided setup',
                  detailedHelp: 'A step-by-step guide to help you configure your privacy settings quickly and easily.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PrivacyQuickStartGuide(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _buildPrivacyOptionWithTooltip(
                  context: context,
                  theme: theme,
                  isLight: isLight,
                  icon: Icons.folder_shared,
                  title: 'Export Your Data',
                  subtitle: 'Download a copy of your journal entries and settings',
                  helpMessage: 'Download a copy of all your personal data',
                  detailedHelp: 'Export creates a complete backup of your journal entries, settings, and preferences. You can choose different formats (JSON, CSV) and decide what data to include. This is useful for backups or transferring to another device.',
                  onTap: () {
                    // TODO: Implement data export
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data export feature coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildPrivacyOptionWithTooltip(
                  context: context,
                  theme: theme,
                  isLight: isLight,
                  icon: Icons.delete_forever,
                  title: 'Delete All Data',
                  subtitle: 'Permanently remove all your data from this device',
                  helpMessage: 'Permanently remove all data from this device',
                  detailedHelp: 'This action permanently deletes all your journal entries, photos, settings, and app data from this device. This cannot be undone. Consider exporting your data first as a backup.',
                  isDestructive: true,
                  onTap: () {
                    _showDeleteDataDialog(context);
                  },
                ),
                const SizedBox(height: 12),

                _buildPrivacyOptionWithTooltip(
                  context: context,
                  theme: theme,
                  isLight: isLight,
                  icon: Icons.article,
                  title: 'Privacy Policy',
                  subtitle: 'Read our complete privacy policy and terms',
                  helpMessage: 'Read our complete privacy policy and terms',
                  detailedHelp: 'Our privacy policy explains how we handle your data, what information we collect, and your rights. We believe in transparency and your right to understand how your personal information is used.',
                  onTap: () {
                    _showPrivacyPolicyDialog(context);
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyOptionWithTooltip({
    required BuildContext context,
    required ThemeData theme,
    required bool isLight,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required String helpMessage,
    String? detailedHelp,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
            ? AuraColors.lightCardGradient
            : AuraColors.darkCardGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
              ? AuraColors.lightPrimary.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive
              ? Colors.red
              : theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: HelpTooltip(
          message: helpMessage,
          detailedHelp: detailedHelp,
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDestructive ? Colors.red : null,
            ),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPrivacyOption({
    required BuildContext context,
    required ThemeData theme,
    required bool isLight,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
            ? AuraColors.lightCardGradient
            : AuraColors.darkCardGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
              ? AuraColors.lightPrimary.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive
              ? Colors.red
              : theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to permanently delete all your journal entries and app data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement data deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data deletion feature coming soon')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.policy, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Privacy Policy'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Collection and Use',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aura One is designed with privacy as a fundamental principle. We collect minimal data and only what is necessary to provide the journaling experience you expect.\n\n'
                  '• Location data (if enabled): Used solely to provide context for your journal entries\n'
                  '• Photos (if accessed): Only photos you explicitly select are processed\n'
                  '• Usage data: Basic app usage statistics to improve functionality\n\n'
                  'All personal data is stored locally on your device using industry-standard encryption.',
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Storage and Security',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Local-first architecture: Your data stays on your device\n'
                  '• No cloud storage without explicit consent\n'
                  '• End-to-end encryption for sensitive information\n'
                  '• Regular security updates and audits\n'
                  '• Data retention policies you control\n',
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Rights and Control',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Access: View all data we have about you\n'
                  '• Export: Download your data in standard formats\n'
                  '• Delete: Remove specific data or all data permanently\n'
                  '• Control: Enable or disable features at any time\n'
                  '• Transparency: This policy and our practices are always available\n',
                ),
                const SizedBox(height: 16),
                Text(
                  'Contact and Updates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This policy may be updated to reflect changes in our practices or legal requirements. Any significant changes will be communicated through the app.\n\n'
                  'For questions about privacy or data handling, you can contact us through the app settings.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/privacy/settings');
            },
            child: const Text('Manage Settings'),
          ),
        ],
      ),
    );
  }
}
