## Why

Aura One's current location stack is doing too much work for the same user
benefit. The app can run two tracking pipelines at once, re-cluster the same day
multiple times, preload expensive map data too aggressively, and query unindexed
location tables on hot paths. That combination risks battery drain, stale map
state, and performance degradation as the local database grows.

## What Changes

- Refactor location capture so the app uses a single authoritative production
  tracking pipeline at a time.
- Unify location-tracking settings so UI state reflects actual tracker state.
- Add database indexes for hot timestamp and geofence queries.
- Replace coarse global clustering cache invalidation with day-scoped
  invalidation tied to location writes.
- Remove redundant geofence polling and other duplicate location work.
- Narrow map preloading so clustering only runs when a cluster consumer actually
  needs it.
- Clean up stale or secondary location/clustering paths that are no longer part
  of the primary runtime.

## Impact

- Affected specs: `location-tracking-pipeline`
- Affected code:
  - `mobile-app/lib/main.dart`
  - `mobile-app/lib/services/background_location_service.dart`
  - `mobile-app/lib/services/simple_location_service.dart`
  - `mobile-app/lib/database/location_database.dart`
  - `mobile-app/lib/providers/location_database_provider.dart`
  - `mobile-app/lib/providers/location_clustering_provider.dart`
  - `mobile-app/lib/providers/preload_provider.dart`
  - `mobile-app/lib/widgets/daily_canvas/map_widget.dart`
  - related settings and permission flows
