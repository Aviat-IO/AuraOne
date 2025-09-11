import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/photo_service.dart';
import '../services/exif_extractor.dart';
import '../services/face_detector.dart';
import '../services/person_service.dart';
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
  bool _isFaceDetecting = false;
  bool _isIdentifyingPersons = false;
  ExifData? _selectedPhotoExif;
  String? _selectedPhotoId;
  FaceDetectionResult? _selectedPhotoFaces;
  Map<String, FaceDetectionResult> _faceDetectionResults = {};
  List<Person> _identifiedPersons = [];
  List<Person> _personsInSelectedPhoto = [];
  Map<String, dynamic> _personStatistics = {};

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

            // Face Detection Button
            ElevatedButton.icon(
              onPressed: _isFaceDetecting || _recentPhotos.isEmpty
                  ? null
                  : () async {
                      setState(() => _isFaceDetecting = true);
                      try {
                        final photoService = ref.read(photoServiceProvider);
                        final results = await photoService.detectFacesBatch(
                          _recentPhotos,
                          config: FaceDetectionConfig.accurate,
                          onProgress: (completed, total) {
                            _logger.info('Face detection progress: $completed/$total');
                          },
                        );

                        setState(() {
                          _faceDetectionResults = results;
                        });

                        final totalFaces = results.values.fold(0, (sum, result) => sum + result.faces.length);
                        final highQualityFaces = results.values.fold(0, (sum, result) => sum + result.highQualityFaces.length);

                        _logger.info('Face detection complete: $totalFaces faces, $highQualityFaces high quality');

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Found $totalFaces faces ($highQualityFaces high quality) in ${results.length} photos'),
                            ),
                          );
                        }
                      } catch (e) {
                        _logger.error('Face detection failed', error: e);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Face detection failed: $e')),
                          );
                        }
                      } finally {
                        setState(() => _isFaceDetecting = false);
                      }
                    },
              icon: _isFaceDetecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.face),
              label: Text(_isFaceDetecting ? 'Detecting Faces...' : 'Detect Faces'),
            ),
            const SizedBox(height: 16),

            // Person Identification Button
            ElevatedButton.icon(
              onPressed: _isIdentifyingPersons || _recentPhotos.isEmpty
                  ? null
                  : () async {
                      setState(() => _isIdentifyingPersons = true);
                      try {
                        final photoService = ref.read(photoServiceProvider);

                        // Identify persons in recent photos
                        final persons = await photoService.identifyPersonsInPhotos(_recentPhotos);

                        // Get updated statistics
                        final stats = await photoService.getPersonStatistics();

                        setState(() {
                          _identifiedPersons = persons;
                          _personStatistics = stats;
                        });

                        _logger.info('Person identification complete: ${persons.length} persons found');

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Identified ${persons.length} persons in photos'),
                            ),
                          );
                        }
                      } catch (e) {
                        _logger.error('Person identification failed', error: e);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Person identification failed: $e')),
                          );
                        }
                      } finally {
                        setState(() => _isIdentifyingPersons = false);
                      }
                    },
              icon: _isIdentifyingPersons
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.people),
              label: Text(_isIdentifyingPersons ? 'Identifying Persons...' : 'Identify Persons'),
            ),
            const SizedBox(height: 16),

            // Face Detection Results
            if (_faceDetectionResults.isNotEmpty) ...[
              Text(
                'Face Detection Results (${_faceDetectionResults.length} photos with faces)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _faceDetectionResults.length,
                  itemBuilder: (context, index) {
                    final entry = _faceDetectionResults.entries.elementAt(index);
                    final result = entry.value;
                    final totalFaces = result.faces.length;
                    final highQualityFaces = result.highQualityFaces.length;

                    return Container(
                      width: 120,
                      margin: const EdgeInsets.all(4),
                      child: Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.face, color: Theme.of(context).primaryColor),
                            Text('$totalFaces faces', style: const TextStyle(fontSize: 12)),
                            Text('$highQualityFaces HQ',
                                 style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Person Identification Results
            if (_identifiedPersons.isNotEmpty) ...[
              Text(
                'Person Identification Results (${_identifiedPersons.length} persons found)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              // Person Statistics
              if (_personStatistics.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Statistics', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text('Total Persons: ${_personStatistics['totalPersons'] ?? 0}'),
                        Text('Named Persons: ${_personStatistics['namedPersons'] ?? 0}'),
                        Text('Photos with Faces: ${_personStatistics['photosWithFaces'] ?? 0}'),
                        Text('Average Photos per Person: ${(_personStatistics['averagePhotosPerPerson'] ?? 0.0).toStringAsFixed(1)}'),
                        Text('Average Confidence: ${((_personStatistics['averageConfidence'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Person List
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _identifiedPersons.length,
                  itemBuilder: (context, index) {
                    final person = _identifiedPersons[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            person.isNamed ? person.displayName[0].toUpperCase() : '?',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ),
                        title: Text(person.displayName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${person.photoCount} photos'),
                            Text('Confidence: ${(person.averageConfidence * 100).toStringAsFixed(1)}%'),
                          ],
                        ),
                        trailing: person.isNamed
                          ? const Icon(Icons.person, color: Colors.green)
                          : IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showNamePersonDialog(person),
                            ),
                        onTap: () => _showPersonDetails(person),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recent Photos Display
            if (_recentPhotos.isNotEmpty) ...[
              Text(
                'Recent Photos (${_recentPhotos.length}) - Tap for EXIF & Face Data',
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
                        onTap: () => _handlePhotoTap(photo),
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

            // Face Detection Data Display
            if (_selectedPhotoFaces != null && _selectedPhotoFaces!.faces.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Face Detection Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Total Faces: ${_selectedPhotoFaces!.faces.length}'),
                      Text('High Quality Faces: ${_selectedPhotoFaces!.highQualityFaces.length}'),
                      if (_selectedPhotoFaces!.bestFace != null) ...[
                        const SizedBox(height: 8),
                        const Text('Best Face:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Quality Score: ${(_selectedPhotoFaces!.bestFace!.qualityScore * 100).toStringAsFixed(1)}%'),
                        if (_selectedPhotoFaces!.bestFace!.confidence != null)
                          Text('Detection Confidence: ${(_selectedPhotoFaces!.bestFace!.confidence! * 100).toStringAsFixed(1)}%'),
                        Text('Bounding Box: ${_selectedPhotoFaces!.bestFace!.boundingBox.width.toInt()} x ${_selectedPhotoFaces!.bestFace!.boundingBox.height.toInt()}'),
                        if (_selectedPhotoFaces!.bestFace!.smilingProbability != null)
                          Text('Smiling: ${(_selectedPhotoFaces!.bestFace!.smilingProbability! * 100).toStringAsFixed(1)}%'),
                        if (_selectedPhotoFaces!.bestFace!.leftEyeOpenProbability != null &&
                            _selectedPhotoFaces!.bestFace!.rightEyeOpenProbability != null) ...[
                          Text('Left Eye Open: ${(_selectedPhotoFaces!.bestFace!.leftEyeOpenProbability! * 100).toStringAsFixed(1)}%'),
                          Text('Right Eye Open: ${(_selectedPhotoFaces!.bestFace!.rightEyeOpenProbability! * 100).toStringAsFixed(1)}%'),
                        ],
                      ],
                      if (_selectedPhotoFaces!.faces.length > 1) ...[
                        const SizedBox(height: 8),
                        const Text('All Faces:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...List.generate(_selectedPhotoFaces!.faces.length, (index) {
                          final face = _selectedPhotoFaces!.faces[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Text('Face ${index + 1}: '),
                                Text('${(face.qualityScore * 100).toStringAsFixed(1)}% quality'),
                                if (face.isHighQuality)
                                  const Text(' ⭐', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // Persons in Selected Photo Display
            if (_personsInSelectedPhoto.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Persons in This Photo (${_personsInSelectedPhoto.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_personsInSelectedPhoto.length, (index) {
                        final person = _personsInSelectedPhoto[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  person.isNamed ? person.displayName[0].toUpperCase() : '?',
                                  style: TextStyle(color: Colors.blue.shade700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Appears in ${person.photoCount} photos • ${(person.averageConfidence * 100).toStringAsFixed(1)}% confidence',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!person.isNamed)
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _showNamePersonDialog(person),
                                ),
                            ],
                          ),
                        );
                      }),
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

  /// Show dialog to name a person
  void _showNamePersonDialog(Person person) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This person appears in ${person.photoCount} photos.'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Person Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                try {
                  final photoService = ref.read(photoServiceProvider);
                  final updatedPerson = await photoService.namePerson(person.personId, name);

                  if (updatedPerson != null && mounted) {
                    // Update the person in our list
                    final index = _identifiedPersons.indexWhere((p) => p.personId == person.personId);
                    if (index != -1) {
                      setState(() {
                        _identifiedPersons[index] = updatedPerson;
                      });
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Named person as "$name"')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to name person: $e')),
                    );
                  }
                }

                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show person details dialog
  void _showPersonDetails(Person person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(person.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Person ID: ${person.personId}'),
              const SizedBox(height: 8),
              Text('Photos: ${person.photoCount}'),
              Text('Average Confidence: ${(person.averageConfidence * 100).toStringAsFixed(1)}%'),
              Text('Cluster Size: ${person.cluster.faces.length} faces'),
              Text('Created: ${person.createdAt.toLocal().toString().split('.')[0]}'),
              if (person.name != null) ...[
                const SizedBox(height: 8),
                Text('Name: ${person.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
              if (person.nickname != null) ...[
                const SizedBox(height: 8),
                Text('Nickname: ${person.nickname}'),
              ],
              const SizedBox(height: 16),
              const Text('Face Quality Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('High Quality Faces: ${person.cluster.faces.where((f) => f.confidence >= 0.6).length}'),
              Text('Medium Quality: ${person.cluster.faces.where((f) => f.confidence >= 0.4 && f.confidence < 0.6).length}'),
              Text('Low Quality: ${person.cluster.faces.where((f) => f.confidence < 0.4).length}'),
              const SizedBox(height: 16),
              const Text('Representative Face:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Quality Score: ${(person.representativeFace.confidence * 100).toStringAsFixed(1)}%'),
              Text('Face ID: ${person.representativeFace.faceId}'),
            ],
          ),
        ),
        actions: [
          if (!person.isNamed)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showNamePersonDialog(person);
              },
              child: const Text('Name Person'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Update photo tap handler to show persons in photo
  Future<void> _handlePhotoTap(AssetEntity photo) async {
    try {
      final photoService = ref.read(photoServiceProvider);

      // Get face detection results if available, or detect faces
      FaceDetectionResult? faceResult;
      if (_faceDetectionResults.containsKey(photo.id)) {
        faceResult = _faceDetectionResults[photo.id];
      } else {
        // Detect faces for this individual photo
        faceResult = await photoService.detectFacesInPhoto(photo);
      }

      // Get persons in this photo
      final personsInPhoto = await photoService.getPersonsInPhoto(photo.id);

      // Get EXIF data
      final exifData = await photoService.extractExifData(photo);

      setState(() {
        _selectedPhotoId = photo.id;
        _selectedPhotoExif = exifData;
        _selectedPhotoFaces = faceResult;
        _personsInSelectedPhoto = personsInPhoto;
      });

      _logger.info('Selected photo: ${photo.id}, faces: ${faceResult?.faces.length ?? 0}, persons: ${personsInPhoto.length}');
    } catch (e) {
      _logger.error('Failed to process photo tap', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process photo: $e')),
        );
      }
    }
  }
}
