import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura_one/screens/main_layout_screen.dart';
import 'package:aura_one/screens/onboarding_screen.dart';
// import 'package:aura_one/screens/privacy_settings_screen.dart';  // Temporarily disabled for APK size optimization
import 'package:aura_one/screens/export_screen.dart';
import 'package:aura_one/screens/import_screen.dart';
import 'package:aura_one/screens/backup_settings_screen.dart';
import 'package:aura_one/screens/syncthing_settings_screen.dart';
import 'package:aura_one/screens/app_lock_settings_screen.dart';
// import 'package:aura_one/screens/privacy_dashboard_screen.dart';  // Temporarily disabled for APK size optimization
import 'package:aura_one/screens/privacy/data_deletion_screen.dart';
import 'package:aura_one/screens/font_size_settings_screen.dart';
import 'package:aura_one/screens/calendar_settings_screen.dart';
import 'package:aura_one/screens/about_screen.dart';
import 'package:aura_one/screens/terms_screen.dart';
import 'package:aura_one/screens/privacy_policy_screen.dart';
import 'package:aura_one/screens/event_detail_screen.dart';
import 'package:aura_one/screens/daily_canvas_screen.dart';
import 'package:aura_one/screens/pattern_insights_screen.dart';
import 'package:aura_one/screens/context/people_list_screen.dart';
import 'package:aura_one/screens/context/person_detail_screen.dart';
import 'package:aura_one/screens/context/face_clustering_screen.dart';
import 'package:aura_one/screens/context/places_list_screen.dart';
import 'package:aura_one/screens/context/place_detail_screen.dart';
import 'package:aura_one/screens/context/journal_preferences_screen.dart';
import 'package:aura_one/widgets/daily_canvas/timeline_widget.dart';

// Debug-only imports - excluded from production builds via kDebugMode guards
// import 'package:aura_one/screens/photo_test_screen.dart';  // Temporarily disabled for APK size optimization
import 'package:aura_one/screens/debug/data_viewer_screen.dart';
import 'package:aura_one/screens/debug/database_viewer_screen.dart';
import 'package:aura_one/screens/debug/journal_debug_screen.dart';
import 'package:aura_one/screens/har_test_screen.dart';
import 'package:aura_one/screens/debug_screen.dart';
import 'package:aura_one/screens/test_mlkit_genai_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Check if onboarding has been completed
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      // If we're already on the onboarding screen, don't redirect
      if (state.matchedLocation == '/onboarding') {
        return null;
      }

      // If onboarding not completed and not already going there, redirect to onboarding
      if (!onboardingCompleted) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainLayoutScreen(),
      ),

      // Onboarding screen
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Privacy and location settings - Temporarily disabled for APK size optimization
      // GoRoute(
      //   path: '/privacy',
      //   builder: (context, state) => const PrivacySettingsScreen(),
      // ),

      // Privacy dashboard
      // GoRoute(  // Temporarily disabled for APK size optimization
      //   path: '/privacy/dashboard',
      //   builder: (context, state) => const PrivacyDashboardScreen(),
      // ),

      // Data deletion screen
      GoRoute(
        path: '/privacy/data-deletion',
        builder: (context, state) => const DataDeletionScreen(),
      ),

      // Debug screens - available in all builds for developer tools
      GoRoute(
        path: '/debug/data-viewer',
        builder: (context, state) => const DataViewerScreen(),
      ),
      GoRoute(
        path: '/debug/database-viewer',
        builder: (context, state) => const DatabaseViewerScreen(),
      ),
      GoRoute(
        path: '/debug/journal',
        builder: (context, state) => const JournalDebugScreen(),
      ),

      // Debug-only routes - excluded from production builds
      if (kDebugMode) ...[
        // Photo service test screen (for development) - temporarily disabled for APK size optimization
        // GoRoute(
        //   path: '/test/photos',
        //   builder: (context, state) => const PhotoTestScreen(),
        // ),
      ],

      // Export screen
      GoRoute(
        path: '/export',
        builder: (context, state) => const ExportScreen(),
      ),

      // Import screen
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportScreen(),
      ),

      // Backup settings screen
      GoRoute(
        path: '/settings/backup',
        builder: (context, state) => const BackupSettingsScreen(),
      ),

      // Syncthing settings screen
      GoRoute(
        path: '/settings/syncthing',
        builder: (context, state) => const SyncthingSettingsScreen(),
      ),

      // App lock settings screen
      GoRoute(
        path: '/privacy/app-lock',
        builder: (context, state) => const AppLockSettingsScreen(),
      ),


      // Font size settings screen
      GoRoute(
        path: '/settings/font-size',
        builder: (context, state) => const FontSizeSettingsScreen(),
      ),

      // Calendar settings screen
      GoRoute(
        path: '/settings/calendar',
        builder: (context, state) => const CalendarSettingsScreen(),
      ),

      // People management screen
      GoRoute(
        path: '/settings/people',
        builder: (context, state) => const PeopleListScreen(),
      ),

      // Person detail screen
      GoRoute(
        path: '/settings/people/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PersonDetailScreen(personId: id);
        },
      ),

      // Face clustering screen
      GoRoute(
        path: '/settings/people/face-clustering',
        builder: (context, state) => const FaceClusteringScreen(),
      ),

      // Places management screen
      GoRoute(
        path: '/settings/places',
        builder: (context, state) => const PlacesListScreen(),
      ),

      // Place detail screen
      GoRoute(
        path: '/settings/places/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PlaceDetailScreen(placeId: id);
        },
      ),

      // Journal preferences screen
      GoRoute(
        path: '/settings/journal-preferences',
        builder: (context, state) => const JournalPreferencesScreen(),
      ),

      // About screen
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutScreen(),
      ),

      // Terms of Use screen
      GoRoute(
        path: '/settings/terms',
        builder: (context, state) => const TermsScreen(),
      ),

      // Privacy Policy screen
      GoRoute(
        path: '/settings/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      // Debug screen - now available in all builds
      GoRoute(
        path: '/settings/debug',
        builder: (context, state) => const DebugScreen(),
      ),

      // HAR Model test screen - available in all builds for testing
      GoRoute(
        path: '/test/har',
        builder: (context, state) => const HARTestScreen(),
      ),

      // ML Kit GenAI test screen - for testing Tier 1 adapter on Pixel 9
      GoRoute(
        path: '/test/mlkit-genai',
        builder: (context, state) => const TestMLKitGenAIScreen(),
      ),

      // Event detail screen
      GoRoute(
        path: '/event-detail',
        builder: (context, state) {
          final event = state.extra as TimelineEvent;
          return EventDetailScreen(event: event);
        },
      ),

      // Daily Canvas screen for viewing a specific day's full canvas
      GoRoute(
        path: '/daily-canvas',
        builder: (context, state) {
          final date = state.extra as DateTime? ?? DateTime.now();
          return DailyCanvasScreen(date: date);
        },
      ),

      // Pattern Insights screen for viewing weekly/monthly analysis
      GoRoute(
        path: '/pattern-insights',
        builder: (context, state) => const PatternInsightsScreen(),
      ),
    ],
  );
});
