import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Privacy Manager for AI Pipeline
/// Implements differential privacy and data protection mechanisms
class PrivacyManager {
  static PrivacyManager? _instance;
  
  // Privacy configuration
  double _privacyEpsilon = 1.0; // Privacy budget (lower = more private)
  bool _enableDifferentialPrivacy = false;
  bool _enableLocationObfuscation = true;
  bool _enableTemporalCloaking = true;
  
  // Noise generation
  final Random _random = Random.secure();
  
  PrivacyManager._();
  
  static PrivacyManager get instance {
    _instance ??= PrivacyManager._();
    return _instance!;
  }
  
  /// Configure privacy settings
  void configure({
    double? privacyEpsilon,
    bool? enableDifferentialPrivacy,
    bool? enableLocationObfuscation,
    bool? enableTemporalCloaking,
  }) {
    if (privacyEpsilon != null) {
      _privacyEpsilon = privacyEpsilon.clamp(0.1, 10.0);
    }
    if (enableDifferentialPrivacy != null) {
      _enableDifferentialPrivacy = enableDifferentialPrivacy;
    }
    if (enableLocationObfuscation != null) {
      _enableLocationObfuscation = enableLocationObfuscation;
    }
    if (enableTemporalCloaking != null) {
      _enableTemporalCloaking = enableTemporalCloaking;
    }
    
    debugPrint('Privacy configuration updated:');
    debugPrint('  Epsilon: $_privacyEpsilon');
    debugPrint('  Differential Privacy: $_enableDifferentialPrivacy');
    debugPrint('  Location Obfuscation: $_enableLocationObfuscation');
    debugPrint('  Temporal Cloaking: $_enableTemporalCloaking');
  }
  
  /// Apply differential privacy to GPS coordinates
  Position obfuscateLocation(Position original) {
    if (!_enableLocationObfuscation) {
      return original;
    }
    
    // Apply Laplacian noise for differential privacy
    final latNoise = _enableDifferentialPrivacy 
        ? _generateLaplacianNoise(_privacyEpsilon)
        : _generateGaussianNoise(0.001); // ~100m standard deviation
    
    final lonNoise = _enableDifferentialPrivacy
        ? _generateLaplacianNoise(_privacyEpsilon)
        : _generateGaussianNoise(0.001);
    
    // Apply noise to coordinates
    final obfuscatedLat = (original.latitude + latNoise).clamp(-90.0, 90.0);
    final obfuscatedLon = (original.longitude + lonNoise).clamp(-180.0, 180.0);
    
    return Position(
      latitude: obfuscatedLat,
      longitude: obfuscatedLon,
      timestamp: _obfuscateTimestamp(original.timestamp),
      accuracy: original.accuracy * 1.5, // Increase uncertainty
      altitude: original.altitude,
      altitudeAccuracy: original.altitudeAccuracy,
      heading: original.heading,
      headingAccuracy: original.headingAccuracy,
      speed: original.speed,
      speedAccuracy: original.speedAccuracy,
    );
  }
  
  /// Obfuscate timestamp for temporal privacy
  DateTime _obfuscateTimestamp(DateTime? original) {
    if (original == null || !_enableTemporalCloaking) {
      return original ?? DateTime.now();
    }
    
    // Add random offset of ±5 minutes
    final offsetMinutes = _random.nextInt(11) - 5;
    return original.add(Duration(minutes: offsetMinutes));
  }
  
  /// Generate Laplacian noise for differential privacy
  double _generateLaplacianNoise(double epsilon) {
    // Laplacian distribution: f(x) = (ε/2) * exp(-ε|x|)
    // Scale parameter b = 1/ε (sensitivity/epsilon)
    final scale = 0.001 / epsilon; // 0.001 degree ≈ 100m sensitivity
    
    // Generate using inverse CDF method
    final u = _random.nextDouble() - 0.5;
    return -scale * u.sign * log(1 - 2 * u.abs());
  }
  
  /// Generate Gaussian noise for standard obfuscation
  double _generateGaussianNoise(double stdDev) {
    // Box-Muller transform for Gaussian distribution
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    
    final z0 = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    return z0 * stdDev;
  }
  
  /// Apply k-anonymity to location clusters
  List<LocationCluster> applyKAnonymity(
    List<LocationCluster> clusters,
    {int k = 5}
  ) {
    final anonymizedClusters = <LocationCluster>[];
    
    for (final cluster in clusters) {
      if (cluster.pointCount < k) {
        // Merge with nearby clusters or generalize
        final generalizedCluster = _generalizeCluster(cluster, k);
        anonymizedClusters.add(generalizedCluster);
      } else {
        anonymizedClusters.add(cluster);
      }
    }
    
    return anonymizedClusters;
  }
  
  /// Generalize a cluster to meet k-anonymity
  LocationCluster _generalizeCluster(LocationCluster cluster, int k) {
    // Expand the cluster radius to include more points
    final expandedRadius = cluster.radius * sqrt(k / cluster.pointCount);
    
    return LocationCluster(
      centroid: _roundCoordinates(cluster.centroid),
      radius: expandedRadius,
      pointCount: k, // Report minimum k points
      startTime: _roundTime(cluster.startTime),
      endTime: _roundTime(cluster.endTime),
    );
  }
  
  /// Round coordinates to reduce precision
  Position _roundCoordinates(Position pos) {
    // Round to 3 decimal places (≈111m precision)
    final roundedLat = (pos.latitude * 1000).round() / 1000;
    final roundedLon = (pos.longitude * 1000).round() / 1000;
    
    return Position(
      latitude: roundedLat,
      longitude: roundedLon,
      timestamp: pos.timestamp,
      accuracy: max(pos.accuracy, 111.0),
      altitude: pos.altitude,
      altitudeAccuracy: pos.altitudeAccuracy,
      heading: pos.heading,
      headingAccuracy: pos.headingAccuracy,
      speed: pos.speed,
      speedAccuracy: pos.speedAccuracy,
    );
  }
  
  /// Round time to nearest 15 minutes
  DateTime _roundTime(DateTime time) {
    final minutes = time.minute;
    final roundedMinutes = ((minutes / 15).round() * 15) % 60;
    final hourAdjustment = minutes > 52 ? 1 : 0;
    
    return DateTime(
      time.year,
      time.month,
      time.day,
      time.hour + hourAdjustment,
      roundedMinutes,
    );
  }
  
  /// Apply privacy to activity patterns
  List<ActivityPattern> privatizeActivityPatterns(
    List<ActivityPattern> patterns
  ) {
    final privatized = <ActivityPattern>[];
    
    for (final pattern in patterns) {
      // Add noise to activity confidence scores
      final noisyConfidence = _enableDifferentialPrivacy
          ? (pattern.confidence + _generateLaplacianNoise(_privacyEpsilon * 10))
              .clamp(0.0, 1.0)
          : pattern.confidence;
      
      // Generalize fine-grained activities
      final generalizedActivity = _generalizeActivity(pattern.activity);
      
      privatized.add(ActivityPattern(
        activity: generalizedActivity,
        confidence: noisyConfidence,
        duration: _obfuscateDuration(pattern.duration),
        timestamp: _roundTime(pattern.timestamp),
      ));
    }
    
    return privatized;
  }
  
  /// Generalize activity types for privacy
  String _generalizeActivity(String activity) {
    // Map fine-grained activities to broader categories
    final generalizations = {
      'running': 'exercise',
      'walking': 'movement',
      'driving': 'transport',
      'cycling': 'exercise',
      'working': 'stationary',
      'sleeping': 'resting',
      'eating': 'stationary',
      'shopping': 'activity',
      'socializing': 'activity',
    };
    
    return generalizations[activity.toLowerCase()] ?? 'activity';
  }
  
  /// Obfuscate duration for temporal privacy
  Duration _obfuscateDuration(Duration original) {
    if (!_enableTemporalCloaking) {
      return original;
    }
    
    // Round to nearest 15 minutes
    final minutes = original.inMinutes;
    final roundedMinutes = ((minutes / 15).round() * 15);
    
    return Duration(minutes: roundedMinutes);
  }
  
  /// Generate privacy-preserving summary statistics
  Map<String, dynamic> generatePrivateStatistics(
    Map<String, dynamic> rawStats
  ) {
    final privateStats = <String, dynamic>{};
    
    for (final entry in rawStats.entries) {
      if (entry.value is num) {
        // Add noise to numeric values
        final noise = _enableDifferentialPrivacy
            ? _generateLaplacianNoise(_privacyEpsilon * 5)
            : 0.0;
        
        privateStats[entry.key] = (entry.value as num) + noise;
      } else if (entry.value is List) {
        // Apply k-anonymity to lists
        final list = entry.value as List;
        if (list.length < 5) {
          privateStats[entry.key] = '<5 items'; // Suppress small counts
        } else {
          privateStats[entry.key] = '${(list.length / 5).round() * 5}+ items';
        }
      } else {
        privateStats[entry.key] = entry.value;
      }
    }
    
    return privateStats;
  }
  
  /// Check if data collection is allowed based on privacy settings
  bool isDataCollectionAllowed(DataType dataType) {
    // Implement privacy policy checks
    switch (dataType) {
      case DataType.location:
        return true; // Always allow but obfuscate
      case DataType.activity:
        return true;
      case DataType.photos:
        return _shouldCollectPhotos();
      case DataType.audio:
        return false; // Disabled by default
      case DataType.biometric:
        return false; // Requires explicit consent
    }
  }
  
  bool _shouldCollectPhotos() {
    // Check user preferences and privacy settings
    return true; // Placeholder - implement actual preference check
  }
  
  double get privacyEpsilon => _privacyEpsilon;
  bool get isDifferentialPrivacyEnabled => _enableDifferentialPrivacy;
  bool get isLocationObfuscationEnabled => _enableLocationObfuscation;
  bool get isTemporalCloakingEnabled => _enableTemporalCloaking;
}

// Data structures for privacy management

class LocationCluster {
  final Position centroid;
  final double radius;
  final int pointCount;
  final DateTime startTime;
  final DateTime endTime;
  
  LocationCluster({
    required this.centroid,
    required this.radius,
    required this.pointCount,
    required this.startTime,
    required this.endTime,
  });
}

class ActivityPattern {
  final String activity;
  final double confidence;
  final Duration duration;
  final DateTime timestamp;
  
  ActivityPattern({
    required this.activity,
    required this.confidence,
    required this.duration,
    required this.timestamp,
  });
}

enum DataType {
  location,
  activity,
  photos,
  audio,
  biometric,
}