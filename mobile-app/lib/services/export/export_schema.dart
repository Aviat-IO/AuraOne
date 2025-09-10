/// Data export schema definitions for Aura One journal backup system
/// 
/// This file defines the JSON schema structure for exporting journal data
/// in a standardized, documented format that can be imported by other systems.

class ExportSchema {
  static const String schemaVersion = '1.0.0';
  
  /// Main export structure
  static Map<String, dynamic> createExportPackage({
    required DateTime exportDate,
    required String appVersion,
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> journalEntries,
    required List<Map<String, dynamic>> mediaReferences,
    required Map<String, dynamic> metadata,
  }) {
    return {
      'schema': {
        'version': schemaVersion,
        'type': 'aura_one_journal_export',
        'exported': exportDate.toIso8601String(),
        'app_version': appVersion,
      },
      'user': userData,
      'journal': {
        'entries': journalEntries,
        'total_count': journalEntries.length,
      },
      'media': {
        'references': mediaReferences,
        'total_count': mediaReferences.length,
      },
      'metadata': metadata,
    };
  }
  
  /// Journal entry structure
  static Map<String, dynamic> createJournalEntry({
    required String id,
    required DateTime date,
    required String content,
    String? aiSummary,
    List<String>? tags,
    Map<String, dynamic>? location,
    List<String>? mediaIds,
    Map<String, dynamic>? sensorData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'ai_summary': aiSummary,
      'tags': tags ?? [],
      'location': location,
      'media_ids': mediaIds ?? [],
      'sensor_data': sensorData ?? {},
      'timestamps': {
        'created': (createdAt ?? date).toIso8601String(),
        'updated': (updatedAt ?? date).toIso8601String(),
      },
    };
  }
  
  /// Media reference structure
  static Map<String, dynamic> createMediaReference({
    required String id,
    required String filename,
    required String mimeType,
    required int sizeBytes,
    required DateTime capturedAt,
    String? relativePath,
    Map<String, dynamic>? metadata,
    String? checksum,
  }) {
    return {
      'id': id,
      'filename': filename,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'captured_at': capturedAt.toIso8601String(),
      'relative_path': relativePath ?? 'media/$filename',
      'metadata': metadata ?? {},
      'checksum': checksum,
    };
  }
  
  /// Location data structure
  static Map<String, dynamic> createLocationData({
    required double latitude,
    required double longitude,
    double? altitude,
    double? accuracy,
    String? placeName,
    String? address,
    DateTime? timestamp,
  }) {
    return {
      'coordinates': {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
      },
      'place': {
        'name': placeName,
        'address': address,
      },
      'timestamp': timestamp?.toIso8601String(),
    };
  }
  
  /// Sensor data structure (from health, calendar, BLE events)
  static Map<String, dynamic> createSensorData({
    Map<String, dynamic>? healthData,
    Map<String, dynamic>? calendarEvents,
    Map<String, dynamic>? bleProximityEvents,
    Map<String, dynamic>? customData,
  }) {
    return {
      'health': healthData ?? {},
      'calendar': calendarEvents ?? {},
      'ble_proximity': bleProximityEvents ?? {},
      'custom': customData ?? {},
    };
  }
  
  /// Export metadata
  static Map<String, dynamic> createMetadata({
    required DateTime exportStartDate,
    required DateTime exportEndDate,
    required int totalEntries,
    required int totalMedia,
    required int totalSizeBytes,
    String? exportReason,
    Map<String, dynamic>? statistics,
  }) {
    return {
      'export_range': {
        'start': exportStartDate.toIso8601String(),
        'end': exportEndDate.toIso8601String(),
      },
      'counts': {
        'entries': totalEntries,
        'media': totalMedia,
        'total_size_bytes': totalSizeBytes,
      },
      'export_reason': exportReason,
      'statistics': statistics ?? {},
    };
  }
}

/// Export format documentation
class ExportFormatDocumentation {
  static const String documentation = '''
# Aura One Journal Export Format v1.0.0

## Overview
This document describes the JSON schema used for exporting journal data from Aura One.
The format is designed to be self-documenting, version-controlled, and easily parseable
by other applications.

## File Structure
The export creates a ZIP archive containing:
- `journal.json` - Main journal data file (this schema)
- `media/` - Directory containing all media files referenced in entries
- `README.md` - This documentation file

## Schema Structure

### Root Object
- `schema`: Export schema metadata
  - `version`: Schema version (semver format)
  - `type`: Always "aura_one_journal_export"
  - `exported`: ISO 8601 timestamp of export
  - `app_version`: Version of Aura One that created export

- `user`: User information (optional, based on privacy settings)

- `journal`: Journal entries container
  - `entries`: Array of journal entry objects
  - `total_count`: Total number of entries

- `media`: Media references container  
  - `references`: Array of media reference objects
  - `total_count`: Total number of media files

- `metadata`: Export metadata and statistics

### Journal Entry Object
- `id`: Unique identifier for the entry
- `date`: ISO 8601 date of the journal entry
- `content`: Main text content of the entry
- `ai_summary`: AI-generated summary (optional)
- `tags`: Array of tag strings
- `location`: Location data object (optional)
- `media_ids`: Array of media reference IDs
- `sensor_data`: Sensor and integration data
- `timestamps`: Creation and update timestamps

### Media Reference Object
- `id`: Unique identifier for the media
- `filename`: Original filename
- `mime_type`: MIME type (e.g., "image/jpeg")
- `size_bytes`: File size in bytes
- `captured_at`: ISO 8601 timestamp when media was captured
- `relative_path`: Path within the export archive
- `metadata`: Additional media metadata (EXIF, etc.)
- `checksum`: SHA-256 hash for verification

### Location Object
- `coordinates`: GPS coordinates
  - `latitude`: Decimal degrees
  - `longitude`: Decimal degrees
  - `altitude`: Meters above sea level (optional)
  - `accuracy`: Accuracy radius in meters
- `place`: Human-readable location
  - `name`: Place name
  - `address`: Full address
- `timestamp`: When location was recorded

## Privacy Considerations
- All data is exported from local storage only
- User can select date ranges and specific entries to export
- Personal identifiers can be excluded based on privacy settings
- Media files can be optionally excluded to reduce size

## Import Compatibility
This format is designed to be imported by:
- Future versions of Aura One
- Other journaling applications
- Data analysis tools
- Personal archival systems

## Version History
- 1.0.0 (2024-01): Initial schema definition
''';
}