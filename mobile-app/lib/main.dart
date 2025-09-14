import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:purplebase/purplebase.dart';
import 'package:aura_one/router.dart';
import 'package:aura_one/theme.dart';
import 'package:aura_one/theme/colors.dart';
import 'package:aura_one/widgets/simple_theme_switcher.dart';
import 'package:aura_one/widgets/privacy_screen_overlay.dart';
import 'package:aura_one/screens/app_lock_screen.dart';
import 'package:aura_one/services/app_lock_service.dart';
import 'package:aura_one/utils/error_handler.dart';
import 'package:aura_one/utils/logger.dart';
import 'package:aura_one/services/simple_location_service.dart';
import 'package:aura_one/services/movement_tracking_service.dart';
import 'package:aura_one/services/background_data_service.dart';
import 'package:aura_one/providers/fusion_providers.dart';
import 'package:aura_one/providers/context_providers.dart';
import 'package:aura_one/providers/settings_providers.dart';

void main() {
  // Initialize error handling first
  ErrorHandler.initialize();

  // Log app startup
  appLogger.info('Aura One starting...');

  runZonedGuarded(() {
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
        home: const AuraOneSplashScreen(),
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
          child: Stack(
            children: [
              // Theme switcher at the top right
              Positioned(
                top: 16,
                right: 16,
                child: const SimpleThemeSwitcher(),
              ),
              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
            ],
          ),
        ),
      ),
    );
  }
}


final appInitializationProvider = FutureProvider<void>((ref) async {
  try {
    appLogger.info('Initializing app storage...');
    final dir = await getApplicationDocumentsDirectory();

    await ref.read(
      initializationProvider(
        StorageConfiguration(
          databasePath: path.join(dir.path, 'aura_one.db'),
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

    // Initialize location service
    appLogger.info('Initializing location service...');
    final locationService = ref.read(simpleLocationServiceProvider);
    await locationService.initialize();

    // Initialize movement tracking service
    appLogger.info('Initializing movement tracking service...');
    final movementService = ref.read(movementTrackingServiceProvider);
    await movementService.initialize();

    // Initialize background data collection service
    appLogger.info('Initializing background data collection service...');
    final backgroundService = ref.read(backgroundDataServiceProvider);
    await backgroundService.initialize();
    
    // Start background data collection with optimized battery usage
    await backgroundService.startBackgroundDataCollection(
      frequency: const Duration(minutes: 15), // Collect data every 15 minutes
      includeLocation: true,
      includeBle: true,
      includeMovement: true,
    );
    appLogger.info('Background data collection started');

    // Initialize Multi-Modal AI Fusion Engine (if enabled by default)
    appLogger.info('Initializing Multi-Modal AI Fusion Engine...');
    final fusionEnabled = ref.read(fusionEngineRunningProvider);
    if (fusionEnabled) {
      final fusionController = ref.read(fusionEngineControllerProvider);
      await fusionController.start();
      appLogger.info('Multi-Modal AI Fusion Engine started');
    }

    // Initialize Personal Context Engine (if enabled by default)
    appLogger.info('Initializing Personal Context Engine...');
    final contextEnabled = ref.read(contextEngineEnabledProvider);
    if (contextEnabled) {
      final contextEngine = ref.read(personalContextEngineProvider);
      await contextEngine.learnUserPatterns();
      appLogger.info('Personal Context Engine started learning patterns');
    }

    // Initialize Notification Service for daily reminders
    appLogger.info('Initializing Notification Service...');
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize();
    appLogger.info('Notification Service initialized');

    // Initialize daily reminders (this will schedule them if enabled)
    appLogger.info('Setting up daily reminders...');
    final dailyRemindersEnabled = ref.read(dailyRemindersEnabledProvider);
    appLogger.info('Daily reminders ${dailyRemindersEnabled ? 'enabled' : 'disabled'}');

    appLogger.info('App initialization complete');
  } catch (error, stackTrace) {
    appLogger.error('Failed to initialize app', error: error, stackTrace: stackTrace);
    rethrow;
  }
});
