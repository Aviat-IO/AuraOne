# Fix Remaining Analysis Warnings

## Why

The pre-commit hook is blocked by 133 remaining analysis issues (37 errors, 28 warnings, 68 info-level issues) that prevent clean commits. These issues include:

- **Critical Errors (37)**: Syntax errors (unterminated comments, malformed code), undefined methods/identifiers, type mismatches, missing parameters
- **Code Quality Warnings (28)**: Unused imports, unused variables/fields/methods, deprecated API usage, protected member access violations
- **Style & Best Practice Info (68)**: Deprecated member usage (Share API, calendar permissions, color methods), unsafe BuildContext usage across async gaps, avoid_print in scripts, dependency issues

These must be resolved to restore clean pre-commit checks and maintain code quality standards.

## What Changes

### 1. Critical Error Fixes (37 issues)
- **onboarding_screen.dart**: Remove malformed commented-out code block (lines 464-520) causing 16 syntax/identifier errors
- **journal_service.dart**: Fix unterminated multi-line comment (line 940+), restore missing private methods (`_ensureTodayEntry`, `_setupDailyTimer`, `_extractActivitiesForDate`, `_formatDate`), fix provider initialization, restore missing field `_lastSyncTime`
- **data_deletion_screen.dart**: Fix syntax error at line 475 (missing identifier, expected token)
- **daily_canvas_screen.dart**: Restore missing JournalService methods (`addMediaToJournalEntry`, `addLocationToJournalEntry`)
- **pattern_analysis_provider.dart**: Fix undefined named parameters (`mediaDatabase`, `locationDatabase`)
- **fusion_providers.dart**: Fix undefined named parameter (`locationService`)
- **calendar_service.dart**: Restore missing field `_lastSyncTime`
- **daily_entry_view.dart**: Define or import `InsufficientDataException` class

### 2. Code Quality Warnings (28 issues)
- Remove unused imports (7 files: multimodal_fusion.dart, contextual_phrase_generator.dart, multi_modal_fusion_engine.dart, journal_service.dart, pattern_analyzer.dart, personality_engine.dart)
- Remove or use unused local variables (2 instances)
- Remove unused fields (2 instances: `_iterationCount`, `_databaseService`)
- Remove unused element declarations (6 methods across 3 files)
- Fix dead null-aware expression (1 instance)
- Address protected member access violations (4 instances: ScrollPosition.activity, StateNotifier.state)

### 3. Deprecation & Best Practice Fixes (68 info-level)
- Replace deprecated `Share` API with `SharePlus.instance.share()` (6 usages in export_screen.dart)
- Replace deprecated `Permission.calendar` with `Permission.calendarFullAccess` (8 usages across 3 files)
- Replace deprecated `withOpacity` with `.withValues()` (1 usage)
- Replace deprecated logger `printTime` with `dateTimeFormat` parameter (1 usage)
- Replace deprecated Workmanager `isInDebugMode` (1 usage)
- Add mounted checks before async BuildContext usage (8 instances across 5 files)
- Fix `prefer_adjacent_string_concatenation` (1 instance)
- Fix `unrelated_type_equality_checks` (2 instances in export/import screens)
- Add sqflite to pubspec.yaml dependencies (1 missing dependency)
- **scripts/seed_dev_database.dart**: Replace `print` calls with proper logging (37 instances) - acceptable for dev scripts but flagged for consistency

## Impact

- **Affected code**: 
  - Core services: `journal_service.dart`, `calendar_service.dart`
  - UI screens: `onboarding_screen.dart`, `daily_canvas_screen.dart`, `data_deletion_screen.dart`, `export_screen.dart`, `import_screen.dart`
  - Providers: `pattern_analysis_provider.dart`, `fusion_providers.dart`
  - Widgets: `daily_entry_view.dart`, various UI widgets
  - Services: AI services, location services, export services
  - Scripts: `seed_dev_database.dart`

- **Affected specs**: None (this is a code quality/bug fix change restoring existing functionality)

- **Risk level**: Low to Medium
  - Most fixes are straightforward (remove unused code, fix imports, add deprecation updates)
  - Medium risk for restoring missing methods/fields - requires verifying git history or implementation from context
  - All changes preserve existing functionality; no feature additions

- **Testing requirements**:
  - Verify `dart analyze --fatal-infos` passes with 0 issues
  - Smoke test critical flows: onboarding, journal entry creation/editing, export functionality
  - Verify no runtime regressions from protected member access fixes
