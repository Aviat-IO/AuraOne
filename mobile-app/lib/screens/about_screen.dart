import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/colors.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Aura One'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App icon and version
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
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
                              ? AuraColors.lightPrimary.withValues(alpha: 0.3)
                              : AuraColors.darkPrimary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aura One',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version ${_packageInfo?.version ?? '0.1.0'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (_packageInfo?.buildNumber != null && _packageInfo!.buildNumber.isNotEmpty)
                      Text(
                        'Build ${_packageInfo!.buildNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Vision section
              _buildSection(
                context,
                icon: Icons.auto_awesome,
                title: 'The Effortless Chronicle',
                content: 'Aura One redefines digital journaling by shifting from active creation to passive curation. '
                    'It functions as a comprehensive lifelogging application, automatically constructing a rich, '
                    'multimedia narrative of your day with minimal direct input.\n\n'
                    'Your role transforms from author starting with a blank page to editor refining a detailed draft, '
                    'creating a living digital autobiography that helps you identify patterns and improve your life '
                    'through enhanced self-reflection.',
              ),
              const SizedBox(height: 20),

              // Privacy section
              _buildSection(
                context,
                icon: Icons.privacy_tip,
                title: 'Privacy by Design',
                content: 'Built on a strict local-first model, all your data—journal entries, media, and metadata—'
                    'resides exclusively on your device. This deliberate departure from cloud-centric models '
                    'ensures your most personal moments remain truly private.\n\n'
                    'The complete source code is open-source, allowing independent auditing of our security '
                    'and privacy claims. Your data sovereignty is guaranteed through non-proprietary export '
                    'formats and complete data portability.',
              ),
              const SizedBox(height: 20),

              // Features section
              _buildSection(
                context,
                icon: Icons.star,
                title: 'Key Features',
                content: '• Automatic daily chronicle generation from device data\n'
                    '• AI-powered narrative synthesis and insights\n'
                    '• Interactive voice-to-AI editing\n'
                    '• Location tracking and journey mapping\n'
                    '• Photo library integration\n'
                    '• Health and fitness data tracking\n'
                    '• Pattern recognition and trend analysis\n'
                    '• Complete data export and backup options\n'
                    '• End-to-end encryption for all backups',
              ),
              const SizedBox(height: 20),

              // Technology section
              _buildSection(
                context,
                icon: Icons.code,
                title: 'Built with Care',
                content: 'Aura One leverages cutting-edge on-device AI technology to provide powerful insights '
                    'without compromising your privacy. All processing happens locally on your device, '
                    'ensuring your personal data never leaves your control.\n\n'
                    'The app is designed for the privacy-conscious individual who values deep self-reflection '
                    'and personal data analysis but is unwilling to compromise on data ownership.',
              ),
              const SizedBox(height: 32),

              // Links section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                child: Column(
                  children: [
                    _buildLinkTile(
                      context,
                      icon: Icons.policy,
                      title: 'Privacy Policy',
                      onTap: () {
                        // Navigate to privacy policy
                      },
                    ),
                    const Divider(height: 1),
                    _buildLinkTile(
                      context,
                      icon: Icons.description,
                      title: 'Terms of Service',
                      onTap: () {
                        // Navigate to terms
                      },
                    ),
                    const Divider(height: 1),
                    _buildLinkTile(
                      context,
                      icon: Icons.code,
                      title: 'Source Code',
                      onTap: () {
                        // Open GitHub
                      },
                    ),
                    const Divider(height: 1),
                    _buildLinkTile(
                      context,
                      icon: Icons.support,
                      title: 'Support',
                      onTap: () {
                        // Open support
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'Made with ❤️ for privacy-conscious journalers',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '© 2024 Aura One',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.primary,
        size: 20,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}