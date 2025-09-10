import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import '../database/media_database.dart';

/// BLE device data model
class BleDeviceData {
  final String id;
  final String name;
  final int rssi;
  final DateTime discoveredAt;
  final DateTime lastSeenAt;
  final Map<String, dynamic>? manufacturerData;
  final List<String> serviceUuids;
  final DeviceType deviceType;
  final double? estimatedDistance;
  
  BleDeviceData({
    required this.id,
    required this.name,
    required this.rssi,
    required this.discoveredAt,
    required this.lastSeenAt,
    this.manufacturerData,
    this.serviceUuids = const [],
    this.deviceType = DeviceType.unknown,
    this.estimatedDistance,
  });
  
  /// Calculate estimated distance from RSSI
  static double? calculateDistance(int rssi, {int measuredPower = -59}) {
    // Using path-loss formula: Distance = 10^((Measured Power - RSSI) / (10 * N))
    // Where N is the path-loss exponent (typically 2 for free space)
    if (rssi == 0) return null;
    
    const double pathLossExponent = 2.0;
    final double distance = 
        Math.pow(10, (measuredPower - rssi) / (10 * pathLossExponent)).toDouble();
    
    return distance;
  }
  
  BleDeviceData copyWith({
    String? name,
    int? rssi,
    DateTime? lastSeenAt,
    Map<String, dynamic>? manufacturerData,
    List<String>? serviceUuids,
    DeviceType? deviceType,
    double? estimatedDistance,
  }) {
    return BleDeviceData(
      id: id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      discoveredAt: discoveredAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      manufacturerData: manufacturerData ?? this.manufacturerData,
      serviceUuids: serviceUuids ?? this.serviceUuids,
      deviceType: deviceType ?? this.deviceType,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
    );
  }
}

/// Device type classification
enum DeviceType {
  phone,
  computer,
  wearable,
  beacon,
  headphones,
  speaker,
  tv,
  car,
  healthDevice,
  unknown,
}

/// Proximity zone classification
enum ProximityZone {
  immediate(0, 0.5),    // < 0.5 meters
  near(0.5, 2),         // 0.5 - 2 meters
  medium(2, 5),         // 2 - 5 meters
  far(5, 10),           // 5 - 10 meters
  distant(10, double.infinity); // > 10 meters
  
  final double minDistance;
  final double maxDistance;
  
  const ProximityZone(this.minDistance, this.maxDistance);
  
  static ProximityZone fromDistance(double distance) {
    for (final zone in ProximityZone.values) {
      if (distance >= zone.minDistance && distance < zone.maxDistance) {
        return zone;
      }
    }
    return ProximityZone.distant;
  }
}

/// Privacy settings for BLE scanning
class BlePrivacySettings {
  final bool scanEnabled;
  final bool storeDeviceNames;
  final bool storeManufacturerData;
  final int scanDurationSeconds;
  final int scanIntervalSeconds;
  final Set<String> allowedDeviceIds;
  final Set<String> blockedDeviceIds;
  final bool anonymizeDevices;
  
  const BlePrivacySettings({
    this.scanEnabled = false,
    this.storeDeviceNames = true,
    this.storeManufacturerData = false,
    this.scanDurationSeconds = 10,
    this.scanIntervalSeconds = 300, // 5 minutes
    this.allowedDeviceIds = const {},
    this.blockedDeviceIds = const {},
    this.anonymizeDevices = false,
  });
  
  BlePrivacySettings copyWith({
    bool? scanEnabled,
    bool? storeDeviceNames,
    bool? storeManufacturerData,
    int? scanDurationSeconds,
    int? scanIntervalSeconds,
    Set<String>? allowedDeviceIds,
    Set<String>? blockedDeviceIds,
    bool? anonymizeDevices,
  }) {
    return BlePrivacySettings(
      scanEnabled: scanEnabled ?? this.scanEnabled,
      storeDeviceNames: storeDeviceNames ?? this.storeDeviceNames,
      storeManufacturerData: storeManufacturerData ?? this.storeManufacturerData,
      scanDurationSeconds: scanDurationSeconds ?? this.scanDurationSeconds,
      scanIntervalSeconds: scanIntervalSeconds ?? this.scanIntervalSeconds,
      allowedDeviceIds: allowedDeviceIds ?? this.allowedDeviceIds,
      blockedDeviceIds: blockedDeviceIds ?? this.blockedDeviceIds,
      anonymizeDevices: anonymizeDevices ?? this.anonymizeDevices,
    );
  }
}

/// Service for BLE scanning and proximity detection
class BleScanningService {
  static final _logger = AppLogger('BleScanningService');
  static final _instance = BleScanningService._internal();
  
  factory BleScanningService() => _instance;
  BleScanningService._internal();
  
  BlePrivacySettings _privacySettings = const BlePrivacySettings();
  
  /// Current scan state
  bool _isScanning = false;
  Timer? _scanTimer;
  StreamSubscription? _scanSubscription;
  
  /// Discovered devices cache
  final Map<String, BleDeviceData> _devicesCache = {};
  final _devicesController = StreamController<List<BleDeviceData>>.broadcast();
  
  /// Stream of discovered devices
  Stream<List<BleDeviceData>> get devicesStream => _devicesController.stream;
  
  /// Get current privacy settings
  BlePrivacySettings get privacySettings => _privacySettings;
  
  /// Update privacy settings
  void updatePrivacySettings(BlePrivacySettings settings) {
    _privacySettings = settings;
    _logger.info('BLE privacy settings updated: scanEnabled=${settings.scanEnabled}');
    
    // Start or stop periodic scanning based on settings
    if (settings.scanEnabled) {
      _startPeriodicScanning();
    } else {
      _stopPeriodicScanning();
    }
  }
  
  /// Request Bluetooth permissions
  Future<bool> requestPermissions() async {
    try {
      _logger.info('Requesting Bluetooth permissions');
      
      // Platform-specific permission request
      if (Platform.isIOS) {
        // iOS requires Bluetooth permission
        final status = await Permission.bluetooth.request();
        
        if (status.isGranted) {
          _logger.info('iOS Bluetooth permissions granted');
          return true;
        } else if (status.isPermanentlyDenied) {
          _logger.warning('iOS Bluetooth permissions permanently denied');
          await openAppSettings();
        }
      } else if (Platform.isAndroid) {
        // Android requires multiple Bluetooth permissions (API 31+)
        if (Platform.version.contains('31') || 
            Platform.version.contains('32') || 
            Platform.version.contains('33') ||
            Platform.version.contains('34')) {
          // Android 12+ requires BLUETOOTH_SCAN, BLUETOOTH_ADVERTISE, BLUETOOTH_CONNECT
          final statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
            Permission.location,
          ].request();
          
          final allGranted = statuses.values.every((status) => status.isGranted);
          
          if (allGranted) {
            _logger.info('Android Bluetooth permissions granted');
            return true;
          } else {
            _logger.warning('Some Android Bluetooth permissions denied');
            return false;
          }
        } else {
          // Android 11 and below
          final statuses = await [
            Permission.bluetooth,
            Permission.location,
          ].request();
          
          final allGranted = statuses.values.every((status) => status.isGranted);
          
          if (allGranted) {
            _logger.info('Android Bluetooth permissions granted (legacy)');
            return true;
          }
        }
      }
      
      return false;
    } catch (e, stack) {
      _logger.error('Failed to request Bluetooth permissions', 
                   error: e, stackTrace: stack);
      return false;
    }
  }
  
  /// Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      final isAvailable = await FlutterBluePlus.isAvailable;
      final isOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      
      return isAvailable && isOn;
    } catch (e) {
      _logger.error('Failed to check Bluetooth availability', error: e);
      return false;
    }
  }
  
  /// Start a single BLE scan
  Future<void> startScan({Duration? timeout}) async {
    try {
      if (_isScanning) {
        _logger.info('Scan already in progress');
        return;
      }
      
      if (!await requestPermissions()) {
        _logger.warning('Bluetooth permissions not granted');
        return;
      }
      
      if (!await isBluetoothAvailable()) {
        _logger.warning('Bluetooth not available or disabled');
        return;
      }
      
      _logger.info('Starting BLE scan');
      _isScanning = true;
      
      // Configure scan settings
      timeout ??= Duration(seconds: _privacySettings.scanDurationSeconds);
      
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidScanMode: AndroidScanMode.balanced,
      );
      
      // Listen to scan results
      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        _processScanResults,
        onError: (error) {
          _logger.error('Scan error: $error');
        },
      );
      
      // Mark scan as stopped after timeout
      Future.delayed(timeout, () {
        _isScanning = false;
      });
      
    } catch (e, stack) {
      _logger.error('Failed to start BLE scan', error: e, stackTrace: stack);
      _isScanning = false;
    }
  }
  
  /// Stop BLE scanning
  Future<void> stopScan() async {
    try {
      _logger.info('Stopping BLE scan');
      
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _isScanning = false;
      
    } catch (e, stack) {
      _logger.error('Failed to stop BLE scan', error: e, stackTrace: stack);
    }
  }
  
  /// Process scan results
  void _processScanResults(List<ScanResult> results) {
    final now = DateTime.now();
    
    for (final result in results) {
      // Check privacy filters
      if (!_shouldIncludeDevice(result)) {
        continue;
      }
      
      // Calculate estimated distance
      final distance = BleDeviceData.calculateDistance(result.rssi);
      
      // Classify device type
      final deviceType = _classifyDeviceType(result);
      
      // Extract or update device data
      final deviceId = result.device.remoteId.toString();
      final existingDevice = _devicesCache[deviceId];
      
      final deviceData = existingDevice?.copyWith(
        name: _privacySettings.storeDeviceNames 
            ? (result.device.platformName.isNotEmpty 
                ? result.device.platformName 
                : 'Unknown Device')
            : 'Device',
        rssi: result.rssi,
        lastSeenAt: now,
        manufacturerData: _privacySettings.storeManufacturerData
            ? _convertManufacturerData(result.advertisementData.manufacturerData)
            : null,
        serviceUuids: result.advertisementData.serviceUuids
            .map((uuid) => uuid.toString())
            .toList(),
        deviceType: deviceType,
        estimatedDistance: distance,
      ) ?? BleDeviceData(
        id: deviceId,
        name: _privacySettings.storeDeviceNames 
            ? (result.device.platformName.isNotEmpty 
                ? result.device.platformName 
                : 'Unknown Device')
            : 'Device',
        rssi: result.rssi,
        discoveredAt: now,
        lastSeenAt: now,
        manufacturerData: _privacySettings.storeManufacturerData
            ? _convertManufacturerData(result.advertisementData.manufacturerData)
            : null,
        serviceUuids: result.advertisementData.serviceUuids
            .map((uuid) => uuid.toString())
            .toList(),
        deviceType: deviceType,
        estimatedDistance: distance,
      );
      
      // Update cache
      _devicesCache[deviceId] = deviceData;
      
      // Apply anonymization if needed
      if (_privacySettings.anonymizeDevices) {
        _devicesCache[deviceId] = deviceData.copyWith(
          name: 'Device ${deviceId.substring(0, 6)}',
        );
      }
    }
    
    // Emit updated devices list
    _emitDevices();
    
    // Clean up old devices (not seen in last 5 minutes)
    _cleanupOldDevices();
  }
  
  /// Check if device should be included based on privacy settings
  bool _shouldIncludeDevice(ScanResult result) {
    final deviceId = result.device.remoteId.toString();
    
    // Check blocked list
    if (_privacySettings.blockedDeviceIds.contains(deviceId)) {
      return false;
    }
    
    // Check allowed list (if not empty, only include allowed)
    if (_privacySettings.allowedDeviceIds.isNotEmpty &&
        !_privacySettings.allowedDeviceIds.contains(deviceId)) {
      return false;
    }
    
    return true;
  }
  
  /// Classify device type based on advertisement data
  DeviceType _classifyDeviceType(ScanResult result) {
    final name = result.device.platformName.toLowerCase();
    final serviceUuids = result.advertisementData.serviceUuids
        .map((uuid) => uuid.toString().toLowerCase())
        .toList();
    
    // Check by name patterns
    if (name.contains('phone') || name.contains('iphone') || name.contains('pixel')) {
      return DeviceType.phone;
    }
    if (name.contains('watch') || name.contains('band') || name.contains('fitbit')) {
      return DeviceType.wearable;
    }
    if (name.contains('airpods') || name.contains('buds') || name.contains('headphone')) {
      return DeviceType.headphones;
    }
    if (name.contains('speaker') || name.contains('echo') || name.contains('home')) {
      return DeviceType.speaker;
    }
    if (name.contains('tv') || name.contains('roku') || name.contains('chromecast')) {
      return DeviceType.tv;
    }
    if (name.contains('car') || name.contains('tesla') || name.contains('bmw')) {
      return DeviceType.car;
    }
    if (name.contains('mac') || name.contains('laptop') || name.contains('desktop')) {
      return DeviceType.computer;
    }
    
    // Check by service UUIDs (standard Bluetooth service UUIDs)
    for (final uuid in serviceUuids) {
      if (uuid.contains('180d') || uuid.contains('180a')) { // Heart rate or device info
        return DeviceType.healthDevice;
      }
      if (uuid.contains('110a') || uuid.contains('110b')) { // Audio
        return DeviceType.headphones;
      }
      if (uuid.contains('1812')) { // HID
        return DeviceType.computer;
      }
    }
    
    // Check for iBeacon
    if (result.advertisementData.manufacturerData.containsKey(0x004C)) { // Apple
      final data = result.advertisementData.manufacturerData[0x004C];
      if (data != null && data.length >= 2 && data[0] == 0x02 && data[1] == 0x15) {
        return DeviceType.beacon;
      }
    }
    
    return DeviceType.unknown;
  }
  
  /// Start periodic BLE scanning
  void _startPeriodicScanning() {
    _stopPeriodicScanning();
    
    if (!_privacySettings.scanEnabled) {
      return;
    }
    
    _logger.info('Starting periodic BLE scanning');
    
    // Start initial scan
    startScan();
    
    // Schedule periodic scans
    _scanTimer = Timer.periodic(
      Duration(seconds: _privacySettings.scanIntervalSeconds),
      (_) => startScan(),
    );
  }
  
  /// Stop periodic BLE scanning
  void _stopPeriodicScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
    stopScan();
  }
  
  /// Emit current devices list
  void _emitDevices() {
    final devices = _devicesCache.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi)); // Sort by signal strength
    
    _devicesController.add(devices);
  }
  
  /// Convert manufacturer data from Map<int, List<int>> to Map<String, dynamic>
  Map<String, dynamic>? _convertManufacturerData(Map<int, List<int>>? data) {
    if (data == null) return null;
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  
  /// Clean up devices not seen recently
  void _cleanupOldDevices() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    
    _devicesCache.removeWhere((id, device) => 
      device.lastSeenAt.isBefore(cutoff));
  }
  
  /// Get recent devices
  List<BleDeviceData> getRecentDevices({
    Duration recency = const Duration(minutes: 5),
  }) {
    final cutoff = DateTime.now().subtract(recency);
    return _devicesCache.values
        .where((device) => device.lastSeenAt.isAfter(cutoff))
        .toList();
  }
  
  /// Get devices in proximity zone
  List<BleDeviceData> getDevicesInZone(ProximityZone zone) {
    return _devicesCache.values.where((device) {
      if (device.estimatedDistance == null) return false;
      
      final deviceZone = ProximityZone.fromDistance(device.estimatedDistance!);
      return deviceZone == zone;
    }).toList();
  }
  
  /// Get nearby devices summary
  Map<String, dynamic> getProximitySummary() {
    final summary = <String, dynamic>{
      'totalDevices': _devicesCache.length,
      'zones': {},
      'deviceTypes': {},
    };
    
    // Count by proximity zone
    for (final zone in ProximityZone.values) {
      final devices = getDevicesInZone(zone);
      summary['zones'][zone.name] = devices.length;
    }
    
    // Count by device type
    for (final device in _devicesCache.values) {
      final typeName = device.deviceType.name;
      summary['deviceTypes'][typeName] = 
          (summary['deviceTypes'][typeName] ?? 0) + 1;
    }
    
    return summary;
  }
  
  /// Clear all cached devices
  void clearCache() {
    _devicesCache.clear();
    _emitDevices();
    _logger.info('BLE device cache cleared');
  }
  
  /// Dispose of resources
  void dispose() {
    _stopPeriodicScanning();
    _scanSubscription?.cancel();
    _devicesController.close();
  }
}

// Extension to add math functions
extension Math on num {
  static num pow(num x, num exponent) {
    if (exponent == 0) return 1;
    if (exponent == 1) return x;
    
    num result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= x;
    }
    return result;
  }
}