import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';

/// Service for generating and storing a persistent device identifier
///
/// The device ID is used for:
/// - Rate limiting AI requests on the backend proxy
/// - Anonymous user tracking without PII
/// - Quota management across app restarts
///
/// Privacy guarantees:
/// - Device ID persists across app updates but not reinstalls
/// - Stored securely using FlutterSecureStorage
/// - No personally identifiable information
/// - Generated locally, never sent to third parties except our proxy
class DeviceIdService {
  static final _logger = AppLogger('DeviceIdService');
  static const String _deviceIdKey = 'aura_device_id';

  final FlutterSecureStorage _secureStorage;
  String? _cachedDeviceId;

  DeviceIdService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Get or generate the persistent device ID
  ///
  /// Returns the existing device ID if found, otherwise generates a new one.
  /// The ID is cached in memory for the lifetime of the app instance.
  Future<String> getDeviceId() async {
    // Return cached ID if available
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      // Try to read existing ID from secure storage
      final existingId = await _secureStorage.read(key: _deviceIdKey);

      if (existingId != null && existingId.isNotEmpty) {
        _logger.info('Retrieved existing device ID');
        _cachedDeviceId = existingId;
        return existingId;
      }

      // Generate new ID if none exists
      final newId = _generateDeviceId();
      await _secureStorage.write(key: _deviceIdKey, value: newId);

      _logger.info('Generated new device ID');
      _cachedDeviceId = newId;
      return newId;
    } catch (e, stackTrace) {
      _logger.error('Error managing device ID', error: e, stackTrace: stackTrace);

      // Fallback to in-memory ID if secure storage fails
      if (_cachedDeviceId != null) {
        return _cachedDeviceId!;
      }

      _cachedDeviceId = _generateDeviceId();
      _logger.warning('Using in-memory device ID due to storage error');
      return _cachedDeviceId!;
    }
  }

  /// Generate a new UUID-like device identifier
  ///
  /// Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx (UUID v4 compatible)
  /// where x is a random hexadecimal digit and y is one of 8, 9, A, or B
  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // Set version to 4 (random UUID)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hexString = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hexString.substring(0, 8)}-'
        '${hexString.substring(8, 12)}-'
        '${hexString.substring(12, 16)}-'
        '${hexString.substring(16, 20)}-'
        '${hexString.substring(20, 32)}';
  }

  /// Clear the device ID (for testing or user-initiated reset)
  ///
  /// This will cause a new ID to be generated on next access.
  /// Use with caution as this will reset quota tracking.
  Future<void> clearDeviceId() async {
    try {
      await _secureStorage.delete(key: _deviceIdKey);
      _cachedDeviceId = null;
      _logger.info('Cleared device ID');
    } catch (e, stackTrace) {
      _logger.error('Error clearing device ID', error: e, stackTrace: stackTrace);
    }
  }

  /// Check if a device ID currently exists
  Future<bool> hasDeviceId() async {
    if (_cachedDeviceId != null) {
      return true;
    }

    try {
      final existingId = await _secureStorage.read(key: _deviceIdKey);
      return existingId != null && existingId.isNotEmpty;
    } catch (e) {
      _logger.warning('Error checking device ID existence: $e');
      return false;
    }
  }
}
