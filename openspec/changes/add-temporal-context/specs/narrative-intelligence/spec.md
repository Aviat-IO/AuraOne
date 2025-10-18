# Narrative Intelligence Specification

## ADDED Requirements

### Requirement: Temporal Pattern Detection

The system SHALL analyze historical data to detect patterns, frequencies, and
changes over time.

#### Scenario: Activity frequency calculated

- **WHEN** analyzing temporal context for a date
- **THEN** system SHALL calculate how often each activity occurs (daily, weekly,
  monthly)

#### Scenario: Place visit frequency detected

- **WHEN** user visits a place
- **THEN** system SHALL determine if it's a first visit, occasional visit, or
  frequent visit

#### Scenario: Time gaps detected

- **WHEN** activity occurs after absence
- **THEN** system SHALL calculate time since last occurrence and generate gap
  description

#### Scenario: Patterns compared to baseline

- **WHEN** analyzing current day
- **THEN** system SHALL compare activity levels to typical patterns for that
  day-of-week

### Requirement: Narrative Thread Tracking

The system SHALL track ongoing activities across multiple days as narrative
threads.

#### Scenario: Thread created for multi-day activity

- **WHEN** activity spans multiple consecutive days
- **THEN** system SHALL create a narrative thread to track continuation

#### Scenario: Thread types supported

- **WHEN** creating a thread
- **THEN** system SHALL support types: ongoing_project, book_reading,
  habit_streak, learning, fitness_program

#### Scenario: Thread status tracked

- **WHEN** managing threads
- **THEN** system SHALL track status: active, completed, paused, abandoned

#### Scenario: Thread completion detected

- **WHEN** thread activity not detected for threshold period
- **THEN** system SHALL mark thread as completed or paused

#### Scenario: Thread mentioned in journal

- **WHEN** thread is active and relevant to current day
- **THEN** system SHALL include thread context in journal generation

### Requirement: Streak Calculation

The system SHALL calculate and track streaks for repeated activities.

#### Scenario: Streak counted for consecutive days

- **WHEN** activity occurs on consecutive days
- **THEN** system SHALL increment streak counter

#### Scenario: Streak broken by missed day

- **WHEN** activity does not occur on a day
- **THEN** current streak SHALL be reset and saved as historical best if
  applicable

#### Scenario: Best streak remembered

- **WHEN** streak ends
- **THEN** system SHALL remember the best streak ever achieved for that activity

#### Scenario: Streak milestones detected

- **WHEN** streak reaches milestone (7, 30, 100, 365 days)
- **THEN** system SHALL flag for celebration in journal or notification

### Requirement: Frequency Insights Generation

The system SHALL generate natural language descriptions of activity frequency
for journal context.

#### Scenario: High frequency described naturally

- **WHEN** place visited 3+ times in a week
- **THEN** insight SHALL be "your usual spot" or "third visit this week"

#### Scenario: First-time event highlighted

- **WHEN** activity or location detected for first time
- **THEN** insight SHALL be "first time at..." or "tried something new"

#### Scenario: Return after gap described

- **WHEN** activity resumes after significant gap
- **THEN** insight SHALL be "back to... after [duration]" or "first time in
  [duration]"

#### Scenario: Routine activities acknowledged

- **WHEN** activity occurs at typical frequency
- **THEN** insight MAY reference routine (e.g., "usual morning routine")

### Requirement: Gap Analysis

The system SHALL detect and describe temporal gaps in activities.

#### Scenario: Significant gap detected

- **WHEN** activity gap exceeds 2x typical frequency
- **THEN** system SHALL generate gap insight for journal context

#### Scenario: Gap severity calculated

- **WHEN** calculating gap
- **THEN** system SHALL categorize as minor (days), moderate (weeks), or major
  (months)

#### Scenario: Gap context provided

- **WHEN** gap detected
- **THEN** insight SHALL include "first time since [date/duration]"

### Requirement: Special Occasion Detection

The system SHALL detect unusual patterns that may indicate special occasions.

#### Scenario: Unusual activity level detected

- **WHEN** photo count or activity count exceeds baseline by 2x
- **THEN** system SHALL flag as potential special occasion

#### Scenario: Unusual location combination

- **WHEN** multiple novel locations visited in one day
- **THEN** system SHALL flag as potential special event (trip, outing)

#### Scenario: Unusual social pattern

- **WHEN** multiple people together who don't typically overlap
- **THEN** system SHALL flag as potential gathering or event

#### Scenario: Calendar cross-reference

- **WHEN** special occasion detected
- **THEN** system SHALL cross-reference with occasions table (birthdays,
  holidays)

### Requirement: Temporal Insights Caching

The system SHALL cache temporal insights to avoid redundant calculation and
improve performance.

#### Scenario: Insights generated once per day

- **WHEN** generating temporal context for a date
- **THEN** system SHALL cache insights and reuse for subsequent journal
  generations

#### Scenario: Cache invalidated by new data

- **WHEN** new data added that affects patterns
- **THEN** relevant cached insights SHALL be invalidated and recalculated

#### Scenario: Cache expires after time period

- **WHEN** cached insight is older than 24 hours
- **THEN** it SHALL be recalculated on next access

### Requirement: On This Day Feature

The system SHALL provide "On This Day" functionality showing historical entries
from same date in previous years.

#### Scenario: Historical entries retrieved

- **WHEN** user accesses "On This Day"
- **THEN** system SHALL show entries from same calendar date in all previous
  years

#### Scenario: Year-over-year comparison

- **WHEN** multiple years available
- **THEN** system SHALL highlight what changed and what stayed the same

#### Scenario: Significant memories highlighted

- **WHEN** historical entry contains special occasions or high significance
  events
- **THEN** it SHALL be prominently featured

### Requirement: Temporal Context Integration

The system SHALL integrate temporal insights into journal generation prompts.

#### Scenario: Temporal section in prompt

- **WHEN** generating journal entry
- **THEN** prompt SHALL include "TEMPORAL CONTEXT" section with relevant
  insights

#### Scenario: Frequency insights included

- **WHEN** frequency patterns detected
- **THEN** they SHALL be formatted as bullet points in temporal context

#### Scenario: Gap insights included

- **WHEN** significant gaps detected
- **THEN** they SHALL be included with contextual descriptions

#### Scenario: Thread continuations mentioned

- **WHEN** active narrative threads relevant to day
- **THEN** they SHALL be included in temporal context

#### Scenario: Streaks acknowledged

- **WHEN** active streaks exist
- **THEN** they SHALL be mentioned in temporal context (e.g., "Day 12 of morning
  runs")

### Requirement: Pattern Significance Scoring

The system SHALL score the significance of temporal patterns to determine what
to include in journals.

#### Scenario: Significance calculated

- **WHEN** pattern detected
- **THEN** system SHALL calculate significance score (0.0-1.0) based on novelty,
  frequency deviation, and user impact

#### Scenario: High significance patterns prioritized

- **WHEN** multiple patterns detected for same day
- **THEN** only highest significance patterns (score > 0.6) SHALL be included in
  journal context

#### Scenario: Low significance patterns omitted

- **WHEN** pattern has low significance (score < 0.3)
- **THEN** it SHALL NOT be mentioned to avoid clutter

### Requirement: Performance and Scalability

The system SHALL efficiently analyze temporal patterns across years of
historical data.

#### Scenario: Analysis completes quickly

- **WHEN** generating temporal context for a day
- **THEN** analysis SHALL complete in less than 2 seconds

#### Scenario: Historical window configurable

- **WHEN** analyzing patterns
- **THEN** system SHALL use configurable window (default 90 days) to limit query
  scope

#### Scenario: Incremental updates efficient

- **WHEN** new day's data added
- **THEN** pattern updates SHALL be incremental, not requiring full
  recalculation
