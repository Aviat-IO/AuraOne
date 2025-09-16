import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../utils/error_handler.dart';

/// Debug screen for testing crash reporting
/// Only available in debug mode
class CrashTestScreen extends StatelessWidget {
  const CrashTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      // This screen should not be accessible in production
      return const Scaffold(
        body: Center(
          child: Text('This screen is only available in debug mode'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Reporting Test'),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.orange.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Debug Mode Only',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This screen is for testing crash reporting. '
                        'In debug mode, errors are logged but not sent to Sentry. '
                        'To test actual Sentry reporting, run in release mode with a configured DSN.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Test Handled Exception
              _TestSection(
                title: 'Handled Exceptions',
                description: 'These errors are caught and reported without crashing the app',
                children: [
                  _TestButton(
                    label: 'Test Handled Exception',
                    color: Colors.blue,
                    onPressed: () {
                      try {
                        throw Exception('This is a test handled exception');
                      } catch (e, stack) {
                        ErrorHandler.handleError(e, stack);
                        _showSnackBar(context, 'Handled exception reported');
                      }
                    },
                  ),
                  _TestButton(
                    label: 'Test with Context',
                    color: Colors.green,
                    onPressed: () async {
                      // Add some context
                      ErrorHandler.setSafeContext('test_action', 'button_press');
                      ErrorHandler.setSafeContext('test_screen', 'crash_test');

                      await ErrorHandler.runWithErrorHandling(
                        () async {
                          throw Exception('Test exception with context');
                        },
                        context: 'Testing error with context',
                      );

                      _showSnackBar(context, 'Error with context reported');

                      // Clear test context
                      ErrorHandler.clearSafeContext();
                    },
                  ),
                ],
              ),

              // Test Messages
              _TestSection(
                title: 'Sentry Messages',
                description: 'Send non-exception messages to Sentry',
                children: [
                  _TestButton(
                    label: 'Send Info Message',
                    color: Colors.teal,
                    onPressed: () async {
                      await ErrorHandler.captureMessage(
                        'Test info message from crash test screen',
                        level: SentryLevel.info,
                        tags: {'source': 'crash_test', 'type': 'manual_test'},
                      );
                      _showSnackBar(context, 'Info message sent');
                    },
                  ),
                  _TestButton(
                    label: 'Send Warning Message',
                    color: Colors.orange,
                    onPressed: () async {
                      await ErrorHandler.captureMessage(
                        'Test warning message - something might be wrong',
                        level: SentryLevel.warning,
                        tags: {'source': 'crash_test', 'severity': 'medium'},
                      );
                      _showSnackBar(context, 'Warning message sent');
                    },
                  ),
                ],
              ),

              // Test Breadcrumbs
              _TestSection(
                title: 'Breadcrumbs',
                description: 'Add breadcrumbs for better error context',
                children: [
                  _TestButton(
                    label: 'Add Navigation Breadcrumb',
                    color: Colors.purple,
                    onPressed: () {
                      ErrorHandler.logBreadcrumb(
                        message: 'Navigated to crash test screen',
                        category: 'navigation',
                        level: SentryLevel.info,
                        data: {'screen': 'crash_test', 'action': 'button_press'},
                      );
                      _showSnackBar(context, 'Navigation breadcrumb added');
                    },
                  ),
                  _TestButton(
                    label: 'Add User Action Breadcrumb',
                    color: Colors.indigo,
                    onPressed: () {
                      ErrorHandler.logBreadcrumb(
                        message: 'User performed test action',
                        category: 'user_action',
                        level: SentryLevel.debug,
                        data: {'button': 'test_breadcrumb', 'timestamp': DateTime.now().toIso8601String()},
                      );
                      _showSnackBar(context, 'User action breadcrumb added');
                    },
                  ),
                ],
              ),

              // Test Unhandled Exceptions (Dangerous!)
              _TestSection(
                title: 'Unhandled Exceptions (Dangerous!)',
                description: 'These will crash the app in release mode',
                children: [
                  _TestButton(
                    label: 'Throw Unhandled Exception',
                    color: Colors.red,
                    onPressed: () {
                      // This will be caught by the zone error handler
                      Future.delayed(Duration.zero, () {
                        throw Exception('Unhandled async exception test');
                      });
                      _showSnackBar(context, 'Async exception thrown');
                    },
                  ),
                  _TestButton(
                    label: 'Null Reference Error',
                    color: Colors.red.shade700,
                    onPressed: () {
                      try {
                        // Intentionally cause a null reference
                        String? nullString;
                        // ignore: unnecessary_null_comparison
                        if (nullString == null) {
                          throw StateError('Null reference test error');
                        }
                      } catch (e, stack) {
                        ErrorHandler.handleError(e, stack);
                        _showSnackBar(context, 'Null reference error reported');
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Info card
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Testing in Release Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'To test actual Sentry reporting:\n'
                        '1. Configure your Sentry DSN in lib/config/sentry_config.dart\n'
                        '2. Build in release mode: flutter build apk --release\n'
                        '3. Install and test the release build\n'
                        '4. Check your Sentry dashboard for reported errors',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _TestSection extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;

  const _TestSection({
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: child,
            )),
          ],
        ),
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _TestButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }
}