import 'package:flutter/foundation.dart';

class ApiEndpoints {
  
  static const String baseUrl = 'https://aroma-1.onrender.com';

  static const String ingredients = '$baseUrl/ingredients';
  static const String recipes = '$baseUrl/recipes';
  static const String cookingSteps = '$baseUrl/cookingSteps';
  static const String cookingStepsDetailed = '$baseUrl/cookingStepsDetailed';
  static const String cookware = '$baseUrl/cookware';
  static const String ingredientData = '$baseUrl/ingredientData';
  static const String reviewData = '$baseUrl/reviewData';
  static const String similarRecipes = '$baseUrl/similarRecipes';
  static const String preferences = '$baseUrl/preferences';

  // Helper for logging in debug mode
  static void debugPrintBaseUrl() {
    if (kDebugMode) {
      debugPrint('API base URL: $baseUrl');
    }
  }
}

