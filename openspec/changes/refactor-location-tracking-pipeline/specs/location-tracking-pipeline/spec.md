## ADDED Requirements

### Requirement: The App SHALL Use One Authoritative Production Location Tracker

The system SHALL ensure that only one production location capture pipeline is
actively writing location points for normal runtime operation.

#### Scenario: Background tracking enabled

- **WHEN** the user enables persistent location tracking
- **THEN** the app SHALL start only the authoritative production tracker
- **AND** the app SHALL NOT start a second location write pipeline for the same
  runtime mode

#### Scenario: Foreground helper access

- **WHEN** the app needs a one-shot foreground location read or foreground-only
  helper behavior
- **THEN** that behavior SHALL NOT create a second continuous location write
  stream

### Requirement: Tracking State SHALL Have One Persisted Source Of Truth

The system SHALL expose location-tracking state through one persisted source of
truth that matches the actual active tracker state.

#### Scenario: User toggles tracking off

- **WHEN** the user disables location tracking from settings or privacy controls
- **THEN** the active tracker SHALL stop
- **AND** all tracking UI SHALL reflect the stopped state consistently

#### Scenario: User toggles tracking on

- **WHEN** the user enables location tracking
- **THEN** the active tracker SHALL start once
- **AND** tracking UI SHALL reflect the running state consistently

### Requirement: Location-Derived Caches SHALL Invalidate By Affected Day

The system SHALL invalidate location clustering and related derived results by
the affected day whenever location data for that day changes.

#### Scenario: New point inserted for a day

- **WHEN** a location point is inserted for a specific day
- **THEN** cached clustering and journey results for that day SHALL be
  invalidated before the next read

#### Scenario: Unrelated day remains cached

- **WHEN** location data changes for one day
- **THEN** cached derived results for unrelated days SHALL remain valid unless
  their underlying data changed

### Requirement: Hot Location Queries SHALL Be Indexed

The system SHALL maintain database indexes for hot query paths used by tracking,
clustering, summaries, and geofence history.

#### Scenario: Latest location lookup

- **WHEN** the app queries the latest stored location point
- **THEN** the query SHALL use an indexed timestamp path

#### Scenario: Geofence history lookup

- **WHEN** the app queries recent geofence events or a geofence event range
- **THEN** the query SHALL use indexed timestamp and geofence lookup paths

### Requirement: Geofence Evaluation SHALL Avoid Redundant Polling

The system SHALL avoid periodic high-accuracy location polling when equivalent
geofence evaluation can be driven from the active tracker stream.

#### Scenario: Continuous tracking active

- **WHEN** the app is already receiving location updates from the active tracker
- **THEN** geofence evaluation SHALL use those updates instead of redundant
  periodic location reads

### Requirement: Map Preload SHALL Avoid Unnecessary Clustering

The system SHALL avoid eager clustering work for screens that only need raw
location paths or lightweight map state.

#### Scenario: Path-only map preload

- **WHEN** a screen preloads location data for path rendering only
- **THEN** the app SHALL preload raw filtered points without forcing a full
  clustering pass

#### Scenario: Cluster consumer present

- **WHEN** a screen or feature explicitly needs cluster semantics
- **THEN** the app MAY compute clusters for that day

### Requirement: Location Tracking Lifecycle SHALL Be Idempotent

The system SHALL prevent duplicate timers, streams, or maintenance jobs from
being created when location services are initialized or started repeatedly.

#### Scenario: Start called twice

- **WHEN** location tracking start is invoked while tracking is already active
- **THEN** the system SHALL keep one active tracking lifecycle and SHALL NOT
  create duplicate timers or listeners

#### Scenario: Service disposed

- **WHEN** the location service lifecycle ends
- **THEN** the system SHALL cancel timers, subscriptions, and background helper
  work it owns
