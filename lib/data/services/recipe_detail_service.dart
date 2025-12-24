import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class RecipeDetailService {
  static const String _baseUrl = 'http://3.108.110.151:5001';
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  
  // Cache to store recipe details to avoid repeated API calls
  static final Map<String, Map<String, dynamic>> _recipeDetailCache = {};

  // Fetch recipe details from the backend
  static Future<Map<String, dynamic>> fetchRecipeDetails(String recipeName) async {
    // Return cached data if available
    if (_recipeDetailCache.containsKey(recipeName)) {
      return _recipeDetailCache[recipeName]!;
    }

    try {
      // Try to fetch recipe details from the main endpoint
      final response = await _dio.post(
        "/generate-recipe-details",
        data: {"dish_name": recipeName},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          _recipeDetailCache[recipeName] = data;
          return data;
        }
      }
      
      // If the specific endpoint fails, try the fallback endpoints
      return await _fetchFallbackDetails(recipeName);
    } catch (e) {
      debugPrint('Error fetching recipe details: $e');
      return _fetchFallbackDetails(recipeName);
    }
  }

  // Fallback to individual endpoints if the combined endpoint fails
  static Future<Map<String, dynamic>> _fetchFallbackDetails(String recipeName) async {
    try {
      // Try to get all data in parallel
      final results = await Future.wait([
        _fetchCookware(recipeName),
        _fetchCookingSteps(recipeName),
        _fetchReviews(recipeName),
        _fetchSimilarRecipes(recipeName),
      ], eagerError: true);

      final result = {
        'cookware': results[0],
        'steps': results[1],
        'reviews': results[2],
        'similar_recipes': results[3],
      };
      
      _recipeDetailCache[recipeName] = result;
      return result;
    } catch (e) {
      debugPrint('Error in fallback details: $e');
      // Return empty data structure if all fails
      return {
        'cookware': [],
        'steps': [],
        'reviews': [],
        'similar_recipes': [],
      };
    }
  }

  static Future<List<String>> _fetchCookware(String recipeName) async {
    try {
      final response = await _dio.post(
        "/generate-recipe-cookware",
        data: {"dish_name": recipeName},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['cookware'] is List) {
          return List<String>.from(data['cookware']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching cookware: $e');
      return [];
    }
  }

  static Future<List<String>> _fetchCookingSteps(String recipeName) async {
    try {
      final response = await _dio.post(
        "/generate-recipe-steps",
        data: {"dish_name": recipeName},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['steps'] is List) {
          return List<String>.from(data['steps']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching cooking steps: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchReviews(String recipeName) async {
    try {
      final response = await _dio.post(
        "/generate-recipe-reviews",
        data: {"dish_name": recipeName},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['reviews'] is List) {
          return List<Map<String, dynamic>>.from(data['reviews']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchSimilarRecipes(String recipeName) async {
    try {
      final response = await _dio.post(
        "/generate-similar-recipes",
        data: {"dish_name": recipeName},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['similar'] is List) {
          return List<Map<String, dynamic>>.from(data['similar']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching similar recipes: $e');
      return [];
    }
  }
}
