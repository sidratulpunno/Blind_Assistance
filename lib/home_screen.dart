import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:google_ml_kit_example/voice_command_service.dart';
import 'package:google_ml_kit_example/camera_service.dart';
import 'package:google_ml_kit_example/google_generative_ai_service.dart';
import 'package:google_ml_kit_example/tts_service.dart';
import 'dart:async';
import 'package:google_ml_kit_example/app_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late VoiceCommandService _voiceCommandService;
  late CameraService _cameraService;
  late GoogleGenerativeAIService _aiService;
  late TTSService _ttsService;
  Timer? _photoTimer;
  bool _isStopCalled = false;
  String _responseText =
      "You are online. Press the mic and say 'give direction', 'describe', or 'offline direction'.";
  bool _isListening = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    var apiKey = dotenv.env['GEMINI_API_KEY'].toString();
    _voiceCommandService = VoiceCommandService();
    _cameraService = CameraService();
    _aiService = GoogleGenerativeAIService(apiKey: apiKey);
    _ttsService = TTSService();
    _ttsService.speak(
        "You are online. Press the mic and say 'give direction', 'describe', or 'offline direction'.");

    _cameraService.initializeCamera();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _objectDetector() {
    Navigator.pushNamed(context, '/objectDetector');
  }

  void _onVoiceCommand(String command) {
    _voiceCommandService.stopListening();
    _ttsService.stop();
    setState(() => _isListening = false);

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
    _photoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isStopCalled) {
        _captureAndProcessPhoto();
      }
    });
    setState(() {
      _responseText = "Navigating... Say 'stop direction' to end.";
    });
  }

  void _stopContinuousCapture() {
    if (_photoTimer != null && _photoTimer!.isActive) {
      _photoTimer!.cancel();
      _photoTimer = null;
    }
    _isStopCalled = true;
    setState(() {
      _responseText =
          "Navigation stopped. Press the microphone for a new command.";
    });
  }

  Future<void> _captureAndProcessPhoto() async {
    try {
      XFile image = await _cameraService.capturePhoto();
      String response = await _aiService.analyzeImage(image);
      if (mounted) {
        setState(() => _responseText = response);
        if (!_isStopCalled) {
          await _ttsService.speak(response);
        }
      }
    } catch (e) {
      print("Error capturing or processing photo: $e");
    }
  }

  @override
  void dispose() {
    _stopContinuousCapture();
    _animationController.dispose();
    if (_isListening) {
      _voiceCommandService.stopListening();
    }
    super.dispose();
  }

  // ✅ REFACTORED: The microphone button area now fills the available lower space.
  Widget _buildMicButton() {
    return GestureDetector(
      onTap: () {
        if (!_isListening) {
          setState(() => _isListening = true);
          _ttsService.stop();
          _voiceCommandService.startListening(_onVoiceCommand);
        } else {
          _voiceCommandService.stopListening();
          setState(() => _isListening = false);
        }
      },
      // This makes the entire transparent area of the GestureDetector tappable.
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: FadeTransition(
          opacity: _isListening
              ? _animationController
              : const AlwaysStoppedAnimation(1.0),
          child: Container(
            width: 120, // Slightly larger for a more prominent look
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening ? Colors.deepOrangeAccent : Colors.cyan,
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? Colors.deepOrangeAccent : Colors.cyan)
                      .withOpacity(0.6),
                  spreadRadius: _isListening ? 8 : 4,
                  // More glow when listening
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 60, // Larger icon
            ),
          ),
        ),
      ),
    );
  }

  // ✅ REFACTORED: The text card is now wrapped in a SingleChildScrollView.
  Widget _buildResponseCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: SingleChildScrollView(
            // This makes the content scrollable
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                _responseText,
                key: ValueKey<String>(_responseText),
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Vision Assist",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                // ✅ REFACTORED: The layout now uses Expanded with flex factors.
                // The response card will take up the top ~60% of the space.
                Expanded(
                  flex: 3,
                  child: _buildResponseCard(),
                ),
                const SizedBox(height: 20),
                // Spacing between the card and button area
                // The microphone area will take up the bottom ~40% of the space.
                Expanded(
                  flex: 2,
                  child: _buildMicButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
