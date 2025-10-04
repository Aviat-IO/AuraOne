/// Backend service configuration
///
/// Provides backend URL based on build environment (dev, staging, prod)
class BackendConfig {
  static const String _devBackendUrl = 'https://aura-one-backend-74noubq3fa-uc.a.run.app';
  static const String _stagingBackendUrl = 'https://aura-one-backend-staging-url'; // TODO: Update when staging deployed
  static const String _prodBackendUrl = 'https://aura-one-backend-prod-url'; // TODO: Update when prod deployed

  /// Get backend URL based on current environment
  static String get backendUrl {
    // TODO: Add proper environment detection (e.g., from build flavor or env variable)
    // For now, always use dev
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

    switch (environment) {
      case 'prod':
        return _prodBackendUrl;
      case 'staging':
        return _stagingBackendUrl;
      case 'dev':
      default:
        return _devBackendUrl;
    }
  }

  /// Health check endpoint
  static String get healthUrl => '$backendUrl/health';

  /// AI generation endpoint
  static String get generateSummaryUrl => '$backendUrl/api/generate-summary';

  /// Usage stats endpoint (requires device ID in path)
  static String usageUrl(String deviceId) => '$backendUrl/api/usage/$deviceId';

  /// Receipt validation endpoint
  static String get validateReceiptUrl => '$backendUrl/api/validate-receipt';
}
