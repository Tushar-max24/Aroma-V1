import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/config/app_config.dart';

class RecipeAIService {
  // Only API key from environment
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _openAiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _openAiModel = 'gpt-3.5-turbo';
  static Future<Map<String, dynamic>> fetchRecipeData(String recipeName) async {
    final url = Uri.parse(_openAiUrl);

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${_apiKey}",
      },
      body: jsonEncode({
        "model": _openAiModel,
        "messages": [
          {
            "role": "system",
            "content": "Return ONLY valid JSON. No explanation."
          },
          {
            "role": "user",
            "content": """
Generate recipe details for "$recipeName" in JSON only.

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
}
"""
          }
        ],
        "temperature": 0.5
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("GPT API failed: ${response.body}");
    }

    final data = jsonDecode(response.body);
    return jsonDecode(data["choices"][0]["message"]["content"]);
  }
}
