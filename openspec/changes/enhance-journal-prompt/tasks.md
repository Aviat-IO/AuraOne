# Implementation Tasks

## 1. Prompt Structure Enhancement

- [x] 1.1 Add WRITING STYLE section with grammar and flow guidelines
- [x] 1.2 Add TONE GUIDELINES section for objective, factual writing
- [x] 1.3 Add WHAT TO EXCLUDE section for uninteresting details
- [x] 1.4 Add MEASUREMENT UNITS section with locale-aware conversion
- [ ] 1.5 Add WHAT TO EMPHASIZE section for meaningful content
- [ ] 1.6 Add few-shot examples (2-3 good vs bad entries)

## 2. Context Formatting Improvements

- [ ] 2.1 Create structured people context formatting method
- [ ] 2.2 Create structured places context formatting method
- [ ] 2.3 Create structured activities context formatting method
- [ ] 2.4 Create timeline events formatting method
- [ ] 2.5 Add health data natural language formatting

## 3. Data Preprocessing Layer

- [ ] 3.1 Transform location counts to actual place names
- [ ] 3.2 Transform person detections to descriptive context
- [ ] 3.3 Remove exact timestamps unless contextually meaningful
- [ ] 3.4 Filter out low-significance events
- [ ] 3.5 Group related activities for narrative coherence

## 4. Prompt Template Refactoring

- [ ] 4.1 Extract prompt building into dedicated class/service
- [ ] 4.2 Add configuration options for prompt customization
- [ ] 4.3 Make prompt sections modular and testable
- [ ] 4.4 Add versioning for A/B testing different prompts

## 5. Testing & Validation

- [ ] 5.1 Create test suite with sample daily contexts
- [ ] 5.2 Generate entries with old vs new prompt for comparison
- [ ] 5.3 Review generated entries for quality metrics
- [ ] 5.4 Test with sparse data days (few events)
- [ ] 5.5 Test with data-rich days (many events)
- [ ] 5.6 Test locale-specific measurement formatting

## 6. Documentation

- [ ] 6.1 Document prompt structure and design decisions
- [ ] 6.2 Add examples of good vs bad generated entries
- [ ] 6.3 Document data preprocessing transformations
- [ ] 6.4 Create guide for future prompt iterations
