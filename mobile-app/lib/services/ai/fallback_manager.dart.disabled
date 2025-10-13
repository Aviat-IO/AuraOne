import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';
import 'optimization_manager.dart';

/// Fallback Manager for AI Pipeline
/// Implements progressive degradation strategies
class FallbackManager {
  static FallbackManager? _instance;
  
  // Fallback configuration
  final Map<String, FallbackStrategy> _strategies = {};
  final List<FallbackEvent> _fallbackHistory = [];
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration baseRetryDelay = Duration(seconds: 1);
  
  FallbackManager._();
  
  static FallbackManager get instance {
    _instance ??= FallbackManager._();
    return _instance!;
  }
  
  /// Initialize fallback strategies
  void initialize() {
    _registerDefaultStrategies();
    debugPrint('FallbackManager initialized with ${_strategies.length} strategies');
  }
  
  /// Register default fallback strategies
  void _registerDefaultStrategies() {
    // Stage 1: Spatiotemporal Processing Fallbacks
    _strategies['spatiotemporal'] = FallbackStrategy(
      name: 'Spatiotemporal Processing',
      levels: [
        FallbackLevel(
          name: 'Full Processing',
          description: 'DBSCAN clustering + HAR models',
          quality: 1.0,
        ),
        FallbackLevel(
          name: 'Simplified Clustering',
          description: 'Basic clustering without HAR',
          quality: 0.7,
        ),
        FallbackLevel(
          name: 'Location Only',
          description: 'Raw location data without analysis',
          quality: 0.4,
        ),
        FallbackLevel(
          name: 'No Location',
          description: 'Skip spatiotemporal analysis',
          quality: 0.0,
        ),
      ],
    );
    
    // Stage 2: Visual Context Fallbacks
    _strategies['visual'] = FallbackStrategy(
      name: 'Visual Context Processing',
      levels: [
        FallbackLevel(
          name: 'Full Vision Pipeline',
          description: 'Scene + Object + Captioning',
          quality: 1.0,
        ),
        FallbackLevel(
          name: 'Scene Recognition Only',
          description: 'Skip object detection and captioning',
          quality: 0.6,
        ),
        FallbackLevel(
          name: 'Basic Image Metadata',
          description: 'Use EXIF data only',
          quality: 0.3,
        ),
        FallbackLevel(
          name: 'No Visual Processing',
          description: 'Skip all image analysis',
          quality: 0.0,
        ),
      ],
    );
    
    // Stage 3: Multimodal Fusion Fallbacks
    _strategies['fusion'] = FallbackStrategy(
      name: 'Multimodal Fusion',
      levels: [
        FallbackLevel(
          name: 'Gemma Multimodal',
          description: 'Full Gemma 3 Nano fusion',
          quality: 1.0,
        ),
        FallbackLevel(
          name: 'Template Fusion',
          description: 'Rule-based fusion without AI',
          quality: 0.5,
        ),
        FallbackLevel(
          name: 'Simple Concatenation',
          description: 'Basic data combination',
          quality: 0.2,
        ),
      ],
    );
    
    // Stage 4: Summary Generation Fallbacks
    _strategies['summary'] = FallbackStrategy(
      name: 'Summary Generation',
      levels: [
        FallbackLevel(
          name: 'Full AI Generation',
          description: 'Gemma text generation',
          quality: 1.0,
        ),
        FallbackLevel(
          name: 'Hybrid Generation',
          description: 'Template + AI enhancement',
          quality: 0.7,
        ),
        FallbackLevel(
          name: 'Template Generation',
          description: 'Pure template-based',
          quality: 0.4,
        ),
        FallbackLevel(
          name: 'Simple List',
          description: 'Basic activity list',
          quality: 0.1,
        ),
      ],
    );
  }
  
  /// Execute operation with fallback support
  Future<T> executeWithFallback<T>(
    String strategyName,
    List<FallbackOperation<T>> operations,
  ) async {
    final strategy = _strategies[strategyName];
    if (strategy == null) {
      throw ArgumentError('Unknown fallback strategy: $strategyName');
    }
    
    for (int levelIndex = 0; levelIndex < operations.length; levelIndex++) {
      final operation = operations[levelIndex];
      final level = strategy.levels[levelIndex];
      
      debugPrint('Attempting: ${level.name} (quality: ${level.quality})');
      
      try {
        // Try operation with exponential backoff retry
        final result = await _executeWithRetry(
          operation,
          maxAttempts: levelIndex == 0 ? maxRetries : 1,
        );
        
        // Record successful execution
        _recordFallbackEvent(
          strategy: strategyName,
          level: levelIndex,
          success: true,
        );
        
        return result;
      } catch (e) {
        debugPrint('Failed at level $levelIndex: $e');
        
        // Record failure
        _recordFallbackEvent(
          strategy: strategyName,
          level: levelIndex,
          success: false,
          error: e.toString(),
        );
        
        // Continue to next fallback level
        if (levelIndex == operations.length - 1) {
          // No more fallback levels
          throw FallbackException(
            'All fallback levels exhausted for $strategyName',
            originalError: e,
          );
        }
      }
    }
    
    throw FallbackException('No operations provided for $strategyName');
  }
  
  /// Execute operation with retry logic
  Future<T> _executeWithRetry<T>(
    FallbackOperation<T> operation,
    {int maxAttempts = 3}
  ) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation.execute();
      } catch (e) {
        if (attempt == maxAttempts) {
          rethrow;
        }
        
        // Exponential backoff with jitter
        final delay = baseRetryDelay * (1 << (attempt - 1));
        final jitter = Duration(
          milliseconds: (delay.inMilliseconds * 0.2).round(),
        );
        
        debugPrint('Retry $attempt/$maxAttempts after ${delay + jitter}');
        await Future.delayed(delay + jitter);
      }
    }
    
    throw StateError('Retry logic failed');
  }
  
  /// Get recommended fallback level based on system state
  int getRecommendedLevel(
    String strategyName,
    ProcessingQuality quality,
  ) {
    final strategy = _strategies[strategyName];
    if (strategy == null) return 0;
    
    // Map processing quality to fallback level
    return switch (quality) {
      ProcessingQuality.maximum => 0,
      ProcessingQuality.high => 0,
      ProcessingQuality.medium => 1,
      ProcessingQuality.minimal => strategy.levels.length - 1,
    };
  }
  
  /// Record fallback event for monitoring
  void _recordFallbackEvent({
    required String strategy,
    required int level,
    required bool success,
    String? error,
  }) {
    final event = FallbackEvent(
      timestamp: DateTime.now(),
      strategy: strategy,
      level: level,
      success: success,
      error: error,
    );
    
    _fallbackHistory.add(event);
    
    // Keep only last 100 events
    if (_fallbackHistory.length > 100) {
      _fallbackHistory.removeAt(0);
    }
  }
  
  /// Get fallback statistics
  FallbackStatistics getStatistics() {
    final stats = <String, StrategyStats>{};
    
    for (final event in _fallbackHistory) {
      stats.putIfAbsent(
        event.strategy,
        () => StrategyStats(),
      );
      
      final strategyStats = stats[event.strategy]!;
      strategyStats.totalAttempts++;
      
      if (event.success) {
        strategyStats.successCount++;
        strategyStats.levelSuccesses[event.level] = 
            (strategyStats.levelSuccesses[event.level] ?? 0) + 1;
      } else {
        strategyStats.failureCount++;
      }
    }
    
    return FallbackStatistics(
      strategyStats: stats,
      totalEvents: _fallbackHistory.length,
      recentEvents: _fallbackHistory.reversed.take(10).toList(),
    );
  }
  
  /// Clear fallback history
  void clearHistory() {
    _fallbackHistory.clear();
  }
}

// Fallback data structures

class FallbackStrategy {
  final String name;
  final List<FallbackLevel> levels;
  
  FallbackStrategy({
    required this.name,
    required this.levels,
  });
}

class FallbackLevel {
  final String name;
  final String description;
  final double quality; // 0.0 to 1.0
  
  FallbackLevel({
    required this.name,
    required this.description,
    required this.quality,
  });
}

abstract class FallbackOperation<T> {
  Future<T> execute();
}

class FallbackEvent {
  final DateTime timestamp;
  final String strategy;
  final int level;
  final bool success;
  final String? error;
  
  FallbackEvent({
    required this.timestamp,
    required this.strategy,
    required this.level,
    required this.success,
    this.error,
  });
}

class FallbackStatistics {
  final Map<String, StrategyStats> strategyStats;
  final int totalEvents;
  final List<FallbackEvent> recentEvents;
  
  FallbackStatistics({
    required this.strategyStats,
    required this.totalEvents,
    required this.recentEvents,
  });
}

class StrategyStats {
  int totalAttempts = 0;
  int successCount = 0;
  int failureCount = 0;
  final Map<int, int> levelSuccesses = {};
  
  double get successRate => totalAttempts > 0
      ? successCount / totalAttempts
      : 0.0;
}

class FallbackException implements Exception {
  final String message;
  final Object? originalError;
  
  FallbackException(this.message, {this.originalError});
  
  @override
  String toString() => 'FallbackException: $message'
      '${originalError != null ? " (Original: $originalError)" : ""}';
}