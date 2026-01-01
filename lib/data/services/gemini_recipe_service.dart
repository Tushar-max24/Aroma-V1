import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiRecipeService {
  static void initialize() {
    // Initialization logic can be added here if needed
    // Currently just a placeholder to satisfy the call in main.dart
  }

  // Remove hardcoded API key - use AppConfig instead

  static String _extractFirstJsonObject(String text) {
    var cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      throw const FormatException('No JSON object found in model response');
    }
    return cleaned.substring(jsonStart, jsonEnd + 1).trim();
  }

  static String _extractFirstJsonArray(String text) {
    var cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final jsonStart = cleaned.indexOf('[');
    final jsonEnd = cleaned.lastIndexOf(']');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      throw const FormatException('No JSON array found in model response');
    }
    return cleaned.substring(jsonStart, jsonEnd + 1).trim();
  }

  static Future<Map<String, dynamic>> fetchRecipeData(String recipeName) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent?key=${dotenv.env['GEMINI_API_KEY'] ?? ''}",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
Generate recipe details for "$recipeName" in STRICT JSON format only.
Return ONLY a valid JSON object. No markdown.

{
  "description": "2-3 lines",
  "nutrition": {
    "calories": "215 kcal",
    "protein": "30g",
    "carbs": "65g",
    "fat": "46g"
  },
  "cookware": ["Pan", "Pressure Cooker"],
  "steps": [
    {
      "instruction": "Heat oil in a pan over medium heat.",
      "ingredients": [
        {"item": "Oil", "quantity": "2 tbsp"}
      ],
      "tips": [
        "Do not overheat the oil? Medium heat is enough"
      ]
    }
  ],
  "similar_recipes": ["Recipe A", "Recipe B"]
}
"""
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Gemini API failed: ${response.body}");
      }

      final decoded = jsonDecode(response.body);
      String text = decoded["candidates"][0]["content"]["parts"][0]["text"];

      final obj = jsonDecode(_extractFirstJsonObject(text));

      if (obj is Map<String, dynamic>) {
        return obj;
      }
      throw const FormatException('Model returned JSON but not an object');
    } catch (e) {
      throw Exception("Error processing Gemini response: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchReviews(
    String recipeName, {
    int count = 3,
  }) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent?key=${dotenv.env['GEMINI_API_KEY'] ?? ''}",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
Generate $count realistic user reviews for the recipe "$recipeName".
Return ONLY a valid JSON array (no markdown fences, no extra text).

Schema:
[
  {"name":"Asha","comment":"...","rating":4.5}
]

Rules:
- name: short human name
- comment: 1-2 sentences, specific to taste/texture/ease
- rating: number between 1 and 5 (can be decimals)
"""
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Gemini API failed: ${response.body}");
      }

      final decoded = jsonDecode(response.body);
      final text = decoded["candidates"][0]["content"]["parts"][0]["text"];

      final parsed = jsonDecode(_extractFirstJsonArray(text));
      if (parsed is! List) {
        throw const FormatException('Model returned JSON but not an array');
      }

      return parsed.whereType<Map>().map((m) {
        final name = (m['name'] ?? 'Anonymous').toString();
        final comment = (m['comment'] ?? '').toString();
        final ratingRaw = m['rating'];
        final rating = ratingRaw is num
            ? ratingRaw.toDouble()
            : double.tryParse(ratingRaw?.toString() ?? '') ?? 0.0;
        return <String, dynamic>{
          'name': name,
          'comment': comment,
          'rating': rating,
        };
      }).toList(growable: false);
    } catch (e) {
      throw Exception("Error processing Gemini reviews: $e");
    }
  }
}
