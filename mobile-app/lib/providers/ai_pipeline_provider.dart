import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/media_database.dart';
import '../services/ai_pipeline_tester.dart';
import '../services/daily_context_synthesizer.dart';
import '../services/ai_feature_extractor.dart';
import 'media_database_provider.dart';
import 'location_database_provider.dart';

/// Provider for AI pipeline testing
final aiPipelineTesterProvider = Provider<AIPipelineTester>((ref) {
  return AIPipelineTester();
});

/// Provider for daily context synthesizer
final dailyContextSynthesizerProvider = Provider<DailyContextSynthesizer>((ref) {
  return DailyContextSynthesizer();
});

/// Provider for AI feature extractor
final aiFeatureExtractorProvider = Provider<AIFeatureExtractor>((ref) {
  return AIFeatureExtractor();
});

/// Provider for running AI pipeline tests
final aiPipelineTestResultsProvider = FutureProvider<PipelineTestResults>((ref) async {
  final tester = ref.read(aiPipelineTesterProvider);

  // Use actual database providers
  final mediaDatabase = ref.read(mediaDatabaseProvider);
  final locationDatabase = ref.read(locationDatabaseProvider);

  return await tester.runComprehensiveTests(
    mediaDatabase: mediaDatabase,
    locationDatabase: locationDatabase,
  );
});

/// Provider for quick health check
final aiPipelineHealthCheckProvider = FutureProvider<bool>((ref) async {
  final tester = ref.read(aiPipelineTesterProvider);
  return await tester.quickHealthCheck();
});

/// Provider for generating daily context for a specific date
final dailyContextProvider = FutureProvider.family<DailyContext, DateTime>((ref, date) async {
  final synthesizer = ref.read(dailyContextSynthesizerProvider);

  // Use actual database providers
  final mediaDatabase = ref.read(mediaDatabaseProvider);
  final locationDatabase = ref.read(locationDatabaseProvider);

  return await synthesizer.synthesizeDailyContext(
    date: date,
    mediaDatabase: mediaDatabase,
    locationDatabase: locationDatabase,
    activities: [], // You can get this from dataActivityTrackerProvider
    enabledCalendarIds: {}, // You can get this from your calendar settings
  );
});

/// Provider state for AI pipeline status
enum AIPipelineStatus {
  uninitialized,
  initializing,
  ready,
  processing,
  error,
}

/// Provider for tracking AI pipeline status
final aiPipelineStatusProvider = StateProvider<AIPipelineStatus>((ref) {
  return AIPipelineStatus.uninitialized;
});

/// Provider for AI pipeline initialization
final aiPipelineInitializationProvider = FutureProvider<bool>((ref) async {
  final extractor = ref.read(aiFeatureExtractorProvider);

  try {
    ref.read(aiPipelineStatusProvider.notifier).state = AIPipelineStatus.initializing;

    await extractor.initialize();

    ref.read(aiPipelineStatusProvider.notifier).state = AIPipelineStatus.ready;
    return true;
  } catch (e) {
    ref.read(aiPipelineStatusProvider.notifier).state = AIPipelineStatus.error;
    return false;
  }
});

/// Provider for processing photos with AI analysis
final photoAnalysisProvider = FutureProvider.family<List<PhotoContext>, List<MediaItem>>((ref, mediaItems) async {
  final extractor = ref.read(aiFeatureExtractorProvider);

  try {
    ref.read(aiPipelineStatusProvider.notifier).state = AIPipelineStatus.processing;

    final contexts = await extractor.analyzePhotos(mediaItems);

    ref.read(aiPipelineStatusProvider.notifier).state = AIPipelineStatus.ready;
    return contexts;
  } catch (e) {
    ref.read(aiPipelineStatusProvider.notifier).state = AIPipelineStatus.error;
    rethrow;
  }
});

/// Provider for the latest AI pipeline test results (cached)
final latestTestResultsProvider = StateProvider<PipelineTestResults?>((ref) {
  return null;
});

/// Provider that runs tests and caches results
final runAIPipelineTestsProvider = FutureProvider<PipelineTestResults>((ref) async {
  final tester = ref.read(aiPipelineTesterProvider);

  // Use actual database providers
  final mediaDatabase = ref.read(mediaDatabaseProvider);
  final locationDatabase = ref.read(locationDatabaseProvider);

  final results = await tester.runComprehensiveTests(
    mediaDatabase: mediaDatabase,
    locationDatabase: locationDatabase,
  );

  // Cache the results
  ref.read(latestTestResultsProvider.notifier).state = results;

  return results;
});