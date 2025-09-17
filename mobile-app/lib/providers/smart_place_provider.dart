import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for smart place recognition setting with persistence
final smartPlaceRecognitionProvider = StateNotifierProvider<SmartPlaceNotifier, bool>((ref) {
  return SmartPlaceNotifier();
});

class SmartPlaceNotifier extends StateNotifier<bool> {
  static const String _prefsKey = 'smart_place_recognition_enabled';

  SmartPlaceNotifier() : super(true) {
    // Load saved preference on initialization
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Default to true if not set
      state = prefs.getBool(_prefsKey) ?? true;
    } catch (e) {
      // If loading fails, keep default (true)
      state = true;
    }
  }

  Future<void> toggle() async {
    state = !state;
    await _savePreference(state);
  }

  Future<void> setEnabled(bool enabled) async {
    if (state != enabled) {
      state = enabled;
      await _savePreference(enabled);
    }
  }

  Future<void> _savePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (e) {
      // Handle save error silently
    }
  }
}

/// Helper provider to check if smart place recognition is enabled
final isSmartPlaceEnabledProvider = Provider<bool>((ref) {
  return ref.watch(smartPlaceRecognitionProvider);
});