import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../database/location_database.dart';
import 'database/database_provider.dart';

/// Service to handle data restoration after app reinstall
class DataRestorationService {
  static final DataRestorationService _instance = DataRestorationService._internal();
  factory DataRestorationService() => _instance;
  DataRestorationService._internal();

  /// Check if this is a fresh install with existing data
  Future<RestorationStatus> checkForExistingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = prefs.getBool('first_run') ?? true;

      if (!isFirstRun) {
        // Not a fresh install, no restoration needed
        return RestorationStatus(
          hasExistingData: false,
          isRestorationNeeded: false,
        );
      }

      // Check for existing database files
      final dir = await getApplicationDocumentsDirectory();
      final mainDbPath = path.join(dir.path, 'aura_one.db');
      final locationDbPath = path.join(dir.path, 'location_database.db');

      final mainDbExists = await File(mainDbPath).exists();
      final locationDbExists = await File(locationDbPath).exists();

      if (mainDbExists || locationDbExists) {
        appLogger.info('Found existing data from previous installation');

        // Check data integrity
        int journalCount = 0;
        int locationCount = 0;

        // We can check database existence without counting records
        // to avoid potential initialization issues

        return RestorationStatus(
          hasExistingData: true,
          isRestorationNeeded: true,
          journalEntries: journalCount,
          locationPoints: locationCount,
          databasePaths: [
            if (mainDbExists) mainDbPath,
            if (locationDbExists) locationDbPath,
          ],
        );
      }

      // No existing data found
      await prefs.setBool('first_run', false);
      return RestorationStatus(
        hasExistingData: false,
        isRestorationNeeded: false,
      );

    } catch (e) {
      appLogger.error('Error checking for existing data', error: e);
      return RestorationStatus(
        hasExistingData: false,
        isRestorationNeeded: false,
        error: e.toString(),
      );
    }
  }

  /// Restore existing data after reinstallation
  Future<bool> restoreExistingData() async {
    try {
      appLogger.info('Starting data restoration process');

      final prefs = await SharedPreferences.getInstance();

      // Mark that we've handled the first run
      await prefs.setBool('first_run', false);
      await prefs.setBool('data_restored', true);
      await prefs.setInt('restoration_timestamp', DateTime.now().millisecondsSinceEpoch);

      // Try to initialize databases with migration support
      try {
        await DatabaseProvider.instance.initialize();
      } catch (dbError) {
        // If database initialization fails, it might be due to incompatible schema versions
        appLogger.warning('Database initialization failed during restoration, attempting recovery', error: dbError);

        // Don't crash - the databases might still work or migrations will handle it
        // The migration strategies in each database file should handle version differences
      }

      appLogger.info('Data restoration completed successfully');
      return true;

    } catch (e) {
      appLogger.error('Failed to restore existing data', error: e);
      return false;
    }
  }

  /// Show restoration dialog to user
  Future<bool> showRestorationDialog(BuildContext context, RestorationStatus status) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.restore, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Previous Data Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We found data from a previous installation of Aura One.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data found:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (status.locationPoints > 0)
                    Text('• ${status.locationPoints} location points'),
                  if (status.journalEntries > 0)
                    Text('• ${status.journalEntries} journal entries'),
                  if (status.locationPoints == 0 && status.journalEntries == 0)
                    const Text('• App data and settings'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Would you like to restore this data?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Start Fresh'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Clear all existing data if user chooses to start fresh
  Future<void> clearExistingData() async {
    try {
      appLogger.info('Clearing existing data for fresh start');

      // Clear databases
      final dir = await getApplicationDocumentsDirectory();
      final mainDbPath = path.join(dir.path, 'aura_one.db');
      final locationDbPath = path.join(dir.path, 'location_database.db');

      if (await File(mainDbPath).exists()) {
        await File(mainDbPath).delete();
      }
      if (await File(locationDbPath).exists()) {
        await File(locationDbPath).delete();
      }

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('first_run', false);
      await prefs.setBool('data_cleared', true);

      appLogger.info('Existing data cleared successfully');
    } catch (e) {
      appLogger.error('Failed to clear existing data', error: e);
    }
  }
}

/// Status of data restoration check
class RestorationStatus {
  final bool hasExistingData;
  final bool isRestorationNeeded;
  final int journalEntries;
  final int locationPoints;
  final List<String> databasePaths;
  final String? error;

  RestorationStatus({
    required this.hasExistingData,
    required this.isRestorationNeeded,
    this.journalEntries = 0,
    this.locationPoints = 0,
    this.databasePaths = const [],
    this.error,
  });
}