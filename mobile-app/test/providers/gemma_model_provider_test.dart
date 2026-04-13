import 'package:flutter_test/flutter_test.dart';
import 'package:aura_one/providers/gemma_model_provider.dart';
import 'package:aura_one/services/ai/gemma_model_service.dart';

void main() {
  group('GemmaModelController', () {
    test('loads installed state on refresh', () async {
      final runtime = _FakeGemmaRuntime(isInstalled: true);
      final controller = GemmaModelController(
        GemmaModelService(runtime: runtime),
      );

      await controller.refresh();

      expect(controller.state.isInstalled, isTrue);
      expect(controller.state.isBusy, isFalse);
      expect(controller.state.error, isNull);
    });

    test('stores refresh errors instead of throwing', () async {
      final runtime = _FakeGemmaRuntime(throwOnInstallCheck: true);
      final controller = GemmaModelController(
        GemmaModelService(runtime: runtime),
      );

      await controller.refresh();

      expect(controller.state.isInstalled, isFalse);
      expect(controller.state.error, contains('install check failed'));
    });

    test('tracks progress during install and marks model installed', () async {
      final runtime = _FakeGemmaRuntime();
      final controller = GemmaModelController(
        GemmaModelService(runtime: runtime),
      );

      await controller.install();

      expect(controller.state.isInstalled, isTrue);
      expect(controller.state.progress, 1.0);
      expect(controller.state.isBusy, isFalse);
    });

    test('removes installed model and clears installed state', () async {
      final runtime = _FakeGemmaRuntime(isInstalled: true);
      final controller = GemmaModelController(
        GemmaModelService(runtime: runtime),
      );

      await controller.refresh();
      await controller.deleteModel();

      expect(controller.state.isInstalled, isFalse);
      expect(runtime.deleteCalled, isTrue);
    });
  });
}

class _FakeGemmaRuntime implements GemmaRuntime {
  _FakeGemmaRuntime({
    this.isInstalled = false,
    this.throwOnInstallCheck = false,
  });

  bool isInstalled;
  final bool throwOnInstallCheck;
  bool deleteCalled = false;

  @override
  Future<void> initialize({String? huggingFaceToken}) async {}

  @override
  Future<bool> isModelInstalled(String fileName) async {
    if (throwOnInstallCheck) {
      throw Exception('install check failed');
    }
    return isInstalled;
  }

  @override
  Future<void> installModel({
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.4);
    onProgress?.call(1.0);
    isInstalled = true;
  }

  @override
  Future<GemmaActiveModelRuntime> getActiveModel({
    int maxTokens = 2048,
    GemmaPreferredBackend preferredBackend = GemmaPreferredBackend.gpu,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteModel({
    required String fileName,
    required String url,
  }) async {
    deleteCalled = true;
    isInstalled = false;
  }
}
