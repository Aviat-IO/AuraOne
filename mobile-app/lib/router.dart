import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:aura_one/screens/home_screen.dart';
import 'package:aura_one/screens/privacy_settings_screen.dart';
import 'package:aura_one/screens/location_history_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Privacy and location settings
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      
      // Location history management
      GoRoute(
        path: '/privacy/location-history',
        builder: (context, state) => const LocationHistoryScreen(),
      ),
    ],
  );
});
