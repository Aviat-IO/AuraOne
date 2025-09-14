import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../database/location_database.dart' as loc_db;
import '../../database/media_database.dart';
import 'narrative_generation.dart';
import 'multimodal_fusion.dart';
import 'activity_recognition.dart';
import 'image_captioning.dart';

/// Enhanced Simple AI Service with image captioning
class EnhancedSimpleAIService {
  static final _instance = EnhancedSimpleAIService._internal();
  factory EnhancedSimpleAIService() => _instance;
  EnhancedSimpleAIService._internal();

  bool _isInitialized = false;
  loc_db.LocationDatabase? _locationDb;
  MediaDatabase? _mediaDb;
  ImageCaptioningService? _imageCaptioningService;
  ImageLabeler? _imageLabeler;
  TextRecognizer? _textRecognizer;

  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize({
    loc_db.LocationDatabase? locationDb,
    MediaDatabase? mediaDb,
  }) async {
    _locationDb = locationDb;
    _mediaDb = mediaDb;

    try {
      // Initialize ML Kit services with improved configuration
      _imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(
          confidenceThreshold: 0.7,  // Higher threshold for better accuracy
        ),
      );
      _textRecognizer = TextRecognizer();

      // Initialize image captioning service
      _imageCaptioningService = ImageCaptioningService();
      await _imageCaptioningService!.initialize();

      _isInitialized = true;
      debugPrint('Enhanced Simple AI Service initialized with image analysis');
    } catch (e) {
      debugPrint('Warning: Could not initialize image analysis: $e');
      _isInitialized = true; // Still allow service to work without image analysis
    }
  }

  /// Generate a daily summary with image analysis
  Future<EnhancedDailySummary> generateDailySummary({
    required DateTime date,
    NarrativeStyle style = NarrativeStyle.casual,
  }) async {
    debugPrint('Generating enhanced daily summary for ${date.toIso8601String()}');

    // Get data from databases
    final locationData = await _getLocationData(date);
    final mediaData = await _getMediaData(date);

    // Analyze photo content
    final photoCaptions = await _analyzePhotos(mediaData);

    // Generate narrative based on available data
    String narrative;
    String summary;
    List<EnhancedEvent> events = [];

    if (locationData.isEmpty && mediaData.isEmpty) {
      // No data available
      narrative = "No activity data recorded for this day.";
      summary = "No data available";
    } else {
      // Build an enhanced narrative
      final buffer = StringBuffer();

      // Opening
      buffer.writeln(_generateOpening(date, locationData.length, mediaData.length));

      // Location summary
      if (locationData.isNotEmpty) {
        buffer.writeln(_generateLocationSummary(locationData));
        events = _createEventsFromLocations(locationData, photoCaptions);
      }

      // Enhanced media summary with photo descriptions
      if (mediaData.isNotEmpty) {
        buffer.writeln(_generateEnhancedMediaSummary(mediaData, photoCaptions));
      }

      // Closing
      buffer.writeln(_generateClosing(locationData.length, mediaData.length, photoCaptions));

      narrative = buffer.toString().trim();
      summary = _generateBriefSummary(locationData.length, mediaData.length, photoCaptions);
    }

    return EnhancedDailySummary(
      date: date,
      narrative: narrative,
      summary: summary,
      events: events,
      photoCaptions: photoCaptions,
      style: style,
      confidence: 0.8,
      dataPoints: {
        'locations': locationData.length,
        'photos': mediaData.length,
        'captions': photoCaptions.length,
      },
    );
  }

  /// Analyze photos and generate captions
  Future<List<PhotoCaption>> _analyzePhotos(List<MediaItem> mediaItems) async {
    final captions = <PhotoCaption>[];

    // Filter to only photos
    final photos = mediaItems.where((m) =>
      m.mimeType?.startsWith('image/') ?? false
    ).toList();

    for (final photo in photos) {
      try {
        final caption = await _generatePhotoCaption(photo);
        if (caption != null) {
          captions.add(caption);
        }
      } catch (e) {
        debugPrint('Error analyzing photo ${photo.id}: $e');
      }
    }

    return captions;
  }

  /// Generate caption for a single photo
  Future<PhotoCaption?> _generatePhotoCaption(MediaItem photo) async {
    if (photo.filePath == null) return null;

    try {
      final file = File(photo.filePath!);
      if (!await file.exists()) return null;

      // Use ML Kit to analyze the image
      final inputImage = InputImage.fromFile(file);

      // Get image labels with higher quality filtering
      List<ImageLabel> labels = [];
      if (_imageLabeler != null) {
        final allLabels = await _imageLabeler!.processImage(inputImage);
        // Filter to only high-confidence labels
        labels = allLabels.where((l) => l.confidence >= 0.7).toList();

        // Sort by confidence for better accuracy
        labels.sort((a, b) => b.confidence.compareTo(a.confidence));
      }

      // Try to detect text in the image
      String? detectedText;
      if (_textRecognizer != null) {
        final recognizedText = await _textRecognizer!.processImage(inputImage);
        if (recognizedText.text.isNotEmpty && recognizedText.text.length < 100) {
          // Filter out excessive text detection
          detectedText = recognizedText.text.trim();
        }
      }

      // Generate a descriptive caption
      String caption = _buildEnhancedCaption(labels, detectedText, photo);

      return PhotoCaption(
        photoId: photo.id,
        caption: caption,
        labels: labels.map((l) => l.label).toList(),
        confidence: labels.isNotEmpty ? labels.first.confidence : 0.5,
        timestamp: photo.createdDate,
        detectedText: detectedText,
      );
    } catch (e) {
      debugPrint('Error generating caption for photo: $e');
      return null;
    }
  }

  /// Build an enhanced natural language caption from labels and text
  String _buildEnhancedCaption(List<ImageLabel> labels, String? detectedText, MediaItem photo) {
    if (labels.isEmpty && detectedText == null) {
      return "A photo";
    }

    final buffer = StringBuffer();

    // Start with dominant objects/scenes
    if (labels.isNotEmpty) {
      final topLabels = labels.take(3).map((l) => l.label.toLowerCase()).toList();

      // Enhanced pattern matching with more specific categories
      if (_containsAny(topLabels, ['sunset', 'sunrise', 'dawn', 'dusk', 'golden hour'])) {
        final skyType = topLabels.firstWhere((l) => ['sunset', 'sunrise', 'dawn', 'dusk', 'golden hour'].contains(l));
        if (_containsAny(topLabels, ['sky', 'cloud', 'horizon'])) {
          buffer.write("A breathtaking $skyType with dramatic skies");
        } else {
          buffer.write("A beautiful $skyType");
        }
      } else if (_containsAny(topLabels, ['beach', 'ocean', 'sea', 'coast', 'shore', 'waves'])) {
        if (_containsAny(topLabels, ['sand', 'water', 'waves'])) {
          buffer.write("A pristine beach scene");
        } else {
          buffer.write("A coastal view");
        }
      } else if (_containsAny(topLabels, ['mountain', 'hill', 'valley', 'peak', 'ridge'])) {
        if (_containsAny(topLabels, ['snow', 'glacier'])) {
          buffer.write("Snow-capped mountains");
        } else if (_containsAny(topLabels, ['forest', 'tree'])) {
          buffer.write("Mountain landscapes with lush forests");
        } else {
          buffer.write("Majestic mountain scenery");
        }
      } else if (_containsAny(topLabels, ['food', 'meal', 'dish', 'cuisine', 'dessert', 'drink'])) {
        if (_containsAny(topLabels, ['restaurant', 'cafe', 'dining'])) {
          buffer.write("A dining experience");
        } else if (_containsAny(topLabels, ['dessert', 'cake', 'sweet'])) {
          buffer.write("A delicious dessert");
        } else {
          buffer.write("A culinary moment");
        }
      } else if (_containsAny(topLabels, ['person', 'face', 'people', 'crowd', 'portrait'])) {
        if (_containsAny(topLabels, ['smile', 'happy', 'joy'])) {
          buffer.write("Happy moments with people");
        } else if (_containsAny(topLabels, ['selfie', 'portrait'])) {
          buffer.write("A portrait capture");
        } else if (_containsAny(topLabels, ['group', 'crowd', 'team'])) {
          buffer.write("A group gathering");
        } else {
          buffer.write("A moment with people");
        }
      } else if (_containsAny(topLabels, ['dog', 'cat', 'pet', 'animal', 'bird'])) {
        final animal = topLabels.firstWhere((l) => ['dog', 'cat', 'pet', 'animal', 'bird'].contains(l));
        buffer.write("A lovely $animal");
      } else if (_containsAny(topLabels, ['city', 'building', 'skyscraper', 'street', 'urban'])) {
        if (_containsAny(topLabels, ['night', 'lights', 'neon'])) {
          buffer.write("City lights at night");
        } else if (_containsAny(topLabels, ['architecture', 'landmark'])) {
          buffer.write("Urban architecture");
        } else {
          buffer.write("A cityscape");
        }
      } else if (_containsAny(topLabels, ['nature', 'forest', 'tree', 'plant', 'flower'])) {
        if (_containsAny(topLabels, ['flower', 'blossom', 'bloom'])) {
          buffer.write("Beautiful flowers in bloom");
        } else if (_containsAny(topLabels, ['forest', 'woods'])) {
          buffer.write("A peaceful forest scene");
        } else {
          buffer.write("Natural beauty");
        }
      } else if (_containsAny(topLabels, ['water', 'lake', 'river', 'waterfall'])) {
        final waterType = topLabels.firstWhere((l) => ['lake', 'river', 'waterfall', 'water'].contains(l));
        buffer.write("A serene $waterType view");
      } else if (topLabels.isNotEmpty) {
        // Improved generic description
        final mainSubject = topLabels.first;
        if (topLabels.length > 1) {
          buffer.write("A $mainSubject scene");
        } else {
          buffer.write("A photo of $mainSubject");
        }
      } else {
        buffer.write("A captured moment");
      }

      // Add location context if multiple related labels
      final locationLabels = labels.where((l) =>
        ['indoor', 'outdoor', 'city', 'nature', 'urban', 'rural'].contains(l.label.toLowerCase())
      ).toList();

      if (locationLabels.isNotEmpty && !buffer.toString().contains(locationLabels.first.label.toLowerCase())) {
        buffer.write(" in an ${locationLabels.first.label.toLowerCase()} setting");
      }
    }

    // Add detected text if meaningful
    if (detectedText != null && detectedText.length > 3 && detectedText.length < 50) {
      if (buffer.isNotEmpty) buffer.write(" ");
      if (detectedText.contains(RegExp(r'[A-Z][a-z]+')) || detectedText.contains(' ')) {
        // Looks like a place name or sign
        buffer.write("at '$detectedText'");
      }
    }

    // Add time context
    final hour = photo.createdDate.hour;
    if (buffer.isEmpty) {
      if (hour < 6 || hour > 20) {
        buffer.write("A nighttime photo");
      } else if (hour < 10) {
        buffer.write("A morning photo");
      } else if (hour < 14) {
        buffer.write("A midday photo");
      } else if (hour < 18) {
        buffer.write("An afternoon photo");
      } else {
        buffer.write("An evening photo");
      }
    }

    return buffer.toString();
  }

  bool _containsAny(List<String> labels, List<String> keywords) {
    return labels.any((label) => keywords.contains(label));
  }

  String _formatList(List<String> items) {
    if (items.isEmpty) return "";
    if (items.length == 1) return items.first;
    if (items.length == 2) return "${items[0]} and ${items[1]}";
    return "${items.sublist(0, items.length - 1).join(", ")}, and ${items.last}";
  }

  /// Generate enhanced media summary with photo descriptions
  String _generateEnhancedMediaSummary(List<MediaItem> media, List<PhotoCaption> captions) {
    if (captions.isEmpty) {
      // Fallback to simple count
      final photoCount = media.where((m) => m.mimeType?.startsWith('image/') ?? false).length;
      if (photoCount > 0) {
        return "You took $photoCount photo${photoCount > 1 ? 's' : ''}.";
      }
      return "";
    }

    final buffer = StringBuffer();

    // Group captions by theme
    final scenicPhotos = captions.where((c) =>
      c.labels.any((l) => ['sunset', 'sunrise', 'landscape', 'beach', 'mountain', 'nature'].contains(l.toLowerCase()))
    ).toList();

    final foodPhotos = captions.where((c) =>
      c.labels.any((l) => ['food', 'meal', 'dish', 'restaurant', 'coffee'].contains(l.toLowerCase()))
    ).toList();

    final peoplePhotos = captions.where((c) =>
      c.labels.any((l) => ['person', 'people', 'group', 'selfie', 'face'].contains(l.toLowerCase()))
    ).toList();

    // Build narrative from photo themes
    if (scenicPhotos.isNotEmpty) {
      buffer.write("You captured ");
      if (scenicPhotos.length == 1) {
        buffer.write(scenicPhotos.first.caption.toLowerCase());
      } else {
        buffer.write("${scenicPhotos.length} scenic moments");
      }
      buffer.write(". ");
    }

    if (foodPhotos.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write("You also documented ");
      else buffer.write("You documented ");

      if (foodPhotos.length == 1) {
        buffer.write(foodPhotos.first.caption.toLowerCase());
      } else {
        buffer.write("${foodPhotos.length} culinary experiences");
      }
      buffer.write(". ");
    }

    if (peoplePhotos.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write("There were ");
      else buffer.write("You captured ");

      if (peoplePhotos.length == 1) {
        buffer.write("a special moment with others");
      } else {
        buffer.write("${peoplePhotos.length} social moments");
      }
      buffer.write(". ");
    }

    // Add specific interesting captions
    final interestingCaptions = captions
      .where((c) => c.confidence > 0.7)
      .take(2)
      .map((c) => c.caption)
      .toList();

    if (interestingCaptions.isNotEmpty && buffer.isEmpty) {
      buffer.write("Your photos included ");
      buffer.write(_formatList(interestingCaptions.map((c) => c.toLowerCase()).toList()));
      buffer.write(". ");
    }

    return buffer.toString().trim();
  }

  String _generateClosing(int locationCount, int mediaCount, List<PhotoCaption> captions) {
    final totalActivity = locationCount + mediaCount;

    // Add context from photo analysis
    if (captions.isNotEmpty) {
      final hasScenic = captions.any((c) =>
        c.labels.any((l) => ['sunset', 'sunrise', 'landscape', 'beach', 'mountain'].contains(l.toLowerCase()))
      );

      final hasSocial = captions.any((c) =>
        c.labels.any((l) => ['person', 'people', 'group', 'selfie'].contains(l.toLowerCase()))
      );

      if (hasScenic && hasSocial) {
        return "A perfect blend of natural beauty and cherished moments with others.";
      } else if (hasScenic) {
        return "A day filled with natural beauty and scenic views.";
      } else if (hasSocial) {
        return "A day enriched by connections and shared experiences.";
      }
    }

    if (totalActivity > 50) {
      return "It was a very active and eventful day!";
    } else if (totalActivity > 20) {
      return "A moderately active day with several memorable moments.";
    } else if (totalActivity > 0) {
      return "A calm day with a few special moments.";
    } else {
      return "";
    }
  }

  String _generateBriefSummary(int locationCount, int mediaCount, List<PhotoCaption> captions) {
    final highlights = <String>[];

    if (locationCount > 0) {
      highlights.add("$locationCount locations");
    }

    if (captions.isNotEmpty) {
      // Add photo themes to summary
      final themes = <String>{};
      for (final caption in captions) {
        if (caption.labels.any((l) => ['sunset', 'sunrise', 'landscape', 'nature'].contains(l.toLowerCase()))) {
          themes.add("scenic views");
        }
        if (caption.labels.any((l) => ['food', 'meal', 'restaurant'].contains(l.toLowerCase()))) {
          themes.add("culinary moments");
        }
        if (caption.labels.any((l) => ['person', 'people', 'selfie'].contains(l.toLowerCase()))) {
          themes.add("social interactions");
        }
      }

      if (themes.isNotEmpty) {
        highlights.add(themes.join(", "));
      } else {
        highlights.add("$mediaCount photos");
      }
    } else if (mediaCount > 0) {
      highlights.add("$mediaCount media items");
    }

    if (highlights.isEmpty) {
      return "No activity recorded";
    }

    return "Day included: ${highlights.join(", ")}";
  }

  // Keep existing helper methods
  Future<List<loc_db.LocationPoint>> _getLocationData(DateTime date) async {
    if (_locationDb == null) return [];

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final points = await _locationDb!.getLocationPointsBetween(
        startOfDay,
        endOfDay,
      );

      return points;
    } catch (e) {
      debugPrint('Error getting location data: $e');
      return [];
    }
  }

  Future<List<MediaItem>> _getMediaData(DateTime date) async {
    if (_mediaDb == null) return [];

    try {
      final media = await _mediaDb!.getRecentMedia(
        duration: const Duration(days: 30),
        limit: 500,
      );

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return media.where((m) {
        final createdDate = m.createdDate;
        return createdDate.isAfter(startOfDay) &&
               createdDate.isBefore(endOfDay);
      }).toList();
    } catch (e) {
      debugPrint('Error getting media data: $e');
      return [];
    }
  }

  String _generateOpening(DateTime date, int locationCount, int mediaCount) {
    final weekday = _getWeekdayName(date.weekday);

    if (locationCount > 0 && mediaCount > 0) {
      return "Your $weekday was filled with exploration and captured memories.";
    } else if (locationCount > 0) {
      return "You were active this $weekday, exploring various locations.";
    } else if (mediaCount > 0) {
      return "You documented special moments this $weekday.";
    } else {
      return "A quiet $weekday.";
    }
  }

  String _generateLocationSummary(List<loc_db.LocationPoint> locations) {
    final clusters = _clusterLocations(locations);

    if (clusters.isEmpty) {
      return "You stayed in one general area throughout the day.";
    } else if (clusters.length == 1) {
      return "You spent most of your day in one location.";
    } else {
      return "You visited ${clusters.length} different locations throughout the day.";
    }
  }

  List<EnhancedEvent> _createEventsFromLocations(
    List<loc_db.LocationPoint> locations,
    List<PhotoCaption> photoCaptions,
  ) {
    final clusters = _clusterLocations(locations);
    final events = <EnhancedEvent>[];

    for (int i = 0; i < clusters.length && i < 5; i++) {
      final cluster = clusters[i];

      // Find photos taken during this time period
      final eventPhotos = photoCaptions.where((caption) {
        return caption.timestamp.isAfter(cluster.first.timestamp.subtract(const Duration(minutes: 30))) &&
               caption.timestamp.isBefore(cluster.last.timestamp.add(const Duration(minutes: 30)));
      }).toList();

      events.add(EnhancedEvent(
        id: 'event_$i',
        startTime: cluster.first.timestamp,
        endTime: cluster.last.timestamp,
        type: EventType.stay,
        activities: [ActivityType.stationary],
        locationId: 'location_$i',
        photoCaptions: eventPhotos.map((p) => p.caption).toList(),
        metadata: {
          'pointCount': cluster.length,
          'latitude': cluster.first.latitude,
          'longitude': cluster.first.longitude,
          'photoCount': eventPhotos.length,
        },
      ));
    }

    return events;
  }

  List<List<loc_db.LocationPoint>> _clusterLocations(List<loc_db.LocationPoint> locations) {
    if (locations.isEmpty) return [];

    final clusters = <List<loc_db.LocationPoint>>[];
    List<loc_db.LocationPoint> currentCluster = [];

    for (final point in locations) {
      if (currentCluster.isEmpty) {
        currentCluster.add(point);
      } else {
        final lastPoint = currentCluster.last;
        final timeDiff = point.timestamp.difference(lastPoint.timestamp);

        if (timeDiff.inMinutes > 30) {
          if (currentCluster.isNotEmpty) {
            clusters.add(List.from(currentCluster));
          }
          currentCluster = [point];
        } else {
          currentCluster.add(point);
        }
      }
    }

    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    return clusters;
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }

  void dispose() {
    _imageLabeler?.close();
    _textRecognizer?.close();
    _imageCaptioningService?.dispose();
    _isInitialized = false;
    _locationDb = null;
    _mediaDb = null;
  }
}

/// Enhanced daily summary with photo captions
class EnhancedDailySummary {
  final DateTime date;
  final String narrative;
  final String summary;
  final List<EnhancedEvent> events;
  final List<PhotoCaption> photoCaptions;
  final NarrativeStyle style;
  final double confidence;
  final Map<String, dynamic> dataPoints;

  EnhancedDailySummary({
    required this.date,
    required this.narrative,
    required this.summary,
    required this.events,
    required this.photoCaptions,
    required this.style,
    required this.confidence,
    required this.dataPoints,
  });
}

/// Enhanced event with photo captions
class EnhancedEvent {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final List<ActivityType> activities;
  final String? locationId;
  final List<String> photoCaptions;
  final Map<String, dynamic> metadata;

  EnhancedEvent({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.activities,
    this.locationId,
    this.photoCaptions = const [],
    this.metadata = const {},
  });
}

/// Photo caption with metadata
class PhotoCaption {
  final String photoId;
  final String caption;
  final List<String> labels;
  final double confidence;
  final DateTime timestamp;
  final String? detectedText;

  PhotoCaption({
    required this.photoId,
    required this.caption,
    required this.labels,
    required this.confidence,
    required this.timestamp,
    this.detectedText,
  });
}