## Why

Aura One's current local AI story is fragmented across incomplete ML Kit,
TFLite, and placeholder model-download paths. The product direction is now to
support a single maintainable local model option, and Gemma 4 is the chosen
path.

## What Changes

- Replace the existing multi-path local generation story with Gemma 4 as the
  only supported local model option.
- Download the local model at runtime from Hugging Face instead of bundling it
  in the mobile app.
- Add a real local-model management flow for install, status, retry, and
  removal.
- Keep managed and BYOK Gemini adapters as optional cloud fallbacks.
- **BREAKING**: remove ML Kit / TFLite local journal-generation options from
  active runtime selection.

## Impact

- Affected specs: `local-ai-journal-generation`
- Affected code: `mobile-app/pubspec.yaml`, `mobile-app/lib/services/ai/*`,
  `mobile-app/lib/main.dart`, `mobile-app/lib/screens/settings_screen.dart`,
  model download services, related docs and tests
