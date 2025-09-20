import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../providers/settings_providers.dart';
import '../debug/ai_pipeline_test.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

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
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Debug',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Developer Tools section
                      Text(
                        'Developer Tools',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildDebugCard(
                        context: context,
                        theme: theme,
                        isLight: isLight,
                        child: Column(
                          children: [
                            _buildDebugTile(
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
                            _buildDebugTile(
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
                            _buildDebugTile(
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
                      const SizedBox(height: 24),

                      // Testing Tools section
                      Text(
                        'Testing Tools',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildDebugCard(
                        context: context,
                        theme: theme,
                        isLight: isLight,
                        child: Column(
                          children: [
                            _buildDebugTile(
                              icon: Icons.notification_add,
                              title: 'Test Notifications',
                              subtitle: 'Send a test notification to verify reminders work',
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                              theme: theme,
                              onTap: () async {
                                final notificationService = ref.read(notificationServiceProvider);
                                await notificationService.sendTestNotification();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Test notification sent! Check your notification panel.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            Divider(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            _buildDebugTile(
                              icon: Icons.smart_toy,
                              title: 'AI Pipeline Test',
                              subtitle: 'Test AI feature extraction and context synthesis',
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                              theme: theme,
                              onTap: () => testAIPipeline(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugCard({
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

  Widget _buildDebugTile({
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
}