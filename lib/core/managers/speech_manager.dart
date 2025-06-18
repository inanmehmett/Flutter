import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused }

class SpeechManager extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5;

  TtsState get ttsState => _ttsState;
  double get volume => _volume;
  double get pitch => _pitch;
  double get rate => _rate;

  SpeechManager() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_rate);

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
      notifyListeners();
    });

    _flutterTts.setPauseHandler(() {
      _ttsState = TtsState.paused;
      notifyListeners();
    });

    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      notifyListeners();
    });
  }

  Future<void> speak(String text) async {
    if (_ttsState == TtsState.playing) {
      await stop();
    }
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
    notifyListeners();
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _ttsState = TtsState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_ttsState == TtsState.paused) {
      await speak(_lastSpokenText);
    }
  }

  final String _lastSpokenText = '';

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _flutterTts.setVolume(volume);
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
    notifyListeners();
  }

  Future<void> setRate(double rate) async {
    _rate = rate;
    await _flutterTts.setSpeechRate(rate);
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
