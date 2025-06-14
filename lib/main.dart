import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'vision_detector_views/object_detector_view.dart';
import 'package:google_ml_kit_example/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Speak response text every time the app starts
  TTSService ttsService = TTSService();
  String welcomeMessage =
      "Please press the button and say give direction to get direction and describe for description and offline direction for direction without internet and say stop to stop the process";
  // tap Start Listening and say 'Give direction' to get directions or 'Describe' for a description.
  await ttsService.speak(welcomeMessage);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
      routes: {
        "/objectDetector": (context) => ObjectDetectorView(),
        "/home": (context) => HomeScreen(),
      },
    );
  }
}
