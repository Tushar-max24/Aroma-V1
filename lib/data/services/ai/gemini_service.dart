// lib/data/services/gemini_recipe_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';

class GeminiRecipeService {
  static String? _apiKey;
  static String? _modelName;
  static String? _endpoint;

  static Future<void> initialize() async {
    _apiKey = AppConfig().geminiApiKey;
    _modelName = AppConfig().geminiModelName;
    _endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent';
  }

  static Future<Map<String, dynamic>> fetchRecipeData(String recipeName) async {
    if (_apiKey == null) await initialize();
    
    final url = '$_endpoint?key=$_apiKey';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "Generate recipe details for $recipeName in JSON format"
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (kDebugMode) {
          print('Gemini API Response: $decoded');
        }
        return decoded;
      } else {
        throw Exception("Gemini API failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchRecipeData: $e');
      }
      rethrow;
    }
  }
}