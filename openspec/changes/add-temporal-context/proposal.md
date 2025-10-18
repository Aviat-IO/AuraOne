# Temporal Context and Narrative Intelligence

## Why

Current journal entries exist in isolation - each day is described without
reference to past days, patterns, or ongoing activities. This makes journals
feel robotic and disconnected:

- Says "went to coffee shop" instead of "third visit to La Barba this week"
- Says "went hiking" instead of "first outdoor activity in 10 days"
- Cannot reference ongoing projects or activities ("continuing the project from
  Monday")
- No sense of habits, streaks, or changes in routine
- Cannot detect special occasions or unusual patterns

Temporal context transforms journals from isolated snapshots into connected
narratives that show patterns, progress, and meaning over time.

## What Changes

- Create temporal context analysis engine that detects patterns across days
- Add "narrative threads" table to track ongoing activities (projects, books,
  habits)
- Implement frequency detection (e.g., "third visit this week")
- Implement gap detection (e.g., "first time since last month")
- Implement activity continuation tracking (e.g., "continuing from yesterday")
- Detect special occasions and unusual patterns
- Integrate temporal insights into journal generation prompts
- Add "On This Day" feature showing past entries from same date
- Create streak tracking for habits and activities
- Build UI to show patterns, streaks, and temporal connections

**Intelligence features:**

- Place frequency: "Your usual Tuesday morning spot" vs "First visit to this
  cafe"
- Activity gaps: "Back to the gym after a break" vs "Continuing daily workout
  streak"
- Social patterns: "Caught up with Sarah again" vs "First meetup in months"
- Progress tracking: "Day 5 of morning runs" or "Finished the book started last
  week"
- Seasonal patterns: "First outdoor run since winter" or "Usual summer hiking
  spot"

## What Changes

**Affected specs:**

- `narrative-intelligence` (new) - Temporal pattern detection and insights
- `journal-generation` (existing) - Integration of temporal context into prompts
- `activity-tracking` (existing) - Pattern analysis and streak detection
- `database-schema` (existing) - New tables for narrative threads and patterns

**Affected code:**

- `mobile-app/lib/services/temporal_context_engine.dart` (new) - Core pattern
  detection
- `mobile-app/lib/database/narrative_threads_database.dart` (new) - Drift tables
- `mobile-app/lib/services/activity_pattern_analyzer.dart` (new) - Pattern
  recognition
- `mobile-app/lib/services/daily_context_synthesizer.dart` - Temporal enrichment
- `mobile-app/lib/services/ai/cloud_gemini_adapter.dart` - Temporal context in
  prompts
- `mobile-app/lib/screens/insights/temporal_patterns_screen.dart` (new) - UI
- `mobile-app/lib/widgets/streak_widget.dart` (new) - Streak display

**User-facing impact:**

- Journals feel connected and aware of history
- Recognition of habits and patterns
- Celebration of streaks and milestones
- Detection of changes and new behaviors
- Insights into life patterns over time
- "On This Day" memories from previous years

**Technical considerations:**

- Efficient querying of historical data (indexed by date and activity)
- Pattern detection algorithms (frequency analysis, streak calculation)
- Memory of ongoing activities (when to mention, when to close threads)
- Performance with years of historical data
- Balance between showing patterns and avoiding repetition

## Impact

**Expected improvements:**

- 30-40% increase in journal entry richness with temporal context
- Users discover patterns they didn't notice
- Stronger emotional connection to journals (seeing progress)
- Higher retention (users check back to see streaks and patterns)
- Differentiation from competitors (unique narrative intelligence)

## Success Metrics

- 60%+ of journal entries include at least one temporal insight
- Users view "On This Day" feature average 3+ times per week
- Temporal insights rated helpful by 70%+ of users
- Streak features increase daily app opens by 15%
- Pattern detection accuracy > 85% (validated by user feedback)
