import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura_one/services/ai/adapter_registry.dart';
import 'package:aura_one/services/ai/ai_journal_generator.dart';
import 'package:aura_one/services/ai/runtime_selector.dart';
import 'package:aura_one/services/daily_context_synthesizer.dart';

void main() {
  late AdapterRegistry registry;
  late RuntimeSelector selector;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    registry = AdapterRegistry();
    registry.clear();
    selector = RuntimeSelector();
    selector.resetForTesting();
  });

  test('selects GemmaLocal first when it is available', () async {
    registry.registerAdapter(
      _FakeAdapter('GemmaLocal', available: true, tierLevel: 3),
      3,
    );
    registry.registerAdapter(
      _FakeAdapter(
        'ManagedCloudGemini',
        available: true,
        tierLevel: 1,
        requiresNetwork: true,
      ),
      1,
    );

    final selected = await selector.selectAdapter();

    expect(selected?.getCapabilities().adapterName, 'GemmaLocal');
  });

  test(
    'falls back to ManagedCloudGemini when GemmaLocal is unavailable and cloud is enabled',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_cloud_enabled', true);

      registry.registerAdapter(
        _FakeAdapter('GemmaLocal', available: false, tierLevel: 3),
        3,
      );
      registry.registerAdapter(
        _FakeAdapter(
          'ManagedCloudGemini',
          available: true,
          tierLevel: 1,
          requiresNetwork: true,
        ),
        1,
      );

      final selected = await selector.selectAdapter(forceReselect: true);

      expect(selected?.getCapabilities().adapterName, 'ManagedCloudGemini');
    },
  );

  test(
    'returns null when GemmaLocal is unavailable and cloud is disabled',
    () async {
      registry.registerAdapter(
        _FakeAdapter('GemmaLocal', available: false, tierLevel: 3),
        3,
      );
      registry.registerAdapter(
        _FakeAdapter(
          'ManagedCloudGemini',
          available: true,
          tierLevel: 1,
          requiresNetwork: true,
        ),
        1,
      );

      final selected = await selector.selectAdapter();

      expect(selected, isNull);
    },
  );
}

class _FakeAdapter implements AIJournalGenerator {
  _FakeAdapter(
    this.name, {
    required this.available,
    required this.tierLevel,
    this.requiresNetwork = false,
  });

  final String name;
  final bool available;
  final int tierLevel;
  final bool requiresNetwork;

  @override
  Future<bool> checkAvailability() async => available;

  @override
  Future<AIGenerationResult> describeImage(String imagePath) async =>
      AIGenerationResult.failure('unused');

  @override
  Future<bool> downloadRequiredAssets({
    void Function(double p1)? onProgress,
  }) async => true;

  @override
  Future<AIGenerationResult> generateSummary(DailyContext context) async =>
      AIGenerationResult.failure('unused');

  @override
  AICapabilities getCapabilities() {
    return AICapabilities(
      canGenerateSummary: true,
      canDescribeImage: false,
      canRewriteText: false,
      isOnDevice: !requiresNetwork,
      requiresNetwork: requiresNetwork,
      supportedLanguages: {'en'},
      supportedTones: {'friendly'},
      adapterName: name,
      tierLevel: tierLevel,
    );
  }

  @override
  Future<AIGenerationResult> rewriteText(
    String text, {
    String? tone,
    String? language,
  }) async => AIGenerationResult.failure('unused');
}
