// lib/data/services/generate_recipe_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GenerateRecipeService {
  // Use environment variables for API endpoints
  static String _baseUrl = dotenv.env['MONGO_EXTERNAL_API_URL'] ?? "http://3.108.110.151:5001";
  static String _localBaseUrl = dotenv.env['MONGO_API_BASE_URL'] ?? "http://localhost:3000";
  static String get _recipeUrl => "$_baseUrl/generate-recipes-ingredient";
  static String get _imageUrl => "$_baseUrl/generate-dish-image";
  
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

  /// Test connection to MongoDB server for recipe generation
  static Future<bool> testConnection() async {
    debugPrint("🔄 Testing recipe service connection to $_baseUrl...");
    
    // List of URLs to try in order
    final urls = [
      "$_baseUrl/api/health",
      "$_localBaseUrl/api/health",
      "http://127.0.0.1:3000/api/health",
      "http://10.231.82.169:3000/api/health",
    ];
    
    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      debugPrint("🔍 Trying recipe connection ${i + 1}/${urls.length}: $url");
      
      try {
        final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 3));
        
        debugPrint("📌 Recipe Health Check Response: ${response.statusCode}");
        
        if (response.statusCode == 200) {
          debugPrint("✅ Recipe service connection successful to: $url");
          // Update base URL for future requests
          _baseUrl = url.replaceAll('/api/health', '');
          return true;
        }
      } catch (e) {
        debugPrint("⚠️ Recipe connection failed to $url: $e");
        continue;
      }
    }
    
    debugPrint("❌ All recipe service connection attempts failed");
    return false;
  }

  // Helper method to log errors
  void _logError(String message, dynamic error) {
    print('❌ $message: $error');
    if (error is Error) {
      print('❌ Stack trace: ${error.stackTrace}');
    }
  }
}
