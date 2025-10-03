import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/logger.dart';

/// Optimized database service that performs operations in background
class OptimizedDatabaseService {
  static final OptimizedDatabaseService _instance = OptimizedDatabaseService._internal();
  factory OptimizedDatabaseService() => _instance;
  OptimizedDatabaseService._internal();

  Database? _database;
  final _operationQueue = <DatabaseOperation>[];
  Timer? _batchTimer;
  bool _isProcessing = false;

  /// Initialize database with optimizations
  Future<void> initialize(String dbPath) async {
    try {
      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
      );

      appLogger.info('Optimized database initialized');
    } catch (e) {
      appLogger.error('Failed to initialize database', error: e);
      rethrow;
    }
  }

  /// Configure database for optimal performance
  Future<void> _onConfigure(Database db) async {
    // Enable WAL mode for better concurrency
    await db.execute('PRAGMA journal_mode = WAL');

    // Optimize for performance
    await db.execute('PRAGMA synchronous = NORMAL');
    await db.execute('PRAGMA cache_size = 10000');
    await db.execute('PRAGMA temp_store = MEMORY');

    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create tables in background to avoid blocking
    await compute(_createTablesInBackground, db.path);
  }

  /// Create tables in isolate
  static Future<void> _createTablesInBackground(String dbPath) async {
    // This runs in a separate isolate
    // Create your tables here
    // Example tables for the app
  }

  /// Perform a read operation with caching
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (_database == null) {
      throw StateError('Database not initialized');
    }

    // For large queries, use compute to run in background
    if (limit == null || limit > 100) {
      return await compute(
        _queryInBackground,
        QueryParams(
          dbPath: _database!.path,
          table: table,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        ),
      );
    }

    // Small queries can run on main thread
    return await _database!.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Perform query in background isolate
  static Future<List<Map<String, dynamic>>> _queryInBackground(
    QueryParams params,
  ) async {
    final db = await openDatabase(params.dbPath);
    try {
      return await db.query(
        params.table,
        where: params.where,
        whereArgs: params.whereArgs,
        orderBy: params.orderBy,
        limit: params.limit,
        offset: params.offset,
      );
    } finally {
      await db.close();
    }
  }

  /// Batch insert for better performance
  Future<void> batchInsert(
    String table,
    List<Map<String, dynamic>> data,
  ) async {
    if (_database == null) {
      throw StateError('Database not initialized');
    }

    if (data.isEmpty) return;

    // For large batches, process in background
    if (data.length > 50) {
      await compute(
        _batchInsertInBackground,
        BatchInsertParams(
          dbPath: _database!.path,
          table: table,
          data: data,
        ),
      );
    } else {
      // Small batches can use transaction on main thread
      await _database!.transaction((txn) async {
        final batch = txn.batch();
        for (final item in data) {
          batch.insert(table, item);
        }
        await batch.commit(noResult: true);
      });
    }
  }

  /// Batch insert in background isolate
  static Future<void> _batchInsertInBackground(
    BatchInsertParams params,
  ) async {
    final db = await openDatabase(params.dbPath);
    try {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final item in params.data) {
          batch.insert(params.table, item);
        }
        await batch.commit(noResult: true);
      });
    } finally {
      await db.close();
    }
  }

  /// Queue operations for batch processing
  void queueOperation(DatabaseOperation operation) {
    _operationQueue.add(operation);

    // Schedule batch processing
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 100), _processBatch);
  }

  /// Process queued operations in batch
  Future<void> _processBatch() async {
    if (_isProcessing || _operationQueue.isEmpty) return;

    _isProcessing = true;
    final operations = List<DatabaseOperation>.from(_operationQueue);
    _operationQueue.clear();

    try {
      await _database!.transaction((txn) async {
        for (final op in operations) {
          switch (op.type) {
            case OperationType.insert:
              await txn.insert(op.table, op.data!);
              break;
            case OperationType.update:
              await txn.update(
                op.table,
                op.data!,
                where: op.where,
                whereArgs: op.whereArgs,
              );
              break;
            case OperationType.delete:
              await txn.delete(
                op.table,
                where: op.where,
                whereArgs: op.whereArgs,
              );
              break;
          }
        }
      });
    } catch (e) {
      appLogger.error('Batch processing failed', error: e);
    } finally {
      _isProcessing = false;
    }
  }

  /// Close database connection
  Future<void> close() async {
    _batchTimer?.cancel();
    await _database?.close();
    _database = null;
  }
}

/// Parameters for background query
class QueryParams {
  final String dbPath;
  final String table;
  final String? where;
  final List<dynamic>? whereArgs;
  final String? orderBy;
  final int? limit;
  final int? offset;

  QueryParams({
    required this.dbPath,
    required this.table,
    this.where,
    this.whereArgs,
    this.orderBy,
    this.limit,
    this.offset,
  });
}

/// Parameters for batch insert
class BatchInsertParams {
  final String dbPath;
  final String table;
  final List<Map<String, dynamic>> data;

  BatchInsertParams({
    required this.dbPath,
    required this.table,
    required this.data,
  });
}

/// Database operation for queuing
class DatabaseOperation {
  final OperationType type;
  final String table;
  final Map<String, dynamic>? data;
  final String? where;
  final List<dynamic>? whereArgs;

  DatabaseOperation({
    required this.type,
    required this.table,
    this.data,
    this.where,
    this.whereArgs,
  });
}

/// Operation type enum
enum OperationType {
  insert,
  update,
  delete,
}