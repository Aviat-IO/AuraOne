import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/media_database.dart';
import '../database/location_database.dart';
import '../services/ai_pipeline_tester.dart';
import '../services/daily_context_synthesizer.dart';
import '../services/ai_feature_extractor.dart';

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

  // You'll need to provide these databases from your app's providers
  // For now, this is a placeholder that shows the integration pattern
  final mediaDatabase = MediaDatabase(); // Replace with your actual database provider
  final locationDatabase = LocationDatabase(); // Replace with your actual database provider

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

  // You'll need to provide these from your app's providers
  final mediaDatabase = MediaDatabase(); // Replace with your actual database provider
  final locationDatabase = LocationDatabase(); // Replace with your actual database provider

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

  // Run tests with actual databases (you'll need to inject these properly)
  final mediaDatabase = MediaDatabase();
  final locationDatabase = LocationDatabase();

  final results = await tester.runComprehensiveTests(
    mediaDatabase: mediaDatabase,
    locationDatabase: locationDatabase,
  );

  // Cache the results
  ref.read(latestTestResultsProvider.notifier).state = results;

  return results;
});