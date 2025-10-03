import 'dart:isolate';
import 'dart:async';
import 'package:photo_manager/photo_manager.dart';
import '../database/media_database.dart';
import '../utils/logger.dart';
import 'media_format_handler.dart';

/// Message types for isolate communication
enum IsolateMessageType {
  processAssets,
  processComplete,
  processError,
  progress,
  shutdown,
}

/// Message class for isolate communication
class IsolateMessage {
  final IsolateMessageType type;
  final dynamic data;
  final String? error;

  IsolateMessage({
    required this.type,
    this.data,
    this.error,
  });
}

/// Parameters for processing assets in isolate
class ProcessAssetsParams {
  final List<String> assetIds;
  final SendPort responsePort;
  final String databasePath;

  ProcessAssetsParams({
    required this.assetIds,
    required this.responsePort,
    required this.databasePath,
  });
}

/// Result of processing a single asset
class AssetProcessingResult {
  final String assetId;
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;

  AssetProcessingResult({
    required this.assetId,
    required this.success,
    this.error,
    this.metadata,
  });
}

/// Media processing isolate for background processing
class MediaProcessingIsolate {
  static final _logger = AppLogger('MediaProcessingIsolate');

  Isolate? _isolate;
  SendPort? _sendPort;
  final _receivePort = ReceivePort();
  final _completer = Completer<void>();
  StreamSubscription? _subscription;

  /// Progress callback
  void Function(int processed, int total)? onProgress;

  /// Error callback
  void Function(String error)? onError;

  /// Start the isolate
  Future<void> start() async {
    try {
      _logger.info('Starting media processing isolate');

      // Spawn the isolate
      _isolate = await Isolate.spawn(
        _isolateEntryPoint,
        _receivePort.sendPort,
        onError: _receivePort.sendPort,
      );

      // Listen for messages from isolate
      _subscription = _receivePort.listen(_handleMessage);

      // Wait for isolate to be ready
      await _completer.future;

      _logger.info('Media processing isolate started successfully');
    } catch (e, stack) {
      _logger.error('Failed to start isolate', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Process assets in background
  Future<List<AssetProcessingResult>> processAssets(
    List<String> assetIds,
    String databasePath,
  ) async {
    if (_sendPort == null) {
      throw StateError('Isolate not started');
    }

    final completer = Completer<List<AssetProcessingResult>>();
    final List<AssetProcessingResult> results = [];
    int expectedCount = assetIds.length;
    int processedCount = 0;

    // Create temporary listener for this batch
    StreamSubscription? batchSubscription;
    batchSubscription = _receivePort.listen((message) {
      if (message is IsolateMessage) {
        switch (message.type) {
          case IsolateMessageType.processComplete:
            results.add(message.data as AssetProcessingResult);
            processedCount++;

            if (processedCount == expectedCount) {
              batchSubscription?.cancel();
              completer.complete(results);
            }
            break;

          case IsolateMessageType.progress:
            final progressData = message.data as Map<String, int>;
            onProgress?.call(progressData['processed']!, progressData['total']!);
            break;

          case IsolateMessageType.processError:
            onError?.call(message.error ?? 'Unknown error');
            break;

          default:
            break;
        }
      }
    });

    // Send processing request to isolate
    _sendPort!.send(IsolateMessage(
      type: IsolateMessageType.processAssets,
      data: ProcessAssetsParams(
        assetIds: assetIds,
        responsePort: _receivePort.sendPort,
        databasePath: databasePath,
      ),
    ));

    return completer.future;
  }

  /// Handle messages from isolate
  void _handleMessage(dynamic message) {
    if (message is SendPort) {
      // Initial handshake - store the send port
      _sendPort = message;
      _completer.complete();
    } else if (message is IsolateMessage) {
      // Handle other messages based on type
      switch (message.type) {
        case IsolateMessageType.processError:
          _logger.error('Isolate error: ${message.error}');
          onError?.call(message.error ?? 'Unknown error');
          break;
        default:
          // Other messages are handled by batch-specific listeners
          break;
      }
    }
  }

  /// Shutdown the isolate
  Future<void> shutdown() async {
    try {
      _logger.info('Shutting down media processing isolate');

      if (_sendPort != null) {
        _sendPort!.send(IsolateMessage(type: IsolateMessageType.shutdown));
      }

      await _subscription?.cancel();
      _receivePort.close();
      _isolate?.kill(priority: Isolate.immediate);

      _logger.info('Media processing isolate shutdown complete');
    } catch (e, stack) {
      _logger.error('Error during isolate shutdown', error: e, stackTrace: stack);
    }
  }

  /// Isolate entry point (runs in separate isolate)
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    MediaDatabase? database;

    receivePort.listen((message) async {
      if (message is IsolateMessage) {
        switch (message.type) {
          case IsolateMessageType.processAssets:
            final params = message.data as ProcessAssetsParams;

            try {
              // Initialize database if needed
              database ??= MediaDatabase.withPath(params.databasePath);

              int processed = 0;
              final total = params.assetIds.length;

              for (final assetId in params.assetIds) {
                try {
                  // Get asset from photo manager
                  final asset = await AssetEntity.fromId(assetId);

                  if (asset != null) {
                    // Process based on type
                    Map<String, dynamic>? metadata;

                    if (asset.type == AssetType.image) {
                      // Extract EXIF data using MediaFormatHandler
                      final exifData = await MediaFormatHandler.extractImageMetadata(asset);
                      if (exifData != null) {
                        metadata = {
                          'type': 'exif',
                          'data': exifData.toJson(),
                        };
                      }
                    } else if (asset.type == AssetType.video) {
                      // Extract video metadata
                      final videoMetadata = await MediaFormatHandler.extractVideoMetadata(asset);
                      if (videoMetadata != null) {
                        metadata = {
                          'type': 'video',
                          'data': {
                            'duration': videoMetadata.duration,
                            'width': videoMetadata.width,
                            'height': videoMetadata.height,
                            'bitrate': videoMetadata.bitrate,
                            'codec': videoMetadata.codec,
                            'frameRate': videoMetadata.frameRate,
                          },
                        };
                      }
                    }

                    // Send success result
                    params.responsePort.send(IsolateMessage(
                      type: IsolateMessageType.processComplete,
                      data: AssetProcessingResult(
                        assetId: assetId,
                        success: true,
                        metadata: metadata,
                      ),
                    ));
                  } else {
                    // Asset not found
                    params.responsePort.send(IsolateMessage(
                      type: IsolateMessageType.processComplete,
                      data: AssetProcessingResult(
                        assetId: assetId,
                        success: false,
                        error: 'Asset not found',
                      ),
                    ));
                  }

                  processed++;

                  // Send progress update
                  if (processed % 10 == 0 || processed == total) {
                    params.responsePort.send(IsolateMessage(
                      type: IsolateMessageType.progress,
                      data: {
                        'processed': processed,
                        'total': total,
                      },
                    ));
                  }
                } catch (e) {
                  // Send error result for this asset
                  params.responsePort.send(IsolateMessage(
                    type: IsolateMessageType.processComplete,
                    data: AssetProcessingResult(
                      assetId: assetId,
                      success: false,
                      error: e.toString(),
                    ),
                  ));
                }
              }
            } catch (e) {
              // Send general error
              params.responsePort.send(IsolateMessage(
                type: IsolateMessageType.processError,
                error: e.toString(),
              ));
            }
            break;

          case IsolateMessageType.shutdown:
            database?.close();
            Isolate.exit();

          default:
            break;
        }
      }
    });
  }
}

/// Pool of isolates for parallel processing
class MediaProcessingPool {
  static final _logger = AppLogger('MediaProcessingPool');

  final int poolSize;
  final List<MediaProcessingIsolate> _isolates = [];
  int _currentIndex = 0;

  MediaProcessingPool({this.poolSize = 3});

  /// Initialize the pool
  Future<void> initialize() async {
    _logger.info('Initializing media processing pool with $poolSize isolates');

    for (int i = 0; i < poolSize; i++) {
      final isolate = MediaProcessingIsolate();
      await isolate.start();
      _isolates.add(isolate);
    }

    _logger.info('Media processing pool initialized');
  }

  /// Get next available isolate (round-robin)
  MediaProcessingIsolate getNextIsolate() {
    final isolate = _isolates[_currentIndex];
    _currentIndex = (_currentIndex + 1) % poolSize;
    return isolate;
  }

  /// Process assets in parallel
  Future<List<AssetProcessingResult>> processAssetsInParallel(
    List<String> assetIds,
    String databasePath, {
    void Function(int processed, int total)? onProgress,
  }) async {
    // Split assets into batches
    final batchSize = (assetIds.length / poolSize).ceil();
    final futures = <Future<List<AssetProcessingResult>>>[];

    int totalProcessed = 0;
    final totalAssets = assetIds.length;

    for (int i = 0; i < poolSize && i * batchSize < assetIds.length; i++) {
      final start = i * batchSize;
      final end = (start + batchSize < assetIds.length)
          ? start + batchSize
          : assetIds.length;

      final batch = assetIds.sublist(start, end);
      final isolate = _isolates[i];

      // Set progress callback
      isolate.onProgress = (processed, total) {
        totalProcessed += processed;
        onProgress?.call(totalProcessed, totalAssets);
      };

      futures.add(isolate.processAssets(batch, databasePath));
    }

    // Wait for all batches to complete
    final results = await Future.wait(futures);

    // Flatten results
    return results.expand((list) => list).toList();
  }

  /// Shutdown all isolates
  Future<void> shutdown() async {
    _logger.info('Shutting down media processing pool');

    await Future.wait(_isolates.map((isolate) => isolate.shutdown()));
    _isolates.clear();

    _logger.info('Media processing pool shutdown complete');
  }
}
