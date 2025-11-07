# Shared Components Architecture

## Overview

This document describes the shared component architecture used in the Aura One mobile app to ensure code reuse and consistency between different screens.

## DailyEntryView - The Core Shared Component

### What is it?

`DailyEntryView` (`lib/widgets/daily_entry_view.dart`) is the primary shared widget that displays daily content for a specific date. It contains 4 sub-tabs:

1. **Journal** - AI-generated or manual journal entries
2. **Timeline** - Activity timeline for the day
3. **Map** - Location visualization with clustering
4. **Media** - Photo/video gallery for the day

### Where is it used?

The `DailyEntryView` widget is used by **TWO** main screens:

| Screen | File | Purpose | Date Source |
|--------|------|---------|-------------|
| **Today** | `lib/screens/home_screen.dart` | Shows current day | `DateTime.now()` |
| **History** | `lib/screens/history_screen.dart` | Shows selected historical date | Calendar selection |

### Why is this important?

**Any change to `DailyEntryView` or its sub-components affects BOTH screens.**

This is **intentional** and provides several benefits:

- ✅ **Consistency**: Today and History views behave identically
- ✅ **Maintainability**: Fix bugs in one place, fixed everywhere
- ✅ **Code reuse**: No duplication between screens
- ✅ **Testing**: Test once, validates both screens

## Sub-Components

The following widgets are used by `DailyEntryView` and are therefore shared:

| Component | File | Purpose |
|-----------|------|---------|
| `TimelineWidget` | `lib/widgets/daily_canvas/timeline_widget.dart` | Activity timeline visualization |
| `MapWidget` | `lib/widgets/daily_canvas/map_widget.dart` | Location map with clustering |
| `MediaGalleryWidget` | `lib/widgets/daily_canvas/media_gallery_widget.dart` | Photo/video gallery |

## Data Loading Architecture

Both Today and History views use the **same data providers**:

```dart
// Location data
locationPointsForDateProvider(date)
clusteredLocationsProvider(date)

// Media data
mediaItemsProvider((date: date, includeDeleted: bool))

// Journal data
journalServiceProvider
```

This ensures:
- Consistent data access patterns
- Shared caching benefits
- Unified performance optimizations

## Making Changes

### ✅ DO:

- Make changes to `DailyEntryView` when you want to affect both Today and History
- Test changes in both Today and History screens after modifications
- Update this documentation if you change the architecture

### ❌ DON'T:

- Create separate implementations for Today and History
- Duplicate code between screens
- Make screen-specific hacks in shared components

### If you need screen-specific behavior:

Use the configuration parameters:

```dart
DailyEntryView(
  date: DateTime.now(),
  enableAI: true,              // Control AI generation
  enableMediaSelection: true,  // Control media selection mode
)
```

## Performance Considerations

Since both screens share the same components:

1. **Caching**: Data is cached by date, benefiting both screens
2. **Preloading**: The `preloadProvider` warms cache for adjacent dates
3. **Limits**: Data limits (1000 location points, 200 media items) apply uniformly

## Recent Changes

- Added aggressive photo scanning when Media tab is viewed
- Reduced scan interval from 30 minutes to 5 minutes
- Added photo library change detection for immediate scanning
- Relaxed location accuracy filter from 30m to 100m
- Fixed async data loading to use `ref.read().future` instead of `ref.watch().when()`

## Questions?

If you're unsure whether to modify the shared components or create screen-specific code, ask:

1. Should Today and History behave differently in this case?
   - **No** → Modify the shared component
   - **Yes** → Use configuration parameters or create a new screen-specific component

2. Is this a general improvement or a screen-specific fix?
   - **General** → Modify the shared component
   - **Specific** → Check if you can use parameters, otherwise consider alternatives
