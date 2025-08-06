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
      // Select prompt based on the app's state
      if (AppState.prompt == 1) {
        AppState.textPart = dotenv.env['PROMPT_1'].toString();
      } else if (AppState.prompt == 2) {
        AppState.textPart = dotenv.env['PROMPT_2'].toString();
      }

      final imageBytes = await image.readAsBytes();

      final model = GenerativeModel(
        model: 'gemini-2.0-flash', // Using the updated model name
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

      // ✅ FIX: Only trigger vibration if the prompt is for directions (prompt 1).
      // This will prevent vibration for descriptive prompts (prompt 2).
      if (AppState.prompt == 1) {
        _vibrateBasedOnText(resultText.toLowerCase());
      }

      return resultText;
    } catch (e) {
      print('Error analyzing image: $e');
      return 'wait for a moment';
    }
  }

  Future<void> _vibrateBasedOnText(String text) async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) {
      print('⚠️ Device has no vibration support.');
      return;
    }

    // Vibration patterns remain the same
    final List<int> leftPattern = [0, 200, 100, 200];
    final List<int> rightPattern = [0, 200, 100, 200];
    final hasCustomSupport =
        await Vibration.hasCustomVibrationsSupport() ?? false;

    try {
      if (hasCustomSupport) {
        if (text.contains('left')) {
          print('🔄 Triggering LEFT vibration...');
          await Vibration.vibrate(pattern: leftPattern);
        } else if (text.contains('right')) {
          // Use 'else if' to avoid both vibrating at once
          print('🔄 Triggering RIGHT vibration...');
          await Vibration.vibrate(pattern: rightPattern);
        }
      } else {
        print('⚠️ Fallback to basic vibration...');
        if (text.contains('left') || text.contains('right')) {
          await Vibration.vibrate(duration: 500);
        }
      }
    } catch (e) {
      print('❌ Vibration error: $e');
      HapticFeedback.mediumImpact();
    }
  }
}
