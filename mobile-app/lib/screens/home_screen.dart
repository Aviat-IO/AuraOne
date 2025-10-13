import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/colors.dart';
import '../widgets/page_header.dart';
import '../widgets/daily_entry_view.dart';
import '../providers/preload_provider.dart';
import '../widgets/notebook_icon.dart';

// Provider for sub-tab index (now using the unified component's provider)
final homeSubTabIndexProvider = StateProvider<int>((ref) => 0);

// Provider for history screen selected date (used when navigating from media)
final historySelectedDateProvider = StateProvider<DateTime?>((ref) => null);

// Provider to force rebuilds when time changes
final currentTimeProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  // Emit current time immediately
  yield DateTime.now();

  // Then emit every minute to update greeting and date
  await for (final _ in Stream.periodic(const Duration(minutes: 1))) {
    yield DateTime.now();
  }
});

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // Watch the current time provider to get updates
    final currentTimeAsync = ref.watch(currentTimeProvider);
    final currentTime = currentTimeAsync.valueOrNull ?? DateTime.now();

    // Trigger background data warming for today and adjacent dates
    // This preloads media and map data in the background
    ref.watch(dataWarmingProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight ? [
              AuraColors.lightSurface,
              AuraColors.lightSurface.withValues(alpha: 0.95),
              AuraColors.lightSurfaceContainerLow.withValues(alpha: 0.9),
            ] : [
              AuraColors.darkSurface,
              AuraColors.darkSurface.withValues(alpha: 0.98),
              AuraColors.darkSurfaceContainerLow.withValues(alpha: 0.95),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: PageHeader(
                  icon: null,
                  title: _getGreeting(currentTime),
                  subtitle: _getFormattedDate(currentTime),
                  customIcon: NotebookIcon(isLight: isLight),
                ),
              ),
              // Daily Entry View for today
              Expanded(
                child: DailyEntryView(
                  key: ValueKey(currentTime.day), // Force rebuild when day changes
                  date: currentTime,
                  enableAI: true,
                  enableMediaSelection: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting(DateTime currentTime) {
    final hour = currentTime.hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getFormattedDate(DateTime currentTime) {
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][currentTime.weekday - 1];
    final month = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][currentTime.month - 1];
    return '$weekday, $month ${currentTime.day}';
  }
}