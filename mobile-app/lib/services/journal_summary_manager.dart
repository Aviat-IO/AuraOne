import '../database/journal_database.dart';
import '../utils/logger.dart';
import 'summary_edit_tracker.dart';

/// High-level service for managing journal summaries with edit protection
///
/// Coordinates between SummaryEditTracker and JournalDatabase to ensure
/// user edits are never overwritten by AI regeneration.
class JournalSummaryManager {
  static final _logger = AppLogger('JournalSummaryManager');
  static final JournalSummaryManager _instance = JournalSummaryManager._internal();

  final SummaryEditTracker _editTracker = SummaryEditTracker();

  factory JournalSummaryManager() => _instance;
  JournalSummaryManager._internal();

  /// Save a new AI-generated summary with edit protection
  ///
  /// This method should be called whenever AI generates a new summary.
  /// It stores both the summary and its hash for edit detection.
  Future<bool> saveAiGeneratedSummary({
    required JournalDatabase database,
    required int journalEntryId,
    required String aiSummary,
  }) async {
    try {
      // Generate hash for edit detection
      final hash = _editTracker.generateSummaryHash(aiSummary);

      _logger.info('Saving AI-generated summary with edit protection');
      _logger.debug('Entry ID: $journalEntryId');
      _logger.debug('Summary hash: $hash');

      // Save summary with original copy and hash
      final success = await database.updateJournalSummary(
        id: journalEntryId,
        summary: aiSummary,
        originalAiSummary: aiSummary,
        summaryHash: hash,
        summaryWasEdited: false,
      );

      if (success) {
        _logger.info('Successfully saved AI summary with protection');
      } else {
        _logger.warning('Failed to save AI summary');
      }

      return success;
    } catch (e, stackTrace) {
      _logger.error('Error saving AI summary: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update journal summary after user edit
  ///
  /// Marks the summary as edited to prevent AI regeneration from
  /// overwriting the user's changes.
  Future<bool> saveUserEditedSummary({
    required JournalDatabase database,
    required int journalEntryId,
    required String editedSummary,
  }) async {
    try {
      _logger.info('Saving user-edited summary');
      _logger.debug('Entry ID: $journalEntryId');

      // Save edited summary and mark as edited
      final success = await database.updateJournalSummary(
        id: journalEntryId,
        summary: editedSummary,
        summaryWasEdited: true,
      );

      if (success) {
        _logger.info('Successfully saved user-edited summary');
      } else {
        _logger.warning('Failed to save user-edited summary');
      }

      return success;
    } catch (e, stackTrace) {
      _logger.error('Error saving user edit: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if summary can be regenerated without losing user edits
  ///
  /// Returns RegenerationStatus with decision and reasoning.
  Future<RegenerationStatus> canRegenerateSummary({
    required JournalDatabase database,
    required int journalEntryId,
    bool force = false,
  }) async {
    try {
      // Get current journal entry
      final entry = await database.select(database.journalEntries)
        .get()
        .then((entries) => entries.firstWhere((e) => e.id == journalEntryId));

      if (entry.summary == null || entry.summary!.isEmpty) {
        return RegenerationStatus(
          canRegenerate: true,
          reason: 'No existing summary',
          hasUserEdits: false,
        );
      }

      // Check if user has edited the summary
      final hasEdits = _editTracker.hasBeenEdited(
        entry.summary!,
        entry.summaryHash,
      );

      // Check if explicitly marked as edited
      final markedAsEdited = entry.summaryWasEdited;

      final hasAnyEdits = hasEdits || markedAsEdited;

      if (force) {
        _logger.warning('Forced regeneration - user edits will be lost');
        return RegenerationStatus(
          canRegenerate: true,
          reason: 'Forced regeneration requested',
          hasUserEdits: hasAnyEdits,
        );
      }

      if (hasAnyEdits) {
        _logger.info('User edits detected - blocking regeneration');
        return RegenerationStatus(
          canRegenerate: false,
          reason: 'Summary contains user edits',
          hasUserEdits: true,
        );
      }

      _logger.debug('No user edits detected - allowing regeneration');
      return RegenerationStatus(
        canRegenerate: true,
        reason: 'AI-generated summary (not edited)',
        hasUserEdits: false,
      );
    } catch (e, stackTrace) {
      _logger.error('Error checking regeneration status: $e', error: e, stackTrace: stackTrace);
      return RegenerationStatus(
        canRegenerate: false,
        reason: 'Error checking edit status',
        hasUserEdits: false,
        error: e.toString(),
      );
    }
  }

  /// Regenerate summary with edit protection check
  ///
  /// This method should be called before regenerating a summary.
  /// It ensures user edits are preserved (100% preservation requirement).
  ///
  /// Returns the new summary if regeneration succeeded, or null if blocked.
  Future<RegenerationResult> regenerateSummary({
    required JournalDatabase database,
    required int journalEntryId,
    required Future<String> Function() generateSummary,
    bool force = false,
  }) async {
    try {
      // Check if regeneration is allowed
      final status = await canRegenerateSummary(
        database: database,
        journalEntryId: journalEntryId,
        force: force,
      );

      if (!status.canRegenerate) {
        _logger.warning('Regeneration blocked: ${status.reason}');
        return RegenerationResult.blocked(
          reason: status.reason,
          hasUserEdits: status.hasUserEdits,
        );
      }

      // Generate new summary
      _logger.info('Generating new AI summary');
      final newSummary = await generateSummary();

      // Save with edit protection
      final success = await saveAiGeneratedSummary(
        database: database,
        journalEntryId: journalEntryId,
        aiSummary: newSummary,
      );

      if (success) {
        _logger.info('Successfully regenerated summary');
        return RegenerationResult.success(
          summary: newSummary,
          wasForced: force,
        );
      } else {
        _logger.error('Failed to save regenerated summary');
        return RegenerationResult.error(
          error: 'Failed to save summary to database',
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Error during regeneration: $e', error: e, stackTrace: stackTrace);
      return RegenerationResult.error(
        error: e.toString(),
      );
    }
  }

  /// Get edit severity for a summary
  ///
  /// Compares current summary with original to determine how much it was edited.
  Future<EditSeverity?> getEditSeverity({
    required JournalDatabase database,
    required int journalEntryId,
  }) async {
    try {
      final entry = await database.select(database.journalEntries)
        .get()
        .then((entries) => entries.firstWhere((e) => e.id == journalEntryId));

      if (entry.summary == null || entry.originalAiSummary == null) {
        return null;
      }

      return _editTracker.getEditSeverity(
        entry.originalAiSummary!,
        entry.summary!,
      );
    } catch (e, stackTrace) {
      _logger.error('Error getting edit severity: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get user-friendly status message
  Future<String> getProtectionStatusMessage({
    required JournalDatabase database,
    required int journalEntryId,
  }) async {
    try {
      final status = await canRegenerateSummary(
        database: database,
        journalEntryId: journalEntryId,
      );

      return _editTracker.getProtectionStatusMessage(
        hasBeenEdited: status.hasUserEdits,
        canRegenerate: status.canRegenerate,
      );
    } catch (e) {
      return 'Unknown status';
    }
  }
}

/// Status of regeneration check
class RegenerationStatus {
  final bool canRegenerate;
  final String reason;
  final bool hasUserEdits;
  final String? error;

  RegenerationStatus({
    required this.canRegenerate,
    required this.reason,
    required this.hasUserEdits,
    this.error,
  });
}

/// Result of regeneration attempt
class RegenerationResult {
  final RegenerationResultType type;
  final String? summary;
  final String? reason;
  final String? error;
  final bool wasForced;
  final bool hasUserEdits;

  RegenerationResult._({
    required this.type,
    this.summary,
    this.reason,
    this.error,
    this.wasForced = false,
    this.hasUserEdits = false,
  });

  factory RegenerationResult.success({
    required String summary,
    bool wasForced = false,
  }) {
    return RegenerationResult._(
      type: RegenerationResultType.success,
      summary: summary,
      wasForced: wasForced,
    );
  }

  factory RegenerationResult.blocked({
    required String reason,
    required bool hasUserEdits,
  }) {
    return RegenerationResult._(
      type: RegenerationResultType.blocked,
      reason: reason,
      hasUserEdits: hasUserEdits,
    );
  }

  factory RegenerationResult.error({
    required String error,
  }) {
    return RegenerationResult._(
      type: RegenerationResultType.error,
      error: error,
    );
  }

  bool get isSuccess => type == RegenerationResultType.success;
  bool get isBlocked => type == RegenerationResultType.blocked;
  bool get isError => type == RegenerationResultType.error;
}

enum RegenerationResultType {
  success,
  blocked,
  error,
}
