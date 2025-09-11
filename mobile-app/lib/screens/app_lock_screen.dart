import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/app_lock_service.dart';

class AppLockScreen extends HookConsumerWidget {
  const AppLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLockService = ref.read(appLockServiceProvider.notifier);
    final appLockState = ref.watch(appLockServiceProvider);

    useEffect(() {
      // Attempt biometric authentication immediately if available
      if (appLockService.canUseBiometrics) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _attemptBiometricAuth(context, appLockService);
        });
      }
      return null;
    }, []);

    if (!appLockService.shouldShowLockScreen) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AuraOne',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'App is locked for your privacy',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (appLockService.canUseBiometrics) ...[
                      _buildBiometricButton(context, appLockService),
                      const SizedBox(height: 24),
                      if (appLockState.hasPasscode) ...[
                        Text(
                          'or',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                    if (appLockState.hasPasscode)
                      _buildPasscodeButton(context, appLockService),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricButton(
    BuildContext context,
    AppLockService appLockService,
  ) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () => _attemptBiometricAuth(context, appLockService),
              child: Icon(
                Icons.fingerprint,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to authenticate',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPasscodeButton(BuildContext context, AppLockService appLockService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showPasscodeScreen(context, appLockService),
        icon: const Icon(Icons.pin_rounded),
        label: const Text('Enter Passcode'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _attemptBiometricAuth(
    BuildContext context,
    AppLockService appLockService,
  ) async {
    final authenticated = await appLockService.authenticateWithBiometrics(
      reason: 'Authenticate to unlock AuraOne',
    );

    if (!authenticated && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Authentication failed. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showPasscodeScreen(BuildContext context, AppLockService appLockService) {
    screenLock(
      context: context,
      correctString: '', // We'll verify using our service
      canCancel: false,
      maxRetries: 3,
      retryDelay: const Duration(seconds: 30),
      title: const Text(
        'Enter Passcode',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      config: const ScreenLockConfig(
        backgroundColor: Colors.transparent,
      ),
      secretsConfig: SecretsConfig(
        spacing: 15,
        padding: const EdgeInsets.all(40),
        secretConfig: SecretConfig(
          borderColor: Theme.of(context).colorScheme.primary,
          borderSize: 2.0,
          disabledColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          enabledColor: Theme.of(context).colorScheme.primary,
          size: 15,
          builder: (context, config, enabled) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? config.enabledColor : config.disabledColor,
                border: Border.all(
                  width: config.borderSize,
                  color: config.borderColor,
                ),
              ),
              padding: const EdgeInsets.all(10),
              width: config.size,
              height: config.size,
            );
          },
        ),
      ),
      keyPadConfig: KeyPadConfig(
        buttonConfig: KeyPadButtonConfig(
          size: 65,
          fontSize: 24,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          backgroundColor: Colors.transparent,
        ),
        displayStrings: [
          '1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'
        ],
      ),
      customizedButtonTap: () async {
        // Allow biometric auth from passcode screen if available
        if (appLockService.canUseBiometrics) {
          await _attemptBiometricAuth(context, appLockService);
        }
      },
      customizedButtonChild: appLockService.canUseBiometrics
          ? Icon(
              Icons.fingerprint,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onUnlocked: () {
        appLockService.unlock();
        Navigator.of(context).pop();
      },
      onValidate: (passcode) async {
        return await appLockService.verifyPasscode(passcode);
      },
      onError: (retries) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incorrect passcode. $retries attempts remaining.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      onMaxRetries: (retries) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Too many failed attempts. Try again later.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      },
    );
  }
}
