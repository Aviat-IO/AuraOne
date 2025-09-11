import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'permission_service.dart';

/// Provider for the VoiceEditingService
final voiceEditingServiceProvider = Provider<VoiceEditingService>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  return VoiceEditingService(permissionService);
});

/// Service for handling voice-to-text and text-to-speech operations
class VoiceEditingService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final PermissionService _permissionService;

  bool _isInitialized = false;
  bool _isListening = false;
  String _currentTranscription = '';
  bool _hasPermission = false;

  /// Callback for when speech is recognized
  Function(String)? onSpeechResult;

  /// Callback for listening state changes
  Function(bool)? onListeningStateChanged;

  /// Callback for errors
  Function(String)? onError;

  /// Callback for permission denied
  Function()? onPermissionDenied;

  VoiceEditingService(this._permissionService) {
    _initializeTts();
  }

  /// Initialize text-to-speech settings
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set completion handler
    _flutterTts.setCompletionHandler(() {
      debugPrint("TTS completed");
    });

    // Set error handler
    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS error: $msg");
      onError?.call("Speech error: $msg");
    });
  }

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            onListeningStateChanged?.call(false);
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _isListening = false;
          onListeningStateChanged?.call(false);
          onError?.call(error.errorMsg);
        },
        debugLogging: kDebugMode,
      );

      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      onError?.call('Failed to initialize speech recognition');
      return false;
    }
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized && _speechToText.isAvailable && _hasPermission;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get current transcription
  String get currentTranscription => _currentTranscription;

  /// Check if microphone permission is granted
  bool get hasPermission => _hasPermission;

  /// Check and request microphone permission
  Future<bool> checkAndRequestPermission(BuildContext context) async {
    _hasPermission = await _permissionService.ensureMicrophonePermission(context);
    if (!_hasPermission) {
      onPermissionDenied?.call();
    }
    return _hasPermission;
  }

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speechToText.locales();
  }

  /// Start listening for speech
  Future<void> startListening({
    required BuildContext context,
    String? localeId,
    Duration? listenFor,
  }) async {
    // Check permissions first
    if (!_hasPermission) {
      _hasPermission = await checkAndRequestPermission(context);
      if (!_hasPermission) {
        onError?.call('Microphone permission is required for voice input');
        return;
      }
    }

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_isListening) {
      debugPrint('Already listening');
      return;
    }

    try {
      _currentTranscription = '';
      _isListening = true;
      onListeningStateChanged?.call(true);

      await _speechToText.listen(
        onResult: (result) {
          _currentTranscription = result.recognizedWords;
          debugPrint('Recognized: $_currentTranscription (final: ${result.finalResult})');
          onSpeechResult?.call(_currentTranscription);

          if (result.finalResult) {
            _isListening = false;
            onListeningStateChanged?.call(false);
          }
        },
        localeId: localeId ?? 'en_US',
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _isListening = false;
      onListeningStateChanged?.call(false);
      onError?.call('Failed to start listening');
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      onListeningStateChanged?.call(false);
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
      onError?.call('Failed to stop listening');
    }
  }

  /// Cancel listening without processing results
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.cancel();
      _isListening = false;
      _currentTranscription = '';
      onListeningStateChanged?.call(false);
    } catch (e) {
      debugPrint('Error canceling speech recognition: $e');
      onError?.call('Failed to cancel listening');
    }
  }

  /// Speak text using text-to-speech
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    try {
      await _flutterTts.stop(); // Stop any ongoing speech
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
      onError?.call('Failed to speak text');
    }
  }

  /// Stop text-to-speech
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Set TTS language
  Future<void> setTtsLanguage(String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
  }

  /// Set TTS speech rate (0.0 to 1.0)
  Future<void> setTtsSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// Set TTS volume (0.0 to 1.0)
  Future<void> setTtsVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Set TTS pitch (0.5 to 2.0)
  Future<void> setTtsPitch(double pitch) async {
    await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
  }

  /// Clean up resources
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
}

/// Editing command types
enum EditingCommandType {
  rewrite,
  addDetail,
  removeSection,
  replaceText,
  insertText,
  summarize,
  expand,
  correct,
  unknown,
}

/// Represents a parsed editing command
class EditingCommand {
  final EditingCommandType type;
  final String? target; // What to edit (e.g., "morning section", "lunch details")
  final String? content; // New content or additional details
  final Map<String, dynamic> metadata;

  EditingCommand({
    required this.type,
    this.target,
    this.content,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'EditingCommand(type: $type, target: $target, content: $content)';
  }
}
