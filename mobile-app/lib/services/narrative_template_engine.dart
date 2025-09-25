import 'dart:math';
import 'package:flutter/material.dart';
import 'daily_context_synthesizer.dart';
import 'ai_feature_extractor.dart';

/// Advanced narrative template engine for generating high-quality,
/// contextual journal narratives that feel natural and personalized
class NarrativeTemplateEngine {
  static final NarrativeTemplateEngine _instance = NarrativeTemplateEngine._internal();
  factory NarrativeTemplateEngine() => _instance;
  NarrativeTemplateEngine._internal();

  final Random _random = Random();

  /// Generate a sophisticated narrative using contextual templates
  String generateContextualNarrative(DailyContext context) {
    final template = _selectOptimalTemplate(context);
    return _populateTemplate(template, context);
  }

  /// Select the best narrative template based on context analysis
  NarrativeTemplate _selectOptimalTemplate(DailyContext context) {
    final templateScore = <NarrativeTemplate, double>{};

    for (final template in _getAllTemplates()) {
      templateScore[template] = _calculateTemplateCompatibility(template, context);
    }

    // Get the highest scoring template
    final bestTemplate = templateScore.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    debugPrint('Selected template: ${bestTemplate.name} (score: ${templateScore[bestTemplate]?.toStringAsFixed(2)})');
    return bestTemplate;
  }

  /// Calculate how well a template matches the day's context
  double _calculateTemplateCompatibility(NarrativeTemplate template, DailyContext context) {
    double score = 0.0;

    // Social compatibility
    final totalPeople = context.photoContexts.fold(0, (sum, photo) => sum + photo.faceCount);
    if (template.socialStyle == SocialStyle.social && totalPeople > 3) score += 0.3;
    if (template.socialStyle == SocialStyle.intimate && totalPeople > 0 && totalPeople <= 3) score += 0.3;
    if (template.socialStyle == SocialStyle.solo && totalPeople == 0) score += 0.3;

    // Activity compatibility
    final photoCount = context.photoContexts.length;
    final eventCount = context.calendarEvents.length;
    final totalActivity = photoCount + eventCount;

    if (template.energyLevel == EnergyLevel.high && totalActivity > 10) score += 0.25;
    if (template.energyLevel == EnergyLevel.moderate && totalActivity >= 5 && totalActivity <= 10) score += 0.25;
    if (template.energyLevel == EnergyLevel.low && totalActivity < 5) score += 0.25;

    // Environment compatibility
    final environments = context.photoContexts
        .expand((photo) => photo.sceneLabels)
        .map((label) => label.toLowerCase())
        .toSet();

    for (final env in template.preferredEnvironments) {
      if (environments.contains(env.toLowerCase())) score += 0.15;
    }

    // Confidence compatibility
    if (context.overallConfidence >= template.minConfidence) score += 0.15;

    // Mood compatibility based on context richness
    final contextRichness = (context.photoContexts.length * 0.3 +
                           context.calendarEvents.length * 0.4 +
                           context.locationPoints.length * 0.2 +
                           context.activities.length * 0.1).clamp(0.0, 1.0);

    if (template.moodTone == MoodTone.upbeat && contextRichness > 0.7) score += 0.15;
    if (template.moodTone == MoodTone.reflective && contextRichness < 0.4) score += 0.15;
    if (template.moodTone == MoodTone.balanced && contextRichness >= 0.4 && contextRichness <= 0.7) score += 0.15;

    return score.clamp(0.0, 1.0);
  }

  /// Populate a template with actual context data
  String _populateTemplate(NarrativeTemplate template, DailyContext context) {
    final variables = _extractTemplateVariables(context);
    String narrative = _selectRandomOpening(template.openings);

    // Replace variables in the narrative
    variables.forEach((key, value) {
      narrative = narrative.replaceAll('{$key}', value);
    });

    // Add body paragraphs
    final bodyParts = <String>[];
    for (final bodyTemplate in template.bodyTemplates) {
      if (_shouldIncludeBodyPart(bodyTemplate, context)) {
        String bodyPart = _selectRandomOption(bodyTemplate.options);
        variables.forEach((key, value) {
          bodyPart = bodyPart.replaceAll('{$key}', value);
        });
        bodyParts.add(bodyPart);
      }
    }

    if (bodyParts.isNotEmpty) {
      narrative += ' ${bodyParts.join(' ')}';
    }

    // Add closing
    final closing = _selectRandomOpening(template.closings);
    variables.forEach((key, value) {
      narrative = narrative.replaceAll('{$key}', value);
    });
    narrative += ' $closing';

    return narrative.trim();
  }

  /// Extract variables from context to populate templates
  Map<String, String> _extractTemplateVariables(DailyContext context) {
    final variables = <String, String>{};

    // Social variables
    final totalPeople = context.photoContexts.fold(0, (sum, photo) => sum + photo.faceCount);
    if (totalPeople == 0) {
      variables['social_context'] = 'myself';
      variables['social_descriptor'] = 'in solitude';
    } else if (totalPeople <= 2) {
      variables['social_context'] = 'close company';
      variables['social_descriptor'] = 'with someone special';
    } else if (totalPeople <= 5) {
      variables['social_context'] = 'good friends';
      variables['social_descriptor'] = 'in good company';
    } else {
      variables['social_context'] = 'a group of people';
      variables['social_descriptor'] = 'surrounded by energy';
    }

    // Activity variables
    final photoCount = context.photoContexts.length;
    if (photoCount > 10) {
      variables['activity_level'] = 'eventful';
      variables['pace'] = 'dynamic';
    } else if (photoCount > 5) {
      variables['activity_level'] = 'engaging';
      variables['pace'] = 'steady';
    } else {
      variables['activity_level'] = 'peaceful';
      variables['pace'] = 'gentle';
    }

    // Environment variables
    final environments = context.photoContexts
        .expand((photo) => photo.sceneLabels)
        .map((label) => label.toLowerCase())
        .toSet();

    if (environments.contains('outdoor') || environments.contains('nature')) {
      variables['primary_environment'] = 'outdoors';
      variables['environment_feeling'] = 'refreshing';
    } else if (environments.contains('restaurant') || environments.contains('cafe')) {
      variables['primary_environment'] = 'cozy spaces';
      variables['environment_feeling'] = 'nourishing';
    } else if (environments.contains('home')) {
      variables['primary_environment'] = 'home';
      variables['environment_feeling'] = 'comfortable';
    } else {
      variables['primary_environment'] = 'various spaces';
      variables['environment_feeling'] = 'interesting';
    }

    // Time-based variables
    final hour = context.date.hour;
    if (hour < 12) {
      variables['time_period'] = 'morning';
      variables['time_feeling'] = 'fresh';
    } else if (hour < 17) {
      variables['time_period'] = 'afternoon';
      variables['time_feeling'] = 'productive';
    } else {
      variables['time_period'] = 'evening';
      variables['time_feeling'] = 'reflective';
    }

    // Enhanced written content variables for narrative depth
    if (context.writtenContentSummary.hasSignificantContent) {
      final themes = context.writtenContentSummary.significantThemes;
      final tones = context.writtenContentSummary.emotionalTones;
      final dominantTone = tones.entries.fold<MapEntry<String, int>?>(null, (prev, curr) {
        return prev == null || curr.value > prev.value ? curr : prev;
      });

      if (themes.contains('work')) {
        variables['content_focus'] = 'professional reflections';
        variables['thought_quality'] = 'productive thinking';
      } else if (themes.contains('relationships')) {
        variables['content_focus'] = 'personal connections';
        variables['thought_quality'] = 'meaningful interactions';
      } else if (themes.contains('nature')) {
        variables['content_focus'] = 'natural observations';
        variables['thought_quality'] = 'mindful presence';
      } else {
        variables['content_focus'] = 'thoughtful observations';
        variables['thought_quality'] = 'reflective insights';
      }

      if (dominantTone != null) {
        switch (dominantTone.key) {
          case 'positive':
            variables['emotional_tenor'] = 'uplifting';
            variables['content_mood'] = 'optimistic reflections';
            break;
          case 'reflective':
            variables['emotional_tenor'] = 'contemplative';
            variables['content_mood'] = 'thoughtful musings';
            break;
          case 'negative':
            variables['emotional_tenor'] = 'processing challenges';
            variables['content_mood'] = 'working through difficulties';
            break;
          default:
            variables['emotional_tenor'] = 'authentic';
            variables['content_mood'] = 'genuine thoughts';
        }
      } else {
        variables['emotional_tenor'] = 'authentic';
        variables['content_mood'] = 'genuine thoughts';
      }

      variables['writing_depth'] = context.writtenContentSummary.totalWrittenEntries > 5
          ? 'extensively'
          : context.writtenContentSummary.totalWrittenEntries > 2
              ? 'thoughtfully'
              : 'briefly';

      variables['content_richness'] = themes.length > 3
          ? 'covering many aspects of life'
          : themes.length > 1
              ? 'exploring various themes'
              : 'focusing on specific experiences';
    } else {
      variables['content_focus'] = 'lived experiences';
      variables['thought_quality'] = 'present moment awareness';
      variables['emotional_tenor'] = 'natural';
      variables['content_mood'] = 'spontaneous moments';
      variables['writing_depth'] = 'organically';
      variables['content_richness'] = 'through direct experience';
    }

    // Proximity and location awareness variables
    if (context.proximitySummary.hasProximityInteractions) {
      final transitions = context.proximitySummary.geofenceTransitions;
      final dwellTimes = context.proximitySummary.locationDwellTimes;
      final locations = context.proximitySummary.frequentProximityLocations;

      if (transitions.any((t) => t.contains('enter'))) {
        variables['location_interaction'] = 'arriving at meaningful places';
        variables['place_connection'] = 'connecting with familiar spaces';
      } else if (transitions.any((t) => t.contains('dwell'))) {
        variables['location_interaction'] = 'settling into important locations';
        variables['place_connection'] = 'spending quality time in chosen spaces';
      } else {
        variables['location_interaction'] = 'moving through various locations';
        variables['place_connection'] = 'experiencing different environments';
      }

      final totalDwellMinutes = dwellTimes.values.fold(0, (sum, d) => sum + d.inMinutes);
      if (totalDwellMinutes > 120) {
        variables['location_depth'] = 'deeply immersed in specific places';
      } else if (totalDwellMinutes > 30) {
        variables['location_depth'] = 'spending focused time in key locations';
      } else {
        variables['location_depth'] = 'briefly engaging with various spaces';
      }

      if (locations.length > 3) {
        variables['place_variety'] = 'exploring diverse locations';
      } else if (locations.length > 1) {
        variables['place_variety'] = 'moving between familiar places';
      } else {
        variables['place_variety'] = 'centered in one meaningful space';
      }
    } else {
      variables['location_interaction'] = 'naturally moving through space';
      variables['place_connection'] = 'organically engaging with surroundings';
      variables['location_depth'] = 'flowing through different areas';
      variables['place_variety'] = 'experiencing the day\'s geography';
    }

    // Enhanced movement variables for dynamic narrative generation
    if (context.movementData.isNotEmpty) {
      // Calculate detailed movement statistics
      double totalWalking = 0;
      double totalRunning = 0;
      double totalDriving = 0;
      double totalStill = 0;
      double totalActivity = 0;

      for (final data in context.movementData) {
        totalWalking += data.walkingPercentage;
        totalRunning += data.runningPercentage;
        totalDriving += data.drivingPercentage;
        totalStill += data.stillPercentage;
        totalActivity += data.averageMagnitude;
      }

      final count = context.movementData.length;
      final avgWalking = totalWalking / count;
      final avgRunning = totalRunning / count;
      final avgDriving = totalDriving / count;
      final avgStill = totalStill / count;
      final avgActivity = totalActivity / count;
      final avgMovement = 100 - avgStill;

      // Primary movement type and descriptors
      if (avgRunning > 10) {
        variables['movement_type'] = 'running';
        variables['movement_style'] = 'vigorously';
        variables['energy_descriptor'] = 'high-energy';
        variables['movement_narrative'] = 'pushing physical boundaries';
        variables['movement_metaphor'] = 'like wind through the streets';
      } else if (avgWalking > 30) {
        variables['movement_type'] = 'walking';
        variables['movement_style'] = 'actively';
        variables['energy_descriptor'] = 'energetic';
        variables['movement_narrative'] = 'exploring on foot';
        variables['movement_metaphor'] = 'finding rhythm in each step';
      } else if (avgDriving > 30) {
        variables['movement_type'] = 'driving';
        variables['movement_style'] = 'purposefully';
        variables['energy_descriptor'] = 'mobile';
        variables['movement_narrative'] = 'journeying between destinations';
        variables['movement_metaphor'] = 'navigating life\'s pathways';
      } else if (avgMovement > 40) {
        variables['movement_type'] = 'mixed';
        variables['movement_style'] = 'variedly';
        variables['energy_descriptor'] = 'dynamic';
        variables['movement_narrative'] = 'alternating between motion and stillness';
        variables['movement_metaphor'] = 'dancing through different rhythms';
      } else if (avgMovement > 20) {
        variables['movement_type'] = 'moderate';
        variables['movement_style'] = 'gently';
        variables['energy_descriptor'] = 'balanced';
        variables['movement_narrative'] = 'moving with intention';
        variables['movement_metaphor'] = 'flowing like a calm river';
      } else {
        variables['movement_type'] = 'minimal';
        variables['movement_style'] = 'peacefully';
        variables['energy_descriptor'] = 'contemplative';
        variables['movement_narrative'] = 'embracing stillness';
        variables['movement_metaphor'] = 'rooted like a tree';
      }

      // Activity intensity
      if (avgActivity > 2.0) {
        variables['activity_intensity'] = 'intense';
        variables['physical_engagement'] = 'highly physical';
      } else if (avgActivity > 1.0) {
        variables['activity_intensity'] = 'moderate';
        variables['physical_engagement'] = 'physically engaged';
      } else if (avgActivity > 0.5) {
        variables['activity_intensity'] = 'light';
        variables['physical_engagement'] = 'gently active';
      } else {
        variables['activity_intensity'] = 'minimal';
        variables['physical_engagement'] = 'restful';
      }

      // Movement duration descriptors
      if (avgMovement > 70) {
        variables['movement_duration'] = 'throughout most of the day';
      } else if (avgMovement > 40) {
        variables['movement_duration'] = 'for significant portions';
      } else if (avgMovement > 20) {
        variables['movement_duration'] = 'in measured moments';
      } else {
        variables['movement_duration'] = 'briefly';
      }
    } else {
      // Default values when no movement data
      variables['movement_type'] = 'unmeasured';
      variables['movement_style'] = 'naturally';
      variables['energy_descriptor'] = 'flowing';
      variables['movement_narrative'] = 'moving through the day';
      variables['movement_metaphor'] = 'finding my own pace';
      variables['activity_intensity'] = 'varied';
      variables['physical_engagement'] = 'as needed';
      variables['movement_duration'] = 'as moments called for it';
    }

    return variables;
  }

  /// Check if a body part should be included based on context
  bool _shouldIncludeBodyPart(BodyTemplate bodyTemplate, DailyContext context) {
    switch (bodyTemplate.type) {
      case BodyType.social:
        return context.photoContexts.any((photo) => photo.faceCount > 0) ||
               context.calendarEvents.any((event) => event.attendees.isNotEmpty);
      case BodyType.activity:
        return context.photoContexts.length > 3 ||
               context.calendarEvents.length > 1 ||
               context.activities.length > 5;
      case BodyType.environment:
        return context.photoContexts.isNotEmpty ||
               context.locationPoints.isNotEmpty;
      case BodyType.reflection:
        return true; // Always include reflection
      case BodyType.movement:
        return context.movementData.isNotEmpty;
      case BodyType.content:
        return context.writtenContentSummary.hasSignificantContent;
      case BodyType.proximity:
        return context.proximitySummary.hasProximityInteractions;
    }
  }

  /// Select a random option from a list
  String _selectRandomOption(List<String> options) {
    if (options.isEmpty) return '';
    return options[_random.nextInt(options.length)];
  }

  /// Select a random opening from a list
  String _selectRandomOpening(List<String> openings) {
    return _selectRandomOption(openings);
  }

  /// Get all available narrative templates
  List<NarrativeTemplate> _getAllTemplates() {
    return [
      _createActiveAndSocialTemplate(),
      _createPeacefulSoloTemplate(),
      _createBalancedDayTemplate(),
      _createOutdoorAdventureTemplate(),
      _createCozyIndoorTemplate(),
      _createBusyProductiveTemplate(),
      _createReflectiveQuietTemplate(),
    ];
  }

  /// Template for active, social days
  NarrativeTemplate _createActiveAndSocialTemplate() {
    return NarrativeTemplate(
      name: 'Active and Social',
      socialStyle: SocialStyle.social,
      energyLevel: EnergyLevel.high,
      moodTone: MoodTone.upbeat,
      minConfidence: 0.6,
      preferredEnvironments: ['outdoor', 'restaurant', 'social'],
      openings: [
        'Today was alive with energy and connection.',
        'The day brought together wonderful moments and {social_context}.',
        'An {activity_level} day filled with shared experiences and laughter.',
        'Energy and joy defined this beautifully {pace} day.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.social,
          options: [
            'Spending time {social_descriptor} created moments of genuine connection and warmth.',
            'The company of {social_context} brought out the best in the day.',
            'Shared conversations and experiences with {social_context} made everything more meaningful.',
          ],
        ),
        BodyTemplate(
          type: BodyType.activity,
          options: [
            'Moving {movement_style} through different activities kept the energy flowing.',
            'Each activity transitioned naturally into the next, creating a wonderful rhythm.',
            'The {pace} nature of the day allowed for both engagement and enjoyment.',
          ],
        ),
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The {primary_environment} provided the perfect backdrop for these {environment_feeling} experiences.',
            'Being in {primary_environment} enhanced every moment with its {environment_feeling} atmosphere.',
          ],
        ),
        BodyTemplate(
          type: BodyType.movement,
          options: [
            '{movement_narrative} {movement_duration}, {movement_metaphor}.',
            'My {movement_type} brought a sense of {energy_descriptor} engagement to the day.',
            'The {activity_intensity} physical activity added depth to today\'s experiences.',
            'Moving {movement_style} felt perfectly aligned with the day\'s {pace} rhythm.',
          ],
        ),
        BodyTemplate(
          type: BodyType.content,
          options: [
            'Capturing {content_focus} through {writing_depth} written reflections added layers of meaning.',
            'The {emotional_tenor} quality of today\'s {content_mood} provided insight into the deeper currents.',
            'Taking time for {thought_quality} created space for {content_richness}.',
            'Written thoughts today were {writing_depth} {emotional_tenor}, {content_richness}.',
          ],
        ),
        BodyTemplate(
          type: BodyType.proximity,
          options: [
            '{location_interaction} created a strong sense of {place_connection}.',
            'The experience of {location_depth} added richness to the day\'s spatial story.',
            'Time spent {place_variety} brought awareness of how places shape experience.',
            'Moving through space with intention, {location_interaction} and {place_connection}.',
          ],
        ),
      ],
      closings: [
        'A day that reminded me of the joy found in active engagement with life and others.',
        'These moments of connection and energy will stay with me.',
        'Sometimes the best days are the ones filled with people, activity, and shared joy.',
      ],
    );
  }

  /// Template for peaceful, solo days
  NarrativeTemplate _createPeacefulSoloTemplate() {
    return NarrativeTemplate(
      name: 'Peaceful Solo',
      socialStyle: SocialStyle.solo,
      energyLevel: EnergyLevel.low,
      moodTone: MoodTone.reflective,
      minConfidence: 0.3,
      preferredEnvironments: ['home', 'nature', 'quiet'],
      openings: [
        'Today offered the gift of solitude and quiet reflection.',
        'A {energy_descriptor} day spent in my own company brought unexpected insights.',
        'The gentle rhythm of a solo day allowed for deep presence and awareness.',
        'Sometimes the most meaningful days are spent {social_descriptor}.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.reflection,
          options: [
            'Moving {movement_style} through the day, I found space for thoughts to settle and clarity to emerge.',
            'The {time_period} hours passed with a natural {pace} that felt perfectly aligned.',
            'In the quieter moments, I discovered the value of simply being present.',
            'Taking time for {content_focus} revealed the {emotional_tenor} threads running through today.',
            'The practice of {thought_quality} brought deeper awareness to the day\'s unfolding.',
          ],
        ),
        BodyTemplate(
          type: BodyType.content,
          options: [
            'Written reflections today were {emotional_tenor}, offering {content_richness}.',
            'Capturing {content_mood} through {writing_depth} observation added contemplative depth.',
            'The quality of {thought_quality} enhanced the solitary experience with meaningful insight.',
          ],
        ),
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The {environment_feeling} quality of {primary_environment} supported this introspective mood.',
            'Being in {primary_environment} created the perfect container for solitude and peace.',
          ],
        ),
      ],
      closings: [
        'Days like this remind me that solitude can be profoundly nourishing.',
        'The quiet moments often hold the most wisdom.',
        'In stillness and solitude, life reveals its subtle gifts.',
      ],
    );
  }

  /// Template for balanced, typical days
  NarrativeTemplate _createBalancedDayTemplate() {
    return NarrativeTemplate(
      name: 'Balanced Day',
      socialStyle: SocialStyle.mixed,
      energyLevel: EnergyLevel.moderate,
      moodTone: MoodTone.balanced,
      minConfidence: 0.4,
      preferredEnvironments: ['home', 'work', 'mixed'],
      openings: [
        'Today found its own natural balance between activity and rest.',
        'A wonderfully {energy_descriptor} day that included both connection and solitude.',
        'The day unfolded with a {pace} rhythm that felt just right.',
        'Balance defined this {activity_level} and satisfying day.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.activity,
          options: [
            'The mix of activities created a nice variety without feeling overwhelming.',
            'Moving {movement_style} between different parts of the day maintained good energy.',
            'Each phase of the day contributed its own character to the whole experience.',
          ],
        ),
        BodyTemplate(
          type: BodyType.social,
          options: [
            'Time spent both {social_descriptor} and alone provided the perfect social balance.',
            'Moments with {social_context} complemented periods of personal reflection beautifully.',
          ],
        ),
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The variety of {primary_environment} kept things interesting and {environment_feeling}.',
            'Each environment visited today offered its own unique contribution to the day\'s character.',
          ],
        ),
      ],
      closings: [
        'Sometimes the most satisfying days are the ones that feel naturally balanced.',
        'A good reminder that variety and balance create their own kind of richness.',
        'Days like this form the comfortable foundation of a well-lived life.',
      ],
    );
  }

  /// Additional specialized templates for outdoor adventures
  NarrativeTemplate _createOutdoorAdventureTemplate() {
    return NarrativeTemplate(
      name: 'Outdoor Adventure',
      socialStyle: SocialStyle.mixed,
      energyLevel: EnergyLevel.high,
      moodTone: MoodTone.upbeat,
      minConfidence: 0.5,
      preferredEnvironments: ['outdoor', 'nature', 'park'],
      openings: [
        'The call of the outdoors shaped this beautifully adventurous day.',
        'Fresh air and open spaces provided the perfect backdrop for today\'s experiences.',
        'Nature offered its gifts generously throughout this {energy_descriptor} day.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The {environment_feeling} energy of being {primary_environment} renewed my spirit.',
            'Each moment spent in nature felt like a small gift of freedom and clarity.',
            'The natural world provided both challenge and restoration in perfect measure.',
          ],
        ),
        BodyTemplate(
          type: BodyType.movement,
          options: [
            'Moving {movement_style} through natural spaces felt both grounding and energizing.',
            'Physical activity in the outdoors created the perfect combination of effort and joy.',
          ],
        ),
      ],
      closings: [
        'Days spent outdoors always remind me of life\'s fundamental simplicities.',
        'Nature has a way of putting everything into perspective.',
        'The outdoors continues to be a source of renewal and inspiration.',
      ],
    );
  }

  /// Template for cozy indoor days
  NarrativeTemplate _createCozyIndoorTemplate() {
    return NarrativeTemplate(
      name: 'Cozy Indoor',
      socialStyle: SocialStyle.intimate,
      energyLevel: EnergyLevel.low,
      moodTone: MoodTone.reflective,
      minConfidence: 0.4,
      preferredEnvironments: ['home', 'indoor', 'cafe'],
      openings: [
        'The comfort of indoor spaces defined this perfectly cozy day.',
        'Today found its rhythm in the warm embrace of familiar, comfortable places.',
        'Sometimes the most nurturing days are spent in {environment_feeling} indoor sanctuaries.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The {environment_feeling} atmosphere of {primary_environment} created the perfect mood.',
            'Being surrounded by comfortable, familiar spaces enhanced every moment.',
            'Indoor sanctuaries provided exactly the kind of nurturing energy needed today.',
          ],
        ),
        BodyTemplate(
          type: BodyType.social,
          options: [
            'Sharing these cozy moments {social_descriptor} made them even more special.',
            'The intimacy of indoor spaces enhanced the quality of time spent with {social_context}.',
          ],
        ),
      ],
      closings: [
        'Cozy days like this remind me of the simple pleasure of comfort and warmth.',
        'The best moments sometimes happen in the most familiar places.',
        'Indoor sanctuaries have their own special way of nurturing the soul.',
      ],
    );
  }

  /// Template for busy, productive days
  NarrativeTemplate _createBusyProductiveTemplate() {
    return NarrativeTemplate(
      name: 'Busy Productive',
      socialStyle: SocialStyle.mixed,
      energyLevel: EnergyLevel.high,
      moodTone: MoodTone.balanced,
      minConfidence: 0.6,
      preferredEnvironments: ['work', 'office', 'meetings'],
      openings: [
        'Productivity and purpose drove this satisfyingly busy day.',
        'A day filled with meaningful tasks and accomplishments.',
        'The energy of focused work created a sense of momentum and achievement.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.activity,
          options: [
            'Moving {movement_style} between different responsibilities maintained good focus.',
            'Each task completed built toward a growing sense of accomplishment.',
            'The {pace} nature of the day allowed for both efficiency and thoroughness.',
          ],
        ),
        BodyTemplate(
          type: BodyType.social,
          options: [
            'Collaboration with {social_context} added depth and richness to the work.',
            'Professional interactions brought both challenge and satisfaction.',
          ],
        ),
      ],
      closings: [
        'Busy days like this remind me of the satisfaction found in purposeful work.',
        'There\'s something deeply satisfying about a day filled with meaningful productivity.',
        'The combination of focus and accomplishment creates its own kind of fulfillment.',
      ],
    );
  }

  /// Template for reflective, quiet days
  NarrativeTemplate _createReflectiveQuietTemplate() {
    return NarrativeTemplate(
      name: 'Reflective Quiet',
      socialStyle: SocialStyle.solo,
      energyLevel: EnergyLevel.low,
      moodTone: MoodTone.reflective,
      minConfidence: 0.3,
      preferredEnvironments: ['home', 'quiet', 'peaceful'],
      openings: [
        'Quiet contemplation and gentle awareness shaped this thoughtful day.',
        'Today offered the rare gift of unhurried time for reflection and presence.',
        'The softer rhythms of a quiet day allowed for deeper listening and awareness.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.reflection,
          options: [
            'Moving {movement_style} through the hours, I found space for thoughts to unfold naturally.',
            'The {time_period} brought its own quality of light and introspection.',
            'In the absence of rush, deeper truths and insights had room to emerge.',
            'Time for {content_focus} opened doorways to {emotional_tenor} understanding.',
            'The practice of {thought_quality} in quiet spaces yielded {content_richness}.',
          ],
        ),
        BodyTemplate(
          type: BodyType.content,
          options: [
            'Written thoughts emerged {writing_depth}, {emotional_tenor} in their honesty.',
            'Capturing {content_mood} added layers of meaning to the contemplative experience.',
            'The depth of {thought_quality} transformed simple moments into rich reflection.',
          ],
        ),
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The {environment_feeling} quality of {primary_environment} supported this contemplative mood.',
            'Quiet spaces have their own way of inviting deeper awareness and presence.',
          ],
        ),
      ],
      closings: [
        'Quiet days remind me that not all valuable experiences are dramatic or eventful.',
        'Sometimes the most important growth happens in the spaces between activities.',
        'The gentle rhythms of contemplation have their own profound gifts to offer.',
      ],
    );
  }
}

/// Represents a narrative template with specific characteristics
class NarrativeTemplate {
  final String name;
  final SocialStyle socialStyle;
  final EnergyLevel energyLevel;
  final MoodTone moodTone;
  final double minConfidence;
  final List<String> preferredEnvironments;
  final List<String> openings;
  final List<BodyTemplate> bodyTemplates;
  final List<String> closings;

  NarrativeTemplate({
    required this.name,
    required this.socialStyle,
    required this.energyLevel,
    required this.moodTone,
    required this.minConfidence,
    required this.preferredEnvironments,
    required this.openings,
    required this.bodyTemplates,
    required this.closings,
  });
}

/// Body template for specific sections of narrative
class BodyTemplate {
  final BodyType type;
  final List<String> options;

  BodyTemplate({
    required this.type,
    required this.options,
  });
}

/// Social style categories
enum SocialStyle { solo, intimate, social, mixed }

/// Energy level categories
enum EnergyLevel { low, moderate, high }

/// Mood tone categories
enum MoodTone { reflective, balanced, upbeat }

/// Body section types
enum BodyType { social, activity, environment, reflection, movement, content, proximity }