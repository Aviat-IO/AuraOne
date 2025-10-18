# Journal Preferences Specification

## ADDED Requirements

### Requirement: Preferences Storage

The system SHALL store user preferences for journal generation in a local
key-value database table.

#### Scenario: Preference values persisted

- **WHEN** user changes a journal preference
- **THEN** it SHALL be stored in the journal_preferences table

#### Scenario: Preferences survive app restart

- **WHEN** app is restarted
- **THEN** previously set preferences SHALL be loaded and applied

### Requirement: Detail Level Control

The system SHALL allow users to control the level of detail in generated journal
entries.

#### Scenario: Detail level options available

- **WHEN** configuring journal preferences
- **THEN** user SHALL be able to select: low, medium, or high detail level

#### Scenario: Low detail generates concise entries

- **WHEN** detail_level = low
- **THEN** generated entries SHALL be 1-2 paragraphs focusing on key moments
  only

#### Scenario: High detail generates rich entries

- **WHEN** detail_level = high
- **THEN** generated entries SHALL be 3-4 paragraphs with rich observations and
  context

### Requirement: Tone Selection

The system SHALL allow users to choose the writing tone for journal entries.

#### Scenario: Tone options available

- **WHEN** configuring journal preferences
- **THEN** user SHALL be able to select: casual, reflective, or professional
  tone

#### Scenario: Tone affects prompt

- **WHEN** generating journal entry
- **THEN** selected tone SHALL be included in prompt to guide LLM writing style

### Requirement: Entry Length Control

The system SHALL allow users to set preferred entry length.

#### Scenario: Length options available

- **WHEN** configuring journal preferences
- **THEN** user SHALL be able to select: short (2-3 paragraphs), medium (3-4
  paragraphs), or long (4-5 paragraphs)

#### Scenario: Length affects word count target

- **WHEN** generating journal entry
- **THEN** prompt SHALL specify target word count based on length preference

### Requirement: Privacy Level Control

The system SHALL provide global privacy level settings that affect all journal
entries.

#### Scenario: Privacy level options available

- **WHEN** configuring journal preferences
- **THEN** user SHALL be able to select: maximum detail, balanced, minimal, or
  paranoid

#### Scenario: Privacy affects context sanitization

- **WHEN** generating journal entry with cloud AI
- **THEN** context data SHALL be sanitized according to privacy level before
  sending

### Requirement: Content Inclusion Toggles

The system SHALL allow users to toggle inclusion of specific data types in
journals.

#### Scenario: Health data toggle

- **WHEN** include_health_data = false
- **THEN** health and fitness data SHALL NOT be included in journal context

#### Scenario: Weather toggle

- **WHEN** include_weather = false
- **THEN** weather information SHALL NOT be included in journal narratives

#### Scenario: Unknown people toggle

- **WHEN** mention_unknown_people = false
- **THEN** unidentified people SHALL be omitted from journal entries

### Requirement: Location Specificity Control

The system SHALL allow users to control how specifically locations are
mentioned.

#### Scenario: Location specificity options

- **WHEN** configuring preferences
- **THEN** user SHALL be able to select: exact (place name + address),
  neighborhood (place + area), city (place + city only), or vague (generic
  descriptions)

#### Scenario: Exact specificity includes full details

- **WHEN** location_specificity = exact
- **THEN** journals SHALL include place name, neighborhood, and city

#### Scenario: Vague specificity uses generic terms

- **WHEN** location_specificity = vague
- **THEN** journals SHALL use generic terms like "a park" or "a restaurant"
  without names

### Requirement: Preferences UI

The system SHALL provide a settings interface for managing journal preferences.

#### Scenario: Preferences screen accessible

- **WHEN** user navigates to settings
- **THEN** journal preferences SHALL be available as a dedicated section

#### Scenario: Changes preview available

- **WHEN** user modifies preferences
- **THEN** system SHOULD show example of how it affects generated entries

#### Scenario: Reset to defaults

- **WHEN** user requests reset
- **THEN** all preferences SHALL be restored to default values

### Requirement: Preferences Applied to Generation

The system SHALL respect user preferences when building prompts and generating
journal entries.

#### Scenario: Preferences integrated into prompt

- **WHEN** generating a journal entry
- **THEN** all relevant preferences SHALL be incorporated into the AI prompt

#### Scenario: Privacy settings applied before cloud calls

- **WHEN** using cloud AI service
- **THEN** privacy settings SHALL sanitize context data before transmission

#### Scenario: Preferences affect both cloud and on-device generation

- **WHEN** generating with any AI tier
- **THEN** preferences SHALL be consistently applied regardless of generation
  method
