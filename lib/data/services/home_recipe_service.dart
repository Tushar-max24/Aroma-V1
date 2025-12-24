import 'package:dio/dio.dart';

class HomeRecipeService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://3.108.110.151:5001",
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  Future<List<dynamic>> generateHomeRecipes() async {
    try {
      final response = await _dio.post(
        "/generate-recipes",
        data: {
          "Cuisine_Preference": "Indian",
          "Dietary_Restrictions": "Vegetarian",
          "Cookware_Available": ["Gas Stove"],
          "Meal_Type": ["Breakfast"],
          "Cooking_Time": "< 15 min",
          "Serving": "1",
          "Ingredients_Available": ["Ladies finger", "rice"],
        },
      );

      print("🔥 RAW HOME API RESPONSE: ${response.data}");

      // Handle different response formats
      if (response.data is Map) {
        // Check for different possible response structures
        if (response.data['Recipes'] != null) {
          return response.data['Recipes'] as List;
        } else if (response.data['recipes'] != null) {
          return response.data['recipes'] as List;
        } else if (response.data['data'] != null) {
          return response.data['data'] as List;
        }
      } else if (response.data is List) {
        return response.data as List;
      }
      
      throw Exception('Unexpected API response format');
    } catch (e) {
      print('❌ Error fetching recipes: $e');
      rethrow; // Re-throw to let the provider handle the error
    }
  }
}