## Context

Aura One currently exposes several local AI concepts, but the implementation is
inconsistent: some paths are partial, some are disabled for APK size, and some
model download metadata is placeholder-only. The approved direction is to
consolidate local generation around Gemma 4 using a runtime-downloaded
mobile-ready artifact.

## Goals / Non-Goals

- Goals:
  - make Gemma 4 the only local model option for journal generation
  - support both Android and iOS
  - download the model from Hugging Face at runtime
  - preserve cloud fallback behavior
- Non-Goals:
  - multi-model local selection
  - custom native LiteRT-LM bridge in the first pass
  - model fine-tuning or personalization

## Decisions

- Decision: use `flutter_gemma` as the Flutter runtime bridge.
  - Alternatives considered: direct platform channels to LiteRT-LM, custom
    `llama.cpp` integration.
  - Rationale: least native code, cross-platform support, existing Gemma 4
    support.

- Decision: use Hugging Face LiteRT-ready `.litertlm` artifacts rather than
  converting raw model weights in-app.
  - Alternatives considered: on-demand HF-to-Task conversion pipeline.
  - Rationale: lower implementation risk and faster delivery.

- Decision: start with Gemma 4 E2B only.
  - Alternatives considered: E4B, multi-variant selector.
  - Rationale: reduces UX and storage complexity in the first pass.

## Risks / Trade-offs

- Large download size increases install friction.
  - Mitigation: install-state UX, storage checks, delete/retry flows.

- `flutter_gemma` may introduce dependency or runtime integration issues.
  - Mitigation: fix baseline first and isolate the integration in
    `GemmaLocalAdapter`.

- Existing docs and code still describe multiple local options.
  - Mitigation: explicitly retire or rewrite stale references as part of this
    change.

## Migration Plan

1. Fix package resolution.
2. Add Gemma runtime and download management.
3. Register Gemma as the only local adapter.
4. Leave cloud adapters untouched except for selector behavior.
5. Update docs and verification.

## Open Questions

- Whether future work should add Gemma E4B as an optional larger local model.
- Whether the app should hard-require Wi-Fi for first-time model installation.
