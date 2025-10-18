# Local Context Database for Personalized Journaling

## Why

Generated journal entries are impersonal and generic because the system lacks
knowledge about the user's life context:

- Says "photographed a child" instead of "Charles (my son)"
- Says "visited 2 locations" instead of "Liberty Park and Discovery Museum in
  Salt Lake City"
- Cannot reference user's preferences for detail level, privacy, or writing
  style
- No memory of place names user has assigned or relationships between people
- Cannot personalize based on user's typical patterns and preferences

To create the world's best auto-journaling app, we need a rich local context
layer that knows the user's people, places, and preferences.

## What Changes

- Create comprehensive local Drift database schema for contextual data
- Add `people` table with names, relationships, face embeddings, and privacy
  levels
- Add `places` table with custom names, categories, neighborhoods, and
  significance scores
- Add `activity_patterns` table to learn user's typical behaviors
- Add `journal_preferences` table for user-controlled writing style and privacy
  settings
- Add `ble_devices` table to map devices to people for social context
- Add `occasions` table for birthdays, anniversaries, and special events
- Create service layer to manage context data (CRUD operations)
- Build UI for users to label people, name places, and set preferences
- Integrate context lookups into journal generation pipeline

**Privacy-first approach:**

- All data stays on-device (local SQLite via Drift)
- User explicitly labels people and places (no automatic assumptions)
- Granular privacy controls per person and per place
- Option to exclude specific people/places from journals entirely

## Impact

**Affected specs:**

- `person-recognition` (new) - Person registry and face embeddings
- `place-registry` (new) - Place naming and categorization
- `journal-preferences` (new) - User preferences and privacy settings
- `journal-generation` (existing) - Integration with context data
- `database-schema` (existing) - New Drift tables

**Affected code:**

- `mobile-app/lib/database/` - New Drift table definitions
- `mobile-app/lib/services/context_manager_service.dart` (new) - Context CRUD
- `mobile-app/lib/services/ai/cloud_gemini_adapter.dart` - Context integration
- `mobile-app/lib/services/daily_context_synthesizer.dart` - Context enrichment
- `mobile-app/lib/screens/settings/` - New settings screens
- `mobile-app/lib/widgets/` - Person/place labeling widgets

**User-facing impact:**

- Entries will use actual names and specific places
- "Spent time with Charles at Liberty Park" vs "photographed child at park"
- Privacy controls for what appears in journals
- Ability to customize writing style and detail level
- Progressive improvement as user labels more context

**Technical considerations:**

- Database migration strategy for new tables
- Efficient lookups during journal generation (indexed queries)
- Face embedding storage format (binary blobs)
- Geocoding cache to reduce API calls
- Privacy settings respected during cloud AI calls

## Success Metrics

- Users label average of 5+ people within first week
- Users name average of 10+ frequent places within first month
- 80%+ of journal entries use at least one person/place name
- User satisfaction with personalization > 4.5/5
- Privacy control adoption rate > 60% of users customize settings
