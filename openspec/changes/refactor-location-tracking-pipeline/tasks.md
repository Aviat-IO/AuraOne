## 1. Implementation

- [ ] 1.1 Inventory and remove duplicate tracker startup paths so only one
      production tracker can run at a time
- [ ] 1.2 Unify persisted tracking state and UI toggles around a single source
      of truth
- [ ] 1.3 Add database indexes for hot location and geofence query paths
- [ ] 1.4 Replace coarse clustering cache invalidation with day-scoped
      invalidation based on location writes
- [ ] 1.5 Fix clustering distance/outlier math so filtering thresholds operate
      in real meters
- [ ] 1.6 Remove redundant geofence polling and make location tracking lifecycle
      idempotent
- [ ] 1.7 Reduce eager location/map preloading and skip clustering when only raw
      path rendering is needed
- [ ] 1.8 Remove or quarantine stale secondary clustering/tracking paths that
      are not part of the production runtime
- [ ] 1.9 Add tests for tracker exclusivity, cache invalidation, and map preload
      behavior
- [ ] 1.10 Run verification and document any remaining follow-up items
