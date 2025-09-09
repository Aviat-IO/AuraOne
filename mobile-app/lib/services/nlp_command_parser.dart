import 'package:flutter/foundation.dart';
import 'voice_editing_service.dart';

/// Parser for natural language editing commands
class NLPCommandParser {
  /// Keywords for different command types
  static const Map<EditingCommandType, List<String>> _commandKeywords = {
    EditingCommandType.rewrite: [
      'rewrite',
      'rephrase',
      'change',
      'modify',
      'edit',
      'update',
      'revise',
    ],
    EditingCommandType.addDetail: [
      'add',
      'include',
      'insert',
      'append',
      'mention',
      'describe',
      'elaborate',
      'expand on',
      'add more',
      'add detail',
      'add information',
    ],
    EditingCommandType.removeSection: [
      'remove',
      'delete',
      'erase',
      'cut',
      'take out',
      'eliminate',
      'drop',
      'clear',
    ],
    EditingCommandType.replaceText: [
      'replace',
      'substitute',
      'swap',
      'change to',
      'make it',
      'instead of',
    ],
    EditingCommandType.insertText: [
      'insert',
      'add after',
      'add before',
      'put',
      'place',
    ],
    EditingCommandType.summarize: [
      'summarize',
      'shorten',
      'brief',
      'condense',
      'make shorter',
      'make concise',
    ],
    EditingCommandType.expand: [
      'expand',
      'elaborate',
      'detail',
      'explain',
      'make longer',
      'add more detail',
    ],
    EditingCommandType.correct: [
      'correct',
      'fix',
      'spell check',
      'grammar',
      'typo',
      'mistake',
    ],
  };

  /// Section identifiers for targeting specific parts
  static const List<String> _sectionKeywords = [
    'morning',
    'afternoon',
    'evening',
    'night',
    'breakfast',
    'lunch',
    'dinner',
    'work',
    'meeting',
    'exercise',
    'commute',
    'beginning',
    'middle',
    'end',
    'first',
    'second',
    'third',
    'last',
    'previous',
    'next',
    'section',
    'paragraph',
    'sentence',
    'line',
    'part',
    'about',
    'where',
    'when',
  ];

  /// Parse a natural language command into an EditingCommand
  static EditingCommand parse(String input) {
    final normalizedInput = input.toLowerCase().trim();
    
    // Detect command type
    final commandType = _detectCommandType(normalizedInput);
    
    // Extract target section
    final target = _extractTarget(normalizedInput);
    
    // Extract content for commands that need it
    final content = _extractContent(normalizedInput, commandType);
    
    // Extract additional metadata
    final metadata = _extractMetadata(normalizedInput);
    
    debugPrint('Parsed command: type=$commandType, target=$target, content=$content');
    
    return EditingCommand(
      type: commandType,
      target: target,
      content: content,
      metadata: metadata,
    );
  }

  /// Detect the type of editing command
  static EditingCommandType _detectCommandType(String input) {
    // Check each command type's keywords
    for (final entry in _commandKeywords.entries) {
      for (final keyword in entry.value) {
        if (input.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    // Default to unknown if no match
    return EditingCommandType.unknown;
  }

  /// Extract the target section or text to edit
  static String? _extractTarget(String input) {
    // Look for section keywords
    String? bestMatch;
    int bestMatchLength = 0;
    
    for (final section in _sectionKeywords) {
      if (input.contains(section)) {
        // Try to extract a phrase around the section keyword
        final pattern = RegExp('(\\w+\\s+)?$section(\\s+\\w+)?', caseSensitive: false);
        final match = pattern.firstMatch(input);
        if (match != null) {
          final extracted = match.group(0)?.trim();
          if (extracted != null && extracted.length > bestMatchLength) {
            bestMatch = extracted;
            bestMatchLength = extracted.length;
          }
        }
      }
    }
    
    // If no section found, look for quoted text
    if (bestMatch == null) {
      final quotedPattern = RegExp(r'"([^"]+)"|' + r"'([^']+)'");
      final match = quotedPattern.firstMatch(input);
      if (match != null) {
        bestMatch = match.group(1) ?? match.group(2);
      }
    }
    
    // If still no match, look for "the ... part/section"
    if (bestMatch == null) {
      final thePattern = RegExp(r'the\s+(\w+(?:\s+\w+)?)\s+(?:part|section|paragraph)', caseSensitive: false);
      final match = thePattern.firstMatch(input);
      if (match != null) {
        bestMatch = match.group(1);
      }
    }
    
    return bestMatch;
  }

  /// Extract content for commands that need new text
  static String? _extractContent(String input, EditingCommandType type) {
    String? content;
    
    // For commands that typically have content after certain phrases
    final contentPhrases = [
      'to say',
      'to read',
      'that says',
      'with',
      'about',
      'describing',
      'mentioning',
      'saying',
      'like',
      'such as',
      'instead',
      'to be',
    ];
    
    for (final phrase in contentPhrases) {
      final index = input.indexOf(phrase);
      if (index != -1) {
        // Extract everything after the phrase
        final afterPhrase = input.substring(index + phrase.length).trim();
        if (afterPhrase.isNotEmpty) {
          // Remove trailing punctuation
          content = afterPhrase.replaceAll(RegExp(r'[.!?]+$'), '').trim();
          break;
        }
      }
    }
    
    // For quoted content
    if (content == null) {
      final quotedPattern = RegExp(r'"([^"]+)"|' + r"'([^']+)'");
      final matches = quotedPattern.allMatches(input);
      if (matches.length > 1) {
        // If there are multiple quotes, the last one might be the content
        final lastMatch = matches.last;
        content = lastMatch.group(1) ?? lastMatch.group(2);
      }
    }
    
    // For replace commands, extract "X with Y" pattern
    if (type == EditingCommandType.replaceText) {
      final replacePattern = RegExp(r'replace\s+(.+?)\s+with\s+(.+)', caseSensitive: false);
      final match = replacePattern.firstMatch(input);
      if (match != null) {
        content = match.group(2)?.trim();
      }
    }
    
    return content;
  }

  /// Extract additional metadata from the command
  static Map<String, dynamic> _extractMetadata(String input) {
    final metadata = <String, dynamic>{};
    
    // Check for position indicators
    if (input.contains('beginning') || input.contains('start') || input.contains('first')) {
      metadata['position'] = 'beginning';
    } else if (input.contains('end') || input.contains('last') || input.contains('final')) {
      metadata['position'] = 'end';
    } else if (input.contains('middle') || input.contains('center')) {
      metadata['position'] = 'middle';
    }
    
    // Check for relative positions
    if (input.contains('before')) {
      metadata['relative'] = 'before';
    } else if (input.contains('after')) {
      metadata['relative'] = 'after';
    }
    
    // Check for emphasis or importance
    if (input.contains('important') || input.contains('emphasis') || input.contains('highlight')) {
      metadata['emphasis'] = true;
    }
    
    // Check for formatting preferences
    if (input.contains('bullet') || input.contains('list')) {
      metadata['format'] = 'list';
    } else if (input.contains('paragraph')) {
      metadata['format'] = 'paragraph';
    }
    
    return metadata;
  }

  /// Apply an editing command to text
  static String applyCommand(String originalText, EditingCommand command) {
    switch (command.type) {
      case EditingCommandType.rewrite:
        return _applyRewrite(originalText, command);
      case EditingCommandType.addDetail:
        return _applyAddDetail(originalText, command);
      case EditingCommandType.removeSection:
        return _applyRemoveSection(originalText, command);
      case EditingCommandType.replaceText:
        return _applyReplaceText(originalText, command);
      case EditingCommandType.insertText:
        return _applyInsertText(originalText, command);
      case EditingCommandType.summarize:
        return _applySummarize(originalText, command);
      case EditingCommandType.expand:
        return _applyExpand(originalText, command);
      case EditingCommandType.correct:
        return _applyCorrect(originalText, command);
      case EditingCommandType.unknown:
        return originalText; // No changes for unknown commands
    }
  }

  static String _applyRewrite(String text, EditingCommand command) {
    // For demo, just prepend a marker
    // In production, this would use AI to actually rewrite the section
    final target = command.target ?? 'entire text';
    return '// [Rewritten $target]\n$text';
  }

  static String _applyAddDetail(String text, EditingCommand command) {
    final content = command.content ?? '[additional details]';
    final position = command.metadata['position'] ?? 'end';
    
    if (position == 'beginning') {
      return '$content\n\n$text';
    } else {
      return '$text\n\n$content';
    }
  }

  static String _applyRemoveSection(String text, EditingCommand command) {
    if (command.target == null) return text;
    
    // Simple removal - in production, would be more sophisticated
    final lines = text.split('\n');
    final filteredLines = lines.where((line) {
      return !line.toLowerCase().contains(command.target!.toLowerCase());
    }).toList();
    
    return filteredLines.join('\n');
  }

  static String _applyReplaceText(String text, EditingCommand command) {
    if (command.target == null || command.content == null) return text;
    
    return text.replaceAll(
      RegExp(command.target!, caseSensitive: false),
      command.content!,
    );
  }

  static String _applyInsertText(String text, EditingCommand command) {
    if (command.content == null) return text;
    
    final position = command.metadata['position'] ?? 'end';
    
    if (position == 'beginning') {
      return '${command.content}\n\n$text';
    } else if (position == 'middle') {
      final lines = text.split('\n');
      final midpoint = lines.length ~/ 2;
      lines.insert(midpoint, '\n${command.content}\n');
      return lines.join('\n');
    } else {
      return '$text\n\n${command.content}';
    }
  }

  static String _applySummarize(String text, EditingCommand command) {
    // For demo, just show first few lines
    // In production, would use AI to summarize
    final lines = text.split('\n');
    final summary = lines.take(3).join('\n');
    return '$summary\n\n[... summarized ...]';
  }

  static String _applyExpand(String text, EditingCommand command) {
    // For demo, just add a marker
    // In production, would use AI to expand
    return '$text\n\n[... expanded with more detail ...]';
  }

  static String _applyCorrect(String text, EditingCommand command) {
    // Simple spelling corrections for demo
    // In production, would use proper spell/grammar checking
    return text
        .replaceAll('teh', 'the')
        .replaceAll('adn', 'and')
        .replaceAll('taht', 'that')
        .replaceAll('  ', ' '); // Remove double spaces
  }
}