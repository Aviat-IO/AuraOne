import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Service for reverse geocoding coordinates to human-readable place names
/// Uses OpenStreetMap's Nominatim API (free, no API key required)
class ReverseGeocodingService {
  static final _logger = AppLogger('ReverseGeocodingService');

  // Nominatim API endpoint
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';

  // Cache duration (7 days)
  static const Duration _cacheDuration = Duration(days: 7);

  // Rate limiting
  static final _requestQueue = <Future<PlaceInfo?>>[];
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(seconds: 1); // Respect Nominatim's rate limit

  // In-memory cache for current session
  static final Map<String, PlaceInfo> _memoryCache = {};

  /// Get place information for coordinates
  static Future<PlaceInfo?> getPlaceInfo({
    required double latitude,
    required double longitude,
    bool useCache = true,
  }) async {
    final cacheKey = '${latitude.toStringAsFixed(6)}_${longitude.toStringAsFixed(6)}';

    // Check memory cache first
    if (useCache && _memoryCache.containsKey(cacheKey)) {
      _logger.debug('Found place in memory cache: ${_memoryCache[cacheKey]?.displayName}');
      return _memoryCache[cacheKey];
    }

    // Check persistent cache
    if (useCache) {
      final cached = await _getCachedPlace(cacheKey);
      if (cached != null) {
        _memoryCache[cacheKey] = cached;
        return cached;
      }
    }

    // Rate limit API requests
    await _enforceRateLimit();

    try {
      // Make API request to Nominatim
      final uri = Uri.parse(_nominatimUrl).replace(queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'zoom': '18', // Street level detail
        'addressdetails': '1',
        'namedetails': '1',
        'extratags': '1',
        'accept-language': 'en',
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AuraOne/1.0', // Required by Nominatim
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final placeInfo = PlaceInfo.fromNominatim(data);

        // Cache the result
        _memoryCache[cacheKey] = placeInfo;
        await _cachePlaceInfo(cacheKey, placeInfo);

        _logger.info('Geocoded location: ${placeInfo.displayName}');
        return placeInfo;
      } else {
        _logger.error('Nominatim API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.error('Error during reverse geocoding: $e');
      // Return a fallback with just coordinates
      return PlaceInfo(
        displayName: 'Location',
        name: null,
        category: PlaceCategory.other,
        address: PlaceAddress(
          city: null,
          neighborhood: null,
          road: null,
          suburb: null,
          state: null,
          country: null,
        ),
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  /// Enforce rate limiting to respect Nominatim's usage policy
  static Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Get cached place info
  static Future<PlaceInfo?> _getCachedPlace(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'geocode_$key';
      final cached = prefs.getString(cacheKey);

      if (cached != null) {
        final data = json.decode(cached);
        final timestamp = DateTime.parse(data['timestamp']);

        // Check if cache is still valid
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          _logger.debug('Found place in persistent cache');
          return PlaceInfo.fromJson(data['place']);
        } else {
          // Remove expired cache
          await prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      _logger.error('Error reading cache: $e');
    }
    return null;
  }

  /// Cache place info
  static Future<void> _cachePlaceInfo(String key, PlaceInfo place) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'geocode_$key';
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'place': place.toJson(),
      };
      await prefs.setString(cacheKey, json.encode(data));
    } catch (e) {
      _logger.error('Error caching place: $e');
    }
  }

  /// Clear all cached places
  static Future<void> clearCache() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('geocode_')).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
      _logger.info('Cleared ${keys.length} cached places');
    } catch (e) {
      _logger.error('Error clearing cache: $e');
    }
  }

  /// Batch geocode multiple locations efficiently
  static Future<List<PlaceInfo?>> batchGeocode(List<LocationCoordinate> coordinates) async {
    final results = <PlaceInfo?>[];

    for (final coord in coordinates) {
      // Check cache first to minimize API calls
      final cached = await getPlaceInfo(
        latitude: coord.latitude,
        longitude: coord.longitude,
        useCache: true,
      );
      results.add(cached);

      // Add small delay between requests to respect rate limits
      if (cached == null) {
        await Future.delayed(const Duration(milliseconds: 1100));
      }
    }

    return results;
  }
}

/// Simple coordinate holder
class LocationCoordinate {
  final double latitude;
  final double longitude;

  LocationCoordinate({required this.latitude, required this.longitude});
}

/// Detailed place information
class PlaceInfo {
  final String displayName;
  final String? name; // Specific venue name (e.g., "Starbucks")
  final PlaceCategory category;
  final PlaceAddress address;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? extraTags;

  PlaceInfo({
    required this.displayName,
    this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.extraTags,
  });

  /// Create from Nominatim API response
  factory PlaceInfo.fromNominatim(Map<String, dynamic> data) {
    final address = data['address'] ?? {};
    final extraTags = data['extratags'] ?? {};

    // Determine the specific venue name
    String? venueName = data['namedetails']?['name'] ??
        address['amenity'] ??
        address['shop'] ??
        address['tourism'] ??
        address['leisure'] ??
        address['building'] ??
        extraTags['name'];

    // Determine category from OSM tags
    final category = _inferCategory(data);

    // Build a smart display name
    String displayName;
    if (venueName != null && venueName.isNotEmpty) {
      displayName = venueName;
    } else if (address['road'] != null) {
      displayName = address['road'];
      if (address['house_number'] != null) {
        displayName = '${address['house_number']} $displayName';
      }
    } else if (address['neighborhood'] != null) {
      displayName = address['neighborhood'];
    } else if (address['suburb'] != null) {
      displayName = address['suburb'];
    } else if (address['city'] != null) {
      displayName = address['city'];
    } else {
      displayName = data['display_name']?.split(',').first ?? 'Unknown Location';
    }

    return PlaceInfo(
      displayName: displayName,
      name: venueName,
      category: category,
      address: PlaceAddress(
        houseNumber: address['house_number'],
        road: address['road'],
        neighborhood: address['neighborhood'],
        suburb: address['suburb'],
        city: address['city'] ?? address['town'] ?? address['village'],
        state: address['state'],
        country: address['country'],
        postcode: address['postcode'],
      ),
      latitude: double.parse(data['lat'].toString()),
      longitude: double.parse(data['lon'].toString()),
      extraTags: extraTags,
    );
  }

  /// Infer category from OSM data
  static PlaceCategory _inferCategory(Map<String, dynamic> data) {
    final type = data['type']?.toLowerCase() ?? '';
    final osm_type = data['osm_type']?.toLowerCase() ?? '';
    final addressType = data['addresstype']?.toLowerCase() ?? '';
    final address = data['address'] ?? {};
    final extraTags = data['extratags'] ?? {};

    // Check for specific amenities
    final amenity = address['amenity']?.toLowerCase() ?? extraTags['amenity']?.toLowerCase() ?? '';
    final shop = address['shop']?.toLowerCase() ?? extraTags['shop']?.toLowerCase() ?? '';
    final leisure = address['leisure']?.toLowerCase() ?? extraTags['leisure']?.toLowerCase() ?? '';
    final tourism = address['tourism']?.toLowerCase() ?? extraTags['tourism']?.toLowerCase() ?? '';

    // Food & Dining
    if (amenity.contains('restaurant') || amenity.contains('cafe') ||
        amenity.contains('fast_food') || amenity.contains('bar') ||
        amenity.contains('pub') || amenity.contains('food')) {
      return PlaceCategory.food;
    }

    // Shopping
    if (shop.isNotEmpty || amenity.contains('shop') ||
        amenity.contains('mall') || amenity.contains('market')) {
      return PlaceCategory.shopping;
    }

    // Fitness & Sports
    if (leisure.contains('fitness') || leisure.contains('sports') ||
        leisure.contains('gym') || amenity.contains('gym')) {
      return PlaceCategory.fitness;
    }

    // Healthcare
    if (amenity.contains('hospital') || amenity.contains('clinic') ||
        amenity.contains('doctor') || amenity.contains('dentist') ||
        amenity.contains('pharmacy')) {
      return PlaceCategory.healthcare;
    }

    // Education
    if (amenity.contains('school') || amenity.contains('university') ||
        amenity.contains('college') || amenity.contains('library')) {
      return PlaceCategory.education;
    }

    // Entertainment
    if (amenity.contains('cinema') || amenity.contains('theatre') ||
        tourism.contains('museum') || tourism.contains('gallery') ||
        leisure.contains('park')) {
      return PlaceCategory.entertainment;
    }

    // Transport
    if (amenity.contains('parking') || amenity.contains('fuel') ||
        type.contains('station') || type.contains('airport')) {
      return PlaceCategory.transport;
    }

    // Work (offices, commercial buildings)
    if (type.contains('office') || extraTags['office'] != null ||
        type.contains('commercial')) {
      return PlaceCategory.work;
    }

    // Home (residential)
    if (type.contains('house') || type.contains('residential') ||
        addressType.contains('house')) {
      return PlaceCategory.home;
    }

    return PlaceCategory.other;
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'name': name,
    'category': category.name,
    'address': address.toJson(),
    'latitude': latitude,
    'longitude': longitude,
    'extraTags': extraTags,
  };

  factory PlaceInfo.fromJson(Map<String, dynamic> json) => PlaceInfo(
    displayName: json['displayName'],
    name: json['name'],
    category: PlaceCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => PlaceCategory.other,
    ),
    address: PlaceAddress.fromJson(json['address']),
    latitude: json['latitude'],
    longitude: json['longitude'],
    extraTags: json['extraTags'],
  );
}

/// Address components
class PlaceAddress {
  final String? houseNumber;
  final String? road;
  final String? neighborhood;
  final String? suburb;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;

  PlaceAddress({
    this.houseNumber,
    this.road,
    this.neighborhood,
    this.suburb,
    this.city,
    this.state,
    this.country,
    this.postcode,
  });

  String get shortAddress {
    final parts = <String>[];
    if (road != null) parts.add(road!);
    if (neighborhood != null && neighborhood != road) parts.add(neighborhood!);
    if (city != null && city != neighborhood) parts.add(city!);
    return parts.take(2).join(', ');
  }

  Map<String, dynamic> toJson() => {
    'houseNumber': houseNumber,
    'road': road,
    'neighborhood': neighborhood,
    'suburb': suburb,
    'city': city,
    'state': state,
    'country': country,
    'postcode': postcode,
  };

  factory PlaceAddress.fromJson(Map<String, dynamic> json) => PlaceAddress(
    houseNumber: json['houseNumber'],
    road: json['road'],
    neighborhood: json['neighborhood'],
    suburb: json['suburb'],
    city: json['city'],
    state: json['state'],
    country: json['country'],
    postcode: json['postcode'],
  );
}

/// Place categories based on OpenStreetMap data
enum PlaceCategory {
  home,
  work,
  food,
  shopping,
  fitness,
  healthcare,
  education,
  entertainment,
  transport,
  other,
}

/// Extension to get icon for category
extension PlaceCategoryIcon on PlaceCategory {
  String get icon {
    switch (this) {
      case PlaceCategory.home:
        return '🏠';
      case PlaceCategory.work:
        return '💼';
      case PlaceCategory.food:
        return '🍽️';
      case PlaceCategory.shopping:
        return '🛍️';
      case PlaceCategory.fitness:
        return '💪';
      case PlaceCategory.healthcare:
        return '🏥';
      case PlaceCategory.education:
        return '📚';
      case PlaceCategory.entertainment:
        return '🎭';
      case PlaceCategory.transport:
        return '🚗';
      case PlaceCategory.other:
        return '📍';
    }
  }
}