# Journal Prompt Enhancement - Implementation Guide

## Overview

This document describes the enhanced prompt engineering implementation for
AI-generated journal entries in Aura One. The changes transform robotic,
surveillance-like journal entries into natural, human-written narratives.

## Problem Statement

**Before:**

```
Visited 3 locations today. Photographed a person at a park. The image shows trees 
and you can see my shadow on the pavement. Later visited a coffee shop and took a 
photo of a beverage. Returned to residential location at 14:30. Took 2 photos of 
food items. Total photos: 5.
```

**After:**

```
Started the morning with a long walk through Liberty Park. The fall colors were 
particularly vibrant today. Met up with a friend for coffee downtown - we caught 
up on recent projects and made plans for the weekend. Spent the afternoon working 
from home on the quarterly report. Ended the day with a quiet dinner and some reading.
```

## Architecture

### 1. Prompt Structure (`cloud_gemini_adapter.dart:332-444`)

The enhanced prompt has **6 key sections**:

#### 1.1 WRITING STYLE

Instructs the LLM to:

- Use complete, grammatically correct sentences
- Vary sentence structure
- Present information chronologically
- Focus on observable facts

#### 1.2 TONE GUIDELINES

Maintains objectivity:

- Describe WHAT, WHERE, WHEN
- Avoid assumptions about feelings
- No emotional adjectives ("amazing", "wonderful")

#### 1.3 WHAT TO EXCLUDE

Eliminates robotic details:

- Photo-technical details (shadows, lighting, angles)
- Meta-observations ("you can see", "visible in photo")
- Self-referential commentary ("from where I was standing")

#### 1.4 WHAT TO EMPHASIZE

Prioritizes meaningful content:

- Activities over locations
- People over demographics
- Memorable moments over routine transitions
- Context over technical details

#### 1.5 MEASUREMENT UNITS

Locale-aware formatting:

- **US/Liberia/Myanmar**: Imperial (miles, Fahrenheit)
- **Rest of world**: Metric (kilometers, Celsius)

Implemented via `_shouldUseImperialMeasurements()` using
`ui.PlatformDispatcher.instance.locale`

#### 1.6 EXAMPLES (Few-Shot Learning)

Provides concrete examples:

- **GOOD EXAMPLE**: Natural, flowing narrative
- **BAD EXAMPLE**: Robotic surveillance report with label "DO NOT WRITE LIKE
  THIS"

### 2. Context Formatting (`cloud_gemini_adapter.dart:472-587`)

#### 2.1 People Context (`_formatPeopleContext`)

```dart
PEOPLE:
- 3 people detected in photos
- Social context: small_group, selfie
```

#### 2.2 Places Context (`_formatPlacesContext`)

```dart
PLACES & LOCATIONS:
- Liberty Park (2h 15m)
- Downtown Coffee Shop (45m)
- Total distance: 2.9 miles  // or "4.7 km" for metric
```

#### 2.3 Activities Context (`_formatActivitiesContext`)

```dart
ACTIVITIES & EVENTS:
- 8:00: Morning Walk at Liberty Park
- 12:00: Lunch Meeting at Downtown Restaurant
- Activities: exercise, meeting, dining
```

#### 2.4 Timeline Context (`_formatTimelineContext`)

```dart
TIMELINE:
- 8:00 at Liberty Park: Morning walk (outdoor, trees)
- 10:30 at Coffee Shop: Meeting with friend (person, beverage)
- 14:00 at Home: Working on project (laptop, desk)
```

#### 2.5 Duration Formatting (`_formatDuration`)

Converts durations to human-readable format:

- `2h 30m` (not "150 minutes")
- `45 minutes` (for sub-hour durations)

### 3. Data Preprocessing (`timeline_event_aggregator.dart:398-485`)

#### 3.1 Event Filtering (`_filterAndGroupEvents`)

Removes low-significance events:

- Filters using `isSignificant` property
- Removes near-duplicate locations (same place within 30 minutes)
- Merges photo events taken within 10 minutes at same location

#### 3.2 Significance Criteria (`isSignificant` property)

```dart
- Calendar events: Always significant
- Photos: Always significant
- Locations: Only if named (not raw coordinates)
- Movement: Only if not "still"
- Activities: Usually filtered out (background noise)
```

#### 3.3 Photo Event Merging (`_shouldMergeWithPreviousPhoto`)

Combines multiple photos into single narrative moment if:

- Taken within 2 minutes of each other
- At same location OR within 10-minute window
- Tracks merged count in metadata

#### 3.4 Location Deduplication (`_isNearDuplicate`)

Prevents redundant location mentions:

- Checks last 3 events for same place name
- Within 30-minute window
- Avoids: "At Park. At Park. At Park."

### 4. Locale-Aware Measurements

#### Implementation

```dart
bool _shouldUseImperialMeasurements() {
  final locale = ui.PlatformDispatcher.instance.locale;
  final countryCode = locale.countryCode?.toUpperCase();
  const imperialCountries = {'US', 'LR', 'MM'};
  return countryCode != null && imperialCountries.contains(countryCode);
}
```

#### Usage in Prompts

```dart
if (useImperial) {
  final miles = context.locationSummary.totalKilometers * 0.621371;
  buffer.writeln('- Total distance: ${miles.toStringAsFixed(1)} miles');
} else {
  buffer.writeln('- Total distance: ${context.locationSummary.totalKilometers.toStringAsFixed(1)} km');
}
```

## Design Decisions

### Why Few-Shot Examples?

**Decision:** Include concrete examples in the prompt instead of just
instructions.

**Rationale:**

- LLMs learn better from examples than abstract rules
- Shows the **exact** difference between good and bad writing
- Prevents model drift toward robotic output
- Examples act as "guardrails" during generation

### Why Locale Detection?

**Decision:** Auto-detect user locale instead of manual settings.

**Rationale:**

- Zero configuration required from users
- Matches user's system preferences
- Covers 99% of use cases (US uses imperial, rest use metric)
- Fallback to metric if locale detection fails

### Why Filter Events During Aggregation?

**Decision:** Remove low-significance events in `timeline_event_aggregator.dart`
instead of prompt.

**Rationale:**

- Reduces token count in LLM requests (lower cost, faster)
- Cleaner prompt with fewer distractions
- More predictable narrative structure
- Preprocessing is deterministic and testable

### Why Merge Photo Events?

**Decision:** Combine rapid-fire photos into single narrative moment.

**Rationale:**

- Avoids repetitive "took a photo, then took another photo"
- Reflects actual human behavior (photo bursts)
- Narrative reads more naturally
- Metadata preserves individual photo details if needed

## Quality Metrics

### Success Criteria

1. **Grammar:** Complete sentences, proper punctuation
2. **Flow:** Smooth transitions, chronological order
3. **Tone:** Objective facts, no assumptions
4. **Relevance:** Meaningful activities, not technical details
5. **Measurements:** Locale-appropriate units

### Testing (`test/services/journal_prompt_quality_test.dart`)

#### Task 5.4: Sparse Data Days

- Few photos (< 3)
- Few calendar events (< 2)
- Limited locations (< 3)
- Low confidence (< 0.5)

#### Task 5.5: Data-Rich Days

- Many photos (> 5)
- Multiple calendar events (> 2)
- Several locations (> 3)
- High confidence (> 0.6)

#### Task 5.6: Locale-Specific Formatting

- US locale: Distances in miles
- Non-US locale: Distances in kilometers
- Automatic conversion (1 km = 0.621371 miles)

#### Task 5.3: Quality Validation

**Robotic phrases to avoid:**

- "photographed", "captured"
- "you can see", "visible in"
- "shadow on the pavement"
- "from where I was standing"

**Photo-technical details to exclude:**

- Camera angles, lighting conditions
- Image composition, reflection
- Background clutter

## Future Improvements

### Phase 2: Personalization (Proposed)

Add person/place registries to use actual names:

- "Charles at Liberty Park" instead of "child at playground"
- "Mom's house" instead of "residential location"
- User-defined relationships and place significance

### Phase 3: Temporal Context (Proposed)

Add historical awareness:

- "Returned to Liberty Park for the third time this week"
- "First visit to this location in 6 months"
- Streak detection: "5-day running streak"

### Phase 4: Emotional Intelligence (Future)

Infer tone from patterns without assumptions:

- "Spent extended time at the gym" (pattern: physical activity)
- "Quick visit to the park" (duration: < 30 minutes)
- "Social gathering" (people count: > 4)

## Examples

### Sparse Data Day

**Input:**

- 1 photo (indoor table)
- 0 calendar events
- 1 location (Home, 8 hours)
- 100m total distance

**Generated Output:**

```
A quiet day at home. Spent most of the day indoors, focusing on personal tasks 
and rest. Minimal travel throughout the day.
```

### Data-Rich Day

**Input:**

- 8 photos (outdoor, people, activities)
- 3 calendar events (Meeting, Lunch, Gym)
- 4 locations (Office, Cafe, Fitness Center, Park)
- 8.5km distance

**Generated Output:**

```
Started the morning at the office with a team meeting to discuss the quarterly 
roadmap. Around midday, met a friend downtown for lunch at a local cafe. The 
afternoon was productive, focusing on project work at home. Ended the day with 
a workout at the fitness center, covering about 5.3 miles throughout the day 
between locations.
```

## Files Modified

### Core Implementation

- `mobile-app/lib/services/ai/cloud_gemini_adapter.dart` - Prompt generation
- `mobile-app/lib/services/timeline_event_aggregator.dart` - Event preprocessing

### Related Services (Context Only)

- `mobile-app/lib/services/daily_context_synthesizer.dart` - Data structure
- `mobile-app/lib/services/data_rich_narrative_builder.dart` - Alternative
  templates

### Testing

- `mobile-app/test/services/journal_prompt_quality_test.dart` - Quality
  validation

## Maintenance Notes

### Prompt Tuning

To adjust prompt behavior:

1. Edit sections in `_buildNarrativePrompt()`
2. Test with sparse and rich contexts
3. Validate against quality metrics
4. Update examples if needed

### Measurement Conversion

To add new locales:

```dart
const imperialCountries = {
  'US', // United States
  'LR', // Liberia
  'MM', // Myanmar
  // Add new countries here
};
```

### Event Significance

To change what's considered "significant":

```dart
bool get isSignificant {
  switch (type) {
    case NarrativeEventType.calendar:
      return true;  // Adjust criteria here
    // ...
  }
}
```

## References

- OpenSpec Proposal: `openspec/changes/enhance-journal-prompt/proposal.md`
- Tasks Checklist: `openspec/changes/enhance-journal-prompt/tasks.md`
- Spec Document: `openspec/changes/enhance-journal-prompt/spec.md`
- Example Narratives: `openspec/changes/enhance-journal-prompt/examples.md`

---

**Last Updated:** 2025-01-18\
**Implementation Status:** Complete (Phase 1)\
**Next Phase:** Local Context Database (person/place registries)
