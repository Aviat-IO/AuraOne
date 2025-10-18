# Implementation Tasks

## 1. Database Schema Design

- [ ] 1.1 Define `people` table schema (id, name, relationship, face_embedding,
      privacy_level)
- [ ] 1.2 Define `places` table schema (id, name, category, lat, lng, radius,
      neighborhood, city, significance)
- [ ] 1.3 Define `activity_patterns` table schema (place_id, day_of_week,
      time_range, activity_type, frequency)
- [ ] 1.4 Define `journal_preferences` table schema (key-value pairs for
      settings)
- [ ] 1.5 Define `ble_devices` table schema (device_id, person_id, device_type,
      first/last_seen)
- [ ] 1.6 Define `occasions` table schema (name, date, person_id, occasion_type)
- [ ] 1.7 Define indexes for efficient lookups (spatial index for places, face
      embedding index)
- [ ] 1.8 Create Drift database migration

## 2. Service Layer Implementation

- [ ] 2.1 Create `ContextManagerService` class
- [ ] 2.2 Implement person CRUD operations
- [ ] 2.3 Implement place CRUD operations
- [ ] 2.4 Implement preferences CRUD operations
- [ ] 2.5 Implement BLE device registry
- [ ] 2.6 Implement occasion registry
- [ ] 2.7 Add spatial queries for nearby places
- [ ] 2.8 Add face embedding similarity queries

## 3. Context Enrichment Integration

- [ ] 3.1 Update `DailyContextSynthesizer` to use context database
- [ ] 3.2 Add person lookup for face detections
- [ ] 3.3 Add place lookup for GPS coordinates
- [ ] 3.4 Add activity pattern matching
- [ ] 3.5 Add BLE device to person mapping
- [ ] 3.6 Add occasion detection for dates
- [ ] 3.7 Cache lookups to avoid repeated queries

## 4. Privacy & Sanitization

- [ ] 4.1 Create `PrivacySanitizer` class
- [ ] 4.2 Implement privacy level filtering (maximum, balanced, minimal,
      paranoid)
- [ ] 4.3 Respect per-person privacy settings
- [ ] 4.4 Respect excluded places list
- [ ] 4.5 Never send raw GPS coordinates to cloud
- [ ] 4.6 Apply privacy settings before cloud AI calls

## 5. User Interface - Person Labeling

- [ ] 5.1 Create face clustering review screen
- [ ] 5.2 Create person labeling dialog
- [ ] 5.3 Create person list management screen
- [ ] 5.4 Add person relationship selector (family, friend, colleague)
- [ ] 5.5 Add per-person privacy level selector
- [ ] 5.6 Add person editing and deletion
- [ ] 5.7 Show person statistics (photos with this person, frequency)

## 6. User Interface - Place Naming

- [ ] 6.1 Create place naming from map screen
- [ ] 6.2 Create frequent places detection
- [ ] 6.3 Create place labeling dialog
- [ ] 6.4 Create place list management screen
- [ ] 6.5 Add place category selector (home, work, restaurant, park, etc.)
- [ ] 6.6 Add place significance level (always mention, mention, don't mention)
- [ ] 6.7 Add place custom descriptions
- [ ] 6.8 Show place statistics (visits, time spent)

## 7. User Interface - Preferences

- [ ] 7.1 Create journal preferences screen
- [ ] 7.2 Add detail level selector (low, medium, high)
- [ ] 7.3 Add tone selector (casual, reflective, professional)
- [ ] 7.4 Add length selector (short, medium, long)
- [ ] 7.5 Add privacy level selector (global default)
- [ ] 7.6 Add toggles for health data, weather, unknown people
- [ ] 7.7 Add location specificity selector
- [ ] 7.8 Save preferences to database

## 8. Integration with Journal Generation

- [ ] 8.1 Update prompt builder to use enriched context
- [ ] 8.2 Format people with names and relationships
- [ ] 8.3 Format places with names, neighborhoods, cities
- [ ] 8.4 Apply preferences to prompt structure
- [ ] 8.5 Use activity patterns for context
- [ ] 8.6 Include occasions when detected
- [ ] 8.7 Test with various privacy levels

## 9. Testing & Validation

- [ ] 9.1 Unit tests for context service CRUD operations
- [ ] 9.2 Integration tests for context enrichment
- [ ] 9.3 Test privacy sanitization at each level
- [ ] 9.4 Test face embedding similarity queries
- [ ] 9.5 Test spatial place queries
- [ ] 9.6 Test preference application to prompts
- [ ] 9.7 Test database migration from empty state

## 10. Documentation

- [ ] 10.1 Document database schema and relationships
- [ ] 10.2 Document context service API
- [ ] 10.3 Document privacy model and settings
- [ ] 10.4 Create user guide for labeling people and places
- [ ] 10.5 Document data retention and deletion policies
