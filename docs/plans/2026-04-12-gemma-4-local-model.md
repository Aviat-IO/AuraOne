# Gemma 4 Local Model Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to
> implement this plan task-by-task.

**Goal:** Make Gemma 4 E2B the only local model option in Aura One, downloaded
from Hugging Face at runtime and usable on both Android and iOS.

**Architecture:** Add a single `GemmaLocalAdapter` behind the existing
`AIJournalGenerator` abstraction, feed it a downloaded `.litertlm` model file,
and simplify local-adapter selection so Gemma is the only local path. Keep
managed and BYOK cloud adapters as optional fallbacks.

**Tech Stack:** Flutter, Riverpod, Drift, `flutter_gemma`, `path_provider`, HTTP
download flow, existing Aura One AI adapter interfaces.

---

### Task 1: Fix The Baseline Dependency Blocker

**Files:**

- Modify: `mobile-app/pubspec.yaml`
- Test: `mobile-app/pubspec.lock`

**Step 1: Write down the current failure**

Run: `cd mobile-app && fvm flutter pub get` Expected: failure due to `freezed`
and `freezed_annotation` mismatch.

**Step 2: Align the dependency pair minimally**

Update the `freezed` and `freezed_annotation` versions so `fvm flutter pub get`
resolves again.

**Step 3: Verify dependency resolution**

Run: `cd mobile-app && fvm flutter pub get` Expected: success.

### Task 2: Add Gemma Runtime Dependency Cleanly

**Files:**

- Modify: `mobile-app/pubspec.yaml`
- Modify: platform-specific generated dependency files as needed after `pub get`

**Step 1: Add `flutter_gemma`**

Un-comment or reintroduce the package in `mobile-app/pubspec.yaml` with the
minimum version that supports Gemma 4 and iOS `.litertlm`.

**Step 2: Resolve dependency conflicts minimally**

Keep unrelated package churn out of scope.

**Step 3: Verify install**

Run: `cd mobile-app && fvm flutter pub get` Expected: success with
`flutter_gemma` present.

### Task 3: Replace Fake Local Model Metadata With Real Gemma 4 Metadata

**Files:**

- Modify: `mobile-app/lib/services/ai/model_download_manager.dart`
- Possibly create: `mobile-app/lib/services/ai/gemma_model_manifest.dart`
- Test: `mobile-app/test/services/` new model metadata tests

**Step 1: Write a failing metadata test**

Assert that the local LLM registry exposes one supported model: Gemma 4 E2B,
with a Hugging Face source and runtime-managed local file target.

**Step 2: Replace placeholder entries**

Remove fake Gemma/TFLite placeholders used for local journal generation.

**Step 3: Add Gemma 4 E2B metadata**

Include source URL, logical version, expected size, and install identity.

**Step 4: Re-run the test**

Run the focused test file.

### Task 4: Implement Real Download State For Gemma 4

**Files:**

- Modify: `mobile-app/lib/services/ai/model_download_manager.dart`
- Possibly create: `mobile-app/lib/services/ai/gemma_model_service.dart`
- Test: new unit tests around install-state persistence and path resolution

**Step 1: Write failing tests for installed/not-installed state**

Cover path resolution, metadata persistence, and remove/reinstall state.

**Step 2: Implement app-managed model storage**

Store the downloaded `.litertlm` in an app-managed directory.

**Step 3: Add storage/error guards**

Handle missing path, partial download, and remove flow.

**Step 4: Verify focused tests**

Run the new test file.

### Task 5: Add GemmaLocalAdapter

**Files:**

- Create: `mobile-app/lib/services/ai/gemma_local_adapter.dart`
- Modify: `mobile-app/lib/services/ai/ai_journal_generator.dart`
- Test: `mobile-app/test/services/gemma_local_adapter_test.dart`

**Step 1: Write failing adapter tests**

Cover capability reporting, unavailable state when the model is missing, and
available state when the model path exists.

**Step 2: Implement minimal adapter**

Use `flutter_gemma` to load and invoke the installed model file.

**Step 3: Return Aura-standard generation results**

Map plugin output into `AIGenerationResult` and `AICapabilities`.

**Step 4: Run focused tests**

Run the adapter test file.

### Task 6: Simplify Adapter Registration And Selection

**Files:**

- Modify: `mobile-app/lib/main.dart`
- Modify: `mobile-app/lib/services/ai/adapter_registry.dart`
- Modify: `mobile-app/lib/services/ai/runtime_selector.dart`
- Test: `mobile-app/test/services/runtime_selector_test.dart`

**Step 1: Write failing selector tests**

Assert that Gemma is the only local adapter candidate and that cloud adapters
remain cloud-only fallbacks.

**Step 2: Register Gemma local adapter**

Replace old local registration assumptions.

**Step 3: Remove stale local selection paths**

Stop preferring ML Kit/TFLite local generation as active local options.

**Step 4: Re-run selector tests**

Run the focused selector test file.

### Task 7: Add Settings UI For Gemma Model Management

**Files:**

- Modify: `mobile-app/lib/screens/settings_screen.dart`
- Possibly create: `mobile-app/lib/widgets/gemma_model_card.dart`
- Possibly create: `mobile-app/lib/providers/gemma_model_provider.dart`
- Test: widget test if practical

**Step 1: Add a simple provider-backed state surface**

Expose installed, downloading, progress, and error states.

**Step 2: Add UI entry point in Settings**

Show install status and actions.

**Step 3: Add install/remove actions**

Support download, retry, and delete.

**Step 4: Verify manually**

Run the app and confirm the settings flow renders without crashing.

### Task 8: Retire Stale Local-Model Code Paths

**Files:**

- Modify: `mobile-app/lib/services/ai/mlkit_genai_adapter.dart`
- Modify: `mobile-app/lib/services/ai/tflite_manager.dart`
- Modify: `mobile-app/docs/MLKIT_GENAI_TESTING.md`
- Modify any stale docs/settings text mentioning old local model options

**Step 1: Remove misleading local-path references**

Keep only what is still needed for non-journal features or explicit future work.

**Step 2: Update docs to reflect Gemma-only local generation**

Make sure the repo no longer claims multiple supported local journal-generation
engines.

**Step 3: Verify search results**

Search the repo for stale local model option text and clean obvious leftovers.

### Task 9: Verify The Feature End-To-End

**Files:**

- Verify affected files above
- Verify test files added or updated

**Step 1: Run dependency resolution**

Run: `cd mobile-app && fvm flutter pub get`

**Step 2: Run focused tests**

Run the new/updated AI and selector tests.

**Step 3: Run broader suite as far as baseline allows**

Run: `cd mobile-app && fvm flutter test`

**Step 4: Run static analysis if feasible**

Run: `cd mobile-app && fvm flutter analyze`

**Step 5: Manual smoke test**

Confirm settings UI, install state, and journal-generation selection logic
behave as expected.
