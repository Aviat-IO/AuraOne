import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/simple_location_service.dart';

class DataViewerScreen extends HookConsumerWidget {
  const DataViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Sensor data states
    final gyroscopeData = useState<GyroscopeEvent?>(null);
    final accelerometerData = useState<AccelerometerEvent?>(null);
    final userAccelerometerData = useState<UserAccelerometerEvent?>(null);
    final magnetometerData = useState<MagnetometerEvent?>(null);
    final locationData = useState<Position?>(null);
    // Update frequency state
    final updateFrequency = useState<Duration>(const Duration(milliseconds: 100));
    
    useEffect(() {
      // Gyroscope subscription
      final gyroSub = gyroscopeEventStream(
        samplingPeriod: updateFrequency.value,
      ).listen((event) {
        gyroscopeData.value = event;
      });
      
      // Accelerometer subscription
      final accelSub = accelerometerEventStream(
        samplingPeriod: updateFrequency.value,
      ).listen((event) {
        accelerometerData.value = event;
      });
      
      // User accelerometer subscription
      final userAccelSub = userAccelerometerEventStream(
        samplingPeriod: updateFrequency.value,
      ).listen((event) {
        userAccelerometerData.value = event;
      });
      
      // Magnetometer subscription
      final magnetSub = magnetometerEventStream(
        samplingPeriod: updateFrequency.value,
      ).listen((event) {
        magnetometerData.value = event;
      });
      
      // Location updates
      Timer? locationTimer;
      void updateLocation() async {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          locationData.value = position;
        } catch (e) {
          debugPrint('Location error: $e');
        }
      }
      
      updateLocation();
      locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        updateLocation();
      });
      
      return () {
        gyroSub.cancel();
        accelSub.cancel();
        userAccelSub.cancel();
        magnetSub.cancel();
        locationTimer?.cancel();
      };
    }, [updateFrequency.value]);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Data Viewer'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          PopupMenuButton<Duration>(
            onSelected: (Duration value) {
              updateFrequency.value = value;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Duration(milliseconds: 50),
                child: Text('20 Hz (50ms)'),
              ),
              const PopupMenuItem(
                value: Duration(milliseconds: 100),
                child: Text('10 Hz (100ms)'),
              ),
              const PopupMenuItem(
                value: Duration(milliseconds: 200),
                child: Text('5 Hz (200ms)'),
              ),
              const PopupMenuItem(
                value: Duration(milliseconds: 500),
                child: Text('2 Hz (500ms)'),
              ),
              const PopupMenuItem(
                value: Duration(seconds: 1),
                child: Text('1 Hz (1s)'),
              ),
            ],
            icon: const Icon(Icons.speed),
            tooltip: 'Update Frequency',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Movement State Card
              _buildDataCard(
                title: 'Movement State',
                icon: Icons.directions_walk,
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow('Status', 'Movement tracking disabled'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Location Data Card
              _buildDataCard(
                title: 'Location (GPS)',
                icon: Icons.location_on,
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow(
                      'Latitude',
                      locationData.value?.latitude.toStringAsFixed(6) ?? 'N/A',
                    ),
                    _buildDataRow(
                      'Longitude',
                      locationData.value?.longitude.toStringAsFixed(6) ?? 'N/A',
                    ),
                    _buildDataRow(
                      'Accuracy',
                      locationData.value != null 
                        ? '${locationData.value!.accuracy.toStringAsFixed(1)}m'
                        : 'N/A',
                    ),
                    _buildDataRow(
                      'Altitude',
                      locationData.value?.altitude.toStringAsFixed(1) ?? 'N/A',
                    ),
                    _buildDataRow(
                      'Speed',
                      locationData.value?.speed != null
                        ? '${(locationData.value!.speed * 3.6).toStringAsFixed(1)} km/h'
                        : 'N/A',
                    ),
                    _buildDataRow(
                      'Heading',
                      locationData.value?.heading?.toStringAsFixed(0) ?? 'N/A',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Gyroscope Data Card
              _buildDataCard(
                title: 'Gyroscope (rad/s)',
                icon: Icons.rotate_right,
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow('X (Pitch)', gyroscopeData.value?.x.toStringAsFixed(3) ?? 'N/A'),
                    _buildDataRow('Y (Roll)', gyroscopeData.value?.y.toStringAsFixed(3) ?? 'N/A'),
                    _buildDataRow('Z (Yaw)', gyroscopeData.value?.z.toStringAsFixed(3) ?? 'N/A'),
                    if (gyroscopeData.value != null) ...[
                      const Divider(),
                      _buildDataRow(
                        'Magnitude',
                        _calculateMagnitude(
                          gyroscopeData.value!.x,
                          gyroscopeData.value!.y,
                          gyroscopeData.value!.z,
                        ).toStringAsFixed(3),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Accelerometer Data Card
              _buildDataCard(
                title: 'Accelerometer (m/s²)',
                icon: Icons.speed,
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow('X', accelerometerData.value?.x.toStringAsFixed(3) ?? 'N/A'),
                    _buildDataRow('Y', accelerometerData.value?.y.toStringAsFixed(3) ?? 'N/A'),
                    _buildDataRow('Z', accelerometerData.value?.z.toStringAsFixed(3) ?? 'N/A'),
                    if (accelerometerData.value != null) ...[
                      const Divider(),
                      _buildDataRow(
                        'Magnitude',
                        _calculateMagnitude(
                          accelerometerData.value!.x,
                          accelerometerData.value!.y,
                          accelerometerData.value!.z,
                        ).toStringAsFixed(3),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // User Accelerometer Data Card (gravity removed)
              _buildDataCard(
                title: 'User Accelerometer (m/s²)',
                icon: Icons.accessibility_new,
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow('X', userAccelerometerData.value?.x.toStringAsFixed(3) ?? 'N/A'),
                    _buildDataRow('Y', userAccelerometerData.value?.y.toStringAsFixed(3) ?? 'N/A'),
                    _buildDataRow('Z', userAccelerometerData.value?.z.toStringAsFixed(3) ?? 'N/A'),
                    if (userAccelerometerData.value != null) ...[
                      const Divider(),
                      _buildDataRow(
                        'Magnitude',
                        _calculateMagnitude(
                          userAccelerometerData.value!.x,
                          userAccelerometerData.value!.y,
                          userAccelerometerData.value!.z,
                        ).toStringAsFixed(3),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Magnetometer Data Card
              _buildDataCard(
                title: 'Magnetometer (μT)',
                icon: Icons.explore,
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow('X', magnetometerData.value?.x.toStringAsFixed(3) ?? 'N/A'),
                    _buildDataRow('Y', magnetometerData.value?.y.toStringAsFixed(3) ?? 'N/A'),
                    _buildDataRow('Z', magnetometerData.value?.z.toStringAsFixed(3) ?? 'N/A'),
                    if (magnetometerData.value != null) ...[
                      const Divider(),
                      _buildDataRow(
                        'Magnitude',
                        _calculateMagnitude(
                          magnetometerData.value!.x,
                          magnetometerData.value!.y,
                          magnetometerData.value!.z,
                        ).toStringAsFixed(3),
                      ),
                      _buildDataRow(
                        'Direction',
                        _calculateCompassDirection(
                          magnetometerData.value!.x,
                          magnetometerData.value!.y,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Update Info Card
              _buildDataCard(
                title: 'Update Info',
                icon: Icons.info_outline,
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow(
                      'Update Frequency',
                      _getFrequencyText(updateFrequency.value),
                    ),
                    _buildDataRow(
                      'Last Update',
                      DateTime.now().toString().split('.')[0],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDataCard({
    required String title,
    required IconData icon,
    required ThemeData theme,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              color: value == 'N/A' ? Colors.grey : null,
            ),
          ),
        ],
      ),
    );
  }
  
  double _calculateMagnitude(double x, double y, double z) {
    return math.sqrt(x * x + y * y + z * z);
  }
  
  String _calculateCompassDirection(double x, double y) {
    final angle = (180 / math.pi) * math.atan2(y, x);
    final normalizedAngle = (angle + 360) % 360;
    
    if (normalizedAngle < 22.5 || normalizedAngle >= 337.5) return 'N';
    if (normalizedAngle < 67.5) return 'NE';
    if (normalizedAngle < 112.5) return 'E';
    if (normalizedAngle < 157.5) return 'SE';
    if (normalizedAngle < 202.5) return 'S';
    if (normalizedAngle < 247.5) return 'SW';
    if (normalizedAngle < 292.5) return 'W';
    return 'NW';
  }
  
  String _getFrequencyText(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      final hz = 1000 / duration.inMilliseconds;
      return '${hz.toStringAsFixed(0)} Hz (${duration.inMilliseconds}ms)';
    } else {
      return '${(1000 / duration.inMilliseconds).toStringAsFixed(1)} Hz (${duration.inSeconds}s)';
    }
  }
}