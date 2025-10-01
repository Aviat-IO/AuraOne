import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/simple_location_service.dart';
import '../services/background_location_service.dart';
import '../providers/location_database_provider.dart';
import '../providers/settings_providers.dart';

// Provider to track if onboarding has been completed
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pageController = usePageController();
    final currentPage = useState(0);
    final permissionsGranted = useState<Map<Permission, bool>>({
      Permission.location: false,
      Permission.locationAlways: false,
      Permission.photos: false,
      Permission.calendar: false,
      Permission.activityRecognition: false,
      Permission.notification: false,
    });

    // Track location button press count and skip button visibility
    final locationButtonPressCount = useState(0);
    final showSkipButton = useState(false);
    final skipButtonTimer = useRef<DateTime?>(null);

    // Check initial permission states
    useEffect(() {
      Future.microtask(() async {
        final updatedPermissions = <Permission, bool>{};
        for (final permission in permissionsGranted.value.keys) {
          final status = await permission.status;
          updatedPermissions[permission] = status.isGranted || status.isLimited;
        }
        permissionsGranted.value = {
          ...permissionsGranted.value,
          ...updatedPermissions,
        };
      });
      return null;
    }, []);

    // Timer to show skip button after 30 seconds on permissions page
    useEffect(() {
      if (currentPage.value == 3 && !showSkipButton.value) {
        // We're on the permissions page and skip button is not shown
        if (skipButtonTimer.value == null) {
          skipButtonTimer.value = DateTime.now();
        }

        final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!context.mounted) {
            timer.cancel();
            return;
          }

          final elapsed = DateTime.now().difference(skipButtonTimer.value!);
          if (elapsed.inSeconds >= 30) {
            showSkipButton.value = true;
            timer.cancel();
          }
        });

        return timer.cancel;
      } else if (currentPage.value != 3) {
        // Reset when leaving permissions page
        skipButtonTimer.value = null;
        locationButtonPressCount.value = 0;
        showSkipButton.value = false;
      }
      return null;
    }, [currentPage.value]);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (currentPage.value + 1) / 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),

            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: (index) => currentPage.value = index,
                children: [
                  _buildWelcomePage(context, theme),
                  _buildValuePropositionPage(context, theme),
                  _buildPrivacyExplanationPage(context, theme),
                  _buildPermissionsPage(context, theme, ref, permissionsGranted, locationButtonPressCount, showSkipButton),
                  _buildSetupCompletePage(context, theme),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(
              context,
              theme,
              pageController,
              currentPage.value,
              permissionsGranted.value,
              ref,
              showSkipButton.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Aura One',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Personal AI-Powered Life Chronicle',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Transform your daily experiences into a rich, automatic journal that captures the essence of your life - effortlessly.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValuePropositionPage(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'How Aura One Works',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildFeatureItem(
            theme,
            Icons.location_on,
            'Automatic Journey Mapping',
            'Tracks your daily movements to create a visual story of your day',
          ),

          _buildFeatureItem(
            theme,
            Icons.photo_library,
            'Photo Memory Integration',
            'Automatically includes photos from your day in your journal entries',
          ),

          _buildFeatureItem(
            theme,
            Icons.psychology,
            'AI-Generated Narratives',
            'Creates beautiful prose summaries of your day using on-device AI',
          ),

          _buildFeatureItem(
            theme,
            Icons.insights,
            'Pattern Recognition',
            'Discovers trends and insights about your life over time',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyExplanationPage(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Your Privacy is Sacred',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildPrivacyPoint(
            theme,
            Icons.phone_android,
            'Everything Stays on Your Device',
            'All your data is stored locally. Nothing is sent to the cloud.',
          ),

          _buildPrivacyPoint(
            theme,
            Icons.visibility_off,
            'No Tracking, No Analytics',
            'We don\'t collect any usage data or analytics. Your life is yours alone.',
          ),

          _buildPrivacyPoint(
            theme,
            Icons.download,
            'Complete Data Ownership',
            'Export your entire journal anytime. Your memories belong to you.',
          ),

          _buildPrivacyPoint(
            theme,
            Icons.code,
            'Open Source Transparency',
            'Our code is open for inspection. Trust through transparency.',
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    ValueNotifier<Map<Permission, bool>> permissionsGranted,
    ValueNotifier<int> locationButtonPressCount,
    ValueNotifier<bool> showSkipButton,
  ) {
    // Define all permissions in order
    final permissionsList = [
      (Icons.notifications, 'Notifications', 'Daily reminders to write in your journal', Permission.notification, true),
      (Icons.location_on, 'Location', 'Track your journeys and places visited. Tap "Allow While Using App" then change to "Allow All the Time" in Settings for background tracking.', Permission.locationAlways, true),
      (Icons.photo_library, 'Photo Library', 'Include photos in your daily entries. Please choose "Allow All".', Permission.photos, false),
      (Icons.calendar_today, 'Calendar', 'Import events and appointments for your daily summaries', Permission.calendar, false),
      (Icons.directions_walk, 'Motion & Fitness', 'Track activities and movement patterns', Permission.activityRecognition, false),
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Enable Features',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Grant permissions to unlock automatic journaling. You can change these anytime in settings.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Permission counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ValueListenableBuilder<Map<Permission, bool>>(
              valueListenable: permissionsGranted,
              builder: (context, permissions, child) {
                final grantedCount = permissions.values.where((granted) => granted).length;
                final totalCount = permissionsList.length;
                return Text(
                  '$grantedCount of $totalCount permissions granted',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.separated(
              itemCount: permissionsList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final (icon, title, description, permission, isRequired) = permissionsList[index];
                return _buildPermissionTile(
                  context,
                  theme,
                  ref,
                  icon,
                  title,
                  description,
                  permission,
                  permissionsGranted,
                  isRequired: isRequired,
                  onPressed: permission == Permission.locationAlways ? () {
                    locationButtonPressCount.value++;
                    if (locationButtonPressCount.value >= 3) {
                      showSkipButton.value = true;
                    }
                  } : null,
                );
              },
            ),
          ),

          // Helpful message at bottom
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review all permissions above before continuing',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSetupCompletePage(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 60,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re All Set!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Aura One is now ready to start chronicling your life automatically.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primaryContainer,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pro Tip',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Carry your phone with you throughout the day for the best automatic journaling experience. Aura One works quietly in the background to capture your story.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedPage(BuildContext context, ThemeData theme, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rocket_launch,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Ready to Begin',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your journey with Aura One starts now',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          FilledButton.icon(
            onPressed: () async {
              // Mark onboarding as complete
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_completed', true);

              // Enable background location tracking
              await prefs.setBool('backgroundLocationTracking', true);

              // Initialize and start background location tracking
              final bgLocationService = ref.read(backgroundLocationServiceProvider);
              await bgLocationService.initialize();
              await bgLocationService.startTracking();

              // Navigate to main app
              if (context.mounted) {
                context.go('/');
              }
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Start Using Aura One'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(200, 56),
              textStyle: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
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
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildPrivacyPoint(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
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

  Widget _buildPermissionTile(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    IconData icon,
    String title,
    String description,
    Permission permission,
    ValueNotifier<Map<Permission, bool>> permissionsGranted, {
    bool isRequired = false,
    VoidCallback? onPressed,
  }) {
    return ValueListenableBuilder<Map<Permission, bool>>(
      valueListenable: permissionsGranted,
      builder: (context, permissions, child) {
        final isGranted = permissions[permission] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isGranted
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isGranted
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Required',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
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
              const SizedBox(width: 16),
              isGranted
                  ? Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    )
                  : OutlinedButton(
                      onPressed: () async {
                        // Call the custom onPressed callback if provided
                        onPressed?.call();

                        print('Enable button pressed for permission: $permission');

                        // For location permission, handle special Android case
                        if (permission == Permission.locationAlways) {
                          // First request location when in use permission
                          final whenInUseStatus = await Permission.locationWhenInUse.request();
                          print('Location when in use status: ${whenInUseStatus.toString()}');

                          if (whenInUseStatus.isGranted) {
                            // Then request always permission
                            final alwaysStatus = await Permission.locationAlways.request();
                            print('Location always status: ${alwaysStatus.toString()}');

                            final newPermissions = Map<Permission, bool>.from(permissionsGranted.value);
                            newPermissions[permission] = alwaysStatus.isGranted || alwaysStatus.isLimited || whenInUseStatus.isGranted;
                            permissionsGranted.value = newPermissions;

                            // Handle location services
                            final serviceEnabled = await Geolocator.isLocationServiceEnabled();
                            if (!serviceEnabled) {
                              print('Location services not enabled, opening settings');
                              await Geolocator.openLocationSettings();
                            }
                          } else {
                            final newPermissions = Map<Permission, bool>.from(permissionsGranted.value);
                            newPermissions[permission] = false;
                            permissionsGranted.value = newPermissions;
                          }
                        } else {
                          // For other permissions, use normal flow
                          final currentStatus = await permission.status;
                          print('Current permission status: ${currentStatus.toString()}');

                          // If already granted, just update the UI
                          if (currentStatus.isGranted || currentStatus.isLimited) {
                            print('Permission already granted, updating UI');
                            final newPermissions = Map<Permission, bool>.from(permissionsGranted.value);
                            newPermissions[permission] = true;
                            permissionsGranted.value = newPermissions;
                            return;
                          }

                          // Otherwise, request the permission
                          final status = await permission.request();
                          print('Permission request result: ${status.toString()}');

                          final newPermissions = Map<Permission, bool>.from(permissionsGranted.value);
                          newPermissions[permission] = status.isGranted || status.isLimited;
                          permissionsGranted.value = newPermissions;
                          print('Updated permissions: $newPermissions');

                          // If notification permission was granted, sync with settings
                          if (permission == Permission.notification && (status.isGranted || status.isLimited)) {
                            await ref.read(dailyRemindersEnabledProvider.notifier).setEnabled(true);
                          }
                        }
                      },
                      child: const Text('Enable'),
                    ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    ThemeData theme,
    PageController pageController,
    int currentPage,
    Map<Permission, bool> permissions,
    WidgetRef ref,
    bool showSkipButton,
  ) {
    final isLastPage = currentPage == 4;
    final isPermissionsPage = currentPage == 3;

    // Check if all required permissions are granted
    final hasAllRequiredPermissions =
        (permissions[Permission.notification] ?? false) &&
        (permissions[Permission.locationAlways] ?? false);

    // Can continue if has all permissions OR 30 seconds have elapsed (showSkipButton is true)
    final canContinueFromPermissions = hasAllRequiredPermissions || showSkipButton;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (currentPage > 0)
            TextButton(
              onPressed: () {
                pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 80),

          // Skip/Next button
          if (!isLastPage)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add Skip button for permissions page (only show after 30 seconds and no all permissions)
                if (isPermissionsPage && !hasAllRequiredPermissions && showSkipButton)
                  TextButton(
                    onPressed: () {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Skip for now'),
                  ),
                if (isPermissionsPage && !hasAllRequiredPermissions && showSkipButton)
                  const SizedBox(width: 12),
                FilledButton(
                  onPressed: (isPermissionsPage && !canContinueFromPermissions)
                      ? null
                      : () {
                          pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                  child: Text(
                    isPermissionsPage ? 'Continue' : 'Next',
                  ),
                ),
              ],
            )
          else
            FilledButton(
              onPressed: () async {
                // Complete onboarding
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_completed', true);

                // Save final notification permission state to settings
                final notificationPermission = permissions[Permission.notification] ?? false;
                if (notificationPermission) {
                  // If permission was granted during onboarding, enable daily reminders
                  await ref.read(dailyRemindersEnabledProvider.notifier).setEnabled(true);
                } else {
                  // If permission was not granted, ensure daily reminders are disabled
                  await ref.read(dailyRemindersEnabledProvider.notifier).setEnabled(false);
                }

                // Enable background location tracking
                await prefs.setBool('backgroundLocationTracking', true);

                // Initialize and start background location tracking
                final bgLocationService = ref.read(backgroundLocationServiceProvider);
                await bgLocationService.initialize();
                await bgLocationService.startTracking();

                // Navigate to main app
                if (context.mounted) {
                  context.go('/');
                }
              },
              child: const Text('Get Started'),
            ),
        ],
      ),
    );
  }
}
