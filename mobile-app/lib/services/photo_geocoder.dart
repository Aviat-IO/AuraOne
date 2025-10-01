import 'package:geocoding/geocoding.dart';
import 'package:native_exif/native_exif.dart';
import '../utils/logger.dart';
import '../database/media_database.dart';

/// Photo location information with coordinates and place name
class PhotoLocation {
  final double? latitude;
  final double? longitude;
  final String? placeName;
  final String? placeType;
  final String? street;
  final String? locality;
  final String? administrativeArea;
  final String? country;

  PhotoLocation({
    this.latitude,
    this.longitude,
    this.placeName,
    this.placeType,
    this.street,
    this.locality,
    this.administrativeArea,
    this.country,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasPlaceName => placeName != null && placeName!.isNotEmpty;

  @override
  String toString() {
    if (hasPlaceName) return placeName!;
    if (hasCoordinates) return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    return 'Unknown Location';
  }
}

/// Service for extracting and geocoding photo location data
class PhotoGeocoder {
  static final _logger = AppLogger('PhotoGeocoder');
  static final PhotoGeocoder _instance = PhotoGeocoder._internal();

  factory PhotoGeocoder() => _instance;
  PhotoGeocoder._internal();

  bool _reverseGeocodingEnabled = false;

  /// Enable or disable reverse geocoding
  void setReverseGeocodingEnabled(bool enabled) {
    _reverseGeocodingEnabled = enabled;
    _logger.info('Reverse geocoding ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if reverse geocoding is enabled
  bool isReverseGeocodingEnabled() => _reverseGeocodingEnabled;

  /// Extract location data from a photo
  Future<PhotoLocation> extractLocationData(MediaItem photo) async {
    try {
      _logger.debug('Extracting location data from: ${photo.filePath}');

      // 1. Extract EXIF GPS coordinates
      final coords = await _extractExifCoordinates(photo.filePath);

      if (coords == null) {
        _logger.debug('No GPS coordinates found in EXIF data');
        return PhotoLocation();
      }

      _logger.debug('Found GPS coordinates: ${coords.$1}, ${coords.$2}');

      // 2. Reverse geocode if enabled
      if (_reverseGeocodingEnabled) {
        try {
          final placemark = await _reverseGeocode(coords.$1, coords.$2);

          if (placemark != null) {
            final placeName = _formatPlaceName(placemark);
            final placeType = _inferPlaceType(placemark);

            return PhotoLocation(
              latitude: coords.$1,
              longitude: coords.$2,
              placeName: placeName,
              placeType: placeType,
              street: placemark.street,
              locality: placemark.locality,
              administrativeArea: placemark.administrativeArea,
              country: placemark.country,
            );
          }
        } catch (e) {
          _logger.warning('Reverse geocoding failed: $e');
        }
      }

      // Return coordinates only
      return PhotoLocation(
        latitude: coords.$1,
        longitude: coords.$2,
      );
    } catch (e, stack) {
      _logger.error('Error extracting location data', error: e, stackTrace: stack);
      return PhotoLocation();
    }
  }

  /// Extract GPS coordinates from EXIF data
  Future<(double, double)?> _extractExifCoordinates(String photoPath) async {
    try {
      final exif = await Exif.fromPath(photoPath);
      final latLong = await exif.getLatLong();
      await exif.close();

      if (latLong == null) {
        return null;
      }

      // latLong returns absolute values, need to check refs for sign
      final attributes = await exif.getAttributes();
      final latRef = attributes?['GPSLatitudeRef'];
      final lonRef = attributes?['GPSLongitudeRef'];

      double lat = latLong.latitude;
      double lon = latLong.longitude;

      // Apply negative sign for South and West
      if (latRef == 'S') lat = -lat;
      if (lonRef == 'W') lon = -lon;

      return (lat, lon);
    } catch (e) {
      _logger.debug('Error extracting EXIF coordinates: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to place information
  Future<Placemark?> _reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        _logger.debug('No placemarks found for coordinates');
        return null;
      }

      return placemarks.first;
    } catch (e) {
      _logger.warning('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Format place name from placemark
  String _formatPlaceName(Placemark placemark) {
    // Priority order for place naming:
    // 1. Name (e.g., "Harbor Roast Coffee", "Golden Gate Park")
    // 2. Street + Locality (e.g., "Market St, San Francisco")
    // 3. Locality only (e.g., "San Francisco")
    // 4. Administrative area (e.g., "California")

    if (placemark.name != null && placemark.name!.isNotEmpty) {
      // Filter out generic names like street numbers
      final name = placemark.name!;
      if (!RegExp(r'^\d+$').hasMatch(name)) {
        return name;
      }
    }

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        return '${placemark.street}, ${placemark.locality}';
      }
      return placemark.street!;
    }

    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      return placemark.locality!;
    }

    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      return placemark.administrativeArea!;
    }

    return 'Unknown Location';
  }

  /// Infer place type from placemark
  String _inferPlaceType(Placemark placemark) {
    // Attempt to categorize the place
    final name = placemark.name?.toLowerCase() ?? '';
    final street = placemark.street?.toLowerCase() ?? '';

    // Check for common place types
    if (name.contains('park') || name.contains('garden')) {
      return 'park';
    } else if (name.contains('restaurant') || name.contains('cafe') || name.contains('coffee')) {
      return 'dining';
    } else if (name.contains('gym') || name.contains('fitness') || name.contains('studio')) {
      return 'fitness';
    } else if (name.contains('office') || name.contains('building')) {
      return 'work';
    } else if (name.contains('home') || name.contains('house')) {
      return 'home';
    } else if (name.contains('mall') || name.contains('store') || name.contains('shop')) {
      return 'shopping';
    } else if (street.isNotEmpty) {
      return 'street';
    } else if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      return 'neighborhood';
    }

    return 'location';
  }

  /// Batch process multiple photos
  Future<Map<String, PhotoLocation>> extractLocationDataBatch(
    List<MediaItem> photos,
  ) async {
    final results = <String, PhotoLocation>{};

    for (final photo in photos) {
      final location = await extractLocationData(photo);
      results[photo.filePath] = location;
    }

    return results;
  }

  /// Get a short location description
  String getShortDescription(PhotoLocation location) {
    if (location.hasPlaceName) {
      return location.placeName!;
    }

    if (location.locality != null && location.locality!.isNotEmpty) {
      return location.locality!;
    }

    if (location.hasCoordinates) {
      return '${location.latitude!.toStringAsFixed(2)}, ${location.longitude!.toStringAsFixed(2)}';
    }

    return 'Unknown';
  }
}
