import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionFlow extends HookConsumerWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;
  final bool showCompactView;
  
  const LocationPermissionFlow({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
    this.showCompactView = false,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRequestingPermission = useState(false);
    final currentStep = useState(0);
    
    if (showCompactView) {
      return _buildCompactView(context, theme, isRequestingPermission);
    }
    
    return _buildFullView(context, theme, isRequestingPermission, currentStep);
  }
  
  Widget _buildCompactView(BuildContext context, ThemeData theme, ValueNotifier<bool> isRequestingPermission) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enable Location Services',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Allow Aura One to automatically map your daily journey and add location context to your memories.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isRequestingPermission.value ? null : () {
                      onPermissionDenied?.call();
                    },
                    child: const Text('Not Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isRequestingPermission.value ? null : () {
                      _requestLocationPermission(context, isRequestingPermission);
                    },
                    child: isRequestingPermission.value 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Allow'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFullView(
    BuildContext context, 
    ThemeData theme, 
    ValueNotifier<bool> isRequestingPermission,
    ValueNotifier<int> currentStep,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, theme),
          const SizedBox(height: 32),
          
          // Benefits explanation
          _buildBenefitsSection(context, theme),
          const SizedBox(height: 32),
          
          // Platform-specific guidance
          _buildPlatformGuidance(context, theme),
          const SizedBox(height: 32),
          
          // Privacy assurance
          _buildPrivacyAssurance(context, theme),
          const SizedBox(height: 32),
          
          // Permission steps
          _buildPermissionSteps(context, theme, currentStep.value),
          const SizedBox(height: 32),
          
          // Action buttons
          _buildActionButtons(context, theme, isRequestingPermission, currentStep),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.explore,
            size: 40,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Enhance Your Journey',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let Aura One automatically map your daily adventures and add meaningful location context to your memories.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBenefitsSection(BuildContext context, ThemeData theme) {
    final benefits = [
      {
        'icon': Icons.auto_awesome,
        'title': 'Automatic Journey Mapping',
        'description': 'Your daily paths are recorded automatically, creating a beautiful timeline of where you\'ve been.',
      },
      {
        'icon': Icons.memory,
        'title': 'Memory Enhancement',
        'description': 'Journal entries are enriched with location context, helping you remember the full story.',
      },
      {
        'icon': Icons.notifications_active,
        'title': 'Location Reminders',
        'description': 'Get gentle nudges to journal when you visit meaningful places or return home.',
      },
      {
        'icon': Icons.timeline,
        'title': 'Visual Timeline',
        'description': 'See your life journey on interactive maps and timelines that tell your unique story.',
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What You Get',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...benefits.map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  benefit['icon'] as IconData,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit['title'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      benefit['description'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
  
  Widget _buildPlatformGuidance(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Platform.isIOS ? Icons.phone_iphone : Icons.android,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                Platform.isIOS ? 'iPhone Users' : 'Android Users',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (Platform.isIOS) ...[
            _buildGuidanceStep(
              theme,
              '1.',
              'Choose "Allow While Using App" first',
              'This lets you try location features immediately.',
            ),
            _buildGuidanceStep(
              theme,
              '2.',
              'Upgrade to "Always Allow" for background tracking',
              'For automatic journey mapping, choose "Always Allow" in Settings.',
            ),
            _buildGuidanceStep(
              theme,
              '3.',
              'Enable Background App Refresh',
              'Go to Settings > Aura One > Background App Refresh.',
            ),
          ] else ...[
            _buildGuidanceStep(
              theme,
              '1.',
              'Allow location access',
              'Choose "While using the app" or "Allow all the time".',
            ),
            _buildGuidanceStep(
              theme,
              '2.',
              'Disable battery optimization (optional)',
              'For best background tracking, exclude Aura One from battery optimization.',
            ),
            _buildGuidanceStep(
              theme,
              '3.',
              'Grant precise location (optional)',
              'Choose "Precise" for the most accurate journey mapping.',
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildGuidanceStep(ThemeData theme, String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                step,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
    );
  }
  
  Widget _buildPrivacyAssurance(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondaryContainer,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Privacy is Protected',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• All location data stays on your device\n'
            '• No data is sent to external servers\n'
            '• You can view, export, or delete your data anytime\n'
            '• Location tracking can be paused or disabled instantly',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionSteps(BuildContext context, ThemeData theme, int currentStep) {
    final steps = [
      'Request location permission',
      'Configure tracking settings',
      'Start automatic journey mapping',
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setup Steps',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted 
                      ? theme.colorScheme.primary
                      : isActive
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.outline.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                      ? Icon(
                          Icons.check,
                          color: theme.colorScheme.onPrimary,
                          size: 16,
                        )
                      : Text(
                          '${index + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isActive
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    step,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive || isCompleted
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildActionButtons(
    BuildContext context, 
    ThemeData theme, 
    ValueNotifier<bool> isRequestingPermission,
    ValueNotifier<int> currentStep,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isRequestingPermission.value ? null : () {
            _requestLocationPermission(context, isRequestingPermission, currentStep: currentStep);
          },
          icon: isRequestingPermission.value 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.location_on),
          label: Text(isRequestingPermission.value ? 'Requesting Permission...' : 'Grant Location Permission'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: isRequestingPermission.value ? null : () {
            onPermissionDenied?.call();
          },
          child: const Text('Maybe Later'),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              _showWhyLocationDialog(context);
            },
            child: const Text('Why do you need my location?'),
          ),
        ),
      ],
    );
  }
  
  Future<void> _requestLocationPermission(
    BuildContext context, 
    ValueNotifier<bool> isRequestingPermission,
    {ValueNotifier<int>? currentStep}
  ) async {
    isRequestingPermission.value = true;
    currentStep?.value = 0;
    
    try {
      // Check current permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        currentStep?.value = 0;
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        isRequestingPermission.value = false;
        _showPermissionDeniedDialog(context);
        return;
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        currentStep?.value = 1;
        
        // Check if location service is enabled
        final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          isRequestingPermission.value = false;
          _showLocationServiceDisabledDialog(context);
          return;
        }
        
        currentStep?.value = 2;
        
        // Success
        isRequestingPermission.value = false;
        onPermissionGranted?.call();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission granted! Automatic journey mapping is now active.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  // Navigate to privacy settings
                },
              ),
            ),
          );
        }
      } else {
        isRequestingPermission.value = false;
        onPermissionDenied?.call();
      }
    } catch (e) {
      isRequestingPermission.value = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
          'Location permission has been permanently denied. To enable location features, please go to your device settings and grant location permission to Aura One.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  void _showLocationServiceDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Service Disabled'),
        content: const Text(
          'Location services are disabled on your device. Please enable location services to use automatic journey mapping.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  void _showWhyLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why Location Permission?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aura One uses your location to create a richer journaling experience:\n\n'
                
                '🗺️ Automatic Journey Mapping\n'
                'We track your daily movements to create beautiful timeline visualizations of where you\'ve been.\n\n'
                
                '📝 Enhanced Journal Entries\n'
                'Location context is automatically added to your journal entries, helping you remember the full story.\n\n'
                
                '🔔 Location-Based Reminders\n'
                'Get gentle nudges to journal when you arrive at meaningful places or return home.\n\n'
                
                '🏠 Place Recognition\n'
                'The app learns your frequent locations (home, work, favorite spots) and can suggest tags and memories.\n\n'
                
                '🔒 Privacy First\n'
                'All location data stays on your device and is never shared with external servers.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}

// Permission status widget for showing current state
class LocationPermissionStatus extends ConsumerWidget {
  const LocationPermissionStatus({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<LocationPermission>(
      future: Geolocator.checkPermission(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        
        final permission = snapshot.data!;
        final theme = Theme.of(context);
        
        final (icon, text, color) = switch (permission) {
          LocationPermission.always => (
            Icons.location_on,
            'Always allowed - Background tracking active',
            Colors.green
          ),
          LocationPermission.whileInUse => (
            Icons.location_on_outlined,
            'Allowed while using app',
            Colors.orange
          ),
          LocationPermission.denied => (
            Icons.location_off,
            'Permission denied',
            Colors.red
          ),
          LocationPermission.deniedForever => (
            Icons.location_disabled,
            'Permission permanently denied',
            Colors.red
          ),
          LocationPermission.unableToDetermine => (
            Icons.help_outline,
            'Unable to determine permission status',
            Colors.grey
          ),
        };
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}