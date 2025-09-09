import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/colors.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';

final selectedTabIndexProvider = StateProvider<int>((ref) => 2); // Default to Home (center tab)

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? [
                    AuraColors.lightSurface.withValues(alpha: 0.95),
                    AuraColors.lightSurface,
                  ]
                : [
                    AuraColors.darkSurface.withValues(alpha: 0.95),
                    AuraColors.darkSurface,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? AuraColors.lightPrimary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  theme: theme,
                  isLight: isLight,
                  index: 0,
                  selectedIndex: selectedIndex,
                  icon: Icons.search,
                  label: 'Search',
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 0,
                ),
                _buildNavItem(
                  context: context,
                  theme: theme,
                  isLight: isLight,
                  index: 1,
                  selectedIndex: selectedIndex,
                  icon: Icons.history,
                  label: 'History',
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 1,
                ),
                // Emphasized center Home button
                _buildCenterNavItem(
                  context: context,
                  theme: theme,
                  isLight: isLight,
                  index: 2,
                  selectedIndex: selectedIndex,
                  icon: Icons.home,
                  label: 'Home',
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 2,
                ),
                _buildNavItem(
                  context: context,
                  theme: theme,
                  isLight: isLight,
                  index: 3,
                  selectedIndex: selectedIndex,
                  icon: Icons.shield,
                  label: 'Privacy',
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 3,
                ),
                _buildNavItem(
                  context: context,
                  theme: theme,
                  isLight: isLight,
                  index: 4,
                  selectedIndex: selectedIndex,
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required ThemeData theme,
    required bool isLight,
    required int index,
    required int selectedIndex,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ) ?? const TextStyle(),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem({
    required BuildContext context,
    required ThemeData theme,
    required bool isLight,
    required int index,
    required int selectedIndex,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isSelected ? 56 : 48,
          height: isSelected ? 56 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? (isLight ? AuraColors.lightLogoGradient : AuraColors.darkLogoGradient)
                  : [
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                      theme.colorScheme.secondary.withValues(alpha: 0.3),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? (isLight 
                        ? AuraColors.lightPrimary.withValues(alpha: 0.4)
                        : AuraColors.darkPrimary.withValues(alpha: 0.3))
                    : theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: isSelected ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                color: isSelected 
                    ? Colors.white 
                    : theme.colorScheme.primary,
                size: isSelected ? 28 : 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}