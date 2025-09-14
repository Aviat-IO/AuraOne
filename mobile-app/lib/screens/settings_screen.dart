import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/simple_theme_switcher.dart';
import '../widgets/page_header.dart';
import '../theme.dart';
import '../theme/colors.dart';
import '../providers/settings_providers.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = ref.watch(brightnessProvider);
    final isLight = theme.brightness == Brightness.light;
    final dailyReminders = ref.watch(dailyRemindersEnabledProvider);
    final fontSize = ref.watch(fontSizeProvider);

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
                // Settings header
                const PageHeader(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'Customize your wellness experience',
                ),
                const SizedBox(height: 32),

                // Settings sections
                        // Appearance section
                        Text(
                          'Appearance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildSettingsCard(
                          context: context,
                          theme: theme,
                          isLight: isLight,
                          child: Column(
                            children: [
                              _buildSettingsTile(
                                icon: Icons.palette,
                                title: 'Theme',
                                subtitle: brightness == Brightness.light ? 'Light mode' : 'Dark mode',
                                trailing: const SimpleThemeSwitcher(),
                                theme: theme,
                              ),
                              Divider(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              _buildSettingsTile(
                                icon: Icons.text_fields,
                                title: 'Font Size',
                                subtitle: _getFontSizeSubtitle(fontSize),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                theme: theme,
                                onTap: () {
                                  context.push('/settings/font-size');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Journal section
                        Text(
                          'Journal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildSettingsCard(
                          context: context,
                          theme: theme,
                          isLight: isLight,
                          child: Column(
                            children: [
                              _buildSettingsTile(
                                icon: Icons.notifications,
                                title: 'Daily Reminders',
                                subtitle: 'Get reminded to write in your journal',
                                trailing: Switch(
                                  value: dailyReminders,
                                  onChanged: (value) async {
                                    if (value) {
                                      // Request notification permission if enabling
                                      final status = await Permission.notification.request();
                                      if (status.isGranted) {
                                        ref.read(dailyRemindersEnabledProvider.notifier).setEnabled(value);
                                      } else {
                                        // Show permission denied message
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please enable notifications in settings to use daily reminders'),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      ref.read(dailyRemindersEnabledProvider.notifier).setEnabled(value);
                                    }
                                  },
                                ),
                                theme: theme,
                              ),
                              Divider(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              _buildSettingsTile(
                                icon: Icons.auto_awesome,
                                title: 'AI Suggestions',
                                subtitle: 'Enable AI-powered writing suggestions',
                                trailing: Switch(
                                  value: true, // TODO: Connect to actual settings
                                  onChanged: (value) {
                                    // TODO: Implement AI settings
                                  },
                                ),
                                theme: theme,
                              ),
                              Divider(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              _buildSettingsTile(
                                icon: Icons.backup,
                                title: 'Auto Backup',
                                subtitle: 'Automatically backup your entries',
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                theme: theme,
                                onTap: () {
                                  context.push('/settings/backup');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Wellness section
                        Text(
                          'Wellness',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildSettingsCard(
                          context: context,
                          theme: theme,
                          isLight: isLight,
                          child: Column(
                            children: [
                              _buildSettingsTile(
                                icon: Icons.track_changes,
                                title: 'Mood Tracking',
                                subtitle: 'Track your daily mood and emotions',
                                trailing: Switch(
                                  value: true, // TODO: Connect to actual settings
                                  onChanged: (value) {
                                    // TODO: Implement mood tracking settings
                                  },
                                ),
                                theme: theme,
                              ),
                              Divider(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              _buildSettingsTile(
                                icon: Icons.insights,
                                title: 'Wellness Insights',
                                subtitle: 'Get personalized wellness recommendations',
                                trailing: Switch(
                                  value: true, // TODO: Connect to actual settings
                                  onChanged: (value) {
                                    // TODO: Implement insights settings
                                  },
                                ),
                                theme: theme,
                              ),
                              Divider(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              _buildSettingsTile(
                                icon: Icons.camera_alt,
                                title: 'Aura Camera',
                                subtitle: 'Capture and analyze your aura',
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                theme: theme,
                                onTap: () {
                                  context.push('/camera');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Support section
                        Text(
                          'Support',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildSettingsCard(
                          context: context,
                          theme: theme,
                          isLight: isLight,
                          child: Column(
                            children: [
                              _buildSettingsTile(
                                icon: Icons.help_outline,
                                title: 'Help & Support',
                                subtitle: 'Get help and contact support',
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                theme: theme,
                                onTap: () {
                                  // TODO: Navigate to help screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Help & Support coming soon')),
                                  );
                                },
                              ),
                              Divider(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              _buildSettingsTile(
                                icon: Icons.info_outline,
                                title: 'About Aura One',
                                subtitle: 'App version and information',
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                theme: theme,
                                onTap: () {
                                  context.push('/settings/about');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Debug section
                        Text(
                          'Debug',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildSettingsCard(
                          context: context,
                          theme: theme,
                          isLight: isLight,
                          child: Column(
                            children: [
                              _buildSettingsTile(
                                icon: Icons.speed,
                                title: 'Data Viewer',
                                subtitle: 'View real-time sensor data',
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                theme: theme,
                                onTap: () {
                                  context.push('/debug/data-viewer');
                                },
                              ),
                              Divider(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              _buildSettingsTile(
                                icon: Icons.storage,
                                title: 'Database',
                                subtitle: 'Browse historical collected data',
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                theme: theme,
                                onTap: () {
                                  context.push('/debug/database-viewer');
                                },
                              ),
                              Divider(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              _buildSettingsTile(
                                icon: Icons.psychology,
                                title: 'AI Models',
                                subtitle: 'Manage AI models for on-device processing',
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                theme: theme,
                                onTap: () {
                                  context.push('/settings/ai-models');
                                },
                              ),
                              Divider(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              _buildSettingsTile(
                                icon: Icons.directions_walk,
                                title: 'HAR Test',
                                subtitle: 'Test Human Activity Recognition model',
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                theme: theme,
                                onTap: () {
                                  context.push('/test/har');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isLight,
    required Widget child,
  }) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
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
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  String _getFontSizeSubtitle(FontSize size) {
    return switch (size) {
      FontSize.small => 'Standard text (Default)',
      FontSize.medium => 'Medium text',
      FontSize.large => 'Large text',
    };
  }
}
