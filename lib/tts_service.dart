import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  TTSService() {
    _flutterTts = FlutterTts();

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
    });
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) {
      stop(); // Call stop without waiting
    }
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    _isSpeaking = true;
    await _flutterTts.speak(text);
  }

  void stop() {
    _flutterTts.stop(); // Non-blocking call
    _isSpeaking = false;
  }
}
