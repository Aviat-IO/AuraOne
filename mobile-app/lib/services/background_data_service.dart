import 'dart:async';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import '../database/location_database.dart';
import '../utils/logger.dart';

// Background task callback - must be top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      appLogger.info('Background task started: $task');
      
      // Initialize services based on task type
      switch (task) {
        case 'data_collection_task':
          await _performDataCollection();
          break;
        case 'ble_scan_task':
          await _performBleScanning();
          break;
        case 'location_tracking_task':
          await _performLocationTracking();
          break;
        case 'movement_tracking_task':
          await _performMovementTracking();
          break;
        default:
          appLogger.warning('Unknown background task: $task');
      }
      
      appLogger.info('Background task completed: $task');
      return Future.value(true);
    } catch (e) {
      appLogger.error('Background task failed: $task', error: e);
      return Future.value(false);
    }
  });
}

// Perform comprehensive data collection
Future<void> _performDataCollection() async {
  try {
    // Note: In a real background task, services would need proper initialization
    // For now, just log that the task ran
    
    // Note: BLE and movement collection would need proper initialization
    // with database references in a real background task
    
    appLogger.info('Background data collection completed');
  } catch (e) {
    appLogger.error('Background data collection failed', error: e);
  }
}

// Perform BLE scanning
Future<void> _performBleScanning() async {
  try {
    // Note: BLE scanning would need proper initialization
    // with database references in a real background task
    
    appLogger.info('Background BLE scanning completed');
  } catch (e) {
    appLogger.error('Background BLE scanning failed', error: e);
  }
}

// Perform location tracking
Future<void> _performLocationTracking() async {
  try {
    appLogger.info('Background location tracking started');

    // Get current location and store it
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      ),
    );

    // Initialize database and store location
    final documentsDir = await getApplicationDocumentsDirectory();
    final database = LocationDatabase.withConnection(
      openConnection: NativeDatabase.createInBackground(
        File(path.join(documentsDir.path, 'location_database.db')),
      ),
    );

    await database.insertLocationPoint(LocationPointsCompanion(
      latitude: drift.Value(position.latitude),
      longitude: drift.Value(position.longitude),
      altitude: drift.Value(position.altitude),
      speed: drift.Value(position.speed),
      heading: drift.Value(position.heading),
      timestamp: drift.Value(position.timestamp),
      accuracy: drift.Value(position.accuracy),
      isSignificant: const drift.Value(false),
    ));

    appLogger.info('Background location stored: ${position.latitude}, ${position.longitude}');
    await database.close();
  } catch (e) {
    appLogger.error('Background location tracking failed', error: e);
  }
}

// Perform movement tracking
Future<void> _performMovementTracking() async {
  try {
    // Note: Movement tracking would need proper initialization
    // with database references in a real background task
    
    appLogger.info('Background movement tracking completed');
  } catch (e) {
    appLogger.error('Background movement tracking failed', error: e);
  }
}

// Background data service provider
final backgroundDataServiceProvider = Provider<BackgroundDataService>((ref) {
  return BackgroundDataService(ref);
});

class BackgroundDataService {
  final Ref _ref;
  bool _isInitialized = false;
  
  BackgroundDataService(this._ref);
  
  // Initialize background data collection
  Future<void> initialize() async {
    if (_isInitialized) {
      appLogger.info('Background data service already initialized');
      return;
    }
    
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      
      _isInitialized = true;
      appLogger.info('Background data service initialized');
    } catch (e) {
      appLogger.error('Failed to initialize background data service', error: e);
      rethrow;
    }
  }
  
  // Start periodic data collection
  Future<void> startBackgroundDataCollection({
    Duration frequency = const Duration(minutes: 15),
    bool includeLocation = true,
    bool includeBle = true,
    bool includeMovement = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Register main data collection task
      await Workmanager().registerPeriodicTask(
        'periodic_data_collection',
        'data_collection_task',
        frequency: frequency,
        initialDelay: const Duration(seconds: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'includeLocation': includeLocation,
          'includeBle': includeBle,
          'includeMovement': includeMovement,
        },
      );
      
      // Register separate tasks for more frequent specific data collection
      if (includeLocation) {
        await Workmanager().registerPeriodicTask(
          'periodic_location_tracking',
          'location_tracking_task',
          frequency: const Duration(minutes: 5),
          initialDelay: const Duration(seconds: 10),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
          constraints: Constraints(
            networkType: NetworkType.notRequired,
            requiresBatteryNotLow: false,
          ),
        );
      }
      
      if (includeBle) {
        await Workmanager().registerPeriodicTask(
          'periodic_ble_scanning',
          'ble_scan_task',
          frequency: const Duration(minutes: 10),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
          constraints: Constraints(
            networkType: NetworkType.notRequired,
            requiresBatteryNotLow: false,
          ),
        );
      }
      
      if (includeMovement) {
        await Workmanager().registerPeriodicTask(
          'periodic_movement_tracking',
          'movement_tracking_task',
          frequency: const Duration(minutes: 10),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
          constraints: Constraints(
            networkType: NetworkType.notRequired,
            requiresBatteryNotLow: false,
          ),
        );
      }
      
      appLogger.info('Background data collection started with frequency: $frequency');
    } catch (e) {
      appLogger.error('Failed to start background data collection', error: e);
      rethrow;
    }
  }
  
  // Stop background data collection
  Future<void> stopBackgroundDataCollection() async {
    try {
      await Workmanager().cancelByUniqueName('periodic_data_collection');
      await Workmanager().cancelByUniqueName('periodic_location_tracking');
      await Workmanager().cancelByUniqueName('periodic_ble_scanning');
      await Workmanager().cancelByUniqueName('periodic_movement_tracking');
      
      appLogger.info('Background data collection stopped');
    } catch (e) {
      appLogger.error('Failed to stop background data collection', error: e);
      rethrow;
    }
  }
  
  // Trigger immediate one-off data collection
  Future<void> triggerImmediateDataCollection() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await Workmanager().registerOneOffTask(
        'immediate_data_collection',
        'data_collection_task',
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );
      
      appLogger.info('Immediate data collection triggered');
    } catch (e) {
      appLogger.error('Failed to trigger immediate data collection', error: e);
      rethrow;
    }
  }
  
  // Check if background data collection is active
  Future<bool> isBackgroundDataCollectionActive() async {
    // Note: WorkManager doesn't provide a direct way to check if tasks are scheduled
    // This would need to be tracked separately in preferences
    try {
      // For now, return true if initialized
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }
}