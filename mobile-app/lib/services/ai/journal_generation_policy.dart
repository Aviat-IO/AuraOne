import 'ai_journal_generator.dart';

class JournalGenerationUnavailableException implements Exception {
  JournalGenerationUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'JournalGenerationUnavailableException: $message';
}

String resolveGeneratedNarrative({
  required AIJournalGenerator? adapter,
  required AIGenerationResult? result,
}) {
  if (adapter == null) {
    throw JournalGenerationUnavailableException(
      'Auto-generation is unavailable. Install Gemma 4 in Settings or enable cloud AI fallback.',
    );
  }

  if (result == null || !result.success) {
    throw JournalGenerationUnavailableException(
      result?.error ?? 'Auto-generation failed.',
    );
  }

  return result.content;
}
