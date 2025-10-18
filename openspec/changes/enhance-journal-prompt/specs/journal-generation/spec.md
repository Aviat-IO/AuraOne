# Journal Generation Specification

## ADDED Requirements

### Requirement: Structured Prompt Architecture

The journal generation system SHALL use a multi-section prompt structure that
clearly separates writing guidelines, tone requirements, and content rules.

#### Scenario: Prompt includes all required sections

- **WHEN** generating a journal entry prompt
- **THEN** the prompt SHALL include WRITING STYLE, TONE GUIDELINES, WHAT TO
  EXCLUDE, WHAT TO EMPHASIZE, and MEASUREMENT UNITS sections

#### Scenario: Sections are clearly delineated

- **WHEN** building the prompt
- **THEN** each section SHALL be clearly labeled and separated for LLM clarity

### Requirement: Natural Writing Style Guidelines

The system SHALL instruct the LLM to write with proper grammar, varied sentence
structure, and natural paragraph flow.

#### Scenario: Grammar requirements specified

- **WHEN** constructing the prompt
- **THEN** it SHALL include instructions for complete, grammatically correct
  sentences with proper punctuation

#### Scenario: Sentence variety required

- **WHEN** constructing the prompt
- **THEN** it SHALL instruct to vary sentence structure and avoid repetitive
  patterns

#### Scenario: Chronological ordering

- **WHEN** constructing the prompt
- **THEN** it SHALL instruct to present information in chronological order
  (morning → afternoon → evening)

### Requirement: Exclusion of Uninteresting Details

The system SHALL explicitly instruct the LLM to exclude photo-technical details,
meta-commentary, and mundane observations.

#### Scenario: Photo technical details excluded

- **WHEN** generating an entry
- **THEN** the prompt SHALL instruct to exclude shadows, lighting, camera
  angles, and composition details

#### Scenario: Meta-commentary excluded

- **WHEN** generating an entry
- **THEN** the prompt SHALL instruct to avoid phrases like "photographed",
  "captured", "you can see in the photo"

#### Scenario: Trivial artifacts excluded

- **WHEN** generating an entry
- **THEN** the prompt SHALL instruct to exclude reflections, shadows on
  pavement, and background clutter

#### Scenario: Self-referential commentary excluded

- **WHEN** generating an entry
- **THEN** the prompt SHALL instruct to avoid "from where I was standing" and
  "visible in the image"

### Requirement: Locale-Aware Measurement Units

The system SHALL automatically detect user locale and use appropriate
measurement units in the prompt.

#### Scenario: Imperial units for US users

- **WHEN** user locale is US, Liberia, or Myanmar
- **THEN** the prompt SHALL instruct to convert metric to imperial (km to miles,
  Celsius to Fahrenheit)

#### Scenario: Metric units for international users

- **WHEN** user locale is not US, Liberia, or Myanmar
- **THEN** the prompt SHALL instruct to use metric measurements with clear
  formatting

#### Scenario: Measurement conversion examples provided

- **WHEN** using imperial mode
- **THEN** the prompt SHALL include example: "traveled 2.9 miles" instead of
  "covered 4.7km"

### Requirement: Few-Shot Learning Examples

The system SHALL include concrete examples of good and bad journal entries to
guide the LLM.

#### Scenario: Good example provided

- **WHEN** constructing the prompt
- **THEN** it SHALL include at least one example of a well-written journal entry
  demonstrating desired style

#### Scenario: Bad example provided

- **WHEN** constructing the prompt
- **THEN** it SHALL include at least one example of poorly-written entry showing
  what to avoid

#### Scenario: Examples demonstrate key differences

- **WHEN** examples are included
- **THEN** they SHALL clearly illustrate the difference between
  surveillance-report and human-like journal writing

### Requirement: Structured Context Formatting

The system SHALL format daily context data into structured sections rather than
unformatted data dumps.

#### Scenario: People context formatted

- **WHEN** daily context includes detected people
- **THEN** it SHALL be formatted as a structured "PEOPLE MENTIONED TODAY"
  section

#### Scenario: Places context formatted

- **WHEN** daily context includes locations
- **THEN** it SHALL be formatted as a structured "PLACES VISITED" section with
  place names and neighborhoods

#### Scenario: Activities context formatted

- **WHEN** daily context includes activities
- **THEN** it SHALL be formatted as a structured section grouping related
  activities

#### Scenario: Timeline formatted chronologically

- **WHEN** daily context includes timeline events
- **THEN** they SHALL be formatted in chronological order with time, place, and
  activity

### Requirement: Data Preprocessing Before Prompt

The system SHALL preprocess raw data to create meaningful context before
including in prompts.

#### Scenario: Location counts transformed

- **WHEN** raw data contains location counts
- **THEN** it SHALL be transformed to actual place names with geographic context

#### Scenario: Timestamps made contextual

- **WHEN** raw data contains exact timestamps
- **THEN** they SHALL be transformed to contextual time references (morning,
  afternoon, mid-day) unless specifically meaningful

#### Scenario: Generic detections enriched

- **WHEN** raw data contains generic person/object detections
- **THEN** they SHALL be enriched with available context before sending to LLM

### Requirement: Objective Factual Tone

The system SHALL instruct the LLM to maintain an objective, factual tone without
assumptions about feelings or emotions.

#### Scenario: Observable data only

- **WHEN** generating an entry
- **THEN** the prompt SHALL instruct to describe only what happened, where, and
  when

#### Scenario: Emotional adjectives avoided

- **WHEN** generating an entry
- **THEN** the prompt SHALL instruct to avoid subjective adjectives like
  "amazing", "wonderful", "enjoyed"

#### Scenario: No feeling assumptions

- **WHEN** generating an entry
- **THEN** the prompt SHALL instruct not to make assumptions about feelings or
  subjective experiences
