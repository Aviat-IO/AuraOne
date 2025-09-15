import 'package:string_similarity/string_similarity.dart';
import 'package:fuzzy/fuzzy.dart';
import '../database/journal_database.dart';

/// Enhanced search service that provides intelligent search capabilities
/// with fuzzy matching, stemming, and similarity scoring
class EnhancedSearchService {
  static const double _fuzzyThreshold = 0.6;
  static const double _similarityThreshold = 0.3;

  /// Simple English stemming rules for common word variations
  static final Map<RegExp, String> _stemmingRules = {
    // Plural to singular (specific patterns first)
    RegExp(r'([^aeiou])ies$'): r'$1y',  // victories -> victory
    RegExp(r'ies$'): 'ie',              // movies -> movie
    RegExp(r'ied$'): 'y',               // tried -> try
    RegExp(r'(s|x|z|ch|sh)es$'): r'$1', // boxes -> box, dishes -> dish
    RegExp(r'([^aeiousc])es$'): r'$1e', // notes -> note
    RegExp(r'([^s])s$'): r'$1',         // cats -> cat

    // Past tense variations
    RegExp(r'ied$'): 'y',
    RegExp(r'([^aeiou])ied$'): r'$1y',
    RegExp(r'(.+)ed$'): r'$1',
    RegExp(r'(.+)ing$'): r'$1',

    // Comparative forms
    RegExp(r'(.+)er$'): r'$1',
    RegExp(r'(.+)est$'): r'$1',
    RegExp(r'(.+)ly$'): r'$1',

    // Common suffixes
    RegExp(r'(.+)tion$'): r'$1t',
    RegExp(r'(.+)sion$'): r'$1s',
    RegExp(r'(.+)ness$'): r'$1',
    RegExp(r'(.+)ment$'): r'$1',
    RegExp(r'(.+)able$'): r'$1',
    RegExp(r'(.+)ible$'): r'$1',
  };

  /// Performs advanced search on journal entries with fuzzy matching and stemming
  Future<List<JournalEntrySearchResult>> searchJournalEntries(
    JournalDatabase database,
    String query,
  ) async {
    if (query.trim().isEmpty) return [];

    // Get all journal entries first
    final allEntries = await database.select(database.journalEntries).get();
    if (allEntries.isEmpty) return [];

    // Prepare search data for fuzzy matching
    final searchableEntries = allEntries.map((entry) {
      return SearchableEntry(
        entry: entry,
        searchableText: _combineSearchableText(entry),
      );
    }).toList();

    // Generate search variations (stemmed and similar words)
    final searchVariations = generateSearchVariations(query);
    final results = <JournalEntrySearchResult>[];

    for (final searchableEntry in searchableEntries) {
      final score = _calculateRelevanceScore(
        searchableEntry.searchableText,
        query,
        searchVariations,
      );

      if (score > 0) {
        results.add(JournalEntrySearchResult(
          entry: searchableEntry.entry,
          relevanceScore: score,
          matchedTerms: _findMatchedTerms(searchableEntry.searchableText, searchVariations),
        ));
      }
    }

    // Sort by relevance score (highest first)
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  /// Combines all searchable text from a journal entry
  String _combineSearchableText(JournalEntry entry) {
    final parts = <String>[
      entry.title,
      entry.content,
      if (entry.mood != null) entry.mood!,
      if (entry.tags != null) entry.tags!,
      if (entry.summary != null) entry.summary!,
    ];

    return parts.join(' ').toLowerCase();
  }

  /// Generates search variations including stemmed forms and common variations
  Set<String> generateSearchVariations(String query) {
    final variations = <String>{};
    final words = query.toLowerCase().split(RegExp(r'\s+'));

    for (final word in words) {
      if (word.isNotEmpty) {
        // Add original word
        variations.add(word);

        // Add stemmed versions
        variations.addAll(_generateStemVariations(word));

        // Add similar words based on common typos/variations
        variations.addAll(_generateSimilarWords(word));

        // Special handling for common word patterns
        if (word.endsWith('y')) {
          // Generate 'ies' version: victory -> victories
          final baseWithoutY = word.substring(0, word.length - 1);
          variations.add('${baseWithoutY}ies');
        }
        if (word.endsWith('ory')) {
          // Generate 'ories' version: victory -> victories
          final baseWithoutY = word.substring(0, word.length - 1);
          variations.add('${baseWithoutY}ies');
        }
      }
    }

    return variations;
  }

  /// Generates stem variations of a word
  Set<String> _generateStemVariations(String word) {
    final stems = <String>{};

    // Apply stemming rules
    for (final rule in _stemmingRules.entries) {
      if (rule.key.hasMatch(word)) {
        final stemmed = word.replaceFirst(rule.key, rule.value);
        if (stemmed.isNotEmpty && stemmed != word) {
          stems.add(stemmed);
        }
      }
    }

    // Also generate common variations from the stem
    final baseStem = _applyStemming(word);
    if (baseStem != word) {
      stems.add(baseStem);

      // Generate common inflections from the stem
      stems.addAll([
        '${baseStem}s',
        '${baseStem}es',
        '${baseStem}ed',
        '${baseStem}ing',
        '${baseStem}er',
        '${baseStem}est',
        '${baseStem}ly',
        '${baseStem}tion',
        '${baseStem}ness',
      ]);

      // Special case for words ending in 'y' - generate 'ies' version
      if (baseStem.endsWith('y')) {
        final baseWithoutY = baseStem.substring(0, baseStem.length - 1);
        stems.addAll([
          '${baseWithoutY}ies',  // victory -> victories
          '${baseWithoutY}ied',  // try -> tried
        ]);
      }
    }

    return stems;
  }

  /// Applies basic stemming rules to a word
  String _applyStemming(String word) {
    for (final rule in _stemmingRules.entries) {
      if (rule.key.hasMatch(word)) {
        return word.replaceFirst(rule.key, rule.value);
      }
    }
    return word;
  }

  /// Generates similar words based on edit distance and common variations
  Set<String> _generateSimilarWords(String word) {
    final similar = <String>{};

    // Common letter substitutions for typos
    final substitutions = {
      'a': ['e', 'o'],
      'e': ['a', 'i'],
      'i': ['e', 'y'],
      'o': ['a', 'u'],
      'u': ['o', 'i'],
      'y': ['i', 'e'],
      'c': ['k', 's'],
      'k': ['c', 'ck'],
      's': ['c', 'z'],
      'z': ['s'],
      'f': ['ph', 'v'],
      'ph': ['f'],
      'v': ['f', 'b'],
      'b': ['p', 'v'],
      'p': ['b'],
      'd': ['t'],
      't': ['d'],
      'g': ['j'],
      'j': ['g'],
    };

    // Generate single-character substitutions
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      final alternatives = substitutions[char] ?? [];

      for (final alt in alternatives) {
        final variation = word.substring(0, i) + alt + word.substring(i + 1);
        similar.add(variation);
      }
    }

    return similar;
  }

  /// Calculates relevance score for a text against search variations
  double _calculateRelevanceScore(
    String text,
    String originalQuery,
    Set<String> searchVariations,
  ) {
    double score = 0.0;
    final words = text.split(RegExp(r'\s+'));
    final queryWords = originalQuery.toLowerCase().split(RegExp(r'\s+'));

    // Exact phrase match gets highest score
    if (text.contains(originalQuery.toLowerCase())) {
      score += 100.0;
    }

    // Exact word matches
    for (final queryWord in queryWords) {
      if (words.any((word) => word.contains(queryWord))) {
        score += 50.0;
      }
    }

    // Check all search variations against all words in text
    for (final variation in searchVariations) {
      for (final word in words) {
        // Only match if the word contains the variation, not the other way around
        // This prevents "victories" from matching "to" just because "victories" contains "to"
        if (word == variation || word.contains(variation)) {
          score += 25.0;
        }
      }
    }

    // Fuzzy matches using the fuzzy package
    // We search for each variation within the list of words, not the entire text
    try {
      final fuzzy = Fuzzy(words, options: FuzzyOptions(
        threshold: _fuzzyThreshold,
      ));

      for (final variation in searchVariations) {
        final fuzzyResults = fuzzy.search(variation);
        for (final result in fuzzyResults) {
          if (result.score >= _fuzzyThreshold) {
            score += result.score * 30.0;
          }
        }
      }
    } catch (e) {
      // Silently continue with other matching methods
    }

    // String similarity matches
    for (final variation in searchVariations) {
      final similarity = StringSimilarity.compareTwoStrings(text, variation);
      if (similarity >= _similarityThreshold) {
        score += similarity * 25.0;
      }

      // Check individual words for similarity
      for (final word in words) {
        final wordSimilarity = StringSimilarity.compareTwoStrings(word, variation);
        if (wordSimilarity >= _similarityThreshold) {
          score += wordSimilarity * 15.0;
        }
      }
    }

    return score;
  }

  /// Finds which terms were matched in the text
  List<String> _findMatchedTerms(String text, Set<String> searchVariations) {
    final matched = <String>[];
    final words = text.split(RegExp(r'\s+'));

    for (final variation in searchVariations) {
      // Exact matches
      if (words.contains(variation)) {
        matched.add(variation);
        continue;
      }

      // Partial matches
      for (final word in words) {
        if (word.contains(variation) || variation.contains(word)) {
          if (StringSimilarity.compareTwoStrings(word, variation) >= _similarityThreshold) {
            matched.add(variation);
            break;
          }
        }
      }
    }

    return matched.toSet().toList(); // Remove duplicates
  }
}

/// Container for a journal entry with its searchable text
class SearchableEntry {
  final JournalEntry entry;
  final String searchableText;

  const SearchableEntry({
    required this.entry,
    required this.searchableText,
  });
}

/// Search result with relevance scoring
class JournalEntrySearchResult {
  final JournalEntry entry;
  final double relevanceScore;
  final List<String> matchedTerms;

  const JournalEntrySearchResult({
    required this.entry,
    required this.relevanceScore,
    required this.matchedTerms,
  });
}