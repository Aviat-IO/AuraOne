# Aura One

A mindful journaling and personal wellness app that captures your daily experiences through automated context gathering, intelligent AI insights, and privacy-first data management.

## Features

- **AI-Powered Daily Summaries**: Automatically generated insights from your location, photos, calendar events, and activities
- **Context-Aware Journaling**: Captures location history, movement patterns, nearby Bluetooth devices, and environmental context
- **Intelligent Photo Management**: Face detection and clustering, automatic person identification, EXIF metadata extraction
- **Privacy-First Architecture**: Local-first data storage, on-device AI processing, granular privacy controls, secure encryption
- **Voice-to-Text Editing**: Natural language commands for hands-free journaling
- **Multi-Source Data Fusion**: Integrates calendar events, health data, location patterns, and media into cohesive daily narratives
- **Export & Backup**: Multiple export formats, encrypted backups, Syncthing support, Nostr integration for selective sharing

## Development Setup

### Prerequisites

For macOS (may work with Homebrew on Linux):

```bash
# Install Android
brew install android-commandlinetools
# add to shell's rc file ANDROID_SDK_ROOT=/opt/homebrew/share/android-commandlinetools

# Install Java
brew install openjdk@17

# Install Dart & Flutter Version Manager
brew tap dart-lang/dart
brew install dart
dart --disable-analytics
dart pub global activate fvm

# Install Flutter
fvm releases
fvm install 3.8.1  # or check .fvmrc for version

# Android SDK setup
sdkmanager --install "platforms;android-35"
sdkmanager --install "build-tools;35.0.0"
sdkmanager --install emulator platform-tools tools
sdkmanager --licenses
```

### Getting Started

```bash
# Clone the repository
git clone https://github.com/Aviat-IO/AuraOne
cd auraone/mobile-app

# Install dependencies
fvm flutter pub get

# Run the app
fvm flutter run

# Build for Android
fvm flutter build apk --target-platform android-arm64 --split-per-abi
```

## Project Structure

```tree
mobile-app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── router.dart            # Navigation configuration
│   ├── screens/               # App screens
│   ├── services/              # Core services (AI, location, media, etc.)
│   ├── widgets/               # Reusable UI components
│   ├── providers/             # Riverpod state management
│   ├── models/                # Data models
│   └── utils/                 # Utility functions
├── assets/                    # Images, icons, AI models
└── tools/                     # Build scripts and MCP servers
```

## Technology Stack

- **Flutter & Dart**: Cross-platform mobile framework
- **Riverpod**: State management and dependency injection
- **Drift**: Local SQLite database with reactive queries
- **TensorFlow Lite**: On-device AI for text generation
- **Google ML Kit**: Face detection, image labeling, OCR
- **Nostr Protocol**: Decentralized data sharing (via Purplebase)
- **Material 3**: Modern UI design system

## License

MIT
