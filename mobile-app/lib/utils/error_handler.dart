import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
  static void initialize() {
    // Set up initial safe context
    setSafeContext('app_version', '1.0.0'); // TODO: Get from package info
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

  /// Log a message to Sentry as a breadcrumb
  static void logBreadcrumb({
    required String message,
    String? category,
    SentryLevel? level,
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      return; // Don't log breadcrumbs in debug mode
    }

    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category ?? 'app',
        level: level ?? SentryLevel.info,
        timestamp: DateTime.now(),
        data: data,
      ),
    );
  }

  /// Capture a message (non-exception) to Sentry
  static Future<void> captureMessage(
    String message, {
    SentryLevel? level,
    Map<String, String>? tags,
  }) async {
    if (kDebugMode) {
      appLogger.debug('Debug mode: Not sending message to Sentry: $message');
      return;
    }

    await Sentry.captureMessage(
      message,
      level: level ?? SentryLevel.info,
      withScope: (scope) {
        if (tags != null) {
          tags.forEach((key, value) {
            scope.setTag(key, value);
          });
        }
      },
    );
  }

  /// Report error to crash analytics service
  static void _reportToCrashlytics(dynamic error, StackTrace? stackTrace) {
    // Don't report in debug mode
    if (kDebugMode) {
      appLogger.debug('Debug mode: Not reporting error to Sentry');
      return;
    }

    // Report to Sentry
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        // Add additional context while respecting privacy
        scope.setLevel(SentryLevel.error);

        // Add error context without PII
        scope.setContexts('error_context', {
          'timestamp': DateTime.now().toIso8601String(),
          'platform': Theme.platform.name,
          'app_state': 'active',
          ...getSafeContext(), // Include safe context
        });

        // Add breadcrumb for better debugging
        scope.addBreadcrumb(
          Breadcrumb(
            message: 'Error captured',
            category: 'error',
            level: SentryLevel.error,
            timestamp: DateTime.now(),
            data: {
              'error_type': error.runtimeType.toString(),
            },
          ),
        );
      },
    );

    appLogger.info('Error reported to Sentry: ${error.runtimeType}');
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

      // Report to Sentry with context
      if (!kDebugMode && context != null) {
        await Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (scope) {
            scope.setTag('operation_context', context);
            scope.setLevel(SentryLevel.warning);
          },
        );
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
