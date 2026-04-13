# Gemma 4 Local Model Design

**Date:** 2026-04-12

## Goal

Replace Aura One's fragmented local AI story with a single supported local-model
path: Gemma 4, downloaded at runtime from Hugging Face in a mobile-ready format
and used on both Android and iOS.

## Current Problems

- The app currently has multiple overlapping local AI paths:
  `MLKitGenAIAdapter`, old TFLite references, fake download metadata, and
  several stubbed services.
- Some of those paths are incomplete, disabled for APK size, or no longer
  aligned with the product direction.
- The runtime selector and docs still describe a multi-tier local stack that
  does not reflect the codebase's real maintainable future.
- The current `ModelDownloadManager` registry points at placeholder models, not
  real Aura One journal-generation assets.

## Approved Direction

- Gemma 4 becomes the **only** local model option.
- The first supported local model is **Gemma 4 E2B**.
- The model is **not bundled** in the app binary.
- The app downloads the model **at runtime** from Hugging Face.
- The preferred runtime path is a Flutter-native bridge using `flutter_gemma`,
  because it already supports Gemma 4, Android, iOS, `.litertlm`, and local-file
  loading.
- Cloud adapters remain available as cloud fallbacks unless removed in a later
  change.

## Model Distribution Decision

### Selected artifact

- Source: Hugging Face
- Artifact: `litert-community/gemma-4-E2B-it-litert-lm`
- Format: `.litertlm`

### Why this artifact

- It is already packaged for Android and iOS deployment.
- It avoids building an immediate conversion pipeline from raw Hugging Face
  `safetensors`.
- It matches the current cross-platform requirement better than Android-only ML
  Kit or a custom native bridge.

### Operational constraints

- The model is large, roughly 2.58 GB on disk.
- The app must check free storage before download.
- The UI must treat download, install, remove, and error states as first-class
  product flows.

## Architecture

### Runtime

- Add a `GemmaLocalAdapter` implementing `AIJournalGenerator`.
- Back it with `flutter_gemma`.
- Load the downloaded `.litertlm` file from app-managed local storage.

### Download and storage

- Replace placeholder model registry usage for local LLMs with a real Gemma 4
  download path.
- Keep downloaded models under app-managed storage from `path_provider`.
- Store model metadata locally: version, source URL, file size, checksum if
  available, installed path, installation timestamp.

### Adapter selection

- Local adapter priority becomes:
  - `GemmaLocalAdapter`
- Cloud adapters remain separate:
  - `ManagedCloudGeminiAdapter`
  - `CloudGeminiAdapter`
- The runtime selector should stop treating ML Kit/TFLite as competing local
  generation paths.

### Capability gating

- The app must explicitly gate Gemma local usage by:
  - supported platform
  - minimum OS/runtime requirements from `flutter_gemma`
  - available storage
  - model installed status
- If Gemma local is unavailable, the selector may fall back to cloud adapters if
  enabled.
- If cloud is disabled and Gemma is unavailable, journal generation should
  surface a clear setup/install state instead of silently pretending a local
  model exists.

## Scope

### In scope

- Add Gemma 4 local runtime path.
- Download Gemma 4 E2B from Hugging Face.
- Add local model management UI.
- Make Gemma 4 the only supported local model path.
- Remove or retire stale local-model selection logic.
- Fix the current dependency blocker before Gemma work proceeds.

### Out of scope

- Fine-tuning Gemma 4.
- Supporting multiple local LLM families.
- Supporting multiple Gemma local variants in the first pass.
- Replacing cloud AI features.
- Building our own native LiteRT-LM bridge.

## Risks And Mitigations

- Very large model download
  - Mitigation: strong UX, storage checks, Wi-Fi recommendation,
    delete/re-download flow.
- Flutter dependency conflict
  - Mitigation: fix baseline package resolution first in the worktree.
- Plugin/runtime mismatch on real devices
  - Mitigation: isolate runtime integration behind `GemmaLocalAdapter` and keep
    cloud fallback intact.
- Existing stale code paths causing confusion
  - Mitigation: explicitly de-register old local adapters and update
    docs/settings text.

## TODO Summary

1. Fix the existing `freezed` / `freezed_annotation` dependency conflict.
2. Add `flutter_gemma` cleanly.
3. Introduce real Gemma 4 model metadata and runtime download flow.
4. Implement `GemmaLocalAdapter`.
5. Replace old local-adapter selection with Gemma-only local selection.
6. Add Settings UI for install/remove/status.
7. Retire stale ML Kit/TFLite local-model code paths.
8. Add tests around adapter selection, model state, and generation setup.
9. Re-run Flutter verification from the worktree.

## Research Notes

- Google documents Gemma mobile deployment on Android and iOS through MediaPipe
  / LiteRT-LM.
- Google provides a Hugging Face to MediaPipe conversion path, but that is
  unnecessary for the first pass because Hugging Face already hosts a
  mobile-ready LiteRT Gemma 4 artifact.
- `flutter_gemma` now advertises Gemma 4 E2B/E4B support and iOS `.litertlm`
  support.
