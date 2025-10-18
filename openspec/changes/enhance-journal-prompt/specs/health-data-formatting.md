# Health Data Natural Language Formatting

**Status:** Draft (Deferred - awaiting health data implementation)\
**Priority:** P2 (Low)\
**Related:** Task 2.5 from enhance-journal-prompt

## Context

The journal prompt enhancement requires health data to be formatted in natural
language for LLM consumption. However, health data tracking is currently
disabled in the app (see `mobile-app/lib/services/health_service.dart`).

This spec documents the **planned** health data formatting for when health
tracking is re-enabled.

## Requirements

The system SHALL format health metrics into natural language when health data
becomes available:

- **WHEN** health data includes step count
- **THEN** it SHALL be formatted as "walked X,XXX steps" (comma-separated
  thousands)

- **WHEN** health data includes distance
- **THEN** it SHALL be converted to locale-appropriate units (miles for US, km
  for others)

- **WHEN** health data includes active calories
- **THEN** it SHALL be formatted as "burned XXX calories" (no decimal places)

- **WHEN** health data includes activity minutes
- **THEN** it SHALL be formatted as "X hours Y minutes of activity" or "Z
  minutes of activity"

- **WHEN** health data includes heart rate measurements
- **THEN** it SHALL format average/peak as "heart rate averaged XX bpm (peak: YY
  bpm)"

- **WHEN** health data includes sleep duration
- **THEN** it SHALL be formatted as "X hours Y minutes of sleep"

- **WHEN** health data includes workout types
- **THEN** it SHALL use natural names: "running", "cycling", "strength
  training", not codes

## Current State

### Health Service Status

```dart
// mobile-app/lib/services/health_service.dart
// Original health service temporarily disabled to reduce APK size
return {
  'health_data': 'Health data collection temporarily disabled for optimized build',
};
```

### Workaround: Estimated Steps

Some services estimate steps from movement data:

```dart
// mobile-app/lib/services/journal_service.dart:571-586
// Estimate steps and distance from movement patterns
final estimatedSteps = (movementMinutes * 100).toInt();

metadata['steps'] = estimatedSteps;
```

### Test Usage

Tests and dev seed data include mock health data:

```dart
// mobile-app/lib/database/dev_seed_data.dart:206-211
final steps = (_random.nextInt(5000) + 2000);
description = 'Walked $steps steps';
metadata = {
  'steps': steps,
  'distance': '${(steps * 0.0008).toStringAsFixed(1)} km',
  'calories': steps ~/ 20,
};
```

## Proposed Implementation

### 1. Health Data Structure

```dart
class HealthSummary {
  final int? stepCount;
  final double? distanceMeters;
  final int? activeCalories;
  final Duration? activeTime;
  final HeartRateData? heartRate;
  final Duration? sleepDuration;
  final List<WorkoutType>? workouts;
  
  HealthSummary({
    this.stepCount,
    this.distanceMeters,
    this.activeCalories,
    this.activeTime,
    this.heartRate,
    this.sleepDuration,
    this.workouts,
  });
}

class HeartRateData {
  final int average;
  final int peak;
  final int resting;
  
  HeartRateData({
    required this.average,
    required this.peak,
    required this.resting,
  });
}

enum WorkoutType {
  running,
  walking,
  cycling,
  swimming,
  strengthTraining,
  yoga,
  hiking,
  other,
}
```

### 2. Formatting Helper

```dart
// Add to cloud_gemini_adapter.dart
String _formatHealthContext(HealthSummary? health) {
  if (health == null) return '';
  
  final buffer = StringBuffer();
  buffer.writeln('HEALTH & ACTIVITY:');
  
  // Steps
  if (health.stepCount != null && health.stepCount! > 0) {
    final formattedSteps = _formatNumber(health.stepCount!);
    buffer.writeln('- Walked $formattedSteps steps');
  }
  
  // Distance
  if (health.distanceMeters != null && health.distanceMeters! > 0) {
    final useImperial = _shouldUseImperialMeasurements();
    if (useImperial) {
      final miles = health.distanceMeters! * 0.000621371;
      buffer.writeln('- Distance: ${miles.toStringAsFixed(1)} miles');
    } else {
      final km = health.distanceMeters! / 1000;
      buffer.writeln('- Distance: ${km.toStringAsFixed(1)} km');
    }
  }
  
  // Active calories
  if (health.activeCalories != null && health.activeCalories! > 0) {
    buffer.writeln('- Burned ${health.activeCalories} calories');
  }
  
  // Active time
  if (health.activeTime != null && health.activeTime!.inMinutes > 0) {
    final formatted = _formatDuration(health.activeTime!);
    buffer.writeln('- Active time: $formatted');
  }
  
  // Heart rate
  if (health.heartRate != null) {
    final hr = health.heartRate!;
    buffer.writeln('- Heart rate: avg ${hr.average} bpm (peak: ${hr.peak} bpm)');
  }
  
  // Sleep
  if (health.sleepDuration != null && health.sleepDuration!.inMinutes > 0) {
    final formatted = _formatDuration(health.sleepDuration!);
    buffer.writeln('- Sleep: $formatted');
  }
  
  // Workouts
  if (health.workouts != null && health.workouts!.isNotEmpty) {
    final workoutNames = health.workouts!
        .map((w) => _workoutTypeToName(w))
        .join(', ');
    buffer.writeln('- Workouts: $workoutNames');
  }
  
  return buffer.toString();
}

String _formatNumber(int number) {
  // Add thousand separators: 10000 -> "10,000"
  final formatted = number.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return formatted;
}

String _workoutTypeToName(WorkoutType type) {
  switch (type) {
    case WorkoutType.running:
      return 'running';
    case WorkoutType.walking:
      return 'walking';
    case WorkoutType.cycling:
      return 'cycling';
    case WorkoutType.swimming:
      return 'swimming';
    case WorkoutType.strengthTraining:
      return 'strength training';
    case WorkoutType.yoga:
      return 'yoga';
    case WorkoutType.hiking:
      return 'hiking';
    case WorkoutType.other:
      return 'workout';
  }
}
```

### 3. Integration with DailyContext

```dart
// Add to daily_context_synthesizer.dart
class DailyContext {
  // ... existing fields ...
  final HealthSummary? healthSummary;  // NEW
  
  DailyContext({
    // ... existing parameters ...
    this.healthSummary,  // NEW
  });
}
```

### 4. Prompt Integration

```dart
// In _buildNarrativePrompt()
final health = _formatHealthContext(context.healthSummary);
if (health.isNotEmpty) {
  buffer.write(health);
  buffer.writeln();
}
```

## Examples

### Example 1: Active Day

**Input:**

```dart
HealthSummary(
  stepCount: 12543,
  distanceMeters: 9800,
  activeCalories: 450,
  activeTime: Duration(hours: 2, minutes: 15),
)
```

**Output (US Locale):**

```
HEALTH & ACTIVITY:
- Walked 12,543 steps
- Distance: 6.1 miles
- Burned 450 calories
- Active time: 2h 15m
```

**Output (EU Locale):**

```
HEALTH & ACTIVITY:
- Walked 12,543 steps
- Distance: 9.8 km
- Burned 450 calories
- Active time: 2h 15m
```

### Example 2: Workout Day

**Input:**

```dart
HealthSummary(
  stepCount: 8200,
  activeCalories: 620,
  activeTime: Duration(hours: 1, minutes: 45),
  heartRate: HeartRateData(average: 125, peak: 165, resting: 68),
  workouts: [WorkoutType.running, WorkoutType.strengthTraining],
)
```

**Output:**

```
HEALTH & ACTIVITY:
- Walked 8,200 steps
- Burned 620 calories
- Active time: 1h 45m
- Heart rate: avg 125 bpm (peak: 165 bpm)
- Workouts: running, strength training
```

### Example 3: Rest Day with Sleep

**Input:**

```dart
HealthSummary(
  stepCount: 3450,
  sleepDuration: Duration(hours: 8, minutes: 15),
)
```

**Output:**

```
HEALTH & ACTIVITY:
- Walked 3,450 steps
- Sleep: 8h 15m
```

## Testing

```dart
test('Health data formats step count with commas', () {
  final health = HealthSummary(stepCount: 12543);
  final formatted = _formatHealthContext(health);
  
  expect(formatted, contains('12,543 steps'));
  expect(formatted, isNot(contains('12543 steps')));
});

test('Health data converts distance to imperial for US', () {
  // Mock locale to US
  final health = HealthSummary(distanceMeters: 9656); // 6 miles
  final formatted = _formatHealthContext(health);
  
  expect(formatted, contains('6.0 miles'));
  expect(formatted, isNot(contains('km')));
});

test('Health data uses metric for non-US', () {
  // Mock locale to UK
  final health = HealthSummary(distanceMeters: 9656);
  final formatted = _formatHealthContext(health);
  
  expect(formatted, contains('9.7 km'));
  expect(formatted, isNot(contains('miles')));
});

test('Health data formats heart rate with units', () {
  final health = HealthSummary(
    heartRate: HeartRateData(average: 125, peak: 165, resting: 68),
  );
  final formatted = _formatHealthContext(health);
  
  expect(formatted, contains('avg 125 bpm'));
  expect(formatted, contains('peak: 165 bpm'));
});

test('Health data handles null/missing data gracefully', () {
  final health = HealthSummary(); // All null
  final formatted = _formatHealthContext(health);
  
  expect(formatted, isEmpty);
});
```

## Dependencies

### Blocked By

1. **Health Service Re-enablement** -
   `mobile-app/lib/services/health_service.dart` must be re-implemented
2. **Health Permissions** - iOS HealthKit / Android Health Connect integration
3. **Privacy Settings** - User must grant health data permission

### Related Work

- **Phase 2: Local Context Database** - May include health goals/preferences
- **HealthKit Integration** (iOS) - Requires native plugin
- **Health Connect Integration** (Android) - Requires native plugin

## Implementation Checklist

When health tracking is re-enabled:

- [ ] Add `HealthSummary` class to `daily_context_synthesizer.dart`
- [ ] Add `healthSummary` field to `DailyContext`
- [ ] Implement `_formatHealthContext()` in `cloud_gemini_adapter.dart`
- [ ] Add `_formatNumber()` helper for thousand separators
- [ ] Add `_workoutTypeToName()` helper for workout labels
- [ ] Integrate health section into `_buildNarrativePrompt()`
- [ ] Add unit tests for health data formatting
- [ ] Add integration tests with real health data
- [ ] Update documentation with health data examples
- [ ] Add privacy notice for health data usage

## References

- **Original Task:** `openspec/changes/enhance-journal-prompt/tasks.md` (Task
  2.5)
- **Health Service:** `mobile-app/lib/services/health_service.dart` (currently
  disabled)
- **Dev Seed Data:** `mobile-app/lib/database/dev_seed_data.dart` (mock health
  data)
- **Privacy Settings:** `mobile-app/lib/models/privacy_settings.dart`
  (healthPermission field)

---

**Status:** Draft (Awaiting health service implementation)\
**Priority:** P2 (Implement after Phase 2)\
**Estimated Effort:** 3-5 days (formatting only, excludes health service
implementation)
