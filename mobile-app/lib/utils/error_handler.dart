import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logger.dart';

/// Global error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();
  
  /// Initialize global error handling
  static void initialize() {
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
  
  /// Report error to crash analytics service
  static void _reportToCrashlytics(dynamic error, StackTrace? stackTrace) {
    // TODO: Integrate with crash reporting service like Sentry or Firebase Crashlytics
    // For now, just log that we would report it
    if (!kDebugMode) {
      appLogger.info('Would report to crash analytics: $error');
    }
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