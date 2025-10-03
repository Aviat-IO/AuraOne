import 'package:flutter/material.dart';
import '../theme/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last Updated: January 2025',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSection(
                  context,
                  'Privacy-First Architecture',
                  'Aura One is built with your privacy as the foundation. All your journal entries, photos, and personal data remain on your device. We do not collect, store, or transmit your personal information to any servers.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Data Storage',
                  'Your data is stored locally on your device using encrypted databases. You have complete control over your data and can export or delete it at any time.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Optional Cloud AI',
                  'If you choose to enable Cloud AI features, your journal context (timeline events, locations, activities) is sent to Google\'s Gemini API for enhanced narrative generation. This requires your explicit consent and can be disabled at any time in Settings > Privacy.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Location Data',
                  'Location tracking is optional and requires your permission. Location data is stored locally on your device and used only to enhance your journal entries with contextual information.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Photos and Media',
                  'All photos and media you add to your journal are stored locally. We use on-device AI (ML Kit) to analyze photos for scene detection and object recognition. This processing happens entirely on your device.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Third-Party Services',
                  'Aura One may use the following third-party services:\n\n• Google ML Kit (on-device AI processing)\n• Google Gemini API (optional, requires consent)\n\nThese services have their own privacy policies that govern their use of your data.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Data Export and Deletion',
                  'You can export all your data in standard formats at any time through Settings > Backup & Export. You can also permanently delete all your data from your device.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Contact Us',
                  'For privacy-related questions or concerns, please contact us at privacy@auraone.app',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}