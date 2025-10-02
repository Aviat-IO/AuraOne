import '../utils/logger.dart';
import 'emotional_tone_analyzer.dart';

/// Adjusts narrative phrasing based on emotional tone
///
/// Uses EmotionalProfile to select tone-appropriate language for different
/// aspects of the narrative (verbs, adjectives, transitions) to match the
/// emotional character of the day.
class PersonalityEngine {
  static final _logger = AppLogger('PersonalityEngine');
  static final PersonalityEngine _instance = PersonalityEngine._internal();

  factory PersonalityEngine() => _instance;
  PersonalityEngine._internal();

  /// Adjust opening phrase based on emotional tone
  String adjustOpening(String baseOpening, EmotionalProfile profile) {
    final tone = profile.primaryTone;

    switch (tone) {
      case EmotionalTone.energetic:
        return _makeEnergetic(baseOpening);
      case EmotionalTone.social:
        return _makeSocial(baseOpening);
      case EmotionalTone.contemplative:
        return _makeContemplative(baseOpening);
      case EmotionalTone.adventurous:
        return _makeAdventurous(baseOpening);
    }
  }

  /// Adjust transition phrase based on emotional tone
  String adjustTransition(String baseTransition, EmotionalProfile profile) {
    final tone = profile.primaryTone;

    // High-energy days get more dynamic transitions
    if (profile.energy > 70) {
      return _energizeTransition(baseTransition);
    }

    // Contemplative days get softer transitions
    if (profile.contemplative > 70) {
      return _softEnTransition(baseTransition);
    }

    return baseTransition;
  }

  /// Adjust action verbs based on emotional tone
  String adjustActionVerb(String verb, EmotionalProfile profile) {
    final verbMap = _getVerbMapForProfile(profile);
    return verbMap[verb] ?? verb;
  }

  /// Adjust closing based on emotional tone
  String adjustClosing(String baseClosing, EmotionalProfile profile) {
    final tone = profile.primaryTone;

    switch (tone) {
      case EmotionalTone.energetic:
        return _makeEnergeticClosing(baseClosing);
      case EmotionalTone.social:
        return _makeSocialClosing(baseClosing);
      case EmotionalTone.contemplative:
        return _makeContemplativeClosing(baseClosing);
      case EmotionalTone.adventurous:
        return _makeAdventurousClosing(baseClosing);
    }
  }

  /// Make opening more energetic
  String _makeEnergetic(String opening) {
    return opening
        .replaceAll('began', 'kicked off')
        .replaceAll('started', 'launched into')
        .replaceAll('found me', 'found me energized')
        .replaceAll('arrived', 'burst into');
  }

  /// Make opening more social
  String _makeSocial(String opening) {
    return opening
        .replaceAll('began', 'welcomed me')
        .replaceAll('started', 'opened with connections')
        .replaceAll('found me', 'brought me together');
  }

  /// Make opening more contemplative
  String _makeContemplative(String opening) {
    return opening
        .replaceAll('began', 'unfolded gently')
        .replaceAll('started', 'dawned peacefully')
        .replaceAll('found me', 'settled me')
        .replaceAll('arrived', 'emerged softly');
  }

  /// Make opening more adventurous
  String _makeAdventurous(String opening) {
    return opening
        .replaceAll('began', 'set off')
        .replaceAll('started', 'ventured into')
        .replaceAll('found me', 'led me to explore')
        .replaceAll('arrived', 'discovered');
  }

  /// Energize transition phrase
  String _energizeTransition(String transition) {
    return transition
        .replaceAll('Moments later', 'In a flash')
        .replaceAll('Shortly after', 'Soon')
        .replaceAll('A little while later', 'Before long')
        .replaceAll('Some time later', 'Next')
        .replaceAll('An hour later', 'An hour on')
        .replaceAll('Later that day', 'As the day progressed');
  }

  /// Soften transition phrase for contemplative tone
  String _softEnTransition(String transition) {
    return transition
        .replaceAll('Moments later', 'A moment passed')
        .replaceAll('Shortly after', 'After a pause')
        .replaceAll('A little while later', 'In time')
        .replaceAll('Some time later', 'As time unfolded')
        .replaceAll('An hour later', 'An hour drifted by')
        .replaceAll('Later that day', 'Later in the day\'s rhythm');
  }

  /// Get verb mapping for emotional profile
  Map<String, String> _getVerbMapForProfile(EmotionalProfile profile) {
    final tone = profile.primaryTone;

    switch (tone) {
      case EmotionalTone.energetic:
        return {
          'went': 'rushed',
          'walked': 'strode',
          'traveled': 'sped',
          'moved': 'dashed',
          'arrived': 'burst in',
          'visited': 'hit up',
          'attended': 'dove into',
        };

      case EmotionalTone.social:
        return {
          'went': 'headed over',
          'walked': 'strolled',
          'traveled': 'made my way',
          'moved': 'connected with',
          'arrived': 'joined',
          'visited': 'met up at',
          'attended': 'gathered for',
        };

      case EmotionalTone.contemplative:
        return {
          'went': 'drifted to',
          'walked': 'wandered',
          'traveled': 'journeyed',
          'moved': 'flowed',
          'arrived': 'settled at',
          'visited': 'found myself at',
          'attended': 'was present for',
        };

      case EmotionalTone.adventurous:
        return {
          'went': 'ventured',
          'walked': 'explored',
          'traveled': 'trekked',
          'moved': 'navigated',
          'arrived': 'discovered',
          'visited': 'explored',
          'attended': 'embarked on',
        };
    }
  }

  /// Make closing more energetic
  String _makeEnergeticClosing(String closing) {
    return closing
        .replaceAll('A day where', 'A dynamic day where')
        .replaceAll('A quiet day', 'A restful day')
        .replaceAll('stayed', 'powered through')
        .replaceAll('traveled', 'covered ground')
        .replaceAll('captured', 'seized');
  }

  /// Make closing more social
  String _makeSocialClosing(String closing) {
    return closing
        .replaceAll('A day where', 'A connected day where')
        .replaceAll('A quiet day', 'A peaceful day')
        .replaceAll('attended', 'connected at')
        .replaceAll('captured', 'shared');
  }

  /// Make closing more contemplative
  String _makeContemplativeClosing(String closing) {
    return closing
        .replaceAll('A day where', 'A reflective day where')
        .replaceAll('stayed', 'remained')
        .replaceAll('traveled', 'wandered')
        .replaceAll('captured', 'contemplated')
        .replaceAll('attended', 'was present at');
  }

  /// Make closing more adventurous
  String _makeAdventurousClosing(String closing) {
    return closing
        .replaceAll('A day where', 'An exploratory day where')
        .replaceAll('A quiet day', 'A day of discovery')
        .replaceAll('traveled', 'explored')
        .replaceAll('captured', 'discovered')
        .replaceAll('attended', 'ventured into');
  }

  /// Get descriptive adjectives for emotional tone
  List<String> getDescriptiveAdjectives(EmotionalProfile profile) {
    final tone = profile.primaryTone;

    switch (tone) {
      case EmotionalTone.energetic:
        return ['dynamic', 'active', 'lively', 'vibrant', 'spirited'];
      case EmotionalTone.social:
        return ['connected', 'engaging', 'warm', 'convivial', 'friendly'];
      case EmotionalTone.contemplative:
        return ['reflective', 'peaceful', 'serene', 'thoughtful', 'quiet'];
      case EmotionalTone.adventurous:
        return ['exploratory', 'bold', 'curious', 'daring', 'venturesome'];
    }
  }

  /// Get intensity modifier based on emotional intensity
  String getIntensityModifier(EmotionalProfile profile) {
    final intensity = profile.intensity;

    if (intensity > 0.8) {
      return 'very';
    } else if (intensity > 0.6) {
      return 'quite';
    } else if (intensity > 0.4) {
      return 'somewhat';
    } else {
      return '';
    }
  }
}
