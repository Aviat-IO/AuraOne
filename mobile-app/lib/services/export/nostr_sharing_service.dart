import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for sharing journal entries via Nostr protocol
/// Implements selective sharing with privacy controls
class NostrSharingService {
  /// Default Nostr relays for publishing
  static const List<String> defaultRelays = [
    'wss://relay.damus.io',
    'wss://relay.nostr.info',
    'wss://nostr-pub.wellorder.net',
    'wss://relay.primal.net',
  ];
  
  /// Create a Nostr event for a journal entry
  static Map<String, dynamic> createJournalEvent({
    required String content,
    required DateTime createdAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? pubkey,
  }) {
    // Create tags array
    final eventTags = <List<String>>[];
    
    // Add custom tags
    if (tags != null) {
      for (final tag in tags) {
        eventTags.add(['t', tag]);
      }
    }
    
    // Add client tag
    eventTags.add(['client', 'aura-one']);
    
    // Add metadata as tags if provided
    if (metadata != null) {
      if (metadata['location'] != null) {
        final location = metadata['location'] as Map<String, dynamic>;
        if (location['placeName'] != null) {
          eventTags.add(['location', location['placeName']]);
        }
        if (location['latitude'] != null && location['longitude'] != null) {
          eventTags.add(['geo', '${location['latitude']},${location['longitude']}']);
        }
      }
      
      if (metadata['mood'] != null) {
        eventTags.add(['mood', metadata['mood']]);
      }
      
      if (metadata['weather'] != null) {
        eventTags.add(['weather', metadata['weather']]);
      }
    }
    
    // Create event structure (NIP-01 compatible)
    final event = {
      'kind': 30023, // Long-form content (NIP-23)
      'content': content,
      'tags': eventTags,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      if (pubkey != null) 'pubkey': pubkey,
    };
    
    return event;
  }
  
  /// Create a filtered version of journal entry for public sharing
  static Map<String, dynamic> filterForPublicSharing({
    required Map<String, dynamic> journalEntry,
    bool includeLocation = false,
    bool includeTags = true,
    bool includeMood = true,
    bool includeWeather = true,
    List<String>? excludeTags,
    String? contentFilter,
  }) {
    final filtered = Map<String, dynamic>.from(journalEntry);
    
    // Filter content if pattern provided
    if (contentFilter != null && filtered['content'] != null) {
      String content = filtered['content'];
      // Remove lines containing the filter pattern
      final lines = content.split('\n');
      final filteredLines = lines.where((line) => 
        !line.toLowerCase().contains(contentFilter.toLowerCase())
      ).toList();
      filtered['content'] = filteredLines.join('\n');
    }
    
    // Handle location privacy
    if (!includeLocation && filtered['location'] != null) {
      filtered.remove('location');
    }
    
    // Handle tags filtering
    if (filtered['tags'] != null) {
      if (!includeTags) {
        filtered.remove('tags');
      } else if (excludeTags != null && excludeTags.isNotEmpty) {
        final tags = List<String>.from(filtered['tags']);
        tags.removeWhere((tag) => excludeTags.contains(tag));
        filtered['tags'] = tags;
      }
    }
    
    // Handle mood privacy
    if (!includeMood && filtered['mood'] != null) {
      filtered.remove('mood');
    }
    
    // Handle weather privacy
    if (!includeWeather && filtered['weather'] != null) {
      filtered.remove('weather');
    }
    
    // Remove sensitive metadata
    filtered.remove('encryptedContent');
    filtered.remove('privateNotes');
    filtered.remove('attachments'); // Don't share file attachments
    
    return filtered;
  }
  
  /// Create a summary event for multiple journal entries
  static Map<String, dynamic> createSummaryEvent({
    required List<Map<String, dynamic>> entries,
    required String title,
    required String summary,
    DateTime? publishedAt,
    String? pubkey,
  }) {
    final tags = <List<String>>[];
    
    // Add entry references as 'e' tags
    for (final entry in entries) {
      if (entry['id'] != null) {
        tags.add(['e', entry['id']]);
      }
    }
    
    // Add metadata tags
    tags.add(['title', title]);
    tags.add(['summary', summary]);
    tags.add(['client', 'aura-one']);
    tags.add(['published_at', (publishedAt ?? DateTime.now()).toIso8601String()]);
    
    // Count statistics
    final totalWords = entries.fold<int>(0, (sum, entry) {
      final content = entry['content'] as String? ?? '';
      return sum + content.split(' ').length;
    });
    
    tags.add(['word_count', totalWords.toString()]);
    tags.add(['entry_count', entries.length.toString()]);
    
    // Create content with markdown formatting
    final content = '''
# $title

$summary

---

This collection contains ${entries.length} journal entries with a total of $totalWords words.

Published from Aura One - Your Personal AI Journal
''';
    
    return {
      'kind': 30023, // Long-form content
      'content': content,
      'tags': tags,
      'created_at': (publishedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000,
      if (pubkey != null) 'pubkey': pubkey,
    };
  }
  
  /// Generate a unique identifier for a journal entry
  static String generateEntryId(Map<String, dynamic> entry) {
    final content = entry['content'] ?? '';
    final date = entry['date'] ?? DateTime.now().toIso8601String();
    final data = '$content$date';
    
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    
    return hash.toString().substring(0, 32); // Use first 32 chars of hash
  }
  
  /// Create sharing metadata for tracking published entries
  static Map<String, dynamic> createSharingMetadata({
    required String entryId,
    required List<String> relays,
    required DateTime publishedAt,
    String? eventId,
    String? pubkey,
    Map<String, dynamic>? privacySettings,
  }) {
    return {
      'entryId': entryId,
      'relays': relays,
      'publishedAt': publishedAt.toIso8601String(),
      if (eventId != null) 'eventId': eventId,
      if (pubkey != null) 'pubkey': pubkey,
      if (privacySettings != null) 'privacySettings': privacySettings,
      'version': 1,
    };
  }
  
  /// Parse a Nostr event back to journal entry format
  static Map<String, dynamic>? parseNostrEvent(Map<String, dynamic> event) {
    if (event['kind'] != 30023) {
      return null; // Not a long-form content event
    }
    
    final tags = event['tags'] as List<dynamic>? ?? [];
    final tagMap = <String, String>{};
    final entryTags = <String>[];
    
    // Parse tags
    for (final tag in tags) {
      if (tag is List && tag.length >= 2) {
        final tagName = tag[0] as String;
        final tagValue = tag[1] as String;
        
        if (tagName == 't') {
          entryTags.add(tagValue);
        } else {
          tagMap[tagName] = tagValue;
        }
      }
    }
    
    // Convert back to journal entry format
    final entry = {
      'content': event['content'],
      'date': DateTime.fromMillisecondsSinceEpoch(
        (event['created_at'] as int) * 1000
      ).toIso8601String(),
      'tags': entryTags,
    };
    
    // Add location if present
    if (tagMap['location'] != null || tagMap['geo'] != null) {
      entry['location'] = <String, dynamic>{};
      
      if (tagMap['location'] != null) {
        entry['location']['placeName'] = tagMap['location'];
      }
      
      if (tagMap['geo'] != null) {
        final coords = tagMap['geo']!.split(',');
        if (coords.length == 2) {
          entry['location']['latitude'] = double.tryParse(coords[0]);
          entry['location']['longitude'] = double.tryParse(coords[1]);
        }
      }
    }
    
    // Add mood if present
    if (tagMap['mood'] != null) {
      entry['mood'] = tagMap['mood'];
    }
    
    // Add weather if present
    if (tagMap['weather'] != null) {
      entry['weather'] = tagMap['weather'];
    }
    
    return entry;
  }
  
  /// Validate if content is appropriate for public sharing
  static bool validateForPublicSharing(String content) {
    // Check minimum content length
    if (content.trim().length < 10) {
      return false;
    }
    
    // Check for potential sensitive patterns
    final sensitivePatterns = [
      RegExp(r'\b\d{3}-?\d{2}-?\d{4}\b'), // SSN pattern
      RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'), // Credit card
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Email
      RegExp(r'\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'), // Phone
    ];
    
    for (final pattern in sensitivePatterns) {
      if (pattern.hasMatch(content)) {
        return false; // Contains potentially sensitive information
      }
    }
    
    return true;
  }
  
  /// Get suggested tags for a journal entry
  static List<String> suggestTags(String content) {
    final tags = <String>[];
    final lowerContent = content.toLowerCase();
    
    // Mood-related tags
    if (lowerContent.contains('happy') || lowerContent.contains('joy')) {
      tags.add('positive');
    }
    if (lowerContent.contains('sad') || lowerContent.contains('depressed')) {
      tags.add('reflection');
    }
    
    // Activity tags
    if (lowerContent.contains('work') || lowerContent.contains('office')) {
      tags.add('work');
    }
    if (lowerContent.contains('travel') || lowerContent.contains('trip')) {
      tags.add('travel');
    }
    if (lowerContent.contains('family') || lowerContent.contains('friends')) {
      tags.add('social');
    }
    
    // Time-based tags
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      tags.add('weekend');
    }
    
    // Add generic journal tag
    tags.add('journal');
    tags.add('auraone');
    
    return tags.toSet().toList(); // Remove duplicates
  }
}