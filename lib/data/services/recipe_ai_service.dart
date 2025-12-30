import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flavoryx/core/config/app_config.dart';

class RecipeAIService {
  static Future<Map<String, dynamic>> fetchRecipeData(String recipeName) async {
    final config = AppConfig();
    await config.init();
    
    final url = Uri.parse(
      '${config.geminiEndpoint}${config.geminiModelName}:generateContent?key=${config.geminiApiKey}',
    );

    final prompt = """
Generate recipe details for "$recipeName" in valid JSON format. Return ONLY the JSON object, no additional text.

{
  "description": "short description",
  "nutrition": {
    "calories": "215 kcal",
    "protein": "30g",
    "carbs": "65g",
    "fat": "46g"
  },
  "cookware": ["Pan", "Bowl"],
  "steps": ["Step 1", "Step 2"],
  "similar_recipes": ["Recipe A", "Recipe B"]
}""";

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.5,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gemini API failed: ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final content = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];
      
      if (content == null) {
        throw Exception('Invalid response format from Gemini API');
      }

      // Extract JSON from the response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
      if (jsonMatch == null) {
        throw Exception('No valid JSON found in response');
      }
      
      return jsonDecode(jsonMatch.group(0)!);
    } catch (e) {
      throw Exception('Error calling Gemini API: $e');
    }
  }
}
