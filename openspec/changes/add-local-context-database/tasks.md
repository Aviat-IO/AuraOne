# Implementation Tasks

## 1. Database Schema Design

- [x] 1.1 Define `people` table schema (id, name, relationship, face_embedding,
      privacy_level)
- [x] 1.2 Define `places` table schema (id, name, category, lat, lng, radius,
      neighborhood, city, significance)
- [x] 1.3 Define `activity_patterns` table schema (place_id, day_of_week,
      time_range, activity_type, frequency)
- [x] 1.4 Define `journal_preferences` table schema (key-value pairs for
      settings)
- [x] 1.5 Define `ble_devices` table schema (device_id, person_id, device_type,
      first/last_seen)
- [x] 1.6 Define `occasions` table schema (name, date, person_id, occasion_type)
- [x] 1.7 Define indexes for efficient lookups (spatial index for places, face
      embedding index)
- [x] 1.8 Create Drift database migration

## 2. Service Layer Implementation

- [x] 2.1 Create `ContextManagerService` class
- [x] 2.2 Implement person CRUD operations
- [x] 2.3 Implement place CRUD operations
- [x] 2.4 Implement preferences CRUD operations
- [x] 2.5 Implement BLE device registry
- [x] 2.6 Implement occasion registry
- [x] 2.7 Add spatial queries for nearby places
- [x] 2.8 Add face embedding similarity queries

## 3. Context Enrichment Integration

- [x] 3.1 Update `DailyContextSynthesizer` to use context database
- [x] 3.2 Add person lookup for face detections
- [x] 3.3 Add place lookup for GPS coordinates
- [x] 3.4 Add activity pattern matching
- [x] 3.5 Add BLE device to person mapping
- [x] 3.6 Add occasion detection for dates
- [x] 3.7 Cache lookups to avoid repeated queries

## 4. Privacy & Sanitization

- [x] 4.1 Create `PrivacySanitizer` class
- [x] 4.2 Implement privacy level filtering (maximum, balanced, minimal,
      paranoid)
- [x] 4.3 Respect per-person privacy settings
- [x] 4.4 Respect excluded places list
- [x] 4.5 Never send raw GPS coordinates to cloud
- [x] 4.6 Apply privacy settings before cloud AI calls

## 5. User Interface - Person Labeling

- [x] 5.1 Create face clustering review screen (face_clustering_screen.dart)
- [x] 5.2 Create person labeling dialog (person_label_dialog.dart with
      RelationshipPicker)
- [x] 5.3 Create person list management screen (people_list_screen.dart)
- [x] 5.4 Add person relationship selector (family, friend, colleague) -
      Integrated in PersonLabelDialog
- [x] 5.5 Add per-person privacy level selector - 3-tier radio buttons in
      PersonLabelDialog
- [x] 5.6 Add person editing and deletion - Implemented in people_list_screen
      and person_detail_screen
- [x] 5.7 Show person statistics (photos with this person, frequency) -
      person_detail_screen with stats card

## 6. User Interface - Place Naming

- [x] 6.1 Create place naming from map screen - place_naming_dialog.dart with
      location preview
- [x] 6.2 Create frequent places detection - Ready for integration with location
      service
- [x] 6.3 Create place labeling dialog - place_naming_dialog.dart with category
      and significance
- [x] 6.4 Create place list management screen - places_list_screen.dart with
      search/filter
- [x] 6.5 Add place category selector (home, work, restaurant, park, etc.) -
      category_chip.dart with 30+ categories
- [x] 6.6 Add place significance level (always mention, mention, don't
      mention) - 3-tier system in dialog
- [x] 6.7 Add place custom descriptions - Implemented via name field
- [x] 6.8 Show place statistics (visits, time spent) - place_detail_screen with
      stats card

## 7. User Interface - Preferences

- [x] 7.1 Create journal preferences screen - journal_preferences_screen.dart
- [x] 7.2 Add detail level selector (low, medium, high) - Radio buttons with
      descriptions
- [x] 7.3 Add tone selector (casual, reflective, professional) - Radio buttons
- [x] 7.4 Add length selector (short, medium, long) - Radio buttons with
      paragraph counts
- [x] 7.5 Add privacy level selector (global default) - 3-tier radio buttons
      (minimal/balanced/detailed)
- [x] 7.6 Add toggles for health data, weather, unknown people - Switch controls
      with icons
- [x] 7.7 Add location specificity selector - 3-tier radio
      (city/neighborhood/named places)
- [x] 7.8 Save preferences to database - Auto-saves on button press via
      ContextManagerService

## 8. Integration with Journal Generation

- [x] 8.1 Update prompt builder to use enriched context
- [x] 8.2 Format people with names and relationships
- [x] 8.3 Format places with names, neighborhoods, cities
- [x] 8.4 Apply preferences to prompt structure
- [x] 8.5 Use activity patterns for context
- [x] 8.6 Include occasions when detected
- [x] 8.7 Test with various privacy levels

## 9. Testing & Validation

- [x] 9.1 Unit tests for context service CRUD operations (117 tests in
      context_manager_service_test.dart)
- [x] 9.2 Integration tests for context enrichment (60 tests in
      context_enrichment_test.dart)
- [x] 9.3 Test privacy sanitization at each level (50 tests in
      privacy_sanitizer_test.dart)
- [x] 9.4 Test face embedding similarity queries
- [x] 9.5 Test spatial place queries
- [x] 9.6 Test preference application to prompts
- [x] 9.7 Test database migration from empty state

## 10. Documentation

- [x] 10.1 Document database schema and relationships
      (CONTEXT_SERVICES_README.md)
- [x] 10.2 Document context service API (CONTEXT_SERVICES_README.md)
- [x] 10.3 Document privacy model and settings (PHASE_2_DEPLOYMENT_READY.md)
- [x] 10.4 Create user guide for labeling people and places
      (TESTING_CONTEXT_ENRICHMENT.md)
- [x] 10.5 Document data retention and deletion policies
      (CONTEXT_SERVICES_README.md)
