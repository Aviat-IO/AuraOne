import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../utils/logger.dart';

/// GPS coordinates extracted from EXIF data
class GpsCoordinates {
  final double latitude;
  final double longitude;
  final double? altitude;
  
  GpsCoordinates({
    required this.latitude,
    required this.longitude,
    this.altitude,
  });
  
  @override
  String toString() {
    return 'Lat: $latitude, Lng: $longitude${altitude != null ? ', Alt: ${altitude}m' : ''}';
  }
  
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (altitude != null) 'altitude': altitude,
  };
}

/// Camera settings extracted from EXIF data
class CameraSettings {
  final dynamic aperture;
  final dynamic shutterSpeed;
  final dynamic iso;
  final dynamic focalLength;
  final int? flash;
  final int? exposureMode;
  final int? meteringMode;
  final int? whiteBalance;
  
  CameraSettings({
    this.aperture,
    this.shutterSpeed,
    this.iso,
    this.focalLength,
    this.flash,
    this.exposureMode,
    this.meteringMode,
    this.whiteBalance,
  });
  
  Map<String, dynamic> toJson() => {
    if (aperture != null) 'aperture': aperture,
    if (shutterSpeed != null) 'shutterSpeed': shutterSpeed,
    if (iso != null) 'iso': iso,
    if (focalLength != null) 'focalLength': focalLength,
    if (flash != null) 'flash': flash,
    if (exposureMode != null) 'exposureMode': exposureMode,
    if (meteringMode != null) 'meteringMode': meteringMode,
    if (whiteBalance != null) 'whiteBalance': whiteBalance,
  };
}

/// Complete EXIF data extracted from an image
class ExifData {
  final String? make;
  final String? model;
  final String? software;
  final String? dateTime;
  final String? dateTimeOriginal;
  final String? dateTimeDigitized;
  final GpsCoordinates? gpsCoordinates;
  final CameraSettings cameraSettings;
  final int? imageWidth;
  final int? imageHeight;
  final int? orientation;
  final Map<String, dynamic> allExifData;
  
  ExifData({
    this.make,
    this.model,
    this.software,
    this.dateTime,
    this.dateTimeOriginal,
    this.dateTimeDigitized,
    this.gpsCoordinates,
    required this.cameraSettings,
    this.imageWidth,
    this.imageHeight,
    this.orientation,
    required this.allExifData,
  });
  
  Map<String, dynamic> toJson() => {
    if (make != null) 'make': make,
    if (model != null) 'model': model,
    if (software != null) 'software': software,
    if (dateTime != null) 'dateTime': dateTime,
    if (dateTimeOriginal != null) 'dateTimeOriginal': dateTimeOriginal,
    if (dateTimeDigitized != null) 'dateTimeDigitized': dateTimeDigitized,
    if (gpsCoordinates != null) 'gpsCoordinates': gpsCoordinates!.toJson(),
    'cameraSettings': cameraSettings.toJson(),
    if (imageWidth != null) 'imageWidth': imageWidth,
    if (imageHeight != null) 'imageHeight': imageHeight,
    if (orientation != null) 'orientation': orientation,
  };
}

/// Service for extracting EXIF metadata from images
class ExifExtractor {
  static final _logger = AppLogger('ExifExtractor');
  
  /// Extract EXIF data from image file path
  static Future<ExifData?> extractFromFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        _logger.warning('File does not exist: $imagePath');
        return null;
      }
      
      final bytes = await file.readAsBytes();
      return extractFromBytes(bytes);
    } catch (e, stack) {
      _logger.error('Failed to extract EXIF from file: $imagePath', 
                   error: e, stackTrace: stack);
      return null;
    }
  }
  
  /// Extract EXIF data from image bytes
  static ExifData? extractFromBytes(Uint8List imageBytes) {
    try {
      // Decode the image (supports JPEG, TIFF, and other formats)
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        _logger.warning('Could not decode image');
        return null;
      }
      
      if (image.exif.data.isEmpty) {
        _logger.info('No EXIF data found in image');
        return null;
      }
      
      return _parseExifData(image);
    } catch (e, stack) {
      _logger.error('Failed to extract EXIF from bytes', 
                   error: e, stackTrace: stack);
      return null;
    }
  }
  
  /// Parse EXIF data from decoded image
  static ExifData _parseExifData(img.Image image) {
    final exif = image.exif;
    final imageIfd = exif.imageIfd;
    final exifIfd = exif.exifIfd;
    final gpsIfd = exif.gpsIfd;
    
    // Extract basic info
    final make = _getStringValue(imageIfd['Make']);
    final model = _getStringValue(imageIfd['Model']);
    final software = _getStringValue(imageIfd['Software']);
    
    // Extract timestamps
    final dateTime = _getStringValue(imageIfd['DateTime']);
    final dateTimeOriginal = _getStringValue(exifIfd['DateTimeOriginal']);
    final dateTimeDigitized = _getStringValue(exifIfd['DateTimeDigitized']);
    
    // Extract image dimensions
    final imageWidth = _getIntValue(exifIfd['PixelXDimension']) ?? 
                      _getIntValue(imageIfd['ImageWidth']);
    final imageHeight = _getIntValue(exifIfd['PixelYDimension']) ?? 
                       _getIntValue(imageIfd['ImageLength']);
    final orientation = _getIntValue(imageIfd['Orientation']);
    
    // Extract GPS coordinates
    final gpsCoordinates = _extractGpsCoordinates(gpsIfd);
    
    // Extract camera settings
    final cameraSettings = CameraSettings(
      aperture: exifIfd['FNumber'],
      shutterSpeed: exifIfd['ExposureTime'],
      iso: exifIfd['ISOSpeedRatings'],
      focalLength: exifIfd['FocalLength'],
      flash: _getIntValue(exifIfd['Flash']),
      exposureMode: _getIntValue(exifIfd['ExposureMode']),
      meteringMode: _getIntValue(exifIfd['MeteringMode']),
      whiteBalance: _getIntValue(exifIfd['WhiteBalance']),
    );
    
    // Combine all EXIF data
    final allExifData = <String, dynamic>{
      'imageIfd': imageIfd,
      'exifIfd': exifIfd,
      if (gpsIfd.isNotEmpty) 'gpsIfd': gpsIfd,
    };
    
    return ExifData(
      make: make,
      model: model,
      software: software,
      dateTime: dateTime,
      dateTimeOriginal: dateTimeOriginal,
      dateTimeDigitized: dateTimeDigitized,
      gpsCoordinates: gpsCoordinates,
      cameraSettings: cameraSettings,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      orientation: orientation,
      allExifData: allExifData,
    );
  }
  
  /// Extract GPS coordinates from GPS IFD
  static GpsCoordinates? _extractGpsCoordinates(Map<String, dynamic> gpsIfd) {
    if (gpsIfd.isEmpty) return null;
    
    final latitudeRef = _getStringValue(gpsIfd['GPSLatitudeRef']);
    final longitudeRef = _getStringValue(gpsIfd['GPSLongitudeRef']);
    final latitude = gpsIfd['GPSLatitude'];
    final longitude = gpsIfd['GPSLongitude'];
    
    if (latitude == null || longitude == null) return null;
    
    // Convert GPS coordinates from degrees/minutes/seconds to decimal
    double? convertDmsToDecimal(dynamic dms, String? ref) {
      if (dms == null) return null;
      
      List<dynamic> dmsList;
      if (dms is List) {
        dmsList = dms;
      } else {
        return null;
      }
      
      if (dmsList.length < 3) return null;
      
      final degrees = _fractionToDouble(dmsList[0]);
      final minutes = _fractionToDouble(dmsList[1]);
      final seconds = _fractionToDouble(dmsList[2]);
      
      if (degrees == null || minutes == null || seconds == null) return null;
      
      double decimal = degrees + (minutes / 60) + (seconds / 3600);
      
      // Apply hemisphere reference (S and W are negative)
      if (ref == 'S' || ref == 'W') {
        decimal = -decimal;
      }
      
      return decimal;
    }
    
    final lat = convertDmsToDecimal(latitude, latitudeRef);
    final lng = convertDmsToDecimal(longitude, longitudeRef);
    
    if (lat == null || lng == null) return null;
    
    // Extract altitude if available
    double? alt;
    final altitude = gpsIfd['GPSAltitude'];
    if (altitude != null) {
      alt = _fractionToDouble(altitude);
      
      // GPSAltitudeRef: 0 = above sea level, 1 = below sea level
      final altitudeRef = _getIntValue(gpsIfd['GPSAltitudeRef']);
      if (altitudeRef == 1 && alt != null) {
        alt = -alt;
      }
    }
    
    return GpsCoordinates(
      latitude: lat,
      longitude: lng,
      altitude: alt,
    );
  }
  
  /// Convert EXIF fraction to double
  static double? _fractionToDouble(dynamic fraction) {
    if (fraction == null) return null;
    
    if (fraction is List && fraction.length >= 2) {
      final numerator = fraction[0];
      final denominator = fraction[1];
      
      if (numerator is num && denominator is num && denominator != 0) {
        return numerator / denominator;
      }
    } else if (fraction is num) {
      return fraction.toDouble();
    }
    
    return null;
  }
  
  /// Get string value from EXIF data
  static String? _getStringValue(dynamic value) {
    if (value == null) return null;
    
    if (value is String) {
      // Clean up string values (remove null terminators)
      return value.replaceAll('\x00', '').trim();
    }
    
    if (value is List<int>) {
      // Convert byte array to string
      try {
        return String.fromCharCodes(value)
            .replaceAll('\x00', '')
            .trim();
      } catch (_) {
        return null;
      }
    }
    
    return value.toString();
  }
  
  /// Get integer value from EXIF data
  static int? _getIntValue(dynamic value) {
    if (value == null) return null;
    
    if (value is int) {
      return value;
    }
    
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is int) {
        return first;
      }
    }
    
    if (value is String) {
      return int.tryParse(value);
    }
    
    return null;
  }
  
  /// Format EXIF date/time string to DateTime
  static DateTime? parseExifDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;
    
    try {
      // EXIF date format: "YYYY:MM:DD HH:MM:SS"
      final parts = dateTimeString.split(' ');
      if (parts.length != 2) return null;
      
      final dateParts = parts[0].split(':');
      final timeParts = parts[1].split(':');
      
      if (dateParts.length != 3 || timeParts.length != 3) return null;
      
      return DateTime(
        int.parse(dateParts[0]), // Year
        int.parse(dateParts[1]), // Month
        int.parse(dateParts[2]), // Day
        int.parse(timeParts[0]), // Hour
        int.parse(timeParts[1]), // Minute
        int.parse(timeParts[2]), // Second
      );
    } catch (e) {
      _logger.warning('Failed to parse EXIF date/time: $dateTimeString', error: e);
      return null;
    }
  }
}