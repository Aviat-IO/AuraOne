import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/app_lock_service.dart';

class PrivacyScreenOverlay extends HookConsumerWidget {
  final Widget child;

  const PrivacyScreenOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLockState = ref.watch(appLockServiceProvider);
    final showPrivacyOverlay = useState(false);

    useEffect(() {
      void handleAppLifecycleState(AppLifecycleState state) {
        if (!appLockState.isEnabled) return;

        switch (state) {
          case AppLifecycleState.inactive:
          case AppLifecycleState.paused:
          case AppLifecycleState.hidden:
            // Show privacy screen when app goes to background
            showPrivacyOverlay.value = true;
            break;
          case AppLifecycleState.resumed:
            // Hide privacy screen and check for auto-lock
            showPrivacyOverlay.value = false;
            ref.read(appLockServiceProvider.notifier).checkAutoLock();
            break;
          case AppLifecycleState.detached:
            break;
        }
      }

      // Create app lifecycle listener
      final observer = _AppLifecycleObserver(handleAppLifecycleState);
      WidgetsBinding.instance.addObserver(observer);

      return () {
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, [appLockState.isEnabled]);

    return Stack(
      children: [
        child,
        if (showPrivacyOverlay.value && appLockState.isEnabled)
          _buildPrivacyOverlay(context),
      ],
    );
  }

  Widget _buildPrivacyOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AuraOne',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Privacy Protected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final void Function(AppLifecycleState) onStateChanged;

  _AppLifecycleObserver(this.onStateChanged);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
