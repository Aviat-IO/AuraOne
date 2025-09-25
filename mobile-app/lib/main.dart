import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:purplebase/purplebase.dart';
import 'package:aura_one/router.dart';
import 'package:aura_one/theme.dart';
import 'package:aura_one/theme/colors.dart';
import 'package:aura_one/widgets/privacy_screen_overlay.dart';
import 'package:aura_one/screens/app_lock_screen.dart';
import 'package:aura_one/utils/error_handler.dart';
import 'package:aura_one/utils/logger.dart';
import 'package:aura_one/services/simple_location_service.dart';
import 'package:aura_one/services/persistent_location_service.dart';
import 'package:aura_one/services/movement_tracking_service.dart';
import 'package:aura_one/services/background_data_service.dart';
import 'package:aura_one/providers/fusion_providers.dart';
import 'package:aura_one/providers/context_providers.dart';
import 'package:aura_one/providers/settings_providers.dart';
import 'package:aura_one/services/journal_service.dart';
import 'package:aura_one/config/sentry_config.dart';
import 'package:aura_one/services/background_init_service.dart';
import 'package:aura_one/screens/optimized_splash_screen.dart';
import 'package:aura_one/utils/performance_monitor.dart';
import 'package:aura_one/services/data_restoration_service.dart';

// Provider to store restoration status
final restorationStatusProvider = StateProvider<RestorationStatus?>((ref) => null);

void main() {
  // Run the entire app in a single zone to avoid zone mismatch issues
  runZonedGuarded(() async {
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Log app startup
    appLogger.info('Aura One starting...');

    // Enable performance monitoring in debug mode
    if (kDebugMode) {
      PerformanceMonitor().startMonitoring();
    }

    // Load saved theme preference before app starts
    await BrightnessNotifier.loadInitialBrightness();

    // Get package info for dynamic version
    PackageInfo? packageInfo;
    try {
      packageInfo = await PackageInfo.fromPlatform();
      // Set dynamic release version for Sentry
      SentryConfig.release = 'aura-one@${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      appLogger.warning('Could not get package info for Sentry: $e');
      // Fallback to a default version if package info fails
      SentryConfig.release = 'aura-one@0.1.0+1';
    }

    // Initialize Sentry for crash reporting only if enabled and DSN is configured
    if (SentryConfig.enabled && SentryConfig.dsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          // Use DSN from configuration
          options.dsn = SentryConfig.dsn;

          // Set sample rates based on build mode
          options.tracesSampleRate = kDebugMode
              ? SentryConfig.debugTracesSampleRate
              : SentryConfig.productionTracesSampleRate;
          options.profilesSampleRate = kDebugMode
              ? SentryConfig.debugProfilesSampleRate
              : SentryConfig.productionProfilesSampleRate;

          // Configure environment
          options.environment = kDebugMode
              ? SentryConfig.developmentEnvironment
              : SentryConfig.productionEnvironment;

          // Session tracking
          options.enableAutoSessionTracking = SentryConfig.enableAutoSessionTracking && !kDebugMode;
          options.autoSessionTrackingInterval = SentryConfig.autoSessionTrackingInterval;

          // Set release version
          options.release = SentryConfig.release;

        // Privacy settings
        options.sendDefaultPii = SentryConfig.sendDefaultPii;
        options.attachScreenshot = SentryConfig.attachScreenshot;
        options.attachViewHierarchy = SentryConfig.attachViewHierarchy;

        // Breadcrumb configuration
        options.maxBreadcrumbs = SentryConfig.maxBreadcrumbs;
        options.enableAutoNativeBreadcrumbs = SentryConfig.enableAutoNativeBreadcrumbs;

        // Configure before send callback for additional privacy filtering
        options.beforeSend = (SentryEvent event, Hint hint) async {
          // Skip sending if no DSN configured
          if (SentryConfig.dsn.isEmpty) {
            return null;
          }

          // Filter out sensitive error types if needed
          if (event.throwable is NetworkImageLoadException) {
            // Don't report image loading errors (might contain URLs with sensitive data)
            return null;
          }

          return event;
        };
      },
    );
      appLogger.info('Sentry initialized with release: ${SentryConfig.release}');
    } else {
      appLogger.info('Sentry is disabled. Set enabled=true and configure DSN in SentryConfig to enable crash reporting.');
    }

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
      // Initialize persistent location service first
      if (onboardingCompleted) {
        appLogger.info('Initializing persistent location service...');
        final persistentLocationService = PersistentLocationService();
        await persistentLocationService.initialize();

        // Start persistent background location tracking
        final trackingStarted = await persistentLocationService.startTracking(
          intervalMinutes: 2, // Collect location every 2 minutes for better coverage
          distanceFilter: 0, // Capture all positions regardless of movement
        );

        if (trackingStarted) {
          appLogger.info('Persistent background location tracking started successfully');
        } else {
          appLogger.warning('Failed to start persistent location tracking');
        }
      }

      // Initialize simple location service for real-time tracking
      if (onboardingCompleted) {
        final locationService = ref.read(simpleLocationServiceProvider);
        await locationService.initialize();

        final hasPermission = await locationService.checkLocationPermission();
        if (hasPermission) {
          await locationService.startTracking();
          appLogger.info('Real-time location tracking started (post-init)');
        }
      }

      // Initialize movement tracking
      final movementService = ref.read(movementTrackingServiceProvider);
      await movementService.initialize();
      if (onboardingCompleted) {
        await movementService.startTracking();
      }

      // Initialize background data collection with WorkManager
      final backgroundService = ref.read(backgroundDataServiceProvider);
      await backgroundService.initialize();
      await backgroundService.startBackgroundDataCollection(
        frequency: const Duration(minutes: 15),
        includeLocation: true,
        includeBle: true,
        includeMovement: true,
      );

      // Initialize notification service (keep this for basic functionality)
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();

      // Initialize journal service (keep this for basic functionality)
      final journalService = ref.read(journalServiceProvider);
      await journalService.initialize();

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
}
