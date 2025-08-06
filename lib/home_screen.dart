import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit_example/voice_command_service.dart';
import 'package:google_ml_kit_example/camera_service.dart';
import 'package:google_ml_kit_example/google_generative_ai_service.dart';
import 'package:google_ml_kit_example/tts_service.dart';
import 'dart:async';
import 'package:google_ml_kit_example/app_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // We've removed all connectivity-related variables and listeners.
  late VoiceCommandService _voiceCommandService;
  late CameraService _cameraService;
  late GoogleGenerativeAIService _aiService;
  late TTSService _ttsService;
  Timer? _photoTimer;
  bool _isStopCalled = false;

  String _responseText =
      "Press the button and say 'give direction', 'describe', or 'offline direction'.";
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    var apiKey = dotenv.env['GEMINI_API_KEY'].toString();
    _voiceCommandService = VoiceCommandService();
    _cameraService = CameraService();
    _aiService = GoogleGenerativeAIService(apiKey: apiKey);
    _ttsService = TTSService();
    _cameraService.initializeCamera();
  }

  void _objectDetector() {
    // This navigation is user-initiated, so it's okay to keep.
    Navigator.pushNamed(context, '/objectDetector');
  }

  void _onVoiceCommand(String command) {
    _voiceCommandService.stopListening();
    _ttsService.stop();
    setState(() {
      _isListening = false;
    });

    String lowerCaseCommand = command.toLowerCase();
    if (lowerCaseCommand.contains("give direction")) {
      AppState.prompt = 1;
      _startContinuousCapture();
    } else if (lowerCaseCommand.contains("describe")) {
      _isStopCalled = false;
      AppState.prompt = 2;
      _captureAndProcessPhoto();
    } else if (lowerCaseCommand.contains("stop direction")) {
      _isStopCalled = true;
      _stopContinuousCapture();
    } else if (lowerCaseCommand.contains("offline direction")) {
      _objectDetector();
    }
  }

  void _startContinuousCapture() {
    _stopContinuousCapture();
    _isStopCalled = false;
    _photoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isStopCalled) {
        _captureAndProcessPhoto();
      }
    });
    setState(() {
      _responseText = "Continuous capture started.";
    });
  }

  void _stopContinuousCapture() {
    if (_photoTimer != null && _photoTimer!.isActive) {
      _photoTimer!.cancel();
      _photoTimer = null;
    }
    _isStopCalled = true;
    setState(() {
      _responseText = "Continuous capture stopped.";
    });
  }

  Future<void> _captureAndProcessPhoto() async {
    try {
      XFile image = await _cameraService.capturePhoto();
      String response = await _aiService.analyzeImage(image);
      setState(() {
        _responseText = response;
      });
      if (!_isStopCalled) {
        await _ttsService.speak(response);
      }
    } catch (e) {
      print("Error capturing or processing photo: $e");
    }
  }

  @override
  void dispose() {
    _stopContinuousCapture();
    if (_isListening) {
      _voiceCommandService.stopListening();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Blind Assistance",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        elevation: 8,
        backgroundColor: Colors.white38,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _responseText,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                if (!_isListening) {
                  setState(() => _isListening = true);
                  _ttsService.stop();
                  _voiceCommandService.startListening(_onVoiceCommand);
                } else {
                  _voiceCommandService.stopListening();
                  setState(() => _isListening = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 60.0, vertical: 100.0),
                textStyle:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(_isListening ? "Stop Listening" : "Start Listening"),
            ),
          ],
        ),
      ),
    );
  }
}
