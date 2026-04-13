## 1. Implementation

- [x] 1.1 Fix the existing Flutter dependency resolution blocker in
      `mobile-app/pubspec.yaml`
- [x] 1.2 Add and resolve `flutter_gemma` in the mobile app
- [x] 1.3 Replace placeholder local-model metadata with Gemma 4 E2B metadata
      sourced from Hugging Face
- [x] 1.4 Implement real local install/remove/install-state handling for the
      Gemma 4 model artifact
- [x] 1.5 Add `GemmaLocalAdapter` implementing `AIJournalGenerator`
- [x] 1.6 Update adapter registration and runtime selection so Gemma 4 is the
      only local adapter
- [x] 1.7 Add Settings UI and provider state for Gemma install status and
      actions
- [x] 1.8 Retire stale ML Kit / TFLite local-generation references and update
      docs
- [x] 1.9 Run verification commands and document any remaining baseline failures
