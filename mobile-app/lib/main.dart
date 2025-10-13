import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:purplebase/purplebase.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aura_one/router.dart';
import 'package:aura_one/theme.dart';
import 'package:aura_one/theme/colors.dart';
import 'package:aura_one/widgets/privacy_screen_overlay.dart';
import 'package:aura_one/screens/app_lock_screen.dart';
import 'package:aura_one/utils/error_handler.dart';
import 'package:aura_one/utils/logger.dart';
import 'package:aura_one/services/background_location_service.dart';
import 'package:aura_one/services/simple_location_service.dart';
import 'package:aura_one/providers/fusion_providers.dart';
import 'package:aura_one/providers/context_providers.dart';
import 'package:aura_one/providers/settings_providers.dart';
import 'package:aura_one/providers/location_database_provider.dart';
import 'package:aura_one/services/journal_service.dart';
import 'package:aura_one/services/background_init_service.dart';
import 'package:aura_one/screens/optimized_splash_screen.dart';
import 'package:aura_one/utils/performance_monitor.dart';
import 'package:aura_one/services/data_restoration_service.dart';
import 'package:aura_one/services/calendar_initialization_service.dart';
import 'package:aura_one/services/ai/adapter_registry.dart';
import 'package:aura_one/services/ai/template_adapter.dart';
import 'package:aura_one/services/ai/cloud_gemini_adapter.dart';
import 'package:aura_one/services/ai/managed_cloud_gemini_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to store restoration status
final restorationStatusProvider = StateProvider<RestorationStatus?>((ref) => null);

void main() {
  // Run the entire app in a single zone to avoid zone mismatch issues
  runZonedGuarded(() async {
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables from .env file
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env file is optional - app will work without it
      appLogger.info('No .env file found, using defaults');
    }

    // Initialize timezone data
    tz.initializeTimeZones();

    // Set local timezone based on device's local time
    // We'll use a simple approach to determine timezone offset
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Find a timezone with the matching offset
      // For Utah (Mountain Time), this should resolve to America/Denver
      String timezoneName = 'UTC';

      if (offset.inHours == -7 || offset.inHours == -6) {
        // Mountain Time (MST/MDT)
        timezoneName = 'America/Denver';
      } else if (offset.inHours == -8 || offset.inHours == -7) {
        // Pacific Time (PST/PDT)
        timezoneName = 'America/Los_Angeles';
      } else if (offset.inHours == -5 || offset.inHours == -4) {
        // Eastern Time (EST/EDT)
        timezoneName = 'America/New_York';
      } else if (offset.inHours == -6 || offset.inHours == -5) {
        // Central Time (CST/CDT)
        timezoneName = 'America/Chicago';
      }

      tz.setLocalLocation(tz.getLocation(timezoneName));
      appLogger.info('Timezone initialized: $timezoneName (offset: ${offset.inHours}h)');
    } catch (e) {
      appLogger.warning('Could not detect timezone, using UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    // Note: Background location now uses flutter_background_geolocation
    // which handles its own initialization

    // Log app startup
    appLogger.info('Aura One starting...');

    // Enable performance monitoring in debug mode
    if (kDebugMode) {
      PerformanceMonitor().startMonitoring();
    }

    // Load saved theme preference before app starts
    await BrightnessNotifier.loadInitialBrightness();

    // Register AI adapters in privacy-first priority order
    // Tier 1: Managed Cloud - Backend proxy with rate limiting (no API key needed)
    // Tier 2: BYOK Cloud - Direct Gemini API for users with their own API key
    // Tier 3: Template - Privacy-first fallback, always available
    appLogger.info('Registering AI adapters...');
    final adapterRegistry = AdapterRegistry();
    adapterRegistry.registerAdapter(
      ManagedCloudGeminiAdapter(),
      1,
    ); // Tier 1: Managed service (backend proxy, rate-limited)
    adapterRegistry.registerAdapter(CloudGeminiAdapter(), 2); // Tier 2: BYOK (user-provided API key)
    adapterRegistry.registerAdapter(TemplateAdapter(), 3); // Tier 3: Privacy-first fallback (always available)
    appLogger.info('AI adapters registered successfully');

    // Initialize error handling after Sentry
    await ErrorHandler.initialize();

    runApp(
      ProviderScope(
        overrides: [
          storageNotifierProvider.overrideWith(
            (ref) => PurplebaseStorageNotifier(ref),
          ),
        ],
        child: const AuraOneApp(),
      ),
    );
  }, (error, stack) {
    ErrorHandler.handleError(error, stack);
  });
}

class AuraOneApp extends ConsumerWidget {
  const AuraOneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = 'AuraOne';
    final theme = ref.watch(themeProvider);

    return switch (ref.watch(appInitializationProvider)) {
      AsyncLoading() => MaterialApp(
        title: title,
        theme: theme,
        home: const OptimizedSplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
      AsyncError(:final error) => MaterialApp(
        title: title,
        theme: theme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
      _ => MaterialApp.router(
        title: title,
        theme: theme,
        routerConfig: ref.watch(routerProvider),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return PrivacyScreenOverlay(
            child: Stack(
              children: [
                child!,
                const AppLockScreen(),
              ],
            ),
          );
        },
      ),
    };
  }
}

class AuraOneSplashScreen extends StatelessWidget {
  const AuraOneSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
              ? AuraColors.lightBackgroundGradient
              : AuraColors.darkBackgroundGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                // Aura One Logo - a mindful, circular design
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLight
                        ? AuraColors.lightLogoGradient
                        : AuraColors.darkLogoGradient,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isLight
                          ? AuraColors.lightPrimary.withValues(alpha: 0.2)
                          : AuraColors.darkPrimary.withValues(alpha: 0.15),
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      // Inner circle with icon
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          Icons.self_improvement,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Aura One',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Personal Wellness Journey',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Powered by Nostr • Location-Aware • Private',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Loading indicator
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


final appInitializationProvider = FutureProvider<void>((ref) async {
  try {
    appLogger.info('Starting optimized app initialization...');

    // Check for existing data from previous installation
    final restorationService = DataRestorationService();
    final restorationStatus = await restorationService.checkForExistingData();

    if (restorationStatus.isRestorationNeeded) {
      appLogger.info('Found existing data from previous installation');
      // The restoration dialog will be shown in the UI after initialization
      // Store the status for later use
      ref.read(restorationStatusProvider.notifier).state = restorationStatus;
    }

    // Use background initialization service for better performance
    final initService = BackgroundInitService();
    final initResult = await initService.initializeInBackground();

    if (!initResult.success) {
      throw Exception('Initialization failed: ${initResult.error}');
    }

    // Initialize storage with the database path from background init
    await ref.read(
      initializationProvider(
        StorageConfiguration(
          databasePath: initResult.dbPath!,
          relayGroups: {
            'default': {
              'wss://relay.damus.io',
              'wss://relay.primal.net',
              'wss://nos.lol',
            },
          },
          defaultRelayGroup: 'default',
        ),
      ).future,
    );

    // Services are now initialized lazily in background
    // Heavy operations are deferred to after UI is ready

    appLogger.info('App initialization complete (optimized)');

    // Post-initialization tasks (non-blocking)
    _schedulePostInitializationTasks(ref, initResult.onboardingCompleted);

  } catch (error, stackTrace) {
    appLogger.error('Failed to initialize app', error: error, stackTrace: stackTrace);
    rethrow;
  }
});

/// Schedule post-initialization tasks that don't block the UI
void _schedulePostInitializationTasks(Ref ref, bool onboardingCompleted) {
  // These run after the UI is ready
  Future.delayed(const Duration(milliseconds: 2000), () async {
    try {
      bool locationTrackingActive = false;

      // Initialize free background location service only if enabled
      if (onboardingCompleted) {
        // Check if user has opted in to background location tracking
        final prefs = await SharedPreferences.getInstance();
        final backgroundTrackingEnabled = prefs.getBool('backgroundLocationTracking') ?? false;

        if (backgroundTrackingEnabled) {
          appLogger.info('Initializing background location service (user opted-in)...');
          final backgroundLocationService = BackgroundLocationService(ref);
          final initialized = await backgroundLocationService.initialize();

          if (initialized) {
            final hasPermission = await backgroundLocationService.checkLocationPermission();
            
            if (hasPermission) {
              final trackingStarted = await backgroundLocationService.startTracking();

              if (trackingStarted) {
                appLogger.info('Background location tracking started successfully');
                locationTrackingActive = true;
              } else {
                appLogger.warning('Failed to start background location tracking');
              }
            } else {
              appLogger.warning('Background location permission not granted');
            }
          } else {
            appLogger.warning('Failed to initialize background location service');
          }
        } else {
          appLogger.info('Background location tracking is disabled by user preference');
        }
      }

      // Initialize simple location service for real-time tracking
      if (onboardingCompleted) {
        final simpleLocationService = SimpleLocationService(ref);
        await simpleLocationService.initialize();

        final hasPermission = await simpleLocationService.checkLocationPermission();
        if (hasPermission) {
          await simpleLocationService.startTracking();
          appLogger.info('Real-time location tracking started (post-init)');
          locationTrackingActive = true;
        }
      }

      // Show notification if onboarding is complete but location tracking is not active
      if (onboardingCompleted && !locationTrackingActive) {
        appLogger.info('Location tracking inactive for returning user, showing notification');
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.showLocationServicesWarning();
      }

      // Background data collection now handled by efficient location service

      // Initialize notification service (keep this for basic functionality)
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();

      // Initialize journal service (keep this for basic functionality)
      final journalService = ref.read(journalServiceProvider);
      await journalService.initialize();

      // Initialize calendar settings and permissions
      final calendarInitService = ref.read(calendarInitializationServiceProvider);
      await calendarInitService.initialize();
      appLogger.info('Calendar settings initialized (post-init)');

    } catch (e) {
      appLogger.error('Post-initialization task failed', error: e);
    }
  });

  // Heavy AI initialization happens even later
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      // Initialize fusion engine if enabled
      final fusionEnabled = ref.read(fusionEngineRunningProvider);
      if (fusionEnabled) {
        final fusionController = ref.read(fusionEngineControllerProvider);
        await fusionController.start();
        appLogger.info('Fusion engine started (post-init)');
      }

      // Initialize context engine if enabled
      final contextEnabled = ref.read(contextEngineEnabledProvider);
      if (contextEnabled) {
        final contextEngine = ref.read(personalContextEngineProvider);
        await contextEngine.learnUserPatterns();
        appLogger.info('Context engine started (post-init)');
      }
    } catch (e) {
      appLogger.error('AI initialization failed', error: e);
    }
  });

  // Schedule daily cleanup of old data
  Future.delayed(const Duration(seconds: 10), () async {
    try {
      // Perform initial cleanup
      final cleanupService = ref.read(locationDataCleanupProvider);
      await cleanupService.performCleanup(
        retentionPeriod: const Duration(days: 30),  // Keep location data for 30 days
        movementRetentionPeriod: const Duration(days: 3),  // Keep movement data for only 3 days
      );
      appLogger.info('Initial data cleanup completed');

      // Schedule daily cleanup at 3 AM
      Timer.periodic(const Duration(hours: 24), (timer) async {
        final now = DateTime.now();
        if (now.hour == 3) {  // Run at 3 AM local time
          await cleanupService.performCleanup(
            retentionPeriod: const Duration(days: 30),
            movementRetentionPeriod: const Duration(days: 3),
          );
          appLogger.info('Daily data cleanup completed');
        }
      });
    } catch (e) {
      appLogger.error('Data cleanup failed', error: e);
    }
  });
}
