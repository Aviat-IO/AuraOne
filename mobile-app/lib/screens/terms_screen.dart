import 'package:flutter/material.dart';
import '../theme/colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Use'),
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
                  'Terms of Use',
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
                  'Acceptance of Terms',
                  'By downloading, installing, or using Aura One, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use the app.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'License to Use',
                  'We grant you a personal, non-exclusive, non-transferable license to use Aura One on your device. You may not copy, modify, distribute, sell, or lease any part of the app or its content.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Your Data',
                  'You retain all rights to your data. Your journal entries, photos, and personal information remain yours. We do not claim any ownership over your content.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Prohibited Uses',
                  'You agree not to:\n\n• Use the app for any unlawful purpose\n• Attempt to reverse engineer or decompile the app\n• Use the app to harm, harass, or violate the rights of others\n• Attempt to gain unauthorized access to our systems',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Disclaimer of Warranties',
                  'Aura One is provided "as is" without warranties of any kind. We do not guarantee that the app will be error-free or uninterrupted. Use the app at your own risk.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Limitation of Liability',
                  'To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of Aura One.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Changes to Terms',
                  'We reserve the right to modify these terms at any time. We will notify you of significant changes through the app. Continued use after changes constitutes acceptance of the new terms.',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Contact Information',
                  'For questions about these terms, please contact us at legal@auraone.app',
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