# Location Tracking Pipeline Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to
> implement this plan task-by-task.

**Goal:** Tighten Aura One's location pipeline so one authoritative tracker
drives location capture, hot queries are indexed, cache invalidation is
day-scoped, and map preload/render work no longer performs unnecessary
clustering.

**Architecture:** Keep `flutter_background_geolocation` as the production
continuous tracker, move UI and startup state to one persisted tracking source
of truth, and make clustering a day-scoped derived cache that is invalidated by
actual writes instead of global heuristics. Reduce map and preload work so raw
filtered points are used when cluster semantics are not needed.

**Tech Stack:** Flutter, Riverpod, Drift/SQLite, flutter_background_geolocation,
geolocator, flutter test, OpenSpec.

---

### Task 1: Copy Approved Spec Into Worktree

**Files:**

- Create: `openspec/changes/refactor-location-tracking-pipeline/proposal.md`
- Create: `openspec/changes/refactor-location-tracking-pipeline/design.md`
- Create: `openspec/changes/refactor-location-tracking-pipeline/tasks.md`
- Create:
  `openspec/changes/refactor-location-tracking-pipeline/specs/location-tracking-pipeline/spec.md`

**Step 1: Copy the approved change files into the worktree**

Use the already-approved content from the main workspace so the implementation
branch carries the spec with it.

**Step 2: Validate the change in the worktree**

Run: `openspec validate refactor-location-tracking-pipeline --strict` Expected:
valid change

### Task 2: Add Tests For Single-Tracker Startup

**Files:**

- Create: `mobile-app/test/services/location_startup_policy_test.dart`
- Modify: `mobile-app/lib/main.dart`
- Modify: `mobile-app/lib/services/background_location_service.dart`
- Modify: `mobile-app/lib/services/simple_location_service.dart`

**Step 1: Write failing tests**

Cover:

- startup does not start both continuous trackers
- repeated start calls are idempotent
- simple service can still provide one-shot foreground helpers without starting
  a second continuous stream

**Step 2: Run tests to verify failure**

Run:
`cd mobile-app && fvm flutter test test/services/location_startup_policy_test.dart`
Expected: FAIL because current startup still launches duplicate tracking paths

**Step 3: Implement minimal production changes**

Make `main.dart` start only the authoritative tracker. Make
`SimpleLocationService.startTracking()` a non-production helper or remove it
from normal startup. Add explicit idempotency guards to the active tracker
lifecycle.

**Step 4: Re-run focused tests**

Run:
`cd mobile-app && fvm flutter test test/services/location_startup_policy_test.dart`
Expected: PASS

### Task 3: Unify Tracking State And UI Toggles

**Files:**

- Modify: `mobile-app/lib/providers/settings_providers.dart`
- Modify: `mobile-app/lib/screens/privacy_screen.dart`
- Modify: `mobile-app/lib/widgets/location_settings_card.dart`
- Test: `mobile-app/test/providers/location_tracking_settings_test.dart`

**Step 1: Write failing provider/UI state tests**

Cover:

- one persisted source of truth for tracking enabled/disabled
- privacy/settings toggles target the same tracker state

**Step 2: Run tests to verify failure**

Run:
`cd mobile-app && fvm flutter test test/providers/location_tracking_settings_test.dart`

**Step 3: Implement minimal state unification**

Replace the separate simple-service toggle state with one provider backed by
persisted tracking state.

**Step 4: Re-run focused tests**

Run:
`cd mobile-app && fvm flutter test test/providers/location_tracking_settings_test.dart`
Expected: PASS

### Task 4: Add Database Indexes For Hot Paths

**Files:**

- Modify: `mobile-app/lib/database/location_database.dart`
- Test: `mobile-app/test/database/location_database_index_test.dart`

**Step 1: Write failing database/index coverage tests**

Check that hot-path indexes exist for timestamp and geofence event lookups.

**Step 2: Run tests to verify failure**

Run:
`cd mobile-app && fvm flutter test test/database/location_database_index_test.dart`

**Step 3: Implement indexes and migration support**

Add indexes for:

- `location_points(timestamp)`
- `geofence_events(timestamp)`
- `geofence_events(geofence_id, timestamp)`
- `movement_data(timestamp)` if needed for current hot queries

**Step 4: Re-run focused tests**

Run:
`cd mobile-app && fvm flutter test test/database/location_database_index_test.dart`
Expected: PASS

### Task 5: Replace Global Cluster Cache Invalidation With Day-Scoped Invalidation

**Files:**

- Modify: `mobile-app/lib/providers/location_clustering_provider.dart`
- Modify: `mobile-app/lib/providers/location_database_provider.dart`
- Possibly create:
  `mobile-app/lib/providers/location_cache_version_provider.dart`
- Test: `mobile-app/test/providers/location_clustering_invalidation_test.dart`

**Step 1: Write failing cache invalidation tests**

Cover:

- insert for one day invalidates only that day's cluster/journey cache
- unrelated days remain cached

**Step 2: Run tests to verify failure**

Run:
`cd mobile-app && fvm flutter test test/providers/location_clustering_invalidation_test.dart`

**Step 3: Implement day-scoped invalidation**

Use a day key or version token derived from writes rather than coarse 7-day
count deltas.

**Step 4: Re-run focused tests**

Run:
`cd mobile-app && fvm flutter test test/providers/location_clustering_invalidation_test.dart`
Expected: PASS

### Task 6: Fix Clustering Outlier Distance Math

**Files:**

- Modify: `mobile-app/lib/providers/location_clustering_provider.dart`
- Test: `mobile-app/test/providers/location_outlier_filter_test.dart`

**Step 1: Write failing outlier filter tests**

Cover real-meter threshold behavior for jump/speed/geographic outlier filtering.

**Step 2: Run tests to verify failure**

Run:
`cd mobile-app && fvm flutter test test/providers/location_outlier_filter_test.dart`

**Step 3: Implement correct distance math**

Use real Euclidean/Haversine meter calculations consistently for outlier
thresholds.

**Step 4: Re-run focused tests**

Run:
`cd mobile-app && fvm flutter test test/providers/location_outlier_filter_test.dart`
Expected: PASS

### Task 7: Remove Redundant Geofence Polling And Fix Service Lifecycle

**Files:**

- Modify: `mobile-app/lib/services/simple_location_service.dart`
- Test: `mobile-app/test/services/simple_location_service_lifecycle_test.dart`

**Step 1: Write failing lifecycle tests**

Cover:

- no duplicate timers/subscriptions on repeated init/start
- no minute-by-minute forced GPS polling during continuous tracking
- owned timers are cancelled on stop/dispose

**Step 2: Run tests to verify failure**

Run:
`cd mobile-app && fvm flutter test test/services/simple_location_service_lifecycle_test.dart`

**Step 3: Implement minimal lifecycle cleanup**

Store/cancel maintenance timers, remove redundant geofence polling, and cap/trim
unused in-memory history.

**Step 4: Re-run focused tests**

Run:
`cd mobile-app && fvm flutter test test/services/simple_location_service_lifecycle_test.dart`
Expected: PASS

### Task 8: Reduce Eager Map Preload And Skip Unneeded Clustering

**Files:**

- Modify: `mobile-app/lib/providers/preload_provider.dart`
- Modify: `mobile-app/lib/widgets/daily_canvas/map_widget.dart`
- Modify: `mobile-app/lib/screens/home_screen.dart`
- Modify: `mobile-app/lib/screens/history_screen.dart`
- Test: `mobile-app/test/providers/preload_provider_test.dart`

**Step 1: Write failing preload behavior tests**

Cover:

- path-only consumers do not force clustering preload
- adjacent-day preloads are conservative and non-duplicative

**Step 2: Run tests to verify failure**

Run:
`cd mobile-app && fvm flutter test test/providers/preload_provider_test.dart`

**Step 3: Implement minimal preload/render changes**

Use raw filtered points for path rendering and map bounds where possible. Only
compute clusters when a real cluster consumer requests them.

**Step 4: Re-run focused tests**

Run:
`cd mobile-app && fvm flutter test test/providers/preload_provider_test.dart`
Expected: PASS

### Task 9: Quarantine Stale Secondary Location Paths

**Files:**

- Modify: `mobile-app/lib/providers/realtime_clustering_provider.dart`
- Modify: `mobile-app/lib/providers/location_providers.dart`
- Possibly modify stale references in
  `mobile-app/lib/services/journal_service.dart`

**Step 1: Remove or clearly quarantine non-production clustering/tracking
paths**

Keep only what is needed for current production runtime behavior.

**Step 2: Verify repository search results**

Run targeted searches for duplicate or stale production location paths.

### Task 10: Final Verification

**Files:**

- Verify all touched files above

**Step 1: Validate OpenSpec in the worktree**

Run: `openspec validate refactor-location-tracking-pipeline --strict`

**Step 2: Run focused location test files**

Run the new location-focused tests added in this plan.

**Step 3: Run broader verification**

Run: `cd mobile-app && fvm flutter analyze`

Run: `cd mobile-app && fvm flutter test`

Expected: existing known HAR failures may remain; new location-refactor
regressions should not be introduced.
