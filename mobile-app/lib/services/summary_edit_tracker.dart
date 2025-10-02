import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../utils/logger.dart';

/// Service for tracking AI-generated summaries and detecting user edits
///
/// Implements SHA-256 hashing to preserve user edits and prevent AI regeneration
/// from overwriting manual changes.
class SummaryEditTracker {
  static final _logger = AppLogger('SummaryEditTracker');
  static final SummaryEditTracker _instance = SummaryEditTracker._internal();

  factory SummaryEditTracker() => _instance;
  SummaryEditTracker._internal();

  /// Generate SHA-256 hash of AI-generated summary
  ///
  /// This hash is stored when AI generates a summary. Before regenerating,
  /// the current summary is hashed and compared to detect user edits.
  String generateSummaryHash(String summary) {
    if (summary.isEmpty) {
      return '';
    }

    // Normalize whitespace and line endings before hashing
    final normalized = _normalizeSummary(summary);
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Check if summary has been edited by user
  ///
  /// Compares current summary hash with original AI-generated hash.
  /// Returns true if user has modified the summary.
  bool hasBeenEdited(String currentSummary, String? originalHash) {
    if (originalHash == null || originalHash.isEmpty) {
      // No original hash means we can't detect edits
      return false;
    }

    if (currentSummary.isEmpty) {
      // Empty summary means it was deleted
      return originalHash.isNotEmpty;
    }

    final currentHash = generateSummaryHash(currentSummary);
    final wasEdited = currentHash != originalHash;

    if (wasEdited) {
      _logger.info('User edit detected: hash mismatch');
      _logger.debug('Original: $originalHash');
      _logger.debug('Current:  $currentHash');
    }

    return wasEdited;
  }

  /// Normalize summary text for consistent hashing
  ///
  /// Removes variations in whitespace and line endings that don't represent
  /// meaningful content changes.
  String _normalizeSummary(String summary) {
    return summary
        // Normalize line endings
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        // Remove trailing whitespace from each line
        .split('\n')
        .map((line) => line.trimRight())
        .join('\n')
        // Remove leading/trailing whitespace from entire text
        .trim();
  }

  /// Create edit protection metadata for a new AI-generated summary
  ///
  /// Returns map with hash and timestamp for tracking purposes.
  Map<String, dynamic> createProtectionMetadata(String aiSummary) {
    return {
      'hash': generateSummaryHash(aiSummary),
      'generated_at': DateTime.now().toIso8601String(),
      'version': 1,
    };
  }

  /// Validate edit protection metadata
  ///
  /// Ensures metadata has required fields and valid format.
  bool isValidMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return false;

    return metadata.containsKey('hash') &&
           metadata['hash'] is String &&
           (metadata['hash'] as String).isNotEmpty;
  }

  /// Check if regeneration should be allowed
  ///
  /// Returns true if summary can be safely regenerated without losing user edits.
  /// Returns false if user has edited the summary (100% preservation).
  bool canRegenerate({
    required String currentSummary,
    required String? originalHash,
    bool force = false,
  }) {
    if (force) {
      _logger.warning('Forced regeneration requested - user edits will be lost');
      return true;
    }

    if (originalHash == null || originalHash.isEmpty) {
      // No original hash means first generation or migration
      _logger.debug('No original hash found - allowing regeneration');
      return true;
    }

    final hasEdits = hasBeenEdited(currentSummary, originalHash);

    if (hasEdits) {
      _logger.info('User edits detected - blocking regeneration to preserve changes');
      return false;
    }

    _logger.debug('No user edits detected - allowing regeneration');
    return true;
  }

  /// Get user-friendly explanation of edit protection status
  String getProtectionStatusMessage({
    required bool hasBeenEdited,
    required bool canRegenerate,
  }) {
    if (!hasBeenEdited && canRegenerate) {
      return 'AI-generated summary (not edited)';
    } else if (hasBeenEdited && !canRegenerate) {
      return 'Manually edited - regeneration will overwrite your changes';
    } else if (!hasBeenEdited && !canRegenerate) {
      return 'Protected from regeneration';
    } else {
      return 'User-modified summary';
    }
  }

  /// Compare two summaries and calculate similarity
  ///
  /// Returns percentage similarity (0.0 to 1.0).
  /// Useful for detecting minor vs major edits.
  double calculateSimilarity(String summary1, String summary2) {
    if (summary1.isEmpty && summary2.isEmpty) return 1.0;
    if (summary1.isEmpty || summary2.isEmpty) return 0.0;

    final normalized1 = _normalizeSummary(summary1);
    final normalized2 = _normalizeSummary(summary2);

    if (normalized1 == normalized2) return 1.0;

    // Simple word-based similarity
    final words1 = normalized1.toLowerCase().split(RegExp(r'\s+'));
    final words2 = normalized2.toLowerCase().split(RegExp(r'\s+'));

    final set1 = words1.toSet();
    final set2 = words2.toSet();

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    if (union == 0) return 0.0;

    return intersection / union;
  }

  /// Determine edit severity based on similarity
  EditSeverity getEditSeverity(String original, String edited) {
    final similarity = calculateSimilarity(original, edited);

    if (similarity >= 0.95) {
      return EditSeverity.minimal; // Minor typo fixes
    } else if (similarity >= 0.75) {
      return EditSeverity.moderate; // Some rewording
    } else if (similarity >= 0.50) {
      return EditSeverity.substantial; // Significant changes
    } else {
      return EditSeverity.major; // Complete rewrite
    }
  }
}

/// Severity level of user edits to AI-generated content
enum EditSeverity {
  minimal,      // < 5% change (typos, minor tweaks)
  moderate,     // 5-25% change (some rewording)
  substantial,  // 25-50% change (significant changes)
  major,        // > 50% change (complete rewrite)
}

extension EditSeverityExtension on EditSeverity {
  String get description {
    switch (this) {
      case EditSeverity.minimal:
        return 'Minor edits';
      case EditSeverity.moderate:
        return 'Moderate changes';
      case EditSeverity.substantial:
        return 'Substantial modifications';
      case EditSeverity.major:
        return 'Major rewrite';
    }
  }

  /// Whether edits warrant preserving the summary
  bool get shouldPreserve {
    // Even minimal edits should be preserved
    return true;
  }
}
