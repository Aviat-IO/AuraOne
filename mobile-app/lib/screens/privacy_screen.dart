import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/simple_location_service.dart';
import '../theme/colors.dart';
import '../widgets/privacy/privacy_help_guide.dart';
import '../widgets/privacy/privacy_quick_start.dart';
import '../providers/settings_providers.dart';
import '../widgets/grouped_list_container.dart';

// Providers for privacy settings
final locationTrackingEnabledProvider = StateProvider<bool>((ref) => true);

// Photo access provider that checks actual permission state
final photoAccessEnabledProvider = StateNotifierProvider<PhotoAccessNotifier, bool>((ref) {
  return PhotoAccessNotifier();
});

class PhotoAccessNotifier extends StateNotifier<bool> {
  PhotoAccessNotifier() : super(false) {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final status = await Permission.photos.status;
    state = status.isGranted || status.isLimited;
  }

  Future<void> toggle(bool value) async {
    if (value) {
      final status = await Permission.photos.request();
      state = status.isGranted || status.isLimited;
    } else {
      // Can't programmatically revoke permission, just update state
      state = false;
    }
  }

  Future<void> refresh() async {
    await _checkInitialState();
  }
}

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

                // Permission Settings
                _buildSectionHeader(
                  context: context,
                  title: 'Permission Settings',
                  subtitle: 'Control what device features the app can access',
                  icon: Icons.tune,
                ),
                const SizedBox(height: 16),

                // Permission Settings items grouped
                GroupedListContainer(
                  isLight: isLight,
                  children: [
                    // Location tracking toggle
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                      title: Text(
                        'Location Tracking',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
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
                    // Photo library access toggle
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                      title: Text(
                        'Photo Library Access',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
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
                        onChanged: (value) async {
                          await ref.read(photoAccessEnabledProvider.notifier).toggle(value);
                          // Refresh to check actual permission state
                          await ref.read(photoAccessEnabledProvider.notifier).refresh();
                        },
                      ),
                    ),
                    // Reverse geocoding toggle
                    Consumer(
                      builder: (context, ref, _) {
                        final reverseGeocodingEnabled = ref.watch(reverseGeocodingEnabledProvider);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.explore,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Location Names',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Convert coordinates to readable place names',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          trailing: Switch(
                            value: reverseGeocodingEnabled,
                            onChanged: (value) async {
                              if (value) {
                                // Show privacy warning dialog
                                final result = await _showReverseGeocodingWarning(context);
                                if (result == true) {
                                  await ref.read(reverseGeocodingEnabledProvider.notifier).setEnabled(true);
                                }
                              } else {
                                // No warning needed to turn off
                                await ref.read(reverseGeocodingEnabledProvider.notifier).setEnabled(false);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Data & Privacy section
                _buildSectionHeader(
                  context: context,
                  title: 'Data & Privacy',
                  subtitle: 'Manage your personal data and privacy settings',
                  icon: Icons.folder_shared,
                ),
                const SizedBox(height: 16),

                // Data & Privacy items grouped
                GroupedListContainer(
                  isLight: isLight,
                  children: [
                    // Privacy Guide option
                    _buildPrivacyListTile(
                      context: context,
                      theme: theme,
                      icon: Icons.school,
                      title: 'Privacy Guide',
                      subtitle: 'Complete guide to privacy controls and settings',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyHelpGuide(),
                        ),
                      ),
                    ),
                    // Quick Start Guide option
                    _buildPrivacyListTile(
                      context: context,
                      theme: theme,
                      icon: Icons.rocket_launch,
                      title: 'Quick Start Guide',
                      subtitle: 'Guided setup for new users',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyQuickStartGuide(),
                        ),
                      ),
                    ),
                    _buildPrivacyListTile(
                      context: context,
                      theme: theme,
                      icon: Icons.folder_shared,
                      title: 'Export Your Data',
                      subtitle: 'Download a copy of your journal entries and settings',
                      onTap: () {
                        // TODO: Implement data export
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data export feature coming soon')),
                        );
                      },
                    ),
                    _buildPrivacyListTile(
                      context: context,
                      theme: theme,
                      icon: Icons.article,
                      title: 'Privacy Policy',
                      subtitle: 'Read our complete privacy policy and terms',
                      onTap: () {
                        _showPrivacyPolicyDialog(context);
                      },
                    ),
                    _buildPrivacyListTile(
                      context: context,
                      theme: theme,
                      icon: Icons.delete_forever,
                      title: 'Delete All Data',
                      subtitle: 'Permanently remove all your data from this device',
                      isDestructive: true,
                      onTap: () {
                        _showDeleteDataDialog(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyListTile({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

  Future<bool?> _showReverseGeocodingWarning(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Privacy Notice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enabling location names will send GPS coordinates to our privacy-focused geocoding service to convert them into readable place names.',
            ),
            const SizedBox(height: 12),
            Text(
              'Important:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Your location data will leave your device\n'
              '• We use a privacy-first service that doesn\'t store or track your data\n'
              '• Place names improve journal readability but are not required\n'
              '• You can disable this feature at any time',
            ),
            const SizedBox(height: 12),
            const Text(
              'Do you want to enable location names?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}
