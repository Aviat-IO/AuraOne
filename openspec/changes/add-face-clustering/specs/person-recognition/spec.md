# Person Recognition Specification (Face Clustering Extension)

## ADDED Requirements

### Requirement: Face Detection and Embedding Extraction

The system SHALL detect faces in photos and extract face embeddings for
similarity matching.

#### Scenario: Face detected in photo

- **WHEN** processing a photo with ML Kit Face Detection
- **THEN** system SHALL detect all visible faces and extract bounding boxes

#### Scenario: Face embedding extracted

- **WHEN** face is detected
- **THEN** system SHALL extract a feature vector (embedding) representing the
  face

#### Scenario: Embedding stored with photo reference

- **WHEN** face embedding is extracted
- **THEN** it SHALL be stored with reference to photo and bounding box
  coordinates

### Requirement: Face Clustering Algorithm

The system SHALL cluster similar faces together using embedding similarity.

#### Scenario: Initial clustering of existing photos

- **WHEN** user initiates face clustering
- **THEN** system SHALL cluster all detected faces based on embedding similarity

#### Scenario: Incremental clustering for new photos

- **WHEN** new photos are added
- **THEN** system SHALL add new faces to existing clusters or create new
  clusters

#### Scenario: Similarity threshold configurable

- **WHEN** clustering faces
- **THEN** system SHALL use a configurable similarity threshold (default 0.7)
  for cluster membership

#### Scenario: Outliers handled

- **WHEN** face does not match any cluster with sufficient confidence
- **THEN** it SHALL be placed in a separate "unclustered" group for review

### Requirement: Cluster Quality Management

The system SHALL maintain high-quality clusters representing individual people.

#### Scenario: Cluster centroid updated

- **WHEN** new faces added to cluster
- **THEN** cluster centroid embedding SHALL be updated to reflect all members

#### Scenario: Cluster splitting detection

- **WHEN** cluster contains faces with low inter-similarity
- **THEN** system SHALL suggest splitting cluster into multiple clusters

#### Scenario: Cluster merging suggestion

- **WHEN** two clusters have high similarity
- **THEN** system SHALL suggest merging them into a single cluster

### Requirement: Cluster-to-Person Mapping

The system SHALL map face clusters to person entities in the person registry.

#### Scenario: Cluster labeled with person

- **WHEN** user assigns a person name to a cluster
- **THEN** all faces in that cluster SHALL be associated with that person

#### Scenario: Multiple clusters for same person

- **WHEN** user labels multiple clusters with the same person
- **THEN** system SHALL suggest merging those clusters

#### Scenario: Person embedding updated

- **WHEN** cluster is labeled with person
- **THEN** person's face embedding SHALL be updated with cluster centroid

### Requirement: Automatic Face-to-Person Matching

The system SHALL automatically match newly detected faces to known people.

#### Scenario: New face matched to cluster

- **WHEN** face is detected in new photo
- **THEN** system SHALL attempt to match it to existing clusters

#### Scenario: High confidence match auto-assigned

- **WHEN** face matches cluster with confidence > 0.85
- **THEN** it SHALL be automatically assigned to that cluster's person

#### Scenario: Low confidence match suggested

- **WHEN** face matches cluster with confidence 0.7-0.85
- **THEN** system SHALL suggest the match for user confirmation

#### Scenario: No match creates new cluster

- **WHEN** face matches no existing cluster with confidence > 0.7
- **THEN** it SHALL create a new single-face cluster

### Requirement: Cluster Review Interface

The system SHALL provide UI for reviewing and managing face clusters.

#### Scenario: Clusters displayed by frequency

- **WHEN** user accesses cluster review
- **THEN** clusters SHALL be sorted by photo count (most frequent first)

#### Scenario: Sample faces shown

- **WHEN** viewing a cluster
- **THEN** system SHALL display 6-12 sample faces from the cluster in grid

#### Scenario: Cluster statistics displayed

- **WHEN** viewing cluster details
- **THEN** system SHALL show member count, date range, and photo count

#### Scenario: Cluster labeling action

- **WHEN** user selects a cluster
- **THEN** system SHALL provide option to label with person name

#### Scenario: Cluster merging action

- **WHEN** user identifies duplicate clusters
- **THEN** system SHALL provide option to merge clusters

#### Scenario: Face removal from cluster

- **WHEN** user identifies misclassified face
- **THEN** system SHALL allow removing face from cluster

### Requirement: Background Processing

The system SHALL perform clustering operations in background to avoid blocking
UI.

#### Scenario: Initial clustering background job

- **WHEN** user initiates face clustering
- **THEN** system SHALL run clustering in background thread with progress
  updates

#### Scenario: Incremental updates non-blocking

- **WHEN** new photos added
- **THEN** face detection and clustering SHALL not block photo viewing or app
  usage

#### Scenario: Progress notifications

- **WHEN** long-running clustering operation in progress
- **THEN** system SHALL show progress notification (e.g., "Clustering 500
  faces...")

#### Scenario: Cancellable operations

- **WHEN** user wants to stop clustering
- **THEN** system SHALL provide option to cancel background operation

### Requirement: Performance and Scalability

The system SHALL handle large photo libraries efficiently.

#### Scenario: Clustering performance target

- **WHEN** clustering 100 photos with 200 faces
- **THEN** operation SHALL complete in less than 30 seconds

#### Scenario: Incremental updates fast

- **WHEN** adding a single new photo
- **THEN** face detection and cluster matching SHALL complete in less than 2
  seconds

#### Scenario: Memory efficient

- **WHEN** clustering large photo library
- **THEN** memory usage SHALL not exceed 500MB at peak

### Requirement: Privacy and Security

The system SHALL ensure all face processing happens on-device with no cloud
transmission.

#### Scenario: Face embeddings local only

- **WHEN** face embeddings are extracted
- **THEN** they SHALL be stored only in local SQLite database, never transmitted

#### Scenario: Face detection on-device

- **WHEN** detecting faces in photos
- **THEN** Google ML Kit SHALL run on-device, not via cloud API

#### Scenario: User data deletion

- **WHEN** user deletes all face data
- **THEN** system SHALL remove all face embeddings, clusters, and mappings from
  database
