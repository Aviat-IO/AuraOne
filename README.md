# purplestack

![purplestack](assets/images/purplestack.png)

Development stack designed for AI agents to build Nostr-enabled Flutter applications. It includes a complete tech stack based on Riverpod and Purplebase, along with documentation and recipes for common implementation scenarios.

See [CONTEXT](CONTEXT.md) for more.

Originally created to build the new version of [Zapstore](https://zapstore.dev) and to encourage many more freedom oriented tech tools in the store.

## Sample environment setup

For MacOS (may work with Homebrew on Linux) and just for guidance. View the respective projects' documentation for more.

```bash
# Install Android
brew install android-commandlinetools
# add to shell's rc file ANDROID_SDK_ROOT=/opt/homebrew/share/android-commandlinetools

# Install Java
brew install openjdk@17

# Install Dart
brew tap dart-lang/dart
brew install dart
dart --disable-analytics
dart pub global activate fvm

# Install Flutter
fvm releases
fvm install <version>

sdkmanager --install "platforms;android-35"
sdkmanager --install "build-tools;35.0.0"
sdkmanager --install emulator platform-tools tools
sdkmanager --licenses

sdkmanager --install "system-images;android-30;google_apis;arm64-v8a"
avdmanager create avd --name "pixel_8" --package "system-images;android-35;google_apis;arm64-v8a" --abi "arm64-v8a" --device "pixel_8"
```

## License

MIT
<!-- TASKMASTER_EXPORT_START -->
> 🎯 **Taskmaster Export** - 2025-09-11 16:22:25 UTC
> 📋 Export: with subtasks • Status filter: none
> 🔗 Powered by [Task Master](https://task-master.dev?utm_source=github-readme&utm_medium=readme-export&utm_campaign=auraone&utm_content=task-export-link)

| Project Dashboard |  |
| :-                |:-|
| Task Progress     | █████████████████░░░ 83% |
| Done | 19 |
| In Progress | 0 |
| Pending | 4 |
| Deferred | 0 |
| Cancelled | 0 |
|-|-|
| Subtask Progress | ██████████████████░░ 91% |
| Completed | 67 |
| In Progress | 0 |
| Pending | 7 |


| ID | Title | Status | Priority | Dependencies | Complexity |
| :- | :-    | :-     | :-       | :-           | :-         |
| 1 | App Initialization and Configuration | ✓&nbsp;done | high | None | ● 3 |
| 1.1 | Execute rename_app script with new identity | ✓&nbsp;done | -            | None | N/A |
| 1.2 | Update app icons and splash screen branding | ✓&nbsp;done | -            | 1.1 | N/A |
| 1.3 | Configure app metadata and descriptions | ✓&nbsp;done | -            | 1.1 | N/A |
| 1.4 | Implement error handling and logging infrastructure | ✓&nbsp;done | -            | 1.1 | N/A |
| 2 | Core Database Schema and Models | ✓&nbsp;done | high | 1 | ● 7 |
| 2.1 | Design journal-specific database schema | ✓&nbsp;done | -            | None | N/A |
| 2.2 | Create JournalEntry model with Drift | ✓&nbsp;done | -            | 2.1 | N/A |
| 2.3 | Create MediaItem model with relationships | ✓&nbsp;done | -            | 2.1, 2.2 | N/A |
| 2.4 | Create LocationEvent model | ✓&nbsp;done | -            | 2.1, 2.2 | N/A |
| 2.5 | Create CalendarEvent and PersonTag models | ✓&nbsp;done | -            | 2.1, 2.2 | N/A |
| 2.6 | Implement database indices and migration support | ✓&nbsp;done | -            | 2.2, 2.3, 2.4, 2.5 | N/A |
| 3 | Location Services Integration | ✓&nbsp;done | high | 2 | ● 8 |
| 3.1 | Add location package and configure permissions | ✓&nbsp;done | -            | None | N/A |
| 3.2 | Implement LocationService class with background tracking | ✓&nbsp;done | -            | 3.1 | N/A |
| 3.3 | Add geofencing capabilities | ✓&nbsp;done | -            | 3.2 | N/A |
| 3.4 | Configure battery-efficient tracking settings | ✓&nbsp;done | -            | 3.2 | N/A |
| 3.5 | Handle platform background execution limits | ✓&nbsp;done | -            | 3.2 | N/A |
| 3.6 | Implement location data storage | ✓&nbsp;done | -            | 3.3 | N/A |
| 3.7 | Add privacy controls and permission flows | ✓&nbsp;done | -            | 3.1, 3.6 | N/A |
| 4 | Photo and Media Library Integration | ✓&nbsp;done | high | 2 | ● 9 |
| 4.1 | Integrate photo_manager package and setup media library access | ✓&nbsp;done | -            | None | N/A |
| 4.2 | Implement PhotoService for automated media scanning | ✓&nbsp;done | -            | 4.1 | N/A |
| 4.3 | Add EXIF metadata extraction using exif package | ✓&nbsp;done | -            | 4.2 | N/A |
| 4.4 | Integrate google_mlkit_face_detection for on-device face detection | ✓&nbsp;done | -            | 4.2 | N/A |
| 4.5 | Implement face clustering algorithms for person identification | ✓&nbsp;done | -            | 4.4 | N/A |
| 4.6 | Create media database models and storage schema | ✓&nbsp;done | -            | 4.3, 4.5 | N/A |
| 4.7 | Add support for various media formats (JPEG, HEIC, MP4) | ✓&nbsp;done | -            | 4.6 | N/A |
| 4.8 | Optimize performance for large media collections | ✓&nbsp;done | -            | 4.7 | N/A |
| 5 | Calendar and System Integration | ✓&nbsp;done | medium | 2 | ● 8 |
| 5.1 | Implement iOS EventKit integration | ✓&nbsp;done | -            | None | N/A |
| 5.2 | Implement Android Calendar Provider integration | ✓&nbsp;done | -            | None | N/A |
| 5.3 | Add HealthKit integration (iOS) | ✓&nbsp;done | -            | None | N/A |
| 5.4 | Add Google Fit integration (Android) | ✓&nbsp;done | -            | None | N/A |
| 5.5 | Implement BLE scanning with flutter_blue_plus | ✓&nbsp;done | -            | None | N/A |
| 5.6 | Create CalendarService with privacy controls | ✓&nbsp;done | -            | 5.1, 5.2 | N/A |
| 5.7 | Handle data attribution and source tracking | ✓&nbsp;done | -            | 5.3, 5.4, 5.5, 5.6 | N/A |
| 6 | On-Device AI Text Generation | ✓&nbsp;done | high | 3, 4, 5 | ● 9 |
| 6.1 | Integrate tflite_flutter package | ✓&nbsp;done | -            | None | N/A |
| 6.2 | Select and optimize mobile language model | ✓&nbsp;done | -            | 6.1 | N/A |
| 6.3 | Implement AIService class architecture | ✓&nbsp;done | -            | 6.2 | N/A |
| 6.4 | Create data synthesis pipeline | ✓&nbsp;done | -            | None | N/A |
| 6.5 | Develop prompt engineering templates | ✓&nbsp;done | -            | 6.4 | N/A |
| 6.6 | Add fallback text generation | ✓&nbsp;done | -            | 6.4 | N/A |
| 6.7 | Optimize model performance and memory usage | ✓&nbsp;done | -            | 6.3, 6.5 | N/A |
| 6.8 | Handle model loading and inference errors | ✓&nbsp;done | -            | 6.3, 6.6 | N/A |
| 7 | Voice-to-Text Editing Interface | ✓&nbsp;done | medium | 6 | ● 7 |
| 7.1 | Integrate speech_to_text Package | ✓&nbsp;done | -            | None | N/A |
| 7.2 | Implement VoiceEditingService | ✓&nbsp;done | -            | 7.1 | N/A |
| 7.3 | Create NLP Command Parsing Logic | ✓&nbsp;done | -            | 7.2 | N/A |
| 7.4 | Build Voice Recording UI | ✓&nbsp;done | -            | 7.1 | N/A |
| 7.5 | Add Text-to-Speech Feedback | ✓&nbsp;done | -            | 7.2 | N/A |
| 7.6 | Handle Microphone Permissions and Audio Quality | ✓&nbsp;done | -            | 7.4 | N/A |
| 8 | Home Page with Sub-tabs Interface | ✓&nbsp;done | high | 6 | ● 6 |
| 8.1 | Design home page layout with sub-tabs structure | ✓&nbsp;done | -            | None | N/A |
| 8.2 | Implement Overview sub-tab with AI summary and stats | ✓&nbsp;done | -            | 8.1 | N/A |
| 8.3 | Implement Map sub-tab with daily locations | ✓&nbsp;done | -            | 8.1 | N/A |
| 8.4 | Implement Media sub-tab with daily photos | ✓&nbsp;done | -            | 8.1 | N/A |
| 8.5 | Implement sub-tab navigation controls | ✓&nbsp;done | -            | 8.1 | N/A |
| 8.6 | Add skeleton loading states with skeletonizer | ✓&nbsp;done | -            | 8.2, 8.3, 8.4, 8.5 | N/A |
| 8.7 | Ensure responsive design across screen sizes | ✓&nbsp;done | -            | 8.2, 8.3, 8.4, 8.5, 8.6 | N/A |
| 9 | Data Export and Backup System | ✓&nbsp;done | medium | 8 | ● 8 |
| 9.1 | Design export data format and schema | ✓&nbsp;done | -            | None | N/A |
| 9.2 | Implement local file system export | ✓&nbsp;done | -            | 9.1 | N/A |
| 9.3 | Add Google Drive integration with googleapis | ✓&nbsp;done | -            | 9.2 | N/A |
| 9.4 | Implement Syncthing folder sync | ✓&nbsp;done | -            | 9.2 | N/A |
| 9.5 | Add Blossom decentralized storage | ✓&nbsp;done | -            | 9.2 | N/A |
| 9.6 | Implement client-side encryption | ✓&nbsp;done | -            | 9.1 | N/A |
| 9.7 | Create Nostr integration for selective sharing | ✓&nbsp;done | -            | 9.1, 9.6 | N/A |
| 9.8 | Add backup scheduling and monitoring | ✓&nbsp;done | -            | 9.3, 9.4, 9.5, 9.6 | N/A |
| 10 | Privacy Controls and Permissions Management | ✓&nbsp;done | high | 9 | ● 6 |
| 10.1 | Design granular privacy settings UI | ✓&nbsp;done | -            | None | N/A |
| 10.2 | Implement just-in-time permission request flows | ✓&nbsp;done | -            | 10.1 | N/A |
| 10.3 | Create privacy dashboard with data visualization | ✓&nbsp;done | -            | 10.1 | N/A |
| 10.4 | Add selective data deletion tools | ✓&nbsp;done | -            | 10.3 | N/A |
| 10.5 | Implement app lock with biometric authentication | ✓&nbsp;done | -            | None | N/A |
| 10.6 | Ensure privacy controls accessibility and documentation | ✓&nbsp;done | -            | 10.1, 10.2, 10.3, 10.4, 10.5 | N/A |
| 11 | Animated Bottom Navigation Tab Bar with Smart Titles | ✓&nbsp;done | medium | 8 | N/A |
| 12 | Android Microphone Permission Integration | ✓&nbsp;done | medium | 7 | N/A |
| 13 | UI Navigation Update: Bottom Navigation Tab Restructuring | ✓&nbsp;done | medium | 8, 10 | N/A |
| 14 | Fix Home Screen Banner Scroll Behavior | ✓&nbsp;done | medium | 8, 11 | N/A |
| 15 | Implement Sticky Tab Navigation for Home Screen Sub-tabs | ✓&nbsp;done | medium | 11, 14 | N/A |
| 16 | Replace Today's Summary placeholder with empty state | ✓&nbsp;done | medium | 8 | N/A |
| 17 | Integrate on-device AI for Today's Summary generation | ✓&nbsp;done | medium | 6, 16, 3, 5 | N/A |
| 18 | Voice Command Interface for AI Summary Editing | ✓&nbsp;done | medium | 7, 17, 8 | N/A |
| 19 | Standardized Bottom Navigation Tab Behavior with Consistent Visual States | ✓&nbsp;done | medium | 11, 13 | N/A |
| 20 | Media Linking Feature - Make Home > Media Tab Photos Clickable and Linkable | ○&nbsp;pending | high | 8, 4 | N/A |
| 21 | Local AI Models for Daily Summary Generation (KEY FEATURE) | ○&nbsp;pending | critical | 6, 17, 3, 4, 5 | N/A |
| 21.1 | Project Setup and Core Dependencies | ○&nbsp;pending | -            | None | N/A |
| 21.2 | Spatiotemporal Data Processing - Location Clustering | ○&nbsp;pending | -            | 21.1 | N/A |
| 21.3 | Spatiotemporal Data Processing - Human Activity Recognition | ○&nbsp;pending | -            | 21.1, 21.2 | N/A |
| 21.4 | Visual Context Extraction | ○&nbsp;pending | -            | 21.1 | N/A |
| 21.5 | Multi-modal Fusion and Event Correlation | ○&nbsp;pending | -            | 21.2, 21.3, 21.4 | N/A |
| 21.6 | Narrative Generation | ○&nbsp;pending | -            | 21.5 | N/A |
| 21.7 | Final Optimizations | ○&nbsp;pending | -            | 21.1, 21.2, 21.3, 21.4, 21.5, 21.6 | N/A |
| 22 | UI Fix - Remove Duplicate Sparkle Icons from Today's Summary | ○&nbsp;pending | high | 8, 16, 17 | N/A |
| 23 | Data Persistence - Implement Backup System for App Data Survival | ○&nbsp;pending | high | 9, 2, 3, 4, 5 | N/A |

> 📋 **End of Taskmaster Export** - Tasks are synced from your project using the `sync-readme` command.
<!-- TASKMASTER_EXPORT_END -->
