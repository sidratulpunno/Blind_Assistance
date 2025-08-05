// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:camera/camera.dart';
// import 'package:google_ml_kit_example/app_state.dart'; // Import for XFile support
// import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// class GoogleGenerativeAIService {
//   final String apiKey;
//
//   GoogleGenerativeAIService({required this.apiKey});
//
//   Future<String> analyzeImage(XFile image) async {
//     try {
//       if (AppState.prompt == 1) {
//         AppState.textPart = dotenv.env['PROMPT_1'].toString();
//
//         // 'i can not see please give me direction to go forward within 20 words and do not tell sorry and how many steps to go :';
//       } else if (AppState.prompt == 2) {
//         AppState.textPart = dotenv.env['PROMPT_2'].toString();
//       }
//
//       // Read image bytes
//       final imageBytes = await image.readAsBytes();
//
//       // Create a generative model instance
//       final model = GenerativeModel(
//         model: 'gemini-1.5-flash-8b',
//         // gemini-2.0-flash-thinking-exp-01-21    gemini-1.5-flash
//         apiKey: apiKey,
//       );
//
//       print(AppState.textPart);
//
//       // Prepare content with the text prompt and image data
//       final content = [
//         Content.multi([
//           TextPart(AppState.textPart),
//           // Text prompt for the model
//           DataPart('image/jpeg', imageBytes),
//           // Use DataPart with MIME type and bytes
//         ]),
//       ];
//
//       // Generate content using the model
//       final response = await model.generateContent(content);
//
//       // Return the model's description or a default message
//       return response.text ?? 'No description provided.';
//     } catch (e) {
//       print('Error analyzing image: $e');
//       return 'wait for a moment';
//     }
//   }
// }

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:google_ml_kit_example/app_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleGenerativeAIService {
  final String apiKey;

  GoogleGenerativeAIService({required this.apiKey});

  Future<String> analyzeImage(XFile image) async {
    try {
      // Select prompt
      if (AppState.prompt == 1) {
        AppState.textPart = dotenv.env['PROMPT_1'].toString();
      } else if (AppState.prompt == 2) {
        AppState.textPart = dotenv.env['PROMPT_2'].toString();
      }

      final imageBytes = await image.readAsBytes();

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      final content = [
        Content.multi([
          TextPart(AppState.textPart),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await model.generateContent(content);
      final resultText = response.text ?? 'No description provided.';

      print("🤖 AI Response: $resultText");

      // Trigger vibration based on AI result
      _vibrateBasedOnText(resultText.toLowerCase());

      return resultText;
    } catch (e) {
      print('Error analyzing image: $e');
      return 'wait for a moment';
    }
  }

  Future<void> _vibrateBasedOnText(String text) async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    final hasCustomSupport =
        await Vibration.hasCustomVibrationsSupport() ?? false;

    if (!hasVibrator) {
      print('⚠️ Device has no vibration support.');
      return;
    }

    // LEFT vibration pattern: 2 short buzzes
    final List<int> leftPattern = [0, 200, 100, 200];

    // RIGHT vibration pattern: 2 short buzzes with pause
    final List<int> rightPattern = [0, 200, 100, 200];

    try {
      if (hasCustomSupport) {
        if (text.contains('left')) {
          print('🔄 Triggering LEFT vibration...');
          await Vibration.vibrate(pattern: leftPattern);
        }

        if (text.contains('right')) {
          print('🔄 Triggering RIGHT vibration...');
          await Vibration.vibrate(pattern: rightPattern);
        }
      } else {
        print('⚠️ Fallback to basic vibration...');
        if (text.contains('left') || text.contains('right')) {
          await Vibration.vibrate(duration: 500);
        } else {
          HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      print('❌ Vibration error: $e');
      HapticFeedback.mediumImpact();
    }
  }
}
