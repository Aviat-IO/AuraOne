# Place Registry Specification

## ADDED Requirements

### Requirement: Place Registry Database

The system SHALL maintain a local database of named places with geographic
coordinates, categories, and significance levels.

#### Scenario: Place record created

- **WHEN** user names a location
- **THEN** a place record SHALL be created with name, coordinates, category, and
  radius

#### Scenario: Geographic bounds defined

- **WHEN** creating a place
- **THEN** user SHALL define a radius in meters for matching future visits

#### Scenario: Neighborhood and city stored

- **WHEN** creating a place
- **THEN** system SHALL store neighborhood and city for contextual descriptions

### Requirement: Place Categorization

The system SHALL support categorizing places by type to enable contextual
descriptions.

#### Scenario: Category selected from predefined list

- **WHEN** naming a place
- **THEN** user SHALL select from categories: home, work, restaurant, cafe,
  park, gym, school, shop, entertainment, other

#### Scenario: Category affects journal language

- **WHEN** generating journal entry
- **THEN** place category SHALL influence how the location is described (e.g.,
  "had dinner at" for restaurants)

### Requirement: Place Significance Scoring

The system SHALL allow users to assign significance levels to places to control
mention frequency in journals.

#### Scenario: Significance levels available

- **WHEN** configuring a place
- **THEN** user SHALL be able to set significance: 0=never mention, 1=mention
  when relevant, 2=always highlight

#### Scenario: Low significance places omitted

- **WHEN** place has significance = 0
- **THEN** it SHALL NOT be mentioned in generated journals even if visited

#### Scenario: High significance places emphasized

- **WHEN** place has significance = 2
- **THEN** visits SHALL be prominently featured in journal narratives

### Requirement: Spatial Matching

The system SHALL match GPS coordinates to named places using spatial queries.

#### Scenario: Location matched to nearby place

- **WHEN** GPS coordinate is within place radius
- **THEN** system SHALL match to that place

#### Scenario: Multiple overlapping places handled

- **WHEN** GPS coordinate matches multiple places
- **THEN** system SHALL select the place with highest significance or smallest
  radius

#### Scenario: Unknown locations trigger naming prompt

- **WHEN** user visits a location multiple times (3+) without a place name
- **THEN** system SHALL suggest naming this frequent location

### Requirement: Place Custom Descriptions

The system SHALL allow users to add custom descriptions to places for richer
journal context.

#### Scenario: Custom description stored

- **WHEN** user provides a custom description
- **THEN** it SHALL be stored and available for journal generation (e.g., "my
  favorite coffee spot")

#### Scenario: Custom description used in journal

- **WHEN** generating entry for a place with custom description
- **THEN** system MAY include the custom description for additional context

### Requirement: Place Statistics Tracking

The system SHALL track visit statistics for each place.

#### Scenario: Visit count tracked

- **WHEN** location matches a place
- **THEN** system SHALL increment visit count for that place

#### Scenario: Time spent calculated

- **WHEN** location data spans time at a place
- **THEN** system SHALL calculate and store total time spent

#### Scenario: Last visit date tracked

- **WHEN** location matches a place
- **THEN** system SHALL update last_visit_date

### Requirement: Place Management Interface

The system SHALL provide UI for managing the place registry.

#### Scenario: Name place from map

- **WHEN** user taps a location on the map
- **THEN** system SHALL show dialog to name and categorize the place

#### Scenario: Frequent places suggested

- **WHEN** user views place management
- **THEN** system SHALL show unnamed frequently-visited locations for easy
  labeling

#### Scenario: Edit place details

- **WHEN** user selects a place
- **THEN** system SHALL allow editing name, category, radius, significance, and
  description

#### Scenario: Delete place

- **WHEN** user deletes a place
- **THEN** system SHALL remove from registry but preserve historical location
  data

#### Scenario: View place statistics

- **WHEN** viewing place details
- **THEN** system SHALL show visit count, total time spent, and last visit date
