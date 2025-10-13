## ADDED Requirements

### Requirement: Code Analysis Cleanliness
The codebase SHALL maintain a low warning count (<100 non-critical warnings) in static analysis to ensure code quality and maintainability.

#### Scenario: Running dart analyze shows minimal warnings
- **WHEN** developer runs `dart analyze` in mobile-app/ directory
- **THEN** total warning count is less than 100
- **AND** no critical errors exist
- **AND** remaining warnings are documented with justification

### Requirement: No Unused Code
The codebase SHALL NOT contain unused fields, variables, methods, or imports that increase cognitive load.

#### Scenario: Unused code is removed
- **WHEN** static analysis detects unused_element, unused_field, or unused_local_variable
- **THEN** the unused code is removed or properly utilized
- **AND** removal does not break any functionality

#### Scenario: Dead code is eliminated
- **WHEN** static analysis detects dead_code or dead_null_aware_expression
- **THEN** the unreachable code is removed
- **AND** logic paths are tested to ensure correctness

### Requirement: Proper API Usage
The codebase SHALL use framework APIs according to their documented visibility and protection levels.

#### Scenario: Protected members are not accessed externally
- **WHEN** code attempts to access protected members like ScrollPosition.activity or StateNotifier.state
- **THEN** proper public API alternatives are used instead
- **AND** no invalid_use_of_protected_member warnings exist

#### Scenario: Testing-only members are not used in production
- **WHEN** code attempts to use members marked as @visibleForTesting
- **THEN** production code uses the intended public API
- **AND** no invalid_use_of_visible_for_testing_member warnings exist

### Requirement: Correct Override Annotations
Methods marked with @override SHALL actually override a method from a superclass or implement an interface method.

#### Scenario: Override annotations are accurate
- **WHEN** a method has @override annotation
- **THEN** the method actually overrides a superclass/interface method
- **AND** no override_on_non_overriding_member warnings exist

### Requirement: Deprecated API Migration
The codebase SHALL use current, non-deprecated APIs from dependencies.

#### Scenario: Deprecated APIs are replaced
- **WHEN** static analysis detects deprecated_member_use
- **THEN** the deprecated API is replaced with the recommended alternative
- **AND** functionality remains intact after migration

### Requirement: Backup Code Isolation
Experimental or deprecated code SHALL be stored outside the main codebase to prevent analysis pollution.

#### Scenario: lib_backup directory is removed or archived
- **WHEN** lib_backup/ directory exists with deprecated code
- **THEN** either lib_backup/ is deleted OR moved outside mobile-app/ directory
- **AND** no warnings are generated from backup code files
- **AND** active code does not import from lib_backup/

### Requirement: Test Code Quality
Test code SHALL follow the same code quality standards as production code, using proper logging instead of print statements.

#### Scenario: Tests use proper logging
- **WHEN** test code needs to output information
- **THEN** proper logging framework is used instead of print()
- **AND** no avoid_print warnings exist in test files
