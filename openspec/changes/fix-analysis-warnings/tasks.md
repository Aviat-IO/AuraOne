## 1. Assessment and Planning
- [x] 1.1 Run `dart analyze` and categorize all 886 issues by type and severity
- [x] 1.2 Determine fate of lib_backup/ directory (delete vs restore)
- [x] 1.3 Create prioritized list of files to fix based on warning counts
- [x] 1.4 Identify any warnings that indicate actual bugs vs style issues

## 2. lib_backup/ Directory Resolution
- [x] 2.1 Review lib_backup/ contents and compare with active lib/ files
- [x] 2.2 Decision: Either delete lib_backup/ entirely OR move to separate archive location outside mobile-app/
- [x] 2.3 Update any documentation referencing lib_backup/ files
- [x] 2.4 Verify no active code depends on lib_backup/ imports

## 3. Remove Unused Code (High Priority)
- [x] 3.1 Remove unused fields (~25 instances)
- [x] 3.2 Remove unused local variables (~15 instances)
- [x] 3.3 Remove unused methods/declarations (~12 instances)
- [x] 3.4 Remove unused catch clauses
- [x] 3.5 Verify removal doesn't break any functionality through testing

## 4. Fix Dead Code
- [x] 4.1 Remove dead code blocks (~5 instances)
- [x] 4.2 Fix dead null-aware expressions (~8 instances) by removing unnecessary `??` operators
- [x] 4.3 Review and test affected logic paths

## 5. Fix Improper API Usage
- [x] 5.1 Fix lib/widgets/optimized_list_view.dart - Replace direct .activity member access with proper ScrollPosition API
- [x] 5.2 Fix lib/widgets/theme_switcher.dart - Replace direct .state member access with proper StateNotifier API
- [x] 5.3 Test affected widgets to ensure behavior is preserved

## 6. Fix Override Annotations
- [x] 6.1 Remove incorrect @override in lib/services/ai/multimodal_fusion_processor.dart
- [x] 6.2 Remove incorrect @override in lib/services/ai/summary_generator.dart
- [x] 6.3 Remove incorrect @override in lib_backup files (if lib_backup/ is kept)
- [x] 6.4 Verify class hierarchies and interfaces are correct

## 7. Clean Test Files
- [x] 7.1 Replace print() calls with proper logger in test/har_model_test.dart
- [x] 7.2 Replace print() calls in other test files if found
- [x] 7.3 Fix unnecessary underscores in test/backup_restore_test.dart

## 8. Update Deprecated APIs
- [x] 8.1 Replace inputSchemaProperties with toolInputSchema in tools/scripts/purplestack_mcp.dart (4 instances)
- [x] 8.2 Test MCP script functionality after update

## 9. Validation and Testing
- [x] 9.1 Run `dart analyze` and verify issue count reduced significantly (target: <100 warnings)
- [x] 9.2 Run full test suite to ensure no regressions
- [x] 9.3 Build mobile app to verify compilation succeeds
- [x] 9.4 Manual smoke test of critical features (AI generation, location tracking, photo gallery)
- [x] 9.5 Document any remaining acceptable warnings with justification

## 10. Documentation
- [x] 10.1 Update CHANGELOG.md with cleanup summary
- [x] 10.2 Document any intentional warnings left in place (if any)
- [x] 10.3 Add pre-commit hook or CI check to prevent warning buildup in future
