# Journal Enhancement Proposals

This directory contains four major proposals to transform Aura One into the
world's best auto-journaling app.

## Active Proposals

### 1. Enhanced Journal Prompt Engineering (`enhance-journal-prompt`)

**Status**: Ready for review\
**Priority**: P0 (Immediate)\
**Effort**: 1-2 weeks

Restructures AI prompts with clear sections, few-shot examples, and better
writing guidelines to eliminate robotic tone and improve grammar.

**Expected Impact**: 50-70% improvement in journal quality immediately

### 2. Local Context Database (`add-local-context-database`)

**Status**: Ready for review\
**Priority**: P1 (High)\
**Effort**: 3-4 weeks

Creates comprehensive local database for storing people (names, relationships),
places (custom names, categories), and user preferences for personalized journal
generation.

**Expected Impact**: Entries use actual names and specific places ("Charles at
Liberty Park" vs "child at park")

### 3. Face Clustering and Recognition (`add-face-clustering`)

**Status**: Ready for review\
**Priority**: P1 (High)\
**Effort**: 4-6 weeks

Implements on-device face detection, clustering, and person recognition to
automatically identify people in photos with privacy-first approach.

**Expected Impact**: Label once, applies to all photos; automatic person
identification

### 4. Temporal Context and Narrative Intelligence (`add-temporal-context`)

**Status**: Ready for review\
**Priority**: P2 (Medium)\
**Effort**: 6-8 weeks

Adds cross-day narrative connections, pattern detection, streak tracking, and
temporal insights to make journals feel connected over time.

**Expected Impact**: "Third visit this week", "First hike in 2 months", ongoing
activity tracking

## Implementation Sequence

### Phase 1: Foundation (Weeks 1-2)

1. **enhance-journal-prompt** - Quick wins with immediate quality improvement

### Phase 2: Personalization (Weeks 3-8)

2. **add-local-context-database** - Build foundation for personalization
3. **add-face-clustering** - Enable automatic person recognition

### Phase 3: Intelligence (Weeks 9-16)

4. **add-temporal-context** - Add narrative connections and patterns

## Success Metrics

After all implementations:

- User edit rate < 20% (currently higher)
- Journal entry rating > 4.5/5 stars
- 80%+ entries use person/place names
- 60%+ entries include temporal insights
- Privacy-first: all processing on-device
- Differentiation: unique narrative intelligence

## Research Foundation

These proposals are based on comprehensive research covering:

- Competitive analysis (Day One, Memoir, Daylio, Chronicle)
- AI prompt engineering best practices
- Privacy-first architecture patterns
- Mobile ML Kit capabilities
- Temporal pattern recognition algorithms
- User experience research on journaling apps

See research findings in project planning documents for detailed analysis and
rationale.
