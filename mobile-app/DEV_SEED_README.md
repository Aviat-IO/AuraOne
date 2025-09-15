# Development Database Seeding

## Overview

To help test the Search and Calendar features during development, the app includes an automatic database seeding feature that generates 60 days of realistic journal entries.

## How It Works

### Automatic Seeding

The database is automatically seeded when ALL of these conditions are met:
1. The app is running in **debug mode** (`flutter run` or `fvm flutter run`)
2. The database has fewer than 5 existing entries
3. The app is initialized for the first time

### What Gets Seeded

- **60 days** of journal entries (from 60 days ago to yesterday)
- Each entry includes:
  - Realistic daily content with morning, afternoon, and evening activities
  - Random mood indicators (Happy, Calm, Excited, etc.)
  - 3-8 activities per day including:
    - Location visits with GPS coordinates
    - Photo captures
    - Movement/step tracking
    - Calendar events
    - Manual activities
  - Relevant tags and summaries
  - Timestamps throughout the day

## Usage

### First Time Setup

1. Run the app in debug mode:
   ```bash
   fvm flutter run
   # or
   flutter run
   ```

2. The database will automatically be seeded on first launch
3. You'll see log messages indicating the seeding progress

### Resetting and Re-seeding

If you want to reset the database and seed it again:

1. **Option 1: Delete App Data**
   - Android: Settings → Apps → Aura One → Storage → Clear Data
   - iOS: Delete and reinstall the app

2. **Option 2: Fresh Install**
   ```bash
   # Uninstall the app
   fvm flutter clean

   # Run again
   fvm flutter run
   ```

## Important Notes

### Development Only

⚠️ **This feature is ONLY active in debug mode!**

- Seeding will **NEVER** occur in release builds (APK/IPA files)
- The seeding code is wrapped in `kDebugMode` checks
- Production users will never see test data

### Performance

- Initial seeding takes 5-10 seconds
- The app will show "Initializing..." during seeding
- Subsequent launches skip seeding if data exists

### Testing Different Scenarios

To test with different data patterns:
1. Clear the app data
2. Modify `lib/database/dev_seed_data.dart` to adjust:
   - Number of days (default: 60)
   - Activity types and frequencies
   - Mood patterns
   - Content variations
3. Run the app again

## Implementation Details

### Files Involved

- `lib/database/dev_seed_data.dart` - Seeding logic and data generation
- `lib/services/journal_service.dart` - Integration point during initialization
- `test/database/dev_seed_data_test.dart` - Unit tests for seeding

### Data Generation

The seeder uses randomized but realistic patterns:
- Varied daily routines
- Multiple location types (home, work, gym, etc.)
- Different activity patterns for weekdays vs weekends
- Realistic time distributions throughout the day
- Coherent narrative content

## Troubleshooting

### Seeding Not Working?

1. **Check you're in debug mode:**
   ```bash
   # Must use flutter run, not flutter build
   fvm flutter run
   ```

2. **Check database state:**
   - Look for log: "Development mode: Database already has data, skipping seed"
   - Clear app data if needed

3. **Check logs:**
   ```
   ✅ Database seeding complete - added 60 days of test data
   ```

### Seeding Takes Too Long?

- Normal duration: 5-10 seconds
- If longer, check device performance
- Consider reducing days in `dev_seed_data.dart`

## For Production Builds

When building for production:
```bash
# APK for Android (seeding disabled automatically)
fvm flutter build apk --release

# iOS (seeding disabled automatically)
fvm flutter build ios --release
```

The `kDebugMode` flag ensures seeding code never runs in production builds.