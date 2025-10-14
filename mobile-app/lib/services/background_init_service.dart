import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'database/database_provider.dart';

/// Service to handle background initialization of heavy operations
class BackgroundInitService {
  static final BackgroundInitService _instance = BackgroundInitService._internal();
  factory BackgroundInitService() => _instance;
  BackgroundInitService._internal();

  final StreamController<InitializationProgress> _progressController =
      StreamController<InitializationProgress>.broadcast();

  Stream<InitializationProgress> get progressStream => _progressController.stream;

  /// Initialize services with background processing
  Future<InitializationResult> initializeInBackground() async {
    try {
      // Light operations first (main thread)
      _progressController.add(InitializationProgress(
        step: 'Loading preferences',
        progress: 0.1,
      ));

      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      // Get app directory on main thread (required for path operations)
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(dir.path, 'aura_one.db');

      _progressController.add(InitializationProgress(
        step: 'Preparing database',
        progress: 0.2,
      ));

      // Heavy database initialization in background
      await compute(_initializeDatabase, dbPath);

      _progressController.add(InitializationProgress(
        step: 'Initializing database provider',
        progress: 0.3,
      ));

      // Initialize database provider (shared instances)
      await DatabaseProvider.instance.initialize();
      appLogger.info('Database provider initialized');

      _progressController.add(InitializationProgress(
        step: 'Setting up services',
        progress: 0.4,
      ));

      // Initialize services in parallel using Future.wait
      await Future.wait([
        _initializeLocationServiceLazy(onboardingCompleted),
        _initializeMovementServiceLazy(),
        _initializeBackgroundDataServiceLazy(),
        _initializeNotificationServiceLazy(),
      ], eagerError: false);

      _progressController.add(InitializationProgress(
        step: 'Configuring AI engines',
        progress: 0.7,
      ));

      // Defer heavy AI initialization to after UI is ready
      final aiInitDeferred = _scheduleAIInitialization(prefs);

      _progressController.add(InitializationProgress(
        step: 'Finalizing setup',
        progress: 0.9,
      ));

      // Journal service initialization (lightweight)
      await _initializeJournalServiceLazy();

      _progressController.add(InitializationProgress(
        step: 'Ready',
        progress: 1.0,
      ));

      return InitializationResult(
        success: true,
        dbPath: dbPath,
        onboardingCompleted: onboardingCompleted,
        deferredAIInit: aiInitDeferred,
      );
    } catch (e, stackTrace) {
      appLogger.error('Background initialization failed', error: e, stackTrace: stackTrace);
      return InitializationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Initialize database in isolate (heavy operation)
  static Future<bool> _initializeDatabase(String dbPath) async {
    try {
      // Simulate database initialization
      // In real implementation, this would set up tables, indices, etc.
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Lazy initialize location service
  Future<bool> _initializeLocationServiceLazy(bool onboardingCompleted) async {
    try {
      // Defer actual initialization until needed
      if (onboardingCompleted) {
        // Schedule for after UI is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          appLogger.info('Location service initialization scheduled');
        });
      }
      return true;
    } catch (e) {
      appLogger.error('Location service init failed', error: e);
      return false;
    }
  }

  /// Lazy initialize movement tracking service
  Future<bool> _initializeMovementServiceLazy() async {
    try {
      // Defer actual initialization
      Future.delayed(const Duration(milliseconds: 600), () {
        appLogger.info('Movement service initialization scheduled');
      });
      return true;
    } catch (e) {
      appLogger.error('Movement service init failed', error: e);
      return false;
    }
  }

  /// Lazy initialize background data service
  Future<bool> _initializeBackgroundDataServiceLazy() async {
    try {
      // Defer actual initialization
      Future.delayed(const Duration(milliseconds: 700), () {
        appLogger.info('Background data service initialization scheduled');
      });
      return true;
    } catch (e) {
      appLogger.error('Background data service init failed', error: e);
      return false;
    }
  }

  /// Lazy initialize notification service
  Future<bool> _initializeNotificationServiceLazy() async {
    try {
      // Basic setup only, defer permission requests
      Future.delayed(const Duration(milliseconds: 800), () {
        appLogger.info('Notification service initialization scheduled');
      });
      return true;
    } catch (e) {
      appLogger.error('Notification service init failed', error: e);
      return false;
    }
  }

  /// Schedule AI initialization after UI is ready
  Future<void> _scheduleAIInitialization(SharedPreferences prefs) async {
    // Defer heavy AI initialization to after the UI is rendered
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        appLogger.info('Starting deferred AI initialization');

        // Check if fusion engine should be enabled
        final fusionEnabled = prefs.getBool('fusion_engine_enabled') ?? true;
        if (fusionEnabled) {
          // Initialize in background
          await compute(_initializeFusionEngine, null);
          appLogger.info('Fusion engine initialized in background');
        }

        // Check if context engine should be enabled
        final contextEnabled = prefs.getBool('context_engine_enabled') ?? true;
        if (contextEnabled) {
          // Initialize in background
          await compute(_initializeContextEngine, null);
          appLogger.info('Context engine initialized in background');
        }
      } catch (e) {
        appLogger.error('Deferred AI initialization failed', error: e);
      }
    });
  }

  /// Initialize fusion engine in isolate
  static Future<bool> _initializeFusionEngine(void _) async {
    try {
      // Simulate heavy AI model loading
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initialize context engine in isolate
  static Future<bool> _initializeContextEngine(void _) async {
    try {
      // Simulate heavy pattern learning initialization
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initialize journal service (lightweight)
  Future<bool> _initializeJournalServiceLazy() async {
    try {
      // Basic setup only
      appLogger.info('Journal service basic setup complete');
      return true;
    } catch (e) {
      appLogger.error('Journal service init failed', error: e);
      return false;
    }
  }

  void dispose() {
    _progressController.close();
  }
}

/// Progress information for initialization
class InitializationProgress {
  final String step;
  final double progress;

  InitializationProgress({
    required this.step,
    required this.progress,
  });
}

/// Result of initialization
class InitializationResult {
  final bool success;
  final String? dbPath;
  final bool onboardingCompleted;
  final Future<void>? deferredAIInit;
  final String? error;

  InitializationResult({
    required this.success,
    this.dbPath,
    this.onboardingCompleted = false,
    this.deferredAIInit,
    this.error,
  });
}