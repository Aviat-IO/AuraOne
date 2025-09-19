import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/simple_theme_switcher.dart';
import '../widgets/page_header.dart';
import '../widgets/grouped_list_container.dart';
import '../theme.dart';
import '../theme/colors.dart';
import '../providers/settings_providers.dart';
import '../providers/fusion_providers.dart';
import '../providers/context_providers.dart';
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

                        GroupedListContainer(
                          isLight: isLight,
                          children: [
                            _buildSettingsTile(
                              icon: Icons.palette,
                              title: 'Theme',
                              subtitle: brightness == Brightness.light ? 'Light mode' : 'Dark mode',
                              trailing: const SimpleThemeSwitcher(),
                              theme: theme,
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
                        const SizedBox(height: 24),

                        // Journal section
                        Text(
                          'Journal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        GroupedListContainer(
                          isLight: isLight,
                          children: [
                            _buildSettingsTile(
                              icon: Icons.notifications,
                              title: 'Daily Reminders',
                              subtitle: 'Get reminded to write in your journal',
                              trailing: Switch(
                                value: dailyReminders,
                                onChanged: (value) async {
                                  if (value) {
                                    try {
                                      // Request notification permission first
                                      final notificationStatus = await Permission.notification.request();

                                      if (!notificationStatus.isGranted) {
                                        // Show permission denied message
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please enable notifications in settings to use daily reminders'),
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      // Request exact alarm permission for Android 12+
                                      final notificationService = ref.read(notificationServiceProvider);
                                      final permissionsGranted = await notificationService.requestPermissions();

                                      if (permissionsGranted) {
                                        // All permissions granted, enable reminders
                                        await ref.read(dailyRemindersEnabledProvider.notifier).setEnabled(value);
                                      } else {
                                        // Show permission denied message
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please enable exact alarms permission in settings to use daily reminders'),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      // Handle any errors
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to enable reminders: ${e.toString()}'),
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    // Disabling reminders doesn't need permissions
                                    await ref.read(dailyRemindersEnabledProvider.notifier).setEnabled(value);
                                  }
                                },
                              ),
                              theme: theme,
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
                            _buildSettingsTile(
                              icon: Icons.merge_type,
                              title: 'Multi-Modal AI Fusion',
                              subtitle: 'Combine photos, location, and movement for richer summaries',
                              trailing: Consumer(
                                builder: (context, ref, _) {
                                  final isRunning = ref.watch(fusionEngineRunningProvider);
                                  return Switch(
                                    value: isRunning,
                                    onChanged: (value) async {
                                      final controller = ref.read(fusionEngineControllerProvider);
                                      await controller.toggle();
                                    },
                                  );
                                },
                              ),
                              theme: theme,
                            ),
                            _buildSettingsTile(
                              icon: Icons.auto_awesome_motion,
                              title: 'Personal Context Engine',
                              subtitle: 'Learn from patterns to provide personalized insights and recommendations',
                              trailing: Consumer(
                                builder: (context, ref, _) {
                                  final isEnabled = ref.watch(contextEngineEnabledProvider);
                                  return Switch(
                                    value: isEnabled,
                                    onChanged: (value) async {
                                      await ref.read(contextEngineEnabledProvider.notifier).setEnabled(value);
                                    },
                                  );
                                },
                              ),
                              theme: theme,
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
                        const SizedBox(height: 24),

                        // Support section
                        Text(
                          'Support',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        GroupedListContainer(
                          isLight: isLight,
                          children: [
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
                            _buildSettingsTile(
                              icon: Icons.bug_report_outlined,
                              title: 'Debug',
                              subtitle: 'Developer tools and diagnostics',
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                              theme: theme,
                              onTap: () {
                                context.push('/settings/debug');
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
