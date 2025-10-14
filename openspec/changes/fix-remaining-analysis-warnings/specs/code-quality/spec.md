## MODIFIED Requirements

### Requirement: Code Analysis Cleanliness
The codebase SHALL maintain zero critical errors and zero warnings in static analysis to ensure code quality, compilation safety, and maintainability.

#### Scenario: Running dart analyze passes with no issues
- **WHEN** developer runs `dart analyze --fatal-infos` in mobile-app/ directory
- **THEN** total issue count is 0 (errors + warnings + info)
- **AND** pre-commit hook passes without blocking
- **AND** any remaining unavoidable warnings are explicitly ignored with inline comments and justification

#### Scenario: Critical errors are immediately fixed
- **WHEN** static analysis detects critical errors (syntax errors, undefined methods, type mismatches)
- **THEN** errors are fixed before any other development work
- **AND** pre-commit hooks prevent committing code with critical errors

### Requirement: Deprecated API Migration
The codebase SHALL use current, non-deprecated APIs from dependencies and framework packages.

#### Scenario: Deprecated APIs are proactively replaced
- **WHEN** static analysis detects deprecated_member_use
- **THEN** the deprecated API is replaced with the recommended alternative within the same PR
- **AND** functionality remains intact after migration
- **AND** migration follows official package migration guides

#### Scenario: Share API migration
- **WHEN** code uses deprecated `share` package APIs
- **THEN** code is migrated to `share_plus` package with `SharePlus.instance` pattern
- **AND** all share functionality continues to work across platforms

#### Scenario: Permission API migration
- **WHEN** code uses deprecated `Permission.calendar`
- **THEN** code is migrated to `Permission.calendarFullAccess` or `Permission.calendarWriteOnly` as appropriate
- **AND** calendar permissions continue to work on all platforms

## ADDED Requirements

### Requirement: No Syntax Errors
The codebase SHALL NOT contain any syntax errors, including malformed comments, incomplete code blocks, or invalid language constructs.

#### Scenario: Multi-line comments are properly terminated
- **WHEN** code contains multi-line comments using `/* ... */` syntax
- **THEN** every opening `/*` has a corresponding closing `*/`
- **AND** no unterminated_multi_line_comment errors exist

#### Scenario: Commented-out code is properly formatted
- **WHEN** code is temporarily disabled via comments
- **THEN** comment syntax is complete and valid
- **AND** commented code does not cause parsing errors
- **AND** long-term commented code includes explanatory notes

### Requirement: Method and Field Completeness
All referenced methods and fields SHALL be defined, either as implementations or proper declarations.

#### Scenario: Private methods are fully implemented
- **WHEN** code calls private methods (prefixed with `_`)
- **THEN** those methods exist with complete implementations
- **AND** no undefined_method errors exist

#### Scenario: Fields are declared before use
- **WHEN** code references instance fields
- **THEN** fields are declared in the class definition
- **AND** no undefined_identifier errors exist

### Requirement: Provider Parameter Matching
Provider constructors and their invocations SHALL use matching parameter names and types.

#### Scenario: Named parameters match constructor signatures
- **WHEN** Riverpod provider passes named parameters to a service constructor
- **THEN** constructor accepts those exact named parameters
- **AND** no undefined_named_parameter errors exist

### Requirement: Exception Type Definitions
All exception types used in catch blocks SHALL be properly defined or imported.

#### Scenario: Custom exceptions are defined
- **WHEN** code uses custom exception types in catch clauses
- **THEN** exception classes are defined or imported
- **AND** exception types are valid class names
- **AND** no non_type_in_catch_clause errors exist

### Requirement: BuildContext Safety Across Async Gaps
BuildContext SHALL NOT be used after async operations without checking widget lifecycle state.

#### Scenario: BuildContext is checked before use after await
- **WHEN** code uses BuildContext after an await statement
- **THEN** code checks `mounted` (StatefulWidget) or `context.mounted` before use
- **AND** no use_build_context_synchronously warnings exist
- **AND** widget lifecycle is respected to prevent runtime crashes

#### Scenario: Early return on unmounted context
- **WHEN** widget is unmounted during async operation
- **THEN** code returns early without using BuildContext
- **AND** no navigation or UI updates occur on disposed widgets
