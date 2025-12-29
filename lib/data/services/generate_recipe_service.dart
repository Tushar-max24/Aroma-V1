// lib/data/services/generate_recipe_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GenerateRecipeService {
  static const String _recipeUrl = "http://3.108.110.151:5001/generate-recipes-ingredient";
  static const String _imageUrl = "http://3.108.110.151:5001/generate-dish-image";
  
  // Default timeout duration for API calls
  static const Duration _timeoutDuration = Duration(seconds: 30);

  /// Generate recipes based on ingredients and preferences
  /// Returns a list of recipes on success, or null on failure
  Future<List<Map<String, dynamic>>?> generateRecipes(
    List<String> ingredients, 
    Map<String, dynamic> preferences,
  ) async {
    try {
      final url = Uri.parse(_recipeUrl);
      final body = jsonEncode({
        "ingredients": ingredients,
        "preferences": preferences,
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      ).timeout(_timeoutDuration);

      _logApiCall('Recipe API', response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['recipes'] is List) {
          return List<Map<String, dynamic>>.from(data['recipes']);
        } else if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      _logError('Recipe Generation Failed', e);
      return null; // Return null to indicate failure
    }
  }

  /// Generate dish image; returns either a remote image URL (String) or Uint8List (decoded base64)
  /// Returns null on failure
  Future<dynamic> generateDishImage(String dishName) async {
    try {
      if (dishName.isEmpty) return null;
      
      final url = Uri.parse(_imageUrl);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"dish_name": dishName}),
      ).timeout(_timeoutDuration);

      _logApiCall('Image API', response.statusCode, response.body);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          if (decoded['image_url'] != null) {
            return decoded['image_url'].toString();
          } else if (decoded['image_base64'] != null) {
            return base64Decode(decoded['image_base64'].toString());
          } else if (response.body.trim().startsWith('http')) {
            return response.body.trim();
          }
        }
        throw Exception('Invalid image response format');
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      _logError('Image Generation Failed', e);
      return null; // Return null to indicate failure
    }
  }

  // Helper method to log API calls
  void _logApiCall(String apiName, int statusCode, String response) {
    print('📌 $apiName Status: $statusCode');
    if (response.length > 200) {
      print('📌 $apiName Response: ${response.substring(0, 200)}...');
    } else {
      print('📌 $apiName Response: $response');
    }
  }

  // Helper method to log errors
  void _logError(String message, dynamic error) {
    print('❌ $message: $error');
    if (error is Error) {
      print('❌ Stack trace: ${error.stackTrace}');
    }
  }
}
