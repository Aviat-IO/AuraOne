# Person Recognition Specification

## ADDED Requirements

### Requirement: Person Registry Database

The system SHALL maintain a local SQLite database of people with names,
relationships, face embeddings, and privacy settings.

#### Scenario: Person record created

- **WHEN** user labels a face cluster
- **THEN** a person record SHALL be created with name, relationship, and
  associated face embedding

#### Scenario: Face embedding stored

- **WHEN** creating a person record
- **THEN** the face embedding SHALL be stored as a binary blob for similarity
  matching

#### Scenario: Privacy level configurable

- **WHEN** creating or editing a person
- **THEN** user SHALL be able to set privacy level (0=omit, 1=first name, 2=full
  detail)

### Requirement: Person-Photo Linking

The system SHALL link detected faces in photos to known people in the registry.

#### Scenario: Face matched to known person

- **WHEN** face is detected in a photo
- **THEN** system SHALL search for similar face embeddings in the person
  registry

#### Scenario: Match confidence threshold

- **WHEN** comparing face embeddings
- **THEN** system SHALL only match if confidence > 0.7 threshold

#### Scenario: Unknown faces clustered

- **WHEN** face does not match any known person
- **THEN** system SHALL add to unknown face cluster for future labeling

### Requirement: Relationship Tracking

The system SHALL allow users to specify relationships for each person.

#### Scenario: Relationship options available

- **WHEN** labeling a person
- **THEN** user SHALL be able to select from predefined relationships (son,
  daughter, partner, friend, colleague, family)

#### Scenario: Custom relationships supported

- **WHEN** predefined relationships are insufficient
- **THEN** user SHALL be able to enter a custom relationship label

### Requirement: Person Privacy Controls

The system SHALL respect per-person privacy settings when generating journals.

#### Scenario: Privacy level 0 excludes person

- **WHEN** person has privacy_level = 0
- **THEN** they SHALL NOT be mentioned in generated journal entries

#### Scenario: Privacy level 1 uses first name

- **WHEN** person has privacy_level = 1
- **THEN** only their first name SHALL be included in journals

#### Scenario: Privacy level 2 includes full details

- **WHEN** person has privacy_level = 2
- **THEN** full name and relationship SHALL be included in journals

### Requirement: Person Management Interface

The system SHALL provide UI for managing the person registry.

#### Scenario: List all people

- **WHEN** user accesses person management
- **THEN** system SHALL display all registered people with photos and statistics

#### Scenario: Edit person details

- **WHEN** user selects a person
- **THEN** system SHALL allow editing name, relationship, and privacy level

#### Scenario: Delete person

- **WHEN** user deletes a person
- **THEN** system SHALL remove from registry but preserve photo-face detection
  data

#### Scenario: View person statistics

- **WHEN** viewing a person's details
- **THEN** system SHALL show count of photos with this person and frequency of
  appearances
