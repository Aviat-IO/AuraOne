import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai/personal_context_engine.dart';
import '../utils/logger.dart';
import 'database_provider.dart';

/// Provider for the Personal Context Engine
/// 100% ON-DEVICE - NO API CALLS
final personalContextEngineProvider = Provider<PersonalContextEngine>((ref) {
  return PersonalContextEngine(
    databaseService: ref.watch(databaseServiceProvider),
  );
});

/// Provider for context engine enabled state
final contextEngineEnabledProvider = StateNotifierProvider<ContextEngineEnabledNotifier, bool>((ref) {
  return ContextEngineEnabledNotifier(ref);
});

class ContextEngineEnabledNotifier extends StateNotifier<bool> {
  final Ref _ref;

  ContextEngineEnabledNotifier(this._ref) : super(true) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('context_engine_enabled') ?? true;

    // Auto-start learning patterns if enabled
    if (state) {
      final engine = _ref.read(personalContextEngineProvider);
      await engine.learnUserPatterns();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('context_engine_enabled', enabled);

    if (enabled) {
      // Start learning patterns when enabled
      final engine = _ref.read(personalContextEngineProvider);
      await engine.learnUserPatterns();
    }
  }
}

/// Provider for generating daily narrative
final dailyNarrativeProvider = FutureProvider.family<PersonalDailyNarrative?, DateTime>((ref, date) async {
  final contextEnabled = ref.watch(contextEngineEnabledProvider);

  if (!contextEnabled) {
    return null;
  }

  final engine = ref.watch(personalContextEngineProvider);

  try {
    final narrative = await engine.generateNarrative(
      date: date,
      includeRecommendations: true,
    );
    return narrative;
  } catch (e, stackTrace) {
    // Log error but don't crash - return safe fallback
    appLogger.error(
      'Failed to generate narrative for date: $date',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});

/// Provider for today's narrative
final todayNarrativeProvider = FutureProvider<PersonalDailyNarrative?>((ref) {
  final today = DateTime.now();
  return ref.watch(dailyNarrativeProvider(today).future);
});

/// Provider for wellness score
final wellnessScoreProvider = Provider<double>((ref) {
  final narrativeAsync = ref.watch(todayNarrativeProvider);

  return narrativeAsync.whenOrNull(
    data: (narrative) => narrative?.wellnessScore ?? 50.0,
  ) ?? 50.0;
});

/// Provider for emotional insights
final emotionalInsightsProvider = Provider<List<String>>((ref) {
  final narrativeAsync = ref.watch(todayNarrativeProvider);

  return narrativeAsync.whenOrNull(
    data: (narrative) => narrative?.emotionalInsights ?? [],
  ) ?? [];
});

/// Provider for recommendations
final recommendationsProvider = Provider<List<String>>((ref) {
  final narrativeAsync = ref.watch(todayNarrativeProvider);

  return narrativeAsync.whenOrNull(
    data: (narrative) => narrative?.recommendations ?? [],
  ) ?? [];
});

/// Provider for activity summary
final activitySummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final narrativeAsync = ref.watch(todayNarrativeProvider);

  return narrativeAsync.whenOrNull(
    data: (narrative) => narrative?.activitySummary ?? {},
  ) ?? {};
});