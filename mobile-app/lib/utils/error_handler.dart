import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'logger.dart';

/// Global error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Privacy-safe context for error reporting
  static final Map<String, dynamic> _safeContext = {};

  /// Add safe context that will be included with error reports
  static void setSafeContext(String key, dynamic value) {
    // Only add non-PII data
    _safeContext[key] = value;
  }

  /// Clear all safe context
  static void clearSafeContext() {
    _safeContext.clear();
  }

  /// Get current safe context
  static Map<String, dynamic> getSafeContext() {
    return Map.from(_safeContext);
  }

  /// Initialize global error handling
  static Future<void> initialize() async {
    // Get package info for version information
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setSafeContext('app_version', packageInfo.version);
      setSafeContext('build_number', packageInfo.buildNumber);
    } catch (e) {
      // Fallback if package info fails
      appLogger.warning('Could not get package info: $e');
      setSafeContext('app_version', 'unknown');
    }

    // Set up initial safe context
    setSafeContext('platform_os', Platform.operatingSystem);
    setSafeContext('locale', PlatformDispatcher.instance.locale.languageCode); // Only language code
    setSafeContext('screen_size', '${PlatformDispatcher.instance.views.first.physicalSize.width.toInt()}x${PlatformDispatcher.instance.views.first.physicalSize.height.toInt()}');

    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // In debug mode, log to console
        FlutterError.dumpErrorToConsole(details);
      } else {
        // In release mode, log silently
        appLogger.error(
          'Flutter error',
          error: details.exception,
          stackTrace: details.stack,
        );
      }

      // Report to crash analytics (if configured)
      _reportToCrashlytics(details.exception, details.stack);
    };

    // Handle platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      appLogger.error(
        'Platform error',
        error: error,
        stackTrace: stack,
      );

      // Report to crash analytics (if configured)
      _reportToCrashlytics(error, stack);

      // Return true to prevent the app from crashing
      return true;
    };

    // Set custom error widget for production
    if (!kDebugMode) {
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return _buildErrorWidget(details);
      };
    }
  }

  /// Handle async errors
  static void handleError(dynamic error, StackTrace? stackTrace) {
    appLogger.error(
      'Unhandled error',
      error: error,
      stackTrace: stackTrace,
    );

    // Report to crash analytics (if configured)
    _reportToCrashlytics(error, stackTrace);
  }

  /// Log a message as a breadcrumb (no-op, Sentry removed)
  static void logBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) {
    // No-op: Sentry has been removed
    appLogger.debug('Breadcrumb: $message');
  }

  /// Capture a message (no-op, Sentry removed)
  static Future<void> captureMessage(
    String message, {
    Map<String, String>? tags,
  }) async {
    // No-op: Sentry has been removed
    appLogger.info('Message: $message');
  }

  /// Report error to crash analytics service (no-op, Sentry removed)
  static void _reportToCrashlytics(dynamic error, StackTrace? stackTrace) {
    // No-op: Sentry has been removed
    // Errors are logged via appLogger instead
    appLogger.error('Error: ${error.runtimeType}', error: error, stackTrace: stackTrace);
  }

  /// Build a user-friendly error widget
  static Widget _buildErrorWidget(FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We apologize for the inconvenience. Please try restarting the app.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    details.exception.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Run a function with error handling
  static Future<T?> runWithErrorHandling<T>(
    Future<T> Function() function, {
    String? context,
    bool showError = true,
  }) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      appLogger.error(
        context ?? 'Error during operation',
        error: error,
        stackTrace: stackTrace,
      );

      // Log error with context (Sentry removed)
      if (context != null) {
        appLogger.warning('Operation failed: $context');
      }

      if (showError && kDebugMode) {
        // Show error in debug mode
        debugPrint('Error: $error');
      }

      return null;
    }
  }
}

/// Provider for error notifications
final errorNotifierProvider = StateNotifierProvider<ErrorNotifier, ErrorState>((ref) {
  return ErrorNotifier();
});

/// Error state
class ErrorState {
  final String? message;
  final bool hasError;

  const ErrorState({
    this.message,
    this.hasError = false,
  });
}

/// Error notifier for UI error handling
class ErrorNotifier extends StateNotifier<ErrorState> {
  ErrorNotifier() : super(const ErrorState());

  void setError(String message) {
    state = ErrorState(
      message: message,
      hasError: true,
    );

    // Auto-clear error after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      clearError();
    });
  }

  void clearError() {
    state = const ErrorState();
  }
}
