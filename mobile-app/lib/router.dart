import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura_one/screens/main_layout_screen.dart';
import 'package:aura_one/screens/onboarding_screen.dart';
import 'package:aura_one/screens/privacy_settings_screen.dart';
import 'package:aura_one/screens/location_history_screen.dart';
import 'package:aura_one/screens/photo_test_screen.dart';
import 'package:aura_one/screens/debug/data_viewer_screen.dart';
import 'package:aura_one/screens/debug/database_viewer_screen.dart';
import 'package:aura_one/screens/debug/journal_debug_screen.dart';
import 'package:aura_one/screens/export_screen.dart';
import 'package:aura_one/screens/import_screen.dart';
import 'package:aura_one/screens/backup_settings_screen.dart';
import 'package:aura_one/screens/syncthing_settings_screen.dart';
import 'package:aura_one/screens/app_lock_settings_screen.dart';
import 'package:aura_one/screens/privacy_dashboard_screen.dart';
import 'package:aura_one/screens/privacy/data_deletion_screen.dart';
import 'package:aura_one/screens/font_size_settings_screen.dart';
import 'package:aura_one/screens/about_screen.dart';
import 'package:aura_one/screens/har_test_screen.dart';
import 'package:aura_one/screens/event_detail_screen.dart';
import 'package:aura_one/widgets/daily_canvas/timeline_widget.dart';

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

      // Privacy and location settings
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),

      // Privacy dashboard
      GoRoute(
        path: '/privacy/dashboard',
        builder: (context, state) => const PrivacyDashboardScreen(),
      ),

      // Location history management
      GoRoute(
        path: '/privacy/location-history',
        builder: (context, state) => const LocationHistoryScreen(),
      ),

      // Data deletion screen
      GoRoute(
        path: '/privacy/data-deletion',
        builder: (context, state) => const DataDeletionScreen(),
      ),

      // Photo service test screen (for development)
      GoRoute(
        path: '/test/photos',
        builder: (context, state) => const PhotoTestScreen(),
      ),

      // Debug screens
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

      // About screen
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutScreen(),
      ),


      // HAR Model test screen
      GoRoute(
        path: '/test/har',
        builder: (context, state) => const HARTestScreen(),
      ),

      // Event detail screen
      GoRoute(
        path: '/event-detail',
        builder: (context, state) {
          final event = state.extra as TimelineEvent;
          return EventDetailScreen(event: event);
        },
      ),
    ],
  );
});
