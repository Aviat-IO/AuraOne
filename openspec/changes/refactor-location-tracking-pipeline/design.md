## Context

Aura One is a local-first journaling app, so location tracking is one of its
highest-leverage background systems. The current implementation mixes a
plugin-based background tracker with a simpler foreground stream, plus multiple
clustering and preload paths. The result is avoidable duplicate work and a
growing risk of stale derived state as the local dataset expands.

## Goals / Non-Goals

- Goals:
  - reduce battery and CPU cost from duplicate location work
  - keep location-derived UI and AI inputs fresh as new points arrive
  - improve database scalability for long-lived local journals
  - preserve current user-facing location features while tightening internals
- Non-Goals:
  - redesigning the map UI itself
  - adding new location-based product features
  - changing the app's privacy posture for location data

## Decisions

- Decision: keep one authoritative production tracker active at a time.
  - Recommended path: `flutter_background_geolocation` for production capture,
    with a much smaller foreground helper role for the simple service or full
    retirement of the simple tracker path.
  - Rationale: the current dual-tracker setup is the largest source of
    duplicated writes and downstream work.

- Decision: treat clustering as a derived, day-scoped cache.
  - Rationale: location clusters are consumed per day across Today, History, AI
    summaries, and maps. Invalidation should happen at that same day boundary,
    not via coarse global heuristics.

- Decision: optimize the database before adding more heuristics.
  - Rationale: hot-path timestamp and geofence queries are already frequent, and
    missing indexes will get worse as the journal grows.

- Decision: decouple map path rendering from cluster computation where possible.
  - Rationale: the map currently renders raw paths and no longer needs cluster
    markers, but clustering is still part of preload/render work.

## Risks / Trade-offs

- Switching to a single tracker may expose assumptions baked into UI code that
  currently relies on simple-service providers.
  - Mitigation: preserve a small compatibility layer while removing the
    duplicate capture path.

- Day-scoped invalidation increases cache churn compared with the current coarse
  threshold.
  - Mitigation: pair invalidation with tighter per-day keys and avoid clustering
    where raw points are sufficient.

- Database indexes can require a migration and slightly increase write cost.
  - Mitigation: add only indexes that directly support hot query paths.

## Migration Plan

1. Add indexes and low-risk internal correctness fixes first.
2. Move tracker startup to one authoritative path.
3. Replace global cache invalidation with day-scoped invalidation.
4. Reduce preload/map clustering work.
5. Remove stale secondary runtime paths and compatibility shims last.

## Open Questions

- Whether `SimpleLocationService` should remain as a foreground utility shell or
  be fully removed.
- Whether map bounds and unique-location counts should be derived from raw
  filtered points instead of clusters everywhere.
