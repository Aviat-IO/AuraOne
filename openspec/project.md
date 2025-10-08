# Project Context

## Purpose

**Aura One** is a local-first, AI-powered automatic journaling application that redefines digital journaling by shifting from active creation to passive curation. The app automatically constructs a rich, multimedia narrative of the user's day with minimal direct input, solving the time commitment and writer's block challenges of traditional journaling.

### Core Vision
Transform the user's role from "author starting with a blank page" to "editor refining a detailed draft" by automatically assembling daily chronicles from diverse data streams (location, photos, calendar, health data, BLE proximity).

### Key Differentiators
1. **Strictly Local-First Architecture** - All data resides on-device; network is optional
2. **Verifiable Transparency** - Open-source codebase (AGPLv3) for trust
3. **Automation-First Workflow** - Passive capture with pre-assembled entries
4. **Native Decentralized Integrations** - Nostr, Blossom, Lightning Network support

### Target User
Privacy-conscious technologists who value deep self-reflection but are constrained by time. Early adopters familiar with data sovereignty, self-hosting, and decentralized protocols (Nostr). Users who want AI-driven insights without compromising data ownership.

## Tech Stack

### Frontend (Mobile App)
- **Framework**: Flutter 3.x (cross-platform iOS/Android from single codebase)
- **State Management**: Riverpod (dependency injection and reactive state)
- **UI Components**: Material 3 design system
- **Navigation**: GoRouter for declarative routing

### Local Data & Storage
- **Database**: Drift (SQLite wrapper) with type-safe SQL queries
- **Media Management**: photo_manager (device photo library access)
- **Secure Storage**: flutter_secure_storage (encryption keys, sensitive data)
- **File System**: path_provider (platform-specific directories)

### AI & Machine Learning
- **On-Device AI**: 
  - ML Kit GenAI APIs (Tier 1: Pixel 8+, Galaxy S24+)
  - TFLite models via tflite_flutter (Tier 2: Android 21+)
  - Template-based generation (Tier 3: guaranteed fallback)
- **Cloud AI** (optional): Google Generative AI SDK (Gemini 2.5 Pro) via secure proxy
- **Vision**: google_mlkit_* packages (image_labeling, object_detection, face_detection, text_recognition)
- **Speech**: speech_to_text, flutter_tts

### Location & Sensors
- **Background Location**: flutter_background_geolocation (motion-based tracking)
- **On-Demand Location**: geolocator (current position, reverse geocoding)
- **Motion Sensors**: sensors_plus (accelerometer, gyroscope for activity recognition)
- **Calendar Integration**: device_calendar (iOS EventKit, Android Calendar Provider)
- **Health Data**: health (HealthKit on iOS, Google Fit on Android)
- **Bluetooth**: flutter_blue_plus (BLE proximity detection)

### Decentralized Technologies
- **Nostr Protocol**: dart_nostr or NDK for event publishing
- **Blossom Storage**: Nostr-based binary blob storage
- **Lightning Network**: Nostr Wallet Connect (NIP-47) for micropayments

### Backend Services
- **Proxy Service**: Bun + TypeScript (secure Gemini API access with rate limiting)
- **Cloud Storage** (optional): googleapis (Google Drive), iCloud/Dropbox placeholders
- **Peer-to-Peer Sync**: Syncthing integration (folder-based sync)

### Infrastructure & DevOps
- **Deployment**: Google Cloud Platform (GCP) via Vertex AI for proxy
- **Build System**: Gradle (Android), CocoaPods (iOS)
- **CI/CD**: GitHub Actions (assumed based on .github presence)
- **Monitoring**: Sentry (crash reporting), custom AppLogger utility

## Project Conventions

### Code Style
- **NO COMMENTS RULE**: Do not add code comments unless explicitly requested
- **Formatting**: Follow Dart/Flutter standard formatting (dart format)
- **Naming Conventions**:
  - Classes: PascalCase (e.g., `JournalService`, `MLKitGenAIAdapter`)
  - Files: snake_case (e.g., `journal_service.dart`, `mlkit_genai_adapter.dart`)
  - Variables/Methods: camelCase (e.g., `generateSummary`, `dailyContext`)
  - Constants: camelCase with `k` prefix or SCREAMING_SNAKE_CASE for config (e.g., `kDebugMode`, `API_KEY`)
  - Providers: descriptive names ending in Provider (e.g., `journalServiceProvider`, `locationDatabaseProvider`)

### Architecture Patterns

#### Layered Architecture
```
lib/
  ├── config/           # App configuration, constants
  ├── database/         # Drift database definitions and DAOs
  ├── models/           # Data models and entities
  ├── providers/        # Riverpod providers for state management
  ├── services/         # Business logic and data acquisition
  │   ├── ai/          # AI adapters and generation logic
  │   ├── export/      # Backup and export functionality
  │   ├── location/    # Location tracking services
  │   └── sensor/      # Sensor data collection
  ├── screens/          # UI screens (feature-first organization)
  ├── widgets/          # Reusable UI components
  └── utils/            # Helper utilities (logger, error_handler)
```

#### Key Patterns
- **Provider Pattern**: Use Riverpod for dependency injection throughout
- **Service Layer**: Business logic in service classes, exposed via providers
- **Repository Pattern**: Database access through DAOs (Data Access Objects)
- **Adapter Pattern**: AI service abstraction with 4-tier fallback system
- **Strategy Pattern**: Multiple backup providers (local, Syncthing, Blossom, cloud)

#### AI Service Adapter Hierarchy
1. **Tier 1**: MLKitGenAIAdapter (ML Kit GenAI APIs - requires Android 26+, AICore, Pixel 8+/Galaxy S24)
2. **Tier 2**: HybridMLKitAdapter (basic ML Kit + custom TFLite - Android 21+)
3. **Tier 3**: TemplateAdapter (DataRichNarrativeBuilder - guaranteed fallback)
4. **Tier 4**: CloudGeminiAdapter or ManagedCloudGeminiAdapter (optional premium with network)

### Testing Strategy
- **Unit Tests**: Test all database operations (CRUD), service methods, and providers
- **Integration Tests**: Complex queries, relationships, AI adapter selection, backup/restore flows
- **Widget Tests**: UI components with different states (loading, error, populated)
- **Build Tests**: Verify APK builds successfully without errors
- **Runtime Tests**: Manual testing on physical devices for location tracking, AI generation, permissions

### Git Workflow
- **License**: GNU Affero General Public License v3 (AGPLv3) - strong copyleft
- **Commit Messages**: Clear, concise descriptions of changes
- **Never Commit**: 
  - Secrets or API keys (use .env.example templates)
  - Sensitive user data or test data in production
  - Development seed data in release builds (`kDebugMode` guards required)

## Domain Context

### Journal Entry Structure ("Daily Canvas")
Each day's entry is a multimedia document with:
- **Text Summary**: AI-generated narrative synthesizing the day's activities
- **Image Gallery**: Photos/videos captured that day (EXIF metadata extracted)
- **Location Map**: Interactive map showing movements, routes, significant locations
- **Data Timeline**: Chronological events (calendar, fitness, music, BLE proximity)

### Data Collection Sources

#### Priority 0 (MVP - Must Have)
- **Location Services**: GPS tracking for significant locations and movements
- **Photo Library**: On-device media with EXIF metadata (timestamps, GPS, camera settings)

#### Priority 1 (High Priority)
- **Calendar Integration**: Native calendar events (meetings, appointments)
- **Health/Fitness**: HealthKit (iOS) and Google Fit (Android) data
- **Bluetooth Proximity**: BLE scanning for social graph (time with other users/beacons)

#### Priority 2 (Future)
- **Plugin-Based Integrations**: IFTTT-like system for third-party services (Spotify, Strava, social media)

### Privacy-First Principles
1. **Local-First**: Primary data copy always on-device; offline-capable
2. **Data Sovereignty**: Complete data export in documented JSON/Markdown format
3. **Transparency**: Open-source codebase for audit and trust
4. **User Control**: Granular permissions, just-in-time requests with explanations
5. **Optional Cloud**: All sync/backup is opt-in with client-side encryption

### Monetization Strategy
- **Free Tier**: 3 AI summaries/day via managed cloud endpoint, unlimited template generation
- **Pro Tier** ($4.99/month or $49.99/year): 25 AI summaries/day, advanced insights, premium features
- **BYOK Option**: Users provide own Gemini API key for unlimited generation
- **Value-for-Value**: Lightning Network micropayments (zaps)

## Important Constraints

### Technical Constraints
- **Mobile-Only**: Flutter app targeting iOS and Android (no web/desktop yet)
- **Android API 21+ Required**: Minimum Android 5.0 for broad compatibility
- **ML Kit GenAI Limitations**: 
  - Requires Android API 26+ (Android 8.0)
  - Requires AICore app installed on device
  - Only available on Pixel 8+, Galaxy S24+, and select flagships
- **Model Sizes**: 
  - Keep bundled TFLite models small (combined <50MB)
  - Gemini Nano models (~2GB) downloaded on first launch, not bundled
- **APK Size Optimization**: Minimize final APK size (target <100MB)

### Business Constraints
- **Privacy-First = No User Data Sale**: Cannot monetize via advertising or data sales
- **AGPLv3 License**: All forks must remain open-source; prevents proprietary cloud services
- **Gemini Terms of Use**: Must comply with Google's GenAI usage restrictions

### Regulatory Constraints
- **GDPR Compliance**: User data rights (access, deletion, portability)
- **App Store Requirements**: Proper permission usage descriptions, privacy policy
- **Health Data Regulations**: HIPAA-aware handling of health/fitness data

### Development Constraints
- **Production Data Safety**: 
  - NO development seed data in release builds
  - Use `kDebugMode` guards for all test data
  - Validate real data availability before AI generation
- **Edit Protection**: Never lose user-edited content during regeneration
- **Graceful Degradation**: App must work perfectly even without AI/cloud features

## External Dependencies

### Google Cloud Platform
- **Vertex AI**: Gemini 2.5 Pro API access via secure proxy service
- **Service Account**: Authentication for proxy service (not end-user credentials)

### ML Kit Services
- **ML Kit GenAI**: On-device summarization, image description, text rewriting APIs
- **ML Kit Vision**: Image labeling, object detection, face detection, text recognition
- **AICore App**: Required system app for ML Kit GenAI functionality

### Device Platform APIs
- **iOS**: EventKit (calendar), HealthKit (health), Core Location, Photos framework
- **Android**: Calendar Provider, Google Fit, Fused Location Provider, MediaStore

### Nostr Ecosystem
- **Nostr Relays**: Decentralized event publishing (public/private relays)
- **Blossom Servers**: Binary blob storage on Nostr infrastructure
- **Lightning Network**: Micropayment infrastructure via NIP-47 wallets

### Optional Cloud Services (User-Controlled)
- **Google Drive**: User's own Drive account for encrypted backups
- **iCloud**: Future iOS backup integration
- **Dropbox**: Placeholder for future implementation
- **Syncthing**: Open-source peer-to-peer file sync (external daemon)

### Package Dependencies (Key Examples)
See `mobile-app/pubspec.yaml` for complete list. Critical dependencies:
- `riverpod` - State management
- `drift` - SQLite database
- `photo_manager` - Photo library access
- `flutter_background_geolocation` - Background location tracking
- `google_mlkit_*` - ML Kit services
- `google_generative_ai` - Gemini API client
- `flutter_secure_storage` - Secure key storage
- `sentry_flutter` - Crash reporting
- `package_info_plus` - App version info
