import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'logger.dart';

/// Performance monitoring utility for tracking frame rates and jank
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final List<FrameTiming> _recentFrames = [];
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  // Thresholds
  static const int _targetFrameTimeMs = 16; // 60 FPS
  static const int _jankThresholdMs = 32; // Frame taking > 2x target time
  static const int _severeJankThresholdMs = 48; // Frame taking > 3x target time

  /// Start monitoring performance
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Register frame callback
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);

    // Start periodic reporting
    _monitoringTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _reportMetrics();
    });

    appLogger.info('Performance monitoring started');
  }

  /// Stop monitoring performance
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;

    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _monitoringTimer?.cancel();
    _monitoringTimer = null;

    appLogger.info('Performance monitoring stopped');
  }

  /// Handle frame timings
  void _onFrameTimings(List<FrameTiming> timings) {
    _recentFrames.addAll(timings);

    // Keep only last 100 frames
    if (_recentFrames.length > 100) {
      _recentFrames.removeRange(0, _recentFrames.length - 100);
    }

    // Check for severe jank immediately
    for (final timing in timings) {
      final frameTimeMs = timing.totalSpan.inMilliseconds;

      if (frameTimeMs > _severeJankThresholdMs) {
        appLogger.warning(
          'Severe jank detected: ${frameTimeMs}ms frame time (Build: ${timing.buildDuration.inMilliseconds}ms, Raster: ${timing.rasterDuration.inMilliseconds}ms)',
        );

        // Log suggestions based on the bottleneck
        if (timing.buildDuration.inMilliseconds > _targetFrameTimeMs) {
          appLogger.info('Consider optimizing widget build methods or using const constructors');
        }
        if (timing.rasterDuration.inMilliseconds > _targetFrameTimeMs) {
          appLogger.info('Consider reducing visual complexity or using RepaintBoundary widgets');
        }
      }
    }
  }

  /// Report performance metrics
  void _reportMetrics() {
    if (_recentFrames.isEmpty) return;

    int totalFrames = _recentFrames.length;
    int jankFrames = 0;
    int severeJankFrames = 0;
    int totalBuildTime = 0;
    int totalRasterTime = 0;

    for (final frame in _recentFrames) {
      final frameTimeMs = frame.totalSpan.inMilliseconds;
      totalBuildTime += frame.buildDuration.inMilliseconds;
      totalRasterTime += frame.rasterDuration.inMilliseconds;

      if (frameTimeMs > _jankThresholdMs) {
        jankFrames++;
        if (frameTimeMs > _severeJankThresholdMs) {
          severeJankFrames++;
        }
      }
    }

    final avgBuildTime = totalBuildTime ~/ totalFrames;
    final avgRasterTime = totalRasterTime ~/ totalFrames;
    final jankPercentage = (jankFrames / totalFrames * 100).toStringAsFixed(1);
    final fps = (1000 / ((totalBuildTime + totalRasterTime) / totalFrames)).toStringAsFixed(1);

    appLogger.info(
      'Performance Report - FPS: $fps, Jank: $jankPercentage% ($jankFrames/$totalFrames frames), '
      'Severe Jank: $severeJankFrames, Avg Build: ${avgBuildTime}ms, Avg Raster: ${avgRasterTime}ms',
    );

    // Clear frames after reporting
    _recentFrames.clear();
  }

  /// Get current performance stats
  PerformanceStats getStats() {
    if (_recentFrames.isEmpty) {
      return const PerformanceStats(
        fps: 60,
        jankPercentage: 0,
        avgBuildTimeMs: 0,
        avgRasterTimeMs: 0,
      );
    }

    int totalFrames = _recentFrames.length;
    int jankFrames = 0;
    int totalBuildTime = 0;
    int totalRasterTime = 0;

    for (final frame in _recentFrames) {
      final frameTimeMs = frame.totalSpan.inMilliseconds;
      totalBuildTime += frame.buildDuration.inMilliseconds;
      totalRasterTime += frame.rasterDuration.inMilliseconds;

      if (frameTimeMs > _jankThresholdMs) {
        jankFrames++;
      }
    }

    final avgBuildTime = totalBuildTime ~/ totalFrames;
    final avgRasterTime = totalRasterTime ~/ totalFrames;
    final avgFrameTime = (totalBuildTime + totalRasterTime) / totalFrames;
    final fps = avgFrameTime > 0 ? 1000 / avgFrameTime : 60;
    final jankPercentage = jankFrames / totalFrames * 100;

    return PerformanceStats(
      fps: fps.toDouble(),
      jankPercentage: jankPercentage,
      avgBuildTimeMs: avgBuildTime,
      avgRasterTimeMs: avgRasterTime,
    );
  }
}

/// Performance statistics
class PerformanceStats {
  final double fps;
  final double jankPercentage;
  final int avgBuildTimeMs;
  final int avgRasterTimeMs;

  const PerformanceStats({
    required this.fps,
    required this.jankPercentage,
    required this.avgBuildTimeMs,
    required this.avgRasterTimeMs,
  });

  bool get isHealthy => fps >= 55 && jankPercentage < 5;
  bool get needsOptimization => fps < 50 || jankPercentage > 10;
}

/// Utility class for measuring specific operations
class PerformanceTimer {
  final String operation;
  final Stopwatch _stopwatch = Stopwatch();

  PerformanceTimer(this.operation) {
    _stopwatch.start();
  }

  /// Stop timer and log results
  void stop() {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;

    if (elapsed > 100) {
      appLogger.warning('Slow operation "$operation" took ${elapsed}ms');
    } else if (kDebugMode) {
      appLogger.debug('Operation "$operation" took ${elapsed}ms');
    }
  }

  /// Stop timer and return elapsed time
  int stopAndReturn() {
    _stopwatch.stop();
    return _stopwatch.elapsedMilliseconds;
  }
}

/// Extension for easy performance timing
extension PerformanceExtensions<T> on Future<T> {
  /// Time an async operation
  Future<T> timed(String operation) async {
    final timer = PerformanceTimer(operation);
    try {
      final result = await this;
      timer.stop();
      return result;
    } catch (e) {
      timer.stop();
      rethrow;
    }
  }
}