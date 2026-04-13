import 'package:flutter_test/flutter_test.dart';
import 'package:aura_one/services/ai/gemma_model_service.dart';

void main() {
  group('GemmaModelService', () {
    test('uses Gemma 4 E2B as the default local model descriptor', () {
      final service = GemmaModelService(runtime: FakeGemmaRuntime());

      expect(service.descriptor.id, 'gemma-4-e2b');
      expect(service.descriptor.fileName, 'gemma-4-E2B-it.litertlm');
      expect(
        service.descriptor.downloadUrl,
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
      );
    });

    test('checks install state using the configured model filename', () async {
      final runtime = FakeGemmaRuntime(isInstalled: true);
      final service = GemmaModelService(runtime: runtime);

      final installed = await service.isInstalled();

      expect(installed, isTrue);
      expect(runtime.lastInstalledQuery, 'gemma-4-E2B-it.litertlm');
    });

    test('forwards install requests and progress to the runtime', () async {
      final runtime = FakeGemmaRuntime();
      final service = GemmaModelService(runtime: runtime);

      final progressValues = <double>[];
      await service.install(onProgress: progressValues.add);

      expect(runtime.installCalled, isTrue);
      expect(runtime.lastInstallUrl, service.descriptor.downloadUrl);
      expect(progressValues, [0.25, 1.0]);
    });

    test(
      'generates text through a chat session and closes the model',
      () async {
        final runtime = FakeGemmaRuntime(responseText: 'Gemma response');
        final service = GemmaModelService(runtime: runtime);

        final response = await service.generateText('Hello Gemma');

        expect(response, 'Gemma response');
        expect(runtime.lastPrompt, 'Hello Gemma');
        expect(runtime.modelClosed, isTrue);
      },
    );

    test('deletes the configured Gemma model via the runtime', () async {
      final runtime = FakeGemmaRuntime();
      final service = GemmaModelService(runtime: runtime);

      await service.deleteModel();

      expect(runtime.deletedFileName, 'gemma-4-E2B-it.litertlm');
      expect(
        runtime.deletedUrl,
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
      );
    });
  });
}

class FakeGemmaRuntime implements GemmaRuntime {
  FakeGemmaRuntime({this.isInstalled = false, this.responseText = 'OK'});

  final bool isInstalled;
  final String responseText;

  String? lastInstalledQuery;
  String? lastInstallUrl;
  String? lastPrompt;
  String? deletedFileName;
  String? deletedUrl;
  bool installCalled = false;
  bool modelClosed = false;

  @override
  Future<void> initialize({String? huggingFaceToken}) async {}

  @override
  Future<bool> isModelInstalled(String fileName) async {
    lastInstalledQuery = fileName;
    return isInstalled;
  }

  @override
  Future<void> installModel({
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    installCalled = true;
    lastInstallUrl = url;
    onProgress?.call(0.25);
    onProgress?.call(1.0);
  }

  @override
  Future<GemmaActiveModelRuntime> getActiveModel({
    int maxTokens = 2048,
    GemmaPreferredBackend preferredBackend = GemmaPreferredBackend.gpu,
  }) async {
    return FakeGemmaActiveModelRuntime(
      onPrompt: (prompt) => lastPrompt = prompt,
      onClose: () => modelClosed = true,
      responseText: responseText,
    );
  }

  @override
  Future<void> deleteModel({
    required String fileName,
    required String url,
  }) async {
    deletedFileName = fileName;
    deletedUrl = url;
  }
}

class FakeGemmaActiveModelRuntime implements GemmaActiveModelRuntime {
  FakeGemmaActiveModelRuntime({
    required this.onPrompt,
    required this.onClose,
    required this.responseText,
  });

  final void Function(String prompt) onPrompt;
  final void Function() onClose;
  final String responseText;

  @override
  Future<GemmaChatRuntime> createChat() async {
    return FakeGemmaChatRuntime(onPrompt: onPrompt, responseText: responseText);
  }

  @override
  Future<void> close() async {
    onClose();
  }
}

class FakeGemmaChatRuntime implements GemmaChatRuntime {
  FakeGemmaChatRuntime({required this.onPrompt, required this.responseText});

  final void Function(String prompt) onPrompt;
  final String responseText;

  @override
  Future<void> addUserText(String prompt) async {
    onPrompt(prompt);
  }

  @override
  Future<String> generateResponse() async {
    return responseText;
  }
}
