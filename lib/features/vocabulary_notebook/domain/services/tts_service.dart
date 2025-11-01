import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';

/// Result of a TTS operation
class TtsResult {
  final bool isSuccess;
  final String? errorMessage;

  const TtsResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  factory TtsResult.success() => const TtsResult._(isSuccess: true);
  
  factory TtsResult.failure(String message) => TtsResult._(
    isSuccess: false,
    errorMessage: message,
  );

  bool get isFailure => !isSuccess;
}

/// Service wrapper for Text-to-Speech functionality
/// Provides error handling, fallback mechanisms, and user-friendly feedback
class TtsService {
  final FlutterTts _tts;
  bool _isInitialized = false;
  bool _isAvailable = true;

  TtsService(this._tts);

  /// Initialize TTS engine with default settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // Normal speed
      await _tts.setVolume(1.0); // Full volume
      await _tts.setPitch(1.0); // Normal pitch
      _isInitialized = true;
      _isAvailable = true;
    } catch (e) {
      _isAvailable = false;
      _isInitialized = false;
    }
  }

  /// Speak the given text with error handling
  Future<TtsResult> speak(String text) async {
    if (text.trim().isEmpty) {
      return TtsResult.failure('Metin boş olamaz');
    }

    if (!_isInitialized) {
      await initialize();
    }

    if (!_isAvailable) {
      return TtsResult.failure(
        'Ses özelliği kullanılamıyor. Lütfen cihaz ayarlarınızı kontrol edin.',
      );
    }

    try {
      // Stop any ongoing speech first
      await _tts.stop();
      
      // Speak the text
      _isSpeaking = true;
      final result = await _tts.speak(text);
      
      // Set completion handler to track state
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      
      if (result == 1) {
        return TtsResult.success();
      } else {
        _isSpeaking = false;
        return TtsResult.failure(
          'Ses çalınamadı. Lütfen ses ayarlarınızı kontrol edin.',
        );
      }
    } on PlatformException catch (e) {
      _isSpeaking = false;
      return _handlePlatformException(e);
    } catch (e) {
      _isSpeaking = false;
      return TtsResult.failure(
        'Beklenmeyen bir hata oluştu: ${e.toString()}',
      );
    }
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (_) {
      // Ignore errors when stopping
      _isSpeaking = false;
    }
  }

  /// Check if TTS is currently speaking
  /// Note: FlutterTts doesn't provide a reliable way to check speaking status
  /// This is a best-effort implementation using internal state tracking
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    if (rate < 0.0 || rate > 1.0) {
      throw ArgumentError('Speech rate must be between 0.0 and 1.0');
    }
    
    try {
      await _tts.setSpeechRate(rate);
    } catch (_) {
      // Ignore if setting fails
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError('Volume must be between 0.0 and 1.0');
    }
    
    try {
      await _tts.setVolume(volume);
    } catch (_) {
      // Ignore if setting fails
    }
  }

  /// Set language
  Future<TtsResult> setLanguage(String languageCode) async {
    try {
      await _tts.setLanguage(languageCode);
      return TtsResult.success();
    } catch (e) {
      return TtsResult.failure(
        'Dil ayarı değiştirilemedi: $languageCode',
      );
    }
  }

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      if (languages is List) {
        return languages.cast<String>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Check if TTS is available on this device
  bool get isAvailable => _isAvailable;

  /// Dispose resources
  void dispose() {
    stop();
  }

  /// Handle platform-specific exceptions
  TtsResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'not_found':
        return TtsResult.failure(
          'Ses motoru bulunamadı. Lütfen cihaz ayarlarını kontrol edin.',
        );
      case 'network_error':
        return TtsResult.failure(
          'İnternet bağlantısı gerekli. Lütfen bağlantınızı kontrol edin.',
        );
      case 'synthesis_error':
        return TtsResult.failure(
          'Ses sentezi başarısız oldu. Lütfen tekrar deneyin.',
        );
      default:
        return TtsResult.failure(
          'Ses çalınamadı (${e.code}). Lütfen tekrar deneyin.',
        );
    }
  }
}

