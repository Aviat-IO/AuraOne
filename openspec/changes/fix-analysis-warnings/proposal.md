## Why

The Flutter/Dart codebase currently has 886 analysis issues (warnings and info-level messages) that reduce code maintainability and obscure potential bugs. While there are no critical errors blocking compilation, these warnings indicate:
1. Unused code and dead code paths that increase cognitive load
2. Backup directory (lib_backup/) with deprecated/experimental code causing ~60 warnings
3. Improper API usage (protected members, testing-only members) causing potential runtime issues
4. Missing or commented-out dependencies that should be removed or restored

## What Changes

- **Remove or archive lib_backup/ directory** - Contains old/experimental code with ~60 warnings for missing dependencies (optimization_manager.dart, tflite_flutter, sensors_plus, health, flutter_blue_plus, fl_chart, onnxruntime)
- **Clean unused code** - Remove unused fields, variables, methods, and imports (~70 warnings)
- **Fix dead code** - Remove unreachable code paths and dead null-aware expressions (~8 warnings)
- **Fix improper API usage** - Correct usage of protected/testing-only members in optimized_list_view.dart and theme_switcher.dart
- **Fix override annotations** - Remove incorrect @override annotations where methods don't actually override
- **Clean test files** - Replace print statements with proper logging in test files
- **Update deprecated API usage** - Replace deprecated inputSchemaProperties with toolInputSchema in MCP scripts

## Impact

- Affected specs: code-quality (new capability)
- Affected code: 
  - mobile-app/lib_backup/ (potential deletion)
  - ~100 files across lib/ with warnings
  - test/ directory (minor logging improvements)
  - tools/scripts/purplestack_mcp.dart (deprecated API fix)
- Breaking changes: None (internal code quality improvements only)
- Developer experience: Cleaner `dart analyze` output, easier to spot real issues
