# Implementation Tasks

## 1. Prompt Structure Enhancement

- [x] 1.1 Add WRITING STYLE section with grammar and flow guidelines
- [x] 1.2 Add TONE GUIDELINES section for objective, factual writing
- [x] 1.3 Add WHAT TO EXCLUDE section for uninteresting details
- [x] 1.4 Add MEASUREMENT UNITS section with locale-aware conversion
- [x] 1.5 Add WHAT TO EMPHASIZE section for meaningful content
- [x] 1.6 Add few-shot examples (2-3 good vs bad entries)

## 2. Context Formatting Improvements

- [x] 2.1 Create structured people context formatting method
- [x] 2.2 Create structured places context formatting method
- [x] 2.3 Create structured activities context formatting method
- [x] 2.4 Create timeline events formatting method
- [-] 2.5 Add health data natural language formatting (CANCELLED: No health data
  currently tracked)

## 3. Data Preprocessing Layer

- [x] 3.1 Transform location counts to actual place names (via
      LocationClusterNamer)
- [-] 3.2 Transform person detections to descriptive context (DEFERRED: Requires
  Phase 2 person registry)
- [x] 3.3 Remove exact timestamps unless contextually meaningful (Timeline uses
      relative times)
- [x] 3.4 Filter out low-significance events (isSignificant +
      _filterAndGroupEvents)
- [x] 3.5 Group related activities for narrative coherence (Event merging +
      location clustering)

## 4. Prompt Template Refactoring

- [-] 4.1 Extract prompt building into dedicated class/service (CANCELLED:
  Minimal implementation preferred)
- [-] 4.2 Add configuration options for prompt customization (CANCELLED: Not
  needed for v1)
- [-] 4.3 Make prompt sections modular and testable (CANCELLED: Current
  structure sufficient)
- [-] 4.4 Add versioning for A/B testing different prompts (CANCELLED: Future
  enhancement)

## 5. Testing & Validation

- [x] 5.1 Create test suite with sample daily contexts
      (journal_prompt_quality_test.dart)
- [x] 5.2 Generate entries with old vs new prompt for comparison (Test helpers
      created)
- [x] 5.3 Review generated entries for quality metrics (Quality validation
      tests)
- [x] 5.4 Test with sparse data days (few events) (_createSparseContext test)
- [x] 5.5 Test with data-rich days (many events) (_createRichContext test)
- [x] 5.6 Test locale-specific measurement formatting (Imperial/metric tests)

## 6. Documentation

- [x] 6.1 Document prompt structure and design decisions
      (IMPLEMENTATION_GUIDE.md)
- [x] 6.2 Add examples of good vs bad generated entries
      (IMPLEMENTATION_GUIDE.md)
- [x] 6.3 Document data preprocessing transformations (IMPLEMENTATION_GUIDE.md)
- [x] 6.4 Create guide for future prompt iterations (IMPLEMENTATION_GUIDE.md)
