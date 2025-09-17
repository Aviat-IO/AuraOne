import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../widgets/common/pill_nav_bar.dart';
import '../widgets/common/pill_tab_bar.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';

final selectedTabIndexProvider = StateProvider<int>((ref) => 2); // Default to Home (middle tab)

class MainLayoutScreen extends ConsumerWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final screens = [
      const SearchScreen(),
      const HistoryScreen(),
      const HomeScreen(),
      const PrivacyScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: PillNavBar(
        selectedIndex: selectedIndex,
        items: const [
          PillTabItem(icon: Icons.search, label: 'Search'),
          PillTabItem(icon: Icons.history, label: 'History'),
          PillTabItem(icon: Icons.home, label: 'Home'),
          PillTabItem(icon: Icons.privacy_tip, label: 'Privacy'),
          PillTabItem(icon: Icons.settings, label: 'Settings'),
        ],
        onItemSelected: (index) {
          // If navigating to Home (index 2), reset to Overview tab
          if (index == 2) {
            ref.read(homeSubTabIndexProvider.notifier).state = 0;
          }
          ref.read(selectedTabIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
