import 'package:flutter_gemma/flutter_gemma.dart';
import '../../utils/logger.dart';

class GemmaModelDescriptor {
  const GemmaModelDescriptor({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
  });

  final String id;
  final String displayName;
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;
}

enum GemmaPreferredBackend { gpu, cpu }

abstract class GemmaChatRuntime {
  Future<void> addUserText(String prompt);

  Future<String> generateResponse();
}

abstract class GemmaActiveModelRuntime {
  Future<GemmaChatRuntime> createChat();

  Future<void> close();
}

abstract class GemmaRuntime {
  Future<void> initialize({String? huggingFaceToken});

  Future<bool> isModelInstalled(String fileName);

  Future<void> installModel({
    required String url,
    void Function(double progress)? onProgress,
  });

  Future<GemmaActiveModelRuntime> getActiveModel({
    int maxTokens = 2048,
    GemmaPreferredBackend preferredBackend = GemmaPreferredBackend.gpu,
  });

  Future<void> deleteModel({required String fileName, required String url});
}

class FlutterGemmaRuntime implements GemmaRuntime {
  static const int _maxDownloadRetries = 10;

  bool _initialized = false;

  @override
  Future<void> initialize({String? huggingFaceToken}) async {
    if (_initialized) {
      return;
    }

    await FlutterGemma.initialize(
      huggingFaceToken: huggingFaceToken,
      maxDownloadRetries: _maxDownloadRetries,
    );
    _initialized = true;
  }

  @override
  Future<bool> isModelInstalled(String fileName) async {
    await initialize();
    return FlutterGemma.isModelInstalled(fileName);
  }

  @override
  Future<void> installModel({
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    await initialize();

    dynamic installer = FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    ).fromNetwork(url);

    if (onProgress != null) {
      installer = installer.withProgress((progress) {
        final normalized = progress is num ? progress.toDouble() : 0.0;
        onProgress(normalized);
      });
    }

    await installer.install();
  }

  @override
  Future<GemmaActiveModelRuntime> getActiveModel({
    int maxTokens = 2048,
    GemmaPreferredBackend preferredBackend = GemmaPreferredBackend.gpu,
  }) async {
    await initialize();

    final backend = preferredBackend == GemmaPreferredBackend.cpu
        ? PreferredBackend.cpu
        : PreferredBackend.gpu;

    final model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: backend,
    );

    return _FlutterGemmaActiveModelRuntime(model);
  }

  @override
  Future<void> deleteModel({
    required String fileName,
    required String url,
  }) async {
    await initialize();
    final spec = InferenceModelSpec.fromLegacyUrl(
      name: fileName,
      modelUrl: url,
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    );
    await FlutterGemmaPlugin.instance.modelManager.deleteModel(spec);
  }
}

class _FlutterGemmaActiveModelRuntime implements GemmaActiveModelRuntime {
  _FlutterGemmaActiveModelRuntime(this._model);

  final dynamic _model;

  @override
  Future<GemmaChatRuntime> createChat() async {
    final chat = await _model.createChat();
    return _FlutterGemmaChatRuntime(chat);
  }

  @override
  Future<void> close() async {
    await _model.close();
  }
}

class _FlutterGemmaChatRuntime implements GemmaChatRuntime {
  _FlutterGemmaChatRuntime(this._chat);

  final dynamic _chat;

  @override
  Future<void> addUserText(String prompt) async {
    await _chat.addQueryChunk(Message.text(text: prompt, isUser: true));
  }

  @override
  Future<String> generateResponse() async {
    final response = await _chat.generateChatResponse();
    return response?.toString() ?? '';
  }
}

class GemmaModelService {
  GemmaModelService({GemmaRuntime? runtime})
    : _runtime = runtime ?? FlutterGemmaRuntime();

  static final _logger = AppLogger('GemmaModelService');

  static const GemmaModelDescriptor defaultDescriptor = GemmaModelDescriptor(
    id: 'gemma-4-e2b',
    displayName: 'Gemma 4 E2B',
    fileName: 'gemma-4-E2B-it.litertlm',
    downloadUrl:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    sizeBytes: 2583000000,
  );

  final GemmaRuntime _runtime;

  GemmaModelDescriptor get descriptor => defaultDescriptor;

  Future<bool> isInstalled() async {
    return _runtime.isModelInstalled(descriptor.fileName);
  }

  Future<void> install({void Function(double progress)? onProgress}) async {
    _logger.info('Installing ${descriptor.displayName} from Hugging Face');
    await _runtime.installModel(
      url: descriptor.downloadUrl,
      onProgress: onProgress,
    );
  }

  Future<void> deleteModel() async {
    _logger.info('Deleting ${descriptor.displayName}');
    await _runtime.deleteModel(
      fileName: descriptor.fileName,
      url: descriptor.downloadUrl,
    );
  }

  Future<String> generateText(
    String prompt, {
    int maxTokens = 2048,
    GemmaPreferredBackend preferredBackend = GemmaPreferredBackend.gpu,
  }) async {
    final model = await _runtime.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: preferredBackend,
    );

    try {
      final chat = await model.createChat();
      await chat.addUserText(prompt);
      return await chat.generateResponse();
    } finally {
      await model.close();
    }
  }
}
