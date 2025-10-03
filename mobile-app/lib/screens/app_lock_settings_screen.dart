import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/app_lock_service.dart';

class AppLockSettingsScreen extends HookConsumerWidget {
  const AppLockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLockService = ref.read(appLockServiceProvider.notifier);
    final appLockState = ref.watch(appLockServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Lock'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // App Lock Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Enable App Lock'),
                subtitle: const Text('Require authentication to access the app'),
                secondary: const Icon(Icons.lock_outline),
                value: appLockState.isEnabled,
                onChanged: (value) async {
                  if (value && !appLockState.hasPasscode && !appLockState.biometricsAvailable) {
                    _showCreatePasscodeDialog(context, appLockService);
                  } else {
                    await appLockService.setEnabled(value);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            if (appLockState.isEnabled) ...[
              // Authentication Method
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Authentication Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (appLockState.biometricsAvailable)
                      RadioListTile<AuthMethod>(
                        title: const Text('Biometric Authentication'),
                        subtitle: const Text('Use fingerprint or Face ID'),
                        secondary: const Icon(Icons.fingerprint),
                        value: AuthMethod.biometric,
                        groupValue: appLockState.authMethod,
                        onChanged: (value) async {
                          if (value != null) {
                            await appLockService.setAuthMethod(value);
                          }
                        },
                      ),
                    RadioListTile<AuthMethod>(
                      title: const Text('Passcode'),
                      subtitle: const Text('Use a numeric passcode'),
                      secondary: const Icon(Icons.pin),
                      value: AuthMethod.passcode,
                      groupValue: appLockState.authMethod,
                      onChanged: (value) async {
                        if (value != null) {
                          if (!appLockState.hasPasscode) {
                            _showCreatePasscodeDialog(context, appLockService);
                          } else {
                            await appLockService.setAuthMethod(value);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Passcode Management
              if (appLockState.hasPasscode)
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Change Passcode'),
                        subtitle: const Text('Update your passcode'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChangePasscodeDialog(context, appLockService),
                      ),
                      ListTile(
                        leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        title: Text(
                          'Remove Passcode',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        subtitle: const Text('Delete your saved passcode'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showRemovePasscodeDialog(context, appLockService),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Auto-Lock Timeout
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Auto-Lock Timeout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Lock the app automatically after inactivity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...AutoLockTimeout.values.map((timeout) => RadioListTile<AutoLockTimeout>(
                      title: Text(timeout.displayName),
                      value: timeout,
                      groupValue: appLockState.timeout,
                      onChanged: (value) async {
                        if (value != null) {
                          await appLockService.setTimeout(value);
                        }
                      },
                    )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Information Card
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About App Lock',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'App Lock protects your personal data by requiring authentication when opening the app or after periods of inactivity. A privacy screen is also shown when the app goes to background to prevent sensitive content from being visible in app switchers.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePasscodeDialog(BuildContext context, AppLockService appLockService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Passcode'),
        content: const Text('You need to create a passcode to enable app lock.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasscodeCreationScreen(context, appLockService);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPasscodeCreationScreen(BuildContext context, AppLockService appLockService) {
    screenLockCreate(
      context: context,
      title: const Text('Create Passcode'),
      confirmTitle: const Text('Confirm Passcode'),
      onConfirmed: (passcode) async {
        final success = await appLockService.setPasscode(passcode);
        if (success) {
          await appLockService.setEnabled(true);
          await appLockService.setAuthMethod(AuthMethod.passcode);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passcode created successfully')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to create passcode'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
      config: const ScreenLockConfig(
        backgroundColor: Colors.transparent,
      ),
    );
  }

  void _showChangePasscodeDialog(BuildContext context, AppLockService appLockService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Passcode'),
        content: const Text('You will need to verify your current passcode before creating a new one.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasscodeVerificationScreen(
                context,
                appLockService,
                () => _showPasscodeCreationScreen(context, appLockService),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showRemovePasscodeDialog(BuildContext context, AppLockService appLockService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Passcode'),
        content: const Text('Are you sure you want to remove your passcode? This will disable app lock if biometrics are not available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasscodeVerificationScreen(
                context,
                appLockService,
                () async {
                  final success = await appLockService.removePasscode();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passcode removed successfully')),
                    );
                  }
                },
              );
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasscodeVerificationScreen(
    BuildContext context,
    AppLockService appLockService,
    VoidCallback onVerified,
  ) {
    screenLock(
      context: context,
      correctString: '', // We'll verify using our service
      title: const Text('Enter Current Passcode'),
      maxRetries: 3,
      retryDelay: const Duration(seconds: 30),
      onValidate: (passcode) async {
        return await appLockService.verifyPasscode(passcode);
      },
      onUnlocked: () {
        onVerified();
        Navigator.of(context).pop();
      },
      onError: (retries) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incorrect passcode. $retries attempts remaining.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      config: const ScreenLockConfig(
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
