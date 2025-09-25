import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../database/journal_database.dart';
import '../../database/media_database.dart';
import '../../database/location_database.dart';

// Global singleton instances for databases - shared across the app
// Journal singleton is also used by journal_service.dart
JournalDatabase? globalJournalDbInstance;
MediaDatabase? globalMediaDbInstance;
LocationDatabase? globalLocationDbInstance;

/// Singleton database provider to prevent multiple database instances
class DatabaseProvider {
  static DatabaseProvider? _instance;
  static DatabaseProvider get instance => _instance ??= DatabaseProvider._();

  DatabaseProvider._();

  JournalDatabase? _journalDb;
  MediaDatabase? _mediaDb;
  LocationDatabase? _locationDb;

  final _initializationCompleter = Completer<void>();
  bool _isInitialized = false;

  /// Initialize all databases (call once at app startup)
  Future<void> initialize() async {
    if (_isInitialized) {
      await _initializationCompleter.future;
      return;
    }

    try {
      // Use global singleton instances to avoid multiple database warnings
      globalJournalDbInstance ??= JournalDatabase();
      globalMediaDbInstance ??= MediaDatabase();
      globalLocationDbInstance ??= LocationDatabase();

      _journalDb = globalJournalDbInstance;
      _mediaDb = globalMediaDbInstance;
      _locationDb = globalLocationDbInstance;

      _isInitialized = true;
      _initializationCompleter.complete();

      debugPrint('DatabaseProvider: All databases initialized');
    } catch (e) {
      _initializationCompleter.completeError(e);
      rethrow;
    }
  }

  /// Get the journal database instance
  Future<JournalDatabase> get journalDatabase async {
    if (!_isInitialized) {
      await initialize();
    }
    return _journalDb!;
  }

  /// Get the media database instance
  Future<MediaDatabase> get mediaDatabase async {
    if (!_isInitialized) {
      await initialize();
    }
    return _mediaDb!;
  }

  /// Get the location database instance
  Future<LocationDatabase> get locationDatabase async {
    if (!_isInitialized) {
      await initialize();
    }
    return _locationDb!;
  }

  /// Close all databases (call at app shutdown)
  Future<void> dispose() async {
    if (!_isInitialized) return;

    await _journalDb?.close();
    await _mediaDb?.close();
    await _locationDb?.close();

    _journalDb = null;
    _mediaDb = null;
    _locationDb = null;
    _isInitialized = false;

    debugPrint('DatabaseProvider: All databases closed');
  }

  /// Check if databases are initialized
  bool get isInitialized => _isInitialized;
}