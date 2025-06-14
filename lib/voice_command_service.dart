import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceCommandService {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  VoiceCommandService() {
    _speech = stt.SpeechToText();
  }

  Future<void> startListening(Function(String) onCommandRecognized) async {
    // Initialize only once
    bool available = await _speech.initialize();
    if (available) {
      _isListening = true;
      _listenForCommand(onCommandRecognized);
    }
  }

  void _listenForCommand(Function(String) onCommandRecognized) async {
    if (!_isListening) return;

    _speech.listen(
      onResult: (result) {
        // Process only final results
        if (result.finalResult) {
          String text = result.recognizedWords.toLowerCase();
          // Check for commands
          if (text.contains("describe")) {
            onCommandRecognized("describe");
          } else if (text.contains("give direction")) {
            onCommandRecognized("give direction");
          } else if (text.contains("stop direction")) {
            onCommandRecognized("stop direction");
          } else if (text.contains("offline direction")) {
            onCommandRecognized("offline direction");
          } else if (text.contains("go to homepage")) {
            onCommandRecognized("go to homepage");
          }
        }
      },
      listenFor: Duration(minutes: 5), // Listen for a longer duration
      pauseFor: Duration(seconds: 5), // Pause after speech ends
      onSoundLevelChange: (level) {
        // Optional: Handle sound level changes
      },
    );

    // Restart listening after the session ends
    await Future.delayed(Duration(seconds: 1)); // Small delay before restarting
    if (_isListening) {
      _listenForCommand(onCommandRecognized);
    }
  }

  void stopListening() {
    _isListening = false;
    _speech.stop(); // Stop the current session
  }
}
