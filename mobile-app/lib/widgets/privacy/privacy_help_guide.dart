import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Comprehensive privacy help guide with step-by-step explanations
/// Provides detailed information about privacy controls and their impact
class PrivacyHelpGuide extends StatelessWidget {
  const PrivacyHelpGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Guide'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction
              _buildIntroSection(context),
              const SizedBox(height: 24),
              
              // Privacy principles
              _buildPrivacyPrinciplesSection(context),
              const SizedBox(height: 24),
              
              // Location tracking guide
              _buildLocationTrackingGuide(context),
              const SizedBox(height: 24),
              
              // Data retention guide
              _buildDataRetentionGuide(context),
              const SizedBox(height: 24),
              
              // Permissions guide
              _buildPermissionsGuide(context),
              const SizedBox(height: 24),
              
              // Data deletion guide
              _buildDataDeletionGuide(context),
              const SizedBox(height: 24),
              
              // Quick actions
              _buildQuickActionsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Privacy First Design',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Aura One is designed with privacy as a fundamental principle. Your personal data stays on your device, and you have complete control over what information is collected and how it\'s used.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPrinciplesSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Our Privacy Principles',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPrincipleItem(
              context,
              Icons.storage,
              'Local First',
              'All your data is stored locally on your device. No cloud storage by default.',
            ),
            
            _buildPrincipleItem(
              context,
              Icons.security,
              'Encryption',
              'Sensitive data is encrypted using industry-standard encryption methods.',
            ),
            
            _buildPrincipleItem(
              context,
              Icons.visibility_off,
              'No Tracking',
              'We don\'t track your behavior or collect analytics without your explicit consent.',
            ),
            
            _buildPrincipleItem(
              context,
              Icons.control_camera,
              'Your Control',
              'You decide what data to share, when to share it, and can delete it anytime.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrincipleItem(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: '$title: $description',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTrackingGuide(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Tracking Guide',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Location data helps provide context to your journal entries by automatically mapping your daily journey.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            _buildLocationOption(
              context,
              'Off',
              'No location data collected',
              'Choose this if you want maximum privacy and don\'t need location context.',
            ),
            
            _buildLocationOption(
              context,
              'Approximate',
              'City/neighborhood level (~1km)',
              'Provides general area context while maintaining privacy.',
            ),
            
            _buildLocationOption(
              context,
              'Balanced',
              'Street level (~50m accuracy)',
              'Good balance between context and battery life. Recommended for most users.',
            ),
            
            _buildLocationOption(
              context,
              'Precise',
              'GPS precise (~10m accuracy)',
              'Most detailed location context but uses more battery.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOption(BuildContext context, String title, String accuracy, String description) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: '$title location tracking: $accuracy. $description',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accuracy,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
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
    );
  }

  Widget _buildDataRetentionGuide(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Retention Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Control how long your data is stored on the device. Automatic cleanup helps manage storage space while preserving recent memories.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            _buildRetentionItem(context, '1 Week', 'For short-term memory tracking'),
            _buildRetentionItem(context, '1 Month', 'Good for monthly patterns'),
            _buildRetentionItem(context, '3 Months', 'Seasonal tracking'),
            _buildRetentionItem(context, '6 Months', 'Recommended for most users'),
            _buildRetentionItem(context, '1 Year', 'Annual patterns and memories'),
            _buildRetentionItem(context, 'Forever', 'Keep all data permanently'),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionItem(BuildContext context, String period, String description) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: 'Retention period $period: $description',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              period,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsGuide(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Permissions Guide',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Each permission enables specific features. You can grant or revoke these at any time.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            _buildPermissionItem(
              context,
              Icons.location_on,
              'Location',
              'Required for automatic journey mapping and location context',
            ),
            _buildPermissionItem(
              context,
              Icons.photo_library,
              'Photo Library',
              'Access photos to include in journal entries and create memories',
            ),
            _buildPermissionItem(
              context,
              Icons.camera_alt,
              'Camera',
              'Take photos directly within journal entries',
            ),
            _buildPermissionItem(
              context,
              Icons.mic,
              'Microphone',
              'Record voice notes and audio memos',
            ),
            _buildPermissionItem(
              context,
              Icons.calendar_today,
              'Calendar',
              'Read calendar events for automatic context in entries',
            ),
            _buildPermissionItem(
              context,
              Icons.favorite,
              'Health Data',
              'Track wellness metrics like steps and activity levels',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: '$title permission: $description',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  Widget _buildDataDeletionGuide(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Deletion Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have complete control over your data and can delete specific information or everything.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            _buildDeletionOption(
              context,
              Icons.cleaning_services,
              'Selective Deletion',
              'Choose specific data types and date ranges to delete while keeping the rest.',
            ),
            _buildDeletionOption(
              context,
              Icons.auto_delete,
              'Automatic Cleanup',
              'Let the app automatically delete old data based on your retention settings.',
            ),
            _buildDeletionOption(
              context,
              Icons.delete_forever,
              'Complete Wipe',
              'Remove all data permanently. This cannot be undone.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletionOption(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: '$title: $description',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildActionButton(
              context,
              Icons.dashboard,
              'View Privacy Dashboard',
              'See data collection insights and statistics',
              () => context.push('/privacy/dashboard')
            ),
            
            _buildActionButton(
              context,
              Icons.settings,
              'Manage Privacy Settings',
              'Configure location tracking, permissions, and data retention',
              () => context.push('/privacy/settings'),
            ),
            
            _buildActionButton(
              context,
              Icons.cleaning_services,
              'Delete Data',
              'Remove specific data or perform a complete wipe',
              () => context.push('/privacy/data-deletion'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Semantics(
      label: '$title: $subtitle',
      hint: 'Double tap to open',
      button: true,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}