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

    // Select and populate opening, skipping if missing variables
    String narrative = '';
    final openings = List<String>.from(template.openings);
    openings.shuffle(_random);

    // Try to find an opening that has all required variables
    for (final opening in openings) {
      final requiredVars = _extractRequiredVariables(opening);
      if (_hasAllVariables(requiredVars, variables)) {
        narrative = _populateString(opening, variables);
        break;
      }
    }

    // Fallback to a simple opening if none work
    if (narrative.isEmpty) {
      narrative = 'Today brought its own unique moments and experiences.';
    }

    // Add body paragraphs, only if their variables are available
    final bodyParts = <String>[];
    for (final bodyTemplate in template.bodyTemplates) {
      if (_shouldIncludeBodyPart(bodyTemplate, context)) {
        // Try each option until we find one with all variables
        final options = List<String>.from(bodyTemplate.options);
        options.shuffle(_random);

        for (final option in options) {
          final requiredVars = _extractRequiredVariables(option);
          if (_hasAllVariables(requiredVars, variables)) {
            final populatedPart = _populateString(option, variables);
            bodyParts.add(populatedPart);
            break; // Use the first valid option
          }
        }
      }
    }

    if (bodyParts.isNotEmpty) {
      // Select 2-3 random body parts for variety
      final partsToUse = bodyParts.length > 3 ? 3 : bodyParts.length;
      bodyParts.shuffle(_random);
      narrative += ' ${bodyParts.take(partsToUse).join(' ')}';
    }

    // Try to add closing if available
    if (template.closings.isNotEmpty) {
      final closings = List<String>.from(template.closings);
      closings.shuffle(_random);

      for (final closing in closings) {
        final requiredVars = _extractRequiredVariables(closing);
        if (_hasAllVariables(requiredVars, variables)) {
          narrative += ' ${_populateString(closing, variables)}';
          break;
        }
      }
    }

    return narrative.trim();
  }

  /// Extract required variables from a template string
  Set<String> _extractRequiredVariables(String template) {
    final pattern = RegExp(r'\{([^}]+)\}');
    final matches = pattern.allMatches(template);
    return matches.map((m) => m.group(1)!).toSet();
  }

  /// Check if all required variables are present
  bool _hasAllVariables(Set<String> required, Map<String, String> available) {
    return required.every((v) => available.containsKey(v) && available[v]!.isNotEmpty);
  }

  /// Populate a string with available variables
  String _populateString(String template, Map<String, String> variables) {
    String result = template;
    variables.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  /// Extract template variables from context - only include available data
  Map<String, String> _extractTemplateVariables(DailyContext context) {
    final variables = <String, String>{};

    try {
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
      variables['social_descriptor'] = 'among friends';
    } else {
      variables['social_context'] = 'many people';
      variables['social_descriptor'] = 'in a crowd';
    }

    // Activity variables
    final photoCount = context.photoContexts.length;
    final eventCount = context.calendarEvents.length;
    final totalActivity = photoCount + eventCount;

    if (totalActivity > 15) {
      variables['activity_level'] = 'exceptionally active';
      variables['pace'] = 'energetic';
    } else if (totalActivity > 10) {
      variables['activity_level'] = 'very active';
      variables['pace'] = 'dynamic';
    } else if (totalActivity > 5) {
      variables['activity_level'] = 'moderately active';
      variables['pace'] = 'steady';
    } else {
      variables['activity_level'] = 'peaceful';
      variables['pace'] = 'relaxed';
    }

    // Environment variables
    final environments = context.photoContexts
        .expand((photo) => photo.sceneLabels)
        .toList();

    if (environments.isNotEmpty) {
      // Determine primary environment
      final envCount = <String, int>{};
      for (final env in environments) {
        envCount[env.toLowerCase()] = (envCount[env.toLowerCase()] ?? 0) + 1;
      }
      final primaryEnv = envCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      variables['primary_environment'] = primaryEnv;

      // Determine environment feeling
      if (primaryEnv.contains('home') || primaryEnv.contains('indoor')) {
        variables['environment_feeling'] = 'cozy';
      } else if (primaryEnv.contains('nature') || primaryEnv.contains('outdoor')) {
        variables['environment_feeling'] = 'refreshing';
      } else if (primaryEnv.contains('urban') || primaryEnv.contains('city')) {
        variables['environment_feeling'] = 'vibrant';
      } else {
        variables['environment_feeling'] = 'interesting';
      }
    }

    // Written content variables
    if (context.writtenContentSummary != null && context.writtenContentSummary.hasSignificantContent) {
      try {
      final themes = context.writtenContentSummary.significantThemes;
      final dominantTone = context.writtenContentSummary.emotionalTones.isNotEmpty
          ? context.writtenContentSummary.emotionalTones.entries
              .reduce((a, b) => a.value > b.value ? a : b)
          : null;

      if (themes.contains('family')) {
        variables['content_focus'] = 'family moments';
        variables['thought_quality'] = 'warm reflections';
      } else if (themes.contains('work')) {
        variables['content_focus'] = 'professional growth';
        variables['thought_quality'] = 'productive thoughts';
      } else if (themes.contains('personal')) {
        variables['content_focus'] = 'personal connections';
        variables['thought_quality'] = 'meaningful interactions';
      } else if (themes.contains('nature')) {
        variables['content_focus'] = 'natural observations';
        variables['thought_quality'] = 'mindful presence';
      } else if (themes.isNotEmpty) {
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
      }

      if (context.writtenContentSummary.totalWrittenEntries > 5) {
        variables['writing_depth'] = 'extensively';
      } else if (context.writtenContentSummary.totalWrittenEntries > 2) {
        variables['writing_depth'] = 'thoughtfully';
      } else if (context.writtenContentSummary.totalWrittenEntries > 0) {
        variables['writing_depth'] = 'briefly';
      }

      if (themes.length > 3) {
        variables['content_richness'] = 'covering many aspects of life';
      } else if (themes.length > 1) {
        variables['content_richness'] = 'exploring various themes';
      } else if (themes.length == 1) {
        variables['content_richness'] = 'focusing on specific experiences';
      }
      } catch (e) {
        debugPrint('Error extracting written content variables: $e');
        // Don't add default values - let the template selection skip these
      }
    }
    // Don't add defaults if no written content

    // Proximity and location awareness variables
    if (context.proximitySummary != null && context.proximitySummary.hasProximityInteractions) {
      try {
      final transitions = context.proximitySummary.geofenceTransitions;
      final dwellTimes = context.proximitySummary.locationDwellTimes;
      final locations = context.proximitySummary.frequentProximityLocations;

      if (transitions.any((t) => t.contains('enter'))) {
        variables['location_interaction'] = 'arriving at meaningful places';
        variables['place_connection'] = 'connecting with familiar spaces';
      } else if (transitions.any((t) => t.contains('dwell'))) {
        variables['location_interaction'] = 'settling into important locations';
        variables['place_connection'] = 'spending quality time in chosen spaces';
      } else if (transitions.isNotEmpty) {
        variables['location_interaction'] = 'moving through various locations';
        variables['place_connection'] = 'experiencing different environments';
      }

      final totalDwellMinutes = dwellTimes.values.fold<int>(0, (sum, d) => sum + d.inMinutes);
      if (totalDwellMinutes > 120) {
        variables['location_depth'] = 'deeply immersed in specific places';
      } else if (totalDwellMinutes > 30) {
        variables['location_depth'] = 'spending focused time in key locations';
      } else if (totalDwellMinutes > 0) {
        variables['location_depth'] = 'briefly engaging with various spaces';
      }

      if (locations.length > 3) {
        variables['place_variety'] = 'exploring diverse locations';
      } else if (locations.length > 1) {
        variables['place_variety'] = 'moving between familiar places';
      } else if (locations.length == 1) {
        variables['place_variety'] = 'centered in one meaningful space';
      }
      } catch (e) {
        debugPrint('Error extracting proximity variables: $e');
        // Don't add default values - let the template selection skip these
      }
    }
    // Don't add defaults if no proximity data

    // Enhanced movement variables for dynamic narrative generation
    if (context.movementData.isNotEmpty) {
      try {
      // Calculate detailed movement statistics
      double totalWalking = 0;
      double totalRunning = 0;
      double totalDriving = 0;
      double totalStill = 0;
      double totalActivity = 0;

      for (final movement in context.movementData) {
        switch (movement.state) {
          case 'walking':
            totalWalking++;
            totalActivity++;
            break;
          case 'running':
            totalRunning++;
            totalActivity++;
            break;
          case 'driving':
            totalDriving++;
            totalActivity++;
            break;
          case 'still':
            totalStill++;
            break;
        }
      }

      final totalSamples = context.movementData.length.toDouble();
      if (totalSamples > 0) {
        final activityPercentage = totalActivity / totalSamples;
        final walkingPercentage = totalWalking / totalSamples;
        final runningPercentage = totalRunning / totalSamples;
        final drivingPercentage = totalDriving / totalSamples;

        // Movement style based on dominant activity
        if (runningPercentage > 0.1) {
          variables['movement_style'] = 'energetically';
          variables['movement_narrative'] = 'High-energy movement powered through the day';
          variables['movement_type'] = 'athletic activity';
          variables['movement_metaphor'] = 'like a runner finding their stride';
          variables['energy_descriptor'] = 'vigorous';
          variables['activity_intensity'] = 'high-energy';
        } else if (drivingPercentage > 0.3) {
          variables['movement_style'] = 'efficiently';
          variables['movement_narrative'] = 'Travel and transitions shaped the rhythm';
          variables['movement_type'] = 'purposeful travel';
          variables['movement_metaphor'] = 'navigating from place to place';
          variables['energy_descriptor'] = 'mobile';
          variables['activity_intensity'] = 'travel-focused';
        } else if (walkingPercentage > 0.2) {
          variables['movement_style'] = 'actively';
          variables['movement_narrative'] = 'Walking and movement added vitality';
          variables['movement_type'] = 'steady movement';
          variables['movement_metaphor'] = 'with purposeful steps';
          variables['energy_descriptor'] = 'dynamic';
          variables['activity_intensity'] = 'moderate';
        } else if (activityPercentage > 0.15) {
          variables['movement_style'] = 'naturally';
          variables['movement_narrative'] = 'Movement flowed through the day';
          variables['movement_type'] = 'balanced activity';
          variables['movement_metaphor'] = 'finding natural rhythm';
          variables['energy_descriptor'] = 'balanced';
          variables['activity_intensity'] = 'gentle';
        }

        // Movement duration patterns
        if (activityPercentage > 0.5) {
          variables['movement_duration'] = 'consistently throughout';
        } else if (activityPercentage > 0.25) {
          variables['movement_duration'] = 'at key moments';
        } else if (activityPercentage > 0.1) {
          variables['movement_duration'] = 'periodically';
        }
      }
      } catch (e) {
        debugPrint('Error extracting movement variables: $e');
        // Don't add default values - let the template selection skip these
      }
    }
    // Don't add defaults if no movement data
    } catch (e) {
      debugPrint('Error extracting template variables: $e');
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
        return context.writtenContentSummary != null &&
               context.writtenContentSummary.hasSignificantContent;
      case BodyType.proximity:
        return context.proximitySummary != null &&
               context.proximitySummary.hasProximityInteractions;
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
            '{location_interaction} while {place_connection} created a sense of belonging.',
            'The day involved {place_variety}, each bringing its own energy.',
            'Being {location_depth} allowed for meaningful connections with the environment.',
          ],
        ),
        BodyTemplate(
          type: BodyType.reflection,
          options: [
            'Looking back, it\'s clear that today was about connection and vitality.',
            'The blend of activity and companionship created something truly special.',
            'These are the days that remind us what it means to be fully engaged with life.',
          ],
        ),
      ],
      closings: [
        'A day to remember for its perfect balance of energy and connection.',
        'Tomorrow will have much to live up to after today\'s wonderful experiences.',
        'These moments of joy and activity are what make life truly rich.',
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
      minConfidence: 0.5,
      preferredEnvironments: ['home', 'nature', 'quiet'],
      openings: [
        'Today unfolded with a gentle, personal rhythm.',
        'A peaceful day of quiet moments and personal reflection.',
        'The day offered space for solitude and inner peace.',
        'In the quietness of today, there was room to breathe and simply be.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.social,
          options: [
            'Time {social_descriptor} provided valuable space for self-reflection.',
            'The solitude of the day allowed thoughts to settle naturally.',
          ],
        ),
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The {primary_environment} offered a {environment_feeling} sanctuary for the day.',
            'Being in {primary_environment} created the perfect space for peaceful contemplation.',
          ],
        ),
        BodyTemplate(
          type: BodyType.movement,
          options: [
            '{movement_narrative}, bringing a gentle rhythm to the quiet hours.',
            'Moving {movement_style} through the day added a peaceful cadence.',
            'The {activity_intensity} movement complemented the day\'s tranquil nature.',
          ],
        ),
        BodyTemplate(
          type: BodyType.content,
          options: [
            'Thoughts about {content_focus} emerged {writing_depth} through quiet reflection.',
            'The {emotional_tenor} nature of today\'s contemplations brought clarity.',
            'Time for {thought_quality} revealed insights worth preserving.',
          ],
        ),
        BodyTemplate(
          type: BodyType.proximity,
          options: [
            'The familiar comfort of {place_variety} provided grounding.',
            '{location_interaction} brought a sense of peaceful presence.',
          ],
        ),
        BodyTemplate(
          type: BodyType.reflection,
          options: [
            'In these quiet moments, there\'s wisdom to be found.',
            'Sometimes the most profound days are the quietest ones.',
            'The simplicity of today held its own kind of beauty.',
          ],
        ),
      ],
      closings: [
        'A day that reminds us of the value of peaceful moments.',
        'Tomorrow may bring more activity, but today\'s tranquility was exactly what was needed.',
        'In the quiet spaces of days like this, we find ourselves.',
      ],
    );
  }

  /// Template for balanced days
  NarrativeTemplate _createBalancedDayTemplate() {
    return NarrativeTemplate(
      name: 'Balanced Day',
      socialStyle: SocialStyle.mixed,
      energyLevel: EnergyLevel.moderate,
      moodTone: MoodTone.balanced,
      minConfidence: 0.5,
      preferredEnvironments: ['varied', 'mixed', 'diverse'],
      openings: [
        'Today struck a pleasant balance between activity and rest.',
        'A well-rounded day unfolded with its mix of experiences.',
        'The day offered a comfortable blend of engagement and ease.',
        'Today moved at just the right pace, neither rushed nor stagnant.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.social,
          options: [
            'Time {social_descriptor} balanced nicely with moments of solitude.',
            'The mix of {social_context} and personal time felt just right.',
          ],
        ),
        BodyTemplate(
          type: BodyType.activity,
          options: [
            'The {pace} flow of activities kept things interesting without overwhelming.',
            'Moving between different experiences created a pleasant variety.',
          ],
        ),
        BodyTemplate(
          type: BodyType.movement,
          options: [
            '{movement_narrative} {movement_duration}, adding structure to the day.',
            'The {activity_intensity} level of activity felt perfectly sustainable.',
          ],
        ),
        BodyTemplate(
          type: BodyType.content,
          options: [
            'Reflections on {content_focus} emerged naturally throughout the day.',
            'The {emotional_tenor} thoughts that arose added depth to ordinary moments.',
          ],
        ),
        BodyTemplate(
          type: BodyType.reflection,
          options: [
            'These balanced days form the steady rhythm of life.',
            'Not every day needs to be extraordinary to be meaningful.',
          ],
        ),
      ],
      closings: [
        'A satisfying day that found its own natural rhythm.',
        'Tomorrow brings new possibilities, built on today\'s solid foundation.',
      ],
    );
  }

  /// Template for outdoor adventure days
  NarrativeTemplate _createOutdoorAdventureTemplate() {
    return NarrativeTemplate(
      name: 'Outdoor Adventure',
      socialStyle: SocialStyle.mixed,
      energyLevel: EnergyLevel.high,
      moodTone: MoodTone.upbeat,
      minConfidence: 0.6,
      preferredEnvironments: ['outdoor', 'nature', 'park', 'beach', 'mountain'],
      openings: [
        'Today was an adventure under open skies.',
        'The outdoors called, and the day answered with enthusiasm.',
        'Fresh air and natural beauty defined this {activity_level} day.',
        'Nature provided the perfect playground for today\'s experiences.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The {primary_environment} offered endless {environment_feeling} moments.',
            'Being immersed in {primary_environment} brought a sense of freedom and possibility.',
          ],
        ),
        BodyTemplate(
          type: BodyType.movement,
          options: [
            '{movement_narrative} through natural surroundings {movement_duration}.',
            'The {activity_intensity} outdoor activity connected body and environment perfectly.',
          ],
        ),
        BodyTemplate(
          type: BodyType.activity,
          options: [
            'Each outdoor experience flowed naturally into the next.',
            'The {pace} adventure kept spirits high throughout.',
          ],
        ),
        BodyTemplate(
          type: BodyType.reflection,
          options: [
            'Days like this remind us why we need nature in our lives.',
            'The outdoor world has a way of putting everything in perspective.',
          ],
        ),
      ],
      closings: [
        'An adventure to remember, written in sunshine and fresh air.',
        'Tomorrow may be indoors, but today\'s outdoor memories will linger.',
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
      preferredEnvironments: ['home', 'indoor', 'cozy'],
      openings: [
        'Today was a cozy retreat into comfortable spaces.',
        'The day unfolded gently within familiar walls.',
        'Indoor comfort defined this peacefully {pace} day.',
        'Home provided the perfect sanctuary for today\'s rhythm.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The {primary_environment} created a {environment_feeling} cocoon for the day.',
            'Indoor spaces offered warmth and comfort throughout.',
          ],
        ),
        BodyTemplate(
          type: BodyType.activity,
          options: [
            'Indoor activities flowed at a comfortable pace.',
            'The {pace} nature of the day allowed for both productivity and rest.',
          ],
        ),
        BodyTemplate(
          type: BodyType.content,
          options: [
            'Thoughts about {content_focus} emerged in the quiet indoor moments.',
            'The cozy setting invited {thought_quality} and contemplation.',
          ],
        ),
        BodyTemplate(
          type: BodyType.reflection,
          options: [
            'Sometimes the best days are spent in familiar comfort.',
            'These cozy days recharge us for whatever comes next.',
          ],
        ),
      ],
      closings: [
        'A day of indoor contentment and gentle rhythms.',
        'Tomorrow may bring adventure, but today\'s coziness was perfect.',
      ],
    );
  }

  /// Template for busy, productive days
  NarrativeTemplate _createBusyProductiveTemplate() {
    return NarrativeTemplate(
      name: 'Busy Productive',
      socialStyle: SocialStyle.mixed,
      energyLevel: EnergyLevel.high,
      moodTone: MoodTone.upbeat,
      minConfidence: 0.7,
      preferredEnvironments: ['office', 'urban', 'workspace'],
      openings: [
        'Today was a whirlwind of productivity and accomplishment.',
        'The day buzzed with activity and forward momentum.',
        'An {activity_level} day full of progress and purpose.',
        'Productivity defined this dynamically {pace} day.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.activity,
          options: [
            'Tasks and activities flowed in rapid succession.',
            'The {pace} rhythm kept energy high and progress constant.',
          ],
        ),
        BodyTemplate(
          type: BodyType.movement,
          options: [
            '{movement_narrative} between tasks {movement_duration}.',
            'The {activity_intensity} pace matched the day\'s productive energy.',
          ],
        ),
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The {primary_environment} buzzed with {environment_feeling} productive energy.',
            'Working in {primary_environment} amplified the sense of accomplishment.',
          ],
        ),
        BodyTemplate(
          type: BodyType.reflection,
          options: [
            'Days like this show what focused energy can achieve.',
            'The satisfaction of a productive day is its own reward.',
          ],
        ),
      ],
      closings: [
        'A day of accomplishment that moves life forward.',
        'Tomorrow can build on today\'s productive foundation.',
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
      preferredEnvironments: ['quiet', 'peaceful', 'contemplative'],
      openings: [
        'Today invited deep reflection and quiet contemplation.',
        'The day passed in thoughtful quietness.',
        'A gently {pace} day of introspection and peace.',
        'Stillness and reflection characterized today\'s journey.',
      ],
      bodyTemplates: [
        BodyTemplate(
          type: BodyType.environment,
          options: [
            'The {primary_environment} provided a {environment_feeling} space for thought.',
            'Quiet surroundings encouraged inner exploration.',
          ],
        ),
        BodyTemplate(
          type: BodyType.content,
          options: [
            'Deep thoughts about {content_focus} surfaced naturally.',
            'The {emotional_tenor} quality of reflection brought new understanding.',
          ],
        ),
        BodyTemplate(
          type: BodyType.reflection,
          options: [
            'In stillness, profound insights often emerge.',
            'These quiet days of reflection shape who we become.',
          ],
        ),
      ],
      closings: [
        'A day of quiet wisdom and gentle insights.',
        'Tomorrow may bring more noise, but today\'s silence spoke volumes.',
      ],
    );
  }
}

/// Narrative template structure
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

/// Body template for narrative sections
class BodyTemplate {
  final BodyType type;
  final List<String> options;

  BodyTemplate({
    required this.type,
    required this.options,
  });
}

/// Enums for template categorization
enum SocialStyle { solo, intimate, social, mixed }
enum EnergyLevel { low, moderate, high }
enum MoodTone { upbeat, balanced, reflective }
enum BodyType { social, activity, environment, reflection, movement, content, proximity }