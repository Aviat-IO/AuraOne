/// Sentry configuration for crash reporting
///
/// To enable Sentry crash reporting in production:
/// 1. Create a project at https://sentry.io
/// 2. Get your DSN from Project Settings > Client Keys (DSN)
/// 3. Replace the placeholder DSN below
/// 4. Update the release version when deploying

class SentryConfig {
  /// Sentry DSN (Data Source Name)
  /// Format: https://[key]@[organization].ingest.sentry.io/[project]
  ///
  /// IMPORTANT: Replace with your actual DSN before deploying to production
  /// Leave empty to disable Sentry (useful for development)
  static const String dsn = '';

  /// Example DSN (DO NOT USE IN PRODUCTION):
  /// static const String dsn = 'https://examplekey123@o123456.ingest.sentry.io/1234567';

  /// Release version - update this with each release
  /// Format: app-name@version+build
  static const String release = 'aura-one@1.0.0+1';

  /// Sample rates for production (0.0 to 1.0)
  static const double productionTracesSampleRate = 0.1; // 10% of transactions
  static const double productionProfilesSampleRate = 0.1; // 10% of profiles

  /// Sample rates for development (typically higher for testing)
  static const double debugTracesSampleRate = 1.0; // 100% in debug
  static const double debugProfilesSampleRate = 1.0; // 100% in debug

  /// Environment names
  static const String developmentEnvironment = 'development';
  static const String stagingEnvironment = 'staging';
  static const String productionEnvironment = 'production';

  /// Privacy settings
  static const bool sendDefaultPii = false; // Never send PII
  static const bool attachScreenshot = false; // Don't attach screenshots
  static const bool attachViewHierarchy = false; // Don't attach view hierarchy

  /// Breadcrumb settings
  static const int maxBreadcrumbs = 100;
  static const bool enableAutoNativeBreadcrumbs = true;

  /// Session tracking
  static const bool enableAutoSessionTracking = true;
  static const Duration autoSessionTrackingInterval = Duration(seconds: 30);
}