import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthMethod {
  biometric,
  passcode,
  disabled,
}

enum AutoLockTimeout {
  immediate(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5)),
  fifteenMinutes(Duration(minutes: 15)),
  thirtyMinutes(Duration(minutes: 30)),
  never(Duration(days: 365));

  const AutoLockTimeout(this.duration);
  final Duration duration;

  String get displayName {
    return switch (this) {
      AutoLockTimeout.immediate => 'Immediately',
      AutoLockTimeout.oneMinute => '1 minute',
      AutoLockTimeout.fiveMinutes => '5 minutes',
      AutoLockTimeout.fifteenMinutes => '15 minutes',
      AutoLockTimeout.thirtyMinutes => '30 minutes',
      AutoLockTimeout.never => 'Never',
    };
  }
}

class AppLockState {
  final bool isEnabled;
  final bool isLocked;
  final AuthMethod authMethod;
  final AutoLockTimeout timeout;
  final bool biometricsAvailable;
  final bool hasPasscode;
  final DateTime? lastActiveTime;

  const AppLockState({
    this.isEnabled = false,
    this.isLocked = false,
    this.authMethod = AuthMethod.disabled,
    this.timeout = AutoLockTimeout.fiveMinutes,
    this.biometricsAvailable = false,
    this.hasPasscode = false,
    this.lastActiveTime,
  });

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    AuthMethod? authMethod,
    AutoLockTimeout? timeout,
    bool? biometricsAvailable,
    bool? hasPasscode,
    DateTime? lastActiveTime,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      authMethod: authMethod ?? this.authMethod,
      timeout: timeout ?? this.timeout,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
      hasPasscode: hasPasscode ?? this.hasPasscode,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
    );
  }
}

class AppLockService extends StateNotifier<AppLockState> {
  AppLockService() : super(const AppLockState()) {
    _initialize();
  }

  static const String _keyEnabled = 'app_lock_enabled';
  static const String _keyAuthMethod = 'app_lock_auth_method';
  static const String _keyTimeout = 'app_lock_timeout';
  static const String _keyPasscode = 'app_lock_passcode';

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check biometric availability
      final biometricsAvailable = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final hasBiometrics = biometricsAvailable && availableBiometrics.isNotEmpty;
      
      // Load settings
      final isEnabled = prefs.getBool(_keyEnabled) ?? false;
      final authMethodIndex = prefs.getInt(_keyAuthMethod) ?? AuthMethod.disabled.index;
      final timeoutIndex = prefs.getInt(_keyTimeout) ?? AutoLockTimeout.fiveMinutes.index;
      final hasPasscode = prefs.getString(_keyPasscode) != null;
      
      final authMethod = AuthMethod.values[authMethodIndex];
      final timeout = AutoLockTimeout.values[timeoutIndex];
      
      state = AppLockState(
        isEnabled: isEnabled,
        isLocked: isEnabled, // Start locked if enabled
        authMethod: authMethod,
        timeout: timeout,
        biometricsAvailable: hasBiometrics,
        hasPasscode: hasPasscode,
        lastActiveTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Failed to initialize app lock: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    
    state = state.copyWith(
      isEnabled: enabled,
      isLocked: enabled, // Lock immediately when enabling
    );
  }

  Future<void> setAuthMethod(AuthMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAuthMethod, method.index);
    
    state = state.copyWith(authMethod: method);
  }

  Future<void> setTimeout(AutoLockTimeout timeout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimeout, timeout.index);
    
    state = state.copyWith(timeout: timeout);
  }

  Future<bool> setPasscode(String passcode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPasscode, passcode);
      
      state = state.copyWith(hasPasscode: true);
      return true;
    } catch (e) {
      debugPrint('Failed to set passcode: $e');
      return false;
    }
  }

  Future<bool> removePasscode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPasscode);
      
      state = state.copyWith(hasPasscode: false);
      
      // Switch to biometric if available, otherwise disable
      if (state.biometricsAvailable) {
        await setAuthMethod(AuthMethod.biometric);
      } else {
        await setEnabled(false);
      }
      
      return true;
    } catch (e) {
      debugPrint('Failed to remove passcode: $e');
      return false;
    }
  }

  Future<bool> verifyPasscode(String passcode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPasscode = prefs.getString(_keyPasscode);
      return storedPasscode == passcode;
    } catch (e) {
      debugPrint('Failed to verify passcode: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({String? reason}) async {
    if (!state.biometricsAvailable) return false;
    
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason ?? 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (isAuthenticated) {
        unlock();
      }
      
      return isAuthenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  void unlock() {
    state = state.copyWith(
      isLocked: false,
      lastActiveTime: DateTime.now(),
    );
  }

  void lock() {
    if (!state.isEnabled) return;
    
    state = state.copyWith(
      isLocked: true,
      lastActiveTime: DateTime.now(),
    );
  }

  void updateActivity() {
    if (!state.isEnabled) return;
    
    state = state.copyWith(lastActiveTime: DateTime.now());
  }

  void checkAutoLock() {
    if (!state.isEnabled || state.isLocked || state.timeout == AutoLockTimeout.never) {
      return;
    }
    
    final lastActive = state.lastActiveTime;
    if (lastActive == null) return;
    
    final timeSinceActive = DateTime.now().difference(lastActive);
    if (timeSinceActive >= state.timeout.duration) {
      lock();
    }
  }

  bool get shouldShowLockScreen => state.isEnabled && state.isLocked;

  bool get canUseBiometrics => 
      state.biometricsAvailable && 
      (state.authMethod == AuthMethod.biometric || !state.hasPasscode);

  bool get requiresPasscode => 
      state.authMethod == AuthMethod.passcode || 
      (!state.biometricsAvailable && state.hasPasscode);
}

final appLockServiceProvider = StateNotifierProvider<AppLockService, AppLockState>(
  (ref) => AppLockService(),
);