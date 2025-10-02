import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../../utils/logger.dart';

/// Device capability information
class DeviceCapabilities {
  final int androidApiLevel;
  final String deviceModel;
  final String manufacturer;
  final bool hasAICore;
  final bool isHighEndDevice;

  DeviceCapabilities({
    required this.androidApiLevel,
    required this.deviceModel,
    required this.manufacturer,
    required this.hasAICore,
    required this.isHighEndDevice,
  });

  @override
  String toString() {
    return 'DeviceCapabilities(API: $androidApiLevel, Model: $deviceModel, Manufacturer: $manufacturer, AICore: $hasAICore, HighEnd: $isHighEndDevice)';
  }
}

/// Maps device capabilities to adapter tier availability
class CapabilityMatrix {
  static final _logger = AppLogger('CapabilityMatrix');
  static final CapabilityMatrix _instance = CapabilityMatrix._internal();

  DeviceCapabilities? _cachedCapabilities;

  factory CapabilityMatrix() => _instance;
  CapabilityMatrix._internal();

  /// Get current device capabilities
  Future<DeviceCapabilities> getDeviceCapabilities() async {
    if (_cachedCapabilities != null) {
      return _cachedCapabilities!;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        // Check if device has AICore support (Pixel 8+, Galaxy S24+, etc.)
        final hasAICore = await _checkAICoreAvailability(androidInfo);

        // Determine if high-end device based on model
        final isHighEnd = _isHighEndDevice(androidInfo.model, androidInfo.manufacturer);

        _cachedCapabilities = DeviceCapabilities(
          androidApiLevel: androidInfo.version.sdkInt,
          deviceModel: androidInfo.model,
          manufacturer: androidInfo.manufacturer,
          hasAICore: hasAICore,
          isHighEndDevice: isHighEnd,
        );
      } else {
        // Non-Android platforms - provide fallback capabilities
        _cachedCapabilities = DeviceCapabilities(
          androidApiLevel: 0,
          deviceModel: 'Unknown',
          manufacturer: 'Unknown',
          hasAICore: false,
          isHighEndDevice: false,
        );
      }

      _logger.info('Device capabilities: $_cachedCapabilities');
      return _cachedCapabilities!;
    } catch (e, stackTrace) {
      _logger.error('Error getting device capabilities', error: e, stackTrace: stackTrace);

      // Return conservative fallback
      _cachedCapabilities = DeviceCapabilities(
        androidApiLevel: 21, // Minimum supported
        deviceModel: 'Unknown',
        manufacturer: 'Unknown',
        hasAICore: false,
        isHighEndDevice: false,
      );

      return _cachedCapabilities!;
    }
  }

  /// Check if Tier 1 (ML Kit GenAI) is available
  Future<bool> canUseTier1() async {
    final capabilities = await getDeviceCapabilities();

    // Requirements: Android 26+, AICore support, high-end device
    final result = capabilities.androidApiLevel >= 26 &&
        capabilities.hasAICore &&
        capabilities.isHighEndDevice;

    _logger.debug('Tier 1 availability: $result (API: ${capabilities.androidApiLevel}, AICore: ${capabilities.hasAICore}, HighEnd: ${capabilities.isHighEndDevice})');
    return result;
  }

  /// Check if Tier 2 (Hybrid ML Kit) is available
  Future<bool> canUseTier2() async {
    final capabilities = await getDeviceCapabilities();

    // Requirements: Android 21+
    final result = capabilities.androidApiLevel >= 21;

    _logger.debug('Tier 2 availability: $result (API: ${capabilities.androidApiLevel})');
    return result;
  }

  /// Check if Tier 3 (Templates) is available
  Future<bool> canUseTier3() async {
    // Always available as guaranteed fallback
    return true;
  }

  /// Check if Tier 4 (Cloud) is available
  Future<bool> canUseTier4() async {
    // Always available but requires user consent and network
    // Actual availability check happens in the adapter
    return true;
  }

  /// Check AICore availability (platform-specific)
  Future<bool> _checkAICoreAvailability(AndroidDeviceInfo androidInfo) async {
    try {
      // Known devices with AICore support
      final aiCoreDevices = {
        'Pixel 8',
        'Pixel 8 Pro',
        'Pixel 8a',
        'Pixel 9',
        'Pixel 9 Pro',
        'Pixel 9 Pro XL',
        'SM-S921', // Galaxy S24
        'SM-S926', // Galaxy S24+
        'SM-S928', // Galaxy S24 Ultra
      };

      final model = androidInfo.model.toUpperCase();
      final hasKnownDevice = aiCoreDevices.any((device) => model.contains(device.toUpperCase()));

      if (hasKnownDevice) {
        _logger.debug('AICore likely available: known device $model');
        return true;
      }

      // TODO: Add actual AICore detection via platform channel if needed
      // For now, use conservative device-based detection

      return false;
    } catch (e, stackTrace) {
      _logger.error('Error checking AICore availability', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Determine if device is high-end based on model/manufacturer
  bool _isHighEndDevice(String model, String manufacturer) {
    final modelUpper = model.toUpperCase();
    final mfgUpper = manufacturer.toUpperCase();

    // Google Pixel 6+
    if (mfgUpper.contains('GOOGLE')) {
      final pixelMatch = RegExp(r'PIXEL\s*(\d+)').firstMatch(modelUpper);
      if (pixelMatch != null) {
        final version = int.tryParse(pixelMatch.group(1) ?? '0') ?? 0;
        return version >= 6;
      }
    }

    // Samsung flagship devices (S series, Z series)
    if (mfgUpper.contains('SAMSUNG')) {
      return modelUpper.contains('SM-S9') || // S20-S24 series
          modelUpper.contains('SM-F9') || // Z Fold series
          modelUpper.contains('SM-Z'); // Z Flip series
    }

    // OnePlus flagship (9+)
    if (mfgUpper.contains('ONEPLUS')) {
      final onePlusMatch = RegExp(r'(\d+)').firstMatch(modelUpper);
      if (onePlusMatch != null) {
        final version = int.tryParse(onePlusMatch.group(1) ?? '0') ?? 0;
        return version >= 9;
      }
    }

    // Xiaomi flagship (Mi 11+, 12+, 13+, 14+)
    if (mfgUpper.contains('XIAOMI')) {
      return modelUpper.contains('MI 1') ||
          modelUpper.contains('MI 2') ||
          modelUpper.contains('REDMI K');
    }

    // Conservative: not recognized as high-end
    return false;
  }

  /// Clear cached capabilities (for testing)
  void clearCache() {
    _cachedCapabilities = null;
  }
}
