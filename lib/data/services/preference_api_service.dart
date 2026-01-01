// lib/data/services/preference_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PreferenceApiService {
  static const String _baseUrl = 'http://3.108.110.151:5001';

  static Future<Map<String, dynamic>> generateRecipes(
    List<Map<String, dynamic>> ingredients,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/generate-recipes-ingredient');

      final body = {
        'Meal_Type': [preferences['meal_type'] ?? 'lunch'],
        'Serving': int.tryParse(preferences['servings']?.toString() ?? '1') ?? 1,
        'Ingredients_Available': ingredients,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating recipes: $e');
    }
  }
}