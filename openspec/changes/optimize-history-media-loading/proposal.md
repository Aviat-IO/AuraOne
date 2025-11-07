## Why

The History > Map, History > Media, Today > Map, and Today > Media views currently exhibit inconsistent loading performance. Users experience sporadic behavior where views load quickly in some cases but take minutes or fail to load entirely in others. This creates a poor user experience and makes the app feel unreliable.

## What Changes

- Implement data limiting to prevent unbounded loading of location points (max 1000) and media items (max 200) per day
- Add debounced cache invalidation (30-second debounce) to prevent cache thrashing
- Implement timeouts for all data loading operations (15s for clustering, 8s for media queries, 2s for map calculations)
- Move expensive synchronous operations to background threads
- Add graceful degradation with fallback algorithms when complex operations fail
- Implement progressive loading for large datasets

## Impact

- Affected specs: New view-performance capability
- Affected code: Location clustering services, media loading services, map rendering components, cache management
- Breaking changes: None - all changes are performance optimizations that maintain existing behavior while improving reliability