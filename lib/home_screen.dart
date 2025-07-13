import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _HomeScreenState extends State {
  late VoiceCommandService _voiceCommandService;
  late CameraService _cameraService;
  late GoogleGenerativeAIService _aiService;
  late TTSService _ttsService;
  Timer? _photoTimer;
  bool _isStopCalled = false;

  String _responseText =
      "Please press the button and say give direction to get direction and describe for description and offline direction for direction without internet and say stop to stop the process";

  bool _isListening = false; // Flag to track if we're currently listening

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
    Navigator.pushNamed(context, '/objectDetector');
  }

  void _onVoiceCommand(String command) async {
    _voiceCommandService
        .stopListening(); // Stop listening once a command is recognized
    _ttsService.stop(); // Stop any ongoing speech
    setState(() {
      _isListening = false; // Update listening state
    });

    if (command.toLowerCase().contains("give direction")) {
      // _isStopCalled = false;
      // String? currentRoute = ModalRoute.of(context)?.settings.name;
      // if (currentRoute != '/home') {
      //   Navigator.pushNamed(context, '/home');
      // }
      AppState.prompt = 1;
      _startContinuousCapture();
    } else if (command.toLowerCase().contains("describe")) {
      _isStopCalled = false;
      AppState.prompt = 2;
      _captureAndProcessPhoto();
    } else if (command.toLowerCase().contains("stop direction")) {
      _isStopCalled = true;
      _stopContinuousCapture();
      // String? currentRoute = ModalRoute.of(context)?.settings.name;
      // if (currentRoute != '/home') {
      //   Navigator.pushNamed(context, '/home');
      // }
    } else if (command.toLowerCase().contains("offline direction")) {
      _objectDetector();
    }
  }

  void _startContinuousCapture() {
    _stopContinuousCapture();
    _photoTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (_isStopCalled == false) {
        await _captureAndProcessPhoto();
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
      _isStopCalled = true;

      setState(() {
        _responseText = "Continuous capture stopped.";
      });
    }
  }

  Future _captureAndProcessPhoto() async {
    try {
      XFile image = await _cameraService.capturePhoto();
      String response = await _aiService.analyzeImage(image);

      setState(() {
        _responseText = response;
      });
      if (_isStopCalled == false) {
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
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall, // Use themed text style
                    textAlign:
                        TextAlign.start, // Left align for better readability
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15), // Reduced SizedBox height
            // ElevatedButton(
            //   onPressed: _objectDetector,
            //   child: const Text("Offline direction"),
            // ),
            // const SizedBox(height: 15), // Reduced SizedBox height
            // ElevatedButton(
            //   onPressed: () {
            //     AppState.prompt = 1;
            //     _startContinuousCapture();
            //   },
            //   child: const Text("Start Continuous Capture"),
            // ),
            // const SizedBox(height: 15), // Reduced SizedBox height
            // ElevatedButton(
            //   onPressed: () {
            //     _stopContinuousCapture();
            //     _isStopCalled = true;
            //   },
            //   child: const Text("Stop Continuous Capture"),
            // ),
            // const SizedBox(height: 15), // Reduced SizedBox height
            // ElevatedButton(
            //   onPressed: () {
            //     AppState.prompt = 2;
            //     _captureAndProcessPhoto();
            //   },
            //   child: const Text("Describe"),
            // ),
            const SizedBox(height: 15), // Reduced SizedBox height
            ElevatedButton(
              onPressed: () {
                if (!_isListening) {
                  setState(() {
                    _isListening = true;
                  });
                  _ttsService.stop();
                  _voiceCommandService.startListening(_onVoiceCommand);
                } else {
                  _voiceCommandService.stopListening();
                  setState(() {
                    _isListening = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                // Override specific button style for "Listen"
                backgroundColor: _isListening ? Colors.red : Colors.green,
                // Distinct color
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 60.0, vertical: 100.0),
                // Reduced but still large padding
                textStyle:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                // Larger, bold text
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)), // More rounded
              ),
              child: Text(_isListening ? "Stop Listening" : "Start Listening"),
            ),
          ],
        ),
      ),
    );
  }
}
