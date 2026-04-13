import 'package:flutter_test/flutter_test.dart';
import 'package:aura_one/services/ai/gemma_local_adapter.dart';
import 'package:aura_one/services/ai/gemma_model_service.dart';
import 'package:aura_one/services/daily_context_synthesizer.dart';

void main() {
  group('GemmaLocalAdapter', () {
    test('reports unavailable when Gemma is not installed', () async {
      final adapter = GemmaLocalAdapter(
        service: GemmaModelService(
          runtime: FakeGemmaRuntime(isInstalled: false),
        ),
      );

      expect(await adapter.checkAvailability(), isFalse);
    });

    test('downloads required assets through the Gemma service', () async {
      final runtime = FakeGemmaRuntime();
      final adapter = GemmaLocalAdapter(
        service: GemmaModelService(runtime: runtime),
      );

      final progressValues = <double>[];
      final success = await adapter.downloadRequiredAssets(
        onProgress: progressValues.add,
      );

      expect(success, isTrue);
      expect(runtime.installCalled, isTrue);
      expect(progressValues, [0.25, 1.0]);
    });

    test('returns a generated summary when Gemma is installed', () async {
      final adapter = GemmaLocalAdapter.testable(
        service: GemmaModelService(
          runtime: FakeGemmaRuntime(
            isInstalled: true,
            responseText: 'Today included a short local summary.',
          ),
        ),
        isSupportedPlatform: () => true,
      );

      final result = await adapter.generateSummary(_buildContext());

      expect(result.success, isTrue);
      expect(result.content, contains('local summary'));
      expect(result.metadata?['adapter'], 'GemmaLocal');
    });
  });
}

DailyContext _buildContext() {
  return DailyContext(
    date: DateTime(2026, 4, 12),
    photoContexts: const [],
    calendarEvents: const [],
    locationPoints: const [],
    activities: const [],
    movementData: const [],
    geofenceEvents: const [],
    locationNotes: const [],
    environmentSummary: EnvironmentSummary(
      dominantEnvironments: const [],
      environmentCounts: const {},
      weatherConditions: const [],
      timeOfDayAnalysis: TimeOfDayAnalysis(
        morningPhotos: 0,
        afternoonPhotos: 0,
        eveningPhotos: 0,
        mostActiveTime: 'morning',
        activityByTimeOfDay: const {},
      ),
    ),
    socialSummary: SocialSummary(
      totalPeopleDetected: 0,
      averageGroupSize: 0,
      socialContexts: const [],
      socialActivityCounts: const {},
      hadSignificantSocialTime: false,
    ),
    activitySummary: ActivitySummary(
      primaryActivities: const [],
      activityDurations: const {},
      detectedObjects: const [],
      environments: const [],
      hadPhysicalActivity: false,
      hadCreativeActivity: false,
      hadWorkActivity: false,
    ),
    locationSummary: LocationSummary(
      significantPlaces: const [],
      totalDistance: 0,
      timeMoving: Duration.zero,
      timeStationary: Duration.zero,
      movementModes: const [],
      placeTimeSpent: const {},
    ),
    proximitySummary: ProximitySummary(
      nearbyDevicesDetected: 0,
      frequentProximityLocations: const [],
      locationDwellTimes: const {},
      hasProximityInteractions: false,
      geofenceTransitions: const [],
    ),
    writtenContentSummary: WrittenContentSummary(
      locationNoteContent: const [],
      significantThemes: const [],
      totalWrittenEntries: 0,
      hasSignificantContent: false,
      emotionalTones: const {},
      keyTopics: const [],
    ),
    overallConfidence: 0,
    metadata: const {},
    timelineEvents: const [],
  );
}

class FakeGemmaRuntime implements GemmaRuntime {
  FakeGemmaRuntime({this.isInstalled = false, this.responseText = 'OK'});

  final bool isInstalled;
  final String responseText;

  bool installCalled = false;

  @override
  Future<void> initialize({String? huggingFaceToken}) async {}

  @override
  Future<bool> isModelInstalled(String fileName) async => isInstalled;

  @override
  Future<void> installModel({
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    installCalled = true;
    onProgress?.call(0.25);
    onProgress?.call(1.0);
  }

  @override
  Future<GemmaActiveModelRuntime> getActiveModel({
    int maxTokens = 2048,
    GemmaPreferredBackend preferredBackend = GemmaPreferredBackend.gpu,
  }) async {
    return _FakeGemmaActiveModelRuntime(responseText: responseText);
  }

  @override
  Future<void> deleteModel({
    required String fileName,
    required String url,
  }) async {}
}

class _FakeGemmaActiveModelRuntime implements GemmaActiveModelRuntime {
  _FakeGemmaActiveModelRuntime({required this.responseText});

  final String responseText;

  @override
  Future<GemmaChatRuntime> createChat() async {
    return _FakeGemmaChatRuntime(responseText: responseText);
  }

  @override
  Future<void> close() async {}
}

class _FakeGemmaChatRuntime implements GemmaChatRuntime {
  _FakeGemmaChatRuntime({required this.responseText});

  final String responseText;

  @override
  Future<void> addUserText(String prompt) async {}

  @override
  Future<String> generateResponse() async => responseText;
}
