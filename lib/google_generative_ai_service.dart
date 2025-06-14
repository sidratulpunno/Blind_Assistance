import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit_example/app_state.dart'; // Import for XFile support
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleGenerativeAIService {
  final String apiKey;

  GoogleGenerativeAIService({required this.apiKey});

  Future<String> analyzeImage(XFile image) async {
    try {
      if (AppState.prompt == 1) {
        print('yesssssssssssssssssssssssssssssssssssss');
        AppState.textPart =
            ' You are a real-time navigation assistant for visually impaired users. I am sending you a photo captured from a forward-facing camera that shows the current environment. Based solely on this image, please provide clear, step-by-step navigational instructions. Your response should include: 1. The approximate number of steps or distance to safely cover before any directional change 2. Identification of any obstacles or objects in the path 3. Specific guidance on how to navigate around these obstacles (e.g., "take a slight left to avoid an obstacle on the right or the door is close or the wall is near stop").4. Any additional safety recommendations or cautions if the scene appears ambiguous or potentially hazardous.Please ensure the language is simple, direct, and easy to understand. give me response under 12 words';

        // 'i can not see please give me direction to go forward within 20 words and do not tell sorry and how many steps to go :';
      } else if (AppState.prompt == 2) {
        print('noooooooooooooooooooooooooooooooooooooo');
        AppState.textPart =
            'please describe the image in normal text without too much space:';
      }

      // Read image bytes
      final imageBytes = await image.readAsBytes();

      // Create a generative model instance
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-8b',
        // gemini-2.0-flash-thinking-exp-01-21    gemini-1.5-flash
        apiKey: apiKey,
      );

      print('helooooooooooooooooooooooooooooooooooooooooooooooo');
      print(AppState.textPart);

      // Prepare content with the text prompt and image data
      final content = [
        Content.multi([
          TextPart(AppState.textPart),
          // Text prompt for the model
          DataPart('image/jpeg', imageBytes),
          // Use DataPart with MIME type and bytes
        ]),
      ];

      // Generate content using the model
      final response = await model.generateContent(content);

      // Return the model's description or a default message
      return response.text ?? 'No description provided.';
    } catch (e) {
      print('hiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii');
      print('Error analyzing image: $e');
      return 'Failed to analyze image. Please try again later.';
    }
  }
}
