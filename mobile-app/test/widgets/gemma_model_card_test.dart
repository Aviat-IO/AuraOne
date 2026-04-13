import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_one/providers/gemma_model_provider.dart';
import 'package:aura_one/services/ai/gemma_model_service.dart';
import 'package:aura_one/widgets/gemma_model_card.dart';

void main() {
  GemmaModelState buildState({
    bool isInstalled = false,
    bool isBusy = false,
    double progress = 0.0,
    String? error,
  }) {
    return GemmaModelState(
      descriptor: GemmaModelService.defaultDescriptor,
      isInstalled: isInstalled,
      isBusy: isBusy,
      progress: progress,
      error: error,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('shows install action when model is not installed', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        GemmaModelCard(
          state: buildState(),
          onInstall: () {},
          onDelete: () {},
          onRefresh: () {},
        ),
      ),
    );

    expect(find.text('Local AI Model'), findsOneWidget);
    expect(find.text('Install Gemma 4 E2B'), findsOneWidget);
    expect(find.textContaining('only local model option'), findsOneWidget);
  });

  testWidgets('shows remove action when model is installed', (tester) async {
    await tester.pumpWidget(
      wrap(
        GemmaModelCard(
          state: buildState(isInstalled: true, progress: 1.0),
          onInstall: () {},
          onDelete: () {},
          onRefresh: () {},
        ),
      ),
    );

    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('shows download progress while install is running', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        GemmaModelCard(
          state: buildState(isBusy: true, progress: 0.42),
          onInstall: () {},
          onDelete: () {},
          onRefresh: () {},
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('Downloading Gemma 4 E2B...'), findsOneWidget);
  });
}
