# Face Clustering and Person Recognition

## Why

The person registry database enables storing people's names and relationships,
but we need a way to automatically detect and cluster faces from photos so users
can label them. Current face detection generates individual faces but doesn't
group similar faces together, making it tedious to label the same person across
many photos.

Without face clustering:

- User must label the same person in every single photo manually
- No way to suggest "this might be the same person as..."
- Cannot build face embeddings for automatic person matching
- Person recognition becomes impractical with large photo libraries

Face clustering enables one-time labeling that propagates across all photos of
that person.

## What Changes

- Implement on-device face detection using Google ML Kit Face Detection (already
  available)
- Extract face embeddings for similarity comparison
- Implement clustering algorithm (DBSCAN or hierarchical clustering) to group
  similar faces
- Create face cluster database tables to store clusters and cluster-to-person
  mappings
- Build UI for reviewing face clusters and labeling them with person names
- Automatically match new photos against existing clusters
- Integrate person identifications into journal generation context
- Handle edge cases: multiple people in photos, partial faces, poor lighting

**Privacy-first approach:**

- All face processing happens on-device
- Face embeddings never leave the device
- User controls which clusters to label
- Can delete clusters and start over
- No cloud face recognition APIs used

## Impact

**Affected specs:**

- `person-recognition` (existing) - Integration with face clustering
- `face-clustering` (new) - Core clustering algorithms and storage
- `photo-processing` (existing) - Face detection pipeline

**Affected code:**

- `mobile-app/lib/services/face_clustering_service.dart` (new) - Clustering
  logic
- `mobile-app/lib/database/face_cluster_database.dart` (new) - Drift tables
- `mobile-app/lib/services/person_recognition_service.dart` (new) - Person
  matching
- `mobile-app/lib/services/media_processing_service.dart` - Face detection
  integration
- `mobile-app/lib/screens/people/face_cluster_review_screen.dart` (new) - UI
- `mobile-app/lib/widgets/face_cluster_card.dart` (new) - Cluster display

**User-facing impact:**

- Label a person once, applies to all their photos
- Automatic detection of new photos with known people
- Suggestions: "Is this the same person as Charles?"
- Statistics: "You have 47 photos with Charles"
- Progressive labeling: start with frequent faces, skip rare ones

**Technical considerations:**

- Face embedding extraction (ML Kit provides 128-dimension vectors)
- Clustering performance with large photo libraries (1000+ photos)
- Incremental clustering as new photos added
- Cluster quality vs. quantity trade-off (tight clusters vs. coverage)
- Storage of face embeddings (binary blobs, ~500 bytes each)
- Background processing to avoid UI blocking

## Success Metrics

- 80%+ of detected faces successfully clustered
- Average cluster purity > 0.9 (same person in cluster)
- Users label average of 5+ clusters in first week
- < 5% false positive matches (wrong person)
- Clustering completes in < 30 seconds for 100 photos
- User satisfaction with face clustering > 4.0/5
