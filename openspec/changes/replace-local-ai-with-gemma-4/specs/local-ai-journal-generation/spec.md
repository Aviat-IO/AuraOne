## ADDED Requirements

### Requirement: Gemma 4 Is The Only Supported Local Journal Generation Model

The system SHALL support Gemma 4 as the only local journal-generation model
option.

#### Scenario: Local generation path selection

- **WHEN** the app selects a local journal-generation runtime
- **THEN** it SHALL select Gemma 4 or report that no local model is available

#### Scenario: Legacy local adapters are not active options

- **WHEN** the runtime enumerates supported local journal-generation adapters
- **THEN** ML Kit and placeholder TFLite journal-generation paths SHALL not
  appear as supported local alternatives

### Requirement: Gemma 4 Local Models Are Downloaded At Runtime

The system SHALL acquire the Gemma 4 local model artifact through a runtime
download flow instead of bundling the model in the mobile application binary.

#### Scenario: First-time install

- **WHEN** the user enables local Gemma generation and the model is not
  installed
- **THEN** the app SHALL provide a download flow for the approved Gemma 4
  artifact

#### Scenario: Installed model reuse

- **WHEN** the approved Gemma 4 artifact is already installed locally
- **THEN** the app SHALL reuse the installed artifact without requiring another
  download

### Requirement: Gemma 4 Local Model Management Must Be User Visible

The system SHALL expose local Gemma model state and management actions to the
user.

#### Scenario: Model status display

- **WHEN** the user opens model management settings
- **THEN** the app SHALL show whether the Gemma model is not installed,
  downloading, installed, or failed

#### Scenario: Model removal

- **WHEN** the user chooses to remove the installed Gemma model
- **THEN** the app SHALL delete the local artifact and return the local model
  state to not installed

### Requirement: Local Gemma Availability Must Be Capability Gated

The system SHALL gate local Gemma usage on platform and device readiness.

#### Scenario: Unsupported environment

- **WHEN** the device or runtime environment does not meet the local Gemma
  requirements
- **THEN** the app SHALL report the local model as unavailable and SHALL not
  attempt inference

#### Scenario: Missing installed artifact

- **WHEN** Gemma local inference is requested but no installed model artifact
  exists
- **THEN** the app SHALL report setup is required instead of pretending a local
  model is ready

### Requirement: Cloud Fallback Behavior Remains Available

The system SHALL preserve optional cloud journal-generation fallbacks when local
Gemma is unavailable.

#### Scenario: Local unavailable with cloud enabled

- **WHEN** the Gemma local model is unavailable and a cloud adapter is enabled
  and available
- **THEN** the runtime selector SHALL allow cloud generation to proceed

#### Scenario: Local unavailable with cloud disabled

- **WHEN** the Gemma local model is unavailable and cloud generation is disabled
- **THEN** the app SHALL surface a clear setup or availability state to the user
