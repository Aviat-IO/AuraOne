import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/photo_service.dart';
import '../services/exif_extractor.dart';
import '../utils/logger.dart';

class PhotoTestScreen extends ConsumerStatefulWidget {
  const PhotoTestScreen({super.key});

  @override
  ConsumerState<PhotoTestScreen> createState() => _PhotoTestScreenState();
}

class _PhotoTestScreenState extends ConsumerState<PhotoTestScreen> {
  static final _logger = AppLogger('PhotoTestScreen');
  List<AssetEntity> _recentPhotos = [];
  bool _isScanning = false;
  ExifData? _selectedPhotoExif;
  String? _selectedPhotoId;

  @override
  Widget build(BuildContext context) {
    final photoService = ref.watch(photoServiceProvider);
    final scanningState = ref.watch(automaticScanningProvider);
    
    // Listen to new photo stream
    ref.listen(newPhotoStreamProvider, (previous, next) {
      next.whenData((photos) {
        if (photos.isNotEmpty) {
          _logger.info('New photos detected: ${photos.length}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found ${photos.length} new photos!')),
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Service Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission Status
            Card(
              child: ListTile(
                title: const Text('Photo Library Access'),
                subtitle: Text(
                  photoService.hasFullAccess
                      ? 'Full Access Granted'
                      : photoService.hasAccess
                          ? 'Limited Access'
                          : 'No Access',
                ),
                trailing: photoService.hasAccess
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        onPressed: () async {
                          final permission = await photoService.requestPermissions();
                          setState(() {});
                          _logger.info('Permission result: ${permission.isAuth}');
                        },
                        child: const Text('Request'),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Automated Scanning Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automated Scanning',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: scanningState.isEnabled,
                          onChanged: (value) {
                            if (value) {
                              ref
                                  .read(automaticScanningProvider.notifier)
                                  .startScanning(
                                    interval: const Duration(seconds: 30), // Fast for testing
                                  );
                            } else {
                              ref
                                  .read(automaticScanningProvider.notifier)
                                  .stopScanning();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          scanningState.isEnabled ? 'Enabled' : 'Disabled',
                        ),
                      ],
                    ),
                    if (scanningState.isEnabled) ...[
                      const SizedBox(height: 8),
                      Text('Interval: ${scanningState.interval.inSeconds} seconds'),
                      if (scanningState.lastScanTime != null)
                        Text(
                          'Last Scan: ${scanningState.lastScanTime}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      Text('Known Photos: ${scanningState.knownPhotosCount}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Manual Scan Button
            ElevatedButton.icon(
              onPressed: _isScanning
                  ? null
                  : () async {
                      setState(() => _isScanning = true);
                      try {
                        final photos = await ref
                            .read(automaticScanningProvider.notifier)
                            .performManualScan(
                              lookback: const Duration(hours: 1),
                            );
                        setState(() {
                          _recentPhotos = photos.take(10).toList();
                        });
                        _logger.info('Manual scan found ${photos.length} photos');
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Found ${photos.length} photos in the last hour'),
                            ),
                          );
                        }
                      } catch (e) {
                        _logger.error('Manual scan failed', error: e);
                      } finally {
                        setState(() => _isScanning = false);
                      }
                    },
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isScanning ? 'Scanning...' : 'Manual Scan (1 hour)'),
            ),
            const SizedBox(height: 16),

            // Recent Photos Display
            if (_recentPhotos.isNotEmpty) ...[
              Text(
                'Recent Photos (${_recentPhotos.length}) - Tap to extract EXIF',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = _recentPhotos[index];
                    final isSelected = _selectedPhotoId == photo.id;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            _selectedPhotoId = photo.id;
                            _selectedPhotoExif = null;
                          });
                          
                          final exif = await photoService.extractExifData(photo);
                          setState(() {
                            _selectedPhotoExif = exif;
                          });
                          
                          if (exif == null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No EXIF data found')),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: isSelected
                                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FutureBuilder<Uint8List?>(
                            future: photoService.getThumbnail(photo),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    snapshot.data!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // EXIF Data Display
            if (_selectedPhotoExif != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXIF Data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_selectedPhotoExif!.make != null || _selectedPhotoExif!.model != null)
                        Text('Camera: ${_selectedPhotoExif!.make ?? ''} ${_selectedPhotoExif!.model ?? ''}'),
                      if (_selectedPhotoExif!.dateTimeOriginal != null)
                        Text('Date: ${_selectedPhotoExif!.dateTimeOriginal}'),
                      if (_selectedPhotoExif!.gpsCoordinates != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'GPS Location:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text('Latitude: ${_selectedPhotoExif!.gpsCoordinates!.latitude.toStringAsFixed(6)}'),
                        Text('Longitude: ${_selectedPhotoExif!.gpsCoordinates!.longitude.toStringAsFixed(6)}'),
                        if (_selectedPhotoExif!.gpsCoordinates!.altitude != null)
                          Text('Altitude: ${_selectedPhotoExif!.gpsCoordinates!.altitude!.toStringAsFixed(1)}m'),
                      ],
                      if (_selectedPhotoExif!.cameraSettings.aperture != null ||
                          _selectedPhotoExif!.cameraSettings.iso != null ||
                          _selectedPhotoExif!.cameraSettings.shutterSpeed != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Camera Settings:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (_selectedPhotoExif!.cameraSettings.aperture != null)
                          Text('Aperture: f/${_selectedPhotoExif!.cameraSettings.aperture}'),
                        if (_selectedPhotoExif!.cameraSettings.iso != null)
                          Text('ISO: ${_selectedPhotoExif!.cameraSettings.iso}'),
                        if (_selectedPhotoExif!.cameraSettings.shutterSpeed != null)
                          Text('Shutter Speed: ${_selectedPhotoExif!.cameraSettings.shutterSpeed}'),
                        if (_selectedPhotoExif!.cameraSettings.focalLength != null)
                          Text('Focal Length: ${_selectedPhotoExif!.cameraSettings.focalLength}mm'),
                      ],
                      if (_selectedPhotoExif!.imageWidth != null || _selectedPhotoExif!.imageHeight != null) ...[
                        const SizedBox(height: 8),
                        Text('Dimensions: ${_selectedPhotoExif!.imageWidth ?? '?'} x ${_selectedPhotoExif!.imageHeight ?? '?'}'),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // Clear Cache Button
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(automaticScanningProvider.notifier).clearCache();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo cache cleared')),
                );
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Cache'),
            ),
          ],
        ),
      ),
    );
  }
}