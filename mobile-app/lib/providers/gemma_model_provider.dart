import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai/gemma_model_service.dart';

final gemmaModelServiceProvider = Provider<GemmaModelService>((ref) {
  return GemmaModelService();
});

final gemmaModelProvider =
    StateNotifierProvider<GemmaModelController, GemmaModelState>((ref) {
      final controller = GemmaModelController(
        ref.watch(gemmaModelServiceProvider),
      );
      controller.refresh();
      return controller;
    });

class GemmaModelState {
  const GemmaModelState({
    required this.descriptor,
    this.isInstalled = false,
    this.isBusy = false,
    this.progress = 0.0,
    this.error,
  });

  final GemmaModelDescriptor descriptor;
  final bool isInstalled;
  final bool isBusy;
  final double progress;
  final String? error;

  String get formattedSize {
    final bytes = descriptor.sizeBytes;
    final gb = bytes / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(2)} GB';
  }

  GemmaModelState copyWith({
    bool? isInstalled,
    bool? isBusy,
    double? progress,
    String? error,
    bool clearError = false,
  }) {
    return GemmaModelState(
      descriptor: descriptor,
      isInstalled: isInstalled ?? this.isInstalled,
      isBusy: isBusy ?? this.isBusy,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GemmaModelController extends StateNotifier<GemmaModelState> {
  GemmaModelController(this._service)
    : super(GemmaModelState(descriptor: _service.descriptor));

  final GemmaModelService _service;

  Future<void> refresh() async {
    try {
      final installed = await _service.isInstalled();
      state = state.copyWith(
        isInstalled: installed,
        isBusy: false,
        progress: installed ? 1.0 : 0.0,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isInstalled: false,
        isBusy: false,
        progress: 0.0,
        error: e.toString(),
      );
    }
  }

  Future<void> install() async {
    state = state.copyWith(isBusy: true, progress: 0.0, clearError: true);

    try {
      await _service.install(
        onProgress: (progress) {
          state = state.copyWith(
            isBusy: true,
            progress: progress.clamp(0.0, 1.0),
            clearError: true,
          );
        },
      );

      state = state.copyWith(
        isInstalled: true,
        isBusy: false,
        progress: 1.0,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> deleteModel() async {
    state = state.copyWith(isBusy: true, clearError: true);

    try {
      await _service.deleteModel();
      state = state.copyWith(
        isInstalled: false,
        isBusy: false,
        progress: 0.0,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}
